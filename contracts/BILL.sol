// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Library.sol";

// Gauges are used to incentivize pools, they emit reward tokens over 7 days for staked LP tokens
contract BILL {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    uint public period = 86400 * 7 * 30; // 1 month
    address public devaddr_;
    address private helper;
    uint public adminBountyRequired;
    bool public immutable isPayable;
    mapping(address => uint) public adminBountyId;
    mapping(address => uint) public totalProcessed;
    mapping(address => bool) public isAdmin;
    uint public bountyRequired;
    bool public profileRequired;
    uint public bufferTime;
    mapping(uint => string) public media;
    mapping(uint => string) public description;
    mapping(uint => bool) public isAutoChargeable;
    mapping(uint => uint) public userBountyRequired;
    mapping(uint => mapping(uint => uint)) public payTab;
    struct MigrationPoint {
        uint version;
        uint startPayable;
        uint startReceivable;
        uint creditFactor;
        uint debitFactor;
    }
    struct ProtocolInfo {
        address token;
        uint version;
        uint bountyId;
        uint profileId;
        uint credit;
        uint debit;
        uint startPayable;
        uint startReceivable;
        uint periodPayable;
        uint periodReceivable;
        uint creditFactor;
        uint debitFactor;
    }
    MigrationPoint public migrationPoint;
    mapping(uint => uint) public optionId;
    mapping(uint => Divisor) public penaltyDivisor;
    mapping(uint => Divisor) public discountDivisor;
    mapping(uint => uint[]) public parents;
    mapping(uint => ProtocolInfo) public protocolInfo;
    mapping(address => uint) public pendingRevenue;
    bool public checkIndentity;
    uint public adminCreditShare;
    uint public adminDebitShare;
    uint public collectionId;
    uint public maxNotesPerProtocol = 1;
    address contractAddress;
    mapping(address => uint) public cap;
    mapping(uint => address) public taxContract;
    mapping(address => uint) public addressToProtocolId;
    mapping(uint => mapping(address => bool)) public whitelist;
    mapping(uint => EnumerableSet.UintSet) private _allPeriods;

    constructor(
        address _devaddr,
        address _helper,
        address __contractAddress,
        bool _isPayable
    ) {
        collectionId = IMarketPlace(IContract(__contractAddress).marketCollections())
        .addressToCollectionId(_devaddr);
        require(collectionId > 0, "B01");
        isPayable = _isPayable;
        helper = _helper;
        devaddr_ = _devaddr;
        isAdmin[devaddr_] = true;
        contractAddress = __contractAddress;
    }

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender]);
        _;
    }

    modifier onlyDev() {
        require(devaddr_ == msg.sender || 
        collectionId == IMarketPlace(IContract(contractAddress).marketCollections())
        .addressToCollectionId(msg.sender));
        _;
    }

    function updateCap(address _token, uint _cap) external onlyAdmin {
        cap[_token] = _cap;
    }

    function updateAdmin(address _admin, bool _add) external onlyDev {
        isAdmin[_admin] = _add;
    }

    function updateDev(address _devaddr) external onlyDev {
        devaddr_ = _devaddr;
    }

    function updateWhitelist(address _contract, uint _protocolId, bool _add) external onlyAdmin {
        whitelist[_protocolId][_contract] = _add;
    }

    function updateDiscountDivisor(uint _optionId, uint _factor, uint _period, uint _cap) external onlyAdmin {
        discountDivisor[_optionId] = Divisor({
            factor: _factor,
            period: _period,
            cap: _cap == 0 ? 10000 : _cap
        });
    }

    function updatePenaltyDivisor(uint _optionId, uint _factor, uint _period, uint _cap) external onlyAdmin {
        penaltyDivisor[_optionId] = Divisor({
            factor: _factor,
            period: _period,
            cap: _cap == 0 ? 10000 : _cap
        });
    }
    
    function updateMigrationPoint(
        uint _startPayable,
        uint _startReceivable,
        uint _creditFactor,
        uint _debitFactor
    ) external onlyAdmin {
        migrationPoint = MigrationPoint({
            version: migrationPoint.version+1,
            startPayable: _startPayable,
            startReceivable: _startReceivable,
            creditFactor: _creditFactor,
            debitFactor: _debitFactor
        });
    }

    function migrate(uint _protocolId) public returns (uint) {
        if (migrationPoint.version > protocolInfo[_protocolId].version) {
            uint _newProtocolId = _updateProtocol(
                protocolInfo[_protocolId].token,
                ve(helper).ownerOf(_protocolId),
                protocolInfo[_protocolId].startReceivable,
                protocolInfo[_protocolId].startPayable,
                protocolInfo[_protocolId].periodReceivable,
                protocolInfo[_protocolId].periodPayable,
                optionId[_protocolId],
                userBountyRequired[_protocolId],
                media[_protocolId],
                description[_protocolId]
            );
            parents[_newProtocolId]= parents[_protocolId];
            parents[_newProtocolId].push(_protocolId);
            delete parents[_protocolId];
            return _newProtocolId;
        }
        return _protocolId;
    }

    function updateParameters(
        bool _checkIndentity,
        bool _profileRequired,
        uint _bountyRequired,
        uint _bufferTime,
        uint _maxNotesPerProtocol,
        uint _adminBountyRequired,
        uint _period,
        uint _adminCreditShare,
        uint _adminDebitShare
    ) external onlyAdmin {
        require(adminCreditShare + IBILL(_note()).tradingFee(true) <= 10000);
        require(adminDebitShare + IBILL(_note()).tradingFee(false) <= 10000);
        adminCreditShare = _adminCreditShare;
        adminDebitShare = _adminDebitShare;
        maxNotesPerProtocol = _maxNotesPerProtocol;
        bountyRequired = _bountyRequired;
        bufferTime = _bufferTime;
        profileRequired = _profileRequired;
        if (_adminBountyRequired > adminBountyRequired) {
            adminBountyRequired = _adminBountyRequired;
        }
        if (_period > period) {
            period = _period;
        }
        checkIndentity = _checkIndentity;
    }
    
    function notifyCredit(address _merchant, address _owner, uint _amount) external lock {
        uint _protocolId = addressToProtocolId[_owner];
        uint _newProtocolId = migrate(_protocolId);
        require(isAdmin[msg.sender] || (whitelist[_protocolId][msg.sender] && whitelist[_protocolId][_merchant]));
        _addRemaining(_protocolId, _amount * protocolInfo[_protocolId].creditFactor / 10000);
        protocolInfo[_protocolId].credit += _amount;
        _creditTab(_protocolId, _amount);
        IBILL(helper).emitNotifyCredit(
            _protocolId,
            _newProtocolId,
            _amount,
            _merchant
        );
    }

    function notifyDebit(address _merchant, address _owner, uint _amount) external lock {
        uint _protocolId = addressToProtocolId[_owner];
        uint _newProtocolId = migrate(_protocolId);
        require(isAdmin[msg.sender] || (whitelist[_protocolId][msg.sender] && whitelist[_protocolId][_merchant]));
        protocolInfo[_protocolId].debit += _amount;
        if (!isPayable) _debitTab(_protocolId, _amount);
        IBILL(helper).emitNotifyDebit(
            _protocolId,
            _newProtocolId,
            _amount,
            _merchant
        );
    }

    function _creditTab(uint _protocolId, uint _amount) internal {
        uint _period = block.timestamp / protocolInfo[_protocolId].periodReceivable * protocolInfo[_protocolId].periodReceivable;
        uint _currPeriod = _allPeriods[_protocolId].length() > 0 ? _allPeriods[_protocolId].at(0) : _period;
        if (payTab[_protocolId][_currPeriod] <= _amount) {
            payTab[_protocolId][_currPeriod] = 0; //clears tab 
            _allPeriods[_protocolId].remove(_currPeriod);
        } else {
            payTab[_protocolId][_currPeriod] -= _amount; 
        }
    }
    
    function getAllPeriods(uint _protocolId, uint _start) external view returns(uint[] memory periods) {
        periods = new uint[](_allPeriods[_protocolId].length() - _start);
        for (uint i = _start; i < _allPeriods[_protocolId].length(); i++) {
            periods[i] = _allPeriods[_protocolId].at(i);
        }    
    }

    function _debitTab(uint _protocolId, uint _amount) internal {
        uint _period = block.timestamp / protocolInfo[_protocolId].periodReceivable * protocolInfo[_protocolId].periodReceivable;
        require(_allPeriods[_protocolId].length() < IContract(contractAddress).maximumSize());
        _allPeriods[_protocolId].add(_period);
        payTab[_protocolId][_period] += _amount; 
    }

    function _trustBounty() internal view returns(address) {
        return IContract(contractAddress).trustBounty();
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || helper == msg.sender);
        contractAddress = _contractAddress;
        helper = IContract(_contractAddress).billMinter();
    }

    function _checkIdentityProof(address _owner, uint _identityTokenId) internal {
        if (collectionId > 0 && checkIndentity) {
            IMarketPlace(IContract(contractAddress).marketHelpers2())
            .checkUserIdentityProof(collectionId, _identityTokenId, _owner);
        }
    }

    function _updateProtocol(
        address _token,
        address _owner,
        uint _startReceivable,
        uint _startPayable,
        uint _periodReceivable,
        uint _periodPayable,
        uint _optionId,
        uint _bountyRequired,
        string memory _media,
        string memory _description
    ) internal returns(uint _protocolId) {
        _protocolId = IBILL(helper).mint(_owner);
        protocolInfo[_protocolId].token = _token;
        protocolInfo[_protocolId].startReceivable = block.timestamp + _startReceivable;
        protocolInfo[_protocolId].startPayable = block.timestamp + _startPayable;
        protocolInfo[_protocolId].periodReceivable = _periodReceivable;
        protocolInfo[_protocolId].periodPayable = _periodPayable;
        protocolInfo[_protocolId].version = migrationPoint.version;
        protocolInfo[_protocolId].creditFactor = migrationPoint.creditFactor;
        protocolInfo[_protocolId].debitFactor = migrationPoint.debitFactor;
        optionId[_protocolId] = _optionId;
        userBountyRequired[_protocolId] = Math.max(bountyRequired, _bountyRequired);

        IBILL(helper).emitUpdateProtocol(
            _protocolId,
            _optionId,
            _token,
            _owner, 
            _media,
            _description
        );
    }
    
    function updateProtocol(
        address _owner,
        address _token,
        uint _protocolId,
        uint[5] memory _userInfo, //_identityTokenId,_startReceivable,_startPayable,_periodReceivable,_periodPayable,
        uint _bountyRequired,
        uint _optionId,
        string memory _media,
        string memory _description
    ) external onlyAdmin {
        if(_protocolId == 0) {
            _checkIdentityProof(_owner, _userInfo[0]);
            _protocolId = _updateProtocol(
                _token, 
                _owner, 
                _userInfo[1],
                _userInfo[2],
                _userInfo[3],
                _userInfo[4],
                _optionId, 
                _bountyRequired,
                _media,
                _description
            );
        }
        addressToProtocolId[_owner] = _protocolId;
        media[_protocolId] = _media;
        description[_protocolId] = _description;
    }

    function updateBounty(uint _bountyId, uint _tokenId) external {
        address trustBounty = _trustBounty();
        (address owner,address _token,,address claimableBy,,,,,,) = 
        ITrustBounty(trustBounty).bountyInfo(_bountyId);
        if (isAdmin[msg.sender]) {
            require(owner == msg.sender && claimableBy == address(0x0), "BILL1");
            if (_bountyId > 0) {
                IBILL(helper).attach(_bountyId);
            } else if (_bountyId == 0 && adminBountyId[_token] > 0) {
                IBILL(helper).detach(_bountyId);
            }
            adminBountyId[_token] = _bountyId;
        } else {
            require(owner == msg.sender && 
                ve(helper).ownerOf(_tokenId) == msg.sender &&
                _token == protocolInfo[_tokenId].token && 
                claimableBy == devaddr_, 
                "BILL2"
            );
            protocolInfo[_tokenId].bountyId = _bountyId;
        }
    }

    function updateAutoCharge(bool _autoCharge, uint _tokenId) external {
        require(ve(helper).ownerOf(_tokenId) == msg.sender, "BILL3");
        isAutoChargeable[_tokenId] = _autoCharge;
        IBILL(helper).emitUpdateAutoCharge(
            _tokenId,
            _autoCharge
        );
    }

    function _note() internal view returns(address) {
        return IContract(contractAddress).billNote();
    }

    function updateTaxContract(address _taxContract) external {
        taxContract[addressToProtocolId[msg.sender]] = _taxContract;
    }

    function updateProfile() external {
        protocolInfo[addressToProtocolId[msg.sender]].profileId = 
        IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender);
    }

    function updateOwner(address _prevOwner, uint _protocolId) external {
        require(ve(helper).ownerOf(_protocolId) == msg.sender, "BILL8");
        addressToProtocolId[msg.sender] = _protocolId;
        delete addressToProtocolId[_prevOwner];
    }

    function updatePaidPayable(uint _protocolId, uint _amount) external {
        if(msg.sender == _note()) {
            protocolInfo[_protocolId].debit += _amount;
            if(taxContract[_protocolId] != address(0x0)) {
                IBILL(taxContract[_protocolId]).notifyCredit(address(this), ve(_minter()).ownerOf(_protocolId), _amount);
            }
        }
    }

    function _minter() internal view returns(address) {
        return IContract(contractAddress).billMinter();
    }

    function deleteProtocol (uint _protocolId) public onlyAdmin {
        IBILL(helper).burn(_protocolId);
        delete protocolInfo[_protocolId];
        IBILL(helper).emitDeleteProtocol(_protocolId);
    }

    function getReceivable(uint _protocolId, uint _amount) public view returns(uint,uint) {
        uint _optionId = optionId[_protocolId];
        (uint dueReceivable,,int secondsReceivable) = IBILL(_note()).getDueReceivable(address(this), _protocolId);
        if (_amount > 0) {
            dueReceivable = _amount;
        }
        if (secondsReceivable > 0) {
            uint _factor = Math.min(penaltyDivisor[_optionId].cap, (uint(secondsReceivable) / Math.max(1,penaltyDivisor[_optionId].period)) * penaltyDivisor[_optionId].factor);
            uint _penalty = dueReceivable * _factor / 10000; 
            return (dueReceivable + _penalty, dueReceivable);
        } else {
            uint _factor = Math.min(discountDivisor[_optionId].cap, (uint(-secondsReceivable) / Math.max(1,discountDivisor[_optionId].period)) * discountDivisor[_optionId].factor);
            uint _discount = dueReceivable * _factor / 10000; 
            return (
                dueReceivable > _discount ? dueReceivable - _discount : 0,
                dueReceivable
            );
        }
    }
    
    function _getFees(uint _value, address token, bool _credit) internal view returns(uint payswapFees,uint adminFees) {
        address note = _note();
        payswapFees = Math.min(
            _value * IBILL(note).tradingFee(_credit) / 10000, 
            IContract(contractAddress).cap(token) > 0 
            ? IContract(contractAddress).cap(token) : type(uint).max
        );
        uint _share = _credit ? adminCreditShare : adminDebitShare;
        adminFees = Math.min(
            _value * _share / 10000, 
            cap[token] > 0 ? cap[token] : type(uint).max
        );
    }

    function _processCredit(uint _due, uint _protocolId) internal {
        (uint payswapFees,uint adminFees) = _getFees(_due, protocolInfo[_protocolId].token, true);
        uint _amount = _due - payswapFees - adminFees;
        protocolInfo[_protocolId].credit += _amount;
        _creditTab(_protocolId, _amount);
    }

    function autoCharge(uint[] memory _protocolIds, uint _amount) public lock {
        for (uint i = 0; i < _protocolIds.length; i++) {
            if (isAdmin[msg.sender]) require(isAutoChargeable[_protocolIds[i]], "BILL4");
            (uint _price, uint _due) = getReceivable(_protocolIds[i], _amount);
            address token = protocolInfo[_protocolIds[i]].token;
            (uint payswapFees,uint adminFees) = _getFees(_price, token, true);
            address _user = isAdmin[msg.sender] ? ve(helper).ownerOf(_protocolIds[i]) : msg.sender;
            IERC20(token).safeTransferFrom(_user, address(this), _price);
            IERC20(token).safeTransfer(helper, payswapFees);
            IBILL(helper).notifyFees(token, payswapFees);
            totalProcessed[token] += _price;
            _processCredit(_due, _protocolIds[i]);
            if(taxContract[_protocolIds[i]] != address(0x0)) {
                IBILL(taxContract[_protocolIds[i]]).notifyDebit(address(this), ve(helper).ownerOf(_protocolIds[i]), _price);
            }
            _processAdminFees(_protocolIds[i], adminFees, token);
            IBILL(helper).emitAutoCharge(
                _user,
                _protocolIds[i], 
                protocolInfo[_protocolIds[i]].credit
            );
        }
    }
    
    function _processAdminFees(uint _protocolId, uint _adminFees, address _token) internal {
        address note = _note();
        uint _tokenId = IARP(note).adminNotes(_protocolId);
        (uint due,,,,) = IBILL(note).notes(_protocolId);
        if (due > 0) {
            uint _paid = _adminFees >= due ? due : _adminFees;
            IBILL(note).updatePendingRevenueFromNote(_tokenId, _paid);
        } else {
            pendingRevenue[_token] += _adminFees;
        }
    }

    function _addRemaining(uint _protocolId, uint duePayable) internal returns(uint) {
        address token = protocolInfo[_protocolId].token;
        uint _balanceOf = erc20(token).balanceOf(address(this));
        if (isAdmin[msg.sender] && _balanceOf < duePayable) {
            IERC20(token).safeTransferFrom(msg.sender, address(this), duePayable - _balanceOf);
            _balanceOf = erc20(token).balanceOf(address(this));
        }
        return _balanceOf;
    }

    function payInvoicePayable(uint _protocolId, uint _amount) external lock {
        require(
            (addressToProtocolId[msg.sender] == _protocolId || isAdmin[msg.sender]) && isPayable, 
            "Only invoice owner or admin!"
        );
        address note = _note();
        address token = protocolInfo[_protocolId].token;
        (uint duePayable,,) = IBILL(note).getDuePayable(address(this), _protocolId);
        duePayable = _amount == 0 ? duePayable : Math.min(duePayable, _amount);
        uint _balanceOf = erc20(token).balanceOf(address(this));
        _balanceOf = _addRemaining(_protocolId, duePayable);
        uint _toPay = _balanceOf < duePayable ? _balanceOf : duePayable;
        protocolInfo[_protocolId].debit += _toPay;
        (uint payswapFees,uint adminFees) = _getFees(_toPay, token, false);
        totalProcessed[token] += _toPay;
        pendingRevenue[token] += adminFees;
        if(taxContract[_protocolId] != address(0x0)) {
            IBILL(taxContract[_protocolId]).notifyCredit(address(this), ve(_minter()).ownerOf(_protocolId), _toPay);
        }
        _processAdminFees(_protocolId, adminFees, token);
        IERC20(token).safeTransfer(helper, payswapFees);
        IBILL(helper).notifyFees(token, payswapFees);
        _toPay -= (adminFees + payswapFees);
        erc20(token).approve(note, _toPay);
        IBILL(note).safeTransferWithBountyCheck(
            token,
            ve(helper).ownerOf(_protocolId),
            _protocolId,
            _toPay
        );
        IBILL(helper).emitPayInvoicePayable(_protocolId, _toPay);
    }

    function withdraw(address _token, uint amount) external onlyAdmin {
        require(pendingRevenue[_token] >= amount, "BILL9");
        pendingRevenue[_token] -= amount;
        address note = _note();
        erc20(_token).approve(note, amount);
        IBILL(note).safeTransferWithBountyCheck(_token, msg.sender, 0, amount);
    
        IBILL(helper).emitWithdraw(msg.sender, amount);
    }

    function noteWithdraw(address _to, address _token, uint amount) external {
        require(msg.sender == _note(), "BILL10");
        IERC20(_token).safeTransfer(_to, amount);     
    }
}

contract BILLMinter is ERC721Pausable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct MintInfo {
        address bill;
        uint extraMint;
    }
    mapping(uint => MintInfo) public tokenIdToBILL;
    mapping(uint => uint) public tokenIdToParent;
    uint public tokenId = 1;
    EnumerableSet.AddressSet private gauges;
    mapping(uint => address) public profiles;
    address public contractAddress;
    mapping(address => uint) public treasuryFees;
    mapping(address => uint) public addressToProfileId;

    event Voted(address indexed bill, uint profileId, uint likes, uint dislikes, bool like);
    event UpdateAutoCharge(uint indexed protocolId, address bill, bool isAutoChargeable);
    event AutoCharge(uint indexed protocolId, address from, address bill, uint paidReceivable);
    event PayInvoicePayable(address bill, uint protocolId, uint toPay);
    event DeleteProtocol(uint indexed protocolId, address bill);
    event Withdraw(address indexed from, address bill, uint amount);
    event TransferDueToNote(address bill, uint protocolId, uint tokenId, uint due, bool adminNote);
    event ClaimTransferNote(uint tokenId);
    event UpdateMiscellaneous(
        uint idx, 
        uint billId, 
        string paramName, 
        string paramValue, 
        uint paramValue2, 
        uint paramValue3, 
        address sender,
        address paramValue4,
        string paramValue5
    );
    event UpdateProtocol(address bill, uint protocolId, uint optionId, address token, address owner, string media, string description);
    event CreateBILL(address bill, address _user, uint profileId);
    event DeleteBILL(address bill);
    event NotifyCredit(address bill, address merchant, uint protocolId, uint newProtocolId, uint amount);
    event NotifyDebit(address bill, address merchant, uint protocolId, uint newProtocolId, uint amount);

    constructor() ERC721("BILLProof", "BILLNFT")  {}

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function _trustBounty() internal view returns(address) {
        return IContract(contractAddress).trustBounty();
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender, "NT2");
        contractAddress = _contractAddress;
    }

    function setContractAddressAt(address _bill) external {
        IMarketPlace(_bill).setContractAddress(contractAddress);
    }

    function verifyNFT(uint _tokenId, uint _collectionId, string memory item) external view returns(uint) {
        if (
            IBILL(tokenIdToBILL[_tokenId].bill).collectionId() == _collectionId &&
            (
                keccak256(abi.encodePacked(item)) == keccak256(abi.encodePacked("")) ||
                keccak256(abi.encodePacked(item)) == keccak256(abi.encodePacked(IBILL(tokenIdToBILL[_tokenId].bill).description(_tokenId)))
            )
        ) {
            return 1;
        }
        return 0;
    }

    function mint(address _to) external returns(uint) {
        require(gauges.contains(msg.sender), "BILLHH10");
        _safeMint(_to, tokenId, msg.data);
        tokenIdToBILL[tokenId].bill = msg.sender;
        return tokenId++;
    }

    function burn(uint _tokenId) external {
        require(gauges.contains(msg.sender) || ownerOf(_tokenId) == msg.sender, "BILLHH6");
        _burn(_tokenId);
        delete tokenIdToParent[_tokenId];
        delete tokenIdToBILL[_tokenId];
    }

    function mintExtra(uint _tokenId, uint _extraMint) external returns(uint) {
        require(ownerOf(_tokenId) == msg.sender, "BILLHH11");
        require(tokenIdToBILL[_tokenId].extraMint >= _extraMint, "BILLHH12");
        for (uint i = 0; i < _extraMint; i++) {
            _safeMint(msg.sender, tokenId, msg.data);
            tokenIdToParent[tokenId++] = _tokenId;
        }
        tokenIdToBILL[_tokenId].extraMint -= _extraMint;
        return tokenId;
    }

    function updateMintInfo(address _bill, uint _extraMint, uint _tokenId) external {
        require(tokenIdToBILL[_tokenId].bill == _bill && IAuth(_bill).isAdmin(msg.sender), "BILLHH13");
        tokenIdToBILL[_tokenId].bill = msg.sender;
        tokenIdToBILL[_tokenId].extraMint += _extraMint;
    }

    function attach(uint _bountyId) external {
        require(gauges.contains(msg.sender), "SN07");
        ITrustBounty(IContract(contractAddress).trustBountyHelper()).attach(_bountyId);
    }

    function detach(uint _bountyId) external {
        require(gauges.contains(msg.sender), "SN08");
        ITrustBounty(IContract(contractAddress).trustBountyHelper()).detach(_bountyId);
    }
    
    function emitVoted(address _bill, uint _profileId, uint likes, uint dislikes, bool like) external {
        require(IContract(contractAddress).billHelper() == msg.sender, "BILLH1");
        emit Voted(_bill, _profileId, likes, dislikes, like);
    }

    function notifyFees(address _token, uint _fees) external {
        require(gauges.contains(msg.sender) || IContract(contractAddress).billNote() == msg.sender, "BILLH2");        
        treasuryFees[_token] += _fees;
    }

    function getAllBills(uint _start) external view returns(address[] memory bills) {
        bills = new address[](gauges.length() - _start);
        for (uint i = _start; i < gauges.length(); i++) {
            bills[i] = gauges.at(i);
        }    
    }
    
    function _getColor(uint _percentile) internal pure returns(COLOR) {
        if (_percentile > 75) {
            return COLOR.GOLD;
        } else if (_percentile > 50) {
            return COLOR.SILVER;
        } else if (_percentile > 25) {
            return COLOR.BROWN;
        } else {
            return COLOR.BLACK;
        }
    }

    function getGaugeNColor(uint _ssidAuditorProfileId) external view returns(address, COLOR) {
        uint _percentile = IBILL(IContract(contractAddress).billHelper()).percentiles(profiles[_ssidAuditorProfileId]);
        return (
            profiles[_ssidAuditorProfileId],
            _getColor(_percentile)
        );
    }

    function isGauge(address _bill) external view returns(bool) {
        return gauges.contains(_bill);
    }
    
    function updateGauge(
        address _last_gauge,
        address _user,
        uint _profileId
    ) external {
        require(msg.sender == IContract(contractAddress).billFactory(), "BILLH3");
        require(IProfile(IContract(contractAddress).profile()).addressToProfileId(_user) == _profileId && _profileId > 0, "BILLH4");
        gauges.add(_last_gauge);
        profiles[_profileId] = _last_gauge;
        addressToProfileId[_last_gauge] = _profileId;
        emit CreateBILL(_last_gauge, _user, _profileId);
    }
    
    function deleteBILL(address _bill) external {
        require(msg.sender == IAuth(contractAddress).devaddr_() || IAuth(_bill).isAdmin(msg.sender));
        gauges.remove(_bill);
        emit DeleteBILL(_bill);
    }

    function emitWithdraw(address from, uint amount) external {
        require(gauges.contains(msg.sender));
        emit Withdraw(from, msg.sender, amount);
    }

    function emitPayInvoicePayable(uint _protocolId, uint _toPay) external {
        require(gauges.contains(msg.sender));
        emit PayInvoicePayable(msg.sender, _protocolId, _toPay);
    }

    function emitDeleteProtocol(uint protocolId) external {
        require(gauges.contains(msg.sender));
        emit DeleteProtocol(protocolId, msg.sender);
    }

    function emitAutoCharge(address from, uint protocolId, uint paidReceivable) external {
        require(gauges.contains(msg.sender));
        emit AutoCharge(protocolId, from, msg.sender, paidReceivable);
    }

    function emitUpdateAutoCharge(uint protocolId, bool isAutoChargeable) external {
        require(gauges.contains(msg.sender));
        emit UpdateAutoCharge(protocolId, msg.sender, isAutoChargeable);
    }

    function emitUpdateMiscellaneous(
        uint _idx, 
        uint _billId, 
        string memory paramName, 
        string memory paramValue, 
        uint paramValue2, 
        uint paramValue3,
        address paramValue4,
        string memory paramValue5
    ) external {
        emit UpdateMiscellaneous(
            _idx, 
            _billId, 
            paramName, 
            paramValue, 
            paramValue2, 
            paramValue3, 
            msg.sender,
            paramValue4,
            paramValue5
        );
    }
    
    function emitNotifyCredit(uint _protocolId, uint _newProtocolId, uint _amount, address _merchant) external {
        require(gauges.contains(msg.sender));
        emit NotifyCredit(
            msg.sender,
            _merchant,
            _protocolId,
            _newProtocolId,
            _amount
        );
    }

    function emitNotifyDebit(uint _protocolId, uint _newProtocolId, uint _amount, address _merchant) external {
        require(gauges.contains(msg.sender));
        emit NotifyDebit(
            msg.sender,
            _merchant,
            _protocolId,
            _newProtocolId,
            _amount
        );
    }

    function emitUpdateProtocol(
        uint _protocolId,
        uint _optionId,
        address _token,
        address _owner,
        string memory _media,
        string memory _description
    ) external {
        require(gauges.contains(msg.sender));
        emit UpdateProtocol(
            msg.sender,
            _protocolId, 
            _optionId,
            _token,
            _owner,
            _media,
            _description
        );
    }

    function emitTransferDueToNote(address _bill, uint _protocolId, uint _tokenId, uint _amount, bool _adminNote) external {
        require(IContract(contractAddress).billNote() == msg.sender);
        emit TransferDueToNote(_bill, _protocolId, _tokenId, _amount, _adminNote);
    }

    function emitClaimTransferNote(uint _tokenId) external {
        require(IContract(contractAddress).billNote() == msg.sender);
        emit ClaimTransferNote(_tokenId);
    }

    function withdrawFees(address _token) external returns(uint _amount) {
        require(msg.sender == IAuth(contractAddress).devaddr_(), "BILLH13");
        _amount = treasuryFees[_token];
        IERC20(_token).safeTransfer(msg.sender, _amount);
        treasuryFees[_token] = 0;
        return _amount;
    }

    function tokenURI(uint __tokenId) public view virtual override returns (string memory output) {
        uint _tokenId = tokenIdToParent[__tokenId] == 0 ? __tokenId : tokenIdToParent[__tokenId];
        address _uriGenerator = IBILL(IContract(contractAddress).billHelper()).uriGenerator(tokenIdToBILL[_tokenId].bill);
        if (_uriGenerator != address(0x0)) {
            output = IBILL(_uriGenerator).uri(__tokenId);
        } else {
            output = _tokenURI(__tokenId);
        }
    }

    function _getOptions(address _bill, uint _protocolId, COLOR _color) internal view returns(string[] memory optionNames, string[] memory optionValues) {
        // (address _token,,uint _bountyId,uint _profileId,uint _credit,uint _debit,,,,,uint _creditFactor,uint _debitFactor) = 
        BILLInfo memory _p = IBILL(_bill).protocolInfo(_protocolId);
        optionNames = new string[](6);
        optionValues = new string[](6);
        uint idx;
        uint decimals = uint(IBILL(_p.token).decimals());
        optionNames[idx] = "BILL Color";
        optionValues[idx++] = _color == COLOR.GOLD 
        ? "Gold" 
        : _color == COLOR.SILVER 
        ? "Silver"
        : _color == COLOR.BROWN
        ? "Brown"
        : "Black";
        optionNames[idx] = "BILLID";
        optionValues[idx++] = toString(addressToProfileId[_bill]);
        optionNames[idx] = "UBID";
        optionValues[idx++] = toString(_p.bountyId);
        optionNames[idx] = "Profile ID";
        optionValues[idx++] = toString(_p.profileId);
        optionNames[idx] = "Credit";
        optionValues[idx++] = string(abi.encodePacked(toString(_p.credit / decimals), "(", toString(_p.credit * _p.creditFactor / decimals) ,")"));
        optionNames[idx] = "Debit";
        optionValues[idx++] = string(abi.encodePacked(toString(_p.debit / decimals), "(", toString(_p.debit * _p.debitFactor / decimals) ,")"));
    }

    function _tokenURI(uint __tokenId) internal view returns(string memory output) {
        uint _tokenId = tokenIdToParent[__tokenId] == 0 ? __tokenId : tokenIdToParent[__tokenId];
        address _bill= tokenIdToBILL[_tokenId].bill;
        uint _percentile = IBILL(IContract(contractAddress).billHelper()).percentiles(profiles[addressToProfileId[_bill]]);
        (string[] memory optionNames, string[] memory optionValues) = _getOptions(_bill, _tokenId, _getColor(_percentile));
        string[] memory description = new string[](1);
        description[0] = IBILL(_bill).description(_tokenId);
        
        output = IMarketPlace(IContract(contractAddress).nftSvg()).constructTokenURI(
            __tokenId,
            'BILL',
            _bill,
            ownerOf(_tokenId),
            ownerOf(__tokenId),
            address(0x0),
            IBILL(IContract(contractAddress).billHelper()).getMedia(_bill, _tokenId),
            optionNames,
            optionValues,
            description
        );
    }

    function toString(uint value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

contract BILLNote is ERC721Pausable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Cheque {
        uint due;
        uint start;
        uint protocolId;
        uint payswapFees;
        address bill;
        address token;
    }
    mapping(address => bool) public dueBeforePayable;
    mapping(uint => mapping(address => uint)) public activePeriod;
    mapping(uint => mapping(address => uint)) public balances;
    mapping(uint => Cheque) public notes;
    mapping(uint => uint) public pendingRevenueFromNote;
    uint public tokenId = 1;
    uint private tradingFeeCredit = 100;
    uint private tradingFeeDebit = 100;
    address public contractAddress;
    uint public bufferTime;
    mapping(uint => uint) public notesPerProtocol;
    mapping(uint => uint) public adminNotes;
    mapping(address => bool) public noChargeContracts;
    
    constructor() ERC721("Electronic Bill Cheque", "ebCheque")  {}

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function _trustBounty() internal view returns(address) {
        return IContract(contractAddress).trustBounty();
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender, "NT2");
        contractAddress = _contractAddress;
    }

    function updatePendingRevenueFromNote(uint _tokenId, uint _paid) external {
        require(IBILL(IContract(contractAddress).billMinter()).isGauge(msg.sender), "BILLH5");
        notes[tokenId].due -= _paid;
        pendingRevenueFromNote[_tokenId] += _paid;
    }

    function updateNoChargeContracts(address _contract, bool _add) external {
        require(msg.sender == IAuth(contractAddress).devaddr_());
        noChargeContracts[_contract] = _add;
    }

    function tradingFee(bool _credit) external view returns(uint) {
        if (noChargeContracts[msg.sender]) return 0;
        return _credit ? tradingFeeCredit : tradingFeeDebit;
    }

    function updateParams(
        uint _tradingFeeCredit, 
        uint _tradingFeeDebit,
        uint _bufferTime
    ) external {
        require(msg.sender == IAuth(contractAddress).devaddr_(), "BILLH12");
        tradingFeeCredit = _tradingFeeCredit;
        bufferTime = _bufferTime;
        tradingFeeDebit = _tradingFeeDebit;
    }

    function getNumPeriods(uint tm1, uint tm2, uint _period) public pure returns(uint) {
        if (tm1 == 0 || tm2 == 0 || tm2 < tm1) return 0;
        uint _numPeriods = _period > 0 ? (tm2 - tm1) / _period : 1;
        return Math.max(1,_numPeriods);
    }
    
    function getDueReceivable(address _bill, uint _protocolId) public view returns(uint, uint, int) {
        // (,,,,uint credit,uint debit,,uint startReceivable,,uint periodReceivable,uint creditFactor,uint debitFactor) 
        BILLInfo memory p = IBILL(_bill).protocolInfo(_protocolId);
        uint[] memory _allPeriods = IBILL(_bill).getAllPeriods(_protocolId, 0);
        uint numPeriods = getNumPeriods(
            p.startReceivable,
            _allPeriods.length > 0 ? _allPeriods[0] : block.timestamp,
            p.periodReceivable
        );
        uint due = p.debit > p.credit ? p.debit * p.debitFactor / 10000 - p.credit * p.creditFactor / 10000: 0;
        uint nextDue = p.startReceivable + p.periodReceivable * numPeriods;
        return (
            due, // due
            nextDue, // next
            int(block.timestamp) - int(nextDue) //late or seconds in advance
        );
    }

    function getDuePayable(address _bill, uint _protocolId) public view returns(uint, uint, int) {
        if(!IBILL(_bill).isPayable()) return (0,0,0);
        // (,,,,uint credit,uint debit,uint startPayable,,uint periodPayable,,uint creditFactor,uint debitFactor) 
        BILLInfo memory p = IBILL(_bill).protocolInfo(_protocolId);
        uint numPeriods = getNumPeriods(
            p.startPayable, 
            block.timestamp,
            p.periodPayable
        );
        uint nextDue = p.startPayable + p.periodPayable * numPeriods;
        uint due = p.credit > p.debit ? p.credit * p.creditFactor / 10000 - p.debit * p.debitFactor / 10000: 0;
        return (
            due, // due
            nextDue, // next
            int(block.timestamp) - int(nextDue) //late or seconds in advance
        );
    }
    
    function transferDueToNoteReceivable(
        address _bill,
        address _to, 
        uint _protocolId
    ) external lock {
        (uint dueReceivable, uint nextDue,) = getDueReceivable(_bill, _protocolId);
        require(
            // dueReceivable > 0 && 
            IAuth(_bill).isAdmin(msg.sender), "BILLH7");
        // (address _token,,,,,,,,,,,) 
        BILLInfo memory p = IBILL(_bill).protocolInfo(_protocolId);
        uint adminFees = Math.min(
            dueReceivable * IBILL(_bill).adminCreditShare() / 10000, 
            IBILL(_bill).cap(p.token) > 0 ? IBILL(_bill).cap(p.token) : type(uint).max
        );
        _beforeTransferCheck(_bill, p.token, 0, adminFees);
        adminNotes[_protocolId] = tokenId;
        notes[tokenId] = Cheque({
            due: adminFees,
            token: p.token,
            start: nextDue,
            protocolId: _protocolId,
            payswapFees: 0,
            bill: _bill
        });
        _safeMint(_to, tokenId, msg.data);
        IBILL(IContract(contractAddress).billMinter()).
        emitTransferDueToNote(_bill, _protocolId, tokenId++, adminFees, true);
    }
    
    function transferDueToNotePayable(
        address _bill,
        address _to, 
        uint _protocolId,
        uint _amount
    ) external lock {
        require(ve(IContract(contractAddress).billMinter()).ownerOf(_protocolId) == msg.sender, "BILLH8");
        require(notesPerProtocol[_protocolId] <= IBILL(_bill).maxNotesPerProtocol());
        (uint duePayable, uint nextDue,) = getDuePayable(_bill, _protocolId);
        // (address _token,,,,,,,,,,,) 
        BILLInfo memory p = IBILL(_bill).protocolInfo(_protocolId);
        uint adminFees = Math.min(
            duePayable * IBILL(_bill).adminDebitShare() / 10000, 
            IBILL(_bill).cap(p.token) > 0 ? IBILL(_bill).cap(p.token) : type(uint).max
        );
        uint payswapFees = Math.min(
            duePayable * tradingFeeDebit / 10000, 
            IContract(contractAddress).cap(p.token) > 0 
            ? IContract(contractAddress).cap(p.token) : type(uint).max
        );
        duePayable -= (adminFees + payswapFees);
        require(duePayable > 0, "BILLH9");
        _beforeTransferCheck(_bill, p.token, _protocolId, duePayable);
        notesPerProtocol[_protocolId] += 1;
        duePayable = Math.min(duePayable,_amount);
        notes[tokenId] = Cheque({
            due: duePayable,
            token: p.token,
            start: nextDue,
            payswapFees: payswapFees,
            bill: _bill,
            protocolId: _protocolId
        });
        IBILL(_bill).updatePaidPayable(_protocolId, duePayable);
        _safeMint(_to, tokenId, msg.data);
        IBILL(IContract(contractAddress).billMinter()).
        emitTransferDueToNote(_bill, _protocolId, tokenId++, duePayable, false);
    }
    
    function claimPendingRevenueFromNote(uint _tokenId) external lock {
        require(ownerOf(_tokenId) == msg.sender, "BILLH10");
        require(notes[_tokenId].start <= block.timestamp, "BILLH11");
        uint256 revenueToClaim;
        address bill = notes[_tokenId].bill;
        address token = notes[_tokenId].token;
        if (adminNotes[notes[_tokenId].protocolId] > 0) {
            revenueToClaim = pendingRevenueFromNote[_tokenId];
            delete pendingRevenueFromNote[_tokenId];
            delete adminNotes[notes[_tokenId].protocolId];
        } else {
            require(erc20(notes[_tokenId].token).balanceOf(bill) >= notes[_tokenId].due);
            revenueToClaim = notes[_tokenId].due;
        }
        delete notes[_tokenId];
        _burn(_tokenId);
        IBILL(bill).noteWithdraw(address(msg.sender), token, revenueToClaim);
        IBILL(bill).noteWithdraw(address(this), token, notes[_tokenId].payswapFees);
        IBILL(IContract(contractAddress).billMinter()).notifyFees(token, notes[_tokenId].payswapFees);
        IBILL(IContract(contractAddress).billMinter()).emitClaimTransferNote(_tokenId);
    }
    
    function _checkBalance(
        address _bill, 
        address _token, 
        uint _protocolId, 
        uint _amount, 
        uint _bountyId,
        uint _bountyRequired
    ) internal {
        address trustBounty = _trustBounty();
        uint _limit = ITrustBounty(trustBounty).getBalance(_bountyId);
        (,,,,,,uint endTime,,,) = ITrustBounty(trustBounty).bountyInfo(_bountyId);
        uint _balance = balances[_protocolId][_token] + _amount;
        if (activePeriod[_protocolId][_token] < block.timestamp) {
            uint _period = IBILL(_bill).period();
            activePeriod[_protocolId][_token] = (block.timestamp + _period) / _period * _period;
            _balance = _amount;
            balances[_protocolId][_token] = 0;
        }
        require(_balance * _bountyRequired / 10000 <= _limit, "BILLH14");
        uint _bufferTime = Math.max(bufferTime, IBILL(msg.sender).bufferTime());
        require(endTime > block.timestamp + _bufferTime, "BILLH15");
    }

    function _beforeTransferCheck(address _bill, address token, uint _protocolId, uint value) internal {
        if (_protocolId == 0 && IBILL(_bill).adminBountyRequired() > 0) {
            uint adminBountyId = IBILL(_bill).adminBountyId(token);
            _checkBalance(_bill, token, 0, value, adminBountyId, IBILL(_bill).adminBountyRequired());
        } else if (_protocolId > 0 && IBILL(_bill).userBountyRequired(_protocolId) > 0) {
            if (dueBeforePayable[_bill]) {
                (uint dueReceivable,,) = getDueReceivable(_bill, _protocolId);
                require(dueReceivable == 0, "BILLH16");
            }
            // (address _token,,uint _bountyId,,,,,,,,,) 
            BILLInfo memory p = IBILL(_bill).protocolInfo(_protocolId);
            _checkBalance(_bill, p.token, _protocolId, value, p.bountyId, IBILL(_bill).userBountyRequired(_protocolId));
        }
    }
    
    function updateDueBeforePayable(address _bill, bool _isTrue) external {
        require(IAuth(_bill).isAdmin(msg.sender), "BILLH17");
        dueBeforePayable[_bill] = _isTrue;
    }

    function safeTransferWithBountyCheck(address _token, address to, uint _protocolId, uint value) external {
        _beforeTransferCheck(msg.sender, _token, _protocolId, value);
        IERC20(_token).safeTransferFrom(msg.sender, to, value);
    }

    function _constructTokenURI(uint _tokenId, address _token, string[] memory description, string[] memory optionNames, string[] memory optionValues) internal view returns(string memory) {
        return IMarketPlace(IContract(contractAddress).nftSvg()).constructTokenURI(
            _tokenId,
            "",
            _token,
            ownerOf(_tokenId),
            ownerOf(_tokenId),
            address(0x0),
            new string[](1),
            optionNames,
            optionValues,
            description
        );
    }

    function tokenURI(uint _tokenId) public override view returns (string memory output) {
        uint idx;
        string[] memory optionNames = new string[](5);
        string[] memory optionValues = new string[](5);
        uint decimals = uint(IMarketPlace(notes[_tokenId].token).decimals());
        optionValues[idx++] = toString(_tokenId);
        optionNames[idx] = "PID";
        optionValues[idx++] = toString(notes[_tokenId].protocolId);
        optionNames[idx] = "End";
        optionValues[idx++] = toString(notes[_tokenId].start);
        optionNames[idx] = "Amount";
        optionValues[idx++] = string(abi.encodePacked(toString(notes[_tokenId].due/10**decimals), " " ,IMarketPlace(notes[_tokenId].token).symbol()));
        optionNames[idx] = "Expired";
        optionValues[idx++] = notes[_tokenId].start < block.timestamp ? "Yes" : "No";
        string[] memory _description = new string[](1);
        _description[0] = "This note gives you access to revenues of the bill on the specified protocol";
        output = _constructTokenURI(
            _tokenId, 
            notes[_tokenId].token,
            _description,
            optionNames, 
            optionValues 
        );
    }

    function toString(uint value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

}

contract BILLHelper {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using Percentile for *;

    // bill => category
    mapping(address => uint) public categories;
    struct ScheduledMedia {
        uint amount;
        string message;
    }
    mapping(uint => uint) public pricePerAttachMinutes;
    mapping(uint => ScheduledMedia) public scheduledMedia;
    mapping(uint => uint) public pendingRevenue;
    mapping(uint => mapping(string => EnumerableSet.UintSet)) private _scheduledMedia;
    uint internal minute = 3600; // allows minting once per week (reset every Thursday 00:00 UTC)
    mapping(address => string[]) public ratingLegend;
    uint private currentMediaIdx = 1;
    uint private maxNumMedia = 3;
    struct Channel {
        string message;
        uint active_period;
    }
    struct Vote {
        uint likes;
        uint dislikes;
    }
    mapping(uint => mapping(string => Channel)) private channels;
    mapping(uint => mapping(string => bool)) private tagRegistrations;
    mapping(uint => mapping(string => EnumerableSet.UintSet)) private excludedContents;
    mapping(uint => mapping(uint => string)) public tags;
    mapping(address => address) public uriGenerator;
    address private contractAddress;
    address public valuepoolAddress;
    uint public treasury;
    uint public valuepool;
    mapping(address => uint) public percentiles;
    EnumerableSet.UintSet private _allVoters;
    uint private sum_of_diff_squared;
    mapping(address => Vote) public  votes;
    mapping(uint => mapping(address => int)) public voted;
    
    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function _resetVote(address _bill, uint _profileId) internal {
        if (voted[_profileId][_bill] > 0) {
            votes[_bill].likes -= 1;
        } else if (voted[_profileId][_bill] < 0) {
            votes[_bill].dislikes -= 1;
        }
    }

    function vote(address _bill, uint _profileId, bool like) external {
        require(IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender) == _profileId && _profileId > 0, "BILLHH2");
        SSIData memory metadata = ISSI(IContract(contractAddress).ssi()).getSSID(_profileId);
        require(keccak256(abi.encodePacked(metadata.answer)) != keccak256(abi.encodePacked("")), "BILLHH3");
        _resetVote(_bill, _profileId);        
        if (like) {
            votes[_bill].likes += 1;
            voted[_profileId][_bill] = 1;
        } else {
            votes[_bill].dislikes += 1;
            voted[_profileId][_bill] = -1;
        }
        uint _billVotes;
        if (votes[_bill].likes > votes[_bill].dislikes) {
            _billVotes = votes[_bill].likes - votes[_bill].dislikes;
        }
        _allVoters.add(_profileId);
        (uint percentile, uint sods) = Percentile.computePercentileFromData(
            false,
            _billVotes,
            _allVoters.length(),
            _allVoters.length(),
            sum_of_diff_squared
        );
        sum_of_diff_squared = sods;
        percentiles[_bill] = percentile;
        IBILL(IContract(contractAddress).billMinter())
        .emitVoted(_bill, _profileId, votes[_bill].likes, votes[_bill].dislikes, like);
    }

    function updateValuepool(address _valuepoolAddress) external {
        require(IAuth(contractAddress).devaddr_() == msg.sender, "BILLHH4");
        valuepoolAddress = _valuepoolAddress;
    }
    
    function _minter() internal view returns(address) {
        return IContract(contractAddress).billMinter();
    }

    function buyWithContract(
        address _bill,
        address _user,
        address _referrer,
        string memory _tokenId,
        uint _amount,
        uint[] memory _protocolIds   
    ) external {
        require(IValuePool(IContract(contractAddress).valuepoolHelper()).isGauge(msg.sender));
        require(IBILL(IContract(contractAddress).billMinter()).isGauge(_bill), "WHHH1");
        (uint _price,) = IBILL(_bill).getReceivable(_protocolIds[0], _amount);
        // (address _token,,,,,,,,,,,) 
        BILLInfo memory p = IBILL(_bill).protocolInfo(_protocolIds[0]);
        erc20(p.token).approve(_bill, _price);
        IBILL(_bill).autoCharge(_protocolIds, _amount);
    }

    function getMedia(address _bill, uint _tokenId) external view returns(string[] memory _media) {
        uint _billId = IProfile(IContract(contractAddress).billMinter()).addressToProfileId(msg.sender);
        string memory _tag = tags[_billId][_tokenId];
        if (tagRegistrations[_billId][_tag]) {
            _media = new string[](_scheduledMedia[1][_tag].length() + 1);
            uint idx;
            _media[idx++] = IBILL(_bill).media(_tokenId);
            for (uint i = 0; i < _scheduledMedia[1][_tag].length(); i++) {
                uint _currentMediaIdx = _scheduledMedia[1][_tag].at(i);
                _media[idx] = scheduledMedia[_currentMediaIdx].message;
            }
        } else {
            _media = new string[](_scheduledMedia[_billId][_tag].length() + 1);
            uint idx;
            _media[idx++] = IBILL(_bill).media(_tokenId);
            for (uint i = 0; i < _scheduledMedia[_billId][_tag].length(); i++) {
                uint _currentMediaIdx = _scheduledMedia[_billId][_tag].at(i);
                _media[idx++] = scheduledMedia[_currentMediaIdx].message;
            }
        }
    }

    function updateTagRegistration(string memory _tag, bool _add) external {
        address billMinter = IContract(contractAddress).billMinter();
        uint _billId = IProfile(billMinter).addressToProfileId(msg.sender);
        tagRegistrations[_billId][_tag] = _add;
        IBILL(billMinter).emitUpdateMiscellaneous(
            1,
            _billId,
            _tag,
            "",
            _add ? 1 : 0,
            0,
            address(0x0),
            ""
        );
    }

    function updateExcludedContent(string memory _tag, string memory _contentName, bool _add) external {
        uint _billId = IProfile(IContract(contractAddress).billMinter()).addressToProfileId(msg.sender);
        if (_add) {
            require(IContent(contractAddress).contains(_contentName), "BILLHH5");
            excludedContents[_billId][_tag].add(uint(keccak256(abi.encodePacked(_contentName))));
        } else {
            excludedContents[_billId][_tag].remove(uint(keccak256(abi.encodePacked(_contentName))));
        }
    }

    function getExcludedContents(uint _billId, string memory _tag) public view returns(string[] memory _excluded) {
        _excluded = new string[](excludedContents[_billId][_tag].length());
        for (uint i = 0; i < _excluded.length; i++) {
            _excluded[i] = IContent(contractAddress).indexToName(excludedContents[_billId][_tag].at(i));
        }
    }

    function claimPendingRevenue() external lock {
        uint _billId = IProfile(IContract(contractAddress).billMinter()).addressToProfileId(msg.sender);
        IERC20(IContract(contractAddress).token()).safeTransfer(address(msg.sender), pendingRevenue[_billId]);
        pendingRevenue[_billId] = 0;
    }
    
    function updatePricePerAttachMinutes(uint _pricePerAttachMinutes) external {
        uint _billId = IProfile(IContract(contractAddress).billMinter()).addressToProfileId(msg.sender);
        pricePerAttachMinutes[_billId] = _pricePerAttachMinutes;
    }

    function sponsorTag(
        address _sponsor,
        address _bill,
        uint _amount, 
        string memory _tag, 
        string memory _message
    ) external {
        uint _billId = IProfile(IContract(contractAddress).billMinter()).addressToProfileId(_bill);
        require(IAuth(_sponsor).isAdmin(msg.sender), "BILLHH6");
        require(!ISponsor(_sponsor).contentContainsAny(getExcludedContents(_billId, _tag)), "BILLHH7");
        uint _pricePerAttachMinutes = pricePerAttachMinutes[_billId];
        if (_pricePerAttachMinutes > 0) {
            uint price = _amount * _pricePerAttachMinutes;
            IERC20(IContract(contractAddress).token()).safeTransferFrom(address(msg.sender), address(this), price);
            uint valuepoolShare = IContract(contractAddress).valuepoolShare();
            uint adminShare = IContract(contractAddress).adminShare();
            valuepool += price * valuepoolShare / 10000;
            if (_billId > 0) {
                treasury += price * adminShare / 10000;
                pendingRevenue[_billId] += price * (10000 - adminShare - valuepoolShare) / 10000;
            } else {
                treasury += price * (10000 - valuepoolShare) / 10000;
            }
            scheduledMedia[currentMediaIdx] = ScheduledMedia({
                amount: _amount,
                message: _message
            });
            _emitAddSponsor(_billId, _sponsor, _tag, _message);
        }
    }

    function _emitAddSponsor(uint _billId, address _sponsor, string memory _tag, string memory _message) internal {
        _scheduledMedia[_billId][_tag].add(currentMediaIdx++);
        updateSponsorMedia(_billId, _tag);
        IBILL(IContract(contractAddress).billMinter()).emitUpdateMiscellaneous(
            2,
            _billId,
            _tag,
            _message,
            0,
            currentMediaIdx,
            _sponsor,
            ""
        );
    }

    function updateSponsorMedia(uint _billId, string memory _tag) public {
        require(channels[_billId][_tag].active_period < block.timestamp, "BILLHH8");
        uint idx = _scheduledMedia[_billId][_tag].at(0);
        channels[_billId][_tag].active_period = block.timestamp + scheduledMedia[idx].amount*minute / minute * minute;
        channels[_billId][_tag].message = scheduledMedia[idx].message;
        if (_scheduledMedia[_billId][_tag].length() > maxNumMedia) {
            _scheduledMedia[_billId][_tag].remove(idx);
        }
    }

    function withdrawTreasury(address _token, uint _amount) external lock {
        address token = IContract(contractAddress).token();
        address devaddr_ = IAuth(contractAddress).devaddr_();
        _token = _token == address(0x0) ? token : _token;
        uint _price = _amount == 0 ? treasury : Math.min(_amount, treasury);
        if (_token == token) {
            treasury -= _price;
            IERC20(_token).safeTransfer(devaddr_, _price);
        } else {
            IERC20(_token).safeTransfer(devaddr_, erc20(_token).balanceOf(address(this)));
        }
    }

    function claimValuepoolRevenue() external {
        require(msg.sender == IAuth(contractAddress).devaddr_(), "BILLHH9");
        IERC20(IContract(contractAddress).token()).safeTransfer(valuepoolAddress, valuepool);
        valuepool = 0;
    }

    function updateCategory(address _bill, uint _category) external {
        require(IAuth(_bill).isAdmin(msg.sender), "BILLHH14");
        categories[_bill] = _category;
    }

    function updateMaxNumMedia(uint _maxNumMedia) external {
        require(IAuth(contractAddress).devaddr_() == msg.sender, "BILLHH5");
        maxNumMedia = _maxNumMedia;
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }
    
    function updateUriGenerator(address _bill, address _uriGenerator) external {
        require(IAuth(_bill).isAdmin(msg.sender), "BILLHH8");
        uriGenerator[_bill] = _uriGenerator;
    }
}

contract BILLFactory {
    address contractAddress;

    constructor(address _contractAddress) {
        contractAddress = _contractAddress;
    }

    function createGauge(
        uint _profileId,
        address _devaddr,
        bool _isPayable
    ) external {
        address _billMinter = IContract(contractAddress).billMinter();
        address last_gauge = address(new BILL(
            _devaddr,
            _billMinter,
            contractAddress,
            _isPayable
        ));
        IBILL(_billMinter).updateGauge(
            last_gauge, 
            _devaddr, 
            _profileId
        );
    }
}
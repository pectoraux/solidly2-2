// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Library.sol";

// Gauges are used to incentivize pools, they emit reward tokens over 7 days for staked LP tokens
contract ARP {
    using SafeERC20 for IERC20;

    uint public bountyRequired;
    bool public profileRequired;
    uint public bufferTime;
    uint public adminCreditShare;
    uint public adminDebitShare;
    bool public immutable automatic;
    bool public immutable percentages;
    address public immutable _ve;
    address public immutable valuepool;
    bool public immutable immutableContract;
    uint public adminBountyRequired;
    uint public period = 86400 * 7 * 30; // 1 month
    address contractAddress;
    mapping(uint => bool) public isAutoChargeable;
    mapping(address => uint) public adminBountyId;
    mapping(uint => Divisor) public penaltyDivisor;
    mapping(uint => Divisor) public discountDivisor;
    mapping(address => uint) public addressToProtocolId;
    mapping(uint => address) public taxContract;
    mapping(address => uint) public pendingRevenue;
    mapping(uint => uint) public userPercentile;
    mapping(address => uint) public totalPercentile;
    uint public maxNotesPerProtocol = 1;

    struct ProtocolInfo {
        address token;
        uint bountyId;
        uint profileId;
        uint tokenId;
        uint amountPayable;
        uint amountReceivable;
        uint paidPayable;
        uint paidReceivable;
        uint periodPayable;
        uint periodReceivable;
        uint startPayable;
        uint startReceivable;
    }
    address public devaddr_;
    address private helper;
    uint public collectionId;
    mapping(uint => uint) public optionId;
    mapping(uint => string) public description;
    mapping(uint => string) public media;
    mapping(uint => ProtocolInfo) public protocolInfo;
    mapping(address => uint) public totalProcessed;
    mapping(address => uint) public reward;
    mapping(address => uint) public debt;
    mapping(uint => uint) public userBountyRequired;
    mapping(address => bool) public isAdmin;
    mapping(address => uint) public cap;

    constructor(
        address _devaddr,
        address _helper,
        address _valuepool,
        address __contractAddress,
        bool _automatic,
        bool _percentages,
        bool _immutableContract
    ) {
        automatic = _automatic;
        percentages = _percentages;
        valuepool = _valuepool;
        helper = _helper;
        devaddr_ = _devaddr;
        isAdmin[devaddr_] = true;
        contractAddress = __contractAddress;
        _ve = _valuepool != address(0x0) ? IValuePool(_valuepool)._ve() : address(0x0);
        immutableContract = _immutableContract;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender]);
        _;
    }

    modifier onlyDev() {
        require(devaddr_ == msg.sender || 
        (collectionId > 0 && collectionId == IMarketPlace(IContract(contractAddress).marketCollections())
        .addressToCollectionId(msg.sender)));
        _;
    }

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
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

    function updateParameters(
        bool _profileRequired,
        uint _bountyRequired,
        uint _collectionId,
        uint _bufferTime,
        uint _maxNotesPerProtocol,
        uint _adminBountyRequired,
        uint _adminCreditShare,
        uint _adminDebitShare,
        uint _period
    ) external onlyAdmin {
        require(adminCreditShare + IARP(_note()).tradingFee(true) <= 10000);
        require(adminDebitShare + IARP(_note()).tradingFee(false) <= 10000);
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
        if (_collectionId > 0 && devaddr_ == msg.sender) {
            collectionId = IMarketPlace(IContract(contractAddress).marketCollections())
            .addressToCollectionId(msg.sender);
        }
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

    function _minter() internal view returns(address) {
        return IContract(contractAddress).arpMinter();
    }

    function _trustBounty() internal view returns(address) {
        return IContract(contractAddress).trustBounty();
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || helper == msg.sender);
        contractAddress = _contractAddress;
        helper = IContract(_contractAddress).arpNote();
    }

    function _checkIdentityProof(address _owner, uint _identityTokenId) internal {
        if (collectionId > 0) {
            IMarketPlace(IContract(contractAddress).marketHelpers2())
            .checkUserIdentityProof(collectionId, _identityTokenId, _owner);
        }
    }

    function updateProtocol(
        address _owner,
        address _token,
        uint[7] memory _bankInfo, //_amountReceivable, _periodReceivable, _startReceivable, _amountPayable, _periodPayable, _startPayable, _bountyRequired
        uint _identityTokenId,
        uint _protocolId,
        uint _optionId,
        string memory _media,
        string memory _description
    ) external onlyAdmin {
        if(_protocolId == 0) {
            _checkIdentityProof(_owner, _identityTokenId);
            _protocolId = IARP(helper).mint(_owner);
            protocolInfo[_protocolId].startReceivable = block.timestamp + _bankInfo[2];
            protocolInfo[_protocolId].amountReceivable = _bankInfo[0];
            protocolInfo[_protocolId].periodReceivable = _bankInfo[1];
            protocolInfo[_protocolId].startPayable = block.timestamp + _bankInfo[5];
            protocolInfo[_protocolId].amountPayable = _bankInfo[3];
            protocolInfo[_protocolId].periodPayable = _bankInfo[4];
            protocolInfo[_protocolId].token = _token;
            userBountyRequired[_protocolId] = Math.max(bountyRequired, _bankInfo[6]);
            optionId[_protocolId] = _optionId;
            addressToProtocolId[_owner] = _protocolId;
        }
        media[_protocolId] = _media;
        description[_protocolId] = _description;
        
        IARP(helper).emitUpdateProtocol(
            _protocolId,
            _optionId,
            _token,
            _owner, 
            _media,
            _description
        );
    }

    function updateBounty(uint _bountyId, uint _tokenId) external {
        address trustBounty = _trustBounty();
        (address owner,address _token,,address claimableBy,,,,,,) = 
        ITrustBounty(trustBounty).bountyInfo(_bountyId);
        if (isAdmin[msg.sender]) {
            require(owner == msg.sender && claimableBy == address(0x0), "ARP1");
            address note = _note();
            if (_bountyId > 0) {
                IARP(note).attach(_bountyId);
            } else if (_bountyId == 0 && adminBountyId[_token] > 0) {
                IARP(note).detach(_bountyId);
            }
            adminBountyId[_token] = _bountyId;
        } else {
            require(owner == msg.sender && 
                ve(_minter()).ownerOf(_tokenId) == msg.sender &&
                _token == protocolInfo[_tokenId].token && 
                claimableBy == devaddr_, 
                "ARP2"
            );
            protocolInfo[_tokenId].bountyId = _bountyId;
        }
    }

    function updateAutoCharge(bool _autoCharge, uint _tokenId) external {
        require(ve(_minter()).ownerOf(_tokenId) == msg.sender, "ARP3");
        isAutoChargeable[_tokenId] = _autoCharge;
        IARP(helper).emitUpdateAutoCharge(
            _tokenId,
            _autoCharge
        );
    }

    function getReceivable(uint _protocolId, uint _numPeriods) public view returns(uint,uint) {
        uint _optionId = optionId[_protocolId];
        (uint dueReceivable,,int secondsReceivable) = IARP(_note()).getDueReceivable(address(this), _protocolId, _numPeriods);
        if (secondsReceivable > 0) {
            uint _factor = Math.min(penaltyDivisor[_optionId].cap, (uint(secondsReceivable) / Math.max(1,penaltyDivisor[_optionId].period)) * penaltyDivisor[_optionId].factor);
            uint _penalty = dueReceivable * _factor / 10000; 
            return (dueReceivable + _penalty, dueReceivable);
        } else {
            uint _factor = Math.min(discountDivisor[_optionId].cap, (uint(-secondsReceivable) / Math.max(1,discountDivisor[_optionId].period)) * discountDivisor[_optionId].factor);
            uint _discount = Math.max(dueReceivable, protocolInfo[_protocolId].amountReceivable) * _factor / 10000; 
            return (
                dueReceivable > _discount ? dueReceivable - _discount : 0,
                dueReceivable
            );
        }
    }

    function _getFees(uint _value, address token, bool _credit) internal view returns(uint payswapFees,uint adminFees) {
        address note = _note();
        payswapFees = Math.min(
            _value * IARP(note).tradingFee(_credit) / 10000, 
            IContract(contractAddress).cap(token) > 0 
            ? IContract(contractAddress).cap(token) : type(uint).max
        );
        uint _share = _credit ? adminCreditShare : adminDebitShare;
        adminFees = Math.min(
            _value * _share / 10000, 
            cap[token] > 0 ? cap[token] : type(uint).max
        );
    }

    function _processPaid(uint _due, uint _protocolId) internal {
        (uint payswapFees,uint adminFees) = _getFees(_due, protocolInfo[_protocolId].token, true);
        protocolInfo[_protocolId].paidReceivable += (_due - payswapFees - adminFees);
    }

    function autoCharge(uint[] memory _tokenIds, uint _numPeriods) public lock {
        for (uint i = 0; i < _tokenIds.length; i++) {
            if (isAdmin[msg.sender]) require(isAutoChargeable[_tokenIds[i]], "ARP4");
            (uint _price, uint _due) = getReceivable(_tokenIds[i], _numPeriods);
            address token = protocolInfo[_tokenIds[i]].token;
            (uint payswapFees,uint adminFees) = _getFees(_price, token, true);
            address _user = isAdmin[msg.sender] ? ve(helper).ownerOf(_tokenIds[i]) : msg.sender;
            IERC20(token).safeTransferFrom(ve(helper).ownerOf(_tokenIds[i]), address(this), _price);
            IERC20(token).safeTransfer(helper, payswapFees);
            IARP(helper).notifyFees(token, payswapFees);
            totalProcessed[token] += _price;
            _processPaid(_due, _tokenIds[i]);
            if(taxContract[_tokenIds[i]] != address(0x0)) {
                IBILL(taxContract[_tokenIds[i]]).notifyDebit(address(this), ve(_minter()).ownerOf(_tokenIds[i]), _price);
            }
            _processAdminFees(_tokenIds[i], adminFees, token);
            IARP(helper).emitAutoCharge(
                _user,
                _tokenIds[i], 
                protocolInfo[_tokenIds[i]].paidReceivable
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

    function payInvoicePayable(uint _protocolId, uint _numPeriods) public lock {
        require(
            addressToProtocolId[msg.sender] == _protocolId || isAdmin[msg.sender], 
            "ARP5"
        );
        address note = _note();
        address token = protocolInfo[_protocolId].token;
        (uint duePayable,,) = IARP(note).getDuePayable(address(this), _protocolId, _numPeriods);
        uint _balanceOf = erc20(token).balanceOf(address(this));
        if (isAdmin[msg.sender] && _balanceOf < duePayable) {
            IERC20(token).safeTransferFrom(msg.sender, address(this), duePayable - _balanceOf);
            _balanceOf = erc20(token).balanceOf(address(this));
        }
        uint _toPay = _balanceOf < duePayable ? _balanceOf : duePayable;
        protocolInfo[_protocolId].paidPayable += _toPay;
        (uint payswapFees,uint adminFees) = _getFees(_toPay, token, false);
        totalProcessed[token] += _toPay;
        pendingRevenue[token] += adminFees;
        if(taxContract[_protocolId] != address(0x0)) {
            IBILL(taxContract[_protocolId]).notifyCredit(address(this), ve(_minter()).ownerOf(_protocolId), _toPay);
        }
        _processAdminFees(_protocolId, adminFees, token);
        IERC20(token).safeTransfer(helper, payswapFees);
        IWorld(helper).notifyFees(token, payswapFees);
        _toPay -= (adminFees + payswapFees);
        erc20(token).approve(note, _toPay);
        IARP(note).safeTransferWithBountyCheck(
            token,
            ve(helper).ownerOf(_protocolId),
            _protocolId,
            _toPay
        );
        IARP(helper).emitPayInvoicePayable(_protocolId, _toPay);
    }
    
    function _note() internal view returns(address) {
        return IContract(contractAddress).arpNote();
    }

    function updateTaxContract(address _taxContract) external {
        taxContract[addressToProtocolId[msg.sender]] = _taxContract;
    }

    function updateProfile() external {
        protocolInfo[addressToProtocolId[msg.sender]].profileId = 
        IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender);
    }

    function updateTokenId(uint _tokenId) external {
        require(ve(_ve).ownerOf(_tokenId) == msg.sender, "ARP7");
        uint _protocolId = addressToProtocolId[msg.sender];
        if (protocolInfo[_protocolId].tokenId == 0) {
            protocolInfo[_protocolId].tokenId = _tokenId;
            uint _userPercentile = IValuePool(IContract(contractAddress).valuepoolHelper()).getUserPercentile(valuepool, _tokenId);
            userPercentile[_tokenId] = _userPercentile;
            totalPercentile[protocolInfo[_protocolId].token] += _userPercentile;
        }
    }

    function updateUserPercentiles(uint[] memory _tokenIds) external returns(uint) {
        for (uint i = 0; i < _tokenIds.length; i++) {
            _updateUserPercentile(_tokenIds[i]);
        }
    }

    function _updateUserPercentile(uint _tokenId) internal returns(uint) {
        uint _protocolId = addressToProtocolId[ve(_minter()).ownerOf(_tokenId)];
        uint _userPercentile = IValuePool(IContract(contractAddress).valuepoolHelper()).getUserPercentile(valuepool, _tokenId);
        if (_userPercentile < totalPercentile[protocolInfo[_protocolId].token]) {
            totalPercentile[protocolInfo[_protocolId].token] -= _userPercentile;
        } else {
            totalPercentile[protocolInfo[_protocolId].token] = 0;
        }
        totalPercentile[protocolInfo[_protocolId].token] += _userPercentile;
    }

    function getUserPercentile(address _token, uint _tokenId) external view returns(uint) {
        uint _userPercentile = IValuePool(IContract(contractAddress).valuepoolHelper()).getUserPercentile(valuepool, _tokenId);
        return _userPercentile*100 / totalPercentile[_token];
    }

    function updateOwner(address _prevOwner, uint _protocolId) external {
        require(ve(_minter()).ownerOf(_protocolId) == msg.sender, "ARP8");
        addressToProtocolId[msg.sender] = _protocolId;
        delete addressToProtocolId[_prevOwner];
    }

    function updatePaidPayable(uint _protocolId, uint _num) external {
        if(msg.sender == helper) {
            protocolInfo[_protocolId].paidPayable += _num;
            if(taxContract[_protocolId] != address(0x0)) {
                IBILL(taxContract[_protocolId]).notifyCredit(address(this), ve(_minter()).ownerOf(_protocolId), _num);
            }
        } else if (isAdmin[msg.sender] && !immutableContract) {
            protocolInfo[_protocolId].paidPayable += protocolInfo[_protocolId].amountPayable * _num;
        }
    }

    function deleteProtocol (uint _protocolId) public onlyAdmin {
        IARP(helper).burn(_protocolId);
        delete protocolInfo[_protocolId];
        IARP(helper).emitDeleteProtocol(_protocolId);
    }

    function withdraw(address _token, uint amount) external onlyAdmin {
        require(pendingRevenue[_token] >= amount, "ARP9");
        pendingRevenue[_token] -= amount;
        address note = _note();
        erc20(_token).approve(note, amount);
        IARP(note).safeTransferWithBountyCheck(_token, msg.sender, 0, amount);
    
        IARP(helper).emitWithdraw(msg.sender, amount);
    }

    function noteWithdraw(address _to, address _token, uint amount) external {
        require(msg.sender == _note(), "ARP10");
        IERC20(_token).safeTransfer(_to, amount);     
    }

    function notifyReward(address _token, uint _amount) external {
        notifyRewardAmount(_token, msg.sender, _amount);
    }

    function notifyRewardAmount(address _token, address _from, uint _amount) public {
        try IERC721(_token).supportsInterface(0x80ac58cd) {
            IERC721(_token).safeTransferFrom(msg.sender, devaddr_, _amount);
        } catch {
            IERC20(_token).safeTransferFrom(_from, address(this), _amount);
            reward[_token] += _amount;
        }
        IARP(helper).emitNotifyReward(_token, _amount);
    }

    function notifyDebt(address _token, uint _amount) external onlyAdmin {
        debt[_token] += _amount;
    }
}

contract ARPHelper is ERC721Pausable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct MintInfo {
        address arp;
        uint extraMint;
    }
    mapping(uint => MintInfo) public tokenIdToARP;
    mapping(uint => uint) public tokenIdToParent;
    uint public tokenId = 1;
    EnumerableSet.AddressSet private gauges;
    mapping(uint => address) public profiles;
    address private contractAddress;
    mapping(address => uint) public treasuryFees;
    mapping(address => uint) public addressToProfileId;
    
    event Voted(address indexed arp, uint profileId, uint likes, uint dislikes, bool like);
    event UpdateAutoCharge(uint indexed protocolId, address arp, bool isAutoChargeable);
    event AutoCharge(uint indexed protocolId, address from, address arp, uint paidReceivable);
    event PayInvoicePayable(address arp, uint protocolId, uint toPay);
    event DeleteProtocol(uint indexed protocolId, address arp);
    event Withdraw(address indexed from, address arp, uint amount);
    event TransferDueToNote(address arp, uint protocolId, uint tokenId, uint due, bool adminNote);
    event ClaimTransferNote(uint tokenId);
    event UpdateMiscellaneous(
        uint idx, 
        uint arpId, 
        string paramName, 
        string paramValue, 
        uint paramValue2, 
        uint paramValue3, 
        address sender,
        address paramValue4,
        string paramValue5
    );
    event UpdateProtocol(address arp, uint protocolId, uint optionId, address token, address owner, string media, string description);
    event CreateARP(address arp, address _user, uint profileId);
    event NotifyReward(address token, uint amount);
    event DeleteARP(address arp);

    constructor() ERC721("Electronic ARP Cheque", "eaCheque")  {}

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender, "NT2");
        contractAddress = _contractAddress;
    }

    function setContractAddressAt(address _arp) external {
        IMarketPlace(_arp).setContractAddress(contractAddress);
    }

    function verifyNFT(uint _tokenId, uint _collectionId, string memory item) external view returns(uint) {
        if (
            IARP(tokenIdToARP[_tokenId].arp).collectionId() == _collectionId &&
            (
                keccak256(abi.encodePacked(item)) == keccak256(abi.encodePacked("")) ||
                keccak256(abi.encodePacked(item)) == keccak256(abi.encodePacked(IARP(tokenIdToARP[_tokenId].arp).description(_tokenId)))
            )
        ) {
            return 1;
        }
        return 0;
    }

    function mint(address _to) external returns(uint) {
        require(gauges.contains(msg.sender), "ARPHH10");
        _safeMint(_to, tokenId, msg.data);
        tokenIdToARP[tokenId].arp = msg.sender;
        return tokenId++;
    }

    function burn(uint _tokenId) external {
        require(gauges.contains(msg.sender) || ownerOf(_tokenId) == msg.sender, "ARPHH6");
        _burn(_tokenId);
        delete tokenIdToParent[_tokenId];
        delete tokenIdToARP[_tokenId];
    }

    function mintExtra(uint _tokenId, uint _extraMint) external returns(uint) {
        require(ownerOf(_tokenId) == msg.sender, "ARPHH11");
        require(tokenIdToARP[_tokenId].extraMint >= _extraMint, "ARPHH12");
        for (uint i = 0; i < _extraMint; i++) {
            _safeMint(msg.sender, tokenId, msg.data);
            tokenIdToParent[tokenId++] = _tokenId;
        }
        tokenIdToARP[_tokenId].extraMint -= _extraMint;
        return tokenId;
    }

    function updateMintInfo(address _arp, uint _extraMint, uint _tokenId) external {
        require(tokenIdToARP[_tokenId].arp == _arp && IAuth(_arp).isAdmin(msg.sender), "ARPHH13");
        tokenIdToARP[_tokenId].arp = msg.sender;
        tokenIdToARP[_tokenId].extraMint += _extraMint;
    }

    function emitVoted(address _arp, uint _profileId, uint likes, uint dislikes, bool like) external {
        require(IContract(contractAddress).arpMinter() == msg.sender, "ARPH1");
        emit Voted(_arp, _profileId, likes, dislikes, like);
    }

    function notifyFees(address _token, uint _fees) external {
        require(gauges.contains(msg.sender) || msg.sender == IContract(contractAddress).arpNote(), "ARPH2");        
        treasuryFees[_token] += _fees;
    }

    function getAllARPs(uint _start) external view returns(address[] memory arps) {
        arps = new address[](gauges.length() - _start);
        for (uint i = _start; i < gauges.length(); i++) {
            arps[i] = gauges.at(i);
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
        uint _percentile = IARP(IContract(contractAddress).arpMinter()).percentiles(profiles[_ssidAuditorProfileId]);
        return (
            profiles[_ssidAuditorProfileId],
            _getColor(_percentile)
        );
    }

    function isGauge(address _arp) external view returns(bool) {
        return gauges.contains(_arp);
    }

    function isLender(address _arp, address _ve, uint _minAdminPeriod, uint _minAdminBounty) external view returns(bool) {
        return gauges.contains(_arp) && 
               IARP(_arp)._ve() == _ve && 
               IARP(_arp).automatic() && 
               IARP(_arp).adminBountyRequired() >= _minAdminBounty &&
               IARP(_arp).period() >= _minAdminPeriod;
    }
    
    function updateGauge(
        address _last_gauge,
        address _user,
        uint _profileId
    ) external {
        require(msg.sender == IContract(contractAddress).arpFactory(), "ARPH3");
        require(IProfile(IContract(contractAddress).profile()).addressToProfileId(_user) == _profileId && _profileId > 0, "ARPH4");
        gauges.add(_last_gauge);
        profiles[_profileId] = _last_gauge;
        addressToProfileId[_last_gauge] = _profileId;
        emit CreateARP(_last_gauge, _user, _profileId);
    }
    
    function deleteARP(address _arp) external {
        require(msg.sender == IAuth(contractAddress).devaddr_() || IAuth(_arp).isAdmin(msg.sender));
        gauges.remove(_arp);
        emit DeleteARP(_arp);
    }

    function emitNotifyReward(address _token, uint _amount) external {
        require(gauges.contains(msg.sender));
        emit NotifyReward(_token, _amount);
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
        uint _arpId, 
        string memory paramName, 
        string memory paramValue, 
        uint paramValue2, 
        uint paramValue3,
        address paramValue4,
        string memory paramValue5
    ) external {
        emit UpdateMiscellaneous(
            _idx, 
            _arpId, 
            paramName, 
            paramValue, 
            paramValue2, 
            paramValue3, 
            msg.sender,
            paramValue4,
            paramValue5
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

    function emitTransferDueToNote(address _arp, uint _protocolId, uint _tokenId, uint _amount, bool _adminNote) external {
        require(IContract(contractAddress).arpNote() == msg.sender);
        emit TransferDueToNote(_arp, _protocolId, _tokenId, _amount, _adminNote);
    }

    function emitClaimTransferNote(uint _tokenId) external {
        require(IContract(contractAddress).arpNote() == msg.sender);
        emit ClaimTransferNote(_tokenId);
    }

    function withdrawFees(address _token) external returns(uint _amount) {
        require(msg.sender == IAuth(contractAddress).devaddr_(), "ARPH13");
        _amount = treasuryFees[_token];
        IERC20(_token).safeTransfer(msg.sender, _amount);
        treasuryFees[_token] = 0;
        return _amount;
    }

    function tokenURI(uint __tokenId) public view virtual override returns (string memory output) {
        address minter = IContract(contractAddress).arpMinter();
        uint _tokenId = tokenIdToParent[__tokenId] == 0 ? __tokenId : tokenIdToParent[__tokenId];
        address _uriGenerator = IARP(minter).uriGenerator(tokenIdToARP[_tokenId].arp);
        if (_uriGenerator != address(0x0)) {
            output = IARP(_uriGenerator).uri(__tokenId);
        } else {
            output = _tokenURI(__tokenId);
        }
    }

    function _getOptions(address _arp, uint _protocolId, COLOR _color) internal view returns(string[] memory optionNames, string[] memory optionValues) {
        // (,uint _bountyId,uint _profileId,uint _tokenId,uint _amountPayable,uint _amountReceivable,uint _paidPayable,uint _paidReceivable,uint _periodPayable,uint _periodReceivable,,) = IARP(_arp).protocolInfo(_protocolId);
        ARPInfo memory _p = IARP(_arp).protocolInfo(_protocolId);
        optionNames = new string[](9);
        optionValues = new string[](9);
        uint idx;
        uint decimals = uint(IMarketPlace(_p.token).decimals());
        optionNames[idx] = "ARP Color";
        optionValues[idx++] = _color == COLOR.GOLD 
        ? "Gold" 
        : _color == COLOR.SILVER 
        ? "Silver"
        : _color == COLOR.BROWN
        ? "Brown"
        : "Black";
        optionNames[idx] = "ARPID";
        optionValues[idx++] = toString(addressToProfileId[_arp]);
        optionNames[idx] = "UBID";
        optionValues[idx++] = toString(_p.bountyId);
        optionNames[idx] = "Profile ID";
        optionValues[idx++] = toString(_p.profileId);
        optionNames[idx] = "VeNFT ID";
        optionValues[idx++] = toString(_p.tokenId);
        optionNames[idx] = "Payable";
        optionValues[idx++] = string(abi.encodePacked(toString(_p.amountPayable/10**decimals), " " , IMarketPlace(_p.token).symbol()));
        optionNames[idx] = "Receivable";
        optionValues[idx++] = string(abi.encodePacked(toString(_p.amountReceivable/10**decimals), " " , IMarketPlace(_p.token).symbol()));
        optionNames[idx] = "PP/PR";
        optionValues[idx++] = string(abi.encodePacked(toString(_p.paidPayable/10**decimals), ", " , toString(_p.paidReceivable/10**decimals)));
        optionNames[idx] = "TP/TR";
        optionValues[idx++] = string(abi.encodePacked(toString(_p.periodPayable), ", " , toString(_p.periodReceivable)));
    }

    function _tokenURI(uint __tokenId) internal view returns(string memory output) {
        uint _tokenId = tokenIdToParent[__tokenId] == 0 ? __tokenId : tokenIdToParent[__tokenId];
        address _arp = tokenIdToARP[_tokenId].arp;
        uint _percentile = IARP(IContract(contractAddress).arpMinter()).percentiles(profiles[addressToProfileId[_arp]]);
        (string[] memory optionNames, string[] memory optionValues) = _getOptions(_arp, _tokenId, _getColor(_percentile));
        string[] memory description = new string[](1);
        description[0] = IARP(_arp).description(_tokenId);
        
        output = IMarketPlace(IContract(contractAddress).nftSvg()).constructTokenURI(
            __tokenId,
            '',
            _arp,
            ownerOf(_tokenId),
            ownerOf(__tokenId),
            address(0x0),
            IARP(IContract(contractAddress).arpMinter()).getMedia(_arp, _tokenId),
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

contract ARPNote is ERC721Pausable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct ARPContractNote {
        uint due;
        uint timer;
        uint protocolId;
        uint payswapFees;
        address arp;
        address token;
    }
    mapping(address => bool) public dueBeforePayable;
    mapping(uint => mapping(address => uint)) public activePeriod;
    mapping(uint => mapping(address => uint)) public balances;
    mapping(uint => ARPContractNote) public notes;
    mapping(uint => uint) public pendingRevenueFromNote;
    uint public tokenId = 1;
    uint private tradingFeeCredit = 100;
    uint private tradingFeeDebit = 100;
    address private contractAddress;
    uint public bufferTime;
    uint public minAdminPeriod;
    uint public minAdminBounty;
    mapping(uint => uint) public notesPerProtocol;
    mapping(uint => uint) public adminNotes;
    mapping(address => bool) public noChargeContracts;
    
    constructor(address _contractAddress) ERC721("ARPNote", "nARP")  {
        contractAddress = _contractAddress;
    }

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    // function setContractAddress(address _contractAddress) external {
    //     require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
    //     contractAddress = _contractAddress;
    // }

    function attach(uint _bountyId) external {
        require(IARP(IContract(contractAddress).arpHelper()).isGauge(msg.sender));
        ITrustBounty(IContract(contractAddress).trustBountyHelper()).attach(_bountyId);
    }

    function detach(uint _bountyId) external {
        require(IARP(IContract(contractAddress).arpHelper()).isGauge(msg.sender));
        ITrustBounty(IContract(contractAddress).trustBountyHelper()).detach(_bountyId);
    }

    function updateNoChargeContracts(address _contract, bool _add) external {
        require(msg.sender == IAuth(contractAddress).devaddr_());
        noChargeContracts[_contract] = _add;
    }

    function tradingFee(bool _credit) external view returns(uint) {
        if (noChargeContracts[msg.sender]) return 0;
        return _credit ? tradingFeeCredit : tradingFeeDebit;
    }

    function updatePendingRevenueFromNote(uint _tokenId, uint _paid) external {
        require(IARP(IContract(contractAddress).arpHelper()).isGauge(msg.sender));
        notes[tokenId].due -= _paid;
        pendingRevenueFromNote[_tokenId] += _paid;
    }

    function updateParams(
        uint _tradingFeeCredit,
        uint _tradingFeeDebit, 
        uint _minAdminBounty, 
        uint _minAdminPeriod,
        uint _bufferTime
    ) external {
        require(msg.sender == IAuth(contractAddress).devaddr_(), "ARPH12");
        tradingFeeCredit = _tradingFeeCredit;
        tradingFeeDebit = _tradingFeeDebit;
        bufferTime = _bufferTime;
        minAdminBounty = _minAdminBounty;
        minAdminPeriod = _minAdminPeriod;
    }

    function _getUserPercentile(address _arp, address _token, uint _tokenId) internal view returns(uint) {
        return _tokenId == 0 ? 0 : IARP(_arp).getUserPercentile(_token, _tokenId);
    }

    function getNumPeriods(uint tm1, uint tm2, uint _period) internal pure returns(uint) {
        // if (tm2 == 0) tm2 = block.timestamp;
        if (tm1 == 0 || tm2 == 0 || tm2 < tm1) return 0;
        return _period > 0 ? (tm2 - tm1) / _period : 1;
    }

    function getDueReceivable(address _arp, uint _protocolId, uint _numExtraPeriods) public view returns(uint, uint, int) {
        // (address token,,,uint _tokenId,,uint amountReceivable,,uint paidReceivable,,uint periodReceivable,,uint startReceivable) =
        ARPInfo memory p = IARP(_arp).protocolInfo(_protocolId);
        uint due;
        uint amountReceivable = p.amountReceivable;
        uint numPeriods = getNumPeriods(p.startReceivable, block.timestamp, p.periodReceivable);
        // uint numPeriods = Math.max(1, p.paidReceivable / amountReceivable);
        uint nextDue = p.startReceivable + p.periodReceivable * numPeriods;
        if (IARP(_arp).percentages()) {
            if (IARP(_arp).automatic()) {
                amountReceivable = _getUserPercentile(_arp, p.token, p.tokenId);
            }
            due = _getDue(IARP(_arp).debt(p.token), nextDue, amountReceivable, p.paidReceivable);
        } else {
            numPeriods += _numExtraPeriods;
            due = nextDue < block.timestamp ? amountReceivable * numPeriods - p.paidReceivable : 0;
        }
        return (
            due, // due
            nextDue, // next
            int(block.timestamp) - int(nextDue) //late or seconds in advance
        );
    }

    function _getDue(uint total, uint nextDue, uint amount, uint paid) internal view returns(uint) {
        return nextDue < block.timestamp ? (total * amount / 10000) - paid : 0;
    }

    function getDuePayable(address _arp, uint _protocolId, uint _numExtraPeriods) public view returns(uint, uint, int) {
        // (address token,,,uint _tokenId,uint amountPayable,,uint paidPayable,,uint periodPayable,,uint startPayable,) = 
        ARPInfo memory p = IARP(_arp).protocolInfo(_protocolId);
        uint amountPayable = p.amountPayable;
        uint nextDue;
        uint due;
        uint numPeriods = getNumPeriods(p.startPayable, block.timestamp, p.periodPayable);
        // uint numPeriods = p.paidPayable / amountPayable;
        nextDue = p.startPayable + p.periodPayable * Math.min(1, numPeriods);
        if (IARP(_arp).percentages()) {
            if (IARP(_arp).automatic()) {
                amountPayable = _getUserPercentile(_arp, p.token, p.tokenId);
            }
            due = _getDue(IARP(_arp).reward(p.token), nextDue, amountPayable, p.paidPayable);
        } else {
            numPeriods += _numExtraPeriods;
            due = nextDue < block.timestamp ? amountPayable * numPeriods - p.paidPayable : 0;
        }
        return (
            due, // due
            nextDue, // next
            int(block.timestamp) - int(nextDue) //late or seconds in advance
        );
    }
    
    function transferDueToNoteReceivable(
        address _arp,
        address _to, 
        uint _protocolId, 
        uint _numPeriods
    ) external lock {
        (uint dueReceivable, uint nextDue,) = getDueReceivable(_arp, _protocolId, _numPeriods);
        require(
            // dueReceivable > 0 && 
            IAuth(_arp).isAdmin(msg.sender), "ARPH7");
        // (address _token,,,,,,,,,,,) = IARP(_arp).protocolInfo(_protocolId);
        ARPInfo memory p = IARP(_arp).protocolInfo(_protocolId);
        uint adminFees = Math.min(
            dueReceivable * IARP(_arp).adminCreditShare() / 10000, 
            IARP(_arp).cap(p.token) > 0 ? IARP(_arp).cap(p.token) : type(uint).max
        );
        _beforeTransferCheck(_arp, p.token, 0, adminFees);
        adminNotes[_protocolId] = tokenId;
        notes[tokenId] = ARPContractNote({
            due: adminFees,
            token: p.token,
            timer: nextDue,
            protocolId: _protocolId,
            arp: _arp,
            payswapFees: 0
        });
        _safeMint(_to, tokenId, msg.data);
        IARP(IContract(contractAddress).arpHelper()).
        emitTransferDueToNote(_arp, _protocolId, tokenId++, adminFees, true);
    }
    
    function transferDueToNotePayable(
        address _arp,
        address _to, 
        uint _protocolId,
        uint _numPeriods
    ) external lock {
        require(ve(IContract(contractAddress).arpHelper()).ownerOf(_protocolId) == msg.sender, "ARPH8");
        require(notesPerProtocol[_protocolId] + _numPeriods <= IARP(_arp).maxNotesPerProtocol());
        (uint duePayable, uint nextDue,) = getDuePayable(_arp, _protocolId, _numPeriods);
        // (address _token,,,,,,,,,,,) = IARP(_arp).protocolInfo(_protocolId);
        ARPInfo memory p = IARP(_arp).protocolInfo(_protocolId);
        uint adminFees = Math.min(
            duePayable * IARP(_arp).adminDebitShare() / 10000, 
            IARP(_arp).cap(p.token) > 0 ? IARP(_arp).cap(p.token) : type(uint).max
        );
        uint payswapFees = Math.min(
            duePayable * tradingFeeDebit / 10000, 
            IContract(contractAddress).cap(p.token) > 0 
            ? IContract(contractAddress).cap(p.token) : type(uint).max
        );
        duePayable -= (adminFees + payswapFees);
        require(duePayable > 0, "ARPH9");
        _beforeTransferCheck(_arp, p.token, _protocolId, duePayable);
        notesPerProtocol[_protocolId] += _numPeriods;
        notes[tokenId] = ARPContractNote({
            due: duePayable,
            token: p.token,
            timer: nextDue,
            payswapFees: payswapFees,
            arp: _arp,
            protocolId: _protocolId
        });
        IARP(_arp).updatePaidPayable(_protocolId, duePayable);
        _safeMint(_to, tokenId, msg.data);
        IARP(IContract(contractAddress).arpHelper()).
        emitTransferDueToNote(_arp, _protocolId, tokenId++, duePayable, false);
    }
    
    function claimPendingRevenueFromNote(uint _tokenId) external lock {
        require(ownerOf(_tokenId) == msg.sender, "ARPH10");
        require(notes[_tokenId].timer <= block.timestamp, "ARPH11");
        uint256 revenueToClaim;
        address arp = notes[_tokenId].arp;
        address token = notes[_tokenId].token;
        if (adminNotes[notes[_tokenId].protocolId] > 0) {
            revenueToClaim = pendingRevenueFromNote[_tokenId];
            delete pendingRevenueFromNote[_tokenId];
            delete adminNotes[notes[_tokenId].protocolId];
        } else {
            require(erc20(notes[_tokenId].token).balanceOf(arp) >= notes[_tokenId].due);
            revenueToClaim = notes[_tokenId].due;
        }
        IARP(arp).noteWithdraw(address(msg.sender), token, revenueToClaim);
        IARP(arp).noteWithdraw(address(this), token, notes[_tokenId].payswapFees);
        address _helper = IContract(contractAddress).arpHelper();
        IARP(_helper).notifyFees(token, notes[_tokenId].payswapFees);
        delete notes[_tokenId];
        _burn(_tokenId);
        IARP(_helper).emitClaimTransferNote(_tokenId);
    }
    
    function _checkBalance(
        address _arp, 
        address _token, 
        uint _protocolId, 
        uint _amount, 
        uint _bountyId,
        uint _bountyRequired
    ) internal {
        address trustBounty = IContract(contractAddress).trustBounty();
        uint _limit = ITrustBounty(trustBounty).getBalance(_bountyId);
        (,,,,,,uint endTime,,,) = ITrustBounty(trustBounty).bountyInfo(_bountyId);
        uint _balance = balances[_protocolId][_token] + _amount;
        if (activePeriod[_protocolId][_token] < block.timestamp) {
            uint _period = IARP(_arp).period();
            activePeriod[_protocolId][_token] = (block.timestamp + _period) / _period * _period;
            _balance = _amount;
            balances[_protocolId][_token] = 0;
        }
        require(_balance * _bountyRequired / 10000 <= _limit, "ARPH14");
        uint _bufferTime = Math.max(bufferTime, IARP(msg.sender).bufferTime());
        require(endTime > block.timestamp + _bufferTime, "ARPH15");
    }

    function _beforeTransferCheck(address _arp, address token, uint _protocolId, uint value) internal {
        if (_protocolId == 0 && IARP(_arp).adminBountyRequired() > 0) {
            uint adminBountyId = IARP(_arp).adminBountyId(token);
            _checkBalance(_arp, token, 0, value, adminBountyId, IARP(_arp).adminBountyRequired());
        } else if (_protocolId > 0 && IARP(_arp).userBountyRequired(_protocolId) > 0) {
            if (dueBeforePayable[_arp]) {
                (uint dueReceivable,,) = getDueReceivable(_arp, _protocolId, 0);
                require(dueReceivable == 0, "ARPH16");
            }
            // (address _token,uint bountyId,,,,,,,,,,) = IARP(_arp).protocolInfo(_protocolId);
            ARPInfo memory p = IARP(_arp).protocolInfo(_protocolId);
            _checkBalance(_arp, p.token, _protocolId, value, p.bountyId, IARP(_arp).userBountyRequired(_protocolId));
        }
    }
    
    function updateDueBeforePayable(address _arp, bool _isTrue) external {
        require(IAuth(_arp).isAdmin(msg.sender), "ARPH17");
        dueBeforePayable[_arp] = _isTrue;
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
        optionValues[idx++] = toString(notes[_tokenId].timer);
        optionNames[idx] = "Amount";
        optionValues[idx++] = string(abi.encodePacked(toString(notes[_tokenId].due/10**decimals), " " ,IMarketPlace(notes[_tokenId].token).symbol()));
        optionNames[idx] = "Expired";
        optionValues[idx++] = notes[_tokenId].timer < block.timestamp ? "Yes" : "No";
        string[] memory _description = new string[](1);
        _description[0] = "This note gives you access to revenues of the arp on the specified protocol";
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

contract ARPMinter {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using Percentile for *; 

    // arp => category
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
    mapping(uint => string) public tags;
    EnumerableSet.UintSet private _allVoters;
    mapping(address => Vote) public votes;
    mapping(address => uint) public percentiles;
    mapping(uint => mapping(address => int)) public voted;
    mapping(address => address) public uriGenerator;
    uint private sum_of_diff_squared;
    address private contractAddress;
    address public valuepoolAddress;
    uint public treasury;
    uint public valuepool;
    
    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function _resetVote(address _arp, uint _profileId) internal {
        if (voted[_profileId][_arp] > 0) {
            votes[_arp].likes -= 1;
        } else if (voted[_profileId][_arp] < 0) {
            votes[_arp].dislikes -= 1;
        }
    }

    function vote(address _arp, uint _profileId, bool like) external {
        require(IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender) == _profileId && _profileId > 0, "ARPHH2");
        SSIData memory metadata = ISSI(IContract(contractAddress).ssi()).getSSID(_profileId);
        require(keccak256(abi.encodePacked(metadata.answer)) != keccak256(abi.encodePacked("")), "ARPHH3");
        _resetVote(_arp, _profileId);        
        if (like) {
            votes[_arp].likes += 1;
            voted[_profileId][_arp] = 1;
        } else {
            votes[_arp].dislikes += 1;
            voted[_profileId][_arp] = -1;
        }
        uint _arpVotes;
        if (votes[_arp].likes > votes[_arp].dislikes) {
            _arpVotes = votes[_arp].likes - votes[_arp].dislikes;
        }
        _allVoters.add(_profileId);
        (uint percentile, uint sods) = Percentile.computePercentileFromData(
            false,
            _arpVotes,
            _allVoters.length(),
            _allVoters.length(),
            sum_of_diff_squared
        );
        sum_of_diff_squared = sods;
        percentiles[_arp] = percentile;
        IARP(IContract(contractAddress).arpHelper())
        .emitVoted(_arp, _profileId, votes[_arp].likes, votes[_arp].dislikes, like);
    }

    function updateValuepool(address _valuepoolAddress) external {
        require(IAuth(contractAddress).devaddr_() == msg.sender, "ARPHH4");
        valuepoolAddress = _valuepoolAddress;
    }
    
    function _helper() internal view returns(address) {
        return IContract(contractAddress).arpHelper();
    }

    function buyWithContract(
        address _arp,
        address _user,
        address _referrer,
        string memory _tokenId,
        uint _numPeriods,
        uint[] memory _protocolIds   
    ) external {
        require(IValuePool(IContract(contractAddress).valuepoolHelper()).isGauge(msg.sender));
        require(IARP(IContract(contractAddress).arpNote()).isGauge(_arp), "WHHH1");
        (uint _price,) = IARP(_arp).getReceivable(_protocolIds[0], _numPeriods);
        // (address _token,,,,,,,,,,,) = IARP(_arp).protocolInfo(_protocolIds[0]);
        ARPInfo memory p = IARP(_arp).protocolInfo(_protocolIds[0]);
        erc20(p.token).approve(_arp, _price);
        IARP(_arp).autoCharge(_protocolIds, _numPeriods);
    }

    function updateTags(address _arp, string memory _tag) external {
        require(IAuth(_arp).isAdmin(msg.sender));
        uint _arpId = IProfile(_helper()).addressToProfileId(_arp);
        tags[_arpId] = _tag;
    }

    function getMedia(address _arp, uint _tokenId) external view returns(string[] memory _media) {
        uint _arpId = IProfile(_helper()).addressToProfileId(_arp);
        string memory _tag = tags[_arpId];
        if (tagRegistrations[_arpId][_tag]) {
            _media = new string[](_scheduledMedia[1][_tag].length() + 1);
            uint idx;
            _media[idx++] = IARP(_arp).media(_tokenId);
            for (uint i = 0; i < _scheduledMedia[1][_tag].length(); i++) {
                uint _currentMediaIdx = _scheduledMedia[1][_tag].at(i);
                _media[idx++] = scheduledMedia[_currentMediaIdx].message;
            }
        } else {
            _media = new string[](_scheduledMedia[_arpId][_tag].length() + 1);
            uint idx;
            _media[idx++] = IARP(_arp).media(_tokenId);
            for (uint i = 0; i < _scheduledMedia[_arpId][_tag].length(); i++) {
                uint _currentMediaIdx = _scheduledMedia[_arpId][_tag].at(i);
                _media[idx++] = scheduledMedia[_currentMediaIdx].message;
            }
        }
    }

    function updateTagRegistration(string memory _tag, bool _add) external {
        address arpHelper = IContract(contractAddress).arpHelper();
        uint _arpId = IProfile(arpHelper).addressToProfileId(msg.sender);
        tagRegistrations[_arpId][_tag] = _add;
        IARP(arpHelper).emitUpdateMiscellaneous(
            1,
            _arpId,
            _tag,
            "",
            _add ? 1 : 0,
            0,
            address(0x0),
            ""
        );
    }

    function updateExcludedContent(string memory _tag, string memory _contentName, bool _add) external {
        uint _arpId = IProfile(IContract(contractAddress).arpHelper()).addressToProfileId(msg.sender);
        if (_add) {
            require(IContent(contractAddress).contains(_contentName), "ARPHH5");
            excludedContents[_arpId][_tag].add(uint(keccak256(abi.encodePacked(_contentName))));
        } else {
            excludedContents[_arpId][_tag].remove(uint(keccak256(abi.encodePacked(_contentName))));
        }
    }

    function getExcludedContents(uint _arpId, string memory _tag) public view returns(string[] memory _excluded) {
        _excluded = new string[](excludedContents[_arpId][_tag].length());
        for (uint i = 0; i < _excluded.length; i++) {
            _excluded[i] = IContent(contractAddress).indexToName(excludedContents[_arpId][_tag].at(i));
        }
    }

    function claimPendingRevenue() external lock {
        uint _arpId = IProfile(IContract(contractAddress).arpHelper()).addressToProfileId(msg.sender);
        IERC20(IContract(contractAddress).token()).safeTransfer(address(msg.sender), pendingRevenue[_arpId]);
        pendingRevenue[_arpId] = 0;
    }
    
    function updatePricePerAttachMinutes(uint _pricePerAttachMinutes) external {
        uint _arpId = IProfile(IContract(contractAddress).arpHelper()).addressToProfileId(msg.sender);
        pricePerAttachMinutes[_arpId] = _pricePerAttachMinutes;
    }

    function sponsorTag(
        address _sponsor,
        address _arp,
        uint _amount, 
        string memory _tag, 
        string memory _message
    ) external {
        uint _arpId = IProfile(IContract(contractAddress).arpHelper()).addressToProfileId(_arp);
        require(IAuth(_sponsor).isAdmin(msg.sender), "ARPHH6");
        require(!ISponsor(_sponsor).contentContainsAny(getExcludedContents(_arpId, _tag)), "ARPHH7");
        uint _pricePerAttachMinutes = pricePerAttachMinutes[_arpId];
        if (_pricePerAttachMinutes > 0) {
            uint price = _amount * _pricePerAttachMinutes;
            IERC20(IContract(contractAddress).token()).safeTransferFrom(address(msg.sender), address(this), price);
            uint valuepoolShare = IContract(contractAddress).valuepoolShare();
            uint adminShare = IContract(contractAddress).adminShare();
            valuepool += price * valuepoolShare / 10000;
            if (_arpId > 0) {
                treasury += price * adminShare / 10000;
                pendingRevenue[_arpId] += price * (10000 - adminShare - valuepoolShare) / 10000;
            } else {
                treasury += price * (10000 - valuepoolShare) / 10000;
            }
            scheduledMedia[currentMediaIdx] = ScheduledMedia({
                amount: _amount,
                message: _message
            });
            _emitAddSponsor(_arpId, _sponsor, _tag, _message);
        }
    }

    function _emitAddSponsor(uint _arpId, address _sponsor, string memory _tag, string memory _message) internal {
        _scheduledMedia[_arpId][_tag].add(currentMediaIdx++);
        updateSponsorMedia(_arpId, _tag);
        IARP(IContract(contractAddress).arpNote()).emitUpdateMiscellaneous(
            2,
            _arpId,
            _tag,
            _message,
            0,
            currentMediaIdx,
            _sponsor,
            ""
        );
    }

    function updateSponsorMedia(uint _arpId, string memory _tag) public {
        require(channels[_arpId][_tag].active_period < block.timestamp, "ARPHH8");
        uint idx = _scheduledMedia[_arpId][_tag].at(0);
        channels[_arpId][_tag].active_period = block.timestamp + scheduledMedia[idx].amount*minute / minute * minute;
        channels[_arpId][_tag].message = scheduledMedia[idx].message;
        if (_scheduledMedia[_arpId][_tag].length() > maxNumMedia) {
            _scheduledMedia[_arpId][_tag].remove(idx);
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
        require(msg.sender == IAuth(contractAddress).devaddr_(), "ARPHH9");
        IERC20(IContract(contractAddress).token()).safeTransfer(valuepoolAddress, valuepool);
        valuepool = 0;
    }

    function updateCategory(address _arp, uint _category) external {
        require(IAuth(_arp).isAdmin(msg.sender), "ARPHH14");
        categories[_arp] = _category;
    }

    function updateMaxNumMedia(uint _maxNumMedia) external {
        require(IAuth(contractAddress).devaddr_() == msg.sender, "ARPHH5");
        maxNumMedia = _maxNumMedia;
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }
    
    function updateUriGenerator(address _arp, address _uriGenerator) external {
        require(IAuth(_arp).isAdmin(msg.sender), "ARPHH8");
        uriGenerator[_arp] = _uriGenerator;
    }

    // function tokenURI(uint __tokenId) external view returns(string memory output) {
    //     address helper = _helper();
    //     uint _tokenId = IARP(helper).tokenIdToParent(__tokenId);
    //     (address _arp,) = IARP(helper).tokenIdToARP(_tokenId);
    //     (string[] memory optionNames, string[] memory optionValues) = _getOptions(_arp, _tokenId);
    //     string[] memory description = new string[](1);
    //     description[0] = IARP(_arp).description(_tokenId);
        
    //     output = IMarketPlace(IContract(contractAddress).nftSvg()).constructTokenURI(
    //         __tokenId,
    //         'ARP',
    //         _arp,
    //         ve(helper).ownerOf(_tokenId),
    //         ve(helper).ownerOf(__tokenId),
    //         address(0x0),
    //         getMedia(_tokenId),
    //         optionNames,
    //         optionValues,
    //         description
    //     );
    // }

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

contract ARPFactory {
    address public contractAddress;

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }

    function createGauge(
        uint _profileId,
        address _devaddr,
        address _valuepool,
        bool _automatic,
        bool _percentages,
        bool _immutableContract
    ) external {
        address arpHelper = IContract(contractAddress).arpHelper();
        address last_gauge = address(new ARP(
            _devaddr,
            arpHelper,
            _valuepool,
            contractAddress,
            _automatic,
            _percentages,
            _immutableContract
        ));
        IARP(arpHelper).updateGauge(
            last_gauge, 
            _devaddr, 
            _profileId
        );
    }
}
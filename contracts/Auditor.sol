// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Library.sol";

// Gauges are used to incentivize pools, they emit reward tokens over 7 days for staked LP tokens
contract Auditor {
    using SafeERC20 for IERC20;

    uint public collectionId;
    bool public bountyRequired;
    address public contractAddress;
    address public devaddr_;
    address private helper;
    mapping(address => bool) public isAdmin;
    mapping(uint => bool) public isAutoChargeable;
    mapping(address => uint) public adminBountyIds;
    mapping(uint => Divisor) public penaltyDivisor;
    mapping(uint => Divisor) public discountDivisor;

    struct ProtocolInfo {
        address token;
        uint bountyId;
        uint amountReceivable;
        uint paidReceivable;
        uint periodReceivable;
        uint startReceivable;
        uint esgRating;
        uint optionId;
    }
    mapping(uint => uint[]) private _protocolRatings;
    mapping(uint => string) public description;
    mapping(uint => string) public media;
    mapping(uint => ProtocolInfo) public protocolInfo;
    mapping(address => uint) public totalProcessed;
    address public uriGenerator;

    constructor(
        address _devaddr,
        address _helper,
        address __contractAddress
    ) {
        collectionId = IMarketPlace(IContract(__contractAddress).marketCollections())
        .addressToCollectionId(_devaddr);
        require(collectionId > 0, "A01");
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

    function updateParameters(bool _bountyRequired) external onlyAdmin {
        bountyRequired = _bountyRequired;
    }

    function updateDev(address _devaddr) external onlyDev {
        devaddr_ = _devaddr;
    }

    function updateAdmin(address _admin, bool _add) external onlyDev {
        isAdmin[_admin] = _add;
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
        return IContract(contractAddress).auditorHelper();
    }

    function _trustBounty() internal view returns(address) {
        return IContract(contractAddress).trustBounty();
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || helper == msg.sender);
        contractAddress = _contractAddress;
        helper = IContract(_contractAddress).auditorNote();
    }

    function updateBounty(uint _bountyId, uint _tokenId) external {
        address trustBounty = _trustBounty();
        (address owner,address _token,,address claimableBy,,,,,,) = 
        ITrustBounty(trustBounty).bountyInfo(_bountyId);
        if (isAdmin[msg.sender]) {
            require(owner == msg.sender && claimableBy == address(0x0));
            if (_bountyId > 0 && adminBountyIds[_token] == 0) {
                IAuditor(helper).attach(_bountyId);
            } else if (_bountyId == 0 && adminBountyIds[_token] > 0) {
                IAuditor(helper).detach(_bountyId);
            }
            adminBountyIds[_token] = _bountyId;
        } else {
            require(owner == msg.sender && 
                ve(_minter()).ownerOf(_tokenId) == msg.sender &&
                _token == protocolInfo[_tokenId].token && 
                claimableBy == devaddr_
            );
            protocolInfo[_tokenId].bountyId = _bountyId;
        }
    }

    function updateAutoCharge(bool _autoCharge, uint _tokenId) external {
        require(ve(_minter()).ownerOf(_tokenId) == msg.sender);
        isAutoChargeable[_tokenId] = _autoCharge;
        IAuditor(helper).emitUpdateAutoCharge(
            _tokenId,
            _autoCharge
        );
    }

    function getReceivable(uint _protocolId, uint _numPeriods) public view returns(uint,uint) {
        uint _optionId = protocolInfo[_protocolId].optionId;
        (uint dueReceivable,,int secondsReceivable) = IAuditor(IContract(contractAddress).auditorHelper2()).getDueReceivable(address(this), _protocolId, _numPeriods);
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

    function autoCharge(uint[] memory _tokenIds, uint _numPeriods) external lock {
        address minter = _minter();
        for (uint i = 0; i < _tokenIds.length; i++) {
            if (isAdmin[msg.sender]) require(isAutoChargeable[_tokenIds[i]], "A4");
            (uint _price, uint _due) = getReceivable(_tokenIds[i], _numPeriods);
            address token = protocolInfo[_tokenIds[i]].token;
            uint payswapFees = Math.min(
                _price * IAuditor(helper).tradingFee() / 10000, 
                IContract(contractAddress).cap(token) > 0 
                ? IContract(contractAddress).cap(token) : type(uint).max
            );
            uint _bounty = ITrustBounty(_trustBounty()).getBalance(adminBountyIds[token]);
            require(_bounty >= IAuditor(helper).minBountyPercent() * totalProcessed[token] / 10000);
            address _user = isAdmin[msg.sender] ? ve(helper).ownerOf(_tokenIds[i]) : msg.sender;
            IERC20(token).safeTransferFrom(ve(minter).ownerOf(_tokenIds[i]), address(this), _price);
            IERC20(token).safeTransfer(helper, payswapFees);
            IAuditor(helper).notifyFees(token, payswapFees);
            protocolInfo[_tokenIds[i]].paidReceivable += _due;
            totalProcessed[token] += _price;
            if (IAuditor(helper).adminNotes(_tokenIds[i]) > 0) {
                uint _noteTokenId = IAuditor(helper).adminNotes(_tokenIds[i]);
                (uint due,,,,) = IAuditor(helper).notes(_noteTokenId);
                uint _paid = _price >= due ? due : _price;
                IAuditor(helper).updatePendingRevenueFromNote(_noteTokenId, _paid);
            }
            IAuditor(helper).emitAutoCharge(
                _user,
                _tokenIds[i], 
                protocolInfo[_tokenIds[i]].paidReceivable
            );
        }
    }

    function getProtocolRatings(uint _protocolId) external view returns(uint[] memory) {
        return _protocolRatings[_protocolId];
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
        uint[4] memory _bankInfo, //_amountReceivable, _periodReceivable, _startReceivable, _optionId
        uint _identityTokenId,
        uint _esgRating,
        uint _protocolId,
        uint[] memory _ratings,
        string memory _media,
        string memory _description
    ) external onlyAdmin {
        if(_protocolId == 0) {
            _checkIdentityProof(_owner, _identityTokenId);
            _protocolId = IAuditor(_minter()).mint(_owner);
            protocolInfo[_protocolId].startReceivable = block.timestamp + _bankInfo[2];
            protocolInfo[_protocolId].amountReceivable = _bankInfo[0];
            protocolInfo[_protocolId].periodReceivable = _bankInfo[1];
            protocolInfo[_protocolId].token = _token;
            protocolInfo[_protocolId].optionId = _bankInfo[3];
        }
        
        if (_ratings.length > 0) {
            _protocolRatings[_protocolId] = _ratings;
        }
        protocolInfo[_protocolId].esgRating = _esgRating;
        media[_protocolId] = _media;
        description[_protocolId] = _description;
        
        IAuditor(helper).emitUpdateProtocol(
            _protocolId,
            _ratings,
            _esgRating,
            _owner, 
            _media,
            _description
        );
    }

    function updateURIGenerator(address _uriGenerator) external onlyAdmin {
        uriGenerator = _uriGenerator;
    }

    function deleteProtocol (uint _tokenId) public onlyAdmin {
        IAuditor(_minter()).burn(_tokenId);
        delete protocolInfo[_tokenId];
        delete _protocolRatings[_tokenId];
        IAuditor(helper).emitDeleteProtocol(_tokenId);
    }

    function withdraw(address _token, uint amount) external onlyAdmin {
        IERC20(_token).safeTransfer(msg.sender, amount);
    
        IAuditor(helper).emitWithdraw(msg.sender, amount);
    }

    function noteWithdraw(address _to, uint _tokenId, uint amount) external {
        require(msg.sender == helper);
        IERC20(protocolInfo[_tokenId].token).safeTransfer(_to, amount);
    }
}

contract AuditorNote is ERC721Pausable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using Percentile for *; 

    EnumerableSet.AddressSet private gauges;
    mapping(uint => EnumerableSet.UintSet) private _allVoters;
    mapping(address => uint) public percentiles;
    struct AuditNote {
        uint due;
        uint timer;
        uint protocolId;
        address auditor;
        address token;
    }
    mapping(uint => AuditNote) public notes;
    mapping(address => bool) public dataKeeper;
    mapping(uint => uint) public adminNotes;
    mapping(uint => uint) public pendingRevenueFromNote;
    uint public tokenId = 1;
    uint public tradingFee = 100;
    struct Vote {
        uint likes;
        uint dislikes;
    }
    bool public check;
    address public contractAddress;
    mapping(uint => uint) private sum_of_diff_squared;
    uint public minBountyPercent = 1;
    mapping(address => Vote) public votes;
    mapping(uint => mapping(address => int)) public voted;
    mapping(uint => mapping(uint => address)) public profiles;
    mapping(address => uint) public treasuryFees;
    mapping(address => uint) public addressToProfileId;

    event Voted(address indexed auditor, uint profileId, uint likes, uint dislikes, bool like);
    event UpdateProtocol(
        uint indexed protocolId,
        uint[] ratings,
        uint esgRating,
        address auditor,
        address owner,
        string media,
        string description
    );
    event UpdateAutoCharge(uint indexed protocolId, address auditor, bool isAutoChargeable);
    event AutoCharge(uint indexed protocolId, address from, address auditor, uint paidReceivable);
    event DeleteProtocol(uint indexed protocolId, address auditor);
    event Withdraw(address indexed from, address auditor, uint amount);
    event UpdateMiscellaneous(
        uint idx, 
        uint auditorId, 
        string paramName, 
        string paramValue, 
        uint paramValue2, 
        uint paramValue3, 
        address sender,
        address paramValue4,
        string paramValue5
    );
    event CreateAuditor(address indexed auditor, address user, uint profileId);
    event DeleteAuditor(address indexed auditor);

    constructor() ERC721("AuditorNote", "nAuditor")  {}

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

    function setContractAddressAt(address _auditor) external {
        IMarketPlace(_auditor).setContractAddress(contractAddress);
    }

    function attach(uint _bountyId) external {
        require(gauges.contains(msg.sender), "SN07");
        ITrustBounty(IContract(contractAddress).trustBountyHelper()).attach(_bountyId);
    }

    function detach(uint _bountyId) external {
        require(gauges.contains(msg.sender), "SN08");
        ITrustBounty(IContract(contractAddress).trustBountyHelper()).detach(_bountyId);
    }

    function notifyFees(address _token, uint _fees) external {
        require(gauges.contains(msg.sender));
        treasuryFees[_token] += _fees;
    }

    function getAllAuditors(uint _start) external view returns(address[] memory auditors) {
        auditors = new address[](gauges.length() - _start);
        for (uint i = _start; i < gauges.length(); i++) {
            auditors[i] = gauges.at(i);
        }    
    }

    function isGauge(address _auditor) external view returns(bool) {
        return gauges.contains(_auditor);
    }
    
    function updateGauge(address _last_gauge, address _user, uint _profileId) external {
        require(msg.sender == IContract(contractAddress).auditorFactory());
        require(IProfile(IContract(contractAddress).profile()).addressToProfileId(_user) == _profileId && _profileId > 0);
        gauges.add(_last_gauge);
        addressToProfileId[_last_gauge] = _profileId;
        emit CreateAuditor(_last_gauge, _user, _profileId);
    }

    function updateDatakeeper(address _auditor, bool _dataKeeper) external {
        require(IAuth(_auditor).isAdmin(msg.sender) && gauges.contains(_auditor));
        uint _category = IAuditor(IContract(contractAddress).auditorHelper()).categories(_auditor);
        uint _profileId = IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender);
        require(_category > 0 && _profileId > 0);
        profiles[_profileId][_category] = _auditor;
        dataKeeper[_auditor] = _dataKeeper;
    }
    
    function updateMinBountyPercent(uint _minBountyPercent) external {
        require(msg.sender == IAuth(contractAddress).devaddr_());
        minBountyPercent = _minBountyPercent;
    }

    function deleteAuditor(address _auditor) external {
        require(msg.sender == IAuth(contractAddress).devaddr_() || IAuth(_auditor).isAdmin(msg.sender));
        gauges.remove(_auditor);
        emit DeleteAuditor(_auditor);
    }

    function _resetVote(address _auditor, uint profileId) internal {
        if (voted[profileId][_auditor] > 0) {
            votes[_auditor].likes -= 1;
        } else if (voted[profileId][_auditor] < 0) {
            votes[_auditor].dislikes -= 1;
        }
    }

    function vote(address _auditor, uint profileId, bool like) external {
        uint _category = IAuditor(IContract(contractAddress).auditorHelper()).categories(_auditor);
        require(_category > 0);
        require(IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender) == profileId && profileId > 0);
        SSIData memory metadata = ISSI(IContract(contractAddress).ssi()).getSSID(profileId);
        require(keccak256(abi.encodePacked(metadata.answer)) != keccak256(abi.encodePacked("")));
        _resetVote(_auditor, profileId);        
        if (like) {
            votes[_auditor].likes += 1;
            voted[profileId][_auditor] = 1;
        } else {
            votes[_auditor].dislikes += 1;
            voted[profileId][_auditor] = -1;
        }
        uint _auditorVotes;
        if (votes[_auditor].likes > votes[_auditor].dislikes) {
            _auditorVotes = votes[_auditor].likes - votes[_auditor].dislikes;
        }
        _allVoters[_category].add(profileId);
        (uint percentile, uint sods) = Percentile.computePercentileFromData(
            false,
            _auditorVotes,
            _allVoters[_category].length(),
            _allVoters[_category].length(),
            sum_of_diff_squared[_category]
        );
        sum_of_diff_squared[_category] = sods;
        percentiles[_auditor] = percentile;

        emit Voted(_auditor, profileId, votes[_auditor].likes, votes[_auditor].dislikes, like);
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

    function getGaugeNColor(uint _ssidAuditorProfileId) external view returns(address, bool, COLOR) {
        uint _category = IAuditor(IContract(contractAddress).auditorHelper()).profileCategories(_ssidAuditorProfileId);
        address _auditor = profiles[_ssidAuditorProfileId][_category];
        return (
            _auditor,
            dataKeeper[_auditor],
            _getColor(percentiles[_auditor])
        );
    }

    function emitUpdateProtocol(
        uint _protocolId,
        uint[] memory _ratings,
        uint _esgRating,
        address _owner,
        string memory _media,
        string memory _description
    ) external {
        require(gauges.contains(msg.sender));
        emit UpdateProtocol(
            _protocolId,
            _ratings,
            _esgRating,
            msg.sender,
            _owner,
            _media,
            _description
        );
    }

    function emitWithdraw(address from, uint amount) external {
        require(gauges.contains(msg.sender));
        emit Withdraw(from, msg.sender, amount);
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
        uint _auditorId, 
        string memory paramName, 
        string memory paramValue, 
        uint paramValue2, 
        uint paramValue3,
        address paramValue4,
        string memory paramValue5
    ) external {
        emit UpdateMiscellaneous(
            _idx, 
            _auditorId, 
            paramName, 
            paramValue, 
            paramValue2, 
            paramValue3, 
            msg.sender,
            paramValue4,
            paramValue5
        );
    }

    function updatePendingRevenueFromNote(uint _tokenId, uint _paid) external {
        require(gauges.contains(msg.sender));
        pendingRevenueFromNote[_tokenId] += _paid;
    }
    
    function transferDueToNoteReceivable(
        address _auditor,
        address _to, 
        uint _protocolId, 
        uint _numPeriods
    ) external lock {
        check = true;
        require(gauges.contains(_auditor));
        (uint dueReceivable, uint nextDue,) = IAuditor(IContract(contractAddress).auditorHelper2()).getDueReceivable(_auditor, _protocolId, _numPeriods);
        require(
            // dueReceivable > 0 && 
            IAuth(_auditor).isAdmin(msg.sender), "AH7"
        );
        (address _token,,,,,,,) = IAuditor(_auditor).protocolInfo(_protocolId);
        adminNotes[_protocolId] = tokenId;
        notes[tokenId] = AuditNote({
            due: dueReceivable,
            token: _token,
            timer: nextDue,
            protocolId: _protocolId,
            auditor: _auditor
        });
        _safeMint(_to, tokenId, msg.data);
        emit UpdateMiscellaneous(
            3, 
            _protocolId, 
            "", 
            "", 
            tokenId++, 
            0, 
            msg.sender,
            _auditor,
            ""
        );
    }

    function claimPendingRevenueFromNote(uint _tokenId) external lock {
        require(ownerOf(_tokenId) == msg.sender, "Only owner!");
        require(notes[_tokenId].timer <= block.timestamp, "Not yet due");
        uint256 revenueToClaim = pendingRevenueFromNote[_tokenId];
        _burn(_tokenId);
        delete pendingRevenueFromNote[_tokenId];
        delete adminNotes[notes[_tokenId].protocolId];
        uint payswapFees = revenueToClaim * tradingFee / 10000;
        IAuditor(notes[_tokenId].auditor).noteWithdraw(address(msg.sender), _tokenId, revenueToClaim - payswapFees);
        IAuditor(notes[_tokenId].auditor).noteWithdraw(address(this), _tokenId, payswapFees);
        treasuryFees[notes[_tokenId].token] += payswapFees;
        delete notes[_tokenId];
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
        _description[0] = "This note gives you access to revenues of the auditor on the specified protocol";
        output = _constructTokenURI(
            _tokenId, 
            notes[_tokenId].token,
            _description,
            optionNames, 
            optionValues 
        );
    }

    function updateTradingFee(uint _tradingFee) external {
        require(msg.sender == IAuth(contractAddress).devaddr_());
        tradingFee = _tradingFee;
    }

    function withdrawFees(address _token) external returns(uint _amount) {
        require(msg.sender == IAuth(contractAddress).devaddr_());
        _amount = treasuryFees[_token];
        IERC20(_token).safeTransfer(msg.sender, _amount);
        treasuryFees[_token] = 0;
        return _amount;
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

    function addressToString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}

contract AuditorHelper is ERC721Pausable {
    uint public tokenId = 1;
    struct MintInfo {
        address auditor;
        uint extraMint;
    }
    mapping(uint => MintInfo) public tokenIdToAuditor;
    mapping(uint => uint) public tokenIdToParent;
    // auditor => category
    mapping(address => uint) public categories;
    mapping(uint => uint) public profileCategories;
    
    address private contractAddress;

    constructor() ERC721("AuditorProof", "AuditorNFT")  {}
    
    function mint(address _to) external returns(uint) {
        require(IAuditor(IContract(contractAddress).auditorNote()).isGauge(msg.sender));
        _safeMint(_to, tokenId, msg.data);
        tokenIdToAuditor[tokenId].auditor = msg.sender;
        IAuditor(IContract(contractAddress).auditorNote()).emitUpdateMiscellaneous(
            2, 
            tokenId,
            "",
            "",
            tokenId,
            0,
            msg.sender,
            ""
        );
        return tokenId++;
    }

    function mintExtra(uint _tokenId, uint _extraMint) external returns(uint) {
        require(ownerOf(_tokenId) == msg.sender);
        require(tokenIdToAuditor[_tokenId].extraMint >= _extraMint);
        for (uint i = 0; i < _extraMint; i++) {
            _safeMint(msg.sender, tokenId, msg.data);
            tokenIdToParent[tokenId] = _tokenId;
            IAuditor(IContract(contractAddress).auditorNote()).emitUpdateMiscellaneous(
                2, 
                _tokenId,
                "",
                "",
                tokenId++,
                0,
                tokenIdToAuditor[_tokenId].auditor,
                ""
            );
        }
        tokenIdToAuditor[_tokenId].extraMint -= _extraMint;
        return tokenId;
    }

    function updateMintInfo(address _auditor, uint _extraMint, uint _tokenId) external {
        require(tokenIdToAuditor[_tokenId].auditor == _auditor && IAuth(_auditor).isAdmin(msg.sender));
        tokenIdToAuditor[_tokenId].auditor = msg.sender;
        tokenIdToAuditor[_tokenId].extraMint += _extraMint;
    }

    function updateCategory(address _auditor, uint _category) external {
        require(IAuth(_auditor).isAdmin(msg.sender));
        uint _profileId = IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender);
        require(_profileId > 0 && _category > 0);
        categories[_auditor] = _category;
        profileCategories[_profileId] = _category;
    }

    function burn(uint _tokenId) external {
        require(IAuditor(IContract(contractAddress).auditorNote()).isGauge(msg.sender) || ownerOf(_tokenId) == msg.sender);
        _burn(_tokenId);
        delete tokenIdToParent[_tokenId];
        delete tokenIdToAuditor[_tokenId];
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }

    function tokenURI(uint __tokenId) public view virtual override returns (string memory output) {
        uint _tokenId = tokenIdToParent[__tokenId] == 0 ? __tokenId : __tokenId;
        address _uriGenerator = IAuditor(tokenIdToAuditor[_tokenId].auditor).uriGenerator();
        if (_uriGenerator != address(0x0)) {
            output = IAuditor(_uriGenerator).uri(__tokenId);
        } else {
            (string[] memory optionNames, string[] memory optionValues) = _getOptions(tokenIdToAuditor[_tokenId].auditor, _tokenId);
            string[] memory description = new string[](1);
            description[0] = IAuditor(tokenIdToAuditor[_tokenId].auditor).description(_tokenId);
            
            output = IMarketPlace(IContract(contractAddress).nftSvg()).constructTokenURI(
                __tokenId,
                '',
                tokenIdToAuditor[_tokenId].auditor,
                ownerOf(_tokenId),
                ownerOf(__tokenId),
                address(0x0),
                IAuditor((IContract(contractAddress).auditorHelper2())).getMedia(_tokenId),
                optionNames,
                optionValues,
                description
            );
        }
    }

    function _getOptions(address _auditor, uint _tokenId) public view returns(string[] memory optionNames, string[] memory optionValues) {
        uint[] memory protocolRatings = IAuditor(_auditor).getProtocolRatings(_tokenId);
        (,uint bountyId,,,,,uint esg,) = IAuditor(_auditor).protocolInfo(_tokenId);
        uint bountyIdLength = bountyId > 0 ? 1 : 0;
        optionNames = new string[](3 + bountyIdLength + protocolRatings.length);
        optionValues = new string[](3 + bountyIdLength + protocolRatings.length);
        uint idx;
        optionNames[idx] = "Audit Color";
        address _auditorNote = IContract(contractAddress).auditorNote();
        uint _auditorId = IProfile(_auditorNote).addressToProfileId(_auditor);
        (,,COLOR _color) = IAuditor(_auditorNote).getGaugeNColor(_auditorId);
        optionValues[idx++] = _color == COLOR.GOLD 
        ? "Gold" 
        : _color == COLOR.SILVER 
        ? "Silver"
        : _color == COLOR.BROWN
        ? "Brown"
        : "Black";
        if (bountyIdLength > 0) {
            optionNames[idx] = "UBID";
            optionValues[idx++] = string(abi.encodePacked("# ", toString(bountyId)));
        }
        optionNames[idx] = "ESG Rating";
        optionValues[idx++] = toString(esg);
        optionNames[idx] = "AID";
        optionValues[idx++] = toString(_auditorId);
        // address auditorHelper2 = IContract(contractAddress).auditorHelper2();
        for (uint i = 0; i < protocolRatings.length; i++) {
            if (IAuditor(IContract(contractAddress).auditorHelper2()).ratingLegendLength(_auditor) > i) {
                optionNames[idx] = IAuditor(IContract(contractAddress).auditorHelper2()).ratingLegend(_auditor, i);
            } else {
                optionNames[idx] = string(abi.encodePacked("Rating ", "(", toString(i+1), ")"));
            }
            optionValues[idx++] = toString(protocolRatings[i]);
        }
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

contract AuditorHelper2 {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    address public contractAddress;
    address public valuepoolAddress;
    uint public treasury;
    uint public valuepool;
    struct Channel {
        string message;
        uint active_period;
    }
    uint private maxNumMedia = 2;
    uint internal minute = 3600; // allows minting once per week (reset every Thursday 00:00 UTC)
    uint private currentMediaIdx = 1;
    struct ScheduledMedia {
        uint amount;
        string message;
    }
    mapping(uint => uint) public pricePerAttachMinutes;
    mapping(uint => ScheduledMedia) public scheduledMedia;
    mapping(uint => uint) public pendingRevenue;
    mapping(uint => mapping(uint => string)) public tags;
    mapping(uint => mapping(string => EnumerableSet.UintSet)) private _scheduledMedia;
    mapping(address => string[]) public ratingLegend;
    mapping(uint => mapping(string => Channel)) public channels;
    mapping(uint => mapping(string => bool)) public tagRegistrations;
    mapping(uint => mapping(string => EnumerableSet.UintSet)) private excludedContents;

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function updateMaxNumMedia(uint _maxNumMedia) external {
        require(IAuth(contractAddress).devaddr_() == msg.sender);
        maxNumMedia = _maxNumMedia;
    }

    function updateValuepool(address _valuepoolAddress) external {
        require(IAuth(contractAddress).devaddr_() == msg.sender);
        valuepoolAddress = _valuepoolAddress;
    }
    
    function getMedia(uint _tokenId) public view returns(string[] memory _media) {
        (address _auditor,) = IAuditor(IContract(contractAddress).auditorHelper()).tokenIdToAuditor(_tokenId);
        uint _auditorId = IProfile(IContract(contractAddress).auditorNote()).addressToProfileId(msg.sender);
        string memory _tag = tags[_auditorId][_tokenId];
        if (tagRegistrations[_auditorId][_tag]) {
            _media = new string[](_scheduledMedia[1][_tag].length() + 1);
            uint idx;
            _media[idx++] = IAuditor(_auditor).media(_tokenId);
            for (uint i = 0; i < _scheduledMedia[1][_tag].length(); i++) {
                uint _currentMediaIdx = _scheduledMedia[1][_tag].at(i);
                _media[idx++] = scheduledMedia[_currentMediaIdx].message;
            }
        } else {
            _media = new string[](_scheduledMedia[_auditorId][_tag].length() + 1);
            uint idx;
            _media[idx++] = IAuditor(_auditor).media(_tokenId);
            for (uint i = 0; i < _scheduledMedia[_auditorId][_tag].length(); i++) {
                uint _currentMediaIdx = _scheduledMedia[_auditorId][_tag].at(i);
                _media[idx++] = scheduledMedia[_currentMediaIdx].message;
            }
        }
    }

    function updateTagRegistration(string memory _tag, bool _add) external {
        address auditorNote = IContract(contractAddress).auditorNote();
        uint _auditorId = IProfile(auditorNote).addressToProfileId(msg.sender);
        tagRegistrations[_auditorId][_tag] = _add;
        IAuditor(auditorNote).emitUpdateMiscellaneous(
            1,
            _auditorId,
            _tag,
            "",
            _add ? 1 : 0,
            0,
            address(0x0),
            ""
        );
    }

    function updateExcludedContent(string memory _tag, string memory _contentName, bool _add) external {
        uint _auditorId = IProfile(IContract(contractAddress).auditorNote()).addressToProfileId(msg.sender);
        if (_add) {
            require(IContent(contractAddress).contains(_contentName), "Not a content type");
            excludedContents[_auditorId][_tag].add(uint(keccak256(abi.encodePacked(_contentName))));
        } else {
            excludedContents[_auditorId][_tag].remove(uint(keccak256(abi.encodePacked(_contentName))));
        }
    }

    function getExcludedContents(uint _auditorId, string memory _tag) public view returns(string[] memory _excluded) {
        _excluded = new string[](excludedContents[_auditorId][_tag].length());
        for (uint i = 0; i < _excluded.length; i++) {
            _excluded[i] = IContent(contractAddress).indexToName(excludedContents[_auditorId][_tag].at(i));
        }
    }

    function claimPendingRevenue() external lock {
        uint _auditorId = IProfile(IContract(contractAddress).auditorNote()).addressToProfileId(msg.sender);
        IERC20(IContract(contractAddress).token()).safeTransfer(address(msg.sender), pendingRevenue[_auditorId]);
        pendingRevenue[_auditorId] = 0;
    }
    
    function updatePricePerAttachMinutes(uint _pricePerAttachMinutes) external {
        pricePerAttachMinutes[IProfile(IContract(contractAddress).auditorNote()).addressToProfileId(msg.sender)] = _pricePerAttachMinutes;
    }

    function sponsorTag(
        address _sponsor,
        address _auditor,
        uint _amount, 
        string memory _tag, 
        string memory _message
    ) external {
        uint _auditorId = IProfile(IContract(contractAddress).auditorNote()).addressToProfileId(_auditor);
        require(IAuth(_sponsor).isAdmin(msg.sender), "NTH9");
        require(!ISponsor(_sponsor).contentContainsAny(getExcludedContents(_auditorId, _tag)), "NTH10");
        uint _pricePerAttachMinutes = pricePerAttachMinutes[_auditorId];
        if (_pricePerAttachMinutes > 0) {
            uint price = _amount * _pricePerAttachMinutes;
            IERC20(IContract(contractAddress).token()).safeTransferFrom(address(msg.sender), address(this), price);
            uint valuepoolShare = IContract(contractAddress).valuepoolShare();
            uint adminShare = IContract(contractAddress).adminShare();
            valuepool += price * valuepoolShare / 10000;
            if (_auditorId > 0) {
                treasury += price * adminShare / 10000;
                pendingRevenue[_auditorId] += price * (10000 - adminShare - valuepoolShare) / 10000;
            } else {
                treasury += price * (10000 - valuepoolShare) / 10000;
            }
            scheduledMedia[currentMediaIdx] = ScheduledMedia({
                amount: _amount,
                message: _message
            });
            _scheduledMedia[_auditorId][_tag].add(currentMediaIdx++);
            updateSponsorMedia(_auditorId, _tag);
        }
    }

    function updateSponsorMedia(uint _auditorId, string memory _tag) public {
        require(channels[_auditorId][_tag].active_period < block.timestamp, "NTH12");
        uint idx = _scheduledMedia[_auditorId][_tag].at(0);
        channels[_auditorId][_tag].active_period = block.timestamp + scheduledMedia[idx].amount*minute / minute * minute;
        channels[_auditorId][_tag].message = scheduledMedia[idx].message;
        if (_scheduledMedia[_auditorId][_tag].length() > maxNumMedia) {
            _scheduledMedia[_auditorId][_tag].remove(idx);
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
        require(msg.sender == IAuth(contractAddress).devaddr_(), "NTH11");
        IERC20(IContract(contractAddress).token()).safeTransfer(valuepoolAddress, valuepool);
        valuepool = 0;
    }

    function updateRatingLegend(address _auditor, string[] memory legend) external {
        require(IAuth(_auditor).isAdmin(msg.sender));
        ratingLegend[_auditor] = legend;
    }

    function ratingLegendLength(address _auditor) external view returns(uint) {
        return ratingLegend[_auditor].length;
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender, "NT2");
        contractAddress = _contractAddress;
    }

    function verifyNFT(uint _tokenId, uint _collectionId, string memory item) external view returns(uint) {
        (address _auditor,) = IAuditor(IContract(contractAddress).auditorHelper()).tokenIdToAuditor(_tokenId);
        if (
            IAuditor(_auditor).collectionId() == _collectionId &&
            (
                keccak256(abi.encodePacked(item)) == keccak256(abi.encodePacked("")) ||
                keccak256(abi.encodePacked(item)) == keccak256(abi.encodePacked(IAuditor(_auditor).description(_tokenId)))
            )
        ) {
            return 1;
        }
        return 0;
    }

    function getNumPeriods(uint tm1, uint tm2, uint _period) public view returns(uint) {
        if (tm2 == 0) tm2 = block.timestamp;
        if (tm1 == 0 || tm2 == 0 || tm2 < tm1) return 0;
        return _period > 0 ? (tm2 - tm1) / _period : 1;
    }

    function getDueReceivable(address _auditor, uint _protocolId, uint _numExtraPeriods) public view returns(uint, uint, int) {
        (,,uint amountReceivable,uint paidReceivable,uint periodReceivable,uint startReceivable,,) =
        IAuditor(_auditor).protocolInfo(_protocolId);
        uint numPeriods = getNumPeriods(startReceivable, block.timestamp, periodReceivable);
        // uint numPeriods = amountReceivable == 0 ? 1 : Math.max(1, paidReceivable / amountReceivable);
        uint nextDue = startReceivable + periodReceivable * numPeriods;
        numPeriods += _numExtraPeriods;
        uint due = nextDue < block.timestamp ? amountReceivable * numPeriods - paidReceivable : 0;
        return (
            due, // due
            nextDue, // next
            int(block.timestamp) - int(nextDue) //late or seconds in advance
        );
    }

    function buyWithContract(
        address _auditor,
        address _user,
        address _referrer,
        string memory _tokenId,
        uint _numPeriods,
        uint[] memory _protocolIds   
    ) external {
        require(IValuePool(IContract(contractAddress).valuepoolHelper()).isGauge(msg.sender));
        require(IAuditor(IContract(contractAddress).auditorNote()).isGauge(_auditor), "WHHH1");
        (uint _price,) = IAuditor(_auditor).getReceivable(_protocolIds[0], _numPeriods);
        (address _token,,,,,,,) = IAuditor(_auditor).protocolInfo(_protocolIds[0]);
        erc20(_token).approve(_auditor, _price);
        IAuditor(_auditor).autoCharge(_protocolIds, _numPeriods);
    }

    function getOptions(address _auditor, uint _tokenId) external view returns(string[] memory optionNames, string[] memory optionValues) {
        uint[] memory protocolRatings = IAuditor(_auditor).getProtocolRatings(_tokenId);
        (,uint bountyId,,,,,uint esg,) = IAuditor(_auditor).protocolInfo(_tokenId);
        uint bountyIdLength = bountyId > 0 ? 1 : 0;
        optionNames = new string[](3 + bountyIdLength + protocolRatings.length);
        optionValues = new string[](3 + bountyIdLength + protocolRatings.length);
        uint idx;
        optionNames[idx] = "Auditor Color";
        address _auditorNote = IContract(contractAddress).auditorNote();
        uint _auditorId = IProfile(_auditorNote).addressToProfileId(_auditor);
        (,,COLOR _color) = IAuditor(_auditorNote).getGaugeNColor(_auditorId);
        optionValues[idx++] = _color == COLOR.GOLD 
        ? "Gold" 
        : _color == COLOR.SILVER 
        ? "Silver"
        : _color == COLOR.BROWN
        ? "Brown"
        : "Black";
        if (bountyIdLength > 0) {
            optionNames[idx] = "User Bounty ID";
            optionValues[idx++] = string(abi.encodePacked("# ", toString(bountyId)));
        }
        optionNames[idx] = "ESG Rating";
        optionValues[idx++] = toString(esg);
        optionNames[idx] = "Auditor ID";
        optionValues[idx++] = toString(_auditorId);
        for (uint i = 0; i < protocolRatings.length; i++) {
            if (ratingLegend[_auditor].length > i) {
                optionNames[idx] = ratingLegend[_auditor][i];
            } else {
                optionNames[idx] = string(abi.encodePacked("Rating ", "(", toString(i+1), ")"));
            }
            optionValues[idx++] = toString(protocolRatings[i]);
        }
    }

    function addressToString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
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

contract AuditorFactory {
    address public contractAddress;

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }

    function createGauge(uint _profileId, address _devaddr) external {
        address note = IContract(contractAddress).auditorNote();
        address last_gauge = address(new Auditor(
            _devaddr,
            note,
            contractAddress
        ));
        IAuditor(note).updateGauge(
            last_gauge, 
            _devaddr, 
            _profileId
        );
    }
}
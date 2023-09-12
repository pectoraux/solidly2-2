// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Library.sol";

// Gauges are used to incentivize pools, they emit reward tokens over 7 days for staked LP tokens
contract World {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    bool public bountyRequired;
    uint public collectionId;
    uint public totalSupply;
    address private contractAddress;
    address public devaddr_;
    address private helper;
    mapping(address => bool) public isAdmin;
    mapping(uint => bool) public isAutoChargeable;
    mapping(uint => Divisor) public penaltyDivisor;
    mapping(uint => Divisor) public discountDivisor;
    mapping(address => uint) public adminBountyId;
    mapping(uint => address) public taxContract;

    struct ProtocolInfo {
        address owner;
        address token;
        uint bountyId;
        uint amountReceivable;
        uint paidReceivable;
        uint periodReceivable;
        uint startReceivable;
        uint rating;
        uint optionId;
    }
    mapping(uint => string) public description;
    mapping(uint => string) public media;
    mapping(uint => ProtocolInfo) public protocolInfo;
    mapping(address => uint) public addressToProtocolId;
    mapping(address => uint) public totalProcessed;
    mapping(uint => EnumerableSet.UintSet) private _protocolTokenIds;

    constructor(
        address _devaddr,
        address _helper,
        address __contractAddress
    ) {
        collectionId = IMarketPlace(IContract(__contractAddress).marketCollections())
        .addressToCollectionId(_devaddr);
        require(collectionId > 0, "W01");
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

    function updateAdmin(address _admin, bool _add) external onlyDev {
        isAdmin[_admin] = _add;
    }

    function updateDev(address _devaddr) external onlyDev {
        devaddr_ = _devaddr;
    }

    function getDescription(uint _tokenId) external view returns(string[] memory) {
        address _user = ve(IContract(contractAddress).worldHelper2()).ownerOf(_tokenId);
        uint _protocolId = addressToProtocolId[_user];
        string[] memory _description = new string[](1);
        _description[0] = description[_protocolId];
        return _description;
    }

    function getAllTokenIds(address _user, uint _start) external view returns(uint[] memory _tokenIds) {
        _tokenIds = new uint[](_protocolTokenIds[addressToProtocolId[_user]].length() - _start);
        for (uint i = _start; i < _protocolTokenIds[addressToProtocolId[_user]].length(); i++) {
            _tokenIds[i] = _protocolTokenIds[addressToProtocolId[_user]].at(i);
        }    
    }

    function updateParameters(bool _bountyRequired) external onlyAdmin {
        bountyRequired = _bountyRequired;
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
        return IContract(contractAddress).worldHelper();
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
        (address owner,address _token,,address claimableBy,,,,,,) = 
        ITrustBounty(_trustBounty()).bountyInfo(_bountyId);
        if (isAdmin[msg.sender]) {
            require(owner == msg.sender && claimableBy == address(0x0));
            if (_bountyId > 0 && adminBountyId[_token] == 0) {
                IWorld(helper).attach(_bountyId);
            } else if (_bountyId == 0 && adminBountyId[_token] > 0) {
                IWorld(helper).detach(_bountyId);
            }
            adminBountyId[_token] = _bountyId;
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
        IWorld(helper).emitUpdateAutoCharge(
            _tokenId,
            _autoCharge
        );
    }

    function getReceivable(uint _protocolId, uint _numPeriods) public view returns(uint,uint) {
        uint _optionId = protocolInfo[_protocolId].optionId;
        (uint dueReceivable,,int secondsReceivable) = IWorld(helper).getDueReceivable(address(this), _protocolId, _numPeriods);
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

    function updateTaxContract(address _taxContract) external {
        taxContract[addressToProtocolId[msg.sender]] = _taxContract;
    }

    function autoCharge(uint[] memory _tokenIds, uint _numPeriods) external lock {
        address _worldHelper3 = IContract(contractAddress).worldHelper3();
        for (uint i = 0; i < _tokenIds.length; i++) {
            if (isAdmin[msg.sender]) require(isAutoChargeable[_tokenIds[i]], "W4");
            (uint _price, uint _due) = getReceivable(_tokenIds[i], _numPeriods);
            address token = protocolInfo[_tokenIds[i]].token;
            uint payswapFees = Math.min(
                _price * IWorld(_worldHelper3).tradingFee() / 10000, 
                IContract(contractAddress).cap(token) > 0 
                ? IContract(contractAddress).cap(token) : type(uint).max
            );
            uint _bounty = ITrustBounty(_trustBounty()).getBalance(adminBountyId[token]);
            require(_bounty >= IWorld(helper).minBountyPercent() * totalProcessed[token] / 10000, "W1");
            address _user = isAdmin[msg.sender] ? ve(_minter()).ownerOf(_tokenIds[i]) : msg.sender;
            IERC20(token).safeTransferFrom(_user, address(this), _price);
            IERC20(token).safeTransfer(helper, payswapFees);
            IWorld(_worldHelper3).notifyFees(token, payswapFees);
            totalProcessed[token] += _price;
            protocolInfo[_tokenIds[i]].paidReceivable += _due;
            if(taxContract[_tokenIds[i]] != address(0x0)) {
                IBILL(taxContract[_tokenIds[i]]).notifyDebit(address(this), ve(_minter()).ownerOf(_tokenIds[i]), _price);
            }
            uint _noteTokenId = IWorld(_worldHelper3).adminNotes(address(this),_tokenIds[i]);
            (uint due,,,,) = IWorld(_worldHelper3).notes(_noteTokenId);
            if (due > 0) {
                uint _paid = _price >= due ? due : _price;
                IWorld(_worldHelper3).updatePendingRevenueFromNote(_noteTokenId, _paid);
            }
            IWorld(helper).emitAutoCharge(
                _user,
                _tokenIds[i], 
                _price
            );
        }
    }
    
    function updateTokenIds(uint[] memory _tokenIds, bool _add) external {
        uint _protocolId = addressToProtocolId[msg.sender];
        if (_add) require((_protocolTokenIds[_protocolId].length() + _tokenIds.length) <= IContract(contractAddress).maximumSize());
        address minter = _minter();
        for (uint i = 0; i < _tokenIds.length; i++) {
            if (!_protocolTokenIds[_protocolId].contains(_tokenIds[i])) {
                if (_add) {
                    IWorld(minter).attach(_tokenIds[i], msg.sender);
                    _protocolTokenIds[_protocolId].add(_tokenIds[i]);
                    totalSupply += 1;
                } else {
                    IWorld(minter).detach(_tokenIds[i], msg.sender);
                    _protocolTokenIds[_protocolId].remove(_tokenIds[i]);
                    totalSupply -= 1;
                }
            }
        }
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
        uint _protocolId,
        uint _rating,
        string memory _media,
        string memory _description
    ) external onlyAdmin {
        if(_protocolId == 0) {
            _checkIdentityProof(_owner, _identityTokenId);
            _protocolId++;
            protocolInfo[_protocolId].startReceivable = block.timestamp + _bankInfo[2];
            protocolInfo[_protocolId].amountReceivable = _bankInfo[0];
            protocolInfo[_protocolId].periodReceivable = _bankInfo[1];
            protocolInfo[_protocolId].token = _token;
            protocolInfo[_protocolId].optionId = _bankInfo[3];
        }
        addressToProtocolId[_owner] = _protocolId;
        protocolInfo[_protocolId].owner = _owner;
        protocolInfo[_protocolId].rating = _rating;
        media[_protocolId] = _media;
        description[_protocolId] = _description;
        
        IWorld(helper).emitUpdateProtocol(
            _protocolId,
            _rating,
            _owner,
            _token, 
            _media,
            _description
        );
    }

    function deleteProtocol(uint _protocolId) external onlyAdmin {
        address minter = _minter();
        for (uint i = 0; i < _protocolTokenIds[_protocolId].length(); i++) {
            IWorld(minter).detach(
                _protocolTokenIds[_protocolId].at(i),
                protocolInfo[_protocolId].owner
            );
        }
        delete protocolInfo[_protocolId];
        delete _protocolTokenIds[_protocolId];
        IWorld(helper).emitDeleteProtocol(_protocolId);
    }

    function withdraw(address _token, uint amount) external onlyAdmin {
        IERC20(_token).safeTransfer(msg.sender, amount);
    
        IWorld(helper).emitWithdraw(msg.sender, amount);
    }

    function noteWithdraw(address _to, uint _protocolId, uint amount) external {
        require(msg.sender == helper);
        IERC20(protocolInfo[_protocolId].token).safeTransfer(_to, amount);
    }
}

contract WorldNote {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using Percentile for *; 

    EnumerableSet.AddressSet private gauges;
    mapping(WorldType => EnumerableSet.UintSet) private _allVoters;
    mapping(address => uint) public percentiles;
    struct Vote {
        uint likes;
        uint dislikes;
    }
    address private contractAddress;
    mapping(WorldType => uint) private sum_of_diff_squared;
    uint public minBountyPercent = 1;
    mapping(address => Vote) public votes;
    mapping(uint => mapping(address => int)) public voted;
    mapping(uint => mapping(WorldType => address)) public profiles;
    mapping(address => uint) public worldToProfileId;

    event Voted(address indexed world, uint profileId, uint likes, uint dislikes, bool like);
    event UpdateProtocol(
        uint indexed protocolId, 
        uint rating, 
        address world, 
        address owner, 
        address token, 
        string media, 
        string description
    );
    event UpdateAutoCharge(uint indexed protocolId, address world, bool isAutoChargeable);
    event AutoCharge(uint indexed protocolId, address from, address world, uint paidReceivable);
    event DeleteProtocol(uint indexed protocolId, address world);
    event Withdraw(address indexed from, address world, uint amount);
    event UpdateMiscellaneous(
        uint idx, 
        uint worldId, 
        string paramName, 
        string paramValue, 
        uint paramValue2, 
        uint paramValue3, 
        address sender,
        address paramValue4,
        string paramValue5
    );
    event Mint(
        uint indexed tokenId, 
        address to,
        address world,
        uint start,
        uint end,
        string first4,
        string last4,
        string ext
    );
    event Transfer(uint indexed tokenId, address to);
    event CreateWorld(address indexed world, address user, uint profileId);
    event DeleteWorld(address world);

    function _trustBounty() internal view returns(address) {
        return IContract(contractAddress).trustBounty();
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender, "NT2");
        contractAddress = _contractAddress;
    }

    function setContractAddressAt(address _world) external {
        IMarketPlace(_world).setContractAddress(contractAddress);
    }

    function attach(uint _bountyId) external {
        require(gauges.contains(msg.sender));
        ITrustBounty(IContract(contractAddress).trustBountyHelper()).attach(_bountyId);
    }

    function detach(uint _bountyId) external {
        require(gauges.contains(msg.sender));
        ITrustBounty(IContract(contractAddress).trustBountyHelper()).detach(_bountyId);
    }

    function getAllWorlds(uint _start) external view returns(address[] memory worlds) {
        worlds = new address[](gauges.length() - _start);
        for (uint i = _start; i < gauges.length(); i++) {
            worlds[i] = gauges.at(i);
        }    
    }

    function isGauge(address _world) external view returns(bool) {
        return gauges.contains(_world);
    }
    
    function updateGauge(address _last_gauge, address _user, uint _profileId) external {
        require(msg.sender == IContract(contractAddress).worldFactory(), "WN1");
        require(IProfile(IContract(contractAddress).profile()).addressToProfileId(_user) == _profileId && _profileId > 0, "WN2");
        gauges.add(_last_gauge);
        worldToProfileId[_last_gauge] = _profileId;
        emit CreateWorld(_last_gauge, _user, _profileId);
    }

    function updateProfile(address _world) external {
        uint _profileId = IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender);
        require(_profileId > 0 && IAuth(_world).isAdmin(msg.sender));
        WorldType _wt = IWorld(IContract(contractAddress).worldHelper2()).getWorldType(_world);
        require(_wt != WorldType.undefined);
        profiles[_profileId][_wt] = _world;
    }
    
    function updateMinBountyPercent(uint _minBountyPercent) external {
        require(msg.sender == IAuth(contractAddress).devaddr_());
        minBountyPercent = _minBountyPercent;
    }
    
    function deleteWorld(address _world) external {
        require(msg.sender == IAuth(contractAddress).devaddr_() || IAuth(_world).isAdmin(msg.sender));
        gauges.remove(_world);
        emit DeleteWorld(_world);
    }

    function _resetVote(address _world, uint profileId) internal {
        if (voted[profileId][_world] > 0) {
            votes[_world].likes -= 1;
        } else if (voted[profileId][_world] < 0) {
            votes[_world].dislikes -= 1;
        }
    }

    function vote(address _world, uint profileId, bool like) external {
        WorldType _worldType = IWorld(IContract(contractAddress).worldHelper2()).getWorldType(_world);
        require(_worldType != WorldType.undefined);
        require(IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender) == profileId && profileId > 0);
        SSIData memory metadata = ISSI(IContract(contractAddress).ssi()).getSSID(profileId);
        require(keccak256(abi.encodePacked(metadata.answer)) != keccak256(abi.encodePacked("")));
        _resetVote(_world, profileId);        
        if (like) {
            votes[_world].likes += 1;
            voted[profileId][_world] = 1;
        } else {
            votes[_world].dislikes += 1;
            voted[profileId][_world] = -1;
        }
        uint _worldVotes;
        if (votes[_world].likes > votes[_world].dislikes) {
            _worldVotes = votes[_world].likes - votes[_world].dislikes;
        }
        _allVoters[_worldType].add(profileId);
        (uint percentile, uint sods) = Percentile.computePercentileFromData(
            false,
            _worldVotes,
            _allVoters[_worldType].length(),
            _allVoters[_worldType].length(),
            sum_of_diff_squared[_worldType]
        );
        sum_of_diff_squared[_worldType] = sods;
        percentiles[_world] = percentile;

        emit Voted(_world, profileId, votes[_world].likes, votes[_world].dislikes, like);
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

    function getGaugeNColor(uint _ssidWorldProfileId, WorldType _wt) external view returns(address, COLOR) {
        address _world = profiles[_ssidWorldProfileId][_wt];
        return (
            _world,
            _getColor(percentiles[_world])
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
        uint _worldId, 
        string memory paramName, 
        string memory paramValue, 
        uint paramValue2, 
        uint paramValue3,
        address paramValue4,
        string memory paramValue5
    ) external {
        emit UpdateMiscellaneous(
            _idx, 
            _worldId, 
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
        uint protocolId, 
        uint rating, 
        address owner,
        address token,
        string memory media,
        string memory description
    ) external {
        require(gauges.contains(msg.sender));
        emit UpdateProtocol(
            protocolId, 
            rating,
            msg.sender,
            owner, 
            token,
            media,
            description
        );
    }

    function _minter() internal view returns(address) {
        return IContract(contractAddress).worldHelper();
    }

    function emitMint(
        uint _tokenId, 
        address _to,
        address _world,
        uint _start,
        uint _end,
        string memory _first4,
        string memory _last4,
        string memory _ext
    ) external {
        require(msg.sender == _minter());
        emit Mint(_tokenId,_to,_world,_start,_end,_first4,_last4,_ext);
    }

    function emitTransfer(uint _tokenId, address _to) external {
        require(msg.sender == _minter());
        emit Transfer(_tokenId, _to);
    }

    function getDueReceivable(address _world, uint _protocolId, uint _numExtraPeriods) public view returns(uint, uint, int) {   
        (,,,uint amountReceivable,uint paidReceivable,uint periodReceivable,uint startReceivable,,) =
        IWorld(_world).protocolInfo(_protocolId);
        uint numPeriods = amountReceivable == 0 ? 1 : Math.max(1, paidReceivable / amountReceivable);
        numPeriods += _numExtraPeriods;
        uint nextDue = startReceivable + periodReceivable * numPeriods;
        uint due = nextDue < block.timestamp ? amountReceivable * numPeriods - paidReceivable : 0;
        return (
            due, // due
            nextDue, // next
            int(block.timestamp) - int(nextDue) //late or seconds in advance
        );
    }

}

contract WorldHelper {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    uint private tokenId = 1;
    mapping(uint => address) public tokenIdToWorld;
    mapping(uint => uint) private tokenIdToParent;
    mapping(uint => mapping(uint => string)) public tags;
    struct ScheduledMedia {
        uint amount;
        string message;
    }
    mapping(uint => ScheduledMedia) public scheduledMedia;
    mapping(uint => uint) public pendingRevenue;
    uint private worldPercent = 5000;
    mapping(uint => mapping(uint => uint)) public paidRevenue;
    mapping(uint => mapping(string => EnumerableSet.UintSet)) private _scheduledMedia;
    uint internal minute = 3600; // allows minting once per week (reset every Thursday 00:00 UTC)
    uint private currentMediaIdx = 1;
    struct Channel {
        string message;
        uint active_period;
    }
    mapping(uint => mapping(string => Channel)) public channels;
    mapping(uint => mapping(string => bool)) public tagRegistrations;
    // first4 => last4 => ext
    mapping(string => mapping(string => string)) public registeredCodes;
    mapping(WorldType => mapping(string => uint)) public registeredTo;
    address private contractAddress;
    address private valuepoolAddress;
    uint public treasury;
    uint public valuepool;

    uint internal constant week = 86400 * 7;
    struct Code {
        address world;
        uint start;
        uint end;
        uint planet;
        uint rating;
        string first4;
        string last4;
        string ext;
        COLOR color;
        WorldType worldType;
    }
    mapping(uint => Code) public codeInfo;

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function updateValuepool(address _valuepoolAddress) external {
        require(IAuth(contractAddress).devaddr_() == msg.sender);
        valuepoolAddress = _valuepoolAddress;
    }

    function getMedia(uint _tokenId) public view returns(string[] memory _media) {
        address _world = tokenIdToWorld[_tokenId];
        uint _worldId = IWorld(IContract(contractAddress).worldNote()).worldToProfileId(_world);
        string memory _tag = tags[_worldId][_tokenId];
        if (tagRegistrations[_worldId][_tag]) {
            _media = new string[](_scheduledMedia[1][_tag].length() + 1);
            uint idx;
            _media[idx] = IWorld(_world).media(_tokenId);
            for (uint i = 0; i < _scheduledMedia[1][_tag].length(); i++) {
                uint _currentMediaIdx = _scheduledMedia[1][_tag].at(i);
                _media[idx] = scheduledMedia[_currentMediaIdx].message;
            }
        } else {
            _media = new string[](_scheduledMedia[_worldId][_tag].length() + 1);
            uint idx;
            _media[idx] = IWorld(_world).media(_tokenId);
            for (uint i = 0; i < _scheduledMedia[_worldId][_tag].length(); i++) {
                uint _currentMediaIdx = _scheduledMedia[_worldId][_tag].at(i);
                _media[idx] = scheduledMedia[_currentMediaIdx].message;
            }
        }
    }

    function updateTagRegistration(string memory _tag, bool _add) external {
        uint _worldId = IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender);
        require(_worldId > 0);
        tagRegistrations[_worldId][_tag] = _add;
        IWorld(IContract(contractAddress).worldNote()).emitUpdateMiscellaneous(
            1,
            _worldId,
            _tag,
            "",
            _add ? 1 : 0,
            0,
            address(0x0),
            ""
        );
    }
    
    function claimPendingRevenue() external lock {
        uint _worldId = IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender);
        uint _toPay = pendingRevenue[_worldId] * worldPercent / 10000  - paidRevenue[_worldId][0];
        IERC20(IContract(contractAddress).token()).safeTransfer(address(msg.sender), _toPay);
        paidRevenue[_worldId][0] += _toPay;
    }

    function _ownerOf(uint _tokenId) internal view returns(address) {
        return ve(IContract(contractAddress).worldHelper2()).ownerOf(_tokenId);
    }

    function claimPendingRevenueFromTokenId(uint _tokenId) external lock {
        require(_ownerOf(_tokenId) == msg.sender, "WH1");
        uint _worldId = IWorld(IContract(contractAddress).worldNote()).worldToProfileId(codeInfo[_tokenId].world);
        require(_worldId > 0);
        uint _totalSupply = IWorld(codeInfo[_tokenId].world).totalSupply();
        uint _toDistribute = pendingRevenue[_worldId] * (10000 - worldPercent) / 10000;
        uint _toPay = _toDistribute / _totalSupply - paidRevenue[_worldId][_tokenId];
        IERC20(IContract(contractAddress).token()).safeTransfer(address(msg.sender), _toPay);
        paidRevenue[_worldId][_tokenId] += _toPay;
    }

    function sponsorTag(
        address _sponsor,
        address _world,
        uint _amount, 
        string memory _tag, 
        string memory _message
    ) external {
        uint _worldId = IWorld(IContract(contractAddress).worldNote()).worldToProfileId(_world);
        address worldHelper3 = IContract(contractAddress).worldHelper3();
        require(IAuth(_sponsor).isAdmin(msg.sender), "NTH9");
        require(!ISponsor(_sponsor).contentContainsAny(IWorld(worldHelper3).getExcludedContents(_worldId, _tag)), "NTH10");
        uint _pricePerAttachMinutes = IWorld(worldHelper3).pricePerAttachMinutes(_worldId);
        if (_pricePerAttachMinutes > 0) {
            uint price = _amount * _pricePerAttachMinutes;
            IERC20(IContract(contractAddress).token()).safeTransferFrom(address(msg.sender), address(this), price);
            uint valuepoolShare = IContract(contractAddress).valuepoolShare();
            uint adminShare = IContract(contractAddress).adminShare();
            valuepool += price * valuepoolShare / 10000;
            if (_worldId > 0) {
                treasury += price * adminShare / 10000;
                pendingRevenue[_worldId] += price * (10000 - adminShare - valuepoolShare) / 10000;
            } else {
                treasury += price * (10000 - valuepoolShare) / 10000;
            }
            scheduledMedia[currentMediaIdx] = ScheduledMedia({
                amount: _amount,
                message: _message
            });
            _scheduledMedia[_worldId][_tag].add(currentMediaIdx++);
            updateSponsorMedia(_worldId, _tag);
        }
    }

    function updateSponsorMedia(uint _worldId, string memory _tag) public {
        require(channels[_worldId][_tag].active_period < block.timestamp, "NTH12");
        uint idx = _scheduledMedia[_worldId][_tag].at(0);
        channels[_worldId][_tag].active_period = block.timestamp + scheduledMedia[idx].amount*minute / minute * minute;
        channels[_worldId][_tag].message = scheduledMedia[idx].message;
        address worldHelper2 = IContract(contractAddress).worldHelper2();
        if (_scheduledMedia[_worldId][_tag].length() > IWorld(worldHelper2).maxNumMedia()) {
            _scheduledMedia[_worldId][_tag].remove(idx);
        }
    }

    function attach(uint _tokenId, address _user) external {
        require(IWorld(IContract(contractAddress).worldNote()).isGauge(msg.sender));
        require(_ownerOf(_tokenId) == _user);
        address worldHelper2 = IContract(contractAddress).worldHelper2();
        WorldType _wt1 = IWorld(worldHelper2).getWorldType(codeInfo[_tokenId].world);
        WorldType _wt2 = IWorld(worldHelper2).getWorldType(msg.sender);
        require(_wt1 == _wt2);
        codeInfo[_tokenId].world = msg.sender;
    }

    function detach(uint _tokenId, address _user) external {
        require(IWorld(IContract(contractAddress).worldNote()).isGauge(msg.sender));
        require(_ownerOf(_tokenId) == _user);
        codeInfo[_tokenId].world = address(0x0);
        codeInfo[_tokenId].rating = 0;
    }

    function updateCodeInfo(address _world, uint[] memory _tokenIds, uint _rating) external {
        require(IWorld(IContract(contractAddress).worldNote()).isGauge(_world) && IAuth(_world).isAdmin(msg.sender));
        for (uint i = 0; i < _tokenIds[i]; i++) {
            require(codeInfo[_tokenIds[i]].world == _world);
            codeInfo[_tokenIds[i]].rating = _rating;
        }
    }

    function setColor(
        address _world, 
        address _to, 
        uint _tokenId, 
        string memory curr
    ) external {
        address worldHelper2 = IContract(contractAddress).worldHelper2();
        require(msg.sender == worldHelper2);
        address worldNote = IContract(contractAddress).worldNote();
        WorldType _wt = IWorld(worldHelper2).getWorldType(_world);
        (,COLOR _color) = IWorld(worldNote).getGaugeNColor(IWorld(worldNote).worldToProfileId(_world), _wt);
        (,COLOR _color2) = IWorld(worldNote).getGaugeNColor(
            IWorld(worldNote).worldToProfileId(codeInfo[registeredTo[_wt][curr]].world),
            codeInfo[registeredTo[_wt][curr]].worldType
        );
        require(_color2 < IWorld(worldHelper2).minColor(),"WH2");
        codeInfo[_tokenId].world = _world;
        codeInfo[_tokenId].color = _color;
        IWorld(worldHelper2).transferNFT(_ownerOf(registeredTo[_wt][curr]), _to, registeredTo[_wt][curr]);
        IWorld(worldNote).emitTransfer(registeredTo[_wt][curr], _to);
    }

    function newMint(
        address _to, 
        address _world, 
        uint _start, 
        uint _end, 
        uint _planet,
        string memory __first4, 
        string memory __last4,
        string memory _ext
    ) external {
        address worldHelper2 = IContract(contractAddress).worldHelper2();
        require(msg.sender == worldHelper2);
        address worldNote = IContract(contractAddress).worldNote();
        string memory codeName = string(abi.encodePacked(__first4,__last4,'+',_ext,'_',toString(_planet)));
        WorldType _wt = IWorld(worldHelper2).getWorldType(_world);
        (,COLOR _color) = IWorld(worldNote).getGaugeNColor(IWorld(worldNote).worldToProfileId(_world), _wt);
        codeInfo[tokenId].world = _world;
        codeInfo[tokenId].color = _color;
        codeInfo[tokenId].start = _start;
        codeInfo[tokenId].end = _end;
        codeInfo[tokenId].planet = _planet;
        codeInfo[tokenId].first4 = __first4;
        codeInfo[tokenId].last4 = __last4;
        codeInfo[tokenId].ext = _ext;
        codeInfo[tokenId].worldType = _wt;
        registeredTo[_wt][codeName] = tokenId;
        registeredCodes[__first4][__last4] = _ext;
        tokenIdToWorld[tokenId] = _world;
        IWorld(worldHelper2).safeMint(_to, tokenId);
        IWorld(worldNote).emitMint(
            tokenId++, 
            _to,
            _world,
            _start,
            _end,
            __first4,
            __last4,
            _ext
        );
    }

    function burn(uint[] memory _tokenIds) external {
        require(msg.sender == IAuth(contractAddress).devaddr_());
        for (uint i = 0; i < _tokenIds.length; i++) {
            IWorld(IContract(contractAddress).worldHelper2()).burn(_tokenIds[i]);
            delete codeInfo[_tokenIds[i]];
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

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }

    function claimValuepoolRevenue() external {
        require(msg.sender == IAuth(contractAddress).devaddr_(), "NTH11");
        IERC20(IContract(contractAddress).token()).safeTransfer(valuepoolAddress, valuepool);
        valuepool = 0;
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

contract WorldHelper2 is ERC721Pausable {
    uint private maxNumMedia = 2;
    mapping(address => WorldType) public categories;
    // first4 => last4 => ext
    address private contractAddress;
    uint internal constant week = 86400 * 7;
    uint private timeframe = 26;
    uint public minBounty;
    mapping(address => uint) public bounties;
    COLOR public minColor = COLOR.BLACK;
    mapping(address => address) private uriGenerator;
    
    constructor() ERC721("PlusCode", "PlusCode")  {}

    function getWorldType(address _world) external view returns(WorldType) {
        return categories[_world];
    }

    function updateCategory(address _world, WorldType _category) external {
        require(IAuth(_world).isAdmin(msg.sender) && categories[_world] == WorldType.undefined);
        categories[_world] = _category;
    }

    function updateMinBounty(uint _minBounty) external {
        require(msg.sender == IAuth(contractAddress).devaddr_());
        minBounty = _minBounty;
    }

    // function getName(address _world) external view returns(string memory) {
    //     WorldType _wt = categories[_world];
    //     return _wt == WorldType.RPWorld
    //     ? "Red Pill Code"
    //     : _wt == WorldType.BPWorld
    //     ? "Blue Pill Code"
    //     : "Green World Code";
    // }

    function getToken(address _world) public view returns(address) {
        WorldType _wt = categories[_world];
        if (_wt == WorldType.RPWorld) {
            return 0x71635D9FEaE672a3c21386C7a615A467525c91e9;
        } else if (_wt == WorldType.RPWorld) {
            return 0x5790c3534F30437641541a0FA04C992799602998;
        } else {
            return 0xe486De509c5381cbdBF3e71F57D7F1f7570f5c46;
        }
    }
    
    function updateBounty(address _world, uint _bountyId) external {
        address worldNote = IContract(contractAddress).worldNote();
        (address owner,address _token,,address claimableBy,,,,,,) = 
        ITrustBounty(IContract(contractAddress).trustBounty()).bountyInfo(_bountyId);
        require(IWorld(worldNote).isGauge(_world) && IAuth(_world).isAdmin(owner));
        require(
            owner == msg.sender && 
            _token == IContract(contractAddress).token() && 
            claimableBy == address(0x0)
        );
        bounties[_world] = _bountyId;
    }

    function mintPastWorld(
        address _to, 
        address _world,
        uint _start,
        uint _planet,
        string[] memory _first4, 
        string[] memory _last4,
        string[] memory _nfts
    ) external {
        require(IWorld(IContract(contractAddress).worldNote()).isGauge(_world) && IAuth(_world).isAdmin(msg.sender));
        (string memory __first4, string memory __last4) = getCodes(_world, _first4, _last4);
        for (uint i = 0; i < _nfts.length; i++) {
            _callNewMintFromPast(
                _to,
                _world,
                _start,
                _planet,
                __first4,
                __last4,
                _nfts[i]
            );
        }
    }

    function _checkParams(address _world, uint _end, string memory curr, string memory _nft) internal view {
        address worldHelper = IContract(contractAddress).worldHelper();
        (,uint start,,,,,,,,) = IWorld(worldHelper).codeInfo(1);
        require(start > _end); //first code must be after any past code
        require(PlusCodes.checkExtension(_nft));
        (,,uint end,,,,,,,) = IWorld(worldHelper).codeInfo(IWorld(worldHelper).registeredTo(categories[_world], curr));
        require(end == 0);
    }

    function _callNewMintFromPast(
        address _to,
        address _world,
        uint _start,
        uint _planet,
        string memory __first4,
        string memory __last4,
        string memory _nft
    ) internal {
        uint period = timeframe * week;
        uint _end = (_start + period) / period * period;
        require(categories[_world] != WorldType.undefined);
        string memory curr = string(abi.encodePacked(__first4,__last4,'+',_nft,'_',toString(_planet)));
        _checkParams(_world, _end, curr, _nft);
        IWorld(IContract(contractAddress).worldHelper()).newMint(
            _to,
            _world,
            _start,
            _end,
            _planet,
            __first4,
            __last4,
            _nft
        );
    }

    function batchMint(
        address _to, 
        address _world,
        uint _planet,
        string[][] memory _first4, 
        string[][] memory _last4,
        string[][] memory _nfts
    ) external {
        for (uint k = 0; k < _nfts.length; k++) {
            _mintCode(
                _to,
                _world,
                _planet,
                _first4[k],
                _last4[k],
                _nfts[k]
            );
        }
    }

    function _mintCode(
        address _to, 
        address _world,
        uint _planet,
        string[] memory _first4, 
        string[] memory _last4,
        string[] memory _nfts
    ) internal {
        require(IWorld(IContract(contractAddress).worldNote()).isGauge(_world) && IAuth(_world).isAdmin(msg.sender), "WHH1");
        require(categories[_world] != WorldType.undefined,"WHH2");
        (string memory __first4, string memory __last4) = getCodes(_world, _first4, _last4);
        for (uint i = 0; i < _nfts.length; i++) {
            require(PlusCodes.checkExtension(_nfts[i]));
            _callNewMint(
                _to,
                _world,
                _planet,
                __first4,
                __last4,
                _nfts[i]
            );
        }
    }

    function _callNewMint(
        address _to,
        address _world,
        uint _planet,
        string memory __first4,
        string memory __last4,
        string memory _nft
    ) internal {
        uint period = timeframe * week;
        address worldHelper = IContract(contractAddress).worldHelper();
        string memory curr = string(abi.encodePacked(__first4,__last4,'+',_nft,'_',toString(_planet)));
        uint _tokenId = IWorld(worldHelper).registeredTo(categories[_world], curr);
        (,,uint end,uint planet,,,,,,) = IWorld(worldHelper).codeInfo(_tokenId);
        if ( _tokenId > 0 && end > block.timestamp && planet == _planet) {
            IWorld(worldHelper).setColor(_world, _to, _tokenId, curr);
        } else {
            IWorld(worldHelper).newMint(
                _to,
                _world,
                block.timestamp,
                (block.timestamp + period) / period * period,
                _planet,
                __first4,
                __last4,
                _nft
            );
        }
    }

    function getCodes(
        address _world,
        string[] memory _first4, 
        string[] memory _last4
    ) public view returns(string memory,string memory) {
        address worldNote = IContract(contractAddress).worldNote();
        require(IWorld(worldNote).isGauge(_world) && IAuth(_world).isAdmin(msg.sender));
        require(PlusCodes.isPlusCodeFirstFour(_first4[0], _first4[1], _first4[2], _first4[3]));
        require(PlusCodes.isPlusCodeLastFour(_last4[0], _last4[1], _last4[2], _last4[3]));
        if (minBounty > 0) {
            uint _bounty = ITrustBounty(IContract(contractAddress).trustBounty()).getBalance(bounties[_world]);
            require(bounties[_world] > 0 && _bounty >= minBounty);
        }
        string memory __first4 = string(abi.encodePacked(_first4[0],_first4[1],_first4[2],_first4[3]));
        string memory __last4 = string(abi.encodePacked(_last4[0],_last4[1],_last4[2],_last4[3]));
        (,COLOR _color) = IWorld(worldNote).getGaugeNColor(IWorld(worldNote).worldToProfileId(_world), categories[_world]);
        require(_color >= minColor);
        return (__first4, __last4);
    }

    function getRating(uint _tokenId, uint _rating, address world) public view returns(uint) {
        if (_rating > 0) return _rating;
        uint _protocolId = IWorld(world).addressToProtocolId(ownerOf(_tokenId));
        (,,,,,,,uint rating,) = IWorld(world).protocolInfo(_protocolId);
        return rating;
    }
    
    function transferNFT(address from, address to, uint _tokenId) external {
        require(IContract(contractAddress).worldHelper() == msg.sender);
        _transfer(from, to, _tokenId);
    }

    function updateTimeFrame(uint _timeframe, COLOR _minColor) external {
        require(msg.sender == IAuth(contractAddress).devaddr_());
        timeframe = _timeframe;
        minColor = _minColor;
    }

    function updateMaxNumMedia(uint _maxNumMedia) external {
        require(IAuth(contractAddress).devaddr_() == msg.sender);
        maxNumMedia = _maxNumMedia;
    }

    function safeMint(address _to, uint _tokenId) external {
        require(IContract(contractAddress).worldHelper() == msg.sender, "WHH3");
        _safeMint(_to, _tokenId, msg.data);
        IWorld(IContract(contractAddress).worldNote()).emitUpdateMiscellaneous(
            2, 
            _tokenId, 
            "", 
            "", 
            _tokenId, 
            0, 
            msg.sender,
            ""
        );
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }

    function updateUriGenerator(address _world, address _uriGenerator) external {
        require(IWorld(IContract(contractAddress).worldNote()).isGauge(_world) && IAuth(_world).isAdmin(msg.sender));
        uriGenerator[_world] = _uriGenerator;
    }

    function _getOptions(uint _worldId, uint _tokenId) internal view returns(string[] memory optionNames, string[] memory optionValues) {
        uint idx;
        // address worldHelper = IContract(contractAddress).worldHelper();
        (address world,uint start,uint end,uint planet,uint rating,string memory _first4,string memory _last4,string memory _ext,COLOR _color,) = 
        IWorld(IContract(contractAddress).worldHelper()).codeInfo(_tokenId);
        optionNames = new string[](7);
        optionValues = new string[](7);
        optionNames[idx] = "WID";
        optionValues[idx++] = toString(_worldId);
        optionNames[idx] = "Start";
        optionValues[idx++] = toString(start);
        optionNames[idx] = "End";
        optionValues[idx++] = toString(end);
        optionNames[idx] = "Planet";
        optionValues[idx++] = toString(planet);
        optionNames[idx] = "Rating";
        optionValues[idx++] = toString(getRating(_tokenId, rating, world));
        optionNames[idx] = "PlusCode";
        optionValues[idx++] = string(abi.encodePacked(_first4,_last4, "+", _ext));
        optionNames[idx] = "Color";
        optionValues[idx++] = _color == COLOR.GOLD 
        ? "Gold" 
        : _color == COLOR.SILVER 
        ? "Silver"
        : _color == COLOR.BROWN
        ? "Brown"
        : "Black";
    }

    function tokenURI(uint _tokenId) public view override returns (string memory output) {
        address _worldHelper = IContract(contractAddress).worldHelper();
        address _world = IWorld(_worldHelper).tokenIdToWorld(_tokenId);
        if (uriGenerator[_world] != address(0x0)) {
            output = IWorld(uriGenerator[_world]).uri(_tokenId);
        } else {
            (string[] memory optionNames, string[] memory optionValues) = _getOptions(
                IWorld(IContract(contractAddress).worldNote()).worldToProfileId(_world), 
                _tokenId
            ); // max number = 12
            string[] memory _description = IWorld(_world).getDescription(_tokenId); // max number = 1
            string[] memory _media = IWorld(_worldHelper).getMedia(_tokenId); // max number = 2
            output = _constructTokenURI(_world, _tokenId, _media, _description, optionNames, optionValues);
        }
    }

    function _constructTokenURI(address _world, uint _tokenId, string[] memory _media, string[] memory _description, string[] memory optionNames, string[] memory optionValues) internal view returns(string memory) {
        return IMarketPlace(IContract(contractAddress).nftSvg()).constructTokenURI(
            _tokenId,
            "",
            getToken(_world),
            getToken(_world),
            ownerOf(_tokenId),
            address(0x0),
            _media.length > 0 ? _media : new string[](1),
            optionNames,
            optionValues,
            _description.length > 0 ? _description : new string[](1)
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

contract WorldHelper3 is ERC721Pausable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    
    struct RPWorldNote {
        uint due;
        uint timer;
        uint protocolId;
        address token;
        address world;
    }
    uint private tokenId = 1;
    address public contractAddress;
    uint public tradingFee = 100;
    mapping(address => uint) public treasuryFees;
    mapping(uint => RPWorldNote) public notes;
    mapping(address => mapping(uint => uint)) public adminNotes;
    mapping(uint => uint) public pendingRevenueFromNote;
    mapping(uint => uint) public pricePerAttachMinutes;
    mapping(uint => mapping(string => EnumerableSet.UintSet)) private _excludedContents;

    constructor() ERC721("WorldNote", "nWorld")  {}

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function withdrawFees(address _token) external returns(uint _amount) {
        require(msg.sender == IAuth(contractAddress).devaddr_());
        _amount = treasuryFees[_token];
        IERC20(_token).safeTransfer(msg.sender, _amount);
        treasuryFees[_token] = 0;
        return _amount;
    }

    function updateTradingFee(uint _tradingFee) external {
        require(msg.sender == IAuth(contractAddress).devaddr_());
        tradingFee = _tradingFee;
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }

    function updatePricePerAttachMinutes(uint _pricePerAttachMinutes) external {
        uint _worldId = IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender);
        pricePerAttachMinutes[_worldId] = _pricePerAttachMinutes;
    }

    function getExcludedContents(uint _worldId, string memory _tag) external view returns(string[] memory _excluded) {
        _excluded = new string[](_excludedContents[_worldId][_tag].length());
        for (uint i = 0; i < _excluded.length; i++) {
            _excluded[i] = IContent(contractAddress).indexToName(_excludedContents[_worldId][_tag].at(i));
        }
    }

    function updateExcludedContent(string memory _tag, string memory _contentName, bool _add) external {
        uint _worldId = IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender);
        require(_worldId > 0);
        if (_add) {
            require(IContent(contractAddress).contains(_contentName), "WHHH01");
            _excludedContents[_worldId][_tag].add(uint(keccak256(abi.encodePacked(_contentName))));
        } else {
            _excludedContents[_worldId][_tag].remove(uint(keccak256(abi.encodePacked(_contentName))));
        }
    }

    function buyWithContract(
        address _world,
        address _user,
        address _referrer,
        uint _protocolId,
        uint _numPeriods,
        uint[] memory _protocolIds   
    ) external {
        require(IValuePool(IContract(contractAddress).valuepoolHelper()).isGauge(msg.sender));
        require(IWorld(IContract(contractAddress).worldNote()).isGauge(_world), "WHHH1");
        (uint _price,) = IWorld(_world).getReceivable(_protocolIds[0], _numPeriods);
        (,address _token,,,,,,,) = IWorld(_world).protocolInfo(_protocolIds[0]);
        erc20(_token).approve(_world, _price);
        IWorld(_world).autoCharge(_protocolIds, _numPeriods);
    }

    function transferDueToNoteReceivable(
        address _world,
        address _to, 
        uint _protocolId, 
        uint _numPeriods
    ) external lock {
        address worldNote = IContract(contractAddress).worldNote();
        require(IWorld(worldNote).isGauge(_world));
        (uint dueReceivable, uint nextDue,) = IWorld(worldNote).getDueReceivable(_world, _protocolId, _numPeriods);
        require(IAuth(_world).isAdmin(msg.sender), "You can't transfer a nul balance");
        (,address _token,,,,,,,) = IWorld(_world).protocolInfo(_protocolId);
        adminNotes[_world][_protocolId] = tokenId;
        notes[tokenId] = RPWorldNote({
            due: dueReceivable,
            token: _token,
            timer: nextDue,
            protocolId: _protocolId,
            world: _world
        });
        _safeMint(_to, tokenId, msg.data);
        IWorld(worldNote).emitUpdateMiscellaneous(
            3, 
            _protocolId, 
            "", 
            "", 
            tokenId++, 
            0, 
            _world,
            ""
        );
    }

    function notifyFees(address _token, uint _fees) external {
        require(IWorld(IContract(contractAddress).worldNote()).isGauge(msg.sender));
        treasuryFees[_token] += _fees;
    }
    
    function claimPendingRevenueFromNote(uint _tokenId) external lock {
        require(ownerOf(_tokenId) == msg.sender, "Only owner!");
        require(notes[_tokenId].timer <= block.timestamp, "Not yet due");
        uint256 revenueToClaim = pendingRevenueFromNote[_tokenId];
        _burn(_tokenId);
        delete pendingRevenueFromNote[_tokenId];
        delete adminNotes[notes[_tokenId].world][notes[_tokenId].protocolId];
        uint payswapFees = revenueToClaim * tradingFee / 10000;
        IWorld(notes[_tokenId].world).noteWithdraw(address(msg.sender), notes[_tokenId].protocolId, revenueToClaim - payswapFees);
        IWorld(notes[_tokenId].world).noteWithdraw(address(this), notes[_tokenId].protocolId, payswapFees);
        treasuryFees[notes[_tokenId].token] += payswapFees;
        delete notes[_tokenId];
    }

    function updatePendingRevenueFromNote(uint _tokenId, uint _paid) external {
        require(IWorld(IContract(contractAddress).worldNote()).isGauge(msg.sender));
        notes[tokenId].due -= _paid;
        pendingRevenueFromNote[_tokenId] += _paid;
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
        _description[0] = "This note gives you access to revenues of the world on the specified protocol";
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

contract WorldFactory {
    address public contractAddress;

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }

    function createGauge(uint _profileId, address _devaddr) external {
        address note = IContract(contractAddress).worldNote();
        address last_gauge = address(new World(
            _devaddr,
            note,
            contractAddress
        ));
        IWorld(note).updateGauge(
            last_gauge, 
            _devaddr, 
            _profileId
        );
    }
}
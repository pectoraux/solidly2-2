// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Library.sol";

// Gauges are used to incentivize pools, they emit reward tokens over 7 days for staked LP tokens
contract Profile {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(address => uint) public sum_of_diff_squared;
    mapping(address => uint) public total;
    uint bufferTime = 14 days;
    uint limitFactor = 10000;
    uint constant INITIAL_PROFILE_ID = 2;
    mapping(address => EnumerableSet.AddressSet) private _allContracts;
    mapping(uint => EnumerableSet.UintSet) private _badgeIds;
    mapping(uint => ProfileInfo) public profileInfo;
    mapping(uint => EnumerableSet.UintSet) private followers;
    mapping(address => uint) public addressToProfileId;
    mapping(uint => EnumerableSet.AddressSet) private accounts;
    uint public profileId = INITIAL_PROFILE_ID;
    mapping(string => bool) private usedSSID;
    // profileid => token => bountyid
    mapping(uint => mapping(address => uint)) public bounties;
    mapping(address => bool) private isHelper;
    mapping(uint => bool) private isFollowerAuditor;
    mapping(address => mapping(uint =>  CreditReport)) public goldReported;
    mapping(address => mapping(uint =>  CreditReport)) public silverReported;
    mapping(address => mapping(uint =>  CreditReport)) public brownReported;
    mapping(address => mapping(uint => CreditReport)) public blackReported;
    mapping(uint => mapping(address => uint)) public pendingRevenue;
    mapping(uint => mapping(uint => bool)) public isBlacklisted;
    string idValueName = "ssid";
    address contractAddress;
    mapping(uint => uint) public timeConstraint;
    mapping(uint => mapping(address => uint)) private addressToSSIDDeadline;
    mapping(uint => uint) public referrer;
    mapping(uint => bool) public isUnique;
    mapping(bytes32 => uint) private isNameTaken;
    mapping(address => bool) public sharedEmail;
    
    event CreateProfile(uint indexed profileId, string name);
    event PayProfile(address token, uint profileId, uint amount);
    event ClaimRevenue(address token, uint profileId, uint amount);
    event Follow(uint followerProfileId, uint followeeProfileId);
    event UpdateBlackList(uint ownerProfileId, uint userProfileId, bool add);
    event UpdateFollowerAuditor(uint auditorProfileId, bool add);
    event UpdateHelper(address helper, bool add);
    event AddAccount(uint profileId, address account);
    event RemoveAccount(uint profileId, address account);
    event AddBounty(uint profileId, uint bountyId, address token);
    event UpdateCollectionId(uint profileId, uint collectionId);
    event Unfollow(uint followeeProfileId, uint followerProfileId);
    event DeleteProfile(uint profileId);
    event UpdateMiscellaneous(
        uint idx, 
        uint collectionId, 
        string paramName, 
        string paramValue, 
        uint paramValue2, 
        uint paramValue3, 
        address sender,
        address paramValue4,
        string paramValue5
    );
    
    constructor() {
        isFollowerAuditor[1] = true; 
        sharedEmail[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(IAuth(contractAddress).devaddr_() == msg.sender);
        _;
    }

    modifier respectTimeConstraint() {
        uint _profileId = addressToProfileId[msg.sender];
        require(
            addressToSSIDDeadline[_profileId][msg.sender] >= timeConstraint[_profileId],
            "P00"
        );
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

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender, "PH1");
        contractAddress = _contractAddress;
    }

    function _ssi() internal view returns(address) {
        return IContract(contractAddress).ssi();
    }

    function _badgeNft() internal view returns(address) {
        return IContract(contractAddress).badgeNft();
    }

    function _trustBounty() internal view returns(address) {
        return IContract(contractAddress).trustBounty();
    }

    function _marketCollections() internal view returns(address) {
        return IContract(contractAddress).marketCollections();
    }

    function _rampHelper() internal view returns(address) {
        return IContract(contractAddress).rampHelper();
    }

    function _helper() internal view returns(address) {
        return IContract(contractAddress).profileHelper();
    }

    function updateHelper(address __helper, bool _add) external onlyAdmin {
        isHelper[__helper] = _add;
        emit UpdateHelper(__helper, _add);
    }
    
    function updateBlackList(uint _profileId, bool _add) external {
        isBlacklisted[addressToProfileId[msg.sender]][_profileId] = _add;
        emit UpdateBlackList(addressToProfileId[msg.sender], _profileId, _add);
    }

    function updateFollowerAuditor(uint _auditorProfileId, bool _add) external onlyAdmin {
        isFollowerAuditor[_auditorProfileId] = _add;
        emit UpdateFollowerAuditor(_auditorProfileId, _add);
    }

    function updateParameters(
        uint _bufferTime, 
        uint _limitFactor,
        string memory _idValueName
    ) external onlyAdmin {
        bufferTime = _bufferTime;
        limitFactor = _limitFactor;
        idValueName = _idValueName;
    }
    
    function getParams() external view returns(uint,uint,string memory) {
        return (
            bufferTime,
            limitFactor,
            idValueName
        );
    }

    function getIsNameTaken(string memory _name) external view returns(uint) {
        return isNameTaken[keccak256(abi.encodePacked(_name))];
    }

    function getAllFollowers(uint _profileId, uint _start) external view returns(uint[] memory _followers) {
        _followers = new uint[](followers[_profileId].length() - _start);
        for (uint i = _start; i < followers[_profileId].length(); i++) {
            if (!isBlacklisted[_profileId][followers[_profileId].at(i)]) {
                _followers[i] = followers[_profileId].at(i);
            }
        }    
    }

    function getAllBadgeIds(uint _profileId, uint _start) external view returns(uint[] memory _allBadgeIds) {
        _allBadgeIds = new uint[](_badgeIds[_profileId].length() - _start);
        for (uint i = _start; i < _badgeIds[_profileId].length(); i++) {
            _allBadgeIds[i] = _badgeIds[_profileId].at(i);
        }    
    }

    function getAllAccounts(uint _profileId, uint _start) external view returns(address[] memory _accounts) {
        _accounts = new address[](accounts[_profileId].length() - _start);
        for (uint i = _start; i < accounts[_profileId].length(); i++) {
            _accounts[i] = accounts[_profileId].at(i);
        }    
    }

    function addAccount(uint _profileId, address _account) external respectTimeConstraint {
        require(addressToProfileId[msg.sender] == _profileId, "P2");
        SSIData memory metadata = ISSI(_ssi()).getSSID(_profileId);
        require(keccak256(abi.encodePacked(profileInfo[_profileId].ssid)) == keccak256(abi.encodePacked(metadata.answer)), "P4");
        accounts[_profileId].add(_account);
        addressToProfileId[_account] = _profileId;
        addressToSSIDDeadline[_profileId][_account] = addressToSSIDDeadline[_profileId][msg.sender];

        emit AddAccount(_profileId, _account);
    }
    
    function removeAccount(uint _profileId, address _account) external respectTimeConstraint {
        require(addressToProfileId[msg.sender] == _profileId, "P9");
        SSIData memory metadata = ISSI(_ssi()).getSSID(_profileId);
        require(keccak256(abi.encodePacked(profileInfo[_profileId].ssid)) == keccak256(abi.encodePacked(metadata.answer)), "P10");
        accounts[_profileId].remove(_account);
        delete addressToProfileId[_account];
        emit RemoveAccount(_profileId, _account);
    }

    function follow(uint _profileId) external respectTimeConstraint {
        _follow(_profileId, addressToProfileId[msg.sender], msg.sender);
    }

    function deleteProfile(bool _detachSSID) external respectTimeConstraint {
        uint _profileId = addressToProfileId[msg.sender];
        if (isUnique[_profileId] && _detachSSID) {
            delete usedSSID[profileInfo[_profileId].ssid];
            delete isUnique[_profileId];
        }
        delete isNameTaken[keccak256(abi.encodePacked(profileInfo[_profileId].name))];
        delete profileInfo[_profileId];
        delete addressToProfileId[msg.sender];
        IProfile(_helper()).burn(_profileId);
        emit DeleteProfile(_profileId);
    }

    function _follow(
        uint _profileId, 
        uint _followerProfileId,
        address _user
    ) internal {
        require(!isBlacklisted[_profileId][_followerProfileId], "P10");
        require(sharedEmail[_user], "P11");
        
        followers[_profileId].add(_followerProfileId);

        emit Follow(_followerProfileId, _profileId);
    }

    function unFollow(uint _profileId) external respectTimeConstraint {
        followers[_profileId].remove(addressToProfileId[msg.sender]);

        emit Unfollow(_profileId, addressToProfileId[msg.sender]);
    }

    function updateBadgeId(uint _badgeId, bool _add) external respectTimeConstraint {
        require(ve(_badgeNft()).ownerOf(_badgeId) == msg.sender, "P12");
        require(addressToProfileId[msg.sender] > 0, "P13");
        if (_add) {
            _badgeIds[addressToProfileId[msg.sender]].add(_badgeId);
        } else {
            _badgeIds[addressToProfileId[msg.sender]].remove(_badgeId);
        }
    }
    
    function updateSSID() external {
        uint _profileId = addressToProfileId[msg.sender];
        SSIData memory metadata = ISSI(_ssi()).getSSID(_profileId);
        require(!usedSSID[metadata.answer], "P16");
        usedSSID[metadata.answer] = true;
        isUnique[_profileId] = true;
        profileInfo[_profileId].ssid = metadata.answer;
        addressToSSIDDeadline[_profileId][msg.sender] = metadata.deadline;
        profileInfo[_profileId].ssidAuditorProfileId = metadata.auditorProfileId;
    }

    function updateTimeConstraint() external respectTimeConstraint {
        uint _profileId = addressToProfileId[msg.sender];
        require(isUnique[_profileId], "P016");
        SSIData memory metadata = ISSI(_ssi()).getSSID(_profileId);
        if (timeConstraint[_profileId] < metadata.deadline) {
            addressToSSIDDeadline[_profileId][msg.sender] = metadata.deadline;
            timeConstraint[_profileId] = metadata.deadline;
        }
    }
    
    function referrerFromAddress(address _user) external view returns(uint) {
        return referrer[addressToProfileId[_user]];
    }

    function shareEmail(address _account) external {
        require(isFollowerAuditor[addressToProfileId[msg.sender]], "P17");
        sharedEmail[_account] = true;
    }

    function createSpecificProfile(string memory _name, uint _profileId, uint referrerProfileId) external {
        require(IAuth(contractAddress).devaddr_() == msg.sender || IProfile(_helper()).boughtProfile(msg.sender) == _profileId, "P0");
        require(accounts[_profileId].length() == 0 && _profileId < INITIAL_PROFILE_ID, "P017");

        _createProfile(_name, _profileId, referrerProfileId);
     
        emit CreateProfile(_profileId, _name);
    }

    function createProfile(string memory _name, uint referrerProfileId) external {
        _createProfile(_name, profileId, referrerProfileId);

        emit CreateProfile(profileId++, _name);
    }

    function _createProfile(string memory _name, uint _profileId, uint referrerProfileId) internal {
        if (referrerProfileId > 0) {
            require( 
                profileInfo[referrerProfileId].createdAt > 0 &&
                addressToProfileId[msg.sender] != referrerProfileId,
                "P18"
            );
            referrer[_profileId] = referrerProfileId;
        }
        accounts[_profileId].add(msg.sender);
        require(isNameTaken[keccak256(abi.encodePacked(_name))] == 0, "P19");
        isNameTaken[keccak256(abi.encodePacked(_name))] = _profileId;
        profileInfo[_profileId].name = _name;
        profileInfo[_profileId].createdAt = block.timestamp;
        addressToProfileId[msg.sender] = _profileId;
        // follow OG profile
        if (_profileId != 1) {
            require(sharedEmail[msg.sender], "P20");
            followers[1].add(_profileId);
        }
        IProfile(_helper()).safeMint(msg.sender, _profileId);
    }

    function updateCollectionId(uint _collectionId) external respectTimeConstraint {
        require(addressToProfileId[msg.sender] > 0, "P21");
        require(IMarketPlace(_marketCollections()).addressToCollectionId(msg.sender) == _collectionId, "P22");
        profileInfo[addressToProfileId[msg.sender]].collectionId = _collectionId;
        emit UpdateCollectionId(addressToProfileId[msg.sender], _collectionId);
    }
    
    function addBounty(uint _bountyId) external respectTimeConstraint {
        (address owner,address _token,,address claimableBy,,,,,,) = ITrustBounty(_trustBounty()).bountyInfo(_bountyId);
        require(addressToProfileId[msg.sender] > 0 && owner == msg.sender && claimableBy == address(0x0), "P23");
        bounties[addressToProfileId[msg.sender]][_token] = _bountyId;
        emit AddBounty(addressToProfileId[msg.sender], _bountyId, _token);
    }
    
    function payProfile(address _token, uint _profileId, uint _amount) external lock {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        pendingRevenue[_profileId][_token] += _amount;

        emit PayProfile(_token, _profileId, _amount);
    }

    function claimRevenue(address _token, uint _profileId, uint _amount) external lock respectTimeConstraint {
        require(addressToProfileId[msg.sender] == _profileId, "P24");
        uint _toClaim = Math.min(_amount, pendingRevenue[_profileId][_token]);
        pendingRevenue[_profileId][_token] -= _toClaim;
        if (profileInfo[_profileId].activePeriod < block.timestamp) {
            profileInfo[_profileId].paidPayable = 0;
            profileInfo[_profileId].activePeriod = block.timestamp + bufferTime / bufferTime * bufferTime;
        }
        _safeTransfer(_token, msg.sender, _toClaim);
        profileInfo[_profileId].paidPayable += _toClaim;

        emit ClaimRevenue(_token, _profileId, _toClaim);
    }

    function _getPercentile(address _ve, uint _tokenId) internal view returns(uint _percentile, uint _total, uint sods) {
        return ILottery(IContract(contractAddress).profileHelper()).getPercentile(
            msg.sender, 
            _ve, 
            _allContracts[_ve].length(),
            _tokenId
        );
    }

    function updateLateDays(address __helper, address _arp, address _protocolOwner, address _ve, uint _tokenId, uint _protocolId, uint _profileId) external {
        require(isHelper[__helper] && IARP(__helper).isGauge(_arp) && IAuth(_arp).isAdmin(msg.sender), "P26");
        require(accounts[_profileId].contains(_protocolOwner), "P27");
        require(IMarketPlace(_arp).getProfileId(_protocolId) == _profileId, "P28");
        (uint _due,, int lateSeconds) = IMarketPlace(__helper).getDueReceivable(_arp, _protocolId);
        uint due = IRamp(_rampHelper()).convert(IMarketPlace(_arp).getToken(_protocolId), _due);
        require(lateSeconds > 0, "P29");
        _updateReports(_arp, _profileId);
        _allContracts[_ve].add(_arp);
        (uint _percentile, uint _total, uint sods) = _getPercentile(_ve, _tokenId);
        total[_ve] = _total;
        sum_of_diff_squared[_ve] = sods;
        if (_percentile > 75) {
            profileInfo[_profileId].gold.lateSeconds += uint(-lateSeconds);
            profileInfo[_profileId].gold.lateValue += due;
            goldReported[_arp][_profileId].lateSeconds = uint(-lateSeconds);
            goldReported[_arp][_profileId].lateValue = due;
        } else if (_percentile > 50) {
            profileInfo[_profileId].silver.lateSeconds += uint(-lateSeconds);
            profileInfo[_profileId].silver.lateValue += due;
            silverReported[_arp][_profileId].lateSeconds = uint(-lateSeconds);
            silverReported[_arp][_profileId].lateValue = due;
        } else if (_percentile > 25) {
            profileInfo[_profileId].brown.lateSeconds += uint(-lateSeconds);
            profileInfo[_profileId].brown.lateValue += due;
            brownReported[_arp][_profileId].lateSeconds = uint(-lateSeconds);
            brownReported[_arp][_profileId].lateValue = due;
        } else {
            profileInfo[_profileId].black.lateSeconds += uint(-lateSeconds);
            profileInfo[_profileId].black.lateValue += due;
            blackReported[_arp][_profileId].lateSeconds = uint(-lateSeconds);
            blackReported[_arp][_profileId].lateValue = due;
        }
    }
    
    function emitUpdateMiscellaneous(
        uint _idx, 
        uint _collectionId, 
        string memory paramName, 
        string memory paramValue, 
        uint paramValue2, 
        uint paramValue3,
        address paramValue4,
        string memory paramValue5
    ) external {
        emit UpdateMiscellaneous(
            _idx, 
            _collectionId, 
            paramName, 
            paramValue, 
            paramValue2, 
            paramValue3, 
            msg.sender,
            paramValue4,
            paramValue5
        );
    }

    function _updateReports(address _arp, uint _profileId) internal {
        if (goldReported[_arp][_profileId].lateValue > 0) {
            profileInfo[_profileId].gold.lateSeconds -= goldReported[_arp][_profileId].lateSeconds;
            profileInfo[_profileId].gold.lateValue -= goldReported[_arp][_profileId].lateValue;
        } else if (silverReported[_arp][_profileId].lateValue > 0) {
            profileInfo[_profileId].silver.lateSeconds -= silverReported[_arp][_profileId].lateSeconds;
            profileInfo[_profileId].silver.lateValue -= silverReported[_arp][_profileId].lateValue;
        } else if (brownReported[_arp][_profileId].lateValue > 0) {
            profileInfo[_profileId].brown.lateSeconds -= brownReported[_arp][_profileId].lateSeconds;
            profileInfo[_profileId].brown.lateValue -= brownReported[_arp][_profileId].lateValue;
        } else if (blackReported[_arp][_profileId].lateValue > 0) {
            profileInfo[_profileId].black.lateSeconds -= blackReported[_arp][_profileId].lateSeconds;
            profileInfo[_profileId].black.lateValue -= blackReported[_arp][_profileId].lateValue;
        }
    }

    function _safeTransfer(address _token, address to, uint256 value) internal {
        uint _profileId = addressToProfileId[to];
        uint _bountyId = bounties[_profileId][_token];
        require(_profileId > 0 && _bountyId > 0, "P31");
        uint _limit = ITrustBounty(_trustBounty()).getBalance(_bountyId);
        (,,,,,,uint endTime,,,) = ITrustBounty(_trustBounty()).bountyInfo(_bountyId);
        require(endTime > block.timestamp + bufferTime, "P32");
        uint amount = Math.min(value + profileInfo[_profileId].paidPayable, _limit * limitFactor / 10000);
        IERC20(_token).safeTransfer(to, amount);
    }
}

contract ProfileHelper is ERC721Pausable {
    using SafeERC20 for IERC20;
    using Percentile for *;

    address public contractAddress;
    uint constant INITIAL_PROFILE_ID = 2;
    uint public boughtProfileId= 1;
    uint public bidStart = 1000e18;
    uint public bidDuration = 86400 * 7;
    uint public minBidIncrementPercentage = 1000;
    mapping(address => uint) public boughtProfile;
    struct Bid {
        uint lastBid;
        uint lastBidTime;
        address lastBidder;
    }
    mapping(uint => Bid) public bids;
    mapping(uint => mapping(uint => bool)) public crushes;
    mapping(uint => string) public broadcast; // to broadcast msgs to followers
    mapping(uint => string) internal _tokenURIs;
    mapping(uint => address) public uriGenerator;
    mapping(uint => uint) public createdAt;
    mapping(uint => address) public taskContracts;

    event UpdateCrush(
        uint senderProfileId, 
        uint receiverProfileId, 
        uint expiresAt,
        bool notifyCrush,
        bool secretCrush,
        bool active,
        bool friendly,
        string guessQuestion,
        string guessAnswer,
        string sharedInfo
    );

    constructor() ERC721("ProfileNFT", "ProfileNFT") {}

    // simple re-entrancy check 
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender, "PH1");
        contractAddress = _contractAddress;
    }

    function updateBroadcast(string memory message, uint _profileId) external {
        require(IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender) == _profileId, "P0H2");
        broadcast[_profileId] = message;
    }

    function getPercentile(
        address _user, 
        address _ve, 
        uint _length, 
        uint _tokenId
    ) external view returns(uint,uint,uint) {
        require(ITrustBounty(IContract(contractAddress).trustBounty()).ves(_ve) && ve(_ve).ownerOf(_tokenId) == _user, "P25");
        address profile = IContract(contractAddress).profile();
        uint _sodq = IProfile(profile).sum_of_diff_squared(_ve);
        uint _total = IProfile(profile).total(_ve);
        uint _balance = ve(_ve).balanceOfNFT(_tokenId);
        (uint percentile, uint sods) = Percentile.computePercentileFromData(
            false,
            _balance,
            _total + _balance,
            _length,
            _sodq
        );
        return (
            percentile,
            _total + _balance,
            sods
        );
    }

    function updateParams(
        uint _bidStart, 
        uint _bidDuration, 
        uint _minBidIncrementPercentage
    ) external {
        require(IAuth(contractAddress).devaddr_() == msg.sender, "PH2");
        bidStart = _bidStart;
        bidDuration = _bidDuration;
        minBidIncrementPercentage = _minBidIncrementPercentage;
    }

    function bidForProfile(uint _amount) external lock {
        require(boughtProfileId < INITIAL_PROFILE_ID, "PH3");
        
        address _token = IContract(contractAddress).token();
        if (bids[boughtProfileId].lastBidder != address(0x0)) {
            require(bids[boughtProfileId].lastBid * minBidIncrementPercentage / 10000 >= _amount, "PH4");
            IERC20(_token).safeTransfer(bids[boughtProfileId].lastBidder, bids[boughtProfileId].lastBid);
        }
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        bids[boughtProfileId].lastBid = _amount;
        bids[boughtProfileId].lastBidder = msg.sender;
        bids[boughtProfileId].lastBidTime = block.timestamp;
    }

    function processAuction() external {
        require(bids[boughtProfileId].lastBidTime + bidDuration < block.timestamp, "PH5");
        boughtProfile[bids[boughtProfileId].lastBidder] = boughtProfileId++;
    }

    function safeMint(address _user, uint _profileId) public {
        require(msg.sender == IContract(contractAddress).profile(), "PH6");
        _safeMint(_user, _profileId, "");
        createdAt[_profileId] = block.timestamp;
    }

    function burn(uint _profileId) external {
        require(msg.sender == IContract(contractAddress).profile(), "PH7");
        _burn(_profileId);
    }

    function updateCrush(
        uint _receiverProfileId, 
        uint _expiresAt, 
        bool _notifyCrush,
        bool _secretCrush,
        bool _active,
        bool _friendly,
        string memory _guessQuestion,
        string memory _guessAnswer,
        string memory _sharedInfo
    ) external {
        uint _profileId = IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender); 
        require(IProfile(IContract(contractAddress).profile()).isUnique(_profileId), "PH8");
        crushes[_profileId][_receiverProfileId] = _active;
        emit UpdateCrush(
            _profileId,
            _receiverProfileId, 
            _expiresAt, 
            _notifyCrush,
            _secretCrush,
            _active,
            _friendly,
            _guessQuestion,
            _guessAnswer,
            _sharedInfo
        );
    }
    
    function updateUriGenerator(address _uriGenerator) external {
        uint collectionId = IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(msg.sender);
        if (collectionId > 0) {
            uriGenerator[collectionId] = _uriGenerator;
        }
    }

    function _isEmpty(string memory val) internal pure returns(bool) {
        return keccak256(abi.encodePacked(val)) == keccak256(abi.encodePacked(""));
    }
    
    function updateTaxContract(address __taskContract) external {
        uint _collectionId = IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(msg.sender);
        if (_collectionId > 0) {
            taskContracts[_collectionId] = __taskContract;
        }
    }

    function _taskContract(uint _tokenId) internal view returns(address) {
        (,,,,,,uint _collectionId,,,,) = IProfile(IContract(contractAddress).profile()).profileInfo(_tokenId);
        return taskContracts[_collectionId] != address(0x0) && IMarketPlace(taskContracts[_collectionId]).pendingTask(_tokenId)
            ? taskContracts[_collectionId] : address(0x0);
    }

    function _getDescription(uint _tokenId) internal view returns(string[] memory) {
        string[] memory _description = new string[](1);
        _description[0] = broadcast[_tokenId];
        return _description;
    }

    function _getFollowerCount(address profile, uint _profileId) internal view returns(uint) {
        return (IProfile(profile).getAllFollowers(_profileId,0)).length;
    }

    function getAccountAt(uint _profileId, uint index) external view returns(address) {
        address[] memory accounts = IProfile(IContract(contractAddress).profile()).getAllAccounts(_profileId,index);
        return accounts.length > 0 ? accounts[0] : address(0x0);
    }

    function _getOptions(uint _tokenId, uint[] memory _identityProofs) internal view returns(string[] memory media, string[] memory optionNames,string[] memory optionValues) {
        optionNames = new string[](3 + _identityProofs.length);
        optionValues = new string[](3 + _identityProofs.length);
        address profile = IContract(contractAddress).profile();
        (,,,,,,uint _collectionId,,,,) = IProfile(profile).profileInfo(_tokenId);
        media = INFTicket(IContract(contractAddress).nfticketHelper()).getSponsorsMedia(_collectionId, "");
        uint idx;
        optionNames[idx] = "Unique";
        optionValues[idx++] = IProfile(profile).isUnique(_tokenId) ? "Unique" : "Common";
        optionNames[idx] = "# Followers";
        optionValues[idx++] = toString(_getFollowerCount(profile, _tokenId));
        optionNames[idx] = "Created";
        optionValues[idx++] = toString(createdAt[_tokenId]);
        address ssi = IContract(contractAddress).ssi();
        for (uint i = 0; i < _identityProofs.length; i++) {
            require(ve(ssi).ownerOf(_identityProofs[i]) == msg.sender, "Only owner");
            SSIData memory _metadata = ISSI(ssi).getSSIData(_identityProofs[i]);
            require(_metadata.deadline > block.timestamp, "Deadline expired");
            optionNames[idx] = _metadata.question;
            optionValues[idx++] = _metadata.answer;
            optionNames[idx] = "Auditor";
            optionValues[idx++] = toString(_metadata.auditorProfileId);
        }
    }

    function constructTokenURI(uint _tokenId, uint[] memory _identityProofs) external {
        (string[] memory media,string[] memory optionNames,string[] memory optionValues) = _getOptions(_tokenId, _identityProofs);
        _tokenURIs[_tokenId] = _constructTokenURI(
            _taskContract(_tokenId),
            _tokenId, 
            media, 
            optionNames, 
            optionValues, 
            _getDescription(_tokenId)
        );
    }

    function _constructTokenURI(address _task,uint _tokenId,string[] memory media,string[] memory optionNames,string[] memory optionValues,string[] memory _description) internal view returns(string memory output) {
        output = IMarketPlace(IContract(contractAddress).nftSvg()).constructTokenURI(
            _tokenId,
            'Profile',
            address(this),
            ownerOf(_tokenId),
            ownerOf(_tokenId),
            _task,
            media,
            optionNames,
            optionValues,
            _description
        );
    }

    function tokenURI(uint _tokenId) public view virtual override returns (string memory output) {
        address profile = IContract(contractAddress).profile();
        (,,,,,,uint _collectionId,,,,) = IProfile(profile).profileInfo(_tokenId);
        if (uriGenerator[_collectionId] != address(0x0)) {
            output = IMarketPlace(uriGenerator[_collectionId]).uri(_tokenId);
        } else if(!_isEmpty(_tokenURIs[_tokenId])) {
            output = _tokenURIs[_tokenId];
        } else {
            string[] memory optionNames = new string[](3);
            string[] memory optionValues = new string[](3);
            string[] memory media = INFTicket(IContract(contractAddress).nfticketHelper()).getSponsorsMedia(_collectionId, "");
            uint idx;
            optionNames[idx] = "Unique";
            optionValues[idx++] = IProfile(profile).isUnique(_tokenId) ? "Unique" : "Common";
            optionNames[idx] = "# Followers";
            optionValues[idx++] = toString(_getFollowerCount(profile, _tokenId));
            optionNames[idx] = "Created";
            optionValues[idx] = toString(createdAt[_tokenId]);
            output = _constructTokenURI(
                _taskContract(_tokenId),
                _tokenId, 
                media, 
                optionNames, 
                optionValues, 
                _getDescription(_tokenId)
            );
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
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import "./Library.sol";

contract FutureCollateral is ERC721Pausable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    address public token;
    uint private tokenId = 1;
    uint public treasury;
    uint public treasuryFee;
    mapping(uint => uint) public fund;
    uint constant WEEKS_PER_YEAR = 52;
    uint public bufferTime = 86400 * 7 * WEEKS_PER_YEAR;
    uint constant week = 86400 * 7;
    uint public minBountyPercent = 10000;
    mapping(address => bool) public isAdmin;
    mapping(uint => uint) public attachments;
    mapping(uint => address) public isAuditor;
    mapping(uint => address) public channelToValuepool;
    address private contractAddress;
    struct Collateral {
        uint channel;
        uint startTime;
    }
    mapping(uint => Collateral) public collateral;
    mapping(uint => uint) public profileIdToTokenId;
    mapping(uint => uint[WEEKS_PER_YEAR]) public estimationTable;
    COLOR updateColor = COLOR.GOLD;
    COLOR minColor = COLOR.GOLD;
    uint public minToBlacklist;
    uint constant FC_IDX = 3;
    mapping(uint => uint) public channels;
    mapping(uint => EnumerableSet.UintSet) private isBlacklisted;
    mapping(uint => bool) public isValidChannel;

    event Mint (
        address _auditor,
        address _to, 
        uint _stakeId,
        uint _userBountyId, 
        uint _auditorBountyId, 
        uint _channel,
        uint _tokenId
    );
    event Burn(address from);
    event SellCollateral(address from);
    event EraseDebt(address account);
    event AddToChannel(uint profileId, uint channel);
    event UpdateValidChannel(uint channel, bool add);
    event UpdateEstimationTable(uint channel, uint[WEEKS_PER_YEAR] table);

    constructor(
        string memory _name,
        string memory _symbol,
        address _token,
        address _contractAddress
    ) ERC721(_name, _symbol) {
        token = _token;
        isAdmin[msg.sender] = true;
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

    modifier checkMinAuditor() {
        if (IAuth(contractAddress).devaddr_() != msg.sender) {
            address profile = IContract(contractAddress).profile();
            uint _auditorId = IProfile(profile).addressToProfileId(msg.sender);
            (address gauge,,COLOR _badgeColor) = IAuditor(IContract(contractAddress).auditorNote()).getGaugeNColor(_auditorId);
            uint _category = IAuditor(IContract(contractAddress).auditorHelper()).categories(gauge);
            require(isAdmin[msg.sender] || (_category == FC_IDX && _badgeColor >= minColor));
            require(IProfile(profile).isUnique(_auditorId));
            require(isBlacklisted[_auditorId].length() < minToBlacklist);
        }
        _;
    }
    
    function updateValuePool(address _vava, uint _channel) external {
        require(IAuth(contractAddress).devaddr_() == msg.sender);
        channelToValuepool[_channel] = _vava;
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }

    function updateDev(address _devaddr, bool _add) external {
        require(isAdmin[msg.sender]);
        isAdmin[_devaddr] = _add;
    }
    
    function updateEstimationTable(uint _channel, uint[WEEKS_PER_YEAR] memory _table) external {
        address profile = IContract(contractAddress).profile();
        uint _auditorId = IProfile(profile).addressToProfileId(msg.sender);
        (address gauge,,COLOR _badgeColor) = IAuditor(IContract(contractAddress).auditorNote()).getGaugeNColor(_auditorId);
        uint _category = IAuditor(IContract(contractAddress).auditorHelper()).categories(gauge);
        require(isAdmin[msg.sender] || (_category == FC_IDX && _badgeColor >= updateColor));
        require(IProfile(profile).isUnique(_auditorId) && isValidChannel[_channel]);
        require(isBlacklisted[_auditorId].length() < minToBlacklist);
        estimationTable[_channel] = _table;

        emit UpdateEstimationTable(_channel, _table);
    }

    function addToChannel(uint _profileId, uint _channel) external checkMinAuditor {
        require(IProfile(IContract(contractAddress).profile()).isUnique(_profileId));
        require(isValidChannel[_channel]);
        channels[_profileId] = _channel;

        emit AddToChannel(_profileId, _channel);
    }

    function updateBlacklist(uint _profileId, bool _add) external checkMinAuditor {
        uint _auditorId = IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender);
        if (_add) {
            isBlacklisted[_profileId].add(_auditorId);
        } else {
            isBlacklisted[_profileId].remove(_auditorId);
        }
    }

    function updateParams(
        uint _treasuryFee, 
        uint _bufferTime,
        uint _minToBlacklist,
        uint _minBountyPercent,
        COLOR _updateColor,
        COLOR _minColor
    ) external {
        require(isAdmin[msg.sender]);
        treasuryFee = _treasuryFee;
        bufferTime = _bufferTime;
        minToBlacklist = _minToBlacklist;
        minBountyPercent = _minBountyPercent;
        updateColor = _updateColor;
        minColor = _minColor;
    }

    function withdrawTreasury() external {
        require(isAdmin[msg.sender]);
        IERC20(token).safeTransfer(msg.sender, treasury);
        treasury = 0;
    }
    
    /**
        This function returns whether the previous channel has reached a price
        high enough to unlock the requested channel
    */ 
    function updateValidChannel(uint _channel, bool _add) public {
        require(IAuth(contractAddress).devaddr_() == msg.sender);
        isValidChannel[_channel] = _add;
    }

    function getCurrentPrice(uint _tokenId) public view returns(uint _price) {
        _price = getPriceAt(_tokenId, 0);
    }
    
    function getPriceAt(uint _tokenId, uint _time) public view returns(uint _price) {
        uint _numOfWeeks = (block.timestamp + _time - collateral[_tokenId].startTime)/ week;
        _price = estimationTable[collateral[_tokenId].channel][_numOfWeeks % WEEKS_PER_YEAR];
        _price += estimationTable[collateral[_tokenId].channel][WEEKS_PER_YEAR-1] * _numOfWeeks / WEEKS_PER_YEAR;
    }

    function _profile() internal view returns(address) {
        return IContract(contractAddress).profile();
    }

    function _trustBounty() internal view returns(address) {
        return IContract(contractAddress).trustBounty();
    }
    
    function mint(
        address _auditor,
        address _to, 
        uint _stakeId,
        uint _userBountyId, 
        uint _auditorBountyId, 
        uint _channel
    ) external {
        uint _tokenId = _mintTo(address(this), _channel);
        address trustBounty = _trustBounty();
        _updateAuditor(
            _auditor,
            _to, 
            _tokenId, 
            _stakeId,
            _userBountyId, 
            _auditorBountyId
        );
        // _approve(trustBounty, _tokenId);
        _approve(IContract(contractAddress).trustBountyHelper(), _tokenId);
        ITrustBounty(trustBounty).addBalance(_userBountyId, trustBounty, 0, _tokenId);

        emit Mint(
            _auditor,
            _to, 
            _stakeId,
            _userBountyId, 
            _auditorBountyId, 
            _channel,
            _tokenId
        );
    }
    
    function _mintTo(address _to, uint _channel) internal lock returns(uint) {
        address profile = _profile();
        uint _profileId = IProfile(profile).addressToProfileId(msg.sender);
        require(IProfile(profile).isUnique(_profileId));
        require(profileIdToTokenId[_profileId] == 0);
        require(channels[_profileId] == _channel);
        
        uint _price = estimationTable[_channel][0];
        IERC20(token).safeTransferFrom(msg.sender, address(this), _price);
        _safeMint(_to, tokenId, msg.data);
        
        uint _fee = _price * treasuryFee / 10000;
        treasury += _fee;
        fund[_channel] += _price - _fee;
        profileIdToTokenId[_profileId] = tokenId;
        collateral[tokenId].channel = _channel;
        collateral[tokenId].startTime = block.timestamp;
        return tokenId++;
    }

    function notifyReward(uint _channel, uint _amount) external {
        IERC20(IContract(contractAddress).token()).safeTransferFrom(msg.sender, address(this), _amount);
        fund[_channel] += _amount;
    }

    function burn(address _from) external {
        address profile = _profile();
        uint _profileId = IProfile(profile).addressToProfileId(_from);
        uint _tokenId = profileIdToTokenId[_profileId];
        require(_tokenId > 0 && ownerOf(_tokenId) == msg.sender);

        _burn(_tokenId);
        
        delete collateral[_tokenId];
        delete profileIdToTokenId[_profileId];

        emit Burn(_from);
    }

    function eraseDebt(address _account) external lock {
        address profile = _profile();
        uint _profileId = IProfile(profile).addressToProfileId(_account);
        uint _tokenId = profileIdToTokenId[_profileId];

        
        IERC20(token).safeTransferFrom(msg.sender, address(this), getCurrentPrice(_tokenId));

        delete collateral[_tokenId];
        delete profileIdToTokenId[_profileId];

        emit EraseDebt(_account);
    }

    function getProfileId(address _account) external view returns(uint) {
        address profile = _profile();
        uint _profileId = IProfile(profile).addressToProfileId(_account);
        return profileIdToTokenId[_profileId];
    }

    function sellCollateral(address _from) external lock {
        address profile = _profile();
        uint _profileId = IProfile(profile).addressToProfileId(_from);
        uint _tokenId = profileIdToTokenId[_profileId];
        uint _due = getCurrentPrice(_tokenId);
        require(fund[collateral[_tokenId].channel] >= _due);

        require(_tokenId > 0 && ownerOf(_tokenId) == msg.sender);
        ITrustBounty(IContract(contractAddress).trustBountyHelper()).detach(attachments[_tokenId]);
        
        _burn(_tokenId);
        fund[collateral[_tokenId].channel] -= _due;
        IERC20(token).safeTransfer(msg.sender, _due);

        emit SellCollateral(_from);
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 _tokenId
    )
        internal
        virtual
        override 
    {
        super._beforeTokenTransfer(from, to, _tokenId);
        if (from != address(this) && to != address(this)) {
            require(
                (isAdmin[from] || isAuditor[_tokenId] == from) &&
                (isAdmin[to] || isAuditor[_tokenId] == from)
            );
        }
    }

    function _updateAuditor(
        address _auditor, 
        address _user,
        uint _tokenId, 
        uint _stakeId,
        uint _userBountyId, 
        uint _auditorBountyId
    ) internal {
        // Bounty checks
        address trustBounty = _trustBounty();
        (address _owner,address _token,,address claimableBy,,,,,,) = ITrustBounty(trustBounty).bountyInfo(_userBountyId);
        require(_owner == _user && _token == address(this) && claimableBy == _auditor);
        // bounty actually contains requested token id
        _auditorBountyCheck(_auditorBountyId, _tokenId, _auditor);
        ITrustBounty(IContract(contractAddress).trustBountyHelper()).attach(_auditorBountyId);
        attachments[_tokenId] = _auditorBountyId;
        // stake checks
        _stateCheck(_stakeId, _auditor, _user);
        isAuditor[_tokenId] = _auditor;
    }

    function _auditorBountyCheck(
        uint _auditorBountyId, 
        uint _tokenId,
        address _auditor
    ) internal view {
        address trustBounty = _trustBounty();
        (address _owner2,address _token2,,address claimableBy2,,,uint endTime,,,) = ITrustBounty(trustBounty).bountyInfo(_auditorBountyId);
        require(_owner2 == _auditor && _token2 == IContract(contractAddress).token() && claimableBy2 == address(0x0) && block.timestamp + bufferTime < endTime);
        uint _balance = ITrustBounty(trustBounty).getBalance(_auditorBountyId);
        require(_balance >= getCurrentPrice(_tokenId) * minBountyPercent / 10000);
    }

    function _stateCheck(uint _stakeId, address _auditor, address _user) internal view {
        address stakeMarket = IContract(contractAddress).stakeMarket();
        Stake memory stake = IStakeMarket(stakeMarket).getStake(_stakeId);
        Stake memory parentStake = IStakeMarket(stakeMarket).getStake(stake.parentStakeId);
        require(IStakeMarket(stakeMarket).isStake(_stakeId) && IStakeMarket(stakeMarket).isStake(stake.parentStakeId));
        require(
            (stake.owner == _auditor && parentStake.owner == _user) ||
            (stake.owner == _user && parentStake.owner == _auditor)
        );
    }

    function onERC721Received(address,address,uint256,bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector; 
    }
}
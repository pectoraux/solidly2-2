// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;

// library Math {
//     function max(uint a, uint b) internal pure returns (uint) {
//         return a >= b ? a : b;
//     }
//     function min(uint a, uint b) internal pure returns (uint) {
//         return a < b ? a : b;
//     }
// }

// interface erc20 {
//     function totalSupply() external view returns (uint256);
//     function transfer(address recipient, uint amount) external returns (bool);
//     function balanceOf(address) external view returns (uint);
//     function transferFrom(address sender, address recipient, uint amount) external returns (bool);
//     function approve(address spender, uint value) external returns (bool);
// }

// interface ve {
//     function token() external view returns (address);
//     function balanceOfNFT(uint) external view returns (uint);
//     function isApprovedOrOwner(address, uint) external view returns (bool);
//     function ownerOf(uint) external view returns (address);
//     function transferFrom(address, address, uint) external;
// }

// interface IBaseV1Factory {
//     function isPair(address) external view returns (bool);
// }

// interface IBaseV1Core {
//     function claimFees() external returns (uint, uint);
//     function tokens() external returns (address, address);
// }

// interface IBribe {
//     function notifyRewardAmount(address token, uint amount) external;
//     function left(address token) external view returns (uint);
// }

// interface Voter {
//     function attachTokenToGauge(uint _tokenId, address account) external;
//     function detachTokenFromGauge(uint _tokenId, address account) external;
//     function emitDeposit(uint _tokenId, address account, uint amount) external;
//     function emitWithdraw(uint _tokenId, address account, uint amount) external;
//     function distribute(address _gauge) external;
//     function getColor(address) external view returns(uint);

// }

// interface underlying {
//     function approve(address spender, uint value) external returns (bool);
//     function mint(address, uint) external;
//     function burn(address, uint) external returns (bool);
//     function totalSupply() external view returns (uint);
//     function balanceOf(address) external view returns (uint);
//     function transfer(address, uint) external returns (bool);
// }

// // Gauges are used to incentivize pools, they emit reward tokens over 7 days for staked LP tokens
// contract Gauge2 {

//     // address public immutable stake; // the LP token that needs to be staked for rewards
//     underlying public immutable stake;
//     address public immutable _ve; // the ve token used for gauges
//     address public immutable bribe;
//     address public immutable voter;

//     uint public derivedSupply;
//     mapping(address => uint) public derivedBalances;

//     uint internal constant DURATION = 7 days; // rewards are released over 7 days
//     uint internal constant PRECISION = 10 ** 18;

//     // default snx staking contract implementation
//     mapping(address => uint) public rewardRate;
//     mapping(address => uint) public periodFinish;
//     mapping(address => uint) public lastUpdateTime;
//     mapping(address => uint) public rewardPerTokenStored;

//     mapping(address => mapping(address => uint)) public lastEarn;
//     mapping(address => mapping(address => uint)) public userRewardPerTokenStored;

//     mapping(address => uint) public tokenIds;

//     uint public totalSupply;
//     mapping(address => uint) public balanceOf;

//     address[] public rewards;
//     mapping(address => bool) public isReward;

//     /// @notice A checkpoint for marking balance
//     struct Checkpoint {
//         uint timestamp;
//         uint balanceOf;
//     }

//     /// @notice A checkpoint for marking reward rate
//     struct RewardPerTokenCheckpoint {
//         uint timestamp;
//         uint rewardPerToken;
//     }

//     /// @notice A checkpoint for marking supply
//     struct SupplyCheckpoint {
//         uint timestamp;
//         uint supply;
//     }

//     /// @notice A record of balance checkpoints for each account, by index
//     mapping (address => mapping (uint => Checkpoint)) public checkpoints;
//     /// @notice The number of checkpoints for each account
//     mapping (address => uint) public numCheckpoints;
//     /// @notice A record of balance checkpoints for each token, by index
//     mapping (uint => SupplyCheckpoint) public supplyCheckpoints;
//     /// @notice The number of checkpoints
//     uint public supplyNumCheckpoints;
//     /// @notice A record of balance checkpoints for each token, by index
//     mapping (address => mapping (uint => RewardPerTokenCheckpoint)) public rewardPerTokenCheckpoints;
//     /// @notice The number of checkpoints for each token
//     mapping (address => uint) public rewardPerTokenNumCheckpoints;

//     // info about owner
//     uint public tokenId;
//     string public cancan_email; 
//     string public creative_cid; 
//     string public video_cid; 
//     string public website_link; 
//     string public description; 
//     uint public maxActiveProtocols;

//     enum COLOR {
//         BLACK,
//         BROWN,
//         SILVER,
//         GOLD
//     }
//     COLOR badgeColor = COLOR.BLACK;

//     struct ProtocolInfo {
//         address owner;
//         uint amountReceivable;
//         uint paidReceivable;
//         uint periodReceivable;
//         uint startReceivable;
//         uint dueReceivable;
//         uint rating;
//         string rating_string;
//         string rating_description;
//     }
//     ProtocolInfo[] protocolInfo;
    
//     event Deposit(address indexed from, uint tokenId, uint amount);
//     event Withdraw(address indexed from, uint tokenId, uint amount);
//     event NotifyReward(address indexed from, address indexed reward, uint amount);
//     event ClaimFees(address indexed from, uint claimed0, uint claimed1);
//     event ClaimRewards(address indexed from, address indexed reward, uint amount);

//     event AddProtocol(address indexed from, uint time, address owner);
//     event UpdateProtocol(address indexed from, uint time, address owner);
//     event DeleteProtocol(address indexed from, uint time, uint pid);
//     event PayInvoiceReceivable(address indexed from, uint pid, uint paid);

//     constructor(
//         address _bribe, 
//         address  __ve, 
//         uint _tokenId, 
//         address _voter
//     ) {
//         stake = underlying(ve(__ve).token());
//         bribe = _bribe;
//         _ve = __ve;
//         voter = _voter;
//         tokenId = _tokenId;
//     }

//     // simple re-entrancy check
//     uint internal _unlocked = 1;
//     modifier lock() {
//         require(_unlocked == 1);
//         _unlocked = 2;
//         _;
//         _unlocked = 1;
//     }

//     modifier isNotBlackListed() {
//         // require(!isBlackListed(msg.sender), "You have been blacklisted");
//         _;
//     }

//     modifier isOpened() {
//         require(maxActiveProtocols == 0 || maxActiveProtocols >= protocolInfo.length);
//         _;
//     }

//     modifier onlyAuth() {
//         require(
//             msg.sender == ve(_ve).ownerOf(tokenId), "Gauge: Not owner");
//         _;
//     }

//     function setBadgeColor() external {
//         COLOR _color = COLOR((Voter(voter).getColor(address(this))));
//         badgeColor = _color;
//     }

//     function updateVideoCid(string calldata _video_cid) external onlyAuth() {
//         video_cid = _video_cid;
//     }

//     function updateCreativeCid(string calldata _creative_cid) external onlyAuth() {
//         creative_cid = _creative_cid;
//     }

//     function updateCancanEmail(string calldata _cancan_email) external onlyAuth() {
//         cancan_email = _cancan_email;
//     }

//     function updateWebsiteLink(string calldata _website_link) external onlyAuth() {
//         website_link = _website_link;
//     }

//     function updateDescription(string calldata _description) external onlyAuth() {
//         description = _description;
//     }
    
//     function getPriorSupplyIndex(uint timestamp) public view returns (uint) {
//         uint nCheckpoints = supplyNumCheckpoints;
//         if (nCheckpoints == 0) {
//             return 0;
//         }

//         // First check most recent balance
//         if (supplyCheckpoints[nCheckpoints - 1].timestamp <= timestamp) {
//             return (nCheckpoints - 1);
//         }

//         // Next check implicit zero balance
//         if (supplyCheckpoints[0].timestamp > timestamp) {
//             return 0;
//         }

//         uint lower = 0;
//         uint upper = nCheckpoints - 1;
//         while (upper > lower) {
//             uint center = upper - (upper - lower) / 2; // ceil, avoiding overflow
//             SupplyCheckpoint memory cp = supplyCheckpoints[center];
//             if (cp.timestamp == timestamp) {
//                 return center;
//             } else if (cp.timestamp < timestamp) {
//                 lower = center;
//             } else {
//                 upper = center - 1;
//             }
//         }
//         return lower;
//     }

//     function _writeRewardPerTokenCheckpoint(address token, uint reward, uint timestamp) internal {
//         uint _nCheckPoints = rewardPerTokenNumCheckpoints[token];

//         if (_nCheckPoints > 0 && rewardPerTokenCheckpoints[token][_nCheckPoints - 1].timestamp == timestamp) {
//             rewardPerTokenCheckpoints[token][_nCheckPoints - 1].rewardPerToken = reward;
//         } else {
//             rewardPerTokenCheckpoints[token][_nCheckPoints] = RewardPerTokenCheckpoint(timestamp, reward);
//             rewardPerTokenNumCheckpoints[token] = _nCheckPoints + 1;
//         }
//     }

//     function rewardsListLength() external view returns (uint) {
//         return rewards.length;
//     }

//     // returns the last time the reward was modified or periodFinish if the reward has ended
//     function lastTimeRewardApplicable(address token) public view returns (uint) {
//         return Math.min(block.timestamp, periodFinish[token]);
//     }

//     function rewardPerToken(address token) public view returns (uint) {
//         if (derivedSupply == 0) {
//             return rewardPerTokenStored[token];
//         }
//         return rewardPerTokenStored[token] + ((lastTimeRewardApplicable(token) - Math.min(lastUpdateTime[token], periodFinish[token])) * rewardRate[token] * PRECISION / derivedSupply);
//     }

//     function derivedBalance(address account) public view returns (uint) {
//         uint _tokenId = tokenIds[account];
//         uint _balance = balanceOf[account];
//         uint _derived = _balance * 40 / 100;
//         uint _adjusted = 0;
//         uint _supply = erc20(_ve).totalSupply();
//         if (account == ve(_ve).ownerOf(_tokenId) && _supply > 0) {
//             _adjusted = ve(_ve).balanceOfNFT(_tokenId);
//             _adjusted = (totalSupply * _adjusted / _supply) * 60 / 100;
//         }
//         return Math.min((_derived + _adjusted), _balance);
//     }

//     function batchRewardPerToken(address token, uint maxRuns) external {
//         (rewardPerTokenStored[token], lastUpdateTime[token])  = _batchRewardPerToken(token, maxRuns);
//     }

//     function _batchRewardPerToken(address token, uint maxRuns) internal returns (uint, uint) {
//         uint _startTimestamp = lastUpdateTime[token];
//         uint reward = rewardPerTokenStored[token];

//         if (supplyNumCheckpoints == 0) {
//             return (reward, _startTimestamp);
//         }

//         if (rewardRate[token] == 0) {
//             return (reward, block.timestamp);
//         }

//         uint _startIndex = getPriorSupplyIndex(_startTimestamp);
//         uint _endIndex = Math.min(supplyNumCheckpoints-1, maxRuns);

//         for (uint i = _startIndex; i < _endIndex; i++) {
//             SupplyCheckpoint memory sp0 = supplyCheckpoints[i];
//             if (sp0.supply > 0) {
//                 SupplyCheckpoint memory sp1 = supplyCheckpoints[i+1];
//                 (uint _reward, uint _endTime) = _calcRewardPerToken(token, sp1.timestamp, sp0.timestamp, sp0.supply, _startTimestamp);
//                 reward += _reward;
//                 _writeRewardPerTokenCheckpoint(token, reward, _endTime);
//                 _startTimestamp = _endTime;
//             }
//         }

//         return (reward, _startTimestamp);
//     }

//     function _calcRewardPerToken(address token, uint timestamp1, uint timestamp0, uint supply, uint startTimestamp) internal view returns (uint, uint) {
//         uint endTime = Math.max(timestamp1, startTimestamp);
//         return (((Math.min(endTime, periodFinish[token]) - Math.min(Math.max(timestamp0, startTimestamp), periodFinish[token])) * rewardRate[token] * PRECISION / supply), endTime);
//     }

//     function _updateRewardPerToken(address token) internal returns (uint, uint) {
//         uint _startTimestamp = lastUpdateTime[token];
//         uint reward = rewardPerTokenStored[token];

//         if (supplyNumCheckpoints == 0) {
//             return (reward, _startTimestamp);
//         }

//         if (rewardRate[token] == 0) {
//             return (reward, block.timestamp);
//         }

//         uint _startIndex = getPriorSupplyIndex(_startTimestamp);
//         uint _endIndex = supplyNumCheckpoints-1;

//         if (_endIndex - _startIndex > 1) {
//             for (uint i = _startIndex; i < _endIndex-1; i++) {
//                 SupplyCheckpoint memory sp0 = supplyCheckpoints[i];
//                 if (sp0.supply > 0) {
//                     SupplyCheckpoint memory sp1 = supplyCheckpoints[i+1];
//                     (uint _reward, uint _endTime) = _calcRewardPerToken(token, sp1.timestamp, sp0.timestamp, sp0.supply, _startTimestamp);
//                     reward += _reward;
//                     _writeRewardPerTokenCheckpoint(token, reward, _endTime);
//                     _startTimestamp = _endTime;
//                 }
//             }
//         }

//         SupplyCheckpoint memory sp = supplyCheckpoints[_endIndex];
//         if (sp.supply > 0) {
//             (uint _reward,) = _calcRewardPerToken(token, lastTimeRewardApplicable(token), Math.max(sp.timestamp, _startTimestamp), sp.supply, _startTimestamp);
//             reward += _reward;
//             _writeRewardPerTokenCheckpoint(token, reward, block.timestamp);
//             _startTimestamp = block.timestamp;
//         }

//         return (reward, _startTimestamp);
//     }

//     function getReward() external lock {
//         require(
//             ve(_ve).isApprovedOrOwner(msg.sender, tokenId) || msg.sender == voter,
//             "Not allowed to get reward"
//         );
//         _unlocked = 1;
//         Voter(voter).distribute(address(this));
//         _unlocked = 2;

//         withdrawAll();
//     }

//     function updateMaxActiveProtocols(uint _newMax) external onlyAuth() {
//         maxActiveProtocols = _newMax;
//     }

//     function updateRating(
//         uint _pid, 
//         uint _rating,
//         string memory _rating_string, 
//         string memory _description
//     ) external onlyAuth() {
//         protocolInfo[_pid].rating = _rating;
//         protocolInfo[_pid].rating_string = _rating_string;
//         protocolInfo[_pid].rating_description = _description;
//     }
    
//     function setBadgeColor(COLOR _color) internal {
//         badgeColor = _color;
//     }

//     function addProtocol(
//         address _owner,
//         uint _amountReceivable,
//         uint _periodReceivable,
//         uint _startReceivable,
//         string memory _description
//     ) 
//     external 
//     isNotBlackListed() 
//     isOpened() 
//     {
//         protocolInfo.push(ProtocolInfo({
//             owner: _owner,
//             amountReceivable: _amountReceivable,
//             paidReceivable: 0,
//             periodReceivable: _periodReceivable,
//             dueReceivable: 0,
//             startReceivable: msg.sender == ve(_ve).ownerOf(tokenId) ? _startReceivable : 0,
//             rating: 0,
//             rating_string: string(''),
//             rating_description: _description
//         }));

//         emit AddProtocol(msg.sender, block.timestamp, _owner);
//     }

//     function updateProtocol(
//         uint _pid, 
//         address _owner,
//         uint _amountReceivable,
//         uint _periodReceivable,
//         uint _startReceivable,
//         string memory _description
//     ) external onlyAuth() {
        
//         protocolInfo[_pid].owner = _owner;
//         protocolInfo[_pid].amountReceivable = _amountReceivable;
//         protocolInfo[_pid].periodReceivable = _periodReceivable;
//         protocolInfo[_pid].startReceivable = _startReceivable;
//         protocolInfo[_pid].rating_description = _description;

//         emit UpdateProtocol(msg.sender, block.timestamp, _owner);
//     }

//     function _updateInvoiceDueReceivable(uint _pid) internal {
//         if (protocolInfo[_pid].periodReceivable > 0) { //it is periodic
//             uint deadline = 
//             protocolInfo[_pid].startReceivable + protocolInfo[_pid].periodReceivable;
//             if (block.timestamp > deadline) {
//                 protocolInfo[_pid].startReceivable = deadline;
//                 protocolInfo[_pid].dueReceivable = 
//                 protocolInfo[_pid].dueReceivable + protocolInfo[_pid].amountReceivable;
//             }
//         } else {
//             protocolInfo[_pid].dueReceivable = 
//             protocolInfo[_pid].amountReceivable - protocolInfo[_pid].paidReceivable;
//         }
//     }

//     function payInvoiceReceivable(uint _pid, uint _paid) external lock {
//         _updateInvoiceDueReceivable(_pid);
//         require(protocolInfo[_pid].owner == msg.sender, "Invalid owner");

//         uint paid = protocolInfo[_pid].dueReceivable > _paid ? _paid : protocolInfo[_pid].dueReceivable;
//         _safeTransfer(address(stake), msg.sender, paid);
//         protocolInfo[_pid].paidReceivable += paid;
//         protocolInfo[_pid].dueReceivable -= paid;

//         emit PayInvoiceReceivable(msg.sender, _pid, paid);
//     }

//     function deleteProtocol(uint _pid) public onlyAuth() {

//         delete protocolInfo[_pid];

//         emit DeleteProtocol(msg.sender, block.timestamp, _pid);
//     }

//     function withdrawAll() public {
//         withdraw(stake.balanceOf(address(this)));
//     }

//     function withdraw(uint amount) public {
//         require(ve(_ve).isApprovedOrOwner(msg.sender, tokenId), "Not approved for tokenId");
//         _safeTransfer(address(stake), msg.sender, amount);

//         emit Withdraw(msg.sender, tokenId, amount);
//     }

//     function left(address token) external view returns (uint) {
//         if (block.timestamp >= periodFinish[token]) return 0;
//         uint _remaining = periodFinish[token] - block.timestamp;
//         return _remaining * rewardRate[token];
//     }
    
//     function notifyRewardAmount(address token, uint amount) external lock {
//         require(amount > 0);
//         require(tokenId > 0, "Invalid tokenId for gauge");
//         if (rewardRate[token] == 0) _writeRewardPerTokenCheckpoint(token, 0, block.timestamp);
//         (rewardPerTokenStored[token], lastUpdateTime[token]) = _updateRewardPerToken(token);

//         if (block.timestamp >= periodFinish[token]) {
//             _safeTransferFrom(token, msg.sender, address(this), amount);
//             rewardRate[token] = amount / DURATION;
//         } else {
//             uint _remaining = periodFinish[token] - block.timestamp;
//             uint _left = _remaining * rewardRate[token];
//             require(amount > _left);
//             _safeTransferFrom(token, msg.sender, address(this), amount);
//             rewardRate[token] = (amount + _left) / DURATION;
//         }
//         require(rewardRate[token] > 0);
//         uint balance = erc20(token).balanceOf(address(this));
//         require(rewardRate[token] <= balance / DURATION, "Provided reward too high");
//         periodFinish[token] = block.timestamp + DURATION;
//         if (!isReward[token]) {
//             isReward[token] = true;
//             rewards.push(token);
//         }

//         emit NotifyReward(msg.sender, token, amount);
//     }

//     function _safeTransfer(address token, address to, uint256 value) internal {
//         require(token.code.length > 0);
//         (bool success, bytes memory data) =
//         token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
//         require(success && (data.length == 0 || abi.decode(data, (bool))));
//     }

//     function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
//         require(token.code.length > 0);
//         (bool success, bytes memory data) =
//         token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
//         require(success && (data.length == 0 || abi.decode(data, (bool))));
//     }

//     function _safeApprove(address token, address spender, uint256 value) internal {
//         require(token.code.length > 0);
//         (bool success, bytes memory data) =
//         token.call(abi.encodeWithSelector(erc20.approve.selector, spender, value));
//         require(success && (data.length == 0 || abi.decode(data, (bool))));
//     }
// }

// contract BaseV1GaugeFactory2 {
//     address public last_gauge;
//     address[] public gauges;

//     function createGauge(
//         address _bribe, 
//         address _ve, 
//         uint _tokenId
//     ) external returns (address) {
//         last_gauge = address(new Gauge2(
//             _bribe, 
//             _ve, 
//             _tokenId, 
//             msg.sender
//         ));
//         gauges.push(last_gauge);
//         return last_gauge;
//     }

//     function createGaugeSingle(
//         address _bribe, 
//         address _ve, 
//         uint _tokenId, 
//         address _voter
//     ) external returns (address) {
//         last_gauge = address(new Gauge2(
//             _bribe, 
//             _ve, 
//             _tokenId, 
//             _voter
//         ));
//         gauges.push(last_gauge);
//         return last_gauge;
//     }
// }

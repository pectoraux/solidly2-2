// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;

// import './Library.sol';

// // Gauges are used to incentivize pools, they emit reward tokens over 7 days for staked LP tokens
// contract PoolGauge {
//     mapping(address => uint) public derivedSupply;
//     mapping(address => mapping(string => uint)) public derivedBalances;

//     uint internal constant DURATION = 7 days; // rewards are released over 7 days
//     uint internal constant PRECISION = 10 ** 18;

//     // default snx staking contract implementation
//     mapping(address => uint) public rewardRate;
//     mapping(address => uint) public periodFinish;
//     mapping(address => uint) public lastUpdateTime;
//     mapping(address => uint) public rewardPerTokenStored;

//     mapping(address => mapping(string => uint)) public lastEarn;
//     mapping(address => mapping(string => uint)) public userRewardPerTokenStored;

//     mapping(address => uint) public totalSupply;
//     mapping(address => mapping(string => uint)) public balanceOf;

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
//     mapping (string => mapping (uint => Checkpoint)) public checkpoints;
//     /// @notice The number of checkpoints for each account
//     mapping (string => uint) public numCheckpoints;
//     /// @notice A record of balance checkpoints for each token, by index
//     mapping (uint => SupplyCheckpoint) public supplyCheckpoints;
//     /// @notice The number of checkpoints
//     uint public supplyNumCheckpoints;
//     /// @notice A record of balance checkpoints for each token, by index
//     mapping (address => mapping (uint => RewardPerTokenCheckpoint)) public rewardPerTokenCheckpoints;
//     /// @notice The number of checkpoints for each token
//     mapping (address => uint) public rewardPerTokenNumCheckpoints;

//     event Deposit(address indexed from, address token, address ve, uint tokenId, uint amount);
//     event Withdraw(address indexed from, address token, address ve, uint tokenId, uint amount);
//     event NotifyReward(address indexed from, address indexed reward, uint amount);
//     event ClaimFees(address indexed from, uint claimed0, uint claimed1);
//     event ClaimRewards(address indexed from, address indexed reward, uint amount);

//     // simple re-entrancy check
//     uint internal _unlocked = 1;
//     modifier lock() {
//         require(_unlocked == 1);
//         _unlocked = 2;
//         _;
//         _unlocked = 1;
//     }

//     /**
//     * @notice Determine the prior balance for an account as of a block number
//     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
//     * @param timestamp The timestamp to get the balance at
//     * @return The balance the account had as of the given block
//     */
//     function getPriorBalanceIndex(address stake, address _ve, uint tokenId, uint timestamp) public view returns (uint) {
//         string memory cid = string(abi.encodePacked(stake, _ve, tokenId));
//         uint nCheckpoints = numCheckpoints[cid];
//         if (nCheckpoints == 0) {
//             return 0;
//         }

//         // First check most recent balance
//         if (checkpoints[cid][nCheckpoints - 1].timestamp <= timestamp) {
//             return (nCheckpoints - 1);
//         }

//         // Next check implicit zero balance
//         if (checkpoints[cid][0].timestamp > timestamp) {
//             return 0;
//         }

//         uint lower = 0;
//         uint upper = nCheckpoints - 1;
//         while (upper > lower) {
//             uint center = upper - (upper - lower) / 2; // ceil, avoiding overflow
//             Checkpoint memory cp = checkpoints[cid][center];
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

//     function getPriorRewardPerToken(address token, uint timestamp) public view returns (uint, uint) {
//         uint nCheckpoints = rewardPerTokenNumCheckpoints[token];
//         if (nCheckpoints == 0) {
//             return (0,0);
//         }

//         // First check most recent balance
//         if (rewardPerTokenCheckpoints[token][nCheckpoints - 1].timestamp <= timestamp) {
//             return (rewardPerTokenCheckpoints[token][nCheckpoints - 1].rewardPerToken, rewardPerTokenCheckpoints[token][nCheckpoints - 1].timestamp);
//         }

//         // Next check implicit zero balance
//         if (rewardPerTokenCheckpoints[token][0].timestamp > timestamp) {
//             return (0,0);
//         }

//         uint lower = 0;
//         uint upper = nCheckpoints - 1;
//         while (upper > lower) {
//             uint center = upper - (upper - lower) / 2; // ceil, avoiding overflow
//             RewardPerTokenCheckpoint memory cp = rewardPerTokenCheckpoints[token][center];
//             if (cp.timestamp == timestamp) {
//                 return (cp.rewardPerToken, cp.timestamp);
//             } else if (cp.timestamp < timestamp) {
//                 lower = center;
//             } else {
//                 upper = center - 1;
//             }
//         }
//         return (rewardPerTokenCheckpoints[token][lower].rewardPerToken, rewardPerTokenCheckpoints[token][lower].timestamp);
//     }

//     function _writeCheckpoint(address stake, address _ve, uint tokenId, uint balance) internal {
//         uint _timestamp = block.timestamp;
//         string memory cid = string(abi.encodePacked(stake, _ve, tokenId));
//         uint _nCheckPoints = numCheckpoints[cid];

//         if (_nCheckPoints > 0 && checkpoints[cid][_nCheckPoints - 1].timestamp == _timestamp) {
//             checkpoints[cid][_nCheckPoints - 1].balanceOf = balance;
//         } else {
//             checkpoints[cid][_nCheckPoints] = Checkpoint(_timestamp, balance);
//             numCheckpoints[cid] = _nCheckPoints + 1;
//         }
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

//     function _writeSupplyCheckpoint(address stake) internal {
//         uint _nCheckPoints = supplyNumCheckpoints;
//         uint _timestamp = block.timestamp;

//         if (_nCheckPoints > 0 && supplyCheckpoints[_nCheckPoints - 1].timestamp == _timestamp) {
//             supplyCheckpoints[_nCheckPoints - 1].supply = derivedSupply[stake];
//         } else {
//             supplyCheckpoints[_nCheckPoints] = SupplyCheckpoint(_timestamp, derivedSupply[stake]);
//             supplyNumCheckpoints = _nCheckPoints + 1;
//         }
//     }

//     function rewardsListLength() external view returns (uint) {
//         return rewards.length;
//     }

//     // returns the last time the reward was modified or periodFinish if the reward has ended
//     function lastTimeRewardApplicable(address token) public view returns (uint) {
//         return Math.min(block.timestamp, periodFinish[token]);
//     }

//     function getReward(address stake, address _ve, uint tokenId, address[] memory tokens) external lock {
//         require(msg.sender == ve(_ve).ownerOf(tokenId));
//         string memory vId = string(abi.encodePacked(_ve, tokenId));
//         for (uint i = 0; i < tokens.length; i++) {
//             (rewardPerTokenStored[tokens[i]], lastUpdateTime[tokens[i]]) = _updateRewardPerToken(tokens[i]);

//             uint _reward = earned(tokens[i], _ve, tokenId);
//             lastEarn[tokens[i]][vId] = block.timestamp;
//             userRewardPerTokenStored[tokens[i]][vId] = rewardPerTokenStored[tokens[i]];
//             if (_reward > 0) _safeTransfer(tokens[i], msg.sender, _reward);

//             emit ClaimRewards(msg.sender, tokens[i], _reward);
//         }

//         uint _derivedBalance = derivedBalances[stake][vId];
//         derivedSupply[stake] -= _derivedBalance;
//         _derivedBalance = derivedBalance(stake, _ve, tokenId, msg.sender);
//         derivedBalances[stake][vId] = _derivedBalance;
//         derivedSupply[stake] += _derivedBalance;

//         _writeCheckpoint(stake, _ve, tokenId, derivedBalances[stake][vId]);
//         _writeSupplyCheckpoint(stake);
//     }

//     function rewardPerToken(address token) public view returns (uint) {
//         if (derivedSupply[token] == 0) {
//             return rewardPerTokenStored[token];
//         }
//         return rewardPerTokenStored[token] + ((lastTimeRewardApplicable(token) - Math.min(lastUpdateTime[token], periodFinish[token])) * rewardRate[token] * PRECISION / derivedSupply[token]);
//     }

//     function derivedBalance(address stake, address _ve, uint tokenId, address account) public view returns (uint) {
//         string memory vId = string(abi.encodePacked(_ve, tokenId));
//         uint _balance = balanceOf[stake][vId];
//         uint _derived = _balance * 40 / 100;
//         uint _adjusted = 0;
//         uint _supply = erc20(_ve).totalSupply();
//         if (account == ve(_ve).ownerOf(tokenId) && _supply > 0) {
//             _adjusted = ve(_ve).balanceOfNFT(tokenId);
//             _adjusted = (totalSupply[stake] * _adjusted / _supply) * 60 / 100;
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

//     // earned is an estimation, it won't be exact till the supply > rewardPerToken calculations have run
//     function earned(address token, address _ve, uint tokenId) public view returns (uint) {
//         string memory vId = string(abi.encodePacked(_ve, tokenId));
//         string memory cid = string(abi.encodePacked(token, _ve, tokenId));
//         uint _startTimestamp = Math.max(lastEarn[token][vId], rewardPerTokenCheckpoints[token][0].timestamp);
//         if (numCheckpoints[cid] == 0) {
//             return 0;
//         }

//         uint _startIndex = getPriorBalanceIndex(token, _ve, tokenId, _startTimestamp);
//         uint _endIndex = numCheckpoints[cid]-1;

//         uint reward = 0;

//         if (_endIndex - _startIndex > 1) {
//             for (uint i = _startIndex; i < _endIndex-1; i++) {
//                 (uint _rewardPerTokenStored0,) = getPriorRewardPerToken(token, checkpoints[cid][i].timestamp);
//                 (uint _rewardPerTokenStored1,) = getPriorRewardPerToken(token, checkpoints[cid][i+1].timestamp);
//                 reward += checkpoints[cid][i].balanceOf * (_rewardPerTokenStored1 - _rewardPerTokenStored0) / PRECISION;
//             }
//         }

//         (uint _rewardPerTokenStored,) = getPriorRewardPerToken(token, checkpoints[cid][_endIndex].timestamp);
//         reward += checkpoints[cid][_endIndex].balanceOf * (rewardPerToken(token) - Math.max(_rewardPerTokenStored, userRewardPerTokenStored[token][vId])) / PRECISION;

//         return reward;
//     }

//     function depositAll(address stake, address _ve, uint tokenId) external {
//         deposit(stake, _ve, tokenId, erc20(stake).balanceOf(msg.sender));
//     }

//     function deposit(address stake, address _ve, uint tokenId, uint amount) public lock {
//         require(amount > 0 && ve(_ve).ownerOf(tokenId) == msg.sender);

//         _safeTransferFrom(stake, msg.sender, address(this), amount);
//         totalSupply[stake] += amount;
//         string memory vId = string(abi.encodePacked(_ve, tokenId));
//         balanceOf[stake][vId] += amount;

//         uint _derivedBalance = derivedBalances[stake][vId];
//         derivedSupply[stake] -= _derivedBalance;
//         _derivedBalance = derivedBalance(stake, _ve, tokenId, msg.sender);
//         derivedBalances[stake][vId] = _derivedBalance;
//         derivedSupply[stake] += _derivedBalance;

//         _writeCheckpoint(stake, _ve, tokenId, _derivedBalance);
//         _writeSupplyCheckpoint(stake);

//         emit Deposit(msg.sender, stake, _ve, tokenId, amount);
//     }

//     function withdrawAll(address stake, address _ve, uint tokenId) external {
//         string memory vId = string(abi.encodePacked(_ve, tokenId));
//         withdraw(stake, _ve, tokenId, balanceOf[stake][vId]);
//     }

//     function withdraw(address stake, address _ve, uint tokenId, uint amount) public {
//         withdrawToken(stake, _ve, tokenId, amount);
//     }

//     function withdrawToken(address stake, address _ve, uint tokenId, uint amount) public lock {
//         require(ve(_ve).ownerOf(tokenId) == msg.sender);
//         string memory vId = string(abi.encodePacked(_ve, tokenId));
//         totalSupply[stake] -= amount;
//         balanceOf[stake][vId] -= amount;
//         _safeTransfer(stake, msg.sender, amount);

//         uint _derivedBalance = derivedBalances[stake][vId];
//         derivedSupply[stake] -= _derivedBalance;
//         _derivedBalance = derivedBalance(stake, _ve, tokenId, msg.sender);
//         derivedBalances[stake][vId] = _derivedBalance;
//         derivedSupply[stake] += _derivedBalance;

//         _writeCheckpoint(stake, _ve, tokenId, derivedBalances[stake][vId]);
//         _writeSupplyCheckpoint(stake);

//         emit Withdraw(msg.sender, stake, _ve, tokenId, amount);
//     }

//     function left(address token) external view returns (uint) {
//         if (block.timestamp >= periodFinish[token]) return 0;
//         uint _remaining = periodFinish[token] - block.timestamp;
//         return _remaining * rewardRate[token];
//     }

//     function notifyRewardAmount(address token, uint amount) external lock {
//         require(amount > 0);
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
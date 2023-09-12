// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;
// pragma abicoder v2;

// import "./Library.sol";

// contract BaseV1Voter is Auth {
//     using Percentile for *;

//     address public stakeMarket; // the BaseV1Factory
//     address public immutable bribe;
//     uint public period = 7 days;
    
//     mapping(address => uint) public totalWeight; // total voting weight
//     struct Gauge {
//         uint endTime;
//         uint percentile;
//     }
//     struct Litigation {
//         uint attackerId;
//         uint defenderId;
//     }
//     uint public litigationId = 1;
//     mapping(address => uint[]) public pools; // all pools viable for incentives
//     mapping(address => uint) public totalGas;
//     mapping(address => uint) public totalVotes;
//     mapping(address => uint) public sum_of_diff_squared;
//     mapping(address => mapping(uint => Gauge)) public gauges;
//     mapping(address => mapping(uint => int256)) public weights; // pool => weight
//     mapping(string => mapping(uint => int256)) public votes; // nft => pool => votes
//     mapping(address => mapping(uint => uint[])) public poolVote; // nft => pools
//     mapping(address => mapping(uint => uint)) public usedWeights;  // nft => total voting weight of user
//     mapping(address => mapping(uint => bool)) public isGauge;
//     mapping(string => mapping(uint => uint)) public hasVoted;
//     mapping(uint => Litigation) public litigations;

//     event GaugeCreated(
//         uint indexed litigationId,
//         uint percentile, 
//         uint attackerId, 
//         uint defenderId,
//         uint creationTime, 
//         uint endTime,
//         uint gas,
//         address ve, 
//         address _token, 
//         string title,
//         string content
//     );
//     event UpdateAttackerContent(uint indexed litigationId, string content);
//     event UpdateDefenderContent(uint indexed litigationId, string content);
//     event Voted(address indexed ve, address voter, uint tokenId, int256 weight);
//     event Abstained(address ve, uint tokenId, int256 weight);
//     event Deposit(address indexed lp, address indexed gauge, uint tokenId, uint amount);
//     event Withdraw(address indexed lp, address indexed gauge, uint tokenId, uint amount);
//     event NotifyReward(address indexed sender, address indexed reward, uint amount);
//     event DistributeReward(address indexed sender, address indexed gauge, uint amount);
//     event Attach(address indexed owner, address indexed gauge, uint tokenId);
//     event Detach(address indexed owner, address indexed gauge, uint tokenId);
//     event Whitelisted(address indexed whitelister, address indexed token);

//     constructor(
//         address _bribe,
//         address _superLikeGaugeFactory
//     ) Auth(msg.sender, msg.sender, _superLikeGaugeFactory)
//     {
//         bribe = _bribe;
//     }

//     // simple re-entrancy check
//     uint internal _unlocked = 1;
//     modifier lock() {
//         require(_unlocked == 1);
//         _unlocked = 2;
//         _;
//         _unlocked = 1;
//     }

//     function setStakeMarket(address _stakeMarket) external onlyAdmin {
//         stakeMarket = _stakeMarket;
//     }

//     function updatePeriod(uint _period) external onlyAdmin {
//         period = _period;
//     }

//     function reset(address _ve, uint _tokenId) external {
//         require(ve(_ve).isApprovedOrOwner(msg.sender, _tokenId));
//         _reset(_ve, _tokenId);
//         ve(_ve).abstain(_tokenId);
//     }

//     function _reset(address _ve, uint _tokenId) internal {
//         uint[] storage _poolVote = poolVote[_ve][_tokenId];
//         uint _poolVoteCnt = _poolVote.length;
//         int256 _totalWeight = 0;
//         (
//             string memory ssid,, 
//         ) = ISuperLikeGaugeFactory(superLikeGaugeFactory).getIdentityValue(msg.sender, valueName);
//         for (uint i = 0; i < _poolVoteCnt; i ++) {
//             uint _pool = _poolVote[i];
//             hasVoted[ssid][_pool] = 0;
//             string memory ve_tokenId = string(abi.encodePacked(_ve, _tokenId));
//             int256 _votes = votes[ve_tokenId][_pool];

//             if (_votes != 0) {
//                 weights[_ve][_pool] -= _votes;
//                 votes[ve_tokenId][_pool] -= _votes;
//                 if (_votes > 0) {
//                     IStakeMarketBribe(bribe)._withdraw(_ve, uint256(_votes), _tokenId);
//                     _totalWeight += _votes;
//                 } else {
//                     _totalWeight -= _votes;
//                 }
//                 emit Abstained(_ve, _tokenId, _votes);
//             }
//         }
//         totalWeight[_ve] -= uint256(_totalWeight);
//         usedWeights[_ve][_tokenId] = 0;
//         delete poolVote[_ve][_tokenId];
//     }

//     function poke(address _ve, uint _tokenId) external {
//         uint[] memory _poolVote = poolVote[_ve][_tokenId];
//         uint _poolCnt = _poolVote.length;
//         int256[] memory _weights = new int256[](_poolCnt);
//         string memory ve_tokenId = string(abi.encodePacked(_ve, _tokenId));

//         for (uint i = 0; i < _poolCnt; i ++) {
//             _weights[i] = votes[ve_tokenId][_poolVote[i]];
//         }

//         _vote(_ve, _tokenId, _poolVote, _weights);
//     }

//     function _vote(address _ve, uint _tokenId, uint[] memory _poolVote, int256[] memory _weights) internal {
//         _reset(_ve, _tokenId);
//         uint _poolCnt = _poolVote.length;
//         int256 _totalWeight = 0;
//         int256 _usedWeight = 0;
//         // (
//         //     string memory ssid,, 
//         // ) = ISuperLikeGaugeFactory(superLikeGaugeFactory).getIdentityValue(msg.sender, valueName);
//         string memory ssid = "tepa";

//         for (uint i = 0; i < _poolCnt; i++) {
//             uint _pool = _poolVote[i];
//             require(hasVoted[ssid][_pool] < block.timestamp);
//             hasVoted[ssid][_pool] = block.timestamp + period / period * period;
//             int256 _weight = int256(gauges[_ve][_pool].percentile);

//             if (isGauge[_ve][_pool]) {
//                 int256 _poolWeight = _weight;
//                 string memory ve_tokenId = string(abi.encodePacked(_ve, _tokenId));
                
//                 require(votes[ve_tokenId][_pool] == 0);
//                 require(_poolWeight != 0);

//                 poolVote[_ve][_tokenId].push(_pool);

//                 weights[_ve][_pool] += _poolWeight;
//                 votes[ve_tokenId][_pool] += _poolWeight;
//                 if (_poolWeight > 0) {
//                     IStakeMarketBribe(bribe)._deposit(_ve, uint256(_poolWeight), _tokenId);
//                 } else {
//                     _poolWeight = -_poolWeight;
//                 }
//                 _usedWeight += _poolWeight;
//                 _totalWeight += _poolWeight;
//                 emit Voted(_ve, msg.sender, _tokenId, _poolWeight);
//             }
//         }
//         if (_usedWeight > 0) ve(_ve).voting(_tokenId);
//         totalWeight[_ve] += uint256(_totalWeight);
//         usedWeights[_ve][_tokenId] = uint256(_usedWeight);
//     }

//     function vote(address _ve, uint tokenId, uint[] calldata _poolVote, int256[] calldata _weights) external {
//         require(ve(_ve).isApprovedOrOwner(msg.sender, tokenId));
//         require(_poolVote.length == _weights.length);
//         _vote(_ve, tokenId, _poolVote, _weights);
//     }
    
//     function createGauge(
//         address _ve, 
//         address _token, 
//         uint _attackerId, 
//         uint _defenderId, 
//         uint _gas, 
//         string memory _title, 
//         string memory _content
//     ) external {
//         require(msg.sender == stakeMarket, "only stake market");
//         require(!isGauge[_ve][_attackerId] && !isGauge[_ve][_defenderId], "exists");
//         _safeTransferFrom(_token, stakeMarket, bribe, _gas);
//         uint percentile = _updateValues(_ve, _attackerId, _defenderId, _gas);
//         emit GaugeCreated(
//             litigationId++,
//             percentile, 
//             _attackerId, 
//             _defenderId,
//             block.timestamp,
//             block.timestamp + period / period * period,
//             _gas,
//             _ve, 
//             _token,
//             _title,
//             _content
//         );
//     }

//     function _updateValues(address _ve, uint _attackerId, uint _defenderId, uint _gas) internal returns(uint) {
//         isGauge[_ve][_attackerId] = true;
//         isGauge[_ve][_defenderId] = true;
//         pools[_ve].push(_attackerId);
//         litigations[litigationId].attackerId = _attackerId;
//         litigations[litigationId].defenderId = _defenderId;
//         (uint percentile, uint sods) = Percentile.computePercentileFromData(
//             false,
//             _gas,
//             totalGas[_ve] + _gas,
//             totalVotes[_ve],
//             sum_of_diff_squared[_ve]
//         );
//         totalVotes[_ve] += 1;
//         totalGas[_ve] += _gas;
//         sum_of_diff_squared[_ve] = sods;
//         gauges[_ve][_attackerId].percentile = percentile;
//         gauges[_ve][_attackerId].endTime = block.timestamp + period / period * period;
//         return percentile;
//     }

//     function updateAttackerContent(uint _litigationId, string memory content) external {
//         require(IStakeMarket(stakeMarket).getOwner(litigations[_litigationId].attackerId) == msg.sender);
//         emit UpdateAttackerContent(_litigationId, content);
//     }

//     function updateDefenderContent(uint _litigationId, string memory content) external {
//         require(IStakeMarket(stakeMarket).getOwner(litigations[_litigationId].defenderId) == msg.sender);
//         emit UpdateDefenderContent(_litigationId, content);
//     } 

//     function updateStakeFromVoter(address _ve, uint _litigationId) external {
//         require(gauges[_ve][litigations[_litigationId].attackerId].endTime < block.timestamp);
//         uint won = weights[_ve][litigations[_litigationId].attackerId] > 0 
//         ? litigations[_litigationId].attackerId 
//         : litigations[_litigationId].defenderId;
//         IStakeMarket(stakeMarket).updateStakeFromVoter(
//             won, 
//             won == litigations[_litigationId].attackerId 
//             ? litigations[_litigationId].defenderId 
//             : litigations[_litigationId].attackerId
//         );
//         isGauge[_ve][litigations[_litigationId].attackerId] = false;
//         isGauge[_ve][litigations[_litigationId].defenderId] = false;
//         delete gauges[_ve][_litigationId];
//         delete litigations[_litigationId];
//     }

//     function length(address _ve) external view returns (uint) {
//         return pools[_ve].length;
//     }

//     function claimBribes(address _ve, address[] memory _tokens, uint _tokenId) external {
//         require(ve(_ve).isApprovedOrOwner(msg.sender, _tokenId));
//         IStakeMarketBribe(bribe).getRewardForOwner(_ve, _tokenId, _tokens);
//     }

//     function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
//         require(token.code.length > 0);
//         (bool success, bytes memory data) =
//         token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
//         require(success && (data.length == 0 || abi.decode(data, (bool))));
//     }
// }

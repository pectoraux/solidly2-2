// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;
// pragma abicoder v2;

// import "./Library.sol";


// contract BaseV1Voter {
//     address public immutable factory;
//     address public immutable vavaHelper;
//     address public immutable lenderFactory;
//     address public immutable superLikeGaugeFactory;

//     uint internal constant DURATION = 7 days; // rewards are released over 7 days
//     mapping(address => mapping(address => uint)) public upVotes; // pool => weight
//     mapping(address => mapping(address => uint)) public downVotes; // pool => weight

//     mapping(address => uint) public totalWeight; // total voting weight

//     mapping(address => address[]) public pools; // all pools viable for incentives
//     mapping(address => mapping(address => int256)) public weights; // pool => weight
//     mapping(string => mapping(address => int256)) public votes; // nft => pool => votes
//     mapping(address => mapping(uint => address[])) public poolVote; // nft => pools
//     mapping(address => mapping(uint => uint)) public usedWeights;  // nft => total voting weight of user
//     mapping(address => mapping(string => bool)) public ssidVoted;
//     struct Gauge {
//         uint amount;
//         uint start;
//     }
//     mapping(address => mapping(address => Gauge)) public gauges;
//     mapping(address => mapping(address => bool)) public isGauge;
    
//     event GaugeCreated(address indexed user, address indexed va, address indexed pool, uint amount);
//     event Voted(address indexed voter, address indexed va, uint tokenId, int256 weight);
//     event Abstained(address indexed va, uint tokenId, int256 weight);

//     constructor(
//         address _factory,
//         address _vavaHelper,
//         address _lenderFactory
//         address _superLikeGaugeFactory
//     ) {
//         factory = _factory;
//         vavaHelper = _vavaHelper;
//         lenderFactory = _lenderFactory;
//         superLikeGaugeFactory = _superLikeGaugeFactory;
//     }

//     // simple re-entrancy check
//     uint internal _unlocked = 1;
//     modifier lock() {
//         require(_unlocked == 1);
//         _unlocked = 2;
//         _;
//         _unlocked = 1;
//     }

//     function getTotalWeight(address _va) public view returns(uint) {
//         return totalWeight[_va];
//     }

//     function reset(address _va, uint _tokenId) external {
//         require(ve(_va).isApprovedOrOwner(msg.sender, _tokenId));
//         _reset(_va, _tokenId);
//         ve(_va).abstain(_tokenId);
//     }

//     function _reset(address _va, uint _tokenId) internal {
//         address[] storage _poolVote = poolVote[_va][_tokenId];
//         uint _poolVoteCnt = _poolVote.length;
//         int256 _totalWeight = 0;
//         (
//             string memory ssid,, 
//         ) = ISuperLikeGaugeFactory(superLikeGaugeFactory).getIdentityValue(
//             va(_va).ownerOf(_tokenId), 
//             IVava(_va).valueName()
//         );
//         for (uint i = 0; i < _poolVoteCnt; i ++) {
//             address _pool = _poolVote[i];
//             string memory va_tokenId = string(abi.encodePacked(_va, _tokenId));
//             int256 _votes = votes[va_tokenId][_pool];

//             if (_votes != 0) {
//                 weights[_va][_pool] -= _votes;
//                 votes[va_tokenId][_pool] -= _votes;
//                 ssidVoted[_va][ssid] = false;
//                 if (_votes > 0) {
//                     _totalWeight += _votes;
//                     upVotes[_va][_pool] -= uint(_votes);
//                 } else {
//                     _totalWeight -= _votes;
//                     downVotes[_va][_pool] -= uint(_votes);
//                 }
//                 emit Abstained(_va, _tokenId, _votes);
//             }
//         }
//         totalWeight[_va] -= uint256(_totalWeight);
//         usedWeights[_va][_tokenId] = 0;
//         delete poolVote[_va][_tokenId];
//     }

//     function poke(address _va, uint _tokenId) external {
//         address[] memory _poolVote = poolVote[_va][_tokenId];
//         uint _poolCnt = _poolVote.length;
//         int256[] memory _weights = new int256[](_poolCnt);
//         string memory va_tokenId = string(abi.encodePacked(_va, _tokenId));

//         for (uint i = 0; i < _poolCnt; i ++) {
//             _weights[i] = votes[va_tokenId][_poolVote[i]];
//         }

//         _vote(_va, _tokenId, _poolVote, _weights);
//     }

//     function _vote(
//         address _va, 
//         uint _tokenId, 
//         address[] memory _poolVote, 
//         int256[] memory _weights
//     ) internal {
//         _reset(_va, _tokenId);
//         uint _poolCnt = _poolVote.length;
//         bool _onePersonOneVote = IVavaHelper(vavaHelper).onePersonOneVote(_va);
//         int256 _weight = int256(va(_va).balanceOfNFT(_tokenId));
//         string memory va_tokenId = string(abi.encodePacked(_va, _tokenId));
//         int256 _totalVoteWeight = 0;
//         int256 _totalWeight = 0;
//         int256 _usedWeight = 0;

//         for (uint i = 0; i < _poolCnt; i++) {
//             if (_onePersonOneVote) {
//                 _totalVoteWeight += 1;
//             } else {
//                 _totalVoteWeight += _weights[i] > 0 ? _weights[i] : -_weights[i];
//             }
//         }

//         for (uint i = 0; i < _poolCnt; i++) {
//             address _pool = _poolVote[i];

//             if (ILenderFactory(lenderFactory).isLender(_pool)) {
//                 int256 _poolWeight = _onePersonOneVote 
//                 ? _weights[i] > 0 
//                 ? 1 : - 1
//                 : _weights[i] * _weight / _totalVoteWeight;
//                 (
//                     string memory ssid,, 
//                 ) = ISuperLikeGaugeFactory(superLikeGaugeFactory).getIdentityValue(
//                     va(_va).ownerOf(_tokenId), 
//                     IVava(_va).valueName()
//                 );
//                 require(votes[va_tokenId][_pool] == 0);
//                 require(_poolWeight != 0);
//                 require(!ssidVoted[_va][ssid]);

//                 poolVote[_va][_tokenId].push(_pool);

//                 weights[_va][_pool] += _poolWeight;
//                 votes[va_tokenId][_pool] += _poolWeight;
//                 ssidVoted[_va][ssid] = true;
//                 if (_poolWeight > 0) {
//                     upVotes[_va][_pool] += uint(_poolWeight);
//                 } else {
//                     _poolWeight = -_poolWeight;
//                     downVotes[_va][_pool] += uint(_poolWeight);
//                 }
//                 _usedWeight += _poolWeight;
//                 _totalWeight += _poolWeight;
//                 emit Voted(msg.sender, _va, _tokenId, _poolWeight);
//             }
//         }
//         if (_usedWeight > 0) ve(_va).voting(_tokenId);
//         totalWeight[_va] += uint256(_totalWeight);
//         usedWeights[_va][_tokenId] = uint256(_usedWeight);
//     }

//     function vote(address _va, uint tokenId, address[] calldata _poolVote, int256[] calldata _weights) external {
//         require(va(_va).isApprovedOrOwner(msg.sender, tokenId));
//         require(_poolVote.length == _weights.length);
//         _vote(_va, tokenId, _poolVote, _weights);
//     }

//     function createGauge(address _va, address _pool, uint _amount) external returns(address) {
//         require(ILenderFactory(lenderFactory).isLender(_pool));
//         if (!isGauge[_va][_pool]) pools[_va].push(_pool);
//         gauges[_va][_pool].amount = _amount;
//         gauges[_va][_pool].start = block.timestamp;
//         isGauge[_va][_pool] = true;
//         upVotes[_va][_pool] = 0;
//         downVotes[_va][_pool];
        
//         emit GaugeCreated(msg.sender, _va, _pool, _amount);
//         return _pool;
//     }

//     function getBalance(address _va, address _pool) external returns(uint) {
//         if (gauges[_va][_pool].start <= block.timestamp && (
//             (upVotes[_va][_pool] > downVotes[_va][_pool]
//         ) {
//             return gauges[_va][_pool].amount;
//         }
//         return 0;
//     }

//     function length(address _va) external view returns (uint) {
//         return pools[_va].length;
//     }

//     function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
//         require(token.code.length > 0);
//         (bool success, bytes memory data) =
//         token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
//         require(success && (data.length == 0 || abi.decode(data, (bool))));
//     }
// }

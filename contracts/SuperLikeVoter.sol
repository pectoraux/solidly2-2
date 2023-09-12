// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;

// import "./Percentile.sol";

// contract SuperLikeVoter is Percentile {

//     uint internal constant week = 86400 * 7; // allows minting once per week (reset every Thursday 00:00 UTC)
//     address public immutable _ve; // the ve token that governs these contracts
//     address internal immutable base;
//     address public immutable gaugefactory;
//     uint internal constant DURATION = 7 days; // rewards are released over 7 days
//     address public minter;
//     address public devaddr;
//     uint public LISTING_DIVISOR = 20000000e18;
//     uint public totalWeight; // total voting weight
//     mapping(address => bool) public isBlacklisted;
//     address[] public pools; // all pools viable for incentives
//     mapping(address => address) public gauges; // pool => gauge
//     mapping(address => address) public poolForGauge; // gauge => pool
//     mapping(address => address) public bribes; // gauge => bribe
//     mapping(address => int256) public weights; // pool => weight
//     mapping(uint => mapping(address => int256)) public votes; // nft => pool => votes
//     mapping(uint => address[]) public poolVote; // nft => pools
//     mapping(uint => uint) public usedWeights;  // nft => total voting weight of user
//     mapping(address => bool) public isGauge;
//     uint public Q1_ZSCORE = 5;
//     uint public Q2_ZSCORE = 10;
//     uint public Q3_ZSCORE = 15;
//     uint public Q4_ZSCORE = 20;
//     uint lastUpdate;
//     // lastUpdate => quartiles
//     mapping(uint => int256[]) public quartiles;
    
//     event GaugeCreated(address indexed gauge, address creator, address indexed pool);
//     event Voted(address indexed voter, uint tokenId, int256 weight);
//     event Abstained(uint tokenId, int256 weight);
//     event Deposit(address indexed lp, address indexed gauge, uint tokenId, uint amount);
//     event Withdraw(address indexed lp, address indexed gauge, uint tokenId, uint amount);
//     event NotifyReward(address indexed sender, address indexed reward, uint amount);
//     event DistributeReward(address indexed sender, address indexed gauge, uint amount);
//     event Attach(address indexed owner, address indexed gauge, uint tokenId);
//     event Detach(address indexed owner, address indexed gauge, uint tokenId);
//     event Whitelisted(address indexed whitelister, address indexed token);

//     constructor(address __ve, address _gauges) {
//         _ve = __ve;
//         base = ve(__ve).token();
//         gaugefactory = _gauges;
//         minter = msg.sender;
//         devaddr = msg.sender;
//     }

//     // simple re-entrancy check
//     uint internal _unlocked = 1;
//     modifier lock() {
//         require(_unlocked == 1);
//         _unlocked = 2;
//         _;
//         _unlocked = 1;
//     }

//     function setMinter(address _minter) external {
//         require(msg.sender == minter);
//         minter = _minter;
//     }

//     function listing_fee() public view returns (uint) {
//         return (erc20(base).totalSupply() - erc20(_ve).totalSupply()) / LISTING_DIVISOR;
//     }

//     function updateListingDivisor(uint newDivisor) external {
//         require(msg.sender == minter);
//         LISTING_DIVISOR = newDivisor;
//     }

//     function reset(uint _tokenId) external {
//         require(ve(_ve).isApprovedOrOwner(msg.sender, _tokenId), "Not owner of tokenId");
//         _reset(_tokenId);
//         ve(_ve).abstain(_tokenId);
//     }

//     function _reset(uint _tokenId) internal {
//         address[] storage _poolVote = poolVote[_tokenId];
//         uint _poolVoteCnt = _poolVote.length;
//         int256 _totalWeight = 0;

//         for (uint i = 0; i < _poolVoteCnt; i ++) {
//             address _pool = _poolVote[i];
//             int256 _votes = votes[_tokenId][_pool];

//             if (_votes != 0) {
//                 weights[_pool] -= _votes;
//                 votes[_tokenId][_pool] -= _votes;
//                 if (_votes > 0) {
//                     _totalWeight += _votes;
//                 } else {
//                     _totalWeight -= _votes;
//                 }
//                 emit Abstained(_tokenId, _votes);
//             }
//         }
//         totalWeight -= uint256(_totalWeight);
//         usedWeights[_tokenId] = 0;
//         delete poolVote[_tokenId];
//     }

//     function poke(uint _tokenId) external {
//         address[] memory _poolVote = poolVote[_tokenId];
//         uint _poolCnt = _poolVote.length;
//         int256[] memory _weights = new int256[](_poolCnt);

//         for (uint i = 0; i < _poolCnt; i ++) {
//             _weights[i] = votes[_tokenId][_poolVote[i]];
//         }

//         _vote(_tokenId, _poolVote, _weights);
//     }

//     function _vote(uint _tokenId, address[] memory _poolVote, int256[] memory _weights) internal {
//         _reset(_tokenId);
//         uint _poolCnt = _poolVote.length;
//         int256 _weight = int256(ve(_ve).balanceOfNFT(_tokenId));
//         int256 _totalVoteWeight = 0;
//         int256 _totalWeight = 0;
//         int256 _usedWeight = 0;

//         for (uint i = 0; i < _poolCnt; i++) {
//             _totalVoteWeight += _weights[i] > 0 ? _weights[i] : -_weights[i];
//         }

//         for (uint i = 0; i < _poolCnt; i++) {
//             address _pool = _poolVote[i];
//             address _gauge = gauges[_pool];

//             if (isGauge[_gauge]) {
//                 int256 _poolWeight = _weights[i] * _weight / _totalVoteWeight;
//                 require(votes[_tokenId][_pool] == 0);
//                 require(_poolWeight != 0);

//                 poolVote[_tokenId].push(_pool);

//                 weights[_pool] += _poolWeight;
//                 computePercentile(uint(_poolWeight));
//                 votes[_tokenId][_pool] += _poolWeight;
//                 if (_poolWeight < 0) {
//                     _poolWeight = -_poolWeight;
//                 }
//                 _usedWeight += _poolWeight;
//                 _totalWeight += _poolWeight;
//                 emit Voted(msg.sender, _tokenId, _poolWeight);
//             }
//         }
//         totalWeight += uint256(_totalWeight);
//         usedWeights[_tokenId] = uint256(_usedWeight);
//     }

//     function vote(uint tokenId, address[] calldata _poolVote, int256[] calldata _weights) external {
//         require(ve(_ve).isApprovedOrOwner(msg.sender, tokenId), "Not owner of tokenId");
//         require(_poolVote.length == _weights.length, "Invalid poolVote");
//         _vote(tokenId, _poolVote, _weights);
//         if(lastUpdate <= block.timestamp) {
//             lastUpdate = (block.timestamp + week) / week * week;
//         }
//     }

//     function createGauge(address _pool, uint _tokenId, uint _referrerTokenId) external returns (address) {
//         require(gauges[_pool] == address(0x0), "exists");
//         require(msg.sender == ve(_ve).ownerOf(_tokenId));
//         require(ve(_ve).balanceOfNFT(_tokenId) > listing_fee());
//         address _gauge = ISuperLikeGaugeFactory(gaugefactory).createGauge(
//             msg.sender,
//             _ve, 
//             _referrerTokenId,
//             _tokenId
//         );

//         gauges[_pool] = _gauge;
//         poolForGauge[_gauge] = _pool;
//         isGauge[_gauge] = true;
//         pools.push(_pool);
//         emit GaugeCreated(_gauge, msg.sender, _pool);
//         return _gauge;
//     }

//     function length() external view returns (uint) {
//         return pools.length;
//     }

//     function blacklist(address[] memory _gauges, bool[] memory _blacklists) external {
//         require(msg.sender == devaddr, "Only dev!");
//         require(_gauges.length == _blacklists.length, "Ueven lists");

//         for (uint i = 0; i < _gauges.length; i++) {
//             isBlacklisted[_gauges[i]] = _blacklists[i];
//         }
//     }

//     function updateDev(address _newDev) external {
//         require(msg.sender == devaddr, "Only dev!");
//         devaddr = _newDev;
//     }

//     function getColor(address _gauge) external view returns(uint) {
//         if (isBlacklisted[_gauge]) {
//             return 0;
//         }
//         require(lastUpdate <= block.timestamp, "Week not past yet");
//         int256 _weight = weights[_gauge];
//         if (_weight < quartiles[lastUpdate][0]) { //1st quartile
//             return 0;
//         } else if (_weight < quartiles[lastUpdate][1]) { //2nd quartile
//             return 1;
//         } else if (_weight < quartiles[lastUpdate][2]) { //3rd quartile
//             return 2;
//         } else { //4th quartile
//             return 3;
//         }
//     }

//     function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
//         require(token.code.length > 0);
//         (bool success, bytes memory data) =
//         token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
//         require(success && (data.length == 0 || abi.decode(data, (bool))));
//     }
// }

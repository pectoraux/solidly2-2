// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;

// library Math {
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
//     function attach(uint tokenId) external;
//     function detach(uint tokenId) external;
//     function voting(uint tokenId) external;
//     function abstain(uint tokenId) external;
// }

// interface IBaseV1Factory {
//     function isPair(address) external view returns (bool);
// }

// interface IBaseV1Core {
//     function claimFees() external returns (uint, uint);
//     function tokens() external returns (address, address);
// }

// interface IBaseV1GaugeFactory {
//     function createGauge(address, address, uint) external returns (address);
// }

// interface IGauge {
//     function notifyRewardAmount(address token, uint amount) external;
//     function getReward(address account, address[] memory tokens) external;
//     function claimFees() external returns (uint claimed0, uint claimed1);
//     function left(address token) external view returns (uint);
// }

// interface IMinter {
//     function update_period() external returns (uint);
// }

// contract WagmiReferralVoter {

//     address public immutable _ve; // the ve token that governs these contracts
//     address internal immutable base;
//     address public immutable gaugefactory;
//     uint internal constant DURATION = 7 days; // rewards are released over 7 days
//     address public minter;
//     address public devaddr;
//     address public stakeMarket;

//     uint LISTING_DIVISOR = 20000000e18;
//     uint internal constant week = 86400 * 7; // allows minting once per week (reset every Thursday 00:00 UTC)

//     uint public totalWeight; // total voting weight

//     address[] public pools; // all pools viable for incentives
//     mapping(address => address) public gauges; // pool => gauge
//     mapping(address => address) public poolForGauge; // gauge => pool
//     mapping(address => int256) public weights; // pool => weight
//     mapping(uint => mapping(address => int256)) public votes; // nft => pool => votes
//     // used to make sure only one vote per purchase is made per week
//     mapping(uint => mapping(address => uint)) public countVotes; 
//     mapping(uint => address[]) public poolVote; // nft => pools
//     mapping(uint => uint) public usedWeights;  // nft => total voting weight of user
//     mapping(address => bool) public isGauge;
//     mapping(address => uint) public gaugeTokenIds; //pool => tokenId

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

//     constructor(address __ve, address  _gauges) {
//         _ve = __ve;
//         base = ve(__ve).token();
//         gaugefactory = _gauges;
//         minter = msg.sender;
//         devaddr = msg.sender;
//         stakeMarket = msg.sender;
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

//     function setStakeMarket(address _market) external {
//         require(msg.sender == devaddr);
//         stakeMarket = _market;
//     }

//     function listing_fee() public view returns (uint) {
//         return (erc20(base).totalSupply() - erc20(_ve).totalSupply()) / LISTING_DIVISOR;
//     }

//     function updateListingDivisor(uint newDivisor) external {
//         require(msg.sender == devaddr);
//         LISTING_DIVISOR = newDivisor;
//     }

//     function updateDev(address _dev) external {
//         require(msg.sender == devaddr);
//         devaddr = _dev;
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
//                 _updateFor(gauges[_pool]);
//                 weights[_pool] -= _votes;
//                 votes[_tokenId][_pool] -= _votes;
//                 countVotes[_tokenId][_pool] = block.timestamp;
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
//         uint _poolCnt = _poolVote.length;
//         int256 _weight = int256(ve(_ve).balanceOfNFT(_tokenId));
//         uint _totalVoteWeight = _weights.length;
//         int256 _totalWeight = 0;
//         int256 _usedWeight = 0;

//         for (uint i = 0; i < _poolCnt; i++) {
//             address _pool = _poolVote[i];
//             address _gauge = gauges[_pool];

//             if (isGauge[_gauge] && countVotes[_tokenId][_pool] <= block.timestamp) {
//                 int256 _poolWeight = 1 * _weight / int256(_totalVoteWeight);
//                 require(_poolWeight != 0);
//                 _updateFor(_gauge);

//                 poolVote[_tokenId].push(_pool);

//                 weights[_pool] += _poolWeight;
//                 votes[_tokenId][_pool] += _poolWeight;
//                 countVotes[_tokenId][_pool] = (block.timestamp + week) / week * week;
//                 _usedWeight += _poolWeight;
//                 _totalWeight += _poolWeight;
//                 emit Voted(msg.sender, _tokenId, _poolWeight);
//             }
//         }
//         if (_usedWeight > 0) ve(_ve).voting(_tokenId);
//         totalWeight += uint256(_totalWeight);
//         usedWeights[_tokenId] = uint256(_usedWeight);
//     }

//     function vote(uint tokenId, address[] calldata _poolVote, int256[] calldata _weights) external {
//         require(msg.sender == stakeMarket, "Not stake market");
//         require(_poolVote.length == _weights.length, "Invalid poolVote");
//         _vote(tokenId, _poolVote, _weights);
//     }

//     function createGauge(address _pool, uint _tokenId) external returns (address) {
//         // require(_pool == msg.sender, "Not sender");
//         require(gauges[_pool] == address(0x0), "exists");
//         require(ve(_ve).balanceOfNFT(_tokenId) > listing_fee());
//         address _gauge = IBaseV1GaugeFactory(gaugefactory).createGauge(
//             address(0),
//             _ve, 
//             _tokenId
//         );
//         _attachTokenToGauge(_gauge, _tokenId, _pool);
//         _updateFor(_gauge);
//         pools.push(_pool);
//         emit GaugeCreated(_gauge, msg.sender, _pool);
//         return _gauge;
//     }

//     function _attachTokenToGauge(
//         address _gauge, 
//         uint _tokenId, 
//         address _pool
//     ) internal {
//         require(msg.sender == ve(_ve).ownerOf(_tokenId));
//         if (_tokenId > 0) ve(_ve).attach(_tokenId);
//         erc20(base).approve(_gauge, type(uint).max);
//         gauges[_pool] = _gauge;
//         poolForGauge[_gauge] = _pool;
//         gaugeTokenIds[_gauge] = _tokenId;
//         isGauge[_gauge] = true;
//         emit Attach(_pool, msg.sender, _tokenId);
//     }

//     function detachTokenFromGauge(address _gauge, uint _tokenId, address _pool) external {
//         require(msg.sender == ve(_ve).ownerOf(_tokenId), "Not token owner");
//         require(isGauge[_gauge], "Not gauge");
//         require(claimable[_gauge] == 0, "Claimable is not nil");
//         require(gaugeTokenIds[_gauge] == _tokenId, "Not gauge token");
//         if (_tokenId > 0) ve(_ve).detach(_tokenId);
//         erc20(base).approve(_gauge, 0);
//         delete gauges[_pool];
//         delete poolForGauge[_gauge];
//         delete gaugeTokenIds[_gauge];
//         isGauge[_gauge] = false;

//         emit Detach(_pool, msg.sender, _tokenId);
//     }

//     function emitWithdraw(uint tokenId, address account, uint amount) external {
//         require(isGauge[msg.sender]);
//         emit Withdraw(account, msg.sender, tokenId, amount);
//     }

//     function length() external view returns (uint) {
//         return pools.length;
//     }

//     uint internal index;
//     mapping(address => uint) internal supplyIndex;
//     mapping(address => uint) public claimable;

//     function notifyRewardAmount(uint amount) external {
//         _safeTransferFrom(base, msg.sender, address(this), amount); // transfer the distro in
//         if (totalWeight > 0) {
//             uint256 _ratio = amount * 1e18 / totalWeight; // 1e18 adjustment is removed during claim
//             if (_ratio > 0) {
//                 index += _ratio;
//             }
//         }
//         emit NotifyReward(msg.sender, base, amount);
//     }

//     function updateFor(address[] memory _gauges) external {
//         for (uint i = 0; i < _gauges.length; i++) {
//             _updateFor(_gauges[i]);
//         }
//     }

//     function updateForRange(uint start, uint end) public {
//         for (uint i = start; i < end; i++) {
//             _updateFor(gauges[pools[i]]);
//         }
//     }

//     function updateAll() external {
//         updateForRange(0, pools.length);
//     }

//     function updateGauge(address _gauge) external {
//         _updateFor(_gauge);
//     }

//     function _updateFor(address _gauge) internal {
//         address _pool = poolForGauge[_gauge];
//         int256 _supplied = weights[_pool];
//         if (_supplied > 0) {
//             uint _supplyIndex = supplyIndex[_gauge];
//             uint _index = index; // get global index0 for accumulated distro
//             supplyIndex[_gauge] = _index; // update _gauge current position to global position
//             uint _delta = _index - _supplyIndex; // see if there is any difference that need to be accrued
//             if (_delta > 0) {
//                 uint _share = uint(_supplied) * _delta / 1e18; // add accrued difference for each supplied token
//                 claimable[_gauge] += _share;
//             }
//         } else {
//             supplyIndex[_gauge] = index; // new users are set to the default global state
//         }
//     }

//     function claimRewards(address[] memory _gauges, address[][] memory _tokens) external {
//         for (uint i = 0; i < _gauges.length; i++) {
//             IGauge(_gauges[i]).getReward(msg.sender, _tokens[i]);
//         }
//     }

//     function distribute(address _gauge) public lock {
//         IMinter(minter).update_period();
//         _updateFor(_gauge);
//         uint _claimable = claimable[_gauge];
//         if (_claimable > IGauge(_gauge).left(base) && _claimable / DURATION > 0) {
//             claimable[_gauge] = 0;
//             IGauge(_gauge).notifyRewardAmount(base, _claimable);
//             emit DistributeReward(msg.sender, _gauge, _claimable);
//         }
//     }

//     function distro() external {
//         distribute(0, pools.length);
//     }

//     function distribute() external {
//         distribute(0, pools.length);
//     }

//     function distribute(uint start, uint finish) public {
//         for (uint x = start; x < finish; x++) {
//             distribute(gauges[pools[x]]);
//         }
//     }

//     function distribute(address[] memory _gauges) external {
//         for (uint x = 0; x < _gauges.length; x++) {
//             distribute(_gauges[x]);
//         }
//     }

//     function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
//         require(token.code.length > 0);
//         (bool success, bytes memory data) =
//         token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
//         require(success && (data.length == 0 || abi.decode(data, (bool))));
//     }
// }

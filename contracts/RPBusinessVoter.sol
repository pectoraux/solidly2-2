// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;

// import "./Pluscodes.sol";

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
//     function createGauge(uint, address) external returns (address);
// }

// interface IBaseV1Gauge {
//     function initialize(uint[] memory, string[] memory, uint[] memory) external;
// }

// interface IBaseV1BribeFactory {
//     function createBribe() external returns (address);
// }

// interface IGauge {
//     function notifyRewardAmount(address token, uint amount) external;
//     function getReward(address account, address[] memory tokens) external;
//     function claimFees() external returns (uint claimed0, uint claimed1);
//     function left(address token) external view returns (uint);
// }

// interface IBribe {
//     function _deposit(uint amount, uint tokenId) external;
//     function _withdraw(uint amount, uint tokenId) external;
//     function getRewardForOwner(uint tokenId, address[] memory tokens) external;
// }

// interface IMinter {
//     function update_period() external returns (uint);
// }

// interface IRPNFT {
//     function batchMint(address, uint[] memory, uint[] memory, string[] memory) external returns(uint[] memory);
// }

// contract RPBusinessVoter is PlusCodes {

//     address public immutable _ve; // the ve token that governs these contracts
//     address internal immutable base;
//     address public immutable factory; // the BaseV1Factory
//     address public immutable worldfactory;
//     address public immutable bribefactory;
//     uint internal constant DURATION = 7 days; // rewards are released over 7 days
//     address public minter;
//     address public devaddr;

//     uint public threshold = 10000;

//     uint LISTING_DIVISOR = 20000000e18;
    
//     uint public totalWeight; // total voting weight
//     uint internal constant year = 86400 * 7 * 54; // allows minting once per week (reset every Thursday 00:00 UTC)
//     uint public next_year = (block.timestamp + year) / year * year;
//     uint public current_year = block.timestamp / year * year;

//     address[] public pools; // all worlds viable for incentives
//     mapping(address => address) public worlds; // owner => world
//     mapping(address => address) public poolForWorld; // world => pool
//     mapping(address => address) public bribes; // world => bribe
//     mapping(address => int256) public weights; // world => weight
//     mapping(uint => mapping(address => int256)) public votes; // usertokenId => world => votes
//     mapping(uint => address[]) public poolVote; // usertokenId => worlds
//     mapping(uint => uint) public usedWeights;  // usertokenId => total voting weight of user
//     mapping(address => bool) public isWorld;
//     mapping(uint => uint) public isMinted; // code => true/false
//     mapping(uint => address) public miners; // code => true/false
    
//     event WorldCreated(address indexed world, address creator, address indexed bribe, string[] indexed codes);
//     event WorldDeactivated(address indexed world, address creator); 
//     event Voted(address indexed voter, uint tokenId, int256 weight);
//     event Abstained(uint tokenId, int256 weight);
//     event Withdraw(address indexed lp, address indexed gauge, uint tokenId, uint amount);
//     event Attach(address indexed owner, address indexed gauge, uint tokenId);
//     event MintNFTsFromCodes(address indexed owner, uint time, uint[] indexed codes);
//     event Whitelisted(address indexed owner, address account);
//     event NotifyReward(address indexed sender, address indexed reward, uint amount);
//     event DistributeReward(address indexed sender, address indexed world, uint amount);
//     event Detach(address indexed owner, address indexed world, uint tokenId);
//     event Deposit(address indexed lp, address indexed gauge, uint tokenId, uint amount);

//     constructor(
//         address __ve, 
//         address _factory, 
//         address _worlds, 
//         address _bribes
//     ) {
//         _ve = __ve;
//         base = ve(__ve).token();
//         factory = _factory; //rp mine
//         worldfactory = _worlds;
//         bribefactory = _bribes;
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

//     function updateYear(uint newYr) external {
//         require(devaddr == msg.sender, "RPVoter: Not dev");
//         current_year = newYr;
//     }

//     function listing_fee() public view returns (uint) {
//         return (erc20(base).totalSupply() - erc20(_ve).totalSupply()) / LISTING_DIVISOR;
//     }

//     function updateListingDivisor(uint newDivisor) external {
//         require(msg.sender == devaddr);
//         LISTING_DIVISOR = newDivisor;
//     }

//     function updateThreshold(uint newThresh) external {
//         require(msg.sender == devaddr);
//         threshold = newThresh;
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
//                 _updateFor(worlds[_pool]);
//                 weights[_pool] -= _votes;
//                 votes[_tokenId][_pool] -= _votes;
//                 if (_votes > 0) {
//                     IBribe(bribes[worlds[_pool]])._withdraw(uint256(_votes), _tokenId);
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
//             address _world = worlds[_pool];

//             if (isWorld[_world]) {
//                 int256 _poolWeight = _weights[i] * _weight / _totalVoteWeight;
//                 require(votes[_tokenId][_pool] == 0);
//                 require(_poolWeight != 0);
//                 _updateFor(_world);
                
//                 poolVote[_tokenId].push(_pool);

//                 weights[_pool] += _poolWeight;
//                 votes[_tokenId][_pool] += _poolWeight;
//                 if (_poolWeight > 0) {
//                     IBribe(bribes[_world])._deposit(uint256(_poolWeight), _tokenId);
//                 } else {
//                     _poolWeight = -_poolWeight;
//                 }
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
//         require(ve(_ve).isApprovedOrOwner(msg.sender, tokenId), "Not token owner");
//         require(_poolVote.length == _weights.length);
//         _vote(tokenId, _poolVote, _weights);
//     }

//     function canAttachCodesToWorld(uint[] memory __codes, string memory _planet, uint _year) 
//     public view returns(uint[] memory, string[] memory, uint[] memory) {
//         uint[] memory _codes = new uint[](__codes.length);
//         uint[] memory _years = new uint[](__codes.length);
//         string[] memory _planets = new string[](__codes.length);
//         uint j = 0;
//         for (uint i = 0; i < __codes.length; i++) {
//             if (isMinted[__codes[i]] < threshold) {
//                 _codes[j] = __codes[i];
//                 _years[j] = _year;
//                 _planets[j] = _planet;
//                 j++;
//             }
//         }
//         return (_codes, _planets, _years);
//     }

//     function updateCurrentYear() public {
//         if (next_year <= block.timestamp) {
//             current_year = block.timestamp / year * year;
//             next_year = (block.timestamp + year) / year * year;
//         }
//     }

//     function generateCodes(
//         string[] memory _codes, 
//         string memory _planet, 
//         uint _year
//     ) public view returns(uint[] memory) {
//         require(_year <= current_year, "No RP for future");
//         uint[] memory result = new uint[](_codes.length);
//         for (uint i = 0; i < _codes.length; i++) {
//             result[i] = uint(keccak256(abi.encodePacked(
//                 _codes[i],
//                 _year == current_year ? 1 : _year,
//                 _planet 
//             )));
//         }
//         return result;
//     }

//     function createGauge(
//         uint _tokenId,
//         string[] memory __codes, // plus code
//         string memory _planet,
//         uint _year
//     ) external returns (address) {
//         require(worlds[msg.sender] == address(0x0), "exists");
//         require(ve(_ve).balanceOfNFT(_tokenId) > listing_fee(), "Below listing fee");
//         // require(!isBlacklisted[msg.sender], "Address is blacklisted");
//         address _bribe = IBaseV1BribeFactory(bribefactory).createBribe();
//         address _world = IBaseV1GaugeFactory(worldfactory).createGauge(
//             _tokenId,
//             _ve
//         );
//         require(msg.sender == ve(_ve).ownerOf(_tokenId));
//         erc20(base).approve(_world, type(uint).max);
//         bribes[_world] = _bribe;
//         worlds[msg.sender] = _world;
//         poolForWorld[_world] = msg.sender;
//         isWorld[_world] = true;
//         _updateFor(_world);
//         pools.push(msg.sender);
//         emit WorldCreated(_world, msg.sender, _bribe, __codes);
//         initialize(_world, __codes, _planet, _year);
//         return _world;
//     }

//     function initialize(
//         address _world, 
//         string[] memory __codes, // plus code
//         string memory _planet,
//         uint _year
//     ) public {
//         require(poolForWorld[_world] == msg.sender, "Not world creator");
//         // require(!isBlacklisted[msg.sender], "Address is blacklisted");
//         require(batchValidateCodes(__codes), "Invalid list of Plus codes");
//         updateCurrentYear();
//         uint[] memory _codes0 = generateCodes(__codes, _planet, _year);
//         updateMinted(_codes0);
//         (
//             uint[] memory _codes,
//             string[] memory _planets,
//             uint[] memory _years
//         ) = canAttachCodesToWorld(_codes0, _planet, _year);
//         require(_codes[0] != 0, "All your codes have already been mined");
//         require(_years[0] == _year, "Invalid years");

//         IBaseV1Gauge(_world).initialize(
//             _codes, 
//             _planets, 
//             _years
//         );
//     }

//     function deactivateWorld(address _world) external returns(address) {
//         require(isWorld[_world], "Not a world");
//         require(poolForWorld[_world] == msg.sender, "Not world creator");
//         delete bribes[_world];
//         delete poolForWorld[_world];
//         isWorld[_world] = false;
//         claimable[_world] = 0;
//         weights[_world] = 0;
//         emit WorldDeactivated(_world, msg.sender);
//         return _world;
//     }

//     function updateMinted(uint[] memory _codes) public {
//         for (uint i = 0; i < _codes.length; i++) {
//             if (isMinted[_codes[i]] >= threshold 
//                 && miners[_codes[i]] != address(0)
//             ) {
//                 isMinted[_codes[i]] = claimable[miners[_codes[i]]];
//             }
//         }
//     }

//     function mintNFTsFromCodes(
//         uint[] memory _codes, 
//         string[] memory _planets, 
//         uint[] memory _years
//     ) external lock returns(uint[] memory) {
//         address _world = msg.sender;
//         require(isWorld[_world], "Not a world");
//         require(_codes.length == _planets.length, "Invalid list");
//         require(_codes.length == _years.length, "Invalid list");
//         uint _claimable = claimable[_world];
//         require(_claimable >= threshold, "Not enough votes");
        
//         uint[] memory __codes = new uint[](_codes.length);
//         string[] memory __planets = new string[](_codes.length);
//         uint[] memory __years = new uint[](_codes.length);
//         uint j = 0;
//         updateMinted(_codes);
//         for (uint i = 0; i < _codes.length; i++) {
//             if (isMinted[_codes[i]] < threshold) { // already mined
//                 isMinted[_codes[i]] = _claimable;  // is reverted in case of error
//                 miners[_codes[i]] = _world;
//                 __codes[j] = _codes[i];
//                 __planets[j] = _planets[i];
//                 __years[j] = _years[i];
//                 j += 1;
//             }
//         }
//         uint[] memory _tokenIds;
//         // _tokenIds = IRPNFT(factory).batchMint(
//         //     poolForWorld[_world],
//         //     __codes, 
//         //     __years, 
//         //     __planets
//         // );

//         emit MintNFTsFromCodes(_world, block.timestamp, __codes);
//         return _tokenIds;
//     }

//     function length() external view returns (uint) {
//         return pools.length;
//     }

//     function attachTokenToGauge(uint tokenId, address account) external {
//         require(isWorld[msg.sender]);
//         if (tokenId > 0) ve(_ve).attach(tokenId);
//         emit Attach(account, msg.sender, tokenId);
//     }

//     function emitDeposit(uint tokenId, address account, uint amount) external {
//         require(isWorld[msg.sender]);
//         emit Deposit(account, msg.sender, tokenId, amount);
//     }

//     function detachTokenFromGauge(uint tokenId, address account) external {
//         require(isWorld[msg.sender]);
//         if (tokenId > 0) ve(_ve).detach(tokenId);
//         emit Detach(account, msg.sender, tokenId);
//     }

//     function emitWithdraw(uint tokenId, address account, uint amount) external {
//         require(isWorld[msg.sender]);
//         emit Withdraw(account, msg.sender, tokenId, amount);
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

//     function updateFor(address[] memory _worlds) external {
//         for (uint i = 0; i < _worlds.length; i++) {
//             _updateFor(_worlds[i]);
//         }
//     }

//     function updateForRange(uint start, uint end) public {
//         for (uint i = start; i < end; i++) {
//             _updateFor(worlds[pools[i]]);
//         }
//     }

//     function updateAll() external {
//         updateForRange(0, pools.length);
//     }

//     function updateGauge(address _world) external {
//         _updateFor(_world);
//     }

//     function _updateFor(address _world) internal {
//         address _pool = poolForWorld[_world];
//         int256 _supplied = weights[_pool];
//         if (_supplied > 0) {
//             uint _supplyIndex = supplyIndex[_world];
//             uint _index = index; // get global index0 for accumulated distro
//             supplyIndex[_world] = _index; // update _world current position to global position
//             uint _delta = _index - _supplyIndex; // see if there is any difference that need to be accrued
//             if (_delta > 0) {
//                 uint _share = uint(_supplied) * _delta / 1e18; // add accrued difference for each supplied token
//                 claimable[_world] += _share;
//             }
//         } else {
//             supplyIndex[_world] = index; // new users are set to the default global state
//         }
//     }

//     function claimRewards(address[] memory _worlds, address[][] memory _tokens) external {
//         for (uint i = 0; i < _worlds.length; i++) {
//             IGauge(_worlds[i]).getReward(msg.sender, _tokens[i]);
//         }
//     }

//     function claimBribes(address[] memory _bribes, address[][] memory _tokens, uint _tokenId) external {
//         require(ve(_ve).isApprovedOrOwner(msg.sender, _tokenId));
//         for (uint i = 0; i < _bribes.length; i++) {
//             IBribe(_bribes[i]).getRewardForOwner(_tokenId, _tokens[i]);
//         }
//     }

//     function distribute(address _world) public lock {
//         IMinter(minter).update_period();
//         _updateFor(_world);
//         uint _claimable = claimable[_world];
//         if (_claimable > IGauge(_world).left(base) 
//             && _claimable / DURATION > 0
//             && _claimable >= threshold
//         ) {
//             claimable[_world] = 0;
//             IGauge(_world).notifyRewardAmount(base, _claimable);
//             emit DistributeReward(msg.sender, _world, _claimable);
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
//             distribute(worlds[pools[x]]);
//         }
//     }

//     function distribute(address[] memory _worlds) external {
//         for (uint x = 0; x < _worlds.length; x++) {
//             distribute(_worlds[x]);
//         }
//     }

//     function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
//         require(token.code.length > 0);
//         (bool success, bytes memory data) =
//         token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
//         require(success && (data.length == 0 || abi.decode(data, (bool))));
//     }
// }

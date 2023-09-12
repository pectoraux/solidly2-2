// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;
// pragma abicoder v2;

// import "./Library.sol";


// contract ValuepoolVoter {
//     address public lenderFactory;
//     address public devaddr_;
//     enum VoteOption {
//         Percentile,
//         VotingPower,
//         Unique
//     }
//     address public profile;
//     address public ssi;
//     mapping(address => VoteOption) public voteOption;
//     mapping(address => uint) public totalWeight; // total voting weight
//     mapping(address => uint) public period;
//     mapping(address => address[]) public pools; // all pools viable for incentives
//     mapping(address => mapping(address => int256)) public weights; // pool => weight
//     mapping(string => mapping(address => int256)) public votes; // nft => pool => votes
//     mapping(address => mapping(uint => address[])) public poolVote; // nft => pools
//     mapping(address => mapping(uint => uint)) public usedWeights;  // nft => total voting weight of user
//     mapping(address => uint) public minimumLockValue;
//     struct Gauge {
//         uint amount;
//         uint start;
//     }
//     mapping(address => mapping(bytes32 => Gauge)) public gauges;
//     mapping(address => mapping(address => bool)) public isGauge;
    
//     event GaugeCreated(
//         address user, 
//         address va, 
//         address pool, 
//         uint amount, 
//         uint endTime, 
//         string title, 
//         string content
//     );
//     event Voted(address indexed voter, address indexed va, uint tokenId, uint profileId, int256 weight, bool like);
//     event Abstained(address indexed va, uint tokenId, int256 weight);

//     constructor(address _profile, address _ssi) {
//         devaddr_ = msg.sender;
//         profile = _profile;
//         ssi = _ssi;
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

//     function setLenderFactory(address _lenderFactory) external {
//         require(devaddr_ == msg.sender);
//         lenderFactory = _lenderFactory;
//     }

//     function reset(address _va, uint _tokenId, uint _profileId) external {
//         require(ve(_va).isApprovedOrOwner(msg.sender, _tokenId));
//         _reset(_va, _tokenId, _profileId);
//         ve(_va).abstain(_tokenId);
//     }

//     function _reset(address _va, uint _tokenId, uint _profileId) internal {
//         address[] storage _poolVote = poolVote[_va][_tokenId];
//         uint _poolVoteCnt = _poolVote.length;
//         int256 _totalWeight = 0;
//         require(IProfile(profile).addressToProfileId(msg.sender) == _profileId && _profileId > 0);
//         for (uint i = 0; i < _poolVoteCnt; i ++) {
//             address _pool = _poolVote[i];
//             string memory va_tokenId = string(abi.encodePacked(_va, _profileId, _tokenId));
//             int256 _votes = votes[va_tokenId][_pool];

//             if (_votes != 0) {
//                 weights[_va][_pool] -= _votes;
//                 votes[va_tokenId][_pool] -= _votes;
//                 if (_votes > 0) {
//                     _totalWeight += _votes;
//                     _totalWeight += _votes;
//                 } else {
//                     _totalWeight -= _votes;
//                 }
//                 emit Abstained(_va, _tokenId, _votes);
//             }
//         }
//         totalWeight[_va] -= uint256(_totalWeight);
//         usedWeights[_va][_tokenId] = 0;
//         delete poolVote[_va][_tokenId];
//     }

//     function poke(address _va, uint _tokenId, uint _profileId) external {
//         address[] memory _poolVote = poolVote[_va][_tokenId];
//         uint _poolCnt = _poolVote.length;
//         int256[] memory _weights = new int256[](_poolCnt);
//         string memory va_tokenId = string(abi.encodePacked(_va, _profileId, _tokenId));

//         for (uint i = 0; i < _poolCnt; i ++) {
//             _weights[i] = votes[va_tokenId][_poolVote[i]];
//             _vote(_va, _tokenId, _profileId, _poolVote[i], _weights[i]);
//         }
//     }
    
//     function _vote(
//         address _va, 
//         uint _tokenId, 
//         uint _profileId,
//         address _pool, 
//         int256 _weightFactor
//     ) internal {
//         _reset(_va, _tokenId, _profileId);
//         int256 _totalWeight = 0;
//         int256 _usedWeight = 0;
//         int256 _weight = voteOption[_va] == VoteOption.VotingPower ? 
//         int256(va(_va).balanceOfNFT(_tokenId)) :
//         voteOption[_va] == VoteOption.Percentile ? 
//         int256(va(_va).percentiles(_tokenId)) :
//         int256(1);
//         require(IProfile(profile).addressToProfileId(msg.sender) == _profileId && _profileId > 0);
//         (string memory _ssid,) = ISSI(ssi).getSSID(_profileId);
//         if (voteOption[_va] == VoteOption.Unique) {
//             require(keccak256(abi.encodePacked(_ssid)) != keccak256(abi.encodePacked("")));
//         }
//         if (isGauge[_va][_pool]) {
//             int256 _poolWeight;
//             if(_weightFactor > 0) {
//                 _poolWeight = _weight * _weightFactor / _weightFactor;
//             } else {
//                 _poolWeight = -_weight * _weightFactor / _weightFactor;
//             }
//             string memory va_tokenId = string(abi.encodePacked(_va, _profileId, _tokenId));
//             require(votes[va_tokenId][_pool] == 0);
//             require(_poolWeight != 0);

//             poolVote[_va][_tokenId].push(_pool);
            
//             weights[_va][_pool] += _poolWeight;
//             votes[va_tokenId][_pool] += _poolWeight;
            
//             emit Voted(msg.sender, _va, _tokenId, _profileId, _poolWeight, _poolWeight > 0);
//             if (_poolWeight < 0) {
//                 _poolWeight = -_poolWeight;
//             }
//             _usedWeight += _poolWeight;
//             _totalWeight += _poolWeight;
//         }
//         if (_usedWeight > 0) ve(_va).voting(_tokenId);
//         totalWeight[_va] += uint256(_totalWeight);
//         usedWeights[_va][_tokenId] = uint256(_usedWeight);
//     }

//     function vote(address _va, uint tokenId, uint _profileId, address _pool, int256 _weight) external {
//         require(va(_va).isApprovedOrOwner(msg.sender, tokenId));
//         _vote(_va, tokenId, _profileId, _pool, _weight);
//     }

//     function updateMinimumLock(address _vava, uint _minimumLockValue) external {
//         require(IAuth(_vava).isAdmin(msg.sender));
//         minimumLockValue[IVava(_vava)._va()] = _minimumLockValue;
//     }

//     function addVa(address _vava, address _va, uint _period, VoteOption _voteOption) external {
//         require(IAuth(_vava).isAdmin(msg.sender) && _period > 0);
//         period[_va] = _period;
//         voteOption[_va] = _voteOption;
//     }
    
//     function createGauge(
//         address _va, 
//         address _pool, 
//         address _token,
//         uint _tokenId, 
//         uint _amount,
//         string memory _title, 
//         string memory _content
//     ) external {
//         require(period[_va] > 0);
//         require(_amount == 0 || ILenderFactory(lenderFactory).isLender(_pool));
//         require(_pool == msg.sender || IAuth(lenderFactory).isAdmin(msg.sender));
//         require(va(_va).balanceOfNFT(_tokenId) >= minimumLockValue[_va] && va(_va).ownerOf(_tokenId) == msg.sender);
//         if (!isGauge[_va][_pool]) pools[_va].push(_pool);
//         gauges[_va][keccak256(abi.encodePacked(_token, _pool))].amount = _amount;
//         if (gauges[_va][keccak256(abi.encodePacked(_token, _pool))].amount <= _amount) {
//             gauges[_va][keccak256(abi.encodePacked(_token, _pool))].start = block.timestamp;
//         }
//         isGauge[_va][_pool] = true;

//         emit GaugeCreated(
//             msg.sender, 
//             _va, 
//             _pool, 
//             _amount,
//             block.timestamp + period[_va] / period[_va] * period[_va],
//             _title,
//             _content
//         );
//     }

//     function getBalance(address _va, address _token, address _pool) external view returns(uint) {
//         return gauges[_va][keccak256(abi.encodePacked(_token, _pool))].amount;
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

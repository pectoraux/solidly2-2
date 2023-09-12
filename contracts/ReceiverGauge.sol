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
//     function isGauge(address account) external view returns(bool);
//     function attachTokenToGauge(uint _tokenId, address account) external;
//     function detachTokenFromGauge(uint _tokenId, address account) external;
//     function emitDeposit(uint _tokenId, address account, uint amount) external;
//     function emitWithdraw(uint _tokenId, address account, uint amount) external;
//     function distribute(address _gauge) external;
//     function maxWithdrawable() external view returns(uint);
// }

// interface ITrustBounty {
//     function getBalance(uint _bountyId) external view returns(uint _balance);
//     function bountyInfo(uint _bountyId) external view returns(address,address,address,uint,uint,uint,uint,uint);
// }

// interface IGauge {
//     function addToken(address, address) external;
// }

// // File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol

// /**
//  * @dev Library for managing
//  * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
//  * types.
//  *
//  * Sets have the following properties:
//  *
//  * - Elements are added, removed, and checked for existence in constant time
//  * (O(1)).
//  * - Elements are enumerated in O(n). No guarantees are made on the ordering.
//  *
//  * ```
//  * contract Example {
//  *     // Add the library methods
//  *     using EnumerableSet for EnumerableSet.AddressSet;
//  *
//  *     // Declare a set state variable
//  *     EnumerableSet.AddressSet private mySet;
//  * }
//  * ```
//  *
//  * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
//  * and `uint256` (`UintSet`) are supported.
//  */
// library EnumerableSet {
//     // To implement this library for multiple types with as little code
//     // repetition as possible, we write it in terms of a generic Set type with
//     // bytes32 values.
//     // The Set implementation uses private functions, and user-facing
//     // implementations (such as AddressSet) are just wrappers around the
//     // underlying Set.
//     // This means that we can only create new EnumerableSets for types that fit
//     // in bytes32.

//     struct Set {
//         // Storage of set values
//         bytes32[] _values;
//         // Position of the value in the `values` array, plus 1 because index 0
//         // means a value is not in the set.
//         mapping(bytes32 => uint256) _indexes;
//     }

//     /**
//      * @dev Add a value to a set. O(1).
//      *
//      * Returns true if the value was added to the set, that is if it was not
//      * already present.
//      */
//     function _add(Set storage set, bytes32 value) private returns (bool) {
//         if (!_contains(set, value)) {
//             set._values.push(value);
//             // The value is stored at length-1, but we add 1 to all indexes
//             // and use 0 as a sentinel value
//             set._indexes[value] = set._values.length;
//             return true;
//         } else {
//             return false;
//         }
//     }

//     /**
//      * @dev Removes a value from a set. O(1).
//      *
//      * Returns true if the value was removed from the set, that is if it was
//      * present.
//      */
//     function _remove(Set storage set, bytes32 value) private returns (bool) {
//         // We read and store the value's index to prevent multiple reads from the same storage slot
//         uint256 valueIndex = set._indexes[value];

//         if (valueIndex != 0) {
//             // Equivalent to contains(set, value)
//             // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
//             // the array, and then remove the last element (sometimes called as 'swap and pop').
//             // This modifies the order of the array, as noted in {at}.

//             uint256 toDeleteIndex = valueIndex - 1;
//             uint256 lastIndex = set._values.length - 1;

//             if (lastIndex != toDeleteIndex) {
//                 bytes32 lastvalue = set._values[lastIndex];

//                 // Move the last value to the index where the value to delete is
//                 set._values[toDeleteIndex] = lastvalue;
//                 // Update the index for the moved value
//                 set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
//             }

//             // Delete the slot where the moved value was stored
//             set._values.pop();

//             // Delete the index for the deleted slot
//             delete set._indexes[value];

//             return true;
//         } else {
//             return false;
//         }
//     }

//     /**
//      * @dev Returns true if the value is in the set. O(1).
//      */
//     function _contains(Set storage set, bytes32 value) private view returns (bool) {
//         return set._indexes[value] != 0;
//     }

//     /**
//      * @dev Returns the number of values on the set. O(1).
//      */
//     function _length(Set storage set) private view returns (uint256) {
//         return set._values.length;
//     }

//     /**
//      * @dev Returns the value stored at position `index` in the set. O(1).
//      *
//      * Note that there are no guarantees on the ordering of values inside the
//      * array, and it may change when more values are added or removed.
//      *
//      * Requirements:
//      *
//      * - `index` must be strictly less than {length}.
//      */
//     function _at(Set storage set, uint256 index) private view returns (bytes32) {
//         return set._values[index];
//     }

//     // Bytes32Set

//     struct Bytes32Set {
//         Set _inner;
//     }

//     /**
//      * @dev Add a value to a set. O(1).
//      *
//      * Returns true if the value was added to the set, that is if it was not
//      * already present.
//      */
//     function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
//         return _add(set._inner, value);
//     }

//     /**
//      * @dev Removes a value from a set. O(1).
//      *
//      * Returns true if the value was removed from the set, that is if it was
//      * present.
//      */
//     function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
//         return _remove(set._inner, value);
//     }

//     /**
//      * @dev Returns true if the value is in the set. O(1).
//      */
//     function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
//         return _contains(set._inner, value);
//     }

//     /**
//      * @dev Returns the number of values in the set. O(1).
//      */
//     function length(Bytes32Set storage set) internal view returns (uint256) {
//         return _length(set._inner);
//     }

//     /**
//      * @dev Returns the value stored at position `index` in the set. O(1).
//      *
//      * Note that there are no guarantees on the ordering of values inside the
//      * array, and it may change when more values are added or removed.
//      *
//      * Requirements:
//      *
//      * - `index` must be strictly less than {length}.
//      */
//     function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
//         return _at(set._inner, index);
//     }

//     // AddressSet

//     struct AddressSet {
//         Set _inner;
//     }

//     /**
//      * @dev Add a value to a set. O(1).
//      *
//      * Returns true if the value was added to the set, that is if it was not
//      * already present.
//      */
//     function add(AddressSet storage set, address value) internal returns (bool) {
//         return _add(set._inner, bytes32(uint256(uint160(value))));
//     }

//     /**
//      * @dev Removes a value from a set. O(1).
//      *
//      * Returns true if the value was removed from the set, that is if it was
//      * present.
//      */
//     function remove(AddressSet storage set, address value) internal returns (bool) {
//         return _remove(set._inner, bytes32(uint256(uint160(value))));
//     }

//     /**
//      * @dev Returns true if the value is in the set. O(1).
//      */
//     function contains(AddressSet storage set, address value) internal view returns (bool) {
//         return _contains(set._inner, bytes32(uint256(uint160(value))));
//     }

//     /**
//      * @dev Returns the number of values in the set. O(1).
//      */
//     function length(AddressSet storage set) internal view returns (uint256) {
//         return _length(set._inner);
//     }

//     /**
//      * @dev Returns the value stored at position `index` in the set. O(1).
//      *
//      * Note that there are no guarantees on the ordering of values inside the
//      * array, and it may change when more values are added or removed.
//      *
//      * Requirements:
//      *
//      * - `index` must be strictly less than {length}.
//      */
//     function at(AddressSet storage set, uint256 index) internal view returns (address) {
//         return address(uint160(uint256(_at(set._inner, index))));
//     }

//     // UintSet

//     struct UintSet {
//         Set _inner;
//     }

//     /**
//      * @dev Add a value to a set. O(1).
//      *
//      * Returns true if the value was added to the set, that is if it was not
//      * already present.
//      */
//     function add(UintSet storage set, uint256 value) internal returns (bool) {
//         return _add(set._inner, bytes32(value));
//     }

//     /**
//      * @dev Removes a value from a set. O(1).
//      *
//      * Returns true if the value was removed from the set, that is if it was
//      * present.
//      */
//     function remove(UintSet storage set, uint256 value) internal returns (bool) {
//         return _remove(set._inner, bytes32(value));
//     }

//     /**
//      * @dev Returns true if the value is in the set. O(1).
//      */
//     function contains(UintSet storage set, uint256 value) internal view returns (bool) {
//         return _contains(set._inner, bytes32(value));
//     }

//     /**
//      * @dev Returns the number of values on the set. O(1).
//      */
//     function length(UintSet storage set) internal view returns (uint256) {
//         return _length(set._inner);
//     }

//     /**
//      * @dev Returns the value stored at position `index` in the set. O(1).
//      *
//      * Note that there are no guarantees on the ordering of values inside the
//      * array, and it may change when more values are added or removed.
//      *
//      * Requirements:
//      *
//      * - `index` must be strictly less than {length}.
//      */
//     function at(UintSet storage set, uint256 index) internal view returns (uint256) {
//         return uint256(_at(set._inner, index));
//     }
// }

// // Gauges are used to incentivize pools, they emit reward tokens over 7 days for staked LP tokens
// contract Gauge {
//     using EnumerableSet for EnumerableSet.AddressSet;

//     address public immutable factory;
//     address public immutable trustBounty;


//     uint internal constant week = 86400 * 7; // allows minting once per week (reset every Thursday 00:00 UTC)
//     uint public active_period;

//     mapping(address => uint) public balanceOf;
//     address public dev;
//     EnumerableSet.AddressSet private tokens;
//     mapping(address => uint) public bountyIds;
//     mapping(address => address) public tokenToVoter;

//     event Deposit(address indexed from, address token, uint amount);
//     event Withdraw(address indexed from, address token, uint amount);
//     event NotifyReward(address indexed from, address indexed reward, uint amount);
//     event ClaimFees(address indexed from, uint claimed0, uint claimed1);
//     event ClaimRewards(address indexed from, address indexed reward, uint amount);

//     constructor(address _dev, address _trustBounty, address _ve, address _voter) {
//         dev = _dev;
//         tokens.add(ve(_ve).token());
//         tokenToVoter[ve(_ve).token()] = _voter;
//         trustBounty = _trustBounty;
//         factory = msg.sender;
//     }

//     // simple re-entrancy check
//     uint internal _unlocked = 1;
//     modifier lock() {
//         require(_unlocked == 1);
//         _unlocked = 2;
//         _;
//         _unlocked = 1;
//     }

//     function updateDev(address _dev) external {
//         require(msg.sender == dev);
//         dev = _dev;
//     }

//     function addToken(address _ve, address _voter) external {
//         require(msg.sender == factory);
//         tokens.add(ve(_ve).token());
//         tokenToVoter[ve(_ve).token()] = _voter;
//     }

//     function updateBounty(uint _bountyId) external {
//         (address owner,address token,address claimableBy,,,,,) = ITrustBounty(trustBounty).bountyInfo(_bountyId);
//         require(owner == msg.sender && msg.sender == dev && claimableBy == address(this));
//         require(tokens.contains(token));
//         bountyIds[token] = _bountyId;
//     }

//     function depositAll(address _token) external {
//         deposit(_token, erc20(_token).balanceOf(msg.sender));
//     }

//     function deposit(address _token, uint amount) public lock {
//         require(amount > 0);
//         require(tokens.contains(_token));
        
//         _safeTransferFrom(_token, msg.sender, address(this), amount);
        
//         emit Deposit(msg.sender, _token, amount);
//     }

//     function withdrawAll() external {
//         for (uint i = 0; i < tokens.length(); i++) {
//             uint _amount;
//             if (bountyIds[tokens.at(i)] > 0) {
//                 uint _limit = ITrustBounty(trustBounty).getBalance(
//                     bountyIds[tokens.at(i)]
//                 );
//                 (,,,,,uint endTime,,) = ITrustBounty(trustBounty).bountyInfo(
//                     bountyIds[tokens.at(i)]
//                 );
//                 require(endTime > active_period);
//                 _amount = _limit - balanceOf[tokens.at(i)];
//             } else {
//                 _amount = Voter(tokenToVoter[tokens.at(i)]).maxWithdrawable() - balanceOf[tokens.at(i)];
//             }
//             withdraw(tokens.at(i), _amount);
//         }
//     }
    
//     function totalSupply(address _token) external view returns(uint supply) {
//         supply = erc20(_token).balanceOf(address(this));
//     }

//     function withdraw(address _token, uint amount) public lock {
//         require(amount > 0);
//         _updateBalances();
//         balanceOf[_token] += amount;
//         _safeTransfer(_token, msg.sender, amount);

//         emit Withdraw(msg.sender, _token, amount);
//     }

//     function _updateBalances() internal {
//         if (block.timestamp >= active_period) {
//             for (uint i = 0; i < tokens.length(); i++) {
//                 // only reinitialize tokens with a bounty
//                 if (bountyIds[tokens.at(i)] > 0) balanceOf[tokens.at(i)] = 0;
//             }
//             active_period = block.timestamp / week * week;
//         }
//     }

//     function getReward(address account, address[] memory tokens) external lock {
//         _unlocked = 1;
//         Voter(msg.sender).distribute(address(this));
//         _unlocked = 2;
//     }

//     function notifyRewardAmount(address token, uint amount) external lock {
//         // require(voters[msg.sender]);
//         require(amount > 0);

//         _safeTransferFrom(token, msg.sender, address(this), amount);

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

// contract BaseV1GaugeFactory {
//     address public last_gauge;
//     address public immutable trustBounty;
//     mapping(address => bool) public voters;
//     mapping(address => address) public hasGauge;
//     address dev;
    
//     constructor(address _trustBounty) {
//         dev = msg.sender;
//         trustBounty = _trustBounty;
//     }

//     function updateVoter(address[] memory _voters, bool _add) external {
//         require(msg.sender == dev);
//         for (uint i = 0; i < _voters.length; i++) {
//             voters[_voters[i]] = _add;
//         }
//     }

//     function createGauge(address _pool, address _bribe, address _ve) external returns (address) {
//         require(voters[msg.sender]);
//         if (hasGauge[_pool] != address(0x0)) {
//             IGauge(hasGauge[_pool]).addToken(_ve, msg.sender);
//         } else {
//             last_gauge = address(new Gauge(_pool, trustBounty, _ve, msg.sender));
//             return last_gauge;
//         }
//     }

//     function updateDev(address _dev) external {
//         require(msg.sender == dev);
//         dev = _dev;
//     }
// }

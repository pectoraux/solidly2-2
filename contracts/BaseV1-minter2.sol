// // SPDX-License-Identifier: GPL-3.0-or-later
// pragma solidity 0.8.17;

// interface ve {
//     function token() external view returns (address);
//     function totalSupply() external view returns (uint);
//     function create_lock_for(uint, uint, address) external returns (uint);
//     function transferFrom(address, address, uint) external;
// }

// interface underlying {
//     function approve(address spender, uint value) external returns (bool);
//     function mint(address, uint) external;
//     function burn(address, uint) external returns (bool);
//     function totalSupply() external view returns (uint);
//     function balanceOf(address) external view returns (uint);
//     function transfer(address, uint) external returns (bool);
// }

// interface voter {
//     function totalWeight() external view returns(uint);
//     function notifyRewardAmount(uint amount) external;
// }

// interface ve_dist {
//     function checkpoint_token() external;
//     function checkpoint_total_supply() external;
// }

// library Math {
//     function max(uint a, uint b) internal pure returns (uint) {
//         return a >= b ? a : b;
//     }
//     function min(uint a, uint b) internal pure returns (uint) {
//         return a < b ? a : b;
//     }
//     function sqrt(uint y) internal pure returns (uint z) {
//         if (y > 3) {
//             z = y;
//             uint x = y / 2 + 1;
//             while (x < z) {
//                 z = x;
//                 x = (y / x + x) / 2;
//             }
//         } else if (y != 0) {
//             z = 1;
//         }
//     }
//     function cbrt(uint256 n) internal pure returns (uint256) { unchecked {
//         uint256 x = 0;
//         for (uint256 y = 1 << 255; y > 0; y >>= 3) {
//             x <<= 1;
//             uint256 z = 3 * x * (x + 1) + 1;
//             if (n / y >= z) {
//                 n -= y * z;
//                 x += 1;
//             }
//         }
//         return x;
//     }}
// }

// /**
//  * @dev Provides information about the current execution context, including the
//  * sender of the transaction and its data. While these are generally available
//  * via msg.sender and msg.data, they should not be accessed in such a direct
//  * manner, since when dealing with meta-transactions the account sending and
//  * paying for execution may not be the actual sender (as far as an application
//  * is concerned).
//  *
//  * This contract is only required for intermediate, library-like contracts.
//  */
// abstract contract Context {
//     function _msgSender() internal view virtual returns (address) {
//         return msg.sender;
//     }

//     function _msgData() internal view virtual returns (bytes calldata) {
//         return msg.data;
//     }
// }

// /**
//  * @dev Contract module which provides a basic access control mechanism, where
//  * there is an account (an owner) that can be granted exclusive access to
//  * specific functions.
//  *
//  * By default, the owner account will be the one that deploys the contract. This
//  * can later be changed with {transferOwnership}.
//  *
//  * This module is used through inheritance. It will make available the modifier
//  * `onlyOwner`, which can be applied to your functions to restrict their use to
//  * the owner.
//  */
// abstract contract Ownable is Context {
//     address private _owner;

//     event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

//     /**
//      * @dev Initializes the contract setting the deployer as the initial owner.
//      */
//     constructor() {
//         _transferOwnership(_msgSender());
//     }

//     /**
//      * @dev Returns the address of the current owner.
//      */
//     function owner() public view virtual returns (address) {
//         return _owner;
//     }

//     /**
//      * @dev Throws if called by any account other than the owner.
//      */
//     modifier onlyOwner() {
//         require(owner() == _msgSender(), "Ownable: caller is not the owner");
//         _;
//     }

//     /**
//      * @dev Leaves the contract without owner. It will not be possible to call
//      * `onlyOwner` functions anymore. Can only be called by the current owner.
//      *
//      * NOTE: Renouncing ownership will leave the contract without an owner,
//      * thereby removing any functionality that is only available to the owner.
//      */
//     function renounceOwnership() public virtual onlyOwner {
//         _transferOwnership(address(0));
//     }

//     /**
//      * @dev Transfers ownership of the contract to a new account (`newOwner`).
//      * Can only be called by the current owner.
//      */
//     function transferOwnership(address newOwner) public virtual onlyOwner {
//         require(newOwner != address(0), "Ownable: new owner is the zero address");
//         _transferOwnership(newOwner);
//     }

//     /**
//      * @dev Transfers ownership of the contract to a new account (`newOwner`).
//      * Internal function without access restriction.
//      */
//     function _transferOwnership(address newOwner) internal virtual {
//         address oldOwner = _owner;
//         _owner = newOwner;
//         emit OwnershipTransferred(oldOwner, newOwner);
//     }
// }

// /**
//  * @title Roles
//  * @dev Library for managing addresses assigned to a Role.
//  */
// library Roles {
//     struct Role {
//         mapping (address => bool) bearer;
//     }

//     /**
//      * @dev give an account access to this role
//      */
//     function add(Role storage role, address account) internal {
//         require(account != address(0));
//         require(!has(role, account));

//         role.bearer[account] = true;
//     }

//     /**
//      * @dev remove an account's access to this role
//      */
//     function remove(Role storage role, address account) internal {
//         require(account != address(0));
//         require(has(role, account));

//         role.bearer[account] = false;
//     }

//     /**
//      * @dev check if an account has this role
//      * @return bool
//      */
//     function has(Role storage role, address account) internal view returns (bool) {
//         require(account != address(0));
//         return role.bearer[account];
//     }
// }

// contract PauserRole {
//     using Roles for Roles.Role;

//     event PauserAdded(address indexed account);
//     event PauserRemoved(address indexed account);

//     Roles.Role private _pausers;

//     constructor () {
//         _addPauser(msg.sender);
//     }

//     modifier onlyPauser() {
//         require(isPauser(msg.sender));
//         _;
//     }

//     function isPauser(address account) public view returns (bool) {
//         return _pausers.has(account);
//     }

//     function addPauser(address account) public onlyPauser {
//         _addPauser(account);
//     }

//     function renouncePauser() public {
//         _removePauser(msg.sender);
//     }

//     function _addPauser(address account) internal {
//         _pausers.add(account);
//         emit PauserAdded(account);
//     }

//     function _removePauser(address account) internal {
//         _pausers.remove(account);
//         emit PauserRemoved(account);
//     }
// }

// // File: contracts/NFTfi/v1/openzeppelin/Pausable.sol
// /**
//  * @title Pausable
//  * @dev Base contract which allows children to implement an emergency stop mechanism.
//  */
// contract Pausable is PauserRole {
//     event Paused(address account);
//     event Unpaused(address account);

//     bool private _paused;

//     constructor () {
//         _paused = false;
//     }

//     /**
//      * @return true if the contract is paused, false otherwise.
//      */
//     function paused() public view returns (bool) {
//         return _paused;
//     }

//     /**
//      * @dev Modifier to make a function callable only when the contract is not paused.
//      */
//     modifier whenNotPaused() {
//         require(!_paused);
//         _;
//     }

//     /**
//      * @dev Modifier to make a function callable only when the contract is paused.
//      */
//     modifier whenPaused() {
//         require(_paused);
//         _;
//     }

//     /**
//      * @dev called by the owner to pause, triggers stopped state
//      */
//     function pause() public onlyPauser whenNotPaused {
//         _paused = true;
//         emit Paused(msg.sender);
//     }

//     /**
//      * @dev called by the owner to unpause, returns to normal state
//      */
//     function unpause() public onlyPauser whenPaused {
//         _paused = false;
//         emit Unpaused(msg.sender);
//     }
// }

// /**
//  * @title Helps contracts guard against reentrancy attacks.
//  * @author Remco Bloemen <remco@2π.com>, Eenae <alexey@mixbytes.io>
//  * @dev If you mark a function `nonReentrant`, you should also
//  * mark it `external`.
//  */
// contract ReentrancyGuard {
//     /// @dev counter to allow mutex lock with only one SSTORE operation
//     uint256 private _guardCounter;

//     constructor() {
//         // The counter starts at one to prevent changing it from zero to a non-zero
//         // value, which is a more expensive operation.
//         _guardCounter = 1;
//     }

//     /**
//      * @dev Prevents a contract from calling itself, directly or indirectly.
//      * Calling a `nonReentrant` function from another `nonReentrant`
//      * function is not supported. It is possible to prevent this from happening
//      * by making the `nonReentrant` function external, and make it call a
//      * `private` function that does the actual work.
//      */
//     modifier nonReentrant() {
//         _guardCounter += 1;
//         uint256 localCounter = _guardCounter;
//         _;
//         require(localCounter == _guardCounter);
//     }
// }

// // @title Admin contract for NFT. Holds owner-only functions to adjust
// //        contract-wide fees, parameters, etc.
// // @author smartcontractdev.eth, creator of wrappedkitties.eth, cwhelper.eth, and
// //         kittybounties.eth
// contract Admin is Ownable, Pausable, ReentrancyGuard {

//     /* ****** */
//     /* EVENTS */
//     /* ****** */

//     // @notice This event is fired whenever the admins change the percent of
//     //         interest rates earned that they charge as a fee. Note that
//     //         newAdminFee can never exceed 10,000, since the fee is measured
//     //         in basis points.
//     // @param  newAdminFee - The new admin fee measured in basis points. This
//     //         is a percent of the interest paid upon a loan's completion that
//     //         go to the contract admins.
//     event AdminFeeUpdated(
//         uint256 newAdminFee
//     );

//     /* ******* */
//     /* STORAGE */
//     /* ******* */

//     // @notice A mapping from from an ERC20 currency address to whether that
//     //         currency is whitelisted to be used by this contract. Note that
//     //         NFTfi only supports loans that use ERC20 currencies that are
//     //         whitelisted, all other calls to beginLoan() will fail.
//     mapping (address => bool) public erc20CurrencyIsWhitelisted;

//     // @notice A mapping from from an NFT contract's address to whether that
//     //         contract is whitelisted to be used by this contract. Note that
//     //         NFTfi only supports loans that use NFT collateral from contracts
//     //         that are whitelisted, all other calls to beginLoan() will fail.
//     mapping (address => bool) public nftContractIsWhitelisted;

//     // @notice The maximum duration of any loan started on this platform,
//     //         measured in seconds. This is both a sanity-check for borrowers
//     //         and an upper limit on how long admins will have to support v1 of
//     //         this contract if they eventually deprecate it, as well as a check
//     //         to ensure that the loan duration never exceeds the space alotted
//     //         for it in the loan struct.
//     uint256 public maximumLoanDuration = 53 weeks;

//     // @notice The maximum number of active loans allowed on this platform.
//     //         This parameter is used to limit the risk that NFTfi faces while
//     //         the project is first getting started.
//     uint256 public maximumNumberOfActiveLoans = 100;

//     // @notice The percentage of interest earned by lenders on this platform
//     //         that is taken by the contract admin's as a fee, measured in
//     //         basis points (hundreths of a percent).
//     uint256 public adminFeeInBasisPoints = 25;

//     /* *********** */
//     /* CONSTRUCTOR */
//     /* *********** */

//     constructor() {
//         // Whitelist mainnet WETH
//         erc20CurrencyIsWhitelisted[address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)] = true;

//         // Whitelist mainnet DAI
//         erc20CurrencyIsWhitelisted[address(0x6B175474E89094C44Da98b954EedeAC495271d0F)] = true;

//         // Whitelist mainnet CryptoKitties
//         nftContractIsWhitelisted[address(0x06012c8cf97BEaD5deAe237070F9587f8E7A266d)] = true;
//     }

//     /* ********* */
//     /* FUNCTIONS */
//     /* ********* */

//     /**
//      * @dev Gets the token name
//      * @return string representing the token name
//      */
//     function name() external pure returns (string memory) {
//         return "NFTfi Promissory Note";
//     }

//     /**
//      * @dev Gets the token symbol
//      * @return string representing the token symbol
//      */
//     function symbol() external pure returns (string memory) {
//         return "NFTfi";
//     }

//     // @notice This function can be called by admins to change the whitelist
//     //         status of an ERC20 currency. This includes both adding an ERC20
//     //         currency to the whitelist and removing it.
//     // @param  _erc20Currency - The address of the ERC20 currency whose whitelist
//     //         status changed.
//     // @param  _setAsWhitelisted - The new status of whether the currency is
//     //         whitelisted or not.
//     function whitelistERC20Currency(address _erc20Currency, bool _setAsWhitelisted) external onlyOwner {
//         erc20CurrencyIsWhitelisted[_erc20Currency] = _setAsWhitelisted;
//     }

//     // @notice This function can be called by admins to change the whitelist
//     //         status of an NFT contract. This includes both adding an NFT
//     //         contract to the whitelist and removing it.
//     // @param  _nftContract - The address of the NFT contract whose whitelist
//     //         status changed.
//     // @param  _setAsWhitelisted - The new status of whether the contract is
//     //         whitelisted or not.
//     function whitelistNFTContract(address _nftContract, bool _setAsWhitelisted) external onlyOwner {
//         nftContractIsWhitelisted[_nftContract] = _setAsWhitelisted;
//     }

//     // @notice This function can be called by admins to change the
//     //         maximumLoanDuration. Note that they can never change
//     //         maximumLoanDuration to be greater than UINT32_MAX, since that's
//     //         the maximum space alotted for the duration in the loan struct.
//     // @param  _newMaximumLoanDuration - The new maximum loan duration, measured
//     //         in seconds.
//     function updateMaximumLoanDuration(uint256 _newMaximumLoanDuration) external onlyOwner {
//         require(_newMaximumLoanDuration <= uint256(~uint32(0)), 'loan duration cannot exceed space alotted in struct');
//         maximumLoanDuration = _newMaximumLoanDuration;
//     }

//     // @notice This function can be called by admins to change the
//     //         maximumNumberOfActiveLoans. 
//     // @param  _newMaximumNumberOfActiveLoans - The new maximum number of
//     //         active loans, used to limit the risk that NFTfi faces while the
//     //         project is first getting started.
//     function updateMaximumNumberOfActiveLoans(uint256 _newMaximumNumberOfActiveLoans) external onlyOwner {
//         maximumNumberOfActiveLoans = _newMaximumNumberOfActiveLoans;
//     }

//     // @notice This function can be called by admins to change the percent of
//     //         interest rates earned that they charge as a fee. Note that
//     //         newAdminFee can never exceed 10,000, since the fee is measured
//     //         in basis points.
//     // @param  _newAdminFeeInBasisPoints - The new admin fee measured in basis points. This
//     //         is a percent of the interest paid upon a loan's completion that
//     //         go to the contract admins.
//     function updateAdminFee(uint256 _newAdminFeeInBasisPoints) external onlyOwner {
//         require(_newAdminFeeInBasisPoints <= 10000, 'By definition, basis points cannot exceed 10000');
//         adminFeeInBasisPoints = _newAdminFeeInBasisPoints;
//         emit AdminFeeUpdated(_newAdminFeeInBasisPoints);
//     }
// }

// // codifies the minting rules as per ve(3,3), abstracted from the token to support any token that allows minting

// contract BaseV1Minter2 is Admin {

//     uint internal constant week = 86400 * 7; // allows minting once per week (reset every Thursday 00:00 UTC)
//     uint internal constant emission = 98;
//     uint internal constant tail_emission = 2;
//     uint internal constant target_base = 100; // 2% per week target emission
//     uint internal constant tail_base = 1000; // 0.2% per week target emission
//     underlying public immutable _token;
//     voter public immutable _businesses;
//     voter public immutable _referrals;
//     voter public immutable _contributors;
//     voter public immutable _accelerator;
//     address public immutable _team;
//     ve public immutable _ve;
//     ve_dist public immutable _ve_dist;
//     uint public weekly = 20000000e18;
//     uint public active_period;
//     uint internal constant lock = 86400 * 7 * 52 * 4;

//     uint public teamPercent = 100; // 1 percent
//     bool public custom = false;
//     uint public referralsPercent;
//     uint public businessesPercent;
//     uint public acceleratorPercent;
//     uint public contributorsPercent;

//     uint public weeklyBusinessEmission;
//     uint public weeklyReferralEmission;
//     uint public weeklyContributorEmission;
//     uint public weeklyAcceleratorEmission;

//     // minimum amount of votes above which 
//     // a protocol can start receiving emissions
//     uint MIN_VOTES_4_EMISSIONS = 5000;
    
//     event Mint(address indexed sender, uint weekly, uint circulating_supply, uint circulating_emission);

//     constructor(
//         address __businesses, // the voting & distribution system
//         address __accelerator, // the voting & distribution system
//         address __contributors, // the voting & distribution system
//         address __referrals, // the voting & distribution system
//         address  __ve, // the ve(3,3) system that will be locked into
//         address __ve_dist // the distribution system that ensures users aren't diluted
//     ) {
//         _token = underlying(ve(__ve).token());
//         _businesses = voter(__businesses);
//         _accelerator = voter(__accelerator);
//         _contributors = voter(__contributors);
//         _referrals = voter(__referrals);
//         _team = msg.sender;
//         _ve = ve(__ve);
//         _ve_dist = ve_dist(__ve_dist);
//         // active_period = (block.timestamp + (2*week)) / week * week;
//         active_period = (block.timestamp + week) / week * week;
//     }

//     function updateTeamPercent(
//         bool _custom,
//         uint _percent1, 
//         uint _percent2, 
//         uint _percent3,
//         uint _percent4,
//         uint _percent5
//     ) public onlyOwner {
//         custom = _custom;
//         if(_custom == true) {
//             require(
//                 _percent2+_percent3+_percent4+_percent5 == 10000, 
//                 "Invalid percentages"
//             );
//             teamPercent = _percent1;
//             referralsPercent = _percent2;
//             businessesPercent = _percent3;
//             acceleratorPercent = _percent4;
//             contributorsPercent = _percent5;
//         }
//     }

//     function getPercentage(voter _voter) internal view returns(uint) {
//         if (_voter.totalWeight() == 0) return 0;
//         return _voter.totalWeight() * 10000 / (_referrals.totalWeight() + _businesses.totalWeight() + _accelerator.totalWeight() + _contributors.totalWeight());
//     }

//     function updatePercentages() public {
//         if(!custom) {
//             referralsPercent = getPercentage(_referrals);
//             businessesPercent = getPercentage(_businesses);
//             acceleratorPercent = getPercentage(_accelerator);
//             contributorsPercent = getPercentage(_contributors);
//         }
//     }

//     // calculate circulating supply as total token supply - locked supply
//     function circulating_supply() public view returns (uint) {
//         return _token.totalSupply() - _ve.totalSupply();
//     }

//     // emission calculation is 2% of available supply to mint adjusted by circulating / total supply
//     function calculate_emission() public view returns (uint) {
//         return weekly * emission * circulating_supply() / target_base / _token.totalSupply();
//     }

//     // weekly emission takes the max of calculated (aka target) emission versus circulating tail end emission
//     function weekly_emission() public view returns (uint) {
//         return Math.max(calculate_emission(), circulating_emission());
//     }

//     // calculates tail end (infinity) emissions as 0.2% of total supply
//     function circulating_emission() public view returns (uint) {
//         return circulating_supply() * tail_emission / tail_base;
//     }

//     // calculate inflation and adjust ve balances accordingly
//     function calculate_growth(uint _minted) public view returns (uint) {
//         return _ve.totalSupply() * _minted / _token.totalSupply();
//     }

//     function updateMinVotes4Emission(uint newMin) external onlyOwner {
//         MIN_VOTES_4_EMISSIONS = newMin;
//     }

//     // update period can only be called once per cycle (1 week)
//     function update_period() external returns (uint) {
//         uint _period = active_period;
//         if (block.timestamp >= _period + week) { // only trigger if new week
//             _period = block.timestamp / week * week;
//             active_period = _period;
//             weekly = weekly_emission();

//             uint _growth = calculate_growth(weekly);
//             uint _required = _growth + weekly;
//             uint _balanceOf = _token.balanceOf(address(this));
//             if (_balanceOf < _required) {
//                 _token.mint(address(this), _required-_balanceOf);
//             }

//             if (_growth > 0) require(_token.transfer(address(_ve_dist), _growth));
//             _ve_dist.checkpoint_token(); // checkpoint token balance that was just minted in ve_dist
//             _ve_dist.checkpoint_total_supply(); // checkpoint supply
            
//             // send team's percentage
//             uint _teamFee = weekly * teamPercent / 10000;
//             require(_token.transfer(address(_team), _teamFee));
//             uint _weeklyLessTeam = weekly - _teamFee;
//             // send other percentages
//             updatePercentages();
            
//             if (_businesses.totalWeight() > MIN_VOTES_4_EMISSIONS) {
//                 //businesses
//                 weeklyBusinessEmission = _weeklyLessTeam * businessesPercent / 10000;
//                 _token.approve(address(_businesses), weeklyBusinessEmission);
//                 _businesses.notifyRewardAmount(weeklyBusinessEmission);
//             }
//             if (_referrals.totalWeight() > MIN_VOTES_4_EMISSIONS) {
//                 //referrals
//                 weeklyReferralEmission = _weeklyLessTeam * referralsPercent / 10000;
//                 _token.approve(address(_referrals), weeklyReferralEmission);
//                 _referrals.notifyRewardAmount(weeklyReferralEmission);
//             }
//             if (_contributors.totalWeight() > MIN_VOTES_4_EMISSIONS) {
//                 //contributors
//                 weeklyContributorEmission = _weeklyLessTeam * contributorsPercent / 10000;
//                 _token.approve(address(_contributors), weeklyContributorEmission);
//                 _contributors.notifyRewardAmount(weeklyContributorEmission);
//             }
//             if (_accelerator.totalWeight() > MIN_VOTES_4_EMISSIONS) {
//                 //accelerator
//                 weeklyAcceleratorEmission = _weeklyLessTeam * acceleratorPercent / 10000;
//                 _token.approve(address(_accelerator), weeklyAcceleratorEmission);
//                 _accelerator.notifyRewardAmount(weeklyAcceleratorEmission);
//             }
            
//             // require(_token.burn(address(this), _token.balanceOf(address(this))));

//             emit Mint(msg.sender, weekly, circulating_supply(), circulating_emission());
//         }
//         return _period;
//     }
// }

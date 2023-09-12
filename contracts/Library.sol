// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

uint256 constant MAX_VAL = type(uint256).max;
enum Source {
    Local,
    External
}
enum WorldType {
    undefined,
    RPWorld,
    BPWorld,
    GreenWorld
}
enum CollateralStatus {
    OverCollateralized,
    UnderCollateralized
}
enum ProofType {
    shareProof,
    identityProof
}
struct Divisor {
    uint factor;
    uint period;
    uint cap;
}
struct Treasury {
    uint256 priceTicket;
    uint256 fee;
    bool useNFTicket;
    uint256 referrerFee;
}
struct ARPInfo {
    address token;
    uint bountyId;
    uint profileId;
    uint tokenId;
    uint amountPayable;
    uint amountReceivable;
    uint paidPayable;
    uint paidReceivable;
    uint periodPayable;
    uint periodReceivable;
    uint startPayable;
    uint startReceivable;
}
struct BILLInfo {
    address token;
    uint version;
    uint bountyId;
    uint profileId;
    uint credit;
    uint debit;
    uint startPayable;
    uint startReceivable;
    uint periodPayable;
    uint periodReceivable;
    uint creditFactor;
    uint debitFactor;
}
struct Ticket {
    uint number;
    address owner;
}
enum LotteryStatus {
    Pending,
    Open,
    Close,
    Claimable
}
enum BettingStatus {
    Open,
    Close,
    Claimable
}
struct Lottery {
    LotteryStatus status;
    uint256 startTime;
    uint256 endTime;
    uint256 endAmount;
    uint256 discountDivisor;
    uint256[6] rewardsBreakdown; // 0: 1 matching number // 5: 6 matching numbers
    uint256[6] countWinnersPerBracket;
    uint256 firstTicketId;
    uint256 lockDuration;
    uint finalNumber;
    address valuepool;
    address owner;
    Treasury treasury;
}
struct MintValues {
    address minter;
    uint tokenId;
    NFTYPE nftype;
}
struct CreditReport {
    uint lateSeconds;
    uint lateValue;
}
struct Credit {
    address token;
    address checker;
    address destination;
    uint discount;
    uint collectionId;
    string item;
}
struct ProfileInfo {
    string ssid;
    string name;
    uint ssidAuditorProfileId;
    uint createdAt;
    uint activePeriod;
    uint paidPayable;
    uint collectionId;
    CreditReport black;
    CreditReport brown;
    CreditReport silver;
    CreditReport gold;
}
struct SSIData {
    uint senderProfileId;
    uint receiverProfileId;
    uint auditorProfileId;
    uint deadline;
    string question;
    string answer;
    ProofType proofType;
}
struct TicketInfo {
    address token;
    address lender;
    uint merchant;
    uint timer;
    uint date;
    uint price;
    uint timeEstimate;
    bool active;
    bool transferrable;
    string item;
    string superChatOwner;
    string superChatResponse;
    Source source;
}
struct Collection {
    Status status; // status of the collection
    address owner;
    address baseToken;
    uint256 tradingFee; // trading fee (100 = 1%, 500 = 5%, 5 = 0.05%)
    uint256 referrerFee; // creator fee (100 = 1%, 500 = 5%, 5 = 0.05%)
    uint256 minBounty;
    uint256 userMinBounty;
    uint256 badgeId;
    uint256 recurringBounty;
    bool requestUserRegistration;
    bool requestPartnerRegistration;
    IdentityProof userIdentityProof;
    IdentityProof partnerIdentityProof;
}
struct CardInfo {
    address owner;
    address token;
    uint bountyId;
    uint tokenId;
    uint amountPayable;
    uint paidPayable;
    uint periodPayable;
    uint startPayable;
}
enum RampStatus {
    Pending,
    Open,
    Close
}
struct RampInfo {
    RampStatus status;
    uint tokenId;
    uint bountyId;
    uint profileId;
    uint badgeId;
    uint minted;
    uint burnt;
    uint salePrice;
    uint maxParters;
    uint cap;
}
enum DepositType {
    DEPOSIT_FOR_TYPE,
    CREATE_LOCK_TYPE,
    INCREASE_LOCK_AMOUNT,
    INCREASE_LOCK_AMOUNT_AND_UNLOCK_TIME,
    INCREASE_UNLOCK_TIME,
    MERGE_TYPE
}
enum NFTYPE {
    not,
    erc721,
    erc1155
}
enum Status {
    Pending,
    Open,
    Close
}
enum COLOR {
    BLACK,
    BROWN,
    SILVER,
    GOLD
}
enum CONTENT {
    I,
    II,
    III,
    IV,
    E
}
struct Referral {
    uint collectionId;
    uint referrerFee;
    uint bountyId;
}
struct Discount {
    uint256 cursor;
    uint256 size;
    uint256 perct;
    uint256 lowerThreshold;
    uint256 upperThreshold;
    uint256 limit;
}
struct IdentityProof {
    string requiredIndentity;
    COLOR minIDBadgeColor;
    string valueName;
    uint maxUse;
    bool dataKeeperOnly;
    bool onlyTrustWorthyAuditors;
}
struct TokenInfo {
    address tFIAT;
    address ve;
    bool usetFIAT;
    bool requireUpfrontPayment;
}
struct PriceReductor {
    Status discountStatus;   
    uint discountStart;   
    Status cashbackStatus;   
    uint cashbackStart;   
    bool cashNotCredit;
    bool checkItemOnly;
    bool checkIdentityCode;
    Discount discountNumbers;
    Discount discountCost;    
    Discount cashbackNumbers;
    Discount cashbackCost;
}
struct Ask {
    address seller;
    uint256 price; // price of the token
    address lastBidder;
    uint256 bidDuration;
    uint256 lastBidTime;
    int256 minBidIncrementPercentage;
    uint256 rsrcTokenId;
    bool transferrable;
    PriceReductor priceReductor;
    IdentityProof identityProof;
    uint maxSupply;
    uint dropinTimer;
    TokenInfo tokenInfo;
}
struct Option {
    uint id;
    uint min;
    uint max;
    uint unitPrice;
    string category;
    string element;
    string traitType;
    string value;
    string currency;
}
struct PaywallOption {
    uint id;
    uint min;
    uint max;
    uint value;
    uint unitPrice;
    string category;
    string element;
    string traitType;
    string currency;
}
struct Note {
    uint due;
    uint nextDue;
    uint tokenId;
}
struct Bank {
    uint startPayable;
    uint startReceivable;
    uint amountPayable;
    uint amountReceivable;
    uint periodPayable;
    uint periodReceivable;
    uint paidPayable;
    uint paidReceivable;
    uint gasPercent;
    uint waitingPeriod;
    uint stakeRequired;
}
struct MetaData {
    address source;
    address collection;
    address referrer;
    uint userTokenId;
    uint identityTokenId;
    uint[] options;
}
enum StakeStatusEnum {
    AtPeace,
    AtWar
}
struct StakeStatus {
    StakeStatusEnum status;
    uint endTime;
    uint winnerId;
    uint loserId;
}
struct Stake {
    address ve;
    address token;
    string tokenId;
    address owner;
    Bank bank;
    uint profileId;
    uint bountyId;
    uint parentStakeId;
    bool profileRequired;
    bool bountyRequired;
    MetaData metadata;
    AGREEMENT ownerAgreement;
}
enum AGREEMENT{
    undefined,
    pending,
    good,
    notgood,
    disagreement
}
enum ApplicationStatus {
    Pending,
    Accepted,
    Rejected
}
struct Application {
    ApplicationStatus status;
    uint stakeId;
    uint deadline;
}
// reverts on overflow
function safeAdd(uint256 x, uint256 y) pure returns (uint256) {
    return x + y;
}

// does not revert on overflow
function unsafeAdd(uint256 x, uint256 y) pure returns (uint256) { unchecked {
    return x + y;
}}

// does not revert on overflow
function unsafeSub(uint256 x, uint256 y) pure returns (uint256) { unchecked {
    return x - y;
}}

// does not revert on overflow
function unsafeMul(uint256 x, uint256 y) pure returns (uint256) { unchecked {
    return x * y;
}}

// does not overflow
function mulModMax(uint256 x, uint256 y) pure returns (uint256) { unchecked {
    return mulmod(x, y, MAX_VAL);
}}

// does not overflow
function mulMod(uint256 x, uint256 y, uint256 z) pure returns (uint256) { unchecked {
    return mulmod(x, y, z);
}}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract BEP20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function toHexStringNoPrefix(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = buffer.length; i > 0; i--) {
            buffer[i - 1] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
}

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is BEP20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

/**
 * @dev Extension of ERC20 to support Compound-like voting and delegation. This version is more generic than Compound's,
 * and supports token supply up to 2^224^ - 1, while COMP is limited to 2^96^ - 1.
 *
 * NOTE: If exact COMP compatibility is required, use the {ERC20VotesComp} variant of this module.
 *
 * This extension keeps a history (checkpoints) of each account's vote power. Vote power can be delegated either
 * by calling the {delegate} function directly, or by providing a signature to be used with {delegateBySig}. Voting
 * power can be queried through the public accessors {getVotes} and {getPastVotes}.
 *
 * By default, token balance does not account for voting power. This makes transfers cheaper. The downside is that it
 * requires users to delegate to themselves in order to activate checkpoints and have their voting power tracked.
 *
 * _Available since v4.2._
 */
abstract contract ERC20Votes is IVotes, ERC20Permit {
    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => address) private _delegates;
    mapping(address => Checkpoint[]) private _checkpoints;
    Checkpoint[] private _totalSupplyCheckpoints;

    /**
     * @dev Get the `pos`-th checkpoint for `account`.
     */
    function checkpoints(address account, uint32 pos) public view virtual returns (Checkpoint memory) {
        return _checkpoints[account][pos];
    }

    /**
     * @dev Get number of checkpoints for `account`.
     */
    function numCheckpoints(address account) public view virtual returns (uint32) {
        return SafeCast.toUint32(_checkpoints[account].length);
    }

    /**
     * @dev Get the address `account` is currently delegating to.
     */
    function delegates(address account) public view virtual override returns (address) {
        return _delegates[account];
    }

    /**
     * @dev Gets the current votes balance for `account`
     */
    function getVotes(address account) public view virtual override returns (uint256) {
        uint256 pos = _checkpoints[account].length;
        return pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
    }

    /**
     * @dev Retrieve the number of votes for `account` at the end of `blockNumber`.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotes(address account, uint256 blockNumber) public view virtual override returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_checkpoints[account], blockNumber);
    }

    /**
     * @dev Retrieve the `totalSupply` at the end of `blockNumber`. Note, this value is the sum of all balances.
     * It is but NOT the sum of all the delegated votes!
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber) public view virtual override returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
    }

    /**
     * @dev Lookup a value in a list of (sorted) checkpoints.
     */
    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber) private view returns (uint256) {
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
        //
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
        // the same.
        uint256 high = ckpts.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (ckpts[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : ckpts[high - 1].votes;
    }

    /**
     * @dev Delegate votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) public virtual override {
        _delegate(_msgSender(), delegatee);
    }

    /**
     * @dev Delegates votes from signer to `delegatee`
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= expiry, "ERC20Votes: signature expired");
        address signer = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry))),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), "ERC20Votes: invalid nonce");
        _delegate(signer, delegatee);
    }

    /**
     * @dev Maximum token supply. Defaults to `type(uint224).max` (2^224^ - 1).
     */
    function _maxSupply() internal view virtual returns (uint224) {
        return type(uint224).max;
    }

    /**
     * @dev Snapshots the totalSupply after it has been increased.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        super._mint(account, amount);
        require(totalSupply() <= _maxSupply(), "ERC20Votes: total supply risks overflowing votes");

        _writeCheckpoint(_totalSupplyCheckpoints, _add, amount);
    }

    /**
     * @dev Snapshots the totalSupply after it has been decreased.
     */
    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount);

        _writeCheckpoint(_totalSupplyCheckpoints, _subtract, amount);
    }

    /**
     * @dev Move voting power when tokens are transferred.
     *
     * Emits a {DelegateVotesChanged} event.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);

        _moveVotingPower(delegates(from), delegates(to), amount);
    }

    /**
     * @dev Change delegation for `delegator` to `delegatee`.
     *
     * Emits events {DelegateChanged} and {DelegateVotesChanged}.
     */
    function _delegate(address delegator, address delegatee) internal virtual {
        address currentDelegate = delegates(delegator);
        uint256 delegatorBalance = balanceOf(delegator);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveVotingPower(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveVotingPower(
        address src,
        address dst,
        uint256 amount
    ) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[src], _subtract, amount);
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[dst], _add, amount);
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }
        }
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].votes;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].votes = SafeCast.toUint224(newWeight);
        } else {
            ckpts.push(Checkpoint({fromBlock: SafeCast.toUint32(block.number), votes: SafeCast.toUint224(newWeight)}));
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <remco@2π.com>, Eenae <alexey@mixbytes.io>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor() {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the token name.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface erc20 {
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint amount) external returns (bool);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function mint(address,uint) external;
    function burn(address,uint) external;
}

interface IBaseV1Voter {
    function _ve() external view returns (address);
}

interface IBaseV1Factory {
    function isPair(address) external view returns (bool);
}

interface IBaseV1Core {
    function claimFees() external returns (uint, uint);
    function tokens() external returns (address, address);
}

interface IBaseV1GaugeFactory {
    function createGauge(address, address, address) external returns (address);
    function createGauge(address, address) external returns (address);
}

interface IBaseV1BribeFactory {
    function createBribe(address) external returns (address);
}

interface Voter {
    function attachTokenToGauge(uint _tokenId, address account) external;
    function detachTokenFromGauge(uint _tokenId, address account) external;
    function emitDeposit(uint _tokenId, address account, uint amount) external;
    function emitWithdraw(uint _tokenId, address account, uint amount) external;
    function distribute(address _gauge) external;
    function getColor(address) external view returns(uint);
    function weights(address) external returns(uint);
    function poolForGauge(address) external returns(address);
    function isGauge(address) external returns(bool);
    function vote(uint, address[] calldata, int256[] calldata) external;
    function gauges(address) external returns(address);
}

interface ISuperLikeVoter {
    function vote(uint, address[] calldata, int256[] calldata) external;
    function isGauge(address) external returns(bool);
}

interface IAcceleratorVoter {
    function isGauge(address) external returns(bool);
    function vote(uint,uint,uint,uint,address,address,bool) external;
    function distribute(address,address) external;
    function getReward(address[] memory) external;
    function maxWithdrawable() external view returns(uint);
    function deposit(uint,uint) external;
    function withdraw(uint,uint) external;
    function notifyRewardAmount(address,uint) external;
}

interface IBusinessVoter {
    function isGauge(address) external returns(bool);
    function vote(uint,uint,uint,uint,address,address,bool) external;
    function distribute(address,address) external;
    function getReward(address[] memory) external;
    function maxWithdrawable() external view returns(uint);
    function deposit(uint,uint,address) external;
    function withdraw(uint,uint) external;
    function notifyRewardAmount(address,uint) external;
}

interface IReferralVoter {
    function vote(uint,uint,uint,address,address,bool) external;
    function isGauge(address) external returns(bool);
    function deposit(uint,uint) external;
    function withdraw(uint,uint) external;
}

interface IBadgeNFT {
    function batchMint(
        address,
        uint256,
        uint256,
        int256,
        string memory,
        string memory) external;
    function getTicketOwner(uint) external returns(address);
    function getTicketAuditor(uint) external returns(address, address);
    function getTicketRating(uint) external view returns(bytes32, bytes32, int);
    function updateDev(address) external;
    function updateApi(uint, bytes32) external;
    function updateInfo(uint, int, bytes32, bytes32) external;
}

interface IGauge {
    function notifyRewardAmount(address token, uint amount) external;
    function getReward(address account, address[] memory tokens) external;
    function claimFees() external returns (uint claimed0, uint claimed1);
    function left(address token) external view returns (uint);
    function createGauge(uint,address) external returns(address);
    function addToken(address,address) external;
}

interface IBribe {
    function createBribe(address) external returns (address);
    function createBribe() external returns(address);
    function _deposit(uint amount, uint tokenId) external;
    function _withdraw(uint amount, uint tokenId) external;
    function getRewardForOwner(uint tokenId, address[] memory tokens) external returns(uint);
}

interface IStakeMarketBribe {
    function _deposit(address ve, uint amount, uint tokenId) external;
    function _withdraw(address ve, uint amount, uint tokenId) external;
    function getRewardForOwner(address ve, uint tokenId, address[] memory tokens) external returns(uint);
}

interface IMinter {
    function update_period() external returns (uint);
}

interface ve {
    function token() external view returns (address);
    function balanceOfNFT(uint) external view returns (uint);
    function percentiles(uint) external view returns (uint);
    function isApprovedOrOwner(address, uint) external view returns (bool);
    function ownerOf(uint) external view returns (address);
    function transferFrom(address, address, uint) external;
    function attach(uint tokenId) external;
    function detach(uint tokenId) external;
    function voting(uint tokenId) external;
    function abstain(uint tokenId) external;
    function totalSupply() external view returns (uint);
    function create_lock_for(uint, uint, address) external returns (uint);
}

interface IVaFactory {
    function maximumSize() external view returns (uint);
    function voter() external view returns (address);
    function helper() external view returns (address);
    function trustBounty() external view returns (address);
}

interface va {
    function token() external view returns (address);
    function balanceOfNFT(uint) external view returns (uint);
    function lenderFactor() external view returns (uint);
    function percentiles(uint) external view returns (uint);
    function isApprovedOrOwner(address, uint) external view returns (bool);
    function ownerOf(uint) external view returns (address);
    function transferFrom(address, address, uint) external;
    function attach(uint tokenId) external;
    function detach(uint tokenId) external;
    function voting(uint tokenId) external;
    function abstain(uint tokenId) external;
    function addSponsor(address) external;
}

interface underlying {
    function approve(address spender, uint value) external returns (bool);
    function mint(address, uint) external;
    function burn(address, uint) external returns (bool);
    function totalSupply() external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function transfer(address, uint) external returns (bool);
}

interface ISponsorCardReceiver {
    function addSponsorCard() external;
    function removeSponsorCard() external;
    function notifyRewardAmount(address, uint) external;
    function getAllPaidFromSponsor() external view returns(uint);
    function getAllSponsors() external view returns(address[] memory, uint[] memory);
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract AML is ERC20Votes, Ownable {
    address public contractAddress;
    uint public limitWithoutProfileFactor = 1000e18;
    uint public limitWithProfileFactor = 10000e18;
    uint public bufferTime = 14 days;
    uint internal constant month = 86400 * 7 * 4;
    mapping(address => uint) public attachedProfileId;
    mapping(uint => uint) public attachedBountyId;
    mapping(address => uint) private nextUpdate;
    mapping(address => uint) public transferedSoFar;
    mapping(address => uint) public minimBalance;
    mapping(address => bool) public blacklistedAccount;
    mapping(uint => bool) public blacklistedProfile;
    mapping(address => bool) public isSourceWhitelisted;
    mapping(address => bool) public isDestWhitelisted;
    uint public tokenPriceInDollar = 1;
    address public platform;

    event AttachProfile(uint indexed profileId, address account);
    event AttachBounty(uint indexed profileId, uint bountyId, address account);
    event DetachProfile(uint indexed profileId, address account);

    constructor(
        address _contractAddress,
        address _devaddr,
        string memory _name,
        string memory _symbol
    ) BEP20(_name, _symbol) ERC20Permit(_name) {
        contractAddress = _contractAddress;
        platform = _devaddr;
    }
    
    modifier notInBlacklist(address _user) {
        if (attachedProfileId[_user] > 0) {
            require(!blacklistedProfile[attachedProfileId[_user]]);
        }
        require(!blacklistedAccount[_user]);
        _;
    }

    function setContractAddress(address __contractAddress) external {
        require(contractAddress == address(0x0) || platform == msg.sender, "PMC13");
        contractAddress = __contractAddress;
    }

    function updateTokenPriceInDollar(uint _tokenPriceInDollar) external onlyOwner {
        tokenPriceInDollar = _tokenPriceInDollar;
    }

    function limitWithProfile() public view returns(uint) {
        return tokenPriceInDollar * limitWithProfileFactor;
    }

    function limitWithoutProfile() public view returns(uint) {
        return tokenPriceInDollar * limitWithoutProfileFactor;
    }

    function getLimit(address _user) public returns(uint) {
        uint _limit = attachedProfileId[_user] > 0 ? limitWithProfile() : limitWithoutProfile();
        if (nextUpdate[_user] < block.timestamp) {
            nextUpdate[_user] = (block.timestamp + month) / month * month;
            transferedSoFar[_user] = 0;
            return _limit > minimBalance[_user] ? 
            _limit - minimBalance[_user] : 0;
        }
        return _limit > transferedSoFar[_user] + minimBalance[_user] 
        ? _limit - transferedSoFar[_user] + minimBalance[_user] 
        : 0;
    }
    
    function getVals() external view returns(uint,uint,uint) {
        uint _limit = attachedProfileId[msg.sender] > 0 ? limitWithProfile() : limitWithoutProfile();
        return (
            _limit,
            transferedSoFar[msg.sender],
            minimBalance[msg.sender]
        );
    }

    function _notifyTransfer(address _from, address _to, uint _amount) internal notInBlacklist(_from) {
        if (attachedProfileId[_from] != attachedProfileId[_to] || 
            attachedProfileId[_from] == 0
        ) {
            require(getLimit(_from) >= _amount, "Limit lower than amount");
            transferedSoFar[_from] += _amount; 
        }
    }

    function _notifyExceptionalTransfer(address _user, uint _amount, uint _bountyId) internal notInBlacklist(_user) {
        address trustBounty = IContract(contractAddress).trustBounty();
        (address _owner,address _token,,address claimableBy,,,,,,) = ITrustBounty(trustBounty).bountyInfo(_bountyId);
        require(_owner == _user && _token == address(this) && claimableBy == address(this));
        uint _limit = ITrustBounty(trustBounty).getBalance(_bountyId);
        if (nextUpdate[_user] < block.timestamp) {
            nextUpdate[_user] = (block.timestamp + month) / month * month;
            transferedSoFar[_user] = 0;
            require(_limit >= minimBalance[_user] + _amount);
        } else {
            require(_limit >= transferedSoFar[_user] + minimBalance[_user] + _amount);
        }
        transferedSoFar[_user] += _amount; 
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        super.transfer(to, amount);
        address trustBounty = IContract(contractAddress).trustBounty();
        if (!(isSourceWhitelisted[msg.sender] || isDestWhitelisted[to])) {
            uint _bounty1 = attachedBountyId[attachedProfileId[msg.sender]];
            uint _bounty2 = attachedBountyId[attachedProfileId[to]];
            if (attachedProfileId[msg.sender] > 0 && (_bounty1 > 0 || _bounty2 > 0)
            ) {
                uint _limit1 = ITrustBounty(trustBounty).getBalance(_bounty1);
                uint _limit2 = ITrustBounty(trustBounty).getBalance(_bounty2);
                _notifyExceptionalTransfer(
                    _limit1 >= _limit2 ? msg.sender : to, 
                    amount, 
                    _limit1 >= _limit2 ? _bounty1 : _bounty2
                );
            } else {
                _notifyTransfer(msg.sender, to, amount);
            }
        }
        return true;
    }
    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        super.transferFrom(from, to, amount);
        if (!(isSourceWhitelisted[msg.sender] || isDestWhitelisted[to])) {
            if (attachedProfileId[from] > 0 && 
                attachedBountyId[attachedProfileId[from]] > 0
            ) {
                _notifyExceptionalTransfer(
                    from, 
                    amount, 
                    attachedBountyId[attachedProfileId[from]]
                );
            } else {
                _notifyTransfer(from, to, amount);
            }
        }
        return true;
    }

    function token() external view returns(address) { return address(this); }

    function createBountyWithBalance(
        address _ve, 
        uint _collectionId, 
        uint _amount,
        string memory _avatar
    ) external {
        address trustBounty = IContract(contractAddress).trustBounty();
        uint _bountyId = ITrustBounty(trustBounty).createBounty(
            msg.sender,
            address(this),
            _ve,
            address(this),
            0,
            _collectionId,
            type(uint).max,
            0,
            false,
            _avatar,
            "AML"
        );
        ITrustBounty(trustBounty).addBalance(_bountyId, address(this), 0, _amount);
    }

    function createClaim(
        uint _bountyId, 
        uint _amountToClaim,
        bool _lockBounty,
        string memory _title, 
        string memory _content,
        string memory _tags
    ) external {
        address trustBounty = IContract(contractAddress).trustBounty();
        uint _minToClaim = ITrustBounty(trustBounty).minToClaim() * _amountToClaim / 10000;
        erc20(address(this)).transferFrom(msg.sender, address(this), _minToClaim);
        erc20(address(this)).approve(trustBounty, _minToClaim);
        ITrustBounty(trustBounty).createClaim(
            address(this),
            _bountyId,
            _amountToClaim,
            _lockBounty,
            _title, 
            _content,
            _tags
        );
    }

    function applyClaimResults(
        uint _bountyId, 
        uint _claimId, 
        uint _amountToClaim,
        string memory _title, 
        string memory _content
    ) external {
        address trustBounty = IContract(contractAddress).trustBounty();
        ITrustBounty(trustBounty).applyClaimResults(
            _bountyId, 
            _claimId, 
            _amountToClaim,
            _title, 
            _content
        );
    }
    
    function endBounty(uint _bountyId) external {
        address trustBounty = IContract(contractAddress).trustBounty();
        ITrustBounty(trustBounty).updateBountyEndTime(_bountyId, bufferTime);
    }
    
    function updateMinimumBalance(address _owner, uint _tokenId, uint _amount, uint _deadline) external {
        address trustBounty = IContract(contractAddress).trustBounty();
        require(msg.sender == trustBounty);
        minimBalance[_owner] += _amount;
    }

    function deleteMinimumBalance(address _owner, uint _tokenId, uint _amount) external {
        address trustBounty = IContract(contractAddress).trustBounty();
        require(msg.sender == trustBounty);
        minimBalance[_owner] -= _amount;
    }

    function updateLimits(uint _limitWithProfileFactor, uint _limitWithoutProfileFactor) external {
        require(msg.sender == platform);
        require(_limitWithProfileFactor >= _limitWithoutProfileFactor * 10);
        limitWithProfileFactor = _limitWithProfileFactor;
        limitWithoutProfileFactor = _limitWithoutProfileFactor;
    }

    function updateWhitelist(address _contract, bool _sourceWhitelist, bool _destWhitelist) external onlyOwner {
        isSourceWhitelisted[_contract] = _sourceWhitelist;
        isDestWhitelisted[_contract] = _destWhitelist;
    }

    function updateBlacklistProfile(uint _profileId, bool _add) external onlyOwner {
        blacklistedProfile[_profileId] = _add;
    }

    function updateBlacklistAccount(address _account, bool _add) external onlyOwner {
        blacklistedAccount[_account] = _add;
    }

    function updatePlatform(address _platform) external onlyOwner {
        platform = _platform;
    }

    function updateBufferTime(uint _bufferTime) external onlyOwner {
        bufferTime = _bufferTime;
    }

    function attachProfile() external {
        address profile = IContract(contractAddress).profile();
        uint _profileId = IProfile(profile).addressToProfileId(msg.sender);
        require(IProfile(profile).isUnique(_profileId));
        attachedProfileId[msg.sender] = _profileId;

        emit AttachProfile(_profileId, msg.sender);
    }

    function attachBounty(uint _bountyId) external {
        address trustBounty = IContract(contractAddress).trustBounty();
        uint _profileId = attachedProfileId[msg.sender];
        (address _owner,address _token,,address claimableBy,,,,,,) = ITrustBounty(trustBounty).bountyInfo(_bountyId);
        require(
            // _profileId > 0 && 
            _owner == msg.sender && 
            _token == address(this) && claimableBy == address(this)
        );
        attachedBountyId[_profileId] = _bountyId;

        emit AttachBounty(_profileId, _bountyId, msg.sender);
    }
    
    function detachProfile() external {
        uint _profileId = attachedProfileId[msg.sender];
        attachedProfileId[msg.sender] = 0;
        emit DetachProfile(_profileId, msg.sender);
    }

    function detachBounty() external {
        uint _profileId = attachedProfileId[msg.sender];
        attachedBountyId[_profileId] = 0;
        emit DetachProfile(_profileId, msg.sender);
    }
}

interface ISponsorCard {
    function getSponsored(address) external view returns(address[] memory);
    function payInvoicePayable(address) external returns(uint);
    function getDuePayable(address,address,uint) external view returns(uint,uint,int);
    function transferDueToNote(address) external;
    function getPaidPayable(address) external view returns(uint);
    function devaddr_() external view returns(address);
    function emitPayInvoicePayable(uint,uint) external;
    function emitUpdateContents(string memory,bool) external;
    function trustBounty() external view returns(address);
    function minBountyPercent() external view returns(uint);
    function tradingFee() external view returns(uint);
    function contentContainsAny(string[] memory) external view returns(bool);
    function protocolInfoCard(uint) external view returns(CardInfo memory);
    function protocolInfo(uint) external view returns(address,address,uint,uint,uint,uint,uint,uint);
    function emitUpdateProtocol(uint,address,string memory,string memory) external;
    function addressToProtocolId(address) external view returns(uint);
    function notes(address,uint) external view returns(uint,uint,uint,address);
    function noteWithdraw(address,uint,uint) external;
    function emitDeleteProtocol(uint) external;
    function emitWithdraw(address,uint) external;
    function updateGauge(address,address,uint,string memory,string memory) external;
}

interface ISponsorCardFactory {
    function addPaid(uint) external;
    function canBoost(address) external returns(bool);
    function setCanBoost(address _nftContract, bool _canBoost) external;
    function MAX_BOOST() external returns(uint);
}

interface erscr {
    function balanceOf(address, uint) external view returns(uint);
    function boostingPower(uint) external returns(uint);
    function getLender(uint) external returns(address);
    function batchDetach(uint[] memory) external;
    function safeTransfer(address, uint) external;
    function batchAttach(uint[] memory, uint, address) external;
}

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

library Percentile {
    // zscore => percentile
    function table(int _val) public pure returns(uint) {   
        if(_val == -241) return 1;
        if(_val == -205) return 2;
        if(_val == -188) return 3;
        if(_val == -175) return 4;
        if(_val == -165) return 5;
        if(_val == -156) return 6;
        if(_val == -148) return 7;
        if(_val == -141) return 8;
        if(_val == -134) return 9;
        if(_val == -128) return 10;
        if(_val == -123) return 11;
        if(_val == -118) return 12;
        if(_val == -113) return 13;
        if(_val == -108) return 14;
        if(_val == -104) return 15;
        if(_val == -100) return 16;
        if(_val == -95) return 17;
        if(_val == -92) return 18;
        if(_val == -88) return 19;
        if(_val == -84) return 20;
        if(_val == -81) return 21;
        if(_val == -77) return 22;
        if(_val == -74) return 23;
        if(_val == -71) return 24;
        if(_val == -67) return 25;
        if(_val == -64) return 26;
        if(_val == -61) return 27;
        if(_val == -58) return 28;
        if(_val == -55) return 29;
        if(_val == -52) return 30;
        if(_val == -50) return 31;
        if(_val == -47) return 32;
        if(_val == -44) return 33;
        if(_val == -41) return 34;
        if(_val == -39) return 35;
        if(_val == -36) return 36;
        if(_val == -33) return 37;
        if(_val == -31) return 38;
        if(_val == -28) return 39;
        if(_val == -25) return 40;
        if(_val == -23) return 41;
        if(_val == -20) return 42;
        if(_val == -18) return 43;
        if(_val == -15) return 44;
        if(_val == -13) return 45;
        if(_val == -10) return 46;
        if(_val == -8) return 47;
        if(_val == -5) return 48;
        if(_val == -3) return 49;
        if(_val == 0) return 50;
        if(_val == 3) return 51;
        if(_val == 5) return 52;
        if(_val == 8) return 53;
        if(_val == 10) return 54;
        if(_val == 13) return 55;
        if(_val == 15) return 56;
        if(_val == 18) return 57;
        if(_val == 20) return 58;
        if(_val == 23) return 59;
        if(_val == 25) return 60;
        if(_val == 28) return 61;
        if(_val == 31) return 62;
        if(_val == 33) return 63;
        if(_val == 36) return 64;
        if(_val == 39) return 65;
        if(_val == 41) return 66;
        if(_val == 44) return 67;
        if(_val == 47) return 68;
        if(_val == 50) return 69;
        if(_val == 52) return 70;
        if(_val == 55) return 71;
        if(_val == 58) return 72;
        if(_val == 61) return 73;
        if(_val == 64) return 74;
        if(_val == 67) return 75;
        if(_val == 71) return 76;
        if(_val == 74) return 77;
        if(_val == 77) return 78;
        if(_val == 81) return 79;
        if(_val == 84) return 80;
        if(_val == 88) return 81;
        if(_val == 92) return 82;
        if(_val == 95) return 83;
        if(_val == 100) return 84;
        if(_val == 104) return 85;
        if(_val == 108) return 86;
        if(_val == 113) return 87;
        if(_val == 118) return 88;
        if(_val == 123) return 89;
        if(_val == 128) return 90;
        if(_val == 134) return 91;
        if(_val == 141) return 92;
        if(_val == 148) return 93;
        if(_val == 156) return 94;
        if(_val == 165) return 95;
        if(_val == 175) return 96;
        if(_val == 188) return 97;
        if(_val == 205) return 98;
        if(_val == 241) return 99;
    }
    // percentile => zscore
    function zTable(uint _val) public pure returns(int) {
        if(_val == 1) return -241;
        if(_val == 2) return -205;
        if(_val == 3) return -188;
        if(_val == 4) return -175;
        if(_val == 5) return -165;
        if(_val == 6) return -156;
        if(_val == 7) return -148;
        if(_val == 8) return -141;
        if(_val == 9) return -134;
        if(_val == 10) return -128;
        if(_val == 11) return -123;
        if(_val == 12) return -118;
        if(_val == 13) return -113;
        if(_val == 14) return -108;
        if(_val == 15) return -104;
        if(_val == 16) return -100;
        if(_val == 17) return -95;
        if(_val == 18) return -92;
        if(_val == 19) return -88;
        if(_val == 20) return -84;
        if(_val == 21) return -81;
        if(_val == 22) return -77;
        if(_val == 23) return -74;
        if(_val == 24) return -71;
        if(_val == 25) return -67;
        if(_val == 26) return -64;
        if(_val == 27) return -61;
        if(_val == 28) return -58;
        if(_val == 29) return -55;
        if(_val == 30) return -52;
        if(_val == 31) return -50;
        if(_val == 32) return -47;
        if(_val == 33) return -44;
        if(_val == 34) return -41;
        if(_val == 35) return -39;
        if(_val == 36) return -36;
        if(_val == 37) return -33;
        if(_val == 38) return -31;
        if(_val == 39) return -28;
        if(_val == 40) return -25;
        if(_val == 41) return -23;
        if(_val == 42) return -20;
        if(_val == 43) return -18;
        if(_val == 44) return -15;
        if(_val == 45) return -13;
        if(_val == 46) return -10;
        if(_val == 47) return -8;
        if(_val == 48) return -5;
        if(_val == 49) return -3;
        if(_val == 50) return 0;
        if(_val == 51) return 3;
        if(_val == 52) return 5;
        if(_val == 53) return 8;
        if(_val == 54) return 10;
        if(_val == 55) return 13;
        if(_val == 56) return 15;
        if(_val == 57) return 18;
        if(_val == 58) return 20;
        if(_val == 59) return 23;
        if(_val == 60) return 25;
        if(_val == 61) return 28;
        if(_val == 62) return 31;
        if(_val == 63) return 33;
        if(_val == 64) return 36;
        if(_val == 65) return 39;
        if(_val == 66) return 41;
        if(_val == 67) return 44;
        if(_val == 68) return 47;
        if(_val == 69) return 50;
        if(_val == 70) return 52;
        if(_val == 71) return 55;
        if(_val == 72) return 58;
        if(_val == 73) return 61;
        if(_val == 74) return 64;
        if(_val == 75) return 67;
        if(_val == 76) return 71;
        if(_val == 77) return 74;
        if(_val == 78) return 77;
        if(_val == 79) return 81;
        if(_val == 80) return 84;
        if(_val == 81) return 88;
        if(_val == 82) return 92;
        if(_val == 83) return 95;
        if(_val == 84) return 100;
        if(_val == 85) return 104;
        if(_val == 86) return 108;
        if(_val == 87) return 113;
        if(_val == 88) return 118;
        if(_val == 89) return 123;
        if(_val == 90) return 128;
        if(_val == 91) return 134;
        if(_val == 92) return 141;
        if(_val == 93) return 148;
        if(_val == 94) return 156;
        if(_val == 95) return 165;
        if(_val == 96) return 175;
        if(_val == 97) return 188;
        if(_val == 98) return 205;
        if(_val == 99) return 241;
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function computePercentileFromData(
        bool skip,
        uint _paid,
        uint _totalpaidInvoices,
        uint _totalInvoices,
        uint _sum_of_diff_squared_invoices
    ) public pure returns(uint, uint) {
        _totalInvoices += 1;
        if (_totalpaidInvoices < type(uint).max) _totalpaidInvoices += _paid;
        uint _mean = _totalpaidInvoices / _totalInvoices;
        int256 paid_mean;
        int sign = 1;
        if (_paid > _mean) {
            paid_mean = int256(_paid - _mean);
        } else {
            sign = -1;
            paid_mean = int256(_mean - _paid);
        }
        if (!skip) {
            _sum_of_diff_squared_invoices += uint(paid_mean)**2;
        }
        uint _std = sqrt(_sum_of_diff_squared_invoices / (_totalInvoices>1?_totalInvoices-1:1));
        _std = _std>0?_std:1;
        return (
            getPercentile(sign * paid_mean * 100 / int256(_std)),
            _sum_of_diff_squared_invoices
        );
    }

    function getPercentile(int _zscore) public pure returns(uint){
        if (_zscore >= 241) {
            return 99;
        }
        if (table(_zscore) != 0) {
            return table(_zscore);
        }
        while(table(_zscore) == 0) {
            _zscore += 1;
        } 
        return table(_zscore);
    }
}

library PlusCodes {
    uint internal constant GLOC_LENGTH = 20;

    function isPlusCodeFirstFour(string memory a, string memory b, string memory c, string memory d) external pure returns(bool){
        require(isFirstDigit(a));
        require(isSecondDigit(b));
        require(isThirdOrFourthDigit(c));
        require(isThirdOrFourthDigit(d));
        return true;
    }

    function isPlusCodeLastFour(string memory a, string memory b, string memory c, string memory d) external pure returns(bool){
        require(isFirstDigit(a));
        require(isSecondDigit(b));
        require(isThirdOrFourthDigit(c));
        require(isThirdOrFourthDigit(d));
        return true;
    }

    function isFirstDigit(string memory a) public pure returns(bool) {
        // first digit
        if (
            keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked('3')) ||
            keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked('4')) ||
            keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked('5')) ||
            keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked('6')) ||
            keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked('7')) ||
            keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked('8')) ||
            keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked('9'))
        ) {
            return true;
        }
        return false;
    }

    function isSecondDigit(string memory a) public pure returns(bool) {
        // second digit
        if (
            isFirstDigit(a) ||
            keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked('c')) ||
            keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked('f')) ||
            keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked('g')) ||
            keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked('h')) ||
            keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked('j')) ||
            keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked('m')) ||
            keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked('p')) ||
            keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked('q')) ||
            keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked('r')) ||
            keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked('v'))
        ) {
            return true;
        }
        return false;
    }

    function isThirdOrFourthDigit(string memory a) public pure returns(bool) {
        // third & fourth digit
        if (
            isFirstDigit(a) || isSecondDigit(a) ||
            keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked('w')) ||
            keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked('x'))
        ) {
            return true;
        }
        return false;
    }

    function getGlocChars() public pure returns(bytes[20] memory _glocChars) {
        _glocChars[0] = bytes('2');
        _glocChars[1] = bytes('3');
        _glocChars[2] = bytes('4');
        _glocChars[3] = bytes('5');
        _glocChars[4] = bytes('6');
        _glocChars[5] = bytes('7');
        _glocChars[6] = bytes('8');
        _glocChars[7] = bytes('9');
        _glocChars[8] = bytes('c');
        _glocChars[9] = bytes('f');
        _glocChars[10] = bytes('g');
        _glocChars[11] = bytes('h');
        _glocChars[12] = bytes('j');
        _glocChars[13] = bytes('m');
        _glocChars[14] = bytes('p');
        _glocChars[15] = bytes('q');
        _glocChars[16] = bytes('r');
        _glocChars[17] = bytes('v');
        _glocChars[18] = bytes('w');
        _glocChars[19] = bytes('x');
    }

    function generateExtensions() public pure returns(string[] memory _extensions,bytes[20] memory _glocChars) {
        _glocChars = getGlocChars();
        _extensions = new string[](GLOC_LENGTH * GLOC_LENGTH);
        for (uint i=0; i < GLOC_LENGTH; i++) {
            for (uint j=0; j < GLOC_LENGTH; j++) {
                string memory curr = string(abi.encodePacked(_glocChars[i],_glocChars[j]));
                _extensions[i*GLOC_LENGTH + j] = curr;
            }
        }
    }

    function checkExtension(string memory _ext) public pure returns(bool) {
        if (keccak256(abi.encodePacked('22')) == keccak256(abi.encodePacked(_ext))) {
            return true;
        }
        bytes[20] memory _glocChars = getGlocChars();
        for (uint i=0; i < GLOC_LENGTH; i++) {
            for (uint j=0; j < GLOC_LENGTH; j++) {
                string memory curr = string(abi.encodePacked(_glocChars[i],_glocChars[j]));
                if (keccak256(abi.encodePacked(curr)) == keccak256(abi.encodePacked(_ext))) {
                    return true;
                }
            }
        }
        return false;
    }

    function getExtensionsRow(uint _i) external pure returns(string[] memory _row) {
        (string[] memory _extensions,) = generateExtensions();
        _row = new string[](GLOC_LENGTH);
        for (uint j=0; j < GLOC_LENGTH; j++) {
            _row[j] = _extensions[_i*GLOC_LENGTH +j];
        }
        return _row;
    }

    function getNFTsFromExtension(uint _i, uint _j) external pure returns(string[] memory _row) {
        (string[] memory _extensions, bytes[20] memory _glocChars) = generateExtensions();
        _row = new string[](GLOC_LENGTH);
        string memory _ext = _extensions[_i*GLOC_LENGTH + _j*GLOC_LENGTH];
        for (uint k=0; k < GLOC_LENGTH; k++) {
            _row[k] = string(abi.encodePacked(_ext,_glocChars[k]));
        }
        return _row;
    }

    function getNFTsFromExtension2(string memory _ext) external pure returns(string[] memory _row) {
        require(checkExtension(_ext), "Invalid extension");
        (,bytes[20] memory _glocChars) = generateExtensions();
        _row = new string[](GLOC_LENGTH);
        for (uint k=0; k < GLOC_LENGTH; k++) {
            _row[k] = string(abi.encodePacked(_ext,_glocChars[k]));
        }
        return _row;
    }
}

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: contracts/interfaces/IWETH.sol

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// File: contracts/interfaces/ICollectionWhitelistChecker.sol

interface ICollectionWhitelistChecker {
    function canList(address, uint256 _tokenId) external view returns (bool);
}

// File: contracts/interfaces/ICollectionWhitelistChecker2.sol

interface ICollectionWhitelistChecker2 {
    function canList(string memory _tokenId) external view returns (bool);
}

// interface Mintables {
//     function _safeMint(address to, uint256 tokenId)  external;
// }

interface ITrustBounty {
    function emitDeleteBounty(uint) external;
    function emitUpdateBounty(uint,uint,address,string memory,string memory) external;
    function emitCreateBounty(uint,address,address,uint,uint,string memory,string memory) external;
    function emitAddBalance(uint,address,uint) external;
    function emitDeleteBalance(uint,address) external;
    function emitCreateClaim(uint,uint,uint,address,bool,bool) external;
    function emitUpdateClaim(uint,uint,bool,address) external;
    function emitAddApproval(uint,uint,uint,uint) external;
    function emitRemoveApproval(uint,uint,uint,bool) external;
    function notifyFees(address,uint) external;
    function claims(uint) external view returns(uint[] memory);
    function updateBountyEndTime(uint,uint) external;
    function attachments(uint) external view returns(uint);
    function ves(address) external view returns(bool);
    function attach(uint) external;
    function detach(uint) external;
    function createClaim(address, uint, uint, bool, string memory, string memory, string memory) external;
    function createClaimETH(address, uint, uint, bool, string memory, string memory,string memory) external payable;
    function getBalance(uint _bountyId) external view returns(uint _balance);
    function bountyInfo(uint _bountyId) external view returns(address,address,address,address,uint,uint,uint,uint,NFTYPE,bool);
    function createBounty(address,address,address,address,uint,uint,uint,uint,bool,string memory,string memory) external returns(uint);
    function addBalance(uint,address,uint,uint) external;
    function applyClaimResults(uint,uint,uint,string memory,string memory) external;
    function minToClaim() external view returns(uint);
    function tradingFee() external view returns(uint);
    function tradingNFTFee() external view returns(uint);
    function minLockPeriod() external view returns(uint);
    function balanceBuffer() external view returns(uint);
    function appealWindow() external view returns(uint);
    function isAuthorizedSourceFactories(address) external view returns(bool);
    function isWhiteListed(address) external view returns(bool);
    function isVe(address) external view returns(bool);
    function WETH() external view returns(address);
    function attach(uint,address) external;
    function detach(uint,address) external;
    function safeTransferFrom(uint,address,address,uint256) external;
    function safeTransfer(uint,address,uint256) external;
    function deleteTreasuryFee(address) external;
    function treasuryFees(address) external view returns(uint);
    function emitUpdateWhitelistedTokens(address[] memory,bool) external;
    function emitUpdateAuthorizedSourceFactories(address[] memory,bool) external;
}

interface IProfile {
    function emitUpdateMiscellaneous(uint,uint,string memory,string memory,uint,uint,address,string memory) external;
    function sum_of_diff_squared(address) external view returns(uint);
    function total(address) external view returns(uint);
    function getAllFollowers(uint,uint) external view returns(address[] memory);
    function boughtProfile(address) external view returns(uint);
    function getAccountAt(uint,uint) external view returns(address);
    function isUnique(uint) external view returns(bool);
    function sharedEmail(address) external view returns(bool);
    function safeMint(address,uint) external;
    function burn(uint) external;
    function referrerFromAddress(address) external view returns(uint);
    function updateLateDays(uint _profileId, uint _lateDays, uint _dueReceivable) external;
    function getAllAccounts(uint,uint) external view returns(address[] memory);
    function profileInfo(uint _profileId) external view returns(
        string memory,
        string memory,
        uint,
        uint,
        uint,
        uint,
        uint,
        CreditReport memory,
        CreditReport memory,
        CreditReport memory,
        CreditReport memory
    );
    function addressToProfileId(address) external view returns(uint);
}

interface IGaugeBalance {
    function _ve() external view returns(address);
    function balanceOf(uint) external view returns (uint);
    function withdrawBounty(address, uint, uint) external;
    function updateMinimumBalance(address _owner, uint _tokenId, uint _amount, uint _endTime) external;
    function deleteMinimumBalance(address _owner, uint _tokenId, uint _amount) external;
}

interface IGaugeBalanceFactory {
    function isGauge(address _source) external view returns(bool);
    function withdrawBounty(address _sender, uint _toWithdraw) external returns(bool);
}

interface IExtractor {
    function extractResource(string memory, address, uint) external;
}

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

interface IGameNFT {
    function destination(uint) external view returns(address);
    function getDescription(uint) external view returns(string[] memory);
    function getTaskContract(uint,uint) external view returns(address);
    function attach(uint256,uint256,address) external;
    function safeMint(address,uint) external;
    function updateAfterSponsorPayment(uint,uint,address) external;
    function tokenIdToCollectionId(uint) external view returns(uint);
    function emitMintObject(uint,string memory,uint[] memory) external;
    function checkNotBlacklisted(address,uint) external;
    function emitUpdateMiscellaneous(uint,uint,string memory,string memory,uint,uint,address,string memory) external;
    function isContract(uint) external view returns(address);
    function processClaim(address,address,uint,uint) external;
    function mint(address,uint) external;
    function symbol() external view returns(string memory);
    function addObject(uint,string memory) external;
    function addressToCollectionId(address) external view returns(uint);
    function decimals() external view returns(uint8);
    function uri(uint) external view returns(string memory);
    function blacklistedTickets(uint) external view returns(bool);
    function blacklist(address) external view returns(bool);
    function uriGenerator(uint) external view returns(address);
    function taskContract(uint,uint) external view returns(address);
    function isObject(uint,string memory) external view returns(bool,uint);
    function pendingTask(uint) external view returns(bool);
    function description(uint) external view returns(string memory);
    function getMedia(uint) external view returns(string[] memory);
    function removeObject(uint,uint) external;
    function computePercentileFromData(uint,uint,uint,uint) external view returns(uint,uint);
    function tokenURI(uint,uint,address) external view returns(string memory);
    function updatePricePercentile(uint, uint, uint) external;
    function updateScorePercentile(uint, uint, uint) external;
    function ticketInfo_(uint) external view returns(address,address,address,uint,uint,uint,uint,uint,uint,uint,bool);
    function gameInfo_(uint) external view returns(address,address,address,uint,uint,uint,uint,uint,uint,uint,uint,uint);
    function updateGameContract(address, address, uint, uint, uint, uint) external;
    function getExcludedContents(uint,string memory) external view returns(string[] memory);
    function updateDev(address) external;
    function deleteObjects(uint) external;
    function burn(address,uint,uint) external;
    function safeBurn(uint) external;
    function deleteObject(uint, uint) external;
    function getGamePrice(uint) external returns(uint);
    function getQ2() external view returns(uint);
    function getReceiver(uint) external view returns(address);
    function getTicketOwner(uint) external view returns(address);
    function getTicketLender(uint) external view returns(address);
    function updateScoreNDeadline(uint, uint, uint) external;
    function updateObjects(uint, uint[] memory, bool) external;
    function batchMint(address, uint256) external returns(uint256[] memory);
    function updateScorePercentile(uint, uint, uint, uint, uint) external returns(uint);
}

interface IGemNFT {
    function getReceiver(uint) external view returns(address);
    function getTicketOwner(uint) external view returns(address);
    function getTicketLender(uint) external view returns(address);
    function getTicketCarat(uint) external view returns(uint);
    function getTicketType(uint) external view returns(uint);
    function getTicketClarity(uint) external view returns(uint);
}

interface IDiamondNFT {
    function getReceiver(uint) external view returns(address);
    function getTicketOwner(uint) external view returns(address);
    function getTicketLender(uint) external view returns(address);
    function getTicketCarat(uint) external view returns(uint);
    function getTicketColor(uint) external view returns(uint);
    function getTicketClarity(uint) external view returns(uint);
}

interface INaturalResourceNFT {
    function attached(uint) external returns(bool);
    function detach(uint) external;
    function attach(uint256, uint256, address) external; 
    function batchDetach(uint256[] memory) external;
    function getReceiver(uint) external view returns(address);
    function getTicketOwner(uint) external view returns(address);
    function getTicketLender(uint) external view returns(address);
    function getTicketCarat(uint) external view returns(uint);
    function getTicketPPM(uint) external view returns(uint);
    function batchAttach(uint256[] memory, uint256, address) external; 
    function getTicketResource(uint) external view returns(string memory);
    function safeTransferNAttach(
        address,
        uint,
        address,
        address,
        uint256,
        uint256,
        bytes memory) external;
}

interface ISuperLikeGauge {
    function cancan_email() external view returns(string memory);
    function badgeColor() external view returns(uint);
    function devaddr_() external view returns(address);
    function tokenId() external view returns(uint);
    function updateLotteryCredits(uint, uint) external;
    function useLotteryCredit(address, uint) external;
}

interface ISuperLikeGaugeFactory {
    function isElligibleForLoan(bytes32) external view returns(bool);
    function setElligibleForLoan(bytes32[] memory, address, bool) external;
    function isGauge(address) external view returns(bool);
    function userGauge(address) external view returns(address);
    function referrers(address) external view returns(uint);
    function updateGaugeEmail(string memory, string memory) external;
    function mintBadge(address, int256, string memory, string memory) external;
    function safeTransferFrom(address, address, uint) external;
    function createGauge(address, address, uint, uint) external returns(address);
    function getIdentityValue(address, string memory) external view returns(string memory, string memory, address);
}

interface ICatalogNFTFactory {
    function setElligible(address, bytes32[] memory, bool) external;
}

interface IPaywall {
    function updateTokenId(uint) external;
    function isGauge(address) external view returns(bool);
    function startAccount(address, uint) external;
    function mintNFTicket(address,uint,string memory) external;
    function collectionId() external view returns(uint);
    function notifyRevenue(address,uint) external;
    function autoCharge(address[] memory,uint,uint) external;
    function getRealPrice(address,string memory,uint,bytes32) external view returns(uint, bool);
    function updateProtocol(address,uint,uint,uint,uint,uint,string memory) external;
    function updateProtocolShares(uint, uint, address[] memory) external;
    function protocolInfo(uint) external view returns(address,uint,uint,uint,uint,uint,uint,uint,uint,uint,uint,bool);
    function updateCashbackFund(address, uint, uint, bool) external;
    function cashbackFund(address, uint) external view returns(uint);
    function processTrade(address,address,address,string memory,uint,uint) external;
    function updateRecurringBountyRevenue(address,uint,uint) external;
    function calculatePriceAndFeesForCollection(uint,uint,string memory,uint256
    ) external view returns (uint256,uint256,uint256,uint256,uint256,uint256);
}

interface IBILL {
    function attach(uint) external;
    function detach(uint) external;
    function protocolInfo(uint) external view returns(BILLInfo memory);
    function percentiles(address) external view returns(uint);
    function getMedia(address,uint) external view returns(string[] memory);
    function collectionId() external view returns(uint);
    function autoCharge(uint[] memory,uint) external;
    function getReceivable(uint,uint) external view returns(uint,uint);
    function getAllPeriods(uint,uint) external view returns(uint[] memory);
    function cap(address) external view returns(uint);
    function adminCreditShare() external view returns(uint);
    function adminDebitShare() external view returns(uint);
    function decimals() external view returns(uint8);
    function notifyCredit(address, address, uint) external;
    function emitNotifyCredit(uint,uint,uint,address) external;
    function emitNotifyDebit(uint,uint,uint,address) external;
    function notifyCreditFromUser(address, uint) external;
    function notifyDebit(address, address, uint) external;
    function getDueReceivable(address,uint) external view returns(uint, uint, int);
    function getDuePayable(address,uint) external view returns(uint, uint, int);
    function updatePendingRevenueFromNote(uint, uint) external;
    function isPayable() external view returns(bool);
    function tradingFee(bool) external view returns(uint);
    function period() external view returns(uint);
    function bufferTime() external view returns(uint);
    function adminBountyRequired() external view returns(uint);
    function adminBountyId(address) external view returns(uint);
    function userBountyRequired(uint) external view returns(uint);
    function maxNotesPerProtocol() external view returns(uint);
    function adminNotes(uint) external view returns(uint);
    function notes(uint) external view returns(uint,uint,uint,address,address);
    function notifyFees(address,uint) external;
    function tokenIdToBILL(uint) external view returns(address,uint);
    function tokenIdToParent(uint) external view returns(uint);
    function media(uint) external view returns(string memory);
    function description(uint) external view returns(string memory);
    function updateGauge(address,address,uint) external;
    function mint(address) external returns(uint);
    function burn(uint) external returns(uint);
    function updatePaidPayable(uint,uint) external;
    function updateTreasuryFees(address,uint) external;
    function emitUpdateProtocol(uint,uint,address,address,string memory,string memory) external;
    function emitUpdateAutoCharge(uint,bool) external;
    function emitDeleteProtocol(uint) external;
    function emitAutoCharge(address,uint,uint) external;
    function emitClaimTransferNote(uint) external;
    function emitPayInvoicePayable(uint,uint) external;
    function emitWithdraw(address,uint) external;
    function emitVoted(address,uint,uint,uint,bool) external;
    function emitTransferDueToNote(address,uint,uint,uint,bool) external;
    function uriGenerator(address) external view returns(address);
    function uri(uint) external view returns(string memory);
    function isGauge(address) external view returns(bool);
    function tokenURI(uint) external view returns(string memory);
    function safeTransferWithBountyCheck(address,address,uint,uint) external;
    function noteWithdraw(address,address,uint) external;
    function emitUpdateMiscellaneous(uint,uint,string memory,string memory,uint,uint,address,string memory) external;
    function getGaugeNColor(uint) external view returns(address,COLOR);
}

interface INFTMarketPlace {
    function getRealPrice(address,address,uint,uint,bytes32) external returns(uint,bool);
}

interface IRamp {
    function endBounty(uint) external;
    function checkAuditor(address) external view returns(bool);
    function emitClaimPendingRevenue(address,address,address,uint) external;
    function trustWorthyAuditors(address) external view returns(bool);
    function emitVoted(address,uint,uint,uint,bool) external;
    function uri(uint) external view returns(string memory);
    function checkIdentityProof(address,uint) external;
    function updateGauge(address,address) external;
    function convert(address,uint) external view returns(uint);
    function minCap(address) external view returns(uint);
    function isGauge(address) external view returns(bool);
    function getAllTokens(uint) external view returns(address[] memory);
    function getAllPartnerBounties(address,uint) external view returns(uint[] memory);
    function protocolInfo(address) external view returns(RampInfo memory);
    function checkBounty(address,uint) external view;
    function getPartnerShare(uint,uint) external view returns(uint);
    function getTotalBalance(address,address) external view returns(uint);
    function mintAvailable(address,address) external view returns(uint,uint,CollateralStatus);
    function mintFactor(address) external view returns(uint);
    function tradingFee() external view returns(uint);
    function bufferTime() external view returns(uint);
    function maximumArrayLength() external returns(uint);
    function nativeCoin() external view returns(address);
    function badgeNFT() external view returns(address);
    function dTokenSetContains(address) external view returns(bool);
    function mint(address, address, uint, uint, uint, string memory) external;
    function mint(address, uint) external;
    function mintTo(address, uint) external;
    function burn(address, uint) external;
    function burn(address, address, uint, uint, uint) external;
    function burnFrom(address, uint) external;
    function emitDeleteProtocol(address,address) external;
    function emitCreateProtocol(address,address) external;
    function totalRevenue(address) external view returns(uint);
    function paidRevenue(address,uint) external view returns(uint);
    function claimPendingRevenue(address,address,uint) external returns(uint);
    function emitUpdateMiscellaneous(uint,uint,string memory,string memory,uint,uint,address,string memory) external;
}

interface IMarketPlace {
    function partner(uint,string memory,string memory,uint,bool) external;
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
    function lotteryRevenue(address) external view returns(uint);
    function claimLotteryRevenue(address) external;
    function claimLotteryRevenue() external;
    function notes(address) external view returns(uint,uint,uint);
    function tokenURIs(address,uint) external view returns(string memory);
    function scheduledMedia(uint) external view returns(uint,string memory);
    function currentMediaIdx() external view returns(uint);
    function pendingTask(uint) external view returns(bool);
    function constructTokenURI(uint,string memory,address,address,address,address,string[] memory,string[] memory,string[] memory,string[] memory) external view returns(string memory);
    function getTask(uint) external view returns(string memory);
    function uri(uint) external view returns(string memory);
    function defaultUri(address,string memory) external view returns(string memory);
    function getToken(uint) external view returns(address);
    function getProfileId(uint) external view returns(uint);
    function getMinter(uint,string memory,address,address,uint,uint) external;
    function notifyRewardAmount(address,uint) external;
    function getState(address,string memory,uint) external view returns(uint);
    function itemToMinter(uint,string memory) external view returns(address);
    function updateGauge(address,uint) external;
    function collectionId() external view returns(uint);
    function setContractAddress(address) external;
    function partnerShip(uint,uint) external view returns(bool);
    function hasGauge(uint) external view returns(address);
    function collectionIdToPaywallARP(uint) external view returns(address);
    function ongoingSubscription(address,uint,string memory) external view returns(bool);
    function mint(uint,string memory,address,uint[] memory) external returns(uint);
    function verifyNFT(uint,uint,string memory) external view returns(uint);
    function emitUpdateProtocol(uint,uint,uint,uint,uint,uint,uint,uint,string memory) external;
    function emitUpdateMiscellaneous(uint,uint,string memory,string memory,uint,uint,address,string memory) external;
    function emitDeleteProtocol(uint,uint) external;
    function emitUserRegistration(uint,uint,bool) external;
    function emitUpdateAutoCharge(uint,uint,bool) external;
    function isGauge(address) external returns(bool);
    function referrer(uint) external view returns(address);
    function contractAddress() external view returns(address);
    function emitCreatePaywallARP(address,uint) external;
    function emitDeletePaywallARP(uint) external;
    function getDueReceivable(address,uint) external view returns(uint, uint, int);
    function getDiscount(uint,address,string memory) external view returns(uint);
    function getGaugeNColor(SSIData memory,uint,COLOR,bool,bool) external view returns(bytes32);
    function checkBounty(address,uint,uint,uint,bytes32,bool) external;
    function checkPaywallBounty(address,uint,uint,uint,bytes32) external;
    function checkNftBounty(address,uint,uint,uint,bytes32) external;
    function lotteryCredits(address, address) external view returns(uint);
    function dynamicPrices(uint) external view returns(uint [] memory, uint, uint);
    function mintNote(address,uint) external;
    function checkRequirements(address,address,address,uint,uint,uint) external;
    function getReferral(uint,string memory) external view returns(uint,uint,uint);
    function checkOrderIdentityProof(uint,uint,address,string memory) external returns(bytes32);
    function withdrawRecurringBounty(address,address) external returns(uint);
    function emitCollectionUpdateIdentity(uint,string memory,string memory,bool,uint,bool,bool,COLOR) external;
    function emitVoted(uint,uint,string memory,uint,uint,bool) external;
    function buyWithContract(address,address,address,string memory,uint,uint,uint256[] calldata) external;
    function emitUpdateCollection(uint,string memory,string memory,string memory,string memory,string memory,string memory,string memory,string memory,string memory,string memory,string memory) external;
    function emitUpdateOptions(uint,string memory,uint,uint,uint,string memory,string memory,string memory,string memory,string memory) external;
    function emitPaywallUpdateOptions(uint,string memory,uint,uint,uint,uint,string memory,string memory,string memory,string memory) external;
    function emitCollectionClose(uint) external;
    function emitReview(uint,string memory,uint,uint,bool,uint,string memory,address) external;
    function emitAskInfo(uint,string memory,string memory,uint[] memory,uint,uint,uint,bool,string memory,string memory,string memory,string memory) external;
    function emitNewMinimumAndMaximumAskPrices(uint,uint) external;
    function emitNewAdminAndTreasuryAddresses(address,address) external;
    function emitCollectionUpdate(uint256,address,uint256,uint256,uint256,uint256,uint256,uint256,bool,bool) external;
    function emitCollectionNew(uint256,address,address,uint256,uint256,uint256,uint256,uint256,uint256,bool,bool) external;
    function emitAskUpdate(string memory,address,uint,uint,uint,int,bool,uint,uint,uint) external;
    function emitAskUpdateDiscount(uint,string memory,Status,uint,bool,bool,bool,uint[6] memory,uint[6] memory) external;
    function emitAskUpdateCashback(uint,string memory,Status,uint,bool,bool,uint[6] memory,uint[6] memory) external;
    function emitAskUpdateIdentity(uint,string memory,string memory,string memory,bool,bool,uint,COLOR) external;
    function emitUpdateSubscriptionInfo(uint, uint, uint) external;
    function emitUpdateScubscriptionTiers(uint, uint[] memory, uint[] memory) external;
    function emitAskNew(uint,string memory,uint,uint,int,bool,uint,uint,uint,address,address) external;
    function emitAskCancel(uint,uint) external;
    function emitCloseListing(uint, string memory) external;
    function emitAddReferral(uint, uint, string memory, uint, uint) external;
    function emitRevenueClaim(address, uint) external;
    function emitCloseReferral(uint,uint,uint,address,string memory,bool) external;
    function emitTrade(uint,string memory,address,address,uint,uint,uint,uint) external;
    function minimumAskPrice() external view returns(uint);
    function maximumAskPrice() external view returns(uint);
    function updateTreasuryRevenue(address,uint) external;
    function updateLotteryRevenue(address,uint) external;
    function updateCashbackFund(address, uint, uint, bool) external;
    function cashbackFund(address, uint) external view returns(uint);
    function updateCashbackRevenue(address,string memory) external;
    function updatePendingRevenue(address,address,uint,bool) external;
    function decreasePendingRevenue(address,address,uint,uint) external;
    function updateRecurringBountyRevenue(address,uint,uint) external;
    function subscriptionInfo(uint) external view returns(uint, uint);
    function identityProofs(bytes32) external view returns(uint);
    function processPayment(address, string memory, address, uint256) external;
    function getOptionPrices(string memory, uint[] memory) 
    external view returns(uint[] memory);
    function getTransferrable(address, string memory) external view returns(bool);
    function claimPendingRevenue() external returns(uint);
    function userToIdentityCode(uint) external view returns(bytes32);
    function updateUserToIdentityCode(uint,bytes32) external;
    function _rsrcBatchTransferCollection(address,uint[] memory,address,address) external;
    function getPrice(address, uint) external view returns(uint);
    function _beforePaymentApplyDiscount(address,uint,uint,bytes32) external view returns(uint);
    function incrementIdentityLimits(string memory, bytes32, uint) external;
    function addressToCollectionId(address) external view returns(uint);
    function maximumArrayLength() external view returns(uint);
    function maxDropinTimer() external view returns(uint);
    function cashbackBuffer() external view returns(uint);
    function nft_() external view returns(address);
    function getCollection(uint) external view returns(Collection memory);
    function checkPartnerIdentityProof(uint,uint,address) external;
    function checkUserIdentityProof(uint,uint,address) external;
    function _askDetails(uint,bytes32) external view returns(Ask memory);
    function getAskDetails(uint,bytes32) external view returns(Ask memory);
    function _askDetails2(uint,bytes32) external view returns(address,uint,address,uint,uint,int,uint,bool,PriceReductor memory,IdentityProof memory,uint,uint,TokenInfo memory);
    function checkIdentityProof(address,uint,bool) external;
    function checkIdentityProof2(uint,string memory,address,bool) external returns(bytes32 identityCode);
    function unAuthorizedContracts(address) external view returns(bool);
    function updateAfterSale(uint,string memory,uint,uint,address) external;
    function decrementMaxSupply(uint, bytes32) external;
    function lotteryFee() external view returns(uint);
    function ssi() external view returns(address);
    function treasuryAddress() external view returns(address);
    function lotteryAddress() external view returns(address);
    function token() external view returns(address);
    function lottery() external view returns(uint);
    function requiredIndentity() external view returns(bytes32);
    function timeBuffer() external view returns(uint);
    function _referrals(uint,bytes32) external view returns(address,uint,uint);
    function updatePaymentCredits(address,uint,string memory) external;
    function paymentCredits(address,string memory) external view returns(uint);
    function incrementPaymentCredits(address,uint,string memory,uint) external;
    function decrementPaymentCredits(address,uint,string memory,uint) external;
    function getDiscount(address,address,uint,uint,uint,uint) external view returns(uint);
    function options(uint,string memory,uint) external view returns(Option memory);
    function paywallOptions(uint,string memory,uint) external view returns(PaywallOption memory);
    function getOptions(uint,string memory,uint[] memory) external view returns(Option[] memory);
    function getPaywallOptions(uint,string memory,uint[] memory) external view returns(PaywallOption[] memory);
    function isCollectionTrustWorthyAuditor(uint,address) external view returns(bool);
    function beforePaymentApplyOptions(uint,bytes32,uint[] memory) external view returns(uint);
    function beforePaymentApplyDiscount(address,address,bytes32,uint,bytes32) external view returns(uint);
    function calculatePriceAndFeesForCollection(address,address,bytes32,uint256
    ) external view returns (uint256,uint256,uint256,uint256,uint256,uint256);
    function checkAuction(uint256,address,address,string memory) external;
    function mintNFTicket(address,uint,string memory,uint[] memory) external;
    function vote(address,address,string memory,uint,uint,uint) external;
    function getRealPrice(address,address,string memory,uint[] memory,uint,uint) external view returns(uint, bool);
    function identityLimits(string memory, bytes32) external view returns(uint);
    function discountLimits(string memory, address) external view returns(uint);
    function processTrade(address,address,address,string memory,uint,uint,uint[] memory) external;
    function blackListedIdentities(bytes32) external view returns(bool);
    function veTokenSetContains(address) external view returns(bool);
    function dTokenSetContains(address) external view returns(bool);
    function arps(uint) external view returns(address);
    function getPaymentCredits(address,uint,string memory) external view returns(uint);
    function minter(uint,string memory) external view returns(MintValues memory);
    function protocolInfo(uint) external view returns(uint,uint,uint,uint,uint,uint,uint,uint,uint,bool,string memory);  
}

contract Auth {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    mapping(uint => bytes32) private userToIdentityCode;
    EnumerableSet.AddressSet private trustWorthyAuditors;
    COLOR minIDBadgeColor = COLOR.BLACK;
    bool dataKeeperOnly;
    address public devaddr_;
    string public valueName;
    string public requiredIndentity;
    mapping(bytes32 => uint) private  identityProofs;
    mapping(bytes32 => bool) private blackListedIdentities;
    bool public cosignEnabled;
    uint public minCosigners;
    mapping(address => EnumerableSet.AddressSet) private cosigners;
    EnumerableSet.AddressSet private requests;
    mapping(address => uint) public limits;
    mapping(address => bool) public isAdmin;
    bool public onlyTrustWorthyAuditors;
    uint internal maxUse;
    address public helper;
    address _contractAddress;
    
    constructor(address _helper, address _devaddr, address __contractAddress) {
        helper = _helper;
        devaddr_ = _devaddr;
        isAdmin[_devaddr] = true;
        _contractAddress = __contractAddress;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender]);
        _;
    }

    modifier onlyChangeMinCosigners(address _sender, uint _amount) {
        changeDouble(_sender, _amount);
        _;
    } 

    function changeDouble(address __sender, uint _amount) public {
        address _sender = msg.sender == helper ? __sender : msg.sender;
        if (cosignEnabled) {
            require(cosigners[_sender].length() >= minCosigners && limits[_sender] >= _amount, "A1");
            limits[_sender] -= _amount;
            if (limits[_sender] == 0) {
                uint _length = cosigners[_sender].length();
                while(_length > 0) {
                    cosigners[_sender].remove(cosigners[_sender].at(0));
                    _length -= 1;
                }
                require(_length == 0);
            }
        } else {
            require(_sender == devaddr_);
        }
    }

    function updateAdmin(address _admin, bool _add) external {
        require(devaddr_ == msg.sender);
        isAdmin[_admin] = _add;
    }

    function cosign(address _cosignee) external onlyAdmin {
        if (msg.sender != _cosignee && isAdmin[msg.sender]) {
            cosigners[_cosignee].add(msg.sender);
            if (cosigners[_cosignee].length() >= minCosigners) requests.remove(_cosignee);
        }
    }

    function getAllRequests(uint _start) external view returns(address[] memory _requests) {
        _requests = new address[](requests.length() - _start);
        for (uint i = _start; i < requests.length(); i++){
            _requests[i] = requests.at(i);
        }
    }

    function requestCosign(uint _amount) external onlyAdmin {
        if(cosigners[msg.sender].length() == 0) {
            limits[msg.sender] = _amount;
            requests.add(msg.sender);
        }
    }

    function updateCosign(bool _enable, uint _minCosigners) external {
        require(devaddr_ == msg.sender);
        cosignEnabled = _enable;
        minCosigners = Math.max(1, _minCosigners);
    }

    function updateValueNameNCode(
        COLOR _idColor,
        bool _onlyTrustWorthyAuditors,
        bool _dataKeeperOnly,
        uint _maxUse,
        string memory _valueName, //agebt, age, agelt... 
        string memory _value //18
    ) external onlyAdmin {
        valueName = _valueName;   
        requiredIndentity = _value;
        minIDBadgeColor = _idColor;
        dataKeeperOnly = _dataKeeperOnly;
        maxUse = _maxUse;
        onlyTrustWorthyAuditors = _onlyTrustWorthyAuditors;
    }

    function updateTrustWorthyAuditors(address[] memory _gauges, bool _add) external onlyAdmin {
        for (uint i = 0; i < _gauges.length; i++) {
            if (_add) {
                trustWorthyAuditors.add(_gauges[i]);
            } else {
                trustWorthyAuditors.remove(_gauges[i]);
            }
        }
    }

    function getAllTrustWorthyAuditors(uint _start) external view returns(address[] memory _auditors) {
        _auditors = new address[](trustWorthyAuditors.length() - _start);
        for (uint i = _start; i < trustWorthyAuditors.length(); i++) {
            _auditors[i] = trustWorthyAuditors.at(i);
        }
    }

    function isTrustWorthyAuditor(address _auditor) public view returns(bool) {
        return trustWorthyAuditors.contains(_auditor);
    }

    function ssi() internal view returns(address) {
        return IContract(_contractAddress).ssi();
    }

    function auditorNote() internal view returns(address) {
        return IContract(_contractAddress).auditorNote();
    }

    function checkIdentityProof(address _owner, uint _identityTokenId, bool checkUnique) public {
        if (keccak256(abi.encodePacked(valueName)) != keccak256(abi.encodePacked(""))) {
            address _ssi = ssi();
            address _auditorNote = auditorNote();
            require(ve(_ssi).ownerOf(_identityTokenId) == _owner);
            SSIData memory metadata = ISSI(_ssi).getSSIData(_identityTokenId);
            require(metadata.deadline > block.timestamp);
            SSIData memory metadata2 = ISSI(_ssi).getSSID(metadata.senderProfileId);
            (address _gauge, bool _dataKeeper, COLOR _badgeColor) = IAuditor(_auditorNote).getGaugeNColor(metadata.auditorProfileId);
            (address _gauge2, bool _dataKeeper2, COLOR _badgeColor2) = IAuditor(_auditorNote).getGaugeNColor(metadata2.auditorProfileId);
            require(_badgeColor >= minIDBadgeColor && _badgeColor2 >= minIDBadgeColor);
            if (dataKeeperOnly) require(_dataKeeper && _dataKeeper2);
            require(keccak256(abi.encodePacked(metadata.question)) == keccak256(abi.encodePacked(valueName)));
            require(keccak256(abi.encodePacked(metadata.answer)) == keccak256(abi.encodePacked(requiredIndentity))); 
            require(!onlyTrustWorthyAuditors || (trustWorthyAuditors.contains(_gauge) && trustWorthyAuditors.contains(_gauge2)));
            require(!blackListedIdentities[keccak256(abi.encodePacked(metadata2.answer))]);
            if (maxUse > 0 && checkUnique) {
                require(keccak256(abi.encodePacked(metadata2.answer)) != keccak256(abi.encodePacked("")));
                require(identityProofs[keccak256(abi.encodePacked(metadata2.answer))] < maxUse);
            }
            identityProofs[keccak256(abi.encodePacked(metadata2.answer))] += 1;
            userToIdentityCode[metadata.senderProfileId] = keccak256(abi.encodePacked(metadata2.answer));
        }
    }

    function updateUserToIdentityCode(uint _senderProfileId, bytes32 _identityCode) external {
        require(msg.sender == helper);
        userToIdentityCode[_senderProfileId] = _identityCode;
    }

    function updateBlacklistedIdentities(uint[] memory userProfileIds, bool blacklist) external onlyAdmin {
        for (uint i = 0; i < userProfileIds.length; i++) {
            SSIData memory metadata2 = ISSI(ssi()).getSSID(userProfileIds[i]);
           if (keccak256(abi.encodePacked(metadata2.answer)) != keccak256(abi.encodePacked(""))) {
                blackListedIdentities[keccak256(abi.encodePacked(metadata2.answer))] = blacklist;
            }
        }
    }

    function updateDev(address _devaddr) external {
        require(msg.sender == devaddr_);
        devaddr_ = _devaddr;
    }
}

interface ISSI {
    function getSSIData(uint) external view returns(SSIData memory);
    function metadata(uint) external view returns(SSIData memory);
    function getSSID(uint) external view returns(SSIData memory);
    function referrer(uint) external view returns(uint);
}
interface IAuth {
    function isAdmin(address) external view returns(bool);
    function devaddr_() external view returns(address);
    function changeDouble(address,uint) external;
    function isAuthorized(uint,address) external view returns(bool);
    function checkIdentityProof(address,uint,bool) external;
}

interface IBallerFactory {
    function createBaller(uint, address, address, string memory, address, address) external returns(address);
}

interface IBaller2Factory {
    function createBaller(uint, string memory) external returns(address);
}

interface IBallerNFT {
    function totalSupply_() external view returns(uint);
    function getTicketDate(uint) external returns(uint);
    function getReceiver(uint) external view returns(address);
    function boostingPower(uint) external view returns(uint);
    function batchMint(address, uint256, uint256) external returns(uint256[] memory);
    function getTicketPrice(uint) external returns(uint);
    function getTicketOwner(uint) external returns(address);
    function burn(address , uint256, uint256) external;
    function withdrawTreasury() external;
    function updateDev(address) external;
}

interface IBallerNFT2 {
    function totalSupply_() external returns(uint);
    function getTicketDate(uint) external returns(uint);
    function getReceiver(uint) external returns(address);
    function boostingPower(uint) external view returns(uint);
    function batchMint(address, uint256, uint256, uint256) external returns(uint256[] memory);
    function getTicketPrice(uint) external returns(uint);
    function getTicketOwner(uint) external returns(address);
    function burn(address , uint256, uint256) external;
    function withdrawTreasury() external;
    function updateDev(address) external;
}

interface INFTicket {
    function getSponsorsMedia(uint,string memory) external view returns(string[] memory);
    function taskContracts(uint) external view returns(address);
    function isPaywall(uint) external view returns(uint);
    function getTicketOptions(uint256) external view returns(Option[] memory); 
    function getTicketPaywallOptions(uint256) external view returns(PaywallOption[] memory); 
    function cancanVote(address,string memory,uint,uint,address,uint[5] memory) external;
    function getTimeEstimates(bytes32,uint[] memory) external view returns(uint);
    function tokenURI(address,uint) external view returns(string memory);
    function transactionVolume(address) external view returns(uint);
    function userTokenId(uint) external view returns(uint);
    function identityTokenId(uint) external view returns(uint);
    function getUtility(address, uint) external view returns(address, uint);
    function getUserTicketsPagination(address, uint, uint, uint, string memory) 
    external view returns(uint[] memory, uint);
    function batchUpdateActive(
        address, address, uint256, uint256, bool) external returns(bool);
    function batchUpdateActive2(uint[] memory, bool) external returns(bool);
    function batchMint(address,uint,uint,uint,bytes32,uint[] memory) external;
    function mint(address,address,uint,string memory,uint[5] memory,uint[] memory,bool) external returns(uint);
    function getMerchantTicketsPagination(uint, uint, uint, string memory) 
    external view returns (uint[] memory, uint);
    function devaddr_() external view returns(address);
    function addSponsoredMessagesAdmin(uint, string memory) external;
    function getTicketOwner(uint) external view returns(address);
    function getReceiver(uint) external view returns(address);
    function updateDev(address) external;
    function getMerchantOfTicket(uint) external view returns(address);
    function getOwnerOfTicket(uint) external view returns(address);
    function getPriceOfTicket(uint) external view returns(uint);
    function ticketInfo_(uint) external view returns(TicketInfo memory);
    function safeMint(uint, string memory, address,address,uint,bytes memory,uint[] memory,bool) external;
    function updateAttach(uint,bool) external;
    function attached(uint) external view returns(bool);
    function attach(uint256,uint256,address) external;
    function getTicketInfo(uint) external view returns(TicketInfo memory);
}

interface IStakeMarketVoter {
    function isGauge(address,uint) external returns(bool);
    function createGauge(
        address,
        address,
        uint,
        uint,
        uint,
        string memory,
        string memory,
        string memory
    ) external;
}

interface IStakeMarket {
    function isStake(uint) external view returns(bool);
    function createStake(address[6] memory,string memory,string memory,uint[] memory,uint,uint,uint[7] memory,bool) external returns (uint);
    function createAndApply(address,uint[7] memory,uint,uint,uint,string memory) external;
    function isMarketPlace(address) external view returns(bool);
    function getAllPartners(uint,uint) external view returns(uint[] memory);
    function notes(uint) external view returns(uint,uint,uint,address);
    function checkIdentityProof(uint,uint,address) external;
    function claimRevenueFromNote(address,uint) external;
    function stakes(uint) external view returns(Stake memory);
    function getStake(uint) external view returns(Stake memory);
    function getOwner(uint) external view returns(address);
    function updateStakeFromVoter(uint, uint) external;
    function bufferTime() external view returns(uint);
    function tradingFee() external view returns(uint);
    function mintNote(uint, uint) external returns(uint);
    function getDueReceivable(uint,uint) external view returns(uint, uint, int);
    function getDuePayable(uint,uint) external view returns(uint, uint, int);
    function IOU(uint) external view returns(uint,uint,uint,string memory);
    function safeMint(address,uint) external returns(uint);
    function tokenId() external view returns(uint);
    function emitUpdateMiscellaneous(uint,uint,string memory,string memory,uint,uint,address,string memory) external;
    function tokenURI(uint) external view returns (string memory);
    function tokenURIiou(uint,uint,uint,uint,string memory) external view returns (string memory);
}

interface IVava {
    function token() external view returns(address);
    function _ve() external view returns(address);
    function devaddr_() external view returns(address);
    function treasuryShare() external view returns(uint);
    function epoch() external view returns(uint);
    function checkIdentityProof2(address, bool) external;
    function getQueue(uint) external view returns(uint[] memory);
    function maxWithdrawable() external view returns(uint);
    function callPending(uint) external view returns(uint);
    function notifyWithdraw(address, address, uint) external;
    function initialize(address, address) external;
    function schedulePurchase(address,address,address,string memory,uint[] memory,uint,uint,uint,uint,uint) external;
    function userInfo(uint) external view returns(uint, uint);
    function sponsors(uint) external view returns(uint, uint, uint, uint, uint, uint);
}

interface IVavaHelper {
    function marketPlace() external returns(address);
    function vavoter() external view returns(address);
    function nfticket() external view returns(address);
    function getChainID() external view returns (uint256);
    function maximumSize() external view returns (uint256);
    function randomGenerator_() external view returns(address);
    function getSupplyAvailable(address) external view returns(uint);
    function updateVava(address,address,address,string memory,string memory,bool,bool) external;
    function getUserPercentile(address, address, uint) external view returns(uint);
}

interface ILender {
    function addProtocol(address, address, uint) external;
    function withdrawFromBalance(address, address, uint) external;
}

interface IPaymentContract {
    function createStake(
        address, 
        address, 
        string memory, 
        address, 
        uint256, 
        uint256, 
        uint256, 
        uint256, 
        uint256,
        string memory) external;
}

interface IPaymentContractNFT {
    function createStake(
        address, 
        address, 
        string memory, 
        address, 
        uint256, 
        uint256, 
        uint256,
        string memory) external;
}

interface INFTicketFactory {
    function createNFTicket(address, string memory) external returns(address);
}

interface IdentityProofPayment {
    function createBalance(address, address, uint) external;
}

interface INoteEmitter {
    function pendingRevenueFromNote(uint) external returns(uint);
}

interface ILottery {
    function withdrawPendingReward(address,uint,uint) external;
    function getAllTokens(uint,uint) external view returns(address[] memory);
    function getPercentile(address,address,uint,uint) external view returns(uint,uint,uint);
    function startLottery(address,address,uint256,uint256,uint256,uint256,uint256,uint256,bool,uint256[4] calldata,uint256[6] calldata) external;
    function checkIdentity(address,address,uint,uint,uint[] calldata) external returns(uint,uint);
    function getRandomNumber(uint256) external;
    function viewRandomResult(uint) external view returns (uint);
    function paymentCredits(address,uint) external view returns(uint);
    function decreasePaymentCredits(address,uint,uint) external;
    function deletePaymentCredits(address,uint) external;
    function collectionIdToLotteryId(uint) external view returns(uint);
    function getUserTicketIdsPerLotteryId(address,uint) external view returns(uint[] memory);
    function treasuryFee() external view returns(uint);
    function minDiscountDivisor() external view returns(uint);
    function currentLotteryId() external view returns(uint);
    function viewTicket(uint) external view returns(Ticket memory);
    function viewLottery(uint) external view returns(Lottery memory);
    function viewBracketCalculator(uint) external view returns(uint);
    function tokenPerBracket(uint,address,uint) external view returns(uint);
    function calculateRewardsForTicketId(uint,uint,uint,address) external view returns (uint256);
}

interface IValuePool {
    function pickRank() external;
    function claimRank() external;
    function updateEpoch(uint) external;
    function updateSlope(uint,int128) external;
    function percentile(uint,uint,uint,uint) external view returns(uint,uint);
    function checkpoint(uint,uint,LockedBalance memory,LockedBalance memory) external returns(Point memory);
    function updatePointHistory(uint,Point memory) external;
    function slope_changes(uint) external view returns(int128);
    function point_history(uint) external view returns(Point memory);
    function supply_at(Point memory,uint) external view returns (uint);
    function verifyCardId(uint) external view returns(bool);
    function collectionId(address) external view returns(uint);
    function isGauge(address) external view returns(bool);
    function getRandomNumber(uint256) external;
    function create_lock_for(uint,uint,uint,address) external returns (uint);
    function getMedia(address,uint) external view returns(string[] memory);
    function getDescription(address) external view returns(string[] memory);
    function constructTokenURI(uint,address,string[] memory,string[] memory,string[] memory) external view returns(string memory);
    function getOptions(address,uint,uint,uint,uint) external view returns(string[] memory,string[] memory);
    function getAllSponsors(uint,uint,bool) external view returns(address[] memory);
    function isPayingSponsor(address) external view returns(bool);
    function media(address,address) external view returns(string memory);
    function userInfo(uint) external view returns(uint, uint);
    function riskpool() external view returns(bool);
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
    function totalDebits(uint) external view returns(uint);
    function totalCredits(uint) external view returns(uint);
    function getUserPercentile(address,uint) external view returns(uint);
    function checkContains(bool,address,address,address) external;
    function treasuryShare() external view returns(uint);
    function getSupplyAvailable(address) external view returns(uint);
    function getMarketPlace() external view returns(address);
    function checkIdentityProof(address,address,uint) external;
    function getBalance(address,address) external view returns(uint);
    function merchantValueName() external view returns(string memory);
    function merchantDataKeeperOnly() external view returns(bool);
    function merchantMinIDBadgeColor() external view returns(COLOR);
    function onlyTrustWorthyAuditors() external view returns(bool);
    function onlyTrustWorthyMerchants() external view returns(bool);
    function merchantRequiredIndentity() external view returns(string memory);
    function epoch() external view returns(uint);
    function _ve() external view returns(address);
    function token() external view returns(address);
    function latestTokenId() external view returns(uint);
    function fulfilled(uint) external view returns(uint);
    function viewRandomResult(uint) external view returns(uint32);
    function randomGenerators(address) external view returns(address);
    function emitInitialize(address) external;
    function updateVa() external;
    function updateVava(address,address,address,address,bool,bool) external;
    function emitUpdateParameters(bool,uint,uint,uint,uint,uint,uint,uint) external;
    function claimReward(uint, string memory, address, address) external;
    function addInvoiceFromFactory(address, int, string memory) external;
    function updateCartItems(string memory) external;
    function reimburseLoan(uint) external;
    function deposit(uint) external;
    function withdraw(uint) external;
    function notifyLoan(address, address, uint) external;
    function notifyReimbursement(address, uint) external;
    function isMicroLender(address) external view returns(bool);
    function emitNotifyLoan(address,address,uint) external;
    function emitNotifyReimbursement(address,address,uint,bool) external;
    function emitNotifyPayment(address,uint,uint) external;
    function emitAddSponsor(address,uint,uint,uint) external;
    function emitRemoveSponsor(address) external;
    function emitExecuteNextPurchase(address,uint,uint,uint) external;
    function emitWithdraw(address,uint,uint,uint,uint) external;
    function emitAddCredit(address,uint,uint) external;
    function emitUpdateMinimumBalance(address,uint,uint) external;
    function emitDeleteMinimumBalance(address,uint,uint) external;
    function emitSupply(address,uint,uint) external;
    function emitDeposit(address,address,uint,uint,uint,DepositType,uint) external;
    function emitTransfer(address,address,uint) external;
    function emitApproval(address,address,uint) external;
    function emitApprovalForAll(address,address,bool) external;
    function emitSetParams(address,string memory,string memory,uint8,uint,uint,uint) external;
    function emitSwitch(address) external;
    function tokenURI(address,uint,uint,uint,uint) external pure returns(string memory);
    function balanceOfNFT(uint) external view returns(uint);
    function getParams() external view returns(uint,uint,uint,uint,uint);
    function tradingFee() external view returns(uint);
    function contractAddress() external view returns(address);
}

interface ISubscriptionFactory {
    function channelSubCount(address) external view returns(uint);
}

interface ISubscriptionNFT {
    function mint(address, address, uint, string memory) external returns(uint);
    function getSubSpecs(uint) external view returns(address,uint, string memory);
    function getReceiver(uint) external view returns(address);
    function getChannelTickets(address) external view returns(uint[] memory);
    function fundLottery(address) external returns(uint);
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

struct Point {
    int128 bias;
    int128 slope; // # -dweight / dt
    uint ts;
    uint blk; // block
}
/* We cannot really do block numbers per se b/c slope is per time, not per block
* and per block could be fairly bad b/c Ethereum changes blocktimes.
* What we can do is to extrapolate ***At functions */

struct LockedBalance {
    int128 amount;
    uint end;
}

interface IContentFarmFactory {
    function createGauge(
        address _ve,
        uint _tokenId, 
        string calldata _video_cid,
        string calldata _creative_cid,
        string calldata _cancan_email,
        string calldata _website_link
    ) external returns (address);
}

interface IContentFarm {
    function notifyRewardAmount(address token, uint amount) external;
    function getReward(address account, address[] memory tokens) external;
}

interface IContent {
    function contains(string memory) external view returns(bool);
    function indexToName(uint) external view returns(string memory);
}

interface IMicroLender {
    function initialize(address, bool) external;
    function profileRequired() external view returns(bool);
    function collateralInfo(uint) external view returns(uint);
}

interface vaVoter {
    function getBalance(address,address,address) external view returns(uint);
    function minimumLockValue(address) external view returns(uint);
}

interface IARP {
    function attach(uint) external;
    function detach(uint) external;
    function protocolInfo(uint) external view returns(ARPInfo memory);
    function percentiles(address) external view returns(uint);
    function getMedia(address,uint) external view returns(string[] memory);
    function collectionId() external view returns(uint);
    function getReceivable(uint,uint) external view returns(uint,uint);
    function autoCharge(uint[] memory,uint) external;
    function getUserPercentile(address,uint) external view returns(uint);
    function cap(address) external view returns(uint);
    function adminCreditShare() external view returns(uint);
    function adminDebitShare() external view returns(uint);
    function notifyRewardAmount(address,address,uint) external;
    function updatePendingRevenueFromNote(uint, uint) external;
    function tokenURI(uint) external view returns(string memory);
    function uriGenerator(address) external view returns(address);
    function tokenIdToARP(uint) external view returns(address,uint);
    function tokenIdToParent(uint) external view returns(uint);
    function updateTreasuryFees(address,uint) external;
    function minAdminPeriod() external view returns(uint);
    function minAdminBounty() external view returns(uint);
    function emitTransferDueToNote(address,uint,uint,uint,bool) external;
    function emitClaimTransferNote(uint) external;
    function emitVoted(address,uint,uint,uint,bool) external;
    function updateProfile(uint,address) external;
    function notifyReward(address,uint) external;
    function safeTransferWithBountyCheck(address,address,uint,uint) external;
    function adminNotes(uint) external view returns(uint);
    function mint(address) external returns(uint);
    function burn(uint) external;
    function getGaugeNColor(uint) external view returns(address,COLOR);
    function tradingFee(bool) external view returns(uint);
    function notifyFees(address,uint) external;
    function media(uint) external view returns(string memory);
    function description(uint) external view returns(string memory);
    function emitUpdateMiscellaneous(uint,uint,string memory,string memory,uint,uint,address,string memory) external;
    function percentages() external view returns(bool);
    function automatic() external view returns(bool);    
    function reward(address) external view returns(uint);
    function debt(address) external view returns(uint);
    function getProfileId(address) external view returns(uint);
    function isGauge(address) external view returns(bool);
    function percentile(address) external view returns(uint);
    function updateTradingFee(uint) external;
    function devaddr_() external view returns(address);
    function _ve() external view returns(address);
    function uri(uint) external view returns(string memory);
    function isLender(address,address,uint,uint) external view returns(bool);
    function valuepool() external view returns(address);
    function token() external view returns(address);
    function getToken(address) external view returns(address);
    function payInvoicePayable(address, address, uint) external;
    function addProtocol(address, address, uint, uint, uint, uint, uint, uint, uint, uint, uint, string memory) external;
    function updateProtocol(address, address, uint, uint, uint, uint, uint, uint, uint, uint, uint, string memory) external;
    function getDueReceivable(address, uint, uint) external view returns(uint, uint, int);
    function getDuePayable(address, uint, uint) external view returns(uint, uint, int);
    function updatePaidPayable(uint, uint) external;
    function addressToProtocolId(address) external view returns(uint);
    // function protocolInfo(uint) external view returns(address,uint,uint,uint,uint,uint,uint,uint,uint,uint,uint,uint);
    function maxNotesPerProtocol() external view returns(uint);
    function bountyRequired() external view returns(uint);
    function adminBountyId(address) external view returns(uint);
    function bufferTime() external view returns(uint);
    function limitFactor() external view returns(uint);
    function updateAutoPaidPayable(uint, uint) external;
    function updateProtocolShares(uint, uint) external;
    function noteWithdraw(address,address,uint) external;
    function updateBalances() external;
    function updateBalanceOf(address, uint) external;
    function updateGauge(address,address,uint) external;
    function balanceOf(uint) external view returns(uint);
    function notes(uint) external view returns(uint,uint,uint,address,address);
    function profileRequired() external view returns(bool);
    function adminBountyRequired() external view returns(uint);
    function userBountyRequired(uint) external view returns(uint);
    function period() external view returns(uint);
    function emitUpdateProtocol(uint,uint,address,address,string memory,string memory) external;
    function emitUpdateAutoCharge(uint,bool) external;
    function emitAutoCharge(address,uint,uint) external;
    function emitPayInvoicePayable(uint,uint) external;
    function emitDeleteProtocol(uint) external;
    function emitWithdraw(address,uint) external;
    function emitNotifyReward(address,uint) external;
}

interface IBetting {
    function checkMembership(address) external;
    function addressToProfileId(address) external view returns(uint);
    function pricePerAttachMinutes(uint) external view returns(uint);
    function updateSponsorMedia(uint,string memory) external;
    function emitAddSponsor(uint,uint,address,string memory,string memory) external;
    function updatePaymentCredits(address,address,uint) external;
    function processFees(address,address,address,uint,uint,uint) external;
    function getToken(uint) external view returns(address);
    function media(uint) external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
    function tickets(uint) external view returns(uint,uint,uint,uint,uint,bool,address);
    function emitTicketsClaim(address,uint,uint,uint) external;
    function emitTicketsPurchase(address,uint,uint,uint,uint,uint) external;
    function emitBettingResultsIn(uint,uint,address,uint) external;
    function emitInjectFunds(address,uint,uint,uint) external;
    function maxAdminShare() external view returns(uint);
    function buyWithContract(uint,address,address,uint,uint,uint[] calldata) external;
    function collectionId() external view returns(uint);
    function tokenURI(uint) external view returns(string memory);
    function uriGenerator(address) external view returns(address);
    function tokenIdToBetting(uint) external view returns(address);
    function tokenIdToParent(uint) external view returns(uint);
    function updateTreasuryFees(address,uint) external;
    function minAdminPeriod() external view returns(uint);
    function minAdminBounty() external view returns(uint);
    function emitTransferDueToNote(address,uint,uint,uint,bool) external;
    function emitClaimTransferNote(uint) external;
    function updateProfile(uint,address) external;
    function mint(address) external returns(uint);
    function burn(uint) external;
    function getGaugeNColor(uint) external view returns(address,COLOR);
    function tradingFee() external view returns(uint);
    function notifyFees(address,uint) external;
    function description(uint) external view returns(string memory);
    function emitUpdateMiscellaneous(uint,uint,string memory,string memory,uint,uint,address,string memory) external;
    function isGauge(address) external view returns(bool);
    function updateTradingFee(uint) external;
    function devaddr_() external view returns(address);
    function uri(uint) external view returns(string memory);
    function token() external view returns(address);
    function updateProtocol(address, address, uint, uint, uint, uint, uint, uint, uint, uint, uint, string memory) external;
    function addressToProtocolId(address) external view returns(uint);
    function protocolInfo(uint) external view returns(address,string memory,uint,uint,uint,uint,uint,uint,uint,uint[] memory,uint[] memory);
    function updateGauge(address,address,uint) external;
    function emitUpdateProtocol(uint,uint,address,string memory,uint[5] memory,uint[] memory,string memory,string memory,string memory) external;
    function emitDeleteProtocol(uint) external;
    function emitWithdraw(address,address,uint) external;
    function emitCloseBetting(uint,uint) external;
    function getMedia(uint) external view returns(string[] memory);
    function subjectsLength(uint) external view returns(uint);
    function subjects(uint) external view returns(string memory);
    function getAction(uint) external view returns(string memory);
    function getExcludedContents(uint,string memory) external view returns(string[] memory);
}

interface IARPHelper {
    function profile() external view returns(address);
    function trustBounty() external view returns(address);
    function tradingFee() external view returns(uint);
    function updateGauge(address,address,uint,string memory,string memory) external;
    function notes(address, uint) external view returns(uint,uint,uint,address);
    function adminNotes(address, address) external view returns(uint);
    function updateDue(uint, uint) external;
    function updatePendingRevenueFromNote(uint, uint) external;
    function _safeTransfer(address, address, uint) external;
    function _safeTransferFrom(address, address, address, uint) external;
    function getDuePayable(address, address, uint) external view returns(uint,uint,int);
    function getDueReceivable(address, address, uint) external view returns(uint,uint,int);
}

interface IARPFactory {
    function addInvoiceFromFactory(address, int, string memory) external;
}

interface IGameFactory {
    function sponsorGame(address, address, uint) external;
}

interface IInvoiceNFT {
    function mintToBatch(address, address[] memory, uint[] memory) external
    returns(uint256[] memory);
}

interface IVoter {
    function notifyRewardAmount(uint amount) external;
    function totalWeight(address) external view returns(uint);
}

interface ve_dist {
    function checkpoint_token() external;
    function checkpoint_total_supply() external;
}

interface IAuditor {
    function attach(uint) external;
    function detach(uint) external;
    function getMedia(uint) external view returns(string[] memory);
    function ratingLegendLength(address) external view returns(uint);
    function ratingLegend(address,uint) external view returns(string memory);
    function collectionId() external view returns(uint);
    function autoCharge(uint[] memory,uint) external;
    function tokenURI(uint,uint,uint,uint,address) external view returns (string memory);
    function getReceivable(uint,uint) external view returns(uint,uint);
    function getOptions(address,uint) external view returns(string[] memory,string[] memory);
    function tokenIdToAuditor(uint) external view returns(address,uint);
    function categories(address) external view returns(uint);
    function profileCategories(uint) external view returns(uint);
    function description(uint) external view returns(string memory);
    function updateDue(uint, uint) external;
    function media(uint) external view returns(string memory);
    function emitUpdateMiscellaneous(uint,uint,string memory,string memory,uint,uint,address,string memory) external;
    function tradingFee() external view returns(uint);
    function updatePendingRevenueFromNote(uint, uint) external;
    function notes(uint) external view returns(uint,uint,uint,address,address);
    function adminNotes(uint) external view returns(uint);
    function getDueReceivable(address, uint, uint) external view returns(uint,uint,int);
    function withdrawFees(address) external returns(uint);
    function notifyFees(address,uint) external;
    function addressToProtocolId(address) external view returns(uint);
    function auditorNote() external view returns(address);
    function uriGenerator() external view returns(address);
    function uri(uint) external view returns(string memory);
    function mint(address) external returns(uint);
    function isGauge(address) external returns(bool);
    function burn(uint) external;
    function getGaugeNColor(uint) external view returns(address,bool,COLOR);
    function noteWithdraw(address,uint,uint) external;
    function minBountyPercent() external view returns(uint);
    function trustBounty() external view returns(address);
    function nativeCoin() external view returns(address);
    function emitWithdraw(address,uint) external;
    function emitDeleteProtocol(uint) external;
    function emitAutoCharge(address,uint,uint) external;
    function emitPayInvoicePayable(uint,uint) external;
    function emitUpdateAutoCharge(uint,bool) external;
    function updateGauge(address,address,uint) external;
    function emitUpdateProtocol(uint,uint[] memory,uint,address,string memory,string memory) external;
    function protocolInfo(uint) external view returns(address,uint,uint,uint,uint,uint,uint,uint);
    function getProtocolRatings(uint) external view returns(uint[] memory);
    function addressToProfileId(address) external view returns(uint);
}

interface ISponsor {
    function attach(uint) external;
    function detach(uint) external;
    function emitUpdateContents(string memory,bool) external;
    function tradingFee() external view returns(uint);
    function noteWithdraw(address,address,uint) external;
    function updatePaidPayable(address,uint) external;
    function maxNotesPerProtocol() external view returns(uint);
    function contentContainsAny(string[] memory) external view returns(bool);
    function protocolInfo(uint) external view returns(address,address,uint,uint,uint,uint,uint,uint);
    function emitUpdateProtocol(uint,address,string memory,string memory) external;
    function addressToProtocolId(address) external view returns(uint);
    function notes(address,uint) external view returns(uint,uint,uint,address);
    function getDuePayable(address, address, uint) external view returns(uint,uint,int);
    function minBountyPercent() external view returns(uint);
    function emitPayInvoicePayable(uint,uint) external;
    function emitDeleteProtocol(uint) external;
    function emitWithdraw(address,uint) external;
    function updateGauge(address,address,uint) external;
}

interface IWorld {
    function getOptions(uint,uint) external view returns(string[] memory,string[] memory);
    function constructTokenURI(address,address,uint,uint,string[] memory,string[] memory) external view returns(string memory);
    function autoCharge(uint[] memory,uint) external;
    function attach(uint) external;
    function detach(uint) external;
    function getReceivable(uint,uint) external view returns(uint,uint);
    function attach(uint,address) external;
    function detach(uint,address) external;
    function safeMint(address,uint) external;
    function noteTokenURI(uint) external view returns(string memory);
    function getMedia(uint) external view returns(string[] memory);
    function tokenIdToWorld(uint) external view returns(address);
    function timeframe() external view returns(uint);
    function transferNFT(address,address,uint) external;
    function setColor(address,address,uint,string memory) external;
    function getRating(uint,uint,address) external view returns(uint);
    function minColor() external view returns(COLOR);
    function codeInfo(uint) external view returns(address,uint,uint,uint,uint,string memory,string memory,string memory,COLOR,WorldType);
    function pricePerAttachMinutes(uint) external view returns(uint);
    function registeredTo(WorldType,string memory) external view returns(uint);
    function newMint(address,address,uint,uint,uint,string memory,string memory,string memory) external;
    function toString(uint) external view returns(string memory);
    function getWorldType(address) external view returns(WorldType);
    function getCodes(address,string[4] memory,string[4] memory) external returns(string memory,string memory);
    function addressToProtocolId(address) external view returns(uint);
    function getExcludedContents(uint,string memory) external view returns(string[] memory);
    function maxNumMedia() external view returns(uint);
    function minBountyPercent() external view returns(uint);
    function worldToProfileId(address) external view returns(uint);
    function updateWorld(uint[] memory) external;
    function emitMint(uint,address,address,uint,uint,string memory,string memory,string memory) external;
    function emitTransfer(uint,address) external;
    function decimals() external view returns(uint8);
    function totalSupply() external view returns(uint);
    function notifyCredit(address, uint) external;
    function emitNotifyCredit(uint,uint,uint) external;
    function emitNotifyDebit(uint,uint,uint) external;
    function notifyCreditFromUser(address, uint) external;
    function notifyDebit(address, uint) external;
    function getDueReceivable(address,uint,uint) external view returns(uint, uint, int);
    function getDuePayable(address,uint,uint) external view returns(uint, uint, int);
    function updatePendingRevenueFromNote(uint, uint) external;
    function tradingFee() external view returns(uint);
    function period() external view returns(uint);
    function bufferTime() external view returns(uint);
    function adminBountyRequired() external view returns(uint);
    function adminBountyId(address) external view returns(uint);
    function userBountyRequired(uint) external view returns(uint);
    function maxNotesPerProtocol() external view returns(uint);
    function adminNotes(address,uint) external view returns(uint);
    function notes(uint) external view returns(uint,uint,uint,address,address);
    function notifyFees(address,uint) external;
    function tokenIdToBILL(uint) external view returns(address,uint);
    function tokenIdToParent(uint) external view returns(uint);
    function media(uint) external view returns(string memory);
    function description(uint) external view returns(string memory);
    function updateGauge(address,address,uint) external;
    function mint(address) external returns(uint);
    function burn(uint) external returns(uint);
    function updatePaidPayable(uint,uint) external;
    function updateTreasuryFees(address,uint) external;
    function emitUpdateProtocol(uint,uint,address,address,string memory,string memory) external;
    function emitUpdateAutoCharge(uint,bool) external;
    function emitDeleteProtocol(uint) external;
    function emitAutoCharge(address,uint,uint) external;
    function emitClaimTransferNote(uint) external;
    function emitPayInvoicePayable(uint,uint) external;
    function emitWithdraw(address,uint) external;
    function emitVoted(address,uint,uint,bool) external;
    function emitTransferDueToNote(address,uint,uint,uint,bool) external;
    function uriGenerator() external view returns(address);
    function uri(uint) external view returns(string memory);
    function isGauge(address) external view returns(bool);
    function tokenURI(uint) external view returns(string memory);
    function getName(address) external view returns(string memory);
    function getDescription(uint) external view returns(string[] memory);
    function getToken(address) external view returns(address);
    function protocolInfo(uint) external view returns(address,address,uint,uint,uint,uint,uint,uint,uint);
    function safeTransferWithBountyCheck(address,address,uint,uint) external;
    function noteWithdraw(address,uint,uint) external;
    function emitUpdateMiscellaneous(uint,uint,string memory,string memory,uint,uint,address,string memory) external;
    function getGaugeNColor(uint,WorldType) external view returns(address,COLOR);
}

interface IRouter {
    function getAmountsOut(uint256,address[] memory) external view returns (uint256[] memory);
}

interface IRandomNumberGenerator {
    /**
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(uint256 _seed) external;

    /**
     * View latest lotteryId numbers
     */
    function viewLatestLotteryId() external view returns (uint256);

    /**
     * Views random result
     */
    function viewRandomResult() external view returns (uint32);
}

interface IPancakeSwapLottery {
    /**
     * @notice Buy tickets for the current lottery
     * @param _lotteryId: lotteryId
     * @param _ticketNumbers: array of ticket numbers between 1,000,000 and 1,999,999
     * @dev Callable by users
     */
    function buyTickets(uint256 _lotteryId, uint32[] calldata _ticketNumbers) external;

    /**
     * @notice Claim a set of winning tickets for a lottery
     * @param _lotteryId: lottery id
     * @param _ticketIds: array of ticket ids
     * @param _brackets: array of brackets for the ticket ids
     * @dev Callable by users only, not contract!
     */
    function claimTickets(
        uint256 _lotteryId,
        uint256[] calldata _ticketIds,
        uint32[] calldata _brackets
    ) external;

    /**
     * @notice Close lottery
     * @param _lotteryId: lottery id
     * @dev Callable by operator
     */
    function closeLottery(uint256 _lotteryId) external;

    /**
     * @notice Draw the final number, calculate reward in CAKE per group, and make lottery claimable
     * @param _lotteryId: lottery id
     * @param _autoInjection: reinjects funds into next lottery (vs. withdrawing all)
     * @dev Callable by operator
     */
    function drawFinalNumberAndMakeLotteryClaimable(uint256 _lotteryId, bool _autoInjection) external;

    /**
     * @notice Inject funds
     * @param _lotteryId: lottery id
     * @param _amount: amount to inject in CAKE token
     * @dev Callable by operator
     */
    function injectFunds(uint256 _lotteryId, uint256 _amount) external;

    /**
     * @notice Start the lottery
     * @dev Callable by operator
     * @param _endTime: endTime of the lottery
     * @param _priceTicketInCake: price of a ticket in CAKE
     * @param _discountDivisor: the divisor to calculate the discount magnitude for bulks
     * @param _rewardsBreakdown: breakdown of rewards per bracket (must sum to 10,000)
     * @param _treasuryFee: treasury fee (10,000 = 100%, 100 = 1%)
     */
    function startLottery(
        uint256 _endTime,
        uint256 _priceTicketInCake,
        uint256 _discountDivisor,
        uint256[6] calldata _rewardsBreakdown,
        uint256 _treasuryFee
    ) external;

    /**
     * @notice View current lottery id
     */
    function viewCurrentLotteryId() external returns (uint256);

    /**
     * @notice View user ticket ids, numbers, and statuses of user for a given lottery
     * @param _user: user address
     * @param _lotteryId: lottery id
     * @param _cursor: cursor to start where to retrieve the tickets
     * @param _size: the number of tickets to retrieve
     */
    function viewUserInfoForLotteryId(
        address _user,
        uint256 _lotteryId,
        uint256 _cursor,
        uint256 _size
    )
        external
        view
        returns (
            uint256[] memory,
            uint32[] memory,
            bool[] memory,
            uint256
        );
}

interface IWill {
    function notifyNFTFees(address) external;
    function emitUpdateProtocol(uint,address,string memory,string memory,address[] memory,uint[] memory) external;
    function tradingNFTFee() external view returns(uint);
    function emitUpdateParameters(uint,uint,uint,uint,uint) external;
    function emitAddBalance(address,uint,NFTYPE) external;
    function emitRemoveBalance(address,uint,NFTYPE) external;
    function getProtocolInfo(uint,uint,uint) external view returns(bool,uint,address,uint,address[] memory,uint[] memory,string memory,string memory);
    function unlocked() external view returns(bool);
    function noteWithdraw(address,address,uint) external;
    function tokenType(address) external view returns(NFTYPE);
    function updateGauge(address) external;
    function isGauge(address) external view returns(bool);
    function addBalance(uint[] memory,uint,NFTYPE) external;
    function tradingFee(bool) external view returns(uint);
    function notifyFees(address,uint) external;
    function emitPayInvoicePayable(uint) external;
    function emitStartWillWithdrawalCountDown(uint) external;
    function updatePercentage(uint,uint,uint,uint) external;
}


interface IContract {
    function badgeNft() external view returns(address);
    function lotteryAddress() external view returns(address);
    function marketOrders() external view returns(address);
    function marketPlaceEvents() external view returns(address);
    function marketCollections() external view returns(address);
    function profileHelper() external view returns(address);
    function marketTrades() external view returns(address);
    function paywallMarketOrders() external view returns(address);
    function paywallMarketTrades() external view returns(address);
    function paywallMarketHelpers() external view returns(address);
    function paywallMarketHelpers2() external view returns(address);
    function paywallMarketHelpers3() external view returns(address);
    function nftMarketOrders() external view returns(address);
    function nftMarketTrades() external view returns(address);
    function nftMarketHelpers() external view returns(address);
    function nftMarketHelpers2() external view returns(address);
    function nftMarketHelpers3() external view returns(address);
    function paywallARPHelper() external view returns(address);
    function paywallARPFactory() external view returns(address);
    function marketHelpers() external view returns(address);
    function marketHelpers2() external view returns(address);
    function marketHelpers3() external view returns(address);
    function trustBounty() external view returns(address);
    function profile() external view returns(address);
    function ssi() external view returns(address);
    function poolGauge() external view returns(address);
    function businessVoter() external view returns(address);
    function referralVoter() external view returns(address);
    function acceleratorVoter() external view returns(address);
    function contributorVoter() external view returns(address);
    function nfticket() external view returns(address);
    function nfticketHelper() external view returns(address);
    function nfticketHelper2() external view returns(address);
    function businessMinter() external view returns(address);
    function stakeMarketNote() external view returns(address);
    function stakeMarketVoter() external view returns(address);
    function stakeMarket() external view returns(address);
    function stakeMarketHelper() external view returns(address);
    function stakeMarketBribe() external view returns(address);
    function veFactory() external view returns(address);
    function valuepoolVoter() external view returns(address);
    function valuepoolHelper() external view returns(address);
    function valuepoolHelper2() external view returns(address);
    function valuepoolFactory() external view returns(address);
    function token() external view returns(address);
    function vrfCoordinator() external view returns(address);
    function linkToken() external view returns(address);
    function lenderFactory() external view returns(address);
    function sponsorFactory() external view returns(address);
    function sponsorNote() external view returns(address);
    function auditorNote() external view returns(address);
    function auditorHelper() external view returns(address);
    function auditorHelper2() external view returns(address);
    function auditorFactory() external view returns(address);
    function businessBribeFactory() external view returns(address);
    function businessGaugeFactory() external view returns(address);
    function referralBribeFactory() external view returns(address);
    function minterFactory() external view returns(address);
    function nftSvg() external view returns(address);
    function lotteryHelper() external view returns(address);
    function veValuepool(address) external view returns(address);
    function trustBountyHelper() external view returns(address);
    function trustBountyVoter() external view returns(address);
    function arpNote() external view returns(address);
    function arpHelper() external view returns(address);
    function arpMinter() external view returns(address);
    function arpFactory() external view returns(address);
    function gameMinter() external view returns(address);
    function gameHelper() external view returns(address);
    function gameHelper2() external view returns(address);
    function gameFactory() external view returns(address);
    function billNote() external view returns(address);
    function billMinter() external view returns(address);
    function billHelper() external view returns(address);
    function billFactory() external view returns(address);
    function worldNote() external view returns(address);
    function worldHelper() external view returns(address);
    function worldHelper2() external view returns(address);
    function worldHelper3() external view returns(address);
    function worldFactory() external view returns(address);
    function willFactory() external view returns(address);
    function willNote() external view returns(address);
    function rampFactory() external view returns(address);
    function rampHelper() external view returns(address);
    function rampHelper2() external view returns(address);
    function rampAds() external view returns(address); 
    function bettingFactory() external view returns(address);
    function bettingHelper() external view returns(address);
    function bettingMinter() external view returns(address);
    function cap(address) external view returns(uint);
    function maxMessage() external view returns(uint);
    function maximumSize() external view returns(uint);
    function minSuperChat() external view returns(uint);
    function adminShare() external view returns(uint);
    function valuepoolShare() external view returns(uint);
    function contains(string memory) external view returns(bool);
    function indexToName(uint) external view returns(string memory);
}
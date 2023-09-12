// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;
// pragma experimental ABIEncoderV2;


// uint256 constant MAX_VAL = type(uint256).max;

// // reverts on overflow
// function safeAdd(uint256 x, uint256 y) pure returns (uint256) {
//     return x + y;
// }

// // does not revert on overflow
// function unsafeAdd(uint256 x, uint256 y) pure returns (uint256) { unchecked {
//     return x + y;
// }}

// // does not revert on overflow
// function unsafeSub(uint256 x, uint256 y) pure returns (uint256) { unchecked {
//     return x - y;
// }}

// // does not revert on overflow
// function unsafeMul(uint256 x, uint256 y) pure returns (uint256) { unchecked {
//     return x * y;
// }}

// // does not overflow
// function mulModMax(uint256 x, uint256 y) pure returns (uint256) { unchecked {
//     return mulmod(x, y, MAX_VAL);
// }}

// // does not overflow
// function mulMod(uint256 x, uint256 y, uint256 z) pure returns (uint256) { unchecked {
//     return mulmod(x, y, z);
// }}

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

// interface ve {
//     function token() external view returns (address);
//     function balanceOfNFT(uint) external view returns (uint);
//     function isApprovedOrOwner(address, uint) external view returns (bool);
//     function ownerOf(uint) external view returns (address);
//     function transferFrom(address, address, uint) external;
// }

// interface erc20 {
//     function totalSupply() external view returns (uint256);
//     function transfer(address recipient, uint amount) external returns (bool);
//     function balanceOf(address) external view returns (uint);
//     function transferFrom(address sender, address recipient, uint amount) external returns (bool);
//     function approve(address spender, uint value) external returns (bool);
// }

// interface IGameNFT {
//     function updateDev(address) external;
//     function deleteObjects(uint) external;
//     function burn(address,uint,uint) external;
//     function deleteObject(uint, uint) external;
//     function getGamePrice(uint) external returns(uint);
//     function getQ2() external view returns(uint);
//     function updatePricePercentile(uint, uint) external;
//     function getReceiver(uint) external view returns(address);
//     function getTicketOwner(uint) external view returns(address);
//     function getTicketLender(uint) external view returns(address);
//     function updateScoreNDeadline(uint, uint, uint) external;
//     function updateObjects(uint, uint[] memory, bool) external;
//     function batchMint(address, uint256) external returns(uint256[] memory);
//     function updateScorePercentile(uint, uint, uint, uint, uint) external returns(uint);
//     function updateGameContract(uint, address, address, uint, uint, uint, bool) external;
//     function getGameSpecs(uint) external returns(address,uint,uint,uint,uint,uint,uint[] memory);
// }

// interface IGemNFT {
//     function getReceiver(uint) external view returns(address);
//     function getTicketOwner(uint) external view returns(address);
//     function getTicketLender(uint) external view returns(address);
//     function getTicketCarat(uint) external view returns(uint);
//     function getTicketType(uint) external view returns(uint);
//     function getTicketClarity(uint) external view returns(uint);
// }

// interface IDiamondNFT {
//     function getReceiver(uint) external view returns(address);
//     function getTicketOwner(uint) external view returns(address);
//     function getTicketLender(uint) external view returns(address);
//     function getTicketCarat(uint) external view returns(uint);
//     function getTicketColor(uint) external view returns(uint);
//     function getTicketClarity(uint) external view returns(uint);
// }

// interface INaturalResourceNFT {
//     function attached(uint) external returns(bool);
//     function detach(uint) external;
//     function attach(uint256, uint256, address) external; 
//     function batchDetach(uint256[] memory) external;
//     function getReceiver(uint) external view returns(address);
//     function getTicketOwner(uint) external view returns(address);
//     function getTicketLender(uint) external view returns(address);
//     function getTicketCarat(uint) external view returns(uint);
//     function getTicketPPM(uint) external view returns(uint);
//     function batchAttach(uint256[] memory, uint256, address) external; 
//     function getTicketResource(uint) external view returns(string memory);
//     function safeTransferNAttach(
//         address,
//         uint,
//         address,
//         address,
//         uint256,
//         uint256,
//         bytes memory) external;
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
//  * @dev Collection of functions related to the address type
//  */
// library Address {
//     /**
//      * @dev Returns true if `account` is a contract.
//      *
//      * [IMPORTANT]
//      * ====
//      * It is unsafe to assume that an address for which this function returns
//      * false is an externally-owned account (EOA) and not a contract.
//      *
//      * Among others, `isContract` will return false for the following
//      * types of addresses:
//      *
//      *  - an externally-owned account
//      *  - a contract in construction
//      *  - an address where a contract will be created
//      *  - an address where a contract lived, but was destroyed
//      * ====
//      *
//      * [IMPORTANT]
//      * ====
//      * You shouldn't rely on `isContract` to protect against flash loan attacks!
//      *
//      * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
//      * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
//      * constructor.
//      * ====
//      */
//     function isContract(address account) internal view returns (bool) {
//         // This method relies on extcodesize/address.code.length, which returns 0
//         // for contracts in construction, since the code is only stored at the end
//         // of the constructor execution.

//         return account.code.length > 0;
//     }

//     /**
//      * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
//      * `recipient`, forwarding all available gas and reverting on errors.
//      *
//      * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
//      * of certain opcodes, possibly making contracts go over the 2300 gas limit
//      * imposed by `transfer`, making them unable to receive funds via
//      * `transfer`. {sendValue} removes this limitation.
//      *
//      * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
//      *
//      * IMPORTANT: because control is transferred to `recipient`, care must be
//      * taken to not create reentrancy vulnerabilities. Consider using
//      * {ReentrancyGuard} or the
//      * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
//      */
//     function sendValue(address payable recipient, uint256 amount) internal {
//         require(address(this).balance >= amount, "Address: insufficient balance");

//         (bool success, ) = recipient.call{value: amount}("");
//         require(success, "Address: unable to send value, recipient may have reverted");
//     }

//     /**
//      * @dev Performs a Solidity function call using a low level `call`. A
//      * plain `call` is an unsafe replacement for a function call: use this
//      * function instead.
//      *
//      * If `target` reverts with a revert reason, it is bubbled up by this
//      * function (like regular Solidity function calls).
//      *
//      * Returns the raw returned data. To convert to the expected return value,
//      * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
//      *
//      * Requirements:
//      *
//      * - `target` must be a contract.
//      * - calling `target` with `data` must not revert.
//      *
//      * _Available since v3.1._
//      */
//     function functionCall(address target, bytes memory data) internal returns (bytes memory) {
//         return functionCall(target, data, "Address: low-level call failed");
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
//      * `errorMessage` as a fallback revert reason when `target` reverts.
//      *
//      * _Available since v3.1._
//      */
//     function functionCall(
//         address target,
//         bytes memory data,
//         string memory errorMessage
//     ) internal returns (bytes memory) {
//         return functionCallWithValue(target, data, 0, errorMessage);
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
//      * but also transferring `value` wei to `target`.
//      *
//      * Requirements:
//      *
//      * - the calling contract must have an ETH balance of at least `value`.
//      * - the called Solidity function must be `payable`.
//      *
//      * _Available since v3.1._
//      */
//     function functionCallWithValue(
//         address target,
//         bytes memory data,
//         uint256 value
//     ) internal returns (bytes memory) {
//         return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
//     }

//     /**
//      * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
//      * with `errorMessage` as a fallback revert reason when `target` reverts.
//      *
//      * _Available since v3.1._
//      */
//     function functionCallWithValue(
//         address target,
//         bytes memory data,
//         uint256 value,
//         string memory errorMessage
//     ) internal returns (bytes memory) {
//         require(address(this).balance >= value, "Address: insufficient balance for call");
//         require(isContract(target), "Address: call to non-contract");

//         (bool success, bytes memory returndata) = target.call{value: value}(data);
//         return verifyCallResult(success, returndata, errorMessage);
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
//      * but performing a static call.
//      *
//      * _Available since v3.3._
//      */
//     function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
//         return functionStaticCall(target, data, "Address: low-level static call failed");
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
//      * but performing a static call.
//      *
//      * _Available since v3.3._
//      */
//     function functionStaticCall(
//         address target,
//         bytes memory data,
//         string memory errorMessage
//     ) internal view returns (bytes memory) {
//         require(isContract(target), "Address: static call to non-contract");

//         (bool success, bytes memory returndata) = target.staticcall(data);
//         return verifyCallResult(success, returndata, errorMessage);
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
//      * but performing a delegate call.
//      *
//      * _Available since v3.4._
//      */
//     function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
//         return functionDelegateCall(target, data, "Address: low-level delegate call failed");
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
//      * but performing a delegate call.
//      *
//      * _Available since v3.4._
//      */
//     function functionDelegateCall(
//         address target,
//         bytes memory data,
//         string memory errorMessage
//     ) internal returns (bytes memory) {
//         require(isContract(target), "Address: delegate call to non-contract");

//         (bool success, bytes memory returndata) = target.delegatecall(data);
//         return verifyCallResult(success, returndata, errorMessage);
//     }

//     /**
//      * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
//      * revert reason using the provided one.
//      *
//      * _Available since v4.3._
//      */
//     function verifyCallResult(
//         bool success,
//         bytes memory returndata,
//         string memory errorMessage
//     ) internal pure returns (bytes memory) {
//         if (success) {
//             return returndata;
//         } else {
//             // Look for revert reason and bubble it up if present
//             if (returndata.length > 0) {
//                 // The easiest way to bubble the revert reason is using memory via assembly

//                 assembly {
//                     let returndata_size := mload(returndata)
//                     revert(add(32, returndata), returndata_size)
//                 }
//             } else {
//                 revert(errorMessage);
//             }
//         }
//     }
// }

// /**
//  * @dev Interface of the ERC165 standard, as defined in the
//  * https://eips.ethereum.org/EIPS/eip-165[EIP].
//  *
//  * Implementers can declare support of contract interfaces, which can then be
//  * queried by others ({ERC165Checker}).
//  *
//  * For an implementation, see {ERC165}.
//  */
// interface IERC165 {
//     /**
//      * @dev Returns true if this contract implements the interface defined by
//      * `interfaceId`. See the corresponding
//      * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
//      * to learn more about how these ids are created.
//      *
//      * This function call must use less than 30 000 gas.
//      */
//     function supportsInterface(bytes4 interfaceId) external view returns (bool);
// }

// /**
//  * @dev Required interface of an ERC721 compliant contract.
//  */
// interface IERC721 is IERC165 {
//     /**
//      * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
//      */
//     event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

//     /**
//      * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
//      */
//     event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

//     /**
//      * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
//      */
//     event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

//     /**
//      * @dev Returns the number of tokens in ``owner``'s account.
//      */
//     function balanceOf(address owner) external view returns (uint256 balance);

//     /**
//      * @dev Returns the owner of the `tokenId` token.
//      *
//      * Requirements:
//      *
//      * - `tokenId` must exist.
//      */
//     function ownerOf(uint256 tokenId) external view returns (address owner);

//     /**
//      * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
//      * are aware of the ERC721 protocol to prevent tokens from being forever locked.
//      *
//      * Requirements:
//      *
//      * - `from` cannot be the zero address.
//      * - `to` cannot be the zero address.
//      * - `tokenId` token must exist and be owned by `from`.
//      * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
//      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
//      *
//      * Emits a {Transfer} event.
//      */
//     function safeTransferFrom(
//         address from,
//         address to,
//         uint256 tokenId
//     ) external;

//     /**
//      * @dev Transfers `tokenId` token from `from` to `to`.
//      *
//      * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
//      *
//      * Requirements:
//      *
//      * - `from` cannot be the zero address.
//      * - `to` cannot be the zero address.
//      * - `tokenId` token must be owned by `from`.
//      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
//      *
//      * Emits a {Transfer} event.
//      */
//     function transferFrom(
//         address from,
//         address to,
//         uint256 tokenId
//     ) external;

//     /**
//      * @dev Gives permission to `to` to transfer `tokenId` token to another account.
//      * The approval is cleared when the token is transferred.
//      *
//      * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
//      *
//      * Requirements:
//      *
//      * - The caller must own the token or be an approved operator.
//      * - `tokenId` must exist.
//      *
//      * Emits an {Approval} event.
//      */
//     function approve(address to, uint256 tokenId) external;

//     /**
//      * @dev Returns the account approved for `tokenId` token.
//      *
//      * Requirements:
//      *
//      * - `tokenId` must exist.
//      */
//     function getApproved(uint256 tokenId) external view returns (address operator);

//     /**
//      * @dev Approve or remove `operator` as an operator for the caller.
//      * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
//      *
//      * Requirements:
//      *
//      * - The `operator` cannot be the caller.
//      *
//      * Emits an {ApprovalForAll} event.
//      */
//     function setApprovalForAll(address operator, bool _approved) external;

//     /**
//      * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
//      *
//      * See {setApprovalForAll}
//      */
//     function isApprovedForAll(address owner, address operator) external view returns (bool);

//     /**
//      * @dev Safely transfers `tokenId` token from `from` to `to`.
//      *
//      * Requirements:
//      *
//      * - `from` cannot be the zero address.
//      * - `to` cannot be the zero address.
//      * - `tokenId` token must exist and be owned by `from`.
//      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
//      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
//      *
//      * Emits a {Transfer} event.
//      */
//     function safeTransferFrom(
//         address from,
//         address to,
//         uint256 tokenId,
//         bytes calldata data
//     ) external;
// }

// /**
//  * @dev Required interface of an ERC1155 compliant contract, as defined in the
//  * https://eips.ethereum.org/EIPS/eip-1155[EIP].
//  *
//  * _Available since v3.1._
//  */
// interface IERC1155 is IERC165 {
//     /**
//      * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
//      */
//     event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

//     /**
//      * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
//      * transfers.
//      */
//     event TransferBatch(
//         address indexed operator,
//         address indexed from,
//         address indexed to,
//         uint256[] ids,
//         uint256[] values
//     );

//     /**
//      * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
//      * `approved`.
//      */
//     event ApprovalForAll(address indexed account, address indexed operator, bool approved);

//     /**
//      * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
//      *
//      * If an {URI} event was emitted for `id`, the standard
//      * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
//      * returned by {IERC1155MetadataURI-uri}.
//      */
//     event URI(string value, uint256 indexed id);

//     /**
//      * @dev Returns the amount of tokens of token type `id` owned by `account`.
//      *
//      * Requirements:
//      *
//      * - `account` cannot be the zero address.
//      */
//     function balanceOf(address account, uint256 id) external view returns (uint256);

//     /**
//      * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
//      *
//      * Requirements:
//      *
//      * - `accounts` and `ids` must have the same length.
//      */
//     function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
//         external
//         view
//         returns (uint256[] memory);

//     /**
//      * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
//      *
//      * Emits an {ApprovalForAll} event.
//      *
//      * Requirements:
//      *
//      * - `operator` cannot be the caller.
//      */
//     function setApprovalForAll(address operator, bool approved) external;

//     /**
//      * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
//      *
//      * See {setApprovalForAll}.
//      */
//     function isApprovedForAll(address account, address operator) external view returns (bool);

//     /**
//      * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
//      *
//      * Emits a {TransferSingle} event.
//      *
//      * Requirements:
//      *
//      * - `to` cannot be the zero address.
//      * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
//      * - `from` must have a balance of tokens of type `id` of at least `amount`.
//      * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
//      * acceptance magic value.
//      */
//     function safeTransferFrom(
//         address from,
//         address to,
//         uint256 id,
//         uint256 amount,
//         bytes calldata data
//     ) external;

//     /**
//      * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
//      *
//      * Emits a {TransferBatch} event.
//      *
//      * Requirements:
//      *
//      * - `ids` and `amounts` must have the same length.
//      * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
//      * acceptance magic value.
//      */
//     function safeBatchTransferFrom(
//         address from,
//         address to,
//         uint256[] calldata ids,
//         uint256[] calldata amounts,
//         bytes calldata data
//     ) external;
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

// interface IGameFactory {
//     function getOwner(address _game) external view returns(address);
// }

// contract RecipeFactory is ReentrancyGuard {
//     // game => object int => object string
//     mapping(address => mapping(uint => string)) private objectStrings;
//     address private nft;
//     struct Diamond {
//         uint carat;
//         uint color;
//         uint clarity;
//     }
//     struct Gem {
//         uint carat;
//         uint type_;
//         uint clarity;
//     }
//     struct Recipe {
//         Diamond[] diamonds;
//         Gem[] gems;
//         string[] naturalResources;
//     }
//     // resourceToObject = mapping(gameaddress => mapping(objectsNum => RecipeStruct))
//     mapping(address => mapping(uint => Recipe)) internal resourceToObject;
//     // objectToResource = mapping(gameaddress => mapping(objectsNum => NumRecipeStruct))
//     mapping(address => mapping(uint => uint)) private objectToResource;

//     address private gemContract;
//     address private diamondContract;
//     address private naturalResourceContract;
//     mapping(address => uint[]) private gemTokenIds;
//     mapping(address => uint[]) private diamondTokenIds;
//     mapping(address => uint[]) private naturalResourceTokenIds;
//     address public devaddr_;
//     address public gameFactory;
//     //-------------------------------------------------------------------------
//     // EVENTS
//     //-------------------------------------------------------------------------

//     //-------------------------------------------------------------------------
//     // MODIFIERS
//     //-------------------------------------------------------------------------
//     modifier onlyAdmin() {
//         require(msg.sender == devaddr_, "Only owner!");
//         _;
//     }
//     //-------------------------------------------------------------------------
//     // CONSTRUCTOR
//     //-------------------------------------------------------------------------

//     /**
//      *          around their NFT token. To see the information replace the 
//      *          `\{id\}` substring with the actual token type ID. For more info
//      *          visit:
//      *          https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
//      */
//     constructor(address _nft, address _gameFactory) {
//         nft = _nft;
//         devaddr_ = msg.sender;
//         gameFactory = _gameFactory;
//     }

//     //-------------------------------------------------------------------------
//     // VIEW FUNCTIONS
//     //-------------------------------------------------------------------------


//     //-------------------------------------------------------------------------
//     // STATE MODIFYING FUNCTIONS 
//     //-------------------------------------------------------------------------
//     function getResourceToObject(address _game, uint _object) 
//     external view returns(Gem[] memory, Diamond[] memory, string[] memory) {
//         return (
//             resourceToObject[_game][_object].gems,
//             resourceToObject[_game][_object].diamonds,
//             resourceToObject[_game][_object].naturalResources
//         );
//     }

//     function updateContracts(
//         address _gemContract, 
//         address _diamondContract, 
//         address _naturalResourceContract
//     ) external onlyAdmin {
//         gemContract = _gemContract;
//         diamondContract = _diamondContract;
//         naturalResourceContract = _naturalResourceContract;    
//     }

//     function updateAdmin(address _devaddr) external onlyAdmin {
//         devaddr_ = _devaddr;
//     }

//     function updateResourceToObject(
//         address _game, 
//         uint _object,
//         uint[] memory _caratTypeNClarityGems,
//         uint[] memory _caratColorNClarityDiamonds,
//         string[] memory _naturalResources
//     ) external 
//     nonReentrant 
//     {
//         require(IGameFactory(gameFactory).getOwner(_game) == msg.sender, "Only owner");
//         require(_caratTypeNClarityGems.length % 3 == 0, "Invalid gem list");
//         require(_caratColorNClarityDiamonds.length % 3 == 0, "Invalid diamonds list");
        
//         for (uint i = 0; i < _caratTypeNClarityGems.length; i+=3) {
//             resourceToObject[_game][_object].gems.push(Gem({
//                 carat: _caratTypeNClarityGems[0],
//                 type_: _caratTypeNClarityGems[1],
//                 clarity: _caratTypeNClarityGems[2]
//             }));
//         }
//         for (uint i = 0; i < _caratColorNClarityDiamonds.length; i+=3) {
//             resourceToObject[_game][_object].diamonds.push(Diamond({
//                 carat: _caratColorNClarityDiamonds[0],
//                 color: _caratColorNClarityDiamonds[1],
//                 clarity: _caratColorNClarityDiamonds[2]
//             }));
//         }
//         resourceToObject[_game][_object].naturalResources = _naturalResources;
//     }
    
//     function _checkObjectToResource(
//         address _game,
//         uint _object,
//         uint _numObjects,
//         uint[] memory _gemTokenIds,
//         uint[] memory _diamondTokenIds,
//         uint[] memory _naturalResourceTokenIds
//     ) internal view {
//         // check if numbers work out
//         require(
//             (_gemTokenIds.length % resourceToObject[_game][_object].gems.length == 0 &&
//             _gemTokenIds.length / resourceToObject[_game][_object].gems.length == _numObjects) ||
//             (resourceToObject[_game][_object].gems.length == 0 && _gemTokenIds.length == 0), "Invalid gems"
//         );
//         require(
//             (_diamondTokenIds.length % resourceToObject[_game][_object].diamonds.length == 0 &&
//             _diamondTokenIds.length / resourceToObject[_game][_object].diamonds.length == _numObjects) ||
//             (resourceToObject[_game][_object].diamonds.length == 0 && _diamondTokenIds.length == 0), "Invalid diamonds"
//         );
//         require(
//             (_naturalResourceTokenIds.length % resourceToObject[_game][_object].naturalResources.length == 0 &&
//             _naturalResourceTokenIds.length / resourceToObject[_game][_object].naturalResources.length == _numObjects) ||
//             (resourceToObject[_game][_object].naturalResources.length == 0 && _naturalResourceTokenIds.length == 0), "Invalid naturalResources"
//         );

//         // check if specs work out
//         for (uint i = 0; i < _gemTokenIds.length; i+=resourceToObject[_game][_object].gems.length) {
//             for (uint j = 0; j < resourceToObject[_game][_object].gems.length; j++) {
//                 require(IGemNFT(gemContract).getTicketCarat(_gemTokenIds[i+j]) == 
//                 resourceToObject[_game][_object].gems[j].carat, "Invalid gems carat");
//                 require(IGemNFT(gemContract).getTicketType(_gemTokenIds[i+j]) == 
//                 resourceToObject[_game][_object].gems[j].type_, "Invalid gems type");
//                 require(IGemNFT(gemContract).getTicketClarity(_gemTokenIds[i+j]) == 
//                 resourceToObject[_game][_object].gems[j].clarity, "Invalid gems clarity");
//                 require(IGemNFT(gemContract).getTicketOwner(_gemTokenIds[i+j]) == msg.sender, "Only owner!");
//             }    
//         }
//         for (uint i = 0; i < _diamondTokenIds.length; i+=resourceToObject[_game][_object].diamonds.length) {
//             for (uint j = 0; j < resourceToObject[_game][_object].diamonds.length; j++) {
//                 require(IDiamondNFT(diamondContract).getTicketCarat(_diamondTokenIds[i+j]) == 
//                 resourceToObject[_game][_object].diamonds[j].carat, "Invalid diamonds carat");
//                 require(IDiamondNFT(diamondContract).getTicketColor(_diamondTokenIds[i+j]) == 
//                 resourceToObject[_game][_object].diamonds[j].color, "Invalid diamonds color");
//                 require(IDiamondNFT(diamondContract).getTicketClarity(_diamondTokenIds[i+j]) == 
//                 resourceToObject[_game][_object].diamonds[j].clarity, "Invalid diamonds clarity");
//                 require(IDiamondNFT(diamondContract).getTicketOwner(_diamondTokenIds[i+j]) == msg.sender, "Only owner!");
//             }    
//         }
//         for (uint i = 0; i < _naturalResourceTokenIds.length; 
//         i+=resourceToObject[_game][_object].naturalResources.length) {
//             for (uint j = 0; j < resourceToObject[_game][_object].naturalResources.length; j++) {
//                 require(
//                     keccak256(abi.encodePacked(
//                         INaturalResourceNFT(naturalResourceContract)
//                         .getTicketResource(_naturalResourceTokenIds[i+j])
//                     )) == keccak256(abi.encodePacked(
//                         resourceToObject[_game][_object].naturalResources[j]
//                     )), "Invalid nat rsrcs"
//                 );
//                 require(INaturalResourceNFT(naturalResourceContract).getTicketOwner(_naturalResourceTokenIds[i+j]) == msg.sender, "Only owner!");
//             }
//         }
//     }

//     function _batchTransferFrom(
//         address _from,
//         address _to,
//         uint[] memory _gemTokenIds,
//         uint[] memory _diamondTokenIds,
//         uint[] memory _naturalResourceTokenIds
//     ) internal {
//         uint[] memory amountGems = new uint[](_gemTokenIds.length);
//         uint[] memory amountDiamonds = new uint[](_diamondTokenIds.length);
//         uint[] memory amountNatRscrs = new uint[](_naturalResourceTokenIds.length);

//         if (amountGems.length > 0) {
//             for(uint i = 0; i < amountGems.length; i++) {
//                 amountGems[i] = 1;
//             }
//             IERC1155(gemContract).safeBatchTransferFrom(
//                 _from, 
//                 _to, 
//                 _gemTokenIds, 
//                 amountGems, 
//                 msg.data
//             );
//         }
//         if (amountDiamonds.length > 0) {
//             for(uint i = 0; i < amountDiamonds.length; i++) {
//                 amountDiamonds[i] = 1;
//             }
//             IERC1155(diamondContract).safeBatchTransferFrom(
//                 _from, 
//                 _to, 
//                 _diamondTokenIds, 
//                 amountDiamonds, 
//                 msg.data
//             );
//         }
//         if (amountNatRscrs.length > 0) {
//             for(uint i = 0; i < amountNatRscrs.length; i++) {
//                 amountNatRscrs[i] = 1;
//             }
//             IERC1155(naturalResourceContract).safeBatchTransferFrom(
//                 _from, 
//                 _to, 
//                 _naturalResourceTokenIds, 
//                 amountNatRscrs, 
//                 msg.data
//             );
//         }
//     }

//     function updateObjectToResource(
//         address _game,
//         uint _object,
//         uint _numObjects,
//         uint[] memory _gemTokenIds,
//         uint[] memory _diamondTokenIds,
//         uint[] memory _naturalResourceTokenIds
//     ) external nonReentrant {
//         require(IGameFactory(gameFactory).getOwner(_game) == msg.sender, "Only game owner");
//         _checkObjectToResource(
//             _game, 
//             _object, 
//             _numObjects, 
//             _gemTokenIds, 
//             _diamondTokenIds, 
//             _naturalResourceTokenIds
//         );
//         for (uint i = 0; i < _gemTokenIds.length; i++) {
//             gemTokenIds[_game].push(_gemTokenIds[i]);
//         }
//         for (uint i = 0; i < _diamondTokenIds.length; i++) {
//             diamondTokenIds[_game].push(_diamondTokenIds[i]);
//         }
//         for (uint i = 0; i < _naturalResourceTokenIds.length; i++) {
//             naturalResourceTokenIds[_game].push(_naturalResourceTokenIds[i]);
//         }
//         _batchTransferFrom(
//             msg.sender,
//             address(this),
//             _gemTokenIds,
//             _diamondTokenIds,
//             _naturalResourceTokenIds
//         );
//         objectToResource[_game][_object] += _numObjects;
//     }

//     function disintegrateObject(uint _tokenId, uint _object) external nonReentrant {
//         require(IGameNFT(nft).getReceiver(_tokenId) == msg.sender, "Only receiver");
//         (address _game,,,,,,uint[] memory _objects) = IGameNFT(nft).getGameSpecs(_tokenId);
//         require(objectToResource[_game][_object] > 0, "Not able due to lack of resources");
//         bool found;
//         for (uint i = 0; i < _objects.length; i++) {
//             if (_objects[i] == _object) {
//                 found = true;
//                 break;
//             }
//         }
//         require(found, "Not able to find game object on your token");
//         IGameNFT(nft).deleteObject(_tokenId, _object);
        
//         (
//          uint[] memory newGemTokenIds,
//          uint[] memory _gemTokenIds
//         ) = pickTokenIds(gemTokenIds[_game], 
//                          resourceToObject[_game][_object].gems.length);
//         gemTokenIds[_game] = newGemTokenIds;

//         (
//          uint[] memory newDiamondTokenIds,
//          uint[] memory _diamondTokenIds
//         ) = pickTokenIds(diamondTokenIds[_game], 
//                          resourceToObject[_game][_object].diamonds.length);
//         diamondTokenIds[_game] = newDiamondTokenIds;

//         (
//          uint[] memory newNaturalResourceTokenIds,
//          uint[] memory _naturalResourceTokenIds
//         ) = pickTokenIds(naturalResourceTokenIds[_game], 
//                          resourceToObject[_game][_object].naturalResources.length);
//         naturalResourceTokenIds[_game] = newNaturalResourceTokenIds;

//         _batchTransferFrom(
//             address(this),
//             msg.sender,
//             _gemTokenIds,
//             _diamondTokenIds,
//             _naturalResourceTokenIds
//         );
//         objectToResource[_game][_object] -= 1;
//     }

//     function mintObject(
//         uint _tokenId, 
//         uint _object,
//         uint _numObjects,
//         uint[] memory _gemTokenIds,
//         uint[] memory _diamondTokenIds,
//         uint[] memory _naturalResourceTokenIds
//     ) external nonReentrant {
//         require(_numObjects > 0, "Unable to mint 0 object"
//         );
//         require(IGameNFT(nft).getReceiver(_tokenId) == msg.sender, "Only receiver");
//         (address _game,,,,,,) = IGameNFT(nft).getGameSpecs(_tokenId);
//         _checkObjectToResource(
//             _game, 
//             _object, 
//             _numObjects, 
//             _gemTokenIds, 
//             _diamondTokenIds, 
//             _naturalResourceTokenIds
//         );
//         _batchTransferFrom(
//             msg.sender,
//             IGameFactory(gameFactory).getOwner(_game),
//             _gemTokenIds,
//             _diamondTokenIds,
//             _naturalResourceTokenIds
//         );
//         uint[] memory _objects = new uint[](_numObjects);
//         for (uint i = 0; i < _numObjects; i++) {
//             _objects[i] = _object;
//         }
//         IGameNFT(nft).updateObjects(_tokenId, _objects, false);
//     }

//     function pickTokenIds(
//         uint[] memory _from, 
//         uint _length
//     ) internal pure returns(uint[] memory, uint[] memory){
//         uint j;
//         uint[] memory _to = new uint[](_length);
//         for (uint i = 0; i < _from.length; i++) {
//             if (_from[i] > 0) {
//                 _to[j] = _from[i];
//                 delete _from[i];
//                 if (++j >= _length) break;
//             }
//         }
//         require(j == _length, "pickTokenIds: Invalid tokenIds");
//         return (_from, _to);
//     }

//     function withdrawNonFungible(address _token, uint _tokenId) external onlyAdmin {
//         IERC721(_token).safeTransferFrom(address(this), address(msg.sender), _tokenId);
//     }

//     function withdrawFungible(address _token, uint _amount) external onlyAdmin {
//         _safeTransferFrom(_token, address(this), address(msg.sender), _amount);
//     }
//     //-------------------------------------------------------------------------
//     // INTERNAL FUNCTIONS 
//     //-------------------------------------------------------------------------
//     function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
//         return this.onERC1155Received.selector;
//     }

//     function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
//         return this.onERC1155BatchReceived.selector;
//     }

//     function _safeTransfer(address _token, address to, uint256 value) internal {
//         require(_token.code.length > 0);
//         (bool success, bytes memory data) =
//         _token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
//         require(success && (data.length == 0 || abi.decode(data, (bool))));
//     }

//     function _safeTransferFrom(address _token, address from, address to, uint256 value) internal {
//         require(_token.code.length > 0);
//         (bool success, bytes memory data) =
//         _token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
//         require(success && (data.length == 0 || abi.decode(data, (bool))));
//     }
// }
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

// interface IBaseV1Factory {
//     function isPair(address) external view returns (bool);
// }

// interface IBaseV1Core {
//     function claimFees() external returns (uint, uint);
//     function tokens() external returns (address, address);
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

// interface IValuePool {
//     function pickRank() external;
//     function claimRank() external;
//     function claimReward(uint, string memory, address, address) external;
//     function addInvoiceFromFactory(address, int, string memory) external;
//     function updateCartItems(string memory) external;
//     function reimburseLoan(uint) external;
//     function deposit(uint) external;
//     function withdraw(uint) external;
// }

// interface ISuperLikeGauge {
//     function cancan_email() external view returns(string memory);
//     function badgeColor() external view returns(uint);
//     function devaddr_() external view returns(address);
//     function tokenId() external view returns(uint);
//     function updateLotteryCredits(uint, uint) external;
//     function useLotteryCredit(address, uint) external;
// }

// interface ISuperLikeGaugeFactory {
//     function isElligibleForLoan(bytes32) external view returns(bool);
//     function setElligibleForLoan(bytes32[] memory, address, bool) external;
//     function isGauge(address) external view returns(bool);
//     function userGauge(address) external view returns(address);
//     function referrers(address) external view returns(uint);
//     function updateGaugeEmail(string memory, string memory) external;
//     function mintBadge(address, int256, string memory, string memory) external;
//     function safeTransferFrom(address, address, uint) external;
//     function createGauge(address, address, uint, uint) external returns(address);
//     function getIdentityValue(address, string memory) 
//              external view returns(string memory, string memory, address);
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

// contract Auth {
//     using EnumerableSet for EnumerableSet.AddressSet;
//     enum COLOR {
//         BLACK,
//         BROWN,
//         SILVER,
//         GOLD
//     }
//     EnumerableSet.AddressSet private trustWorthyAuditors;
//     COLOR minIDBadgeColor = COLOR.BLACK;
//     mapping(bytes32 => uint) private isAuth;
//     uint private AUTH_THRESHOLD = 30;
//     uint private AUTH_MAX_VOTE = 10;
//     address private devaddr_;
//     mapping(address => bytes32) private userToIdentityCode;
//     address internal superLikeGaugeFactory;
//     string private valueName;
//     bytes32 private requiredIndentity;
//     mapping(bytes32 => address) private identityProofs;
//     mapping(bytes32 => bool) private blackListedIdentities;
//     bool private cosignEnabled;
//     uint private minCosigners;
//     mapping(address => EnumerableSet.AddressSet) private cosigners;

//     event CheckIdentityProof(address indexed owner, address indexed gauge, bytes32 indexed identityCode, uint time);

//     constructor(
//         address _devaddr,
//         address _superLikeGaugeFactory
//     ) {
//         isAuth[userToIdentityCode[_devaddr]] = type(uint).max / 2;
//         devaddr_ = _devaddr;
//         superLikeGaugeFactory = _superLikeGaugeFactory;
//         // no user without an ssid
//         blackListedIdentities[keccak256(abi.encodePacked(""))] == true;
//     }

//     modifier onlyAuth() {
//         require(isAuth[userToIdentityCode[msg.sender]] >= AUTH_THRESHOLD
//         // , "Only auth"
//         );
//         _;
//     }

//     modifier onlyAdmin() {
//         require(
//             msg.sender == devaddr_
//             // , "Only dev"
//         );
//         _;
//     }

//     modifier onlyChangeMinCosigners() {
//         require(cosigners[msg.sender].length() >= minCosigners
//         // , "Only cosigners"
//         );
//         _;
//         uint _length = cosigners[msg.sender].length();
//         while(_length > 0) {
//             cosigners[msg.sender].remove(cosigners[msg.sender].at(0));
//             _length -= 1;
//         }
//         require(_length == 0
//         // , "Failed to remove cosigners"
//         );
//     }

//     modifier onlyChangeCosignEnabled() {
//         require(cosigners[msg.sender].length() >= minCosigners * 3
//         // , "Only cosigners"
//         );
//         _;
//         uint _length = cosigners[msg.sender].length();
//         while(_length > 0) {
//             cosigners[msg.sender].remove(cosigners[msg.sender].at(0));
//             _length -= 1;
//         }
//         require(_length == 0
//         // , "Failed to remove cosigners"
//         );
//     }

//     modifier onlyChangeDouble(address _sender) {
//         if (cosignEnabled) {
//             require(cosigners[_sender].length() >= minCosigners * 2
//             // , "Only cosigners"
//             );
//         } else {
//             require(_sender == devaddr_
//             // , "Only admin"
//             );
//         }
//         _;
//         if (cosignEnabled) {
//             uint _length = cosigners[_sender].length();
//             while(_length > 0) {
//                 cosigners[_sender].remove(cosigners[_sender].at(0));
//                 _length -= 1;
//             }
//             require(_length == 0
//             // , "Failed to remove cosigners"
//             );
//         }
//     } 

//     function cosign(address _cosignee) external onlyAuth {
//         if (msg.sender != _cosignee) cosigners[_cosignee].add(msg.sender);
//     }

//     function updateMinCosigners(uint _newMin) external onlyChangeMinCosigners {
//         minCosigners = Math.max(1, _newMin);
//     }

//     function updateCosignEnabled(bool _enable) external onlyChangeCosignEnabled {
//         cosignEnabled = _enable;
//     }
    
//     function updateAuthMaxVote(uint newMax) external onlyAdmin {
//         require(AUTH_THRESHOLD / newMax >= 3
//         // , "At least 3 votes should be needed"
//         );
//         AUTH_MAX_VOTE = newMax;
//     }

//     function updateAuthThreshold(uint newThresh) external onlyAdmin {
//         require(newThresh >= AUTH_MAX_VOTE * 3
//         // , "At least 3 votes should be needed"
//         );
//         AUTH_THRESHOLD = newThresh;
//     }

//     function updateAuth(address _user, uint _isAuth) external onlyAdmin {
//         isAuth[userToIdentityCode[_user]] += _isAuth;
//     }

//     function voteForAuth(
//         address _user, 
//         uint _vote, 
//         bool _positive
//     ) external onlyAuth {
//         require(_vote <= AUTH_MAX_VOTE
//         // , "Max vote reached"
//         );
//         _positive ? isAuth[userToIdentityCode[_user]] += _vote : isAuth[userToIdentityCode[_user]] -= _vote;
//         isAuth[userToIdentityCode[msg.sender]] -= _vote;
//     }

//     function updateMinIDColor(COLOR _idColor) external onlyAdmin {
//         minIDBadgeColor = _idColor;
//     }

//     function updateValueNameNCode(
//         string memory _valueName, //agebt, age, agelt... 
//         string memory _value //18
//     ) external onlyAdmin {
//         if (keccak256(abi.encodePacked(_value)) != keccak256(abi.encodePacked(""))) {
//             requiredIndentity == keccak256(abi.encodePacked(_value));
//         }
//         valueName = _valueName;   
//     }

//     function updateTrustWorthyAuditors(address[] memory _gauges, bool _add) external onlyAdmin {
//         for (uint i = 0; i < _gauges.length; i++) {
//             if (_add) {
//                 trustWorthyAuditors.add(_gauges[i]);
//             } else {
//                 trustWorthyAuditors.remove(_gauges[i]);
//             }
//         }
//     }

//     function getAllTrustWorthyAuditors() external view returns(address[] memory _auditors) {
//         _auditors = new address[](trustWorthyAuditors.length());
//         for (uint i = 0; i < trustWorthyAuditors.length(); i++) {
//             _auditors[i] = trustWorthyAuditors.at(i);
//         }
//     }

//     function checkIdentityProof(address _owner, bool _check) public {
//         if (keccak256(abi.encodePacked(valueName)) != keccak256(abi.encodePacked("")) || _check) {
//             (
//                 string memory ssid,
//                 string memory value, 
//                 address _gauge 
//             ) = ISuperLikeGaugeFactory(superLikeGaugeFactory).getIdentityValue(_owner, valueName);
//             require(ISuperLikeGauge(_gauge).badgeColor() >= uint(minIDBadgeColor)
//             // , "ID Gauge inelligible"
//             );
//             require(keccak256(abi.encodePacked(value)) == requiredIndentity || requiredIndentity == 0
//             // , "Invalid comparator"
//             );
//             require(trustWorthyAuditors.length() == 0 || trustWorthyAuditors.contains(_gauge)
//             // , "Only identity proofs from trustworthy auditors"
//             );
//             bytes32 identityCode = keccak256(abi.encodePacked(ssid));
//             require(!blackListedIdentities[identityCode]
//             // , "You identiyCode is blacklisted"
//             );
//             if (identityProofs[identityCode] == address(0)) {
//                 // only register the first time
//                 identityProofs[identityCode] = _owner;
//             }
//             userToIdentityCode[_owner] = identityCode;

//             emit CheckIdentityProof(_owner, _gauge, identityCode, block.timestamp);
//         }
//     }

//     function updateBlacklistedIdentities(address[] memory users, bool[] memory blacklists) external onlyAdmin {
//         require(users.length == blacklists.length
//         // , "Uneven lengths"
//         );
//         for (uint i = 0; i < users.length; i++) {
//             (string memory ssid,,) = ISuperLikeGaugeFactory(superLikeGaugeFactory)
//             .getIdentityValue(users[i], valueName);
//             bytes32 identityCode = keccak256(abi.encodePacked(ssid));
//             blackListedIdentities[identityCode] = blacklists[i];
//         }
//     }

//     function replaceIdentityProof(address _toReplace, bool _check) public {
//         if (keccak256(abi.encodePacked(valueName)) != keccak256(abi.encodePacked("")) || _check) {
//             (
//                 string memory ssid,
//                 string memory value, 
//                 address _gauge 
//             ) = ISuperLikeGaugeFactory(superLikeGaugeFactory).getIdentityValue(msg.sender, valueName);
//             require(ISuperLikeGauge(_gauge).badgeColor() >= uint(minIDBadgeColor)
//             // , "ID Gauge inelligible"
//             );
//             require(keccak256(abi.encodePacked(value)) == requiredIndentity || requiredIndentity == 0
//             // , "Invalid comparator"
//             );
//             bytes32 identityCode = keccak256(abi.encodePacked(ssid));
//             require(userToIdentityCode[_toReplace] == identityCode
//             // , "Only identity owner"
//             );
//             identityProofs[identityCode] = msg.sender;
//             userToIdentityCode[msg.sender] = identityCode;
//             delete userToIdentityCode[_toReplace];
//         }
//     }

//     function updateDev(address _devaddr) external onlyAdmin {
//         devaddr_ = _devaddr;
//     }
// }

// contract GameFactory is ReentrancyGuard, Auth {
//     // Storage for ticket information
//     struct TicketInfo {
//         address owner;
//         uint date;
//         uint pricePerMinute;
//         uint[] objects;
//         uint paidPayable;
//         address token;
//         uint teamShare;
//         uint creatorShare;
//         uint numPlayers;
//         uint sodq;
//         uint totalScore;
//         string description;
//         string cancan_email;
//         bool claimable;
//     }
//     // game => object int => object string
//     mapping(address => mapping(uint => string)) private objectStrings;
//     // Token ID => Token information 
//     mapping(address => TicketInfo) private ticketInfo_;
//     address[] private tickets;
//     uint256 private ticketID = 1;
//     // User address =>  Ticket IDs
//     // mapping(token ID => mapping(gameaddress => deadline))
//     mapping(uint => mapping(address => uint)) private userDeadLines_;
//     uint private MaximumArraySize = 50;
//     address private immutable factory; // the BaseV1Factory
//     address private immutable _ve; // the ve token that governs these contracts
//     address internal immutable base;
//     uint private teamShare = 100;
//     uint private minPricePerMinute;
//     mapping(address => bool) private isWhitelisted;
//     uint private treasury;
//     mapping(address => uint) private pendingRevenue;
//     uint private MAX_SHARE = 10000;
//     address private nft;
//     address[] private nfts;
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
//     address private valuePoolAddress;
//     //-------------------------------------------------------------------------
//     // EVENTS
//     //-------------------------------------------------------------------------

//     event InfoBatchMint(
//         address indexed receiving, 
//         uint256 amountOfTokens, 
//         uint256[] tokenIds
//     );
//     event AddProtocol(address indexed user, address game, uint time);
//     event UpdateProtocol(address indexed user, address game, uint time);
//     event BuyGameTicket(address indexed user, uint tokenId, uint numMinute);
//     event ProcessPayment(address indexed valuepool, address indexed to, string, uint256 amount);

//     //-------------------------------------------------------------------------
//     // MODIFIERS
//     //-------------------------------------------------------------------------
//     modifier isNotContract() {
//         require(!_isContract(msg.sender), "Contracts not allowed");
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
//     constructor(
//         address _factory,
//         address __ve,
//         address _superLikeGaugeFactory,
//         address _devaddr
//     ) 
//     Auth(_devaddr, _superLikeGaugeFactory)
//     {
//         // Only Mine contract will be able to mint new tokens
//         factory = _factory;
//         _ve = __ve;
//         base = __ve; // ve(__ve).token();
//         isWhitelisted[base] = true;
//     }

//     //-------------------------------------------------------------------------
//     // VIEW FUNCTIONS
//     //-------------------------------------------------------------------------
//     function getOwner(address _game) external view returns(address) {
//         return ticketInfo_[_game].owner;
//     }

//     //-------------------------------------------------------------------------
//     // STATE MODIFYING FUNCTIONS 
//     //-------------------------------------------------------------------------
//     // function createNFT(string memory _uri, bool _confirm, address _randGen) external onlyAdmin {
//     //     require(nft == address(0) || _confirm, "Already exists");

//     //     nft = address(new GameNFT(_uri, address(this), base, _randGen));
//     //     nfts.push(nft);
//     // }

//     function updateValuePoolnSLGFactory(
//         address _valuePoolAddress,
//         address _superLikeGaugeFactory
//     ) external onlyAdmin {
//         valuePoolAddress = _valuePoolAddress;
//         superLikeGaugeFactory = _superLikeGaugeFactory;
//     }

//     function updateWhitelist(address _token, bool _whitelist) external onlyAdmin {
//         isWhitelisted[_token] = _whitelist;
//     }

//     function addProtocol(
//         address _pool,
//         address _token,
//         address _game, 
//         uint _pricePerMinute, 
//         uint _creatorShare,
//         uint[] memory _objectsNumbers,
//         string[] memory _objectStrings,
//         string memory _cancan_email,
//         string memory _description,
//         bool _claimable
//     ) external {
//         require(IBaseV1Factory(factory).isPair(_pool)
//         // , "!_pool"
//         );
//         (address tokenA, address tokenB) = IBaseV1Core(_pool).tokens();
//         require(isWhitelisted[tokenA] || isWhitelisted[tokenB]
//         // , "!whitelisted"
//         );
//         require(_token == tokenA || _token == tokenB
//         // , "Invalid token"
//         );
//         require(_pricePerMinute >= minPricePerMinute
//         // , "Invalid price"
//         );
//         require(ticketInfo_[_game].owner == address(0)
//         // , "Game already listed"
//         );
//         require(_objectsNumbers.length == _objectStrings.length
//         , "Uneven lists"
//         );
//         require(_creatorShare + teamShare <= MAX_SHARE
//         , "Invalid share"
//         );
//         checkIdentityProof(msg.sender, false);

//         ticketInfo_[_game] = TicketInfo({
//             owner: msg.sender,
//             date: block.timestamp,
//             pricePerMinute: _pricePerMinute,
//             objects: _objectsNumbers,
//             paidPayable: 0,
//             token: _token,
//             teamShare: teamShare,
//             creatorShare: _creatorShare,
//             numPlayers: 0,
//             sodq: 0,
//             totalScore: 0,
//             cancan_email: _cancan_email,
//             description: _description,
//             claimable: _claimable
//         });
//         tickets.push(_game);
//         for(uint i = 0; i < _objectStrings.length; i++) {
//             require(_objectsNumbers[i] > 0
//             // , "0 is not a valid object number"
//             );
//             objectStrings[_game][_objectsNumbers[i]] = _objectStrings[i];
//         }

//         emit AddProtocol(msg.sender, _game, block.timestamp);
//     }

//     function updateEmail(
//         address _game, 
//         string memory _email
//     ) external {
//         require(ticketInfo_[_game].owner == msg.sender
//         // , "Game already listed"
//         );
//         ticketInfo_[_game].cancan_email = _email;
//     }

//     function updateDescription(address _game, string memory _desc) external {
//         require(ticketInfo_[_game].owner == msg.sender
//         // , "Only game dev"
//         );
//         ticketInfo_[_game].description = _desc;
//     }

//     function updateClaimable(address _game, bool _claimable) external {
//         require(ticketInfo_[_game].owner == msg.sender
//         // , "Only game dev"
//         );
//         ticketInfo_[_game].claimable = _claimable;
//     }

//     function updateProtocol(
//         address _game, 
//         address _owner, 
//         uint _pricePerMinute, 
//         uint _creatorShare,
//         uint[] memory _objectsNumbers,
//         string[] memory _objectStrings
//     ) external {
//         require(_pricePerMinute > minPricePerMinute
//         // , "Invalid price"
//         );
//         require(ticketInfo_[_game].owner == msg.sender
//         // , "Game already listed"
//         );
//         require(_objectsNumbers.length == _objectStrings.length
//         // , "Uneven lists"
//         );
//         require(_creatorShare + ticketInfo_[_game].teamShare <= MAX_SHARE
//         // , "Invalid share"
//         );

//         ticketInfo_[_game].owner = _owner;
//         ticketInfo_[_game].pricePerMinute = _pricePerMinute;
//         ticketInfo_[_game].creatorShare = _creatorShare;
//         if (_objectsNumbers.length > 0) {
//             ticketInfo_[_game].objects = _objectsNumbers;
//         }
//         for(uint i = 0; i < _objectStrings.length; i++) {
//             require(_objectsNumbers[i] > 0
//             // , "0 is not a valid object number"
//             );
//             objectStrings[_game][_objectsNumbers[i]] = _objectStrings[i];
//         }
//         emit UpdateProtocol(msg.sender, _game, block.timestamp);
//     }
    
//     function createGamingNFT(address _to, uint _num) external {
//         IGameNFT(nft).batchMint(_to, _num);
//     }

//     function sponsorGame(address _game, address _from, uint _amount) 
//     public 
//     nonReentrant 
//     {
//         require(ticketInfo_[_game].token != address(0)
//         // , "Invalid game"
//         );
//         if (_from != address(this)) {
//             _safeTransferFrom(
//                 ticketInfo_[_game].token, 
//                 _from, 
//                 address(this), 
//                 _amount
//             );
//         }
//         uint _teamFee = _amount * teamShare / 10000;
//         uint _creatorFee = _amount * ticketInfo_[_game].creatorShare / 10000; 
//         pendingRevenue[_game] += _creatorFee;
//         treasury += _teamFee;
//         ticketInfo_[_game].paidPayable += _amount - _teamFee - _creatorFee;
//     }

//     function fundWithValuePool(address _valuePool, address _game, uint _amount) 
//     external 
//     nonReentrant 
//     {
//         if (_valuePool == address(0)) {
//             _valuePool = valuePoolAddress;
//         }
//         IValuePool(_valuePool).claimReward(
//             _amount,
//             string(abi.encodePacked("fundWithValuePool")),
//             _game,
//             ISuperLikeGaugeFactory(superLikeGaugeFactory).userGauge(msg.sender)
//         );
//     }

//     /**
//      * @param   _tokenId The token's ID
//      * @param   _numMinutes The number of minutes to buy
//      */
//     function buyGameTicket(
//         uint _tokenId,
//         address _game,
//         uint256 _numMinutes
//     )
//         external
//     {   
//         uint _price = ticketInfo_[_game].pricePerMinute * _numMinutes;
//         sponsorGame(_game, msg.sender, _price);

//         userDeadLines_[_tokenId][_game] = block.timestamp + _numMinutes;
//         (address _oldGame,,,,,,) = IGameNFT(nft).getGameSpecs(_tokenId);
//         bool _delete = _game != _oldGame;
//         ticketInfo_[_game].numPlayers += _game != _oldGame ? 1 : 0;
//         IGameNFT(nft).updatePricePercentile(_tokenId, _price);
//         IGameNFT(nft).updateGameContract(
//             _tokenId, 
//             msg.sender, 
//             _game, 
//             _numMinutes,
//             0, 
//             0,
//             _delete
//         );
        
//         emit BuyGameTicket(msg.sender, _tokenId, _numMinutes);
//     }

//     function claimGameTicket(uint _tokenId) 
//     external 
//     nonReentrant 
//     {
//         require(IGameNFT(nft).getReceiver(_tokenId) == msg.sender
//         // , "Not receiver"
//         );
//         (address _game, uint _score, uint _deadline,,,,) = IGameNFT(nft).getGameSpecs(_tokenId);
//         require(ticketInfo_[_game].claimable
//         // , "Gains are not claimable yet"
//         );
//         require(userDeadLines_[_tokenId][_game] > _deadline && _deadline != 0
//         // , "Score was update after deadline"
//         );
//         delete userDeadLines_[_tokenId][_game];
        
//         ticketInfo_[_game].totalScore += _score;
//         uint _userFee = ticketInfo_[_game].paidPayable * _score / ticketInfo_[_game].totalScore;  
//         _safeTransfer(
//             ticketInfo_[_game].token, 
//             msg.sender, 
//             _userFee
//         );
//         ticketInfo_[_game].sodq = IGameNFT(nft).updateScorePercentile(
//             _tokenId, 
//             ticketInfo_[_game].totalScore,
//             ticketInfo_[_game].numPlayers,
//             _score,
//             ticketInfo_[_game].sodq
//         );
//         IGameNFT(nft).updateGameContract(_tokenId, msg.sender, _game, 0, 0, _userFee, false);
//     }

//     function reimburseTicket(uint _tokenId, address _nft) 
//     external 
//     nonReentrant 
//     {
//         require(IGameNFT(nft).getReceiver(_tokenId) == msg.sender
//         // , "Not receiver"
//         );
//         (address _game,,,,,,) = IGameNFT(nft).getGameSpecs(_tokenId);
//         require(ticketInfo_[_game].claimable
//         // , "Gains are not claimable yet"
//         );
//         delete userDeadLines_[_tokenId][_game];

//         uint _price = Math.min(
//             IGameNFT(nft).getGamePrice(_tokenId), 
//             IGameNFT(nft).getQ2()
//         );
//         // swap to base token using the pool
//         // _price = 
//         IGameNFT(nft).burn(msg.sender, _tokenId, 1);
//         IValuePool(valuePoolAddress).claimReward(
//             _price,
//             string(abi.encodePacked("reimburseTicket")),
//             msg.sender,
//             ISuperLikeGaugeFactory(superLikeGaugeFactory).userGauge(msg.sender)
//         );
//     }

//     function processPayment(address _to, string memory _id, address _from, uint _amount, uint _direction) 
//     external 
//     nonReentrant 
//     {
//         require(_direction == 1
//         // , "Invalid direction"
//         );
//         if (keccak256(abi.encodePacked(_id)) == keccak256(abi.encodePacked("fundWithValuePool"))) {
//             _safeTransferFrom(
//                 base,
//                 address(msg.sender), 
//                 address(this), 
//                 _amount
//             );
//             // swap base token to game's token
//             // _amount = swap(base, ticketInfo_[_to].token, _amount) 
//             sponsorGame(_to, address(this), _amount);
//         } else {
//             _safeTransferFrom(
//                 base,
//                 address(msg.sender), 
//                 _to, 
//                 _amount
//             );
//         }
        
//         emit ProcessPayment(_from, _to, _id, _amount);
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

//     function _isContract(address account) internal view returns (bool) {
//         // This method relies on extcodesize, which returns 0 for contracts in
//         // construction, since the code is only stored at the end of the
//         // constructor execution.
//         uint _size;
//         assembly {
//             _size := extcodesize(account)
//         }
//         return _size > 0;
//     }
// }
// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;

// import "./Library.sol";

// contract RandomNumberGenerator is VRFConsumerBase, IRandomNumberGenerator, Ownable {
//     using SafeERC20 for IERC20;

//     address public valuepool;
//     bytes32 public keyHash;
//     bytes32 public latestRequestId;
//     uint32 public randomResult;
//     uint256 public fee;
//     uint256 public latestId;

//     /**
//      * @notice Constructor
//      * @dev RandomNumberGenerator must be deployed before the valuepool.
//      * Once the valuepool contract is deployed, setValuepoolAddress must be called.
//      * https://docs.chain.link/docs/vrf-contracts/
//      * @param _vrfCoordinator: address of the VRF coordinator
//      * @param _linkToken: address of the LINK token
//      */
//     constructor(address _vrfCoordinator, address _linkToken) VRFConsumerBase(_vrfCoordinator, _linkToken) {
//         //
//     }

//     /**
//      * @notice Request randomness from a user-provided seed
//      * @param _seed: seed provided by the valuepool
//      */
//     function getRandomNumber(uint256 _seed) external override {
//         require(msg.sender == valuepool, "Only Valuepool");
//         require(keyHash != bytes32(0), "Must have valid key hash");
//         require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK tokens");

//         latestRequestId = requestRandomness(keyHash, fee, _seed);
//     }

//     /**
//      * @notice Change the fee
//      * @param _fee: new fee (in LINK)
//      */
//     function setFee(uint256 _fee) external onlyOwner {
//         fee = _fee;
//     }

//     /**
//      * @notice Change the keyHash
//      * @param _keyHash: new keyHash
//      */
//     function setKeyHash(bytes32 _keyHash) external onlyOwner {
//         keyHash = _keyHash;
//     }

//     /**
//      * @notice Set the address for the valuepool
//      * @param _valuepool: address of the valuepool
//      */
//     function setValuepoolAddress(address _valuepool) external onlyOwner {
//         valuepool = _valuepool;
//     }

//     /**
//      * @notice It allows the admin to withdraw tokens sent to the contract
//      * @param _tokenAddress: the address of the token to withdraw
//      * @param _tokenAmount: the number of token amount to withdraw
//      * @dev Only callable by owner.
//      */
//     function withdrawTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
//         IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
//     }

//     /**
//      * @notice View latestId
//      */
//     function viewLatestId() external view override returns (uint256) {
//         return latestId;
//     }

//     /**
//      * @notice View random result
//      */
//     function viewRandomResult() external view override returns (uint32) {
//         return randomResult;
//     }

//     /**
//      * @notice Callback function used by ChainLink's VRF Coordinator
//      */
//     function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
//         require(latestRequestId == requestId, "Wrong requestId");
//         randomResult = uint32(1000000 + (randomness % 1000000));
//         latestId = IValuePool(valuepool).viewCurrentId();
//     }
// }
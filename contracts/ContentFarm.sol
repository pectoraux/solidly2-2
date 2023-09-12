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

// interface Voter {
//     function attachTokenToGauge(uint _tokenId, address account) external;
//     function detachTokenFromGauge(uint _tokenId, address account) external;
//     function emitDeposit(uint _tokenId, address account, uint amount) external;
//     function emitWithdraw(uint _tokenId, address account, uint amount) external;
//     function distribute(address _gauge) external;
// }

// // Gauges are used to incentivize different actions
// contract ContentFarm {

//     address public immutable token; // the governance token
//     address public immutable voter;
//     address public immutable _ve;

//     // info about owner
//     address public devaddr;
//     uint public devTokenId;
//     string public cancan_email; 
//     string public creative_cid; 
//     string public video_cid; 
//     string public website_link; 


//     event Withdraw(address indexed from, uint amount);
//     event NotifyReward(address indexed from, address indexed reward, uint amount);

//     constructor(
//         address __ve,
//         uint _tokenId,
//         address _voter,
//         string memory _video_cid,
//         string memory _creative_cid,
//         string memory _cancan_email,
//         string memory _website_link
//     ) {
//         _ve = __ve;
//         token = ve(__ve).token();
//         voter = _voter;
//         devaddr = msg.sender;
//         devTokenId = _tokenId;
//         video_cid = _video_cid;
//         creative_cid = _creative_cid;
//         cancan_email = _cancan_email;
//         website_link = _website_link;
//     }

//     // simple re-entrancy check
//     uint internal _unlocked = 1;
//     modifier lock() {
//         require(_unlocked == 1);
//         _unlocked = 2;
//         _;
//         _unlocked = 1;
//     }

//     modifier onlyAuth() {
//         require(
//             msg.sender == ve(_ve).ownerOf(devTokenId)
//         );
//         _;
//     }

//     function updateDev(address _devaddr) external onlyAuth {
//         devaddr = _devaddr;
//     }

//     function updateVideoCid(string calldata _video_cid) external onlyAuth {
//         video_cid = _video_cid;
//     }

//     function updateCreativeCid(string calldata _creative_cid) external onlyAuth {
//         creative_cid = _creative_cid;
//     }

//     function updateCancanEmail(string calldata _cancan_email) external onlyAuth {
//         cancan_email = _cancan_email;
//     }

//     function updateWebsiteLink(string calldata _website_link) external onlyAuth {
//         website_link = _website_link;
//     }

//     function getReward(address account) external lock {
//         require(msg.sender == account || msg.sender == voter);
//         _unlocked = 1;
//         Voter(voter).distribute(address(this));
//         _unlocked = 2;

//         withdrawAll(token);
//     }

//     function withdrawAll(address _token) public {
//         withdraw(_token, erc20(_token).balanceOf(address(this)));
//     }

//     function withdraw(address _token, uint amount) public onlyAuth {
//         _safeTransfer(_token, msg.sender, amount);

//         emit Withdraw(msg.sender, amount);
//     }

//     function notifyRewardAmount(address _token, uint amount) external lock {
//         require(amount > 0, "Invalid amount");

//         _safeTransferFrom(_token, msg.sender, address(this), amount);

//         emit NotifyReward(msg.sender, _token, amount);
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

//     function _safeApprove(address _token, address spender, uint256 value) internal {
//         require(_token.code.length > 0);
//         (bool success, bytes memory data) =
//         _token.call(abi.encodeWithSelector(erc20.approve.selector, spender, value));
//         require(success && (data.length == 0 || abi.decode(data, (bool))));
//     }
// }

// contract ContentFarmFactory {
//     address public last_gauge;
//     address[] public gauges;

//     function createGauge(
//         address _ve,
//         uint _tokenId, 
//         string calldata _video_cid,
//         string calldata _creative_cid,
//         string calldata _cancan_email,
//         string calldata _website_link
//     ) external returns (address) {
//         last_gauge = address(new ContentFarm(
//             _ve,
//             _tokenId,
//             msg.sender,
//             _video_cid,
//             _creative_cid,
//             _cancan_email,
//             _website_link
//         ));
//         gauges.push(last_gauge);
//         return last_gauge;
//     }

//     function createGaugeSingle(
//         address _ve,
//         uint _tokenId, 
//         address _voter,
//         string calldata _video_cid,
//         string calldata _creative_cid,
//         string calldata _cancan_email,
//         string calldata _website_link
//     ) external returns (address) {
//         last_gauge = address(new ContentFarm(
//             _ve,
//             _tokenId,
//             _voter,
//             _video_cid,
//             _creative_cid,
//             _cancan_email,
//             _website_link
//         ));

//         gauges.push(last_gauge);
//         return last_gauge;
//     }
// }

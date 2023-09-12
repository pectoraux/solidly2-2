// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;
// pragma abicoder v2;

// import "./Library.sol";


// contract FeeTo {
//     using SafeERC20 for IERC20;

//     uint internal constant week = 86400 * 7; // allows minting once per week (reset every Thursday 00:00 UTC)
//     uint public adminFee;
//     address public contractAddress;
//     mapping(address => uint) public activePeriod;
//     mapping(address => uint) public pendingRevenue;

//     function setContractAddress(address _contractAddress) external {
//         require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender, "PMHH1");
//         contractAddress = _contractAddress;
//     }

//     function updateFee(uint _fee) external {
//         require(IAuth(contractAddress).devaddr_() == msg.sender);
//         adminFee = _fee;
//     }

//     function claimPendingRevenue(address _token, address _to) external {
//         require(IAuth(contractAddress).devaddr_() == msg.sender);
//         IERC20(_token).safeTransfer(_to, pendingRevenue[_token]);
//         pendingRevenue[_token] = 0;
//     }

//     function distribute(address _token) public {
//         uint _period = activePeriod[_token];
//         if (block.timestamp >= _period + week) { // only trigger if new week
//             _period = (block.timestamp + week) / week * week;
//             activePeriod[_token] = _period;
//             uint _amount = erc20(_token).balanceOf(address(this)) - pendingRevenue[_token];
//             uint _fee = _amount * adminFee / 10000;
//             _amount -= _fee;
//             pendingRevenue[_token] += _fee;
//             IGauge(IContract(contractAddress).poolGauge()).notifyRewardAmount(
//                 _token, 
//                 _amount
//             );
//         }
//     }
// }

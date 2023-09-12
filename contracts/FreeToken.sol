// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;

// import './Library.sol';

// contract FreeToken is ERC20 {
//     address public devaddr_;
//     address public minter;

//     constructor(
//         address _devaddr,
//         string memory name, 
//         string memory symbol
//     ) ERC20(name, symbol) {
//         devaddr_ = _devaddr;
//     }

//     modifier onlyAdmin() {
//         require(msg.sender == minter, "Only owner");
//         _;
//     }

//     function mint(uint256 amount) public onlyAdmin returns (bool) {
//         _mint(msg.sender, amount);
//         return true;
//     }

//     function mint(address account, uint256 amount) external onlyAdmin returns (bool) {
//         _mint(account, amount);
//         return true;
//     }

//     function burn(uint256 amount) external onlyAdmin returns (bool) {
//         _burn(msg.sender, amount);
//         return true;
//     }

//     function burn(address account, uint256 amount) external onlyAdmin {
//         _burn(account, amount);
//     }

//     function updateDev(address _devaddr) external {
//         require(msg.sender == devaddr_);
//         devaddr_ = _devaddr;
//     }

//     function updateMinter(address _minter) external {
//         require(msg.sender == devaddr_);
//         minter = _minter;
//     }
// }

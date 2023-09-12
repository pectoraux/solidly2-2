// //SPDX-License-Identifier: MIT
// pragma solidity ^0.8.4;

// import "../Tornado.sol";

// contract MerkleTreeWithHistoryMock is MerkleTreeWithHistory {
//   constructor(uint32 _treeLevels, IHasher _hasher) MerkleTreeWithHistory(_treeLevels, _hasher) {}

//   function insert(bytes32 _leaf) public {
//     _insert(_leaf);
//   }
// }

// interface ERC20Basic {
//   function _totalSupply() external returns (uint256);

//   function totalSupply() external view returns (uint256);

//   function balanceOf(address who) external view returns (uint256);

//   function transfer(address to, uint256 value) external;

//   event Transfer(address indexed from, address indexed to, uint256 value);
// }

// /**
//  * @title ERC20 interface
//  * @dev see https://github.com/ethereum/EIPs/issues/20
//  */
// interface IUSDT is ERC20Basic {
//   function allowance(address owner, address spender) external view returns (uint256);

//   function transferFrom(
//     address from,
//     address to,
//     uint256 value
//   ) external;

//   function approve(address spender, uint256 value) external;

//   event Approval(address indexed owner, address indexed spender, uint256 value);
// }

// interface IDeployer {
//   function deploy(bytes memory _initCode, bytes32 _salt) external returns (address payable createdContract);
// }

// contract BadRecipient {
//   fallback() external {
//     require(false, "this contract does not accept ETH");
//   }
// }

// contract ERC20Mock is ERC20("DAIMock", "DAIM") {
//   function mint(address account, uint256 amount) public {
//     _mint(account, amount);
//   }
// }
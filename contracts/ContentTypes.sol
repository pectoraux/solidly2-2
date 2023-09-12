// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;

// import "./Library.sol";

// contract ContentTypes {
//     using EnumerableSet for EnumerableSet.UintSet;
    
//     mapping(uint => string) public indexToName;
//     EnumerableSet.UintSet private _contentIndices;
//     address public devaddr_;

//     constructor() {
//         devaddr_ = msg.sender;
//     }

//     modifier onlyAdmin {
//         require(msg.sender == devaddr_, "Only Dev");
//         _;
//     }

//     function updateDev(address _devaddr) external onlyAdmin {
//         devaddr_ = _devaddr;
//     }

//     function getContents() external view returns(string[] memory _contents) {
//         _contents = new string[](_contentIndices.length());
//         for (uint i = 0; i < _contentIndices.length(); i++) {
//             _contents[i] = indexToName[_contentIndices.at(i)];
//         }
//         return _contents;
//     }

//     function contains(string memory _contentName) public view returns(bool) {
//         return _contentIndices.contains(uint(keccak256(abi.encodePacked(_contentName))));
//     }

//     function addContent(string memory _contentName) external onlyAdmin {
//         indexToName[uint(keccak256(abi.encodePacked(_contentName)))] = _contentName;
//         _contentIndices.add(uint(keccak256(abi.encodePacked(_contentName))));
//     }

//     function removeContent(string memory _contentName) external onlyAdmin {
//         _contentIndices.remove(uint(keccak256(abi.encodePacked(_contentName))));
//         delete indexToName[uint(keccak256(abi.encodePacked(_contentName)))];
//     }

// }
// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;

// import "./slice.sol";

// contract PlusCodes {
//     using strings for *;
//     mapping(string => bool) _mapping;
//     mapping(string => bool) _mapping2;
//     mapping(string => bool) _mapping3;
//     string[] _glocChars;
//     uint GLOC_LENGTH = 20;
//     string[] public _extensions = new string[](GLOC_LENGTH * GLOC_LENGTH);
//     mapping(string => uint) public _isExtension;
//     mapping(string => address) public isRegistered;

//     constructor() {
//         // first digit
//         _mapping['3'] = true;
//         _mapping['4'] = true;
//         _mapping['5'] = true;
//         _mapping['6'] = true;
//         _mapping['7'] = true;
//         _mapping['8'] = true;
//         _mapping['9'] = true;

//         // second digit
//         _mapping2['2'] = true;
//         _mapping2['3'] = true;
//         _mapping2['4'] = true;
//         _mapping2['5'] = true;
//         _mapping2['6'] = true;
//         _mapping2['7'] = true;
//         _mapping2['8'] = true;
//         _mapping2['9'] = true;
//         _mapping2['c'] = true;
//         _mapping2['f'] = true;
//         _mapping2['g'] = true;
//         _mapping2['h'] = true;
//         _mapping2['j'] = true;
//         _mapping2['m'] = true;
//         _mapping2['p'] = true;
//         _mapping2['q'] = true;
//         _mapping2['r'] = true;
//         _mapping2['v'] = true;

//         // third & fourth digit
//         _mapping3['2'] = true;
//         _mapping3['3'] = true;
//         _mapping3['4'] = true;
//         _mapping3['5'] = true;
//         _mapping3['6'] = true;
//         _mapping3['7'] = true;
//         _mapping3['8'] = true;
//         _mapping3['9'] = true;
//         _mapping3['c'] = true;
//         _mapping3['f'] = true;
//         _mapping3['g'] = true;
//         _mapping3['h'] = true;
//         _mapping3['j'] = true;
//         _mapping3['m'] = true;
//         _mapping3['p'] = true;
//         _mapping3['q'] = true;
//         _mapping3['r'] = true;
//         _mapping3['v'] = true;
//         _mapping3['w'] = true;
//         _mapping3['x'] = true;
        
//         _glocChars = [
//             '2', 
//             '3', 
//             '4', 
//             '5', 
//             '6', 
//             '7', 
//             '8', 
//             '9',
//             'c', 
//             'f', 
//             'g', 
//             'h',
//             'j', 
//             'm', 
//             'p', 
//             'q',
//             'r', 
//             'v', 
//             'w', 
//             'x'
//         ];

//         _generateExtensions();
//     }

//     function isPlusCodeFirstFour(string memory mcode) public view returns(bool){
//         strings.slice memory codeSlice = mcode.toSlice();
//         strings.slice memory first = codeSlice.nextRune();
//         strings.slice memory second = codeSlice.nextRune();
//         strings.slice memory third = codeSlice.nextRune();
//         strings.slice memory fourth = codeSlice.nextRune();
//         if(!_mapping[first.toString()]) return false;
//         if(!_mapping2[second.toString()]) return false;
//         if(!_mapping3[third.toString()]) return false;
//         if(!_mapping3[fourth.toString()]) return false;
//         return true;
//     }

//     function isPlusCodeLastFour(string memory mcode) public view returns(bool){
//         strings.slice memory codeSlice = mcode.toSlice();
//         if (codeSlice.len() > 4) {
//             codeSlice.nextRune();
//             codeSlice.nextRune();
//             codeSlice.nextRune();
//             codeSlice.nextRune();
//         }
//         strings.slice memory fifth = codeSlice.nextRune();
//         strings.slice memory sixth = codeSlice.nextRune();
//         strings.slice memory seventh = codeSlice.nextRune();
//         strings.slice memory eighth = codeSlice.nextRune();
//         if(!_mapping3[fifth.toString()]) return false;
//         if(!_mapping3[sixth.toString()]) return false;
//         if(!_mapping3[seventh.toString()]) return false;
//         if(!_mapping3[eighth.toString()]) return false;
//         return true;
//     }

//     function getExtension(string memory _code) public pure returns(string memory) {
//         strings.slice memory codeSlice = _code.toSlice();
//         if (codeSlice.len() > 8) {
//             codeSlice.nextRune();
//             codeSlice.nextRune();
//             codeSlice.nextRune();
//             codeSlice.nextRune();
//             codeSlice.nextRune();
//             codeSlice.nextRune();
//             codeSlice.nextRune();
//             codeSlice.nextRune();
//         }
//         strings.slice memory sign = codeSlice.nextRune();
//         require(sign.equals("+".toSlice()), "Code is missing + sign");
//         return codeSlice.toString();
//     }

//     function checkExtension(string memory _ext) public view returns(bool) {
//         if (keccak256(abi.encodePacked('22')) == keccak256(abi.encodePacked(_ext))) {
//             return true;
//         }
//         return _isExtension[_ext] != 0;
//     }

//     function validateCode(string memory _code) public view returns(bool) {
//         return  isPlusCodeFirstFour(_code) 
//                 && isPlusCodeLastFour(_code)
//                 && checkExtension(getExtension(_code));
//     }

//     function batchValidateCodes(string[] memory _codes) public view returns(bool) {
//         for (uint i = 0; i < _codes.length; i++) {
//             if (!validateCode(_codes[i])) {
//                 return false;
//             }
//         }
//         return true;
//     }

//     function _generateExtensions() internal {
//         for (uint i=0; i < GLOC_LENGTH; i++) {
//             for (uint j=0; j < GLOC_LENGTH; j++) {
//                 string memory curr = string(
//                     abi.encodePacked(
//                         _glocChars[i],
//                         _glocChars[j]
//                     )
//                 );
//                 _isExtension[curr] = i*GLOC_LENGTH + j;
//                 _extensions[i*GLOC_LENGTH + j] = curr;
//             }
//         }
//     }

//     function getExtensionsRow(uint _i) external view returns(string[] memory _row) {
//         _row = new string[](GLOC_LENGTH);
//         for (uint j=0; j < GLOC_LENGTH; j++) {
//             _row[j] = _extensions[_i*GLOC_LENGTH +j];
//         }
//         return _row;
//     }

//     function getNFTsFromExtension(uint _i, uint _j) external view returns(string[] memory _row) {
//         _row = new string[](GLOC_LENGTH);
//         string memory _ext = _extensions[_i*GLOC_LENGTH + _j*GLOC_LENGTH];
//         for (uint k=0; k < GLOC_LENGTH; k++) {
//             _row[k] = string(
//                 abi.encodePacked(
//                     _ext,
//                     _glocChars[k]
//                 )
//             );
//         }
//         return _row;
//     }

//     function getNFTsFromExtension2(string memory _ext) 
//     external view returns(string[] memory _row) {
//         require(checkExtension(_ext), "Invalid extension");
//         _row = new string[](GLOC_LENGTH);
//         for (uint k=0; k < GLOC_LENGTH; k++) {
//             _row[k] = string(
//                 abi.encodePacked(
//                     _ext,
//                     _glocChars[k]
//                 )
//             );
//         }
//         return _row;
//     }

//     function registerPlusCode(
//         address _owner,
//         string memory _first4, 
//         string memory _last4,
//         string[] memory _nfts
//     ) external {
//         for (uint i = 0; i < _nfts.length; i++) {
//             string memory curr = string(
//                 abi.encodePacked(
//                     _first4,
//                     _last4,
//                     '+',
//                     _nfts[i]
//                 )
//             );
//             require(isRegistered[curr] == _owner, "NFT is registered to another user");
//             isRegistered[curr] = _owner;
//         }
//     }
// }
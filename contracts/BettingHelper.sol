// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;

// import "./Library.sol";

// contract BettingHelper is Auth {
//     uint public immutable MinimumEntriesFor;
//     uint public immutable MinimumEntriesAgainst;
//     mapping(uint => uint) public winningNumbers;
//     mapping(uint => uint) public forWinningNumbers;
//     mapping(uint => uint) public againstWinningNumbers;
//     mapping(bytes32 => mapping(uint => bool)) public votedFor;
//     mapping(bytes32 => mapping(uint => bool)) public votedAgainst;

//     constructor(
//         address _devaddr,
//         uint _minimumEntriesFor,
//         uint _minimumEntriesAgainst,
//         address _superLikeGaugeFactory
//     ) Auth(_devaddr, _superLikeGaugeFactory) {
//         MinimumEntriesFor = _minimumEntriesFor;
//         MinimumEntriesAgainst = _minimumEntriesAgainst;
//     }

//     function viewWinningNumber(uint _bettingId) public view returns(uint) {
//         require(
//             forWinningNumbers[_bettingId] >=  MinimumEntriesFor && 
//             againstWinningNumbers[_bettingId] <= MinimumEntriesAgainst,
//             "At least one auth opposes winning number"
//         );
//         return winningNumbers[_bettingId];
//     }
    
//     function setWinningNumber(uint _bettingId, uint _winningNumber) external onlyAuth {
//         if (winningNumbers[_bettingId] == 0) {
//             winningNumbers[_bettingId] =  _winningNumber;  
//         }
//         if (!votedFor[userToIdentityCode[msg.sender]][_bettingId]) {
//             forWinningNumbers[_bettingId] += 1;
//             votedFor[userToIdentityCode[msg.sender]][_bettingId] = true;
//         }
//     }

//     function blockWinningNumber(uint _bettingId) external onlyAuth {
//         if (!votedAgainst[userToIdentityCode[msg.sender]][_bettingId]) {
//             againstWinningNumbers[_bettingId] += 1;
//             votedAgainst[userToIdentityCode[msg.sender]][_bettingId] = false;
//         }
//     }
// }
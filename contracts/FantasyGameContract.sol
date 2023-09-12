// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;
// pragma experimental ABIEncoderV2;

// import "./Library.sol";

// contract FantasyGameContract {
//     address public devaddr_;
//     address public immutable factory; // the BaseV1Factory
//     address public immutable nft;
//     address public immutable playerNFT;

//     mapping(uint => uint) public boosters;
//     //-------------------------------------------------------------------------
//     // EVENTS
//     //-------------------------------------------------------------------------
//         event UpdateObjects(address indexed from, uint _tokenId, uint[] _objects);
//         event UpdateScoreNDeadline(address indexed from, uint _tokenId, uint _score, uint _time);

//     //-------------------------------------------------------------------------
//     // MODIFIERS
//     //-------------------------------------------------------------------------
//     modifier onlyAdmin() {
//         require(
//             msg.sender == devaddr_,
//             "Only dev"
//         );
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
//         address _nft,
//         address _playerNFT
//     ) {
//         // Only Mine contract will be able to mint new tokens
//         devaddr_ = msg.sender;
//         factory = _factory;
//         nft = _nft;
//         playerNFT = _playerNFT;
//     }
//     //-------------------------------------------------------------------------
//     // STATE MODIFYING FUNCTIONS 
//     //-------------------------------------------------------------------------
//     function updateBooster(uint[] memory _objects, uint[] memory _percts) external onlyAdmin {
//         require(_objects.length == _percts.length, "Uneven lists");
//         for (uint i = 0; i < _objects.length; i++) {
//             boosters[_objects[i]] = _percts[i];
//         }
//     }

//     function updateScoreNDeadline(
//         uint _tokenId, 
//         uint _score,
//         address _to,
//         uint[] memory _boosterObjects
//     ) external onlyAdmin {
//         require(IGameNFT(nft).getTicketOwner(_tokenId) == _to, "Only owner");
//         (address _game,,,,,,uint[] memory _objects) = IGameNFT(nft).getGameSpecs(_tokenId);
//         require(_game == address(this), "Get this game's name on your NFT at the factory");
        
//         for (uint i = 0; i < _boosterObjects.length; i++) {
//             for (uint j = 0; j < _objects.length; j++) {    
//                 if (_boosterObjects[i] == _objects[j]) {
//                     _score += _score * boosters[_boosterObjects[i]] / 10000;
//                 }
//             }
//         }
        
//         IGameNFT(nft).updateScoreNDeadline(_tokenId, _score, block.timestamp);

//         emit UpdateScoreNDeadline(msg.sender, _tokenId, _score, block.timestamp);
//     }

//     function updateObjects(
//         uint _tokenId, 
//         address _to,
//         uint[] memory _objects
//     ) external onlyAdmin {
//         require(IGameNFT(nft).getTicketOwner(_tokenId) == _to, "Only owner");
//         IGameNFT(nft).updateObjects(_tokenId, _objects, false);
        
//         emit UpdateObjects(msg.sender, _tokenId, _objects);
//     }
    
//     function updateDev(address _dev) external onlyAdmin {
//         devaddr_ = _dev;
//     }
// }



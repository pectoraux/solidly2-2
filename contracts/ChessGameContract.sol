// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;
// pragma experimental ABIEncoderV2;

// import "./Library.sol";

// contract ChessGameContract {
//     using EnumerableSet for EnumerableSet.UintSet;

//     address public devaddr_;
//     address public immutable factory; // the BaseV1Factory
//     address public immutable nft;

//     EnumerableSet.UintSet private pieces;
//     EnumerableSet.UintSet private players;
//     enum PIECE {
//         undefined,
//         blackpawn1,
//         whitepawn1,
//         blackpawn2,
//         whitepawn2,
//         blackpawn3,
//         whitepawn3,
//         blackpawn4,
//         whitepawn4,
//         blackpawn5,
//         whitepawn5,
//         blackpawn6,
//         whitepawn6,
//         blackpawn7,
//         whitepawn7,
//         blackpawn8,
//         whitepawn8,
//         blackbishop1,
//         whitebishop1,
//         blackbishop2,
//         whitebishop2,
//         blackknight1,
//         whiteknight1,
//         blackknight2,
//         whiteknight2,
//         blackrook1,
//         whiterook1,
//         blackrook2,
//         whiterook2,
//         blackqueen,
//         whitequeen,
//         blackking,
//         whiteking
//     }
//     uint public constant NUM_PIECES = 32;
//     uint public round = 1;
//     uint public currPlayer;
//     uint public currGameEnd;
//     uint public MaxGameDuration = 86400;
//     struct Board {
//         uint piece;
//         string move;
//         uint deadline;
//     }
//     mapping(uint => Board) private board;
//     uint public pieceFee = 10;
//     uint public moveFee = 10;
//     uint public MoveDeadline = 3600;
//     uint private gameId = 1;
//     mapping(uint => uint[]) private games;
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
//         address _nft
//     ) {
//         // Only Mine contract will be able to mint new tokens
//         devaddr_ = msg.sender;
//         factory = _factory;
//         nft = _nft;
//         for (uint i = 0; i < NUM_PIECES; i++) {
//             pieces.add(i);
//         }
//     }
//     //-------------------------------------------------------------------------
//     // STATE MODIFYING FUNCTIONS 
//     //-------------------------------------------------------------------------
//     function updateDev(address _dev) external onlyAdmin {
//         devaddr_ = _dev;
//     }

//     function getChainID() public view returns (uint256) {
//         uint256 id;
//         assembly {
//             id := chainid()
//         }
//         return id;
//     }

//     function updateFees(
//         uint _pieceFee, 
//         uint _moveFee
//     ) external onlyAdmin {
//         pieceFee = _pieceFee;
//         moveFee = _moveFee;
//     }

//     function updateParams(uint _newMax, uint _moveDeadline) external onlyAdmin {
//         MaxGameDuration = _newMax;
//         MoveDeadline = _moveDeadline;
//     }

//     function getPiece(uint _tokenId) external {
//         require(IGameNFT(nft).getTicketOwner(_tokenId) == msg.sender, "Only owner");
//         (address _game,,,,,,) = IGameNFT(nft).getGameSpecs(_tokenId);
//         require(_game == address(this), "Get this game's name on your NFT at the factory");
//         require(currGameEnd == 0, "Game not yet ended!");
//         require(players.length() < NUM_PIECES, "No peice available");
//         IGameFactory(factory).sponsorGame(
//             address(this), 
//             msg.sender, 
//             pieceFee
//         );
//         players.add(_tokenId);
//         if (players.length() == NUM_PIECES) {
//             startGame();
//         }
//     }

//     function startGame() internal {
//         uint randomNumber = block.timestamp;
//         for (uint i = 0; i < players.length(); i++) {
//             randomNumber += players.at(i);
//         }
//         uint _length;
//         while (players.length() > 0 && _length == NUM_PIECES) {
//             uint randPlayer = players.at(randomNumber % players.length());
//             uint randPiece = pieces.at(_length++);
//             board[randPlayer] = Board({
//                 piece: randPiece,
//                 move: "",
//                 deadline: 0
//             });
//         }
//         gameId++;
//         currGameEnd = block.timestamp + MaxGameDuration;
//     }

//     function move(uint _tokenId, string memory _move) external {
//         require(players.length() == 0, "Not available");
//         require(block.timestamp <= currGameEnd, "Game ended");
//         if (currPlayer != 0 && board[currPlayer].deadline < block.timestamp) {
//             require((currPlayer % 2) != (board[_tokenId].piece % 2), "Not color's turn");
//         }
//         if (currPlayer != _tokenId) {
//             require(board[currPlayer].deadline < block.timestamp || currPlayer == 0, "Current player's time");
//         }

//         IGameFactory(factory).sponsorGame(
//             address(this), 
//             msg.sender, 
//             moveFee
//         );
//         board[_tokenId].move = _move;
//         if (currPlayer != _tokenId) {
//             board[_tokenId].deadline = block.timestamp + MoveDeadline;
//             currPlayer = _tokenId;
//             games[gameId].push(_tokenId);
//         }
//     }

//     function endGame(uint _score, uint _winner) onlyAdmin external {
//         // score == 0 for no winner
//         for (uint i = 0; i < games[gameId].length; i++) {
//             uint _tokenId = games[gameId][i];
//             if ((_winner % 2) == (board[_tokenId].piece % 2)) { // same color
//                 IGameNFT(nft).updateScoreNDeadline(_tokenId, _score, 0);
//             }
//             delete board[_tokenId];
//         }
//         currPlayer = 0;
//         currGameEnd = 0;
//     }

// }



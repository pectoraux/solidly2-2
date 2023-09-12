// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;
// pragma experimental ABIEncoderV2;

// import "./Percentile.sol";

// contract BadgeNFT is ERC1155Pausable, Ownable {
//     // State variables 

//     // Storage for ticket information
//     struct TicketInfo {
//         address owner;
//         address factory;
//         address gauge;
//         uint date;
//         int rating;
//         string ratingString;
//         string ratingDescription;
//     }
//     mapping(uint => string) internal ratingApi; // off-chain api used instead of ticketInfo
//     // Token ID => Token information 
//     mapping(uint256 => TicketInfo) public ticketInfo_;
//     // User address =>  Ticket IDs
//     mapping(address => uint256[]) public userTickets_;
//     uint public ticketID = 1;
//     address internal devaddr_;
//     uint public totalSupply_;
//     //-------------------------------------------------------------------------
//     // EVENTS
//     //-------------------------------------------------------------------------

//     event InfoBatchMint(
//         address indexed receiving, 
//         string[] indexed codes, 
//         uint256[] tokenIds,
//         uint time
//     );
//     //-------------------------------------------------------------------------
//     // MODIFIERS
//     //-------------------------------------------------------------------------

//     /**
//      * @notice  Restricts minting of new tokens to only the rpmine contract.
//      */
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
//      * @param   _uri A dynamic URI that enables individuals to view information
//      *          around their NFT token. To see the information replace the 
//      *          `\{id\}` substring with the actual token type ID. For more info
//      *          visit:
//      *          https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
//      */
//     constructor(string memory _uri) ERC1155(_uri) {
//         devaddr_ = msg.sender;
//     }
    
//     //-------------------------------------------------------------------------
//     // VIEW FUNCTIONS
//     //-------------------------------------------------------------------------
//     function getUserTicketsPagination(
//         address _user, 
//         uint256 first, 
//         uint256 last
//     ) 
//         external 
//         view 
//         returns (uint256[] memory) 
//     {
//         uint length;
//         for (uint256 i = 0; i < userTickets_[_user].length; i++) {
//             uint256 _ticketID = userTickets_[_user][i];
//             uint256 date = ticketInfo_[_ticketID].date;
//             if (date >= first && date <= last) length++;
//         }
//         uint256[] memory values = new uint[](length);
//         uint j;
//         for (uint256 i = 0; i < userTickets_[_user].length; i++) {
//             uint256 _ticketID = userTickets_[_user][i];
//             uint256 date = ticketInfo_[_ticketID].date;
//             if (date >= first && date <= last) {
//                 values[j] = _ticketID;
//                 j++;
//             }
//         }
//         return values;
//     }

//     function getTicketRating(uint _tokenId) external view
//     returns(string memory, string memory, int) {
//         return (
//             ticketInfo_[_tokenId].ratingDescription,
//             ticketInfo_[_tokenId].ratingString,
//             ticketInfo_[_tokenId].rating
//         );
//     }

//     function getTicketAuditor(uint _tokenId) external view returns(address,address) {
//         return (
//             ticketInfo_[_tokenId].factory,
//             ticketInfo_[_tokenId].gauge
//         );
//     }

//     function getTicketOwner(uint _tokenId) external view returns(address) {
//         return ticketInfo_[_tokenId].owner;
//     }

//     //-------------------------------------------------------------------------
//     // STATE MODIFYING FUNCTIONS 
//     //-------------------------------------------------------------------------
//     function batchMint(
//         address _to,
//         address _gauge,
//         uint256 _numberOfTickets,
//         int256 _rating,
//         string memory _rating_string,
//         string memory _rating_description
//     )
//         external
//         onlyAdmin
//         returns(uint256[] memory)
//     {
//         // Storage for the amount of tokens to mint (always 1)
//         uint256[] memory amounts = new uint256[](_numberOfTickets);
//         // Storage for the token IDs
//         uint256[] memory tokenIds = new uint256[](_numberOfTickets);
        
//         for (uint8 i = 0; i < _numberOfTickets; i++) {
//             // Incrementing the tokenId counter
//             uint256 _date = block.timestamp;
//             tokenIds[i] = ticketID++;
//             amounts[i] = 1;
//             // Storing the ticket information 
//             ticketInfo_[tokenIds[i]] = TicketInfo({
//                 owner: _to,
//                 factory: msg.sender,
//                 gauge: _gauge,
//                 date: _date,
//                 rating: _rating,
//                 ratingString: _rating_string,
//                 ratingDescription: _rating_description
//             });
//             totalSupply_ += 1;
//             userTickets_[_to].push(tokenIds[i]);
//         }
        
//         // Minting the batch of tokens
//         _mintBatch(
//             _to,
//             tokenIds,
//             amounts,
//             msg.data
//         );

//         // // Emitting relevant info
//         // emit InfoBatchMint(
//         //     _to, 
//         //     _numberOfTickets, 
//         //     tokenIds,
//         //     block.timestamp
//         // ); 
//         // Returns the token IDs of minted tokens
//         return tokenIds;
//     }

//     function updateDev(address _dev) external onlyAdmin {
//         devaddr_ = _dev;
//     }

//     function updateApi(uint _tokenId, string memory _api) external {
//         require(msg.sender == ticketInfo_[_tokenId].gauge, "Only auditor gauge");
//         ratingApi[_tokenId] = _api;
//     }

//     function updateInfo(
//         uint _tokenId,
//         int _rating,
//         string memory _ratingString,
//         string memory _ratingDescription
//     ) external {
//         require(msg.sender == ticketInfo_[_tokenId].gauge, "Only auditor gauge");
        
//         ticketInfo_[_tokenId].rating = _rating;
//         ticketInfo_[_tokenId].ratingString = _ratingString;
//         ticketInfo_[_tokenId].ratingDescription = _ratingDescription;
//     }

//     function burn(
//         address account, 
//         uint256 id, 
//         uint256 amount
//     ) external {
//         require(msg.sender == ticketInfo_[id].owner || msg.sender == devaddr_, "Only owner or admin");
//         _burn(account, id, amount);
//     }

//     //-------------------------------------------------------------------------
//     // INTERNAL FUNCTIONS 
//     //-------------------------------------------------------------------------

//     /**
//      * @dev See {ERC1155-_beforeTokenTransfer}.
//      *
//      * Requirements:
//      *
//      * - the contract must not be paused.
//      */
//     function _beforeTokenTransfer(
//         address operator,
//         address from,
//         address to,
//         uint256[] memory ids,
//         uint256[] memory amounts,
//         bytes memory data
//     )
//         internal
//         virtual
//         override
//     {
//         super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

//         for(uint i = 0; i < ids.length; i++) {
//             require(ticketInfo_[ids[i]].factory == msg.sender, "Only factory!");
//             ticketInfo_[ids[i]].owner = to;
//         }
//     }

//     function _burn(
//         address account, 
//         uint256 id, 
//         uint256 amount
//     ) internal virtual override{     
//         super._burn(account, id, amount);
//         delete ticketInfo_[id];
//         totalSupply_ = totalSupply_ >= 1 ? totalSupply_ -1 : 0;
//     }
// }


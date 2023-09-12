// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;
// pragma experimental ABIEncoderV2;

// import "./Percentile.sol";

// contract BallerNFT2 is ERC1155Pausable, Percentile {
//     // Storage for ticket information
//     struct TicketInfo {
//         address owner;
//         address lender;
//         uint percentile;
//         bool active;
//         uint date;
//         uint timer;
//         uint price; //does not display
//         string sponsoredMessage;
//     }
//     // Token ID => Token information 
//     mapping(uint256 => TicketInfo) public ticketInfo_;
//     // User address =>  Ticket IDs
//     uint[] public allTickets_;
//     mapping(address => uint256[]) public userTickets_;
//     uint public _percentile;
//     uint public pricePerAttachMinutes = 1;
//     uint internal constant minute = 3600; // allows minting once per week (reset every Thursday 00:00 UTC)
//     uint public active_period;
//     uint public ticketID = 1;
//     mapping(uint => string) public sponsoredMessages;
//     uint256 public constant MAX_PRICE = 80000000000000000; //0.08 ETH
//     uint256 public rpPrice_; //0 ETH
//     uint public totalSupply_;
//     mapping(uint => bool) public attached;
//     uint public Q1 = 1;
//     uint public Q2 = 25;
//     uint public Q3 = 50;
//     uint public Q4 = 75;
//     enum SERIES {
//         UNDEFINED,
//         X,
//         S
//     }
//     SERIES public series;
//     uint public MaximumArraySize = 50;
//     mapping(uint => bool) public blacklist;
//     address public devaddr_;
//     uint[4] public boosts;
//     address public token;
//     uint public lastClaimedRound = 1;
//     uint public linkFee = 1;
//     uint public span = 10000;
//     uint public Range = 1000000;
//     uint TEST_CHAIN = 31337;
//     IRandomNumberGenerator randomGenerator_;

//     //-------------------------------------------------------------------------
//     // EVENTS
//     //-------------------------------------------------------------------------

//     event InfoBatchMint(
//         address indexed receiving, 
//         string[] indexed codes, 
//         uint256[] tokenIds,
//         uint time
//     );

//     event Message(address indexed from, uint tokenId,uint time);
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
//      * @param   _uri A dynamic URI that enables individuals to view information
//      *          around their NFT token. To see the information replace the 
//      *          `\{id\}` substring with the actual token type ID. For more info
//      *          visit:
//      *          https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
//      */
//     constructor(
//         uint _series,  // series S & series X are Payswap's main series
//         string memory _uri,
//         address _token,
//         address _randomGenerator        
//     ) 
//     ERC1155(_uri)
//     {
//         devaddr_ = msg.sender;
//         token = _token;
//         series = SERIES(_series);
//         randomGenerator_ = IRandomNumberGenerator(_randomGenerator);
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
//         returns (uint256[] memory, uint256) 
//     {
//         uint256 totalPrice;
//         uint length;
//         for (uint256 i = 0; i < userTickets_[_user].length; i++) {
//             uint256 _ticketID = userTickets_[_user][i];
//             uint256 date = ticketInfo_[_ticketID].date;
//             if (date >= first && date <= last) {
//                 unchecked {
//                     length++;                
//                 }
//             }
//         }
//         uint256[] memory values = new uint[](length);
//         uint j;
//         for (uint256 i = 0; i < userTickets_[_user].length; i++) {
//             uint256 _ticketID = userTickets_[_user][i];
//             uint256 date = ticketInfo_[_ticketID].date;
//             if (date >= first && date <= last) {
//                 totalPrice = totalPrice + ticketInfo_[_ticketID].price;
//                 values[j] = _ticketID;
//                 unchecked {
//                     j++;
//                 }
//             }
//         }
//         return (values, totalPrice);
//     }

//     function getReceiver(uint _tokenId) public view returns(address) {
//         return ticketInfo_[_tokenId].lender == address(0) ?
//         ticketInfo_[_tokenId].owner : ticketInfo_[_tokenId].lender;
//     }

//     function getTicketOwner(uint _tokenId) public view returns(address) {
//         return ticketInfo_[_tokenId].owner;
//     }

//     function getTicketDate(uint _tokenId) external view returns(uint) {
//         return ticketInfo_[_tokenId].date;
//     }

//     function getTicketPrice(uint _tokenId) external view returns(uint) {
//         return ticketInfo_[_tokenId].price;
//     }

//     function getTicketsPagination(
//         uint256 first, 
//         uint256 last
//     ) 
//         public 
//         view 
//         returns (uint256[] memory) 
//     {
//         uint length;
//         for (uint256 i = 0; i < allTickets_.length; i++) {
//             uint256 _ticketID = allTickets_[i];
//             uint256 date = ticketInfo_[_ticketID].date;
//             if (date >= first && date <= last) length++;
//         }
//         uint256[] memory values = new uint[](length);
//         uint j;
//         for (uint256 i = 0; i < allTickets_.length; i++) {
//             uint256 _ticketID = allTickets_[i];
//             uint256 date = ticketInfo_[_ticketID].date;
//             if (date >= first && date <= last) {
//                 values[j] = _ticketID;
//                 j++;
//             }
//         }
//         return values;
//     }

//     function getChainID() public view returns (uint256) {
//         uint256 id;
//         assembly {
//             id := chainid()
//         }
//         return id;
//     }
//     //-------------------------------------------------------------------------
//     // STATE MODIFYING FUNCTIONS 
//     //-------------------------------------------------------------------------
//     function updateDev(address _devaddr) external onlyAdmin {
//         devaddr_ = _devaddr;
//     }

//     function updateQs(uint q1, uint q2, uint q3, uint q4) external onlyAdmin {
//         require(q1 < q2, "Invalid Q1");
//         require(q2 < q3, "Invalid Q2");
//         require(q3 < q4, "Invalid Q3");
//         Q1 = q1;
//         Q2 = q2;
//         Q3 = q3;
//         Q4 = q4;
//     }   

//     function updateBlacklist(uint[] memory _tokenIds, bool[] memory _blacklists) external onlyAdmin {
//         require(_tokenIds.length == _blacklists.length, "Blackist: Uneven lists");
//         for (uint i = 0; i < _tokenIds.length; i++) {
//             blacklist[_tokenIds[i]] = _blacklists[i];
//         }
//     }

//     function updateMaxArraySize(uint _maxArrSize) external onlyAdmin {
//         MaximumArraySize = _maxArrSize;
//     }

//     function updatePricePerAttachMinutes(uint _pricePerAttachMinutes) external onlyAdmin {
//         pricePerAttachMinutes = _pricePerAttachMinutes;
//     }

//     function batchMint(
//         address _to,
//         uint256 __percentile,
//         uint256 _meanPaid,
//         uint256 _numberOfTickets
//     )
//         external
//         onlyAdmin
//         returns(uint256[] memory)
//     {   
//         require(
//             _numberOfTickets <= MaximumArraySize,
//             "Batch mint too large"
//         );
//         if (__percentile > 0 && _meanPaid == 0) {
//             _meanPaid = getPaid4Percentile(__percentile);
//         }
//         // Storage for the amount of tokens to mint (always 1)
//         uint256[] memory amounts = new uint256[](_numberOfTickets);
//         // Storage for the token IDs
//         uint256[] memory tokenIds = new uint256[](_numberOfTickets);
//         int256 _zscore = computePercentile(_meanPaid);
        
//         for (uint8 i = 0; i < _numberOfTickets; i++) {
//             // Incrementing the tokenId counter
//             uint256 _date = block.timestamp;
//             allTickets_.push(ticketID);
//             unchecked {
//                 tokenIds[i] = ticketID++;
//             }
//             amounts[i] = 1;
//             // Storing the ticket information 
//             ticketInfo_[tokenIds[i]] = TicketInfo({
//                 owner: _to,
//                 lender: address(0),
//                 percentile: getPercentile(_zscore),
//                 active: true,
//                 date: _date,
//                 timer: 0,
//                 price: _meanPaid,
//                 sponsoredMessage: ""
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

//     function addSponsoredMessages(uint _tokenId, string memory _message) external {
//         require(msg.sender == ticketInfo_[_tokenId].owner, "PayERC1155: Only owner");
//         sponsoredMessages[_tokenId] = _message;
//     }

//     function batchAttach(uint256[] memory _tokenIds, uint256 _period, address _lender) external { 
//         for (uint8 i = 0; i < _tokenIds.length; i++) {
//             attach(_tokenIds[i], _period, _lender);
//         }
//     }

//     function attach(uint256 _tokenId, uint256 _period, address _lender) public { 
//         //can be used for collateral for lending
//         require(ticketInfo_[_tokenId].owner == msg.sender, "PayERC1155: Only owner!");
//         require(!attached[_tokenId], "PayERC1155: Attached!");
//         attached[_tokenId] = true;
//         ticketInfo_[_tokenId].lender = _lender;
//         ticketInfo_[_tokenId].timer = block.timestamp + _period;
//     }

//     function batchDetach(uint256[] memory _tokenIds) external {
//         for (uint8 i = 0; i < _tokenIds.length; i++) {
//             detach(_tokenIds[i]);
//         }
//     }

//     function detach(uint _tokenId) public {
//         require(ticketInfo_[_tokenId].timer <= block.timestamp, "PayERC1155: Timer not up!");
//         attached[_tokenId] = false;
//         ticketInfo_[_tokenId].lender = address(0);
//         ticketInfo_[_tokenId].timer = 0;   
//     }

//     function killTimer(uint256 _tokenId) external {
//         require(ticketInfo_[_tokenId].lender == msg.sender, "PayERC1155: Only lender!");
//         ticketInfo_[_tokenId].timer = 0;
//     }

//     function decreaseTimer(uint256 _tokenId, uint256 _timer) external {
//         require(ticketInfo_[_tokenId].lender == msg.sender, "PayERC1155: Only lender!");
//         ticketInfo_[_tokenId].timer -= _timer;
//     }

//     function updateBoosts(uint[4] memory _boosts) external onlyAdmin {
//         require(_boosts.length == 4, "Invalid number of boosts");
//         boosts = _boosts;
//     }

//     function boostingPower(uint _tokenId) external view returns(uint result) {
//         require(ticketInfo_[_tokenId].owner != address(0), "Does not exist");
//         if (ticketInfo_[_tokenId].percentile >= Q4) {
//             result = boosts[3];
//         } else if (ticketInfo_[_tokenId].percentile >= Q3) {
//             result = boosts[2];
//         } else if (ticketInfo_[_tokenId].percentile >= Q2) {
//             result = boosts[1];
//         } else if (ticketInfo_[_tokenId].percentile >= Q1) {
//             result = boosts[0];
//         }
//     }

//     function changePrice(uint _rpPrice) external onlyAdmin {
//         require(_rpPrice <= MAX_PRICE, "PayERC1155: Price too high");
//         rpPrice_ = _rpPrice;
//     }

//     function updateLinkFeeNSpan(uint _fee, uint _span, uint _range) external onlyAdmin {
//         linkFee = _fee;
//         span = _span;
//         Range = _range;
//     }

//     function requestRandomNumber() external {
//         _safeTransferFrom(token, msg.sender, address(this), linkFee);
//         if (getChainID() != TEST_CHAIN) {
//             randomGenerator_.randomnessIsRequestedHere(1, msg.sender);
//         }
//     }

//     function checkWin(uint _tokenId, uint _randNumberFromUser) external  returns(uint _diff) {
//         require(getReceiver(_tokenId) == msg.sender, "Only receiver");
//         uint[] memory randomNumbers = 
//         randomGenerator_.viewRandomNumbers(lastClaimedRound, msg.sender);
//         uint _randNumberFromLink = randomNumbers[0] % Range;
//         _diff = _randNumberFromLink > _randNumberFromUser ? 
//         _randNumberFromLink - _randNumberFromUser : _randNumberFromUser - _randNumberFromLink;
//         if (_diff <= span) {
//             _safeTransfer(
//                 token,
//                 msg.sender,
//                 erc20(token).balanceOf(address(this))
//             );
//         }
//         lastClaimedRound++;
//     }

//     function messageAll(uint _tokenId, uint _amount, string memory _message) external {
//         batchMessage(_tokenId, allTickets_, _amount, _message);
//     }

//     function messageFromTo(uint _tokenId, uint _amount, uint _first, uint _last, string memory _message) external {
//         uint[] memory _tokenIds = getTicketsPagination(_first, _last);
//         batchMessage(_tokenId, _tokenIds, _amount, _message);
//     }

//     function batchMessage(uint _tokenId, uint[] memory _tokenIds, uint _amount, string memory _message) public {
//         require(getReceiver(_tokenId) == msg.sender, "Invalid token ID");
//         require(active_period < block.timestamp, "Current message not yet expired");
//         _safeTransferFrom(
//             token,
//             address(msg.sender), 
//             address(this),
//             _amount * pricePerAttachMinutes
//         );
//         active_period = (block.timestamp + (_amount*minute)) / minute * minute;
//         for (uint i = 0; i < _tokenIds.length; i++) {
//             ticketInfo_[_tokenIds[i]].sponsoredMessage = _message;
//         }

//         emit Message(msg.sender, _tokenId, block.timestamp);
//     }

//     function withdrawTreasury(address _token) external onlyAdmin {
//         _token = _token == address(0) ? token : _token;
//         _safeTransfer(
//             _token,
//             msg.sender,
//             erc20(_token).balanceOf(address(this))
//         );
//     }

//     function withdrawRoyalties(address payable _to) external onlyAdmin {
//         uint balance = address(this).balance;
//         _to.transfer(balance);
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

//         if (msg.sender != devaddr_) {
//             require(rpPrice_ * totalSupply_ <= msg.value, "PayERC1155: Ether value sent is not correct");
//         }

//         for(uint i = 0; i < ids.length; i++) {
//             ticketInfo_[ids[i]].owner = to;
//             require(!attached[ids[i]] && !blacklist[ids[i]], "PayERC1155: Attached!");
//         }
//     }

//     function _burn(
//         address account, 
//         uint256 id, 
//         uint256 amount
//     ) internal virtual override onlyAdmin {     
//         super._burn(account, id, amount);
//         delete ticketInfo_[id];
//         totalSupply_ = totalSupply_ >= 1 ? totalSupply_ -1 : 0;
//     }

//     function _isContract(address account) internal view returns (bool) {
//         // This method relies on extcodesize, which returns 0 for contracts in
//         // construction, since the code is only stored at the end of the
//         // constructor execution.
//         uint _size;
//         assembly {
//             _size := extcodesize(account)
//         }
//         return _size > 0;
//     }

//     function safeTransferNAttach(
//         address attachTo,
//         uint period,
//         address from,
//         address to,
//         uint256 id,
//         uint256 amount,
//         bytes memory data
//     ) external {
//         super.safeTransferFrom(from, to, id, amount, data);
//         attach(id, period, attachTo);
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
// }
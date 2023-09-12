// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;
// pragma experimental ABIEncoderV2;

// import "./Library.sol";

// contract MeltedNFT is Auth, ERC1155Pausable, ReentrancyGuard {
//     uint256 public totalSupply_;
//     mapping(uint => string) public sponsoredMessages;
//     uint public pricePerAttachMinutes = 1;
//     uint internal constant minute = 3600; // allows minting once per week (reset every Thursday 00:00 UTC)
//     uint public active_period;

//     // Storage for ticket information
//     struct TicketInfo {
//         address owner;
//         address lender;
//         uint timer;
//         uint date;
//         address collection;
//         uint percentage;
//     }
//     enum SponsorshipType {
//         text,
//         video
//     }
//     struct TicketSponsor {
//         SponsorshipType stype;
//         string videoCid;
//         string message;
//         uint deadline;
//     }
//     mapping(uint => TicketSponsor) internal ticketSponsors;
//     mapping(uint => uint[]) public userTokenIds;
//     mapping(uint => uint[]) public actual_tokenIds;
//     // Token ID => Token information 
//     mapping(uint256 => TicketInfo) public ticketInfo_;
//     uint256 public ticketID = 1;
//     uint TEST_CHAIN = 31337;
//     address public token;
//     address public devaddr_;
//     // User address =>  Ticket IDs
//     mapping(address => uint256[]) public userTickets_;
//     uint[] public allTickets_;
//     mapping(uint => bool) public attached;
//     mapping(uint => mapping(address => uint[])) public backings;
//     mapping(uint => mapping(uint => uint)) public isNFTLockable;
//     uint public MaximumArraySize = 50;
//     IRandomNumberGenerator randomGenerator_;
//     uint public lastClaimedRound = 1;
//     uint public linkFee = 1;
//     uint public span = 10000;
//     uint public Range = 1000000;
//     //-------------------------------------------------------------------------
//     // EVENTS
//     //-------------------------------------------------------------------------

//     event InfoBatchMint(
//         address indexed receiving, 
//         uint256 amountOfTokens, 
//         uint256[] tokenIds
//     );
    
//     event Message(address indexed from, uint tokenId,uint time);

//     //-------------------------------------------------------------------------
//     // MODIFIERS
//     //-------------------------------------------------------------------------
    

//     modifier isNotContract() {
//         require(!_isContract(msg.sender), "Contracts not allowed");
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
//         address _token,
//         string memory _uri,
//         address _randomGenerator
//     ) 
//     ERC1155(_uri)
//     {
//         // Only Mine contract will be able to mint new tokens
//         token = _token;
//         devaddr_ = msg.sender;
//         randomGenerator_ = IRandomNumberGenerator(_randomGenerator);
//     }

//     //-------------------------------------------------------------------------
//     // VIEW FUNCTIONS
//     //-------------------------------------------------------------------------
//      function getUserTicketsPagination(
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

//     function getReceiver(uint _tokenId) public view returns(address) {
//         return ticketInfo_[_tokenId].lender == address(0) ?
//         ticketInfo_[_tokenId].owner : ticketInfo_[_tokenId].lender;
//     }
//     //-------------------------------------------------------------------------
//     // STATE MODIFYING FUNCTIONS 
//     //-------------------------------------------------------------------------
//     function updateMaximumArraySize(uint _newMax) external onlyAdmin {
//         MaximumArraySize = _newMax;
//     }

//     function updatePricePerAttachMinutes(uint _pricePerAttachMinutes) external onlyAdmin {
//         pricePerAttachMinutes = _pricePerAttachMinutes;
//     }

//     function messageAll(uint _numMinutes, bool _video, string memory _message) external {
//         batchMessage(allTickets_, _numMinutes, _video, _message);
//     }

//     function messageFromTo(
//         uint _numMinutes, 
//         uint _first, 
//         uint _last, 
//         bool _video,
//         string memory _message
//     ) external {
//         uint[] memory _tokenIds = getTicketsPagination(_first, _last);
//         batchMessage(_tokenIds, _numMinutes, _video, _message);
//     }

//     function batchMessage(
//         uint[] memory _tokenIds, 
//         uint _numMinutes,
//         bool _video,
//         string memory _message
//     ) public {
//         checkIdentityProof(msg.sender, false);
//         require(active_period < block.timestamp, "Current message not yet expired");
//         _safeTransferFrom(
//             token,
//             address(msg.sender), 
//             address(this),
//             _numMinutes * pricePerAttachMinutes
//         );
//         active_period = (block.timestamp + (_numMinutes*minute)) / minute * minute;
//         for (uint i = 0; i < _tokenIds.length; i++) {
//             ticketSponsors[_tokenIds[i]].stype = _video ? SponsorshipType.video : SponsorshipType.text;
//             if (_video) {
//                 ticketSponsors[_tokenIds[i]].videoCid = _message;
//             } else {
//                 ticketSponsors[_tokenIds[i]].message = _message;
//             }
//             ticketSponsors[_tokenIds[i]].deadline = active_period;
//         }

//         emit Message(msg.sender, _tokenIds, block.timestamp);
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

//     function withdrawTreasury(address _token) external onlyAdmin {
//         _token = _token == address(0) ? token : _token;
//         _safeTransfer(
//             _token,
//             msg.sender,
//             erc20(_token).balanceOf(address(this))
//         );
//     }

//     /**
//      * @param   _to The address being minted to
//      * @param   _numberOfTickets The number of NFT's to mint
//      * @notice  Only the lotto contract is able to mint tokens. 
//         // uint8[][] calldata _lottoNumbers
//      */
//     function lockToken(
//         address _to,
//         uint _numberOfTickets,
//         address _collection,
//         uint[] memory _tokenIds,
//         uint[] memory _amounts
//     )
//         nonReentrant
//         external
//         returns(uint256[] memory tokenIds)
//     {   
//         require(_to != address(0), "Invalid Owner");
//         require(_amounts.length == _tokenIds.length, "Uneven lists");
//         require(_numberOfTickets <= MaximumArraySize, "Too many tickets");
//         // transfer without changing owner so owner can still get
//         // selected randomly for rewards
//         IERC1155(_collection).safeBatchTransferFrom(
//             msg.sender, 
//             address(this), 
//             _tokenIds,
//             _amounts,
//             msg.data
//         );

//         // Storage for the amount of tokens to mint (always 1)
//         uint256[] memory amounts = new uint256[](_numberOfTickets);
//         // Storage for the token IDs
//         tokenIds = new uint256[](_numberOfTickets);
//         uint _offset;
//         for (uint8 i = 0; i < _numberOfTickets; i++) {
//             // Incrementing the tokenId counter
//             uint _date = block.timestamp;
//             allTickets_.push(ticketID);
//             tokenIds[i] = ticketID++;
//             amounts[i] = 1;
//             uint _percentage = _tokenIds.length * 10000 / _numberOfTickets;
//             for (uint j = _offset; j < _offset+_percentage / 10000; j++) {
//                 actual_tokenIds[tokenIds[i]].push(_tokenIds[j]);
//             }
//             _offset = _percentage / 10000;
//             // Storing the ticket information 
//             ticketInfo_[tokenIds[i]] = TicketInfo({
//                 owner: _to,
//                 lender: address(0),
//                 timer: 0,
//                 date: _date,
//                 collection: _collection,
//                 percentage: _percentage
//             });
//             userTokenIds[tokenIds[i]] = _tokenIds;
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
//     }

    
//     function unlockToken(uint256[] memory _tokenIds) external nonReentrant {
//         bool skip;
//         for (uint i = 0; i < _tokenIds.length; i++) {
//             uint _tokenId = _tokenIds[i];
//             require(ticketInfo_[_tokenId].owner == msg.sender, "Only owner!");

//             uint _length = actual_tokenIds[_tokenId].length;
//             uint[] memory actual_amounts = new uint[](_length);
//             for (uint j = 0; i < _length; j++) {
//                 actual_amounts[j] = 1;
//             }
//             if (ticketInfo_[_tokenId].percentage >= 10000) {
//                 IERC1155(ticketInfo_[_tokenId].collection).safeBatchTransferFrom(
//                     address(this), 
//                     msg.sender,
//                     actual_tokenIds[_tokenId],
//                     actual_amounts,
//                     msg.data
//                 );
//             } else if (!skip) {
//                 skip = true;
//                 actual_amounts = new uint[](1);
//                 actual_amounts[0] = 1;
//                 IERC1155(ticketInfo_[_tokenId].collection).safeBatchTransferFrom(
//                     address(this), 
//                     msg.sender,
//                     userTokenIds[_tokenIds[0]],
//                     actual_amounts,
//                     msg.data
//                 );
//             }
//             _burn(msg.sender, _tokenId, 1);
//             totalSupply_ = totalSupply_ >= 1 ? totalSupply_-1 : 0;
//             delete ticketInfo_[_tokenId];
//             delete actual_tokenIds[_tokenId];
//         }
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

//     function updateDev(address _dev) external onlyAdmin {
//         devaddr_ = _dev;
//     }

//     function withdrawRoyalties(address payable _to) external onlyAdmin {
//         uint balance = address(this).balance;
//         _to.transfer(balance);
//     }

//     function withdrawNonFungible(address _token, uint _tokenId) external onlyAdmin {
//         IERC721(_token).safeTransferFrom(address(this), address(msg.sender), _tokenId);
//     }

//     function withdrawFungible(address _token, uint _amount) external onlyAdmin {
//         _safeTransferFrom(_token, address(this), address(msg.sender), _amount);
//     }

//     function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
//         return this.onERC1155Received.selector;
//     }

//     function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
//         return this.onERC1155BatchReceived.selector;
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
//             ticketInfo_[ids[i]].owner = to;
//             require(!attached[ids[i]], "PayERC1155: Attached!");
//         }
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

//     function st2num(string memory numString) public pure returns(uint) {
//         uint  val=0;
//         bytes   memory stringBytes = bytes(numString);
//         for (uint  i =  0; i<stringBytes.length; i++) {
//             uint exp = stringBytes.length - i;
//             bytes1 ival = stringBytes[i];
//             uint8 uval = uint8(ival);
//            uint jval = uval - uint(0x30);
   
//            val +=  (uint(jval) * (10**(exp-1))); 
//         }
//       return val;
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
// }



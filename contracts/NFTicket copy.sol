// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;
// pragma experimental ABIEncoderV2;

// import "./Library.sol";

// contract NFTicket is ERC721Pausable {
//     using EnumerableSet for EnumerableSet.UintSet;

//     uint256 public totalSupply_;
//     mapping(uint => EnumerableSet.UintSet) private merchantMessages;
//     uint public maxMessage = 100;
//     uint public minSuperChat = 1;
//     enum Source {
//         Local,
//         External
//     }
//     // Storage for ticket information
//     struct TicketInfo {
//         address owner;
//         address lender;
//         uint merchant;
//         uint timer;
//         uint date;
//         uint price;
//         uint timeEstimate;
//         bool active;
//         bool transferrable;
//         string item;
//         string superChatOwner;
//         string superChatResponse;
//         Source source;
//     }
//     mapping(uint => string[]) private options;
//     // Token ID => Token information 
//     mapping(uint256 => TicketInfo) public ticketInfo_;
//     uint256 public ticketID = 1;
//     address public devaddr_;
//     // User address => Merchant address => Ticket IDs
//     mapping(address => mapping(uint => uint256[])) public userTickets_;
//     uint[] public allTickets_;
//     // Merchant address => User address => Ticket IDs
//     mapping(uint => mapping(address => uint256[])) public merchantTickets_;
//     // Merchant address => Ticket IDs
//     mapping(uint => uint256[]) public allMerchantTickets_;
//     mapping(uint => bool) public attached;
//     address private marketOrders;
//     address private marketTrades;
//     address private marketCollections;
//     uint public pricePerAttachMinutes = 1;
//     uint internal minute = 3600; // allows minting once per week (reset every Thursday 00:00 UTC)
//     address public token;
//     struct Channel {
//         string message;
//         uint active_period;
//     }
//     mapping(address => address) public taskContracts;
//     mapping(address => Channel) public channels;
//     mapping(uint => mapping(string => uint)) public timeEstimates;
//     struct Vote {
//         uint likes;
//         uint dislikes;
//     }
//     mapping(uint => Vote) public estimateVotes;
//     mapping(uint => mapping(uint => int)) public voted;
//     uint public adminFee = 1000;
//     uint public treasury;
//     mapping(uint => uint) public pendingRevenue;
//     // channel => set of trusted auditors
//     //-------------------------------------------------------------------------
//     // EVENTS
//     //-------------------------------------------------------------------------

//     event InfoMint(
//         uint indexed ticketID, 
//         address to,
//         uint merchant,
//         uint price, 
//         string item,
//         string[] options,
//         Source source
//     );
//     event Message(address indexed from, address channel, uint time);
//     event SuperChat(address indexed from, uint tokenId, uint time);
//     event Voted(uint indexed merchant, uint likes, uint dislikes, bool like);
//     event UpdateActive(uint indexed ticketID, bool active);
//     //-------------------------------------------------------------------------
//     // MODIFIERS
//     //-------------------------------------------------------------------------
//     modifier onlyAdmin() {
//         require(
//             msg.sender == devaddr_ || msg.sender == marketTrades,
//             "Only dev"
//         );
//         _;
//     }

//     //-------------------------------------------------------------------------
//     // CONSTRUCTOR
//     //-------------------------------------------------------------------------
//     constructor(
//         address _token, 
//         address _marketOrders, 
//         address _marketTrades,
//         address _marketCollections
//     ) ERC721("NFTicket", "NFTicket") {
//         // Only Mine contract will be able to mint new tokens
//         token = _token;
//         devaddr_ = msg.sender;
//         marketTrades = _marketTrades;
//         marketOrders = _marketOrders;
//         marketCollections = _marketCollections;
//     }

//     // simple re-entrancy check
//     uint internal _unlocked = 1;
//     modifier lock() {
//         require(_unlocked == 1);
//         _unlocked = 2;
//         _;
//         _unlocked = 1;
//     }

//     //-------------------------------------------------------------------------
//     // VIEW FUNCTIONS
//     //-------------------------------------------------------------------------
//     /**
//      * @param   _ticketID: The unique ID of the ticket
//      * @return  uint32[]: The chosen numbers for that ticket
//      */
//     function getTicketOptions(
//         uint256 _ticketID
//     ) 
//         external 
//         view 
//         returns(string[] memory) 
//     {
//         return options[_ticketID];
//     }
    
//     function getUserTicketsPagination(
//         address _user, 
//         uint _merchant,
//         uint256 first, 
//         uint256 last
//     ) public view returns (uint256[] memory, uint256) {
//         uint256 totalPrice;
//         uint length;
//         for (uint256 i = 0; i < userTickets_[_user][_merchant].length; i++) {
//             uint256 _ticketID = userTickets_[_user][_merchant][i];
//             uint256 date = ticketInfo_[_ticketID].date;
//             if (date >= first && date <= last) length++;
//         }
//         uint256[] memory values = new uint[](length);
//         uint j;
//         for (uint256 i = 0; i < userTickets_[_user][_merchant].length; i++) {
//             uint256 _ticketID = userTickets_[_user][_merchant][i];
//             uint256 date = ticketInfo_[_ticketID].date;
//             if (date >= first && date <= last) {
//                 totalPrice = totalPrice + ticketInfo_[_ticketID].price;
//                 values[j] = _ticketID;
//                 j++;
//             }
//         }
//         return (values, totalPrice);
//     }

//     function getMerchantTicketsPagination(
//         uint _merchant,
//         uint256 first, 
//         uint256 last
//     ) 
//         public 
//         view 
//         returns (uint256[] memory, uint256) 
//     {
//         uint256 totalPrice;
//         uint length;
//         for (uint256 i = 0; i < allMerchantTickets_[_merchant].length; i++) {
//             uint256 _ticketID = allMerchantTickets_[_merchant][i];
//             uint256 date = ticketInfo_[_ticketID].date;
//             if (date >= first && date <= last) length++;
//         }
//         uint256[] memory values = new uint[](length);
//         uint j;
//         for (uint256 i = 0; i < allMerchantTickets_[_merchant].length; i++) {
//             uint256 _ticketID = allMerchantTickets_[_merchant][i];
//             uint256 date = ticketInfo_[_ticketID].date;
//             if (date >= first && date <= last) {
//                 totalPrice = totalPrice + ticketInfo_[_ticketID].price;
//                 values[j] = _ticketID;
//                 j++;
//             }
//         }
//         return (values, totalPrice);
//     }

//     function getReceiver(uint _tokenId) public view returns(address) {
//         return ticketInfo_[_tokenId].lender == address(0) ?
//         ticketInfo_[_tokenId].owner : ticketInfo_[_tokenId].lender;
//     }

//     function getTicketsPagination(
//         uint256 first, 
//         uint256 last
//     ) 
//         external
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
//     //-------------------------------------------------------------------------
//     // STATE MODIFYING FUNCTIONS 
//     //-------------------------------------------------------------------------
//     /**
//      * @param   _to The address being minted to
//      * @notice  Only the lotto contract is able to mint tokens. 
//         // uint8[][] calldata _lottoNumbers
//      */
//     function mint(
//         address _to,
//         uint _merchant,
//         uint _price,
//         string memory _item,
//         string[] memory _options,
//         bool _external
//     ) external returns(uint)  {   
//         require(devaddr_ == msg.sender || marketTrades == msg.sender, "Only dev");
//         uint _timeEstimate = timeEstimates[_merchant][_item];
//         for (uint i = 0; i < _options.length; i++) {
//             _timeEstimate += timeEstimates[_merchant][_options[i]];
//         }
//         Ask memory ask = IMarketPlace(marketOrders).getAskDetails(_merchant, keccak256(abi.encodePacked(_item)));
//         // Storage for the token IDs
//         // Incrementing the tokenId counter
//         totalSupply_ += 1;
//         Source _source = _external ? Source.Local : Source.External;
//         allTickets_.push(ticketID);
//         ticketInfo_[ticketID] = TicketInfo({
//             owner: _to,
//             merchant: _merchant,
//             lender: address(0x0),
//             timer: 0,
//             date: block.timestamp,
//             price: _price,
//             item: _item,
//             active: true,
//             timeEstimate: _timeEstimate,
//             transferrable: ask.transferrable,
//             superChatOwner: "",
//             superChatResponse: "",
//             source: _source
//         });
//         options[ticketID] = _options;
//         userTickets_[_to][_merchant].push(ticketID);
//         merchantTickets_[_merchant][_to].push(ticketID);
//         allMerchantTickets_[_merchant].push(ticketID);
//         _safeMint(_to, ticketID, msg.data);

//         // Emitting relevant info
//         emit InfoMint(
//             ticketID, 
//             _to, 
//             _merchant, 
//             _price, 
//             _item, 
//             _options,
//             _source
//         );
//         return ticketID++;
//     }

//     function updatePricePerAttachMinutes(uint _pricePerAttachMinutes, uint _adminFee) external onlyAdmin {
//         pricePerAttachMinutes = _pricePerAttachMinutes;
//         adminFee = _adminFee;
//     }

//     function updateMaxMinSuperChat(uint _newMax, uint _newMin) external onlyAdmin {
//         maxMessage = _newMax;
//         minSuperChat = _newMin;
//     }
    
//     function addTask(address _taskContract) external {
//         // used to display forms on the nft
//         taskContracts[msg.sender] = _taskContract;
//     }
    
//     function addTimeEstimates(string[] memory _options, uint[] memory _estimates) external {
//         require(_options.length == _estimates.length);
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         for (uint i = 0; i < _options.length; i++) {
//             timeEstimates[_collectionId][_options[i]] = _estimates[i];
//         }
//     }

//     function _resetVote(uint _merchant, uint _ticketID) internal {
//         if (voted[_ticketID][_merchant] > 0) {
//             estimateVotes[_merchant].likes -= 1;
//         } else if (voted[_ticketID][_merchant] < 0) {
//             estimateVotes[_merchant].dislikes -= 1;
//         }
//     }
    
//     function vote(uint _ticketID, bool like) external {
//         require(getReceiver(_ticketID) == msg.sender); 
//         uint _merchant = ticketInfo_[_ticketID].merchant;
//         _resetVote(_merchant, _ticketID);        
//         if (like) {
//             estimateVotes[_merchant].likes += 1;
//             voted[_ticketID][_merchant] = 1;
//         } else {
//             estimateVotes[_merchant].dislikes += 1;
//             voted[_ticketID][_merchant] = -1;
//         }
//         emit Voted(
//             _merchant, 
//             estimateVotes[_merchant].likes, 
//             estimateVotes[_merchant].dislikes, 
//             like
//         );
//     }

//     function batchMessage(
//         address _channel,
//         uint _amount, 
//         string memory _message
//     ) external lock {
//         require(channels[_channel].active_period < block.timestamp, "Current message not yet expired");
//         _safeTransferFrom(token, address(msg.sender), address(this), _amount * pricePerAttachMinutes);
//         channels[_channel].active_period = block.timestamp + _amount*minute / minute * minute;
//         channels[_channel].message = _message;
//         treasury += _amount * pricePerAttachMinutes;

//         emit Message(msg.sender, _channel, block.timestamp);
//     }

//     function superChatAll(string memory _message) external {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         batchSuperChat(allMerchantTickets_[_collectionId], _message);
//     }

//     function messageFromTo(uint _first, uint _last, string memory _message) external {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         (uint[] memory _tokenIds,) = getMerchantTicketsPagination(_collectionId, _first, _last);
//         batchSuperChat(_tokenIds, _message);
//     }

//     // used by merchant to message clients
//     function batchSuperChat(uint[] memory _tokenIds, string memory _message) public {
//         for (uint i = 0; i < _tokenIds.length; i++) {
//             superChat(_tokenIds[i], 0, _message);
//         }
//     }
    
//     function superChat(uint _tokenId, uint _amount, string memory _message) public lock {
//         uint _merchant = ticketInfo_[_tokenId].merchant;
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         require(getReceiver(_tokenId) == msg.sender || _merchant == _collectionId, 
//         "Invalid token ID");
//         if (getReceiver(_tokenId) == msg.sender) {
//             require(merchantMessages[_merchant].length() <= maxMessage, 
//             "No more place for superchats!");
//             require(_amount >= minSuperChat, "Not enough for superChat");
//             _safeTransferFrom(token, address(msg.sender), address(this), _amount);
//             uint _fee = _amount*adminFee/10000;
//             pendingRevenue[_collectionId] += _amount - _fee;
//             treasury += _fee;
//             merchantMessages[_merchant].add(_tokenId);
//             ticketInfo_[_tokenId].superChatOwner = _message;
//         } else {
//             ticketInfo_[_tokenId].superChatResponse = _message;
//             merchantMessages[ticketInfo_[_tokenId].merchant].remove(_tokenId);
//         }
//         emit SuperChat(msg.sender, _tokenId, block.timestamp);
//     }

//     function batchUpdateActive(
//         address _user, 
//         uint256 _merchant,
//         uint256 first, 
//         uint256 last,
//         bool _activate
//     ) external returns(bool) {
//         (uint[] memory _ticketIDs,) = getUserTicketsPagination(_user, _merchant, first, last);
//         return batchUpdateActive2(_ticketIDs, _activate);
//     }

//     function batchUpdateActive2(
//         uint[] memory _ticketIDs,
//         bool _activate
//     ) public returns(bool) {
//         for (uint i = 0; i < _ticketIDs.length; i++) {
//             updateActive(_ticketIDs[i], _activate);
//         }
//         return true;
//     }

//     function updateActive(uint256 _ticketID, bool _active) public returns(bool) {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         require(
//             ticketInfo_[_ticketID].merchant == _collectionId || devaddr_ == msg.sender,
//             "Only the merchant can deactivate the ticket"
//         );

//         ticketInfo_[_ticketID].active = _active;
//         emit UpdateActive(_ticketID, _active);
//         return true;
//     }

//     function withdrawTreasury(address _token, uint _amount) external onlyAdmin lock {
//         _token = _token == address(0x0) ? token : _token;
//         uint _price = _amount == 0 ? treasury : Math.min(_amount, treasury);
//         if (_token == token) {
//             treasury -= _price;
//             _safeTransfer(_token, msg.sender, _price);
//         } else {
//             _safeTransfer(_token, msg.sender, erc20(_token).balanceOf(address(this)));
//         }
//     }

//     function withdrawRevenue(uint _amount) external lock {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         uint _price = _amount == 0 ? pendingRevenue[_collectionId] : Math.min(_amount, pendingRevenue[_collectionId]);
//         pendingRevenue[_collectionId] -= _price;
//         _safeTransfer(token, msg.sender, _price);
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
//         ticketInfo_[_tokenId].lender = address(0x0);
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

//     // function withdrawNonFungible(address _token, uint _tokenId) external onlyAdmin {
//     //     IERC721(_token).safeTransferFrom(address(this), address(msg.sender), _tokenId);
//     // }

//     // function withdrawFungible(address _token, uint _amount) external onlyAdmin lock {
//     //     _safeTransferFrom(_token, address(this), address(msg.sender), _amount);
//     // }
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
//         address from,
//         address to,
//         uint256 tokenId
//     )
//         internal
//         virtual
//         override 
//     {
//         super._beforeTokenTransfer(from, to, tokenId);
//         ticketInfo_[tokenId].owner = to;
//         require(!attached[tokenId], "PayERC1155: Attached!");
//         if (msg.sender != devaddr_ && to != address(0x0)) {
//             require(ticketInfo_[tokenId].transferrable, "Ticket non transferrable");
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

//     function safeTransferNAttach(
//         address attachTo,
//         uint period,
//         address from,
//         address to,
//         uint256 id,
//         bytes memory data
//     ) external {
//         super.safeTransferFrom(from, to, id, data);
//         attach(id, period, attachTo);
//     }
// }

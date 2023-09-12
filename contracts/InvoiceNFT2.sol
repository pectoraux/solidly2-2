// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;
// pragma experimental ABIEncoderV2;

// import "./Library.sol";

// contract InvoiceNFT is ERC1155Pausable, ReentrancyGuard {
//     // Storage for ticket information
//     struct TicketInfo {
//         address owner;
//         address protocol;
//         address lender;
//         bool active;
//         uint date;
//         uint timer;
//         uint share;
//         string sponsoredMessage;
//         string adminMessage;
//     }
//     // Token ID => Token information 
//     mapping(uint256 => TicketInfo) public ticketInfo_;
//     // User address =>  Ticket IDs
//     mapping(address => uint256[]) public userTickets_;
//     uint[] public allTickets_;
//     mapping(address => uint) public protocolShares;
//     uint TEST_CHAIN = 31337;
//     uint public ticketID = 1;
//     mapping(uint => string) public sponsoredMessages;
//     uint256 public constant MAX_PRICE = 80000000000000000; //0.08 ETH
//     uint256 public rpPrice_; //0 ETH
//     uint public totalSupply_;
//     mapping(uint => bool) public attached;
//     address public token;
//     uint public treasury;
//     uint public MaximumArraySize = 50;
//     mapping(uint => bool) public blacklist;
//     address public devaddr_;
//     address public immutable factory;
//     uint public pricePerAttachMinutes = 1;
//     uint internal constant minute = 3600; // allows minting once per week (reset every Thursday 00:00 UTC)
//     uint public active_period;

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

//     modifier isNotContract() {
//         require(!_isContract(msg.sender), "Contracts not allowed");
//         _;
//     }

//     modifier onlyAdmin() {
//         require(msg.sender == devaddr_ || msg.sender == factory, "Only admin!");
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
//         address _devaddr,
//         address _token,
//         string memory _uri
//     ) 
//     ERC1155(_uri)
//     {
//         token = _token;
//         factory = _devaddr;
//         devaddr_ = _devaddr;
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

//     function getReceiver(uint _tokenId) public view returns(address) {
//         return ticketInfo_[_tokenId].lender == address(0) ?
//         ticketInfo_[_tokenId].owner : ticketInfo_[_tokenId].lender;
//     }

//     function getTicketDate(uint _tokenId) external view returns(uint) {
//         return ticketInfo_[_tokenId].date;
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
//     function updateDev(address _newDev) external onlyAdmin {
//         devaddr_ = _newDev;
//     }

//     function updatePricePerAttachMinutes(uint _pricePerAttachMinutes) external onlyAdmin {
//         pricePerAttachMinutes = _pricePerAttachMinutes;
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

//     function mintToBatch(
//         address _protocol, 
//         address[] memory _recipients, 
//         uint[] memory _shares
//     )
//         onlyAdmin
//         external
//     {   
//         require(
//             _recipients.length <= MaximumArraySize,
//             "Batch mint too large"
//         );
//         require(
//             _recipients.length == _shares.length,
//             "Uneven lists"
//         );
//         require(_sumArr(_shares) + protocolShares[_protocol] <= 10000, "Shares cannot be bigger than 10000");

//         for (uint8 i = 0; i < _recipients.length; i++) {
//             // Storing the ticket information 
//             ticketInfo_[ticketID] = TicketInfo({
//                 owner: _recipients[i],
//                 protocol: _protocol,
//                 lender: address(0),
//                 active: true,
//                 date: block.timestamp,
//                 timer: 0,
//                 share: _shares[i],
//                 adminMessage: "", 
//                 sponsoredMessage: "" 
//             });
//             totalSupply_ += 1;
//             protocolShares[_protocol] += _shares[i];
//             userTickets_[_recipients[i]].push(ticketID);
//             allTickets_.push(ticketID);
//             _mint(_recipients[i], ticketID++, 1, msg.data);
//         }
//     }

//     function payInvoicePayable(uint _tokenId) public nonReentrant {
//         require(getReceiver(_tokenId) == msg.sender, "Only owner!");
//         IARP(factory).payInvoicePayable(
//             ticketInfo_[_tokenId].protocol, 
//             msg.sender, 
//             ticketInfo_[_tokenId].share
//         );
//     }

//     function charge(uint _tokenId, uint _numPeriods) public nonReentrant {
//         require(getReceiver(_tokenId) == msg.sender, "Only owner!");
        
//         address[] memory _owners = new address[](1);
//         address[] memory _protocols = new address[](1);
//         _owners[0] = msg.sender;
//         _protocols[0] = ticketInfo_[_tokenId].protocol;
//         (uint _due,) = IARP(factory).getDueReceivable(ticketInfo_[_tokenId].protocol, _numPeriods);
//         uint _amount = ticketInfo_[_tokenId].share * _due / 10000;
//         IARP(factory).autoCharge(
//             _owners, 
//             _protocols, 
//             _amount, 
//             _numPeriods
//         );
//     }

//     function _sumArr(uint[] memory _arr) internal pure returns(uint total) {
//         for (uint i = 0; i < _arr.length; i++) {
//             total += _arr[i];
//         }
//     }

//     function messageAll(uint _tokenId, uint _amount, string memory _message) external {
//         batchMessage(_tokenId, allTickets_, _amount, _message);
//     }

//     function messageFromTo(uint _tokenId, uint _amount, uint _first, uint _last, string memory _message) external {
//         uint[] memory _tokenIds = getTicketsPagination(_first, _last);
//         batchMessage(_tokenId, _tokenIds, _amount, _message);
//     }

//     function batchMessage(uint _tokenId, uint[] memory _tokenIds, uint _amount, string memory _message) public {
//         require(getReceiver(_tokenId) == msg.sender || devaddr_ == msg.sender, "Invalid token ID");
//         require(active_period < block.timestamp || devaddr_ == msg.sender, "Current message not yet expired");
//         if (msg.sender != devaddr_) {
//             _safeTransferFrom(
//                 token,
//                 address(msg.sender), 
//                 address(this),
//                 _amount * pricePerAttachMinutes
//             );
//             active_period = (block.timestamp + (_amount*minute)) / minute * minute;
//         }
//         for (uint i = 0; i < _tokenIds.length; i++) {
//             if (msg.sender != devaddr_) {
//                 ticketInfo_[_tokenIds[i]].sponsoredMessage = _message;
//             } else {
//                 ticketInfo_[_tokenIds[i]].adminMessage = _message;
//             }
//         }

//         emit Message(msg.sender, _tokenId, block.timestamp);
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

//     function changePrice(uint _rpPrice) external onlyAdmin {
//         require(_rpPrice <= MAX_PRICE, "PayERC1155: Price too high");
//         rpPrice_ = _rpPrice;
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
//     ) internal virtual override{     
//         super._burn(account, id, amount);
//         delete ticketInfo_[id];
//         totalSupply_ = totalSupply_ >= 1 ? totalSupply_ -1 : 0;
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

// contract InvoiceFactory {
//     address public last_invoice;
//     address[] public invoices;
//     function createInvoice(
//         address _arp,
//         address _token,
//         string memory _uri,
//         address _nft,
//         bool _adminBountyRequired
//     ) external returns(address) {
//         last_invoice = address(new InvoiceNFT(
//             msg.sender,
//             _token,
//             _uri
//         ));
//         invoices.push(last_invoice);
//         IMicroLender(_arp).initialize(
//             last_invoice, 
//             _adminBountyRequired
//         );
//         return last_invoice;
//     }
// }
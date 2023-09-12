// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;
// pragma experimental ABIEncoderV2;

// import "./Percentile.sol";

// contract DNtwrk is ERC1155Pausable, Percentile {
//     using EnumerableSet for EnumerableSet.AddressSet;

//     EnumerableSet.AddressSet private _q4AddressSet;
//     EnumerableSet.AddressSet private _q3AddressSet;
//     EnumerableSet.AddressSet private _q2AddressSet;
//     EnumerableSet.AddressSet private _q1AddressSet;
//     // Storage for ticket information
//     struct TicketInfo {
//         address owner;
//         address lender;
//         uint date;
//         uint timer;
//         uint percentile;
//         uint[3] percentiles;
//         uint q4;
//         uint q3;
//         uint q2;
//         uint q1;
//         string q4Message;
//         string q3Message;
//         string q2Message;
//         string q1Message;
//     }
//     mapping(uint => string) internal sponsoredMessage;
//     // Token ID => Token information 
//     mapping(uint256 => TicketInfo) public ticketInfo_;
//     // User address =>  Ticket IDs
//     mapping(address => uint256[]) public userTickets_;
//     uint[] public allTickets_;
//     uint TEST_CHAIN = 31337;
//     uint public pricePerAttachMinutes = 1;
//     uint internal constant minute = 3600; // allows minting once per week (reset every Thursday 00:00 UTC)
//     uint public active_period;
//     mapping(uint => uint) public pendingRound;
//     mapping(uint => uint) public paidPayable;
//     uint public lastClaimedRound = 1;
//     uint public _percentile;
//     uint public round = 1;
//     uint public ticketID = 1;
//     mapping(uint => string) public sponsoredMessages;
//     uint256 public constant MAX_PRICE = 80000000000000000; //0.08 ETH
//     uint256 public rpPrice_; //0 ETH
//     uint public totalSupply_;
//     IRandomNumberGenerator randomGenerator_;
//     mapping(uint => bool) public attached;
//     address public token;
//     uint public Range = 1000000;
//     uint public treasury;
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
//     uint public teamShare;
//     uint public MaximumArraySize = 50;
//     mapping(uint => bool) public blacklist;
//     address public devaddr_;
//     uint[4] public boosts;
//     uint public minPercentile = 50;
//     uint public MinimumLengthToPick = 1;
//     mapping(address => uint) public percentiles;
//     uint public linkFee = 0;
//     //-------------------------------------------------------------------------
//     // EVENTS
//     //-------------------------------------------------------------------------

//     event InfoBatchMint(
//         address indexed receiving, 
//         string[] indexed codes, 
//         uint256[] tokenIds,
//         uint time
//     );
//     event Message(address indexed from, uint tokenId, uint time);
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
//         uint _series,  // series S & series X are Payswap's main series
//         string memory _uri
//     ) 
//     ERC1155(_uri)
//     {
//         devaddr_ = msg.sender;
//         series = SERIES(_series);
//     }

//     //-------------------------------------------------------------------------
//     // VIEW FUNCTIONS
//     //-------------------------------------------------------------------------
//     function getUserTicketsPagination(
//         address _user, 
//         address _merchant,
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
//                 values[j] = _ticketID;
//                 unchecked {
//                     j++;
//                 }
//             }
//         }
//         return values;
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

//     function getChainID() public view returns (uint256) {
//         uint256 id;
//         assembly {
//             id := chainid()
//         }
//         return id;
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

//     function updateMinPercentile(uint _newMinPercentile) external onlyAdmin {
//         minPercentile = _newMinPercentile;
//     }

//     function updateRange(uint _newRange) external onlyAdmin {
//         Range = _newRange;
//     }

//     function updatePricePerAttachMinutes(uint _pricePerAttachMinutes) external onlyAdmin {
//         pricePerAttachMinutes = _pricePerAttachMinutes;
//     }

//     function updateTeamShare(uint _share, uint _linkFee) external onlyAdmin {
//         teamShare = _share;
//         linkFee = _linkFee;
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

//     function mint(
//         bool _noPair,
//         address _to,
//         uint256 _paid,
//         uint256 __percentile
//     )
//         external
//         returns(address,address,address,address)
//     {   
//         require(!_isContract(msg.sender), "Cannot be a contract");
//         if (__percentile > 0 && _paid == 0) {
//             _paid = getPaid4Percentile(__percentile);
//         }
//         int256 _zscore = computePercentile(_paid);
//         uint _userPercentile = getPercentile(_zscore);
        
//         _safeTransferFrom(
//             token,
//             msg.sender, 
//             address(this), 
//             _paid
//         );
//         _safeTransferFrom(
//             token,
//             address(this), 
//             msg.sender, 
//             _paid - teamShare - linkFee
//         );

//         if (_noPair) {
//             ticketInfo_[ticketID] = TicketInfo({
//                 owner: msg.sender,
//                 lender: address(0),
//                 date: block.timestamp,
//                 timer: 0,
//                 percentile: _userPercentile,
//                 q4: _zscore >= getQ4() ? ticketID:0,
//                 q3: _zscore < getQ4() && _zscore >= getQ3() ? ticketID:0,
//                 q2: _zscore < getQ3() && _zscore >= getQ2() ? ticketID:0,
//                 q1: _zscore < getQ2() ? ticketID:0,
//                 percentiles: [uint256(0), uint256(0), uint256(0)],
//                 q4Message: "",
//                 q3Message: "",
//                 q2Message: "",
//                 q1Message: ""
//             });
//             sponsoredMessage[ticketID] = "";
//             userTickets_[msg.sender].push(ticketID);
//             allTickets_.push(ticketID);
//             _mint(msg.sender, ticketID, 1, msg.data);
//             return (address(0), address(0), address(0), address(0));
//         } else if (_userPercentile >= 75) {
//             _q4AddressSet.add(msg.sender);
//         } else if (_userPercentile >= 50) {
//             _q3AddressSet.add(msg.sender);
//         } else if (_userPercentile >= 25) {
//             _q2AddressSet.add(msg.sender);
//         } else {
//             _q1AddressSet.add(msg.sender);
//         }
//         percentiles[msg.sender] = _userPercentile;
        
//         // Request a random number from the generator based on a seed
//         if (getChainID() != TEST_CHAIN) {
//             randomGenerator_.randomnessIsRequestedHere(4, msg.sender);
//         }
//         round++;

//         return pickNSend(round++);
//     }

//     function pickNSend(uint _round) internal returns(
//         address _user1, address _user2, address _user3, address _user4) {
//             uint[] memory randomNumbers;
//             if (
//                 _q4AddressSet.length() >= MinimumLengthToPick &&
//                 _q3AddressSet.length() >= MinimumLengthToPick &&
//                 _q2AddressSet.length() >= MinimumLengthToPick &&
//                 _q1AddressSet.length() >= MinimumLengthToPick
            
//             ) {
//                 if (getChainID() != TEST_CHAIN) {
//                     randomNumbers = randomGenerator_.viewRandomNumbers(round-1, msg.sender);
//                 } else {
//                     randomNumbers = new uint[](4);
//                     // [
//                     //     uint256(keccak256(abi.encodePacked(block.timestamp+10000, msg.sender))),
//                     //     uint256(keccak256(abi.encodePacked(block.timestamp+20000, msg.sender))),
//                     //     uint256(keccak256(abi.encodePacked(block.timestamp+30000, msg.sender))),
//                     //     uint256(keccak256(abi.encodePacked(block.timestamp+40000, msg.sender)))
//                     // ];
//                 }
//                 if (randomNumbers.length >= 4) {
//                     _user4 = _q4AddressSet.at(randomNumbers[0] % _q4AddressSet.length());
//                     _user3 = _q3AddressSet.at(randomNumbers[1] % _q3AddressSet.length());
//                     _user2 = _q2AddressSet.at(randomNumbers[2] % _q2AddressSet.length());
//                     _user1 = _q1AddressSet.at(randomNumbers[3] % _q1AddressSet.length());
//                     _mintTo(_user4, _user3, _user2, _user1);
//                 }
//             }
//     }

//     function _mintTo(address _user4, address _user3, address _user2, address _user1) internal {
//         require(_user4 != address(0) && _user3 != address(0) && _user2 != address(0) && _user1 != address(0), "Invalid addresses");
//         // Storing the ticket information 
//         ticketInfo_[ticketID] = TicketInfo({
//             owner: _user4,
//             lender: address(0),
//             date: block.timestamp,
//             timer: 0,
//             percentile: percentiles[_user4],
//             q4: ticketID,
//             q3: ticketID + 1,
//             q2: ticketID + 2,
//             q1: ticketID + 3,
//             percentiles: [percentiles[_user3], percentiles[_user2], percentiles[_user1]],
//             q4Message: "",
//             q3Message: "",
//             q2Message: "",
//             q1Message: ""
//         });
//         sponsoredMessage[ticketID] = "";
//         userTickets_[_user4].push(ticketID);
//         allTickets_.push(ticketID);
//         _mint(_user4, ticketID, 1, msg.data);

//         ticketInfo_[++ticketID] = TicketInfo({
//             owner: _user3,
//             lender: address(0),
//             date: block.timestamp,
//             timer: 0,
//             percentile: percentiles[_user3],
//             q4: ticketID - 1,
//             q3: ticketID,
//             q2: ticketID + 1,
//             q1: ticketID + 2,
//             percentiles: [percentiles[_user4], percentiles[_user2], percentiles[_user1]],
//             q4Message: "",
//             q3Message: "",
//             q2Message: "",
//             q1Message: ""
//         });
//         sponsoredMessage[ticketID] = "";
//         userTickets_[_user3].push(ticketID);
//         allTickets_.push(ticketID);
//         _mint(_user3, ticketID, 1, msg.data);

//         ticketInfo_[++ticketID] = TicketInfo({
//             owner: _user2,
//             lender: address(0),
//             date: block.timestamp,
//             timer: 0,
//             percentile: percentiles[_user2],
//             q4: ticketID - 2,
//             q3: ticketID - 1,
//             q2: ticketID,
//             q1: ticketID + 1,
//             percentiles: [percentiles[_user4], percentiles[_user3], percentiles[_user1]],
//             q4Message: "",
//             q3Message: "",
//             q2Message: "",
//             q1Message: ""
//         });
//         sponsoredMessage[ticketID] = "";
//         userTickets_[_user2].push(ticketID);
//         allTickets_.push(ticketID);
//         _mint(_user2, ticketID, 1, msg.data);

//         ticketInfo_[++ticketID] = TicketInfo({
//             owner: _user1,
//             lender: address(0),
//             date: block.timestamp,
//             timer: 0,
//             percentile: percentiles[_user1],
//             q4: ticketID - 3,
//             q3: ticketID - 2,
//             q2: ticketID - 1,
//             q1: ticketID,
//             percentiles: [percentiles[_user4], percentiles[_user3], percentiles[_user2]],
//             q4Message: "",
//             q3Message: "",
//             q2Message: "",
//             q1Message: ""
//         });
//         sponsoredMessage[ticketID] = "";
//         userTickets_[_user1].push(ticketID);
//         allTickets_.push(ticketID);
//         totalSupply_ += 4;
//         _mint(_user1, ticketID, 1, msg.data);

//     }

//     function messageNtwrk(uint _tokenId, string memory _message) external isNotContract {
//         require(getReceiver(_tokenId) == msg.sender, "Invalid token ID");
        
//         if (_tokenId == ticketInfo_[_tokenId].q4) {
//             ticketInfo_[ticketInfo_[_tokenId].q3].q4Message = _message;
//             ticketInfo_[ticketInfo_[_tokenId].q2].q4Message = _message;
//             ticketInfo_[ticketInfo_[_tokenId].q1].q4Message = _message;
//         } else if (_tokenId == ticketInfo_[_tokenId].q3) {
//             ticketInfo_[ticketInfo_[_tokenId].q4].q3Message = _message;
//             ticketInfo_[ticketInfo_[_tokenId].q2].q3Message = _message;
//             ticketInfo_[ticketInfo_[_tokenId].q1].q3Message = _message;
//         } else if (_tokenId == ticketInfo_[_tokenId].q2) {
//             ticketInfo_[ticketInfo_[_tokenId].q4].q2Message = _message;
//             ticketInfo_[ticketInfo_[_tokenId].q3].q2Message = _message;
//             ticketInfo_[ticketInfo_[_tokenId].q1].q2Message = _message;
//         } else {
//             ticketInfo_[ticketInfo_[_tokenId].q4].q1Message = _message;
//             ticketInfo_[ticketInfo_[_tokenId].q3].q1Message = _message;
//             ticketInfo_[ticketInfo_[_tokenId].q2].q1Message = _message;
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

//     function updateBoosts(uint[4] memory _boosts) external onlyAdmin {
//         require(_boosts.length == 4, "Invalid number of boosts");
//         boosts = _boosts;
//     }

//     function boostingPower(uint _tokenId) external view returns(uint) {
//         require(ticketInfo_[_tokenId].owner != address(0), "Does not exist");
//         if (ticketInfo_[_tokenId].percentile >= Q4) {
//             return boosts[3];
//         } else if (ticketInfo_[_tokenId].percentile >= Q3) {
//             return boosts[2];
//         } else if (ticketInfo_[_tokenId].percentile >= Q2) {
//             return boosts[1];
//         } else if (ticketInfo_[_tokenId].percentile >= Q1) {
//             return boosts[0];
//         }
//     }

//     function changePrice(uint _rpPrice) external onlyAdmin {
//         require(_rpPrice <= MAX_PRICE, "PayERC1155: Price too high");
//         rpPrice_ = _rpPrice;
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
//         pendingRound[lastClaimedRound] += _amount * pricePerAttachMinutes;
//         active_period = (block.timestamp + (_amount*minute)) / minute * minute;
//         for (uint i = 0; i < _tokenIds.length; i++) {
//             sponsoredMessage[_tokenIds[i]] = _message;
//         }

//         emit Message(msg.sender, _tokenId, block.timestamp);
//     }

//     function withdrawTreasury2(address _token) external onlyAdmin {
//         _token = _token == address(0) ? token : _token;
//         _safeTransfer(
//             _token,
//             msg.sender,
//             erc20(_token).balanceOf(address(this))
//         );
//     }


//     function withdrawTreasury() external onlyAdmin {
//         _safeTransfer(
//             token,
//             msg.sender,
//             erc20(token).balanceOf(address(this))
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
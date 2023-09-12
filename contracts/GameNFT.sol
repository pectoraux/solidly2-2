// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;
// pragma experimental ABIEncoderV2;

// import "./Percentile.sol";

// contract GameNFT is ERC1155Pausable, Percentile, ReentrancyGuard {
//     // State variables 
//     uint256 public totalSupply_;
//     uint256 public constant MAX_PRICE = 80000000000000000; //0.08 ETH
//     mapping(uint => string) public sponsoredMessages;
//     mapping(address => bool) public isMarketPlace;
//     // Storage for ticket information
//     struct TicketInfo {
//         address owner;
//         address lender;
//         uint timer;
//         uint date;
//         uint gameMinutes;
//         uint gameCount;
//         address gameContract;
//         uint score;
//         uint deadline;
//         uint percentile;
//         uint scorePercentile;
//         uint price;
//         uint won;
//         string sponsoredMessage;
//     }
//     uint TEST_CHAIN = 31337;
//     IRandomNumberGenerator randomGenerator_;
//     mapping(uint => uint[]) public nftObjects;
//     // Token ID => Token information 
//     mapping(uint256 => TicketInfo) public ticketInfo_;
//     uint256 public ticketID = 1;
//     address public token;
//     uint public price_;
//     // User address =>  Ticket IDs
//     mapping(address => uint256[]) public userTickets_;
//     uint[] public allTickets_;
//     mapping(uint => bool) public attached;
//     uint public pricePerAttachMinutes = 1;
//     uint internal constant minute = 3600; // allows minting once per week (reset every Thursday 00:00 UTC)
//     uint public active_period;
//     uint public Q1 = 1;
//     uint public Q2 = 25;
//     uint public Q3 = 50;
//     uint public Q4 = 75;
//     mapping(address => bool) public blacklist;
//     uint public MaximumArraySize = 50;
//     uint[4] public boosts;
//     address public devaddr;
//     address public immutable factory;
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

//     modifier onlyAdmin() {
//         require(msg.sender == devaddr, "Only dev!");
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
//     constructor(string memory _uri, address _factory, address _token, address _randomGenerator) 
//     ERC1155(_uri)
//     {
//         devaddr = msg.sender;
//         factory = _factory;
//         token = _token;
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

//     function getTicketLender(uint _tokenId) external view returns(address) {
//         return ticketInfo_[_tokenId].lender;
//     }

//     function getTicketTimer(uint _tokenId) external view returns(uint) {
//         return ticketInfo_[_tokenId].timer;
//     }

//     function getTicketOwner(uint _tokenId) external view returns(address) {
//         return ticketInfo_[_tokenId].owner;
//     }

//     function getTicketPercentiles(uint _tokenId) external view returns(uint, uint) {
//         return (
//             ticketInfo_[_tokenId].percentile,
//             ticketInfo_[_tokenId].scorePercentile
//         );
//     }

//     function getGamePrice(uint _tokenId) external view returns(uint) {
//         return ticketInfo_[_tokenId].price;
//     }

//     function getGameSpecs(uint _tokenId) external view returns(address,uint,uint,uint,uint,uint,uint[] memory) {
//         return (
//             ticketInfo_[_tokenId].gameContract,
//             ticketInfo_[_tokenId].score,
//             ticketInfo_[_tokenId].deadline,
//             ticketInfo_[_tokenId].gameMinutes,
//             ticketInfo_[_tokenId].gameCount,
//             ticketInfo_[_tokenId].won,
//             nftObjects[_tokenId]
//         );
//     }

//     function getReceiver(uint _tokenId) public view returns(address) {
//         return ticketInfo_[_tokenId].lender == address(0) ?
//         ticketInfo_[_tokenId].owner : ticketInfo_[_tokenId].lender;
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
//     function updateQs(uint q1, uint q2, uint q3, uint q4) external onlyAdmin {
//         require(q1 < q2, "Invalid Q1");
//         require(q2 < q3, "Invalid Q2");
//         require(q3 < q4, "Invalid Q3");
//         Q1 = q1;
//         Q2 = q2;
//         Q3 = q3;
//         Q4 = q4;
//     }
    
//     function updatePricePerAttachMinutes(uint _pricePerAttachMinutes) external onlyAdmin {
//         pricePerAttachMinutes = _pricePerAttachMinutes;
//     }

//     function updateDev(address _newDev) external onlyAdmin {
//         devaddr = _newDev;
//     }

//     /**
//      * @param   _to The address being minted to
//      * @param   _numberOfTickets The number of NFT's to mint
//      * @notice  Only the lotto contract is able to mint tokens. 
//         // uint8[][] calldata _lottoNumbers
//      */
//     function batchMint(
//         address _to,
//         uint256 _numberOfTickets
//     )
//         nonReentrant
//         onlyAdmin
//         external
//         returns(uint256[] memory tokenIds)
//     {   
//         require(_numberOfTickets <= MaximumArraySize, "Batch mint too large");
//         require(_to != address(0), "Invalid Owner");

//         // Storage for the amount of tokens to mint (always 1)
//         uint256[] memory amounts = new uint256[](_numberOfTickets);
//         // Storage for the token IDs
//         tokenIds = new uint256[](_numberOfTickets);
//         for (uint8 i = 0; i < _numberOfTickets; i++) {
//             // Incrementing the tokenId counter
//             allTickets_.push(ticketID);
//             tokenIds[i] = ticketID++;
//             amounts[i] = 1;
//             uint[] memory _objects;
//             // Storing the ticket information 
//             ticketInfo_[tokenIds[i]] = TicketInfo({
//                 owner: _to,
//                 lender: address(0),
//                 date: block.timestamp,
//                 timer: 0,
//                 gameContract: address(0),
//                 gameMinutes: 0,
//                 score: 0,
//                 deadline: 0,
//                 percentile: 0,
//                 price: 0,
//                 won: 0,
//                 gameCount: 0,
//                 scorePercentile: 0,
//                 sponsoredMessage: ""
//             });
//             nftObjects[tokenIds[i]] = _objects;
//             totalSupply_ += 1;
//             userTickets_[_to].push(tokenIds[i]);
//         }
//          // Minting the batch of tokens
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
//     }

//     function updateBlacklist(address[] memory _users, bool[] memory _blacklists) external onlyAdmin {
//         require(_users.length == _blacklists.length, "Blackist: Uneven lists");
//         for (uint i = 0; i < _users.length; i++) {
//             blacklist[_users[i]] = _blacklists[i];
//         }
//     }

//     function updateMarketPlace(address _marketPlace, bool _add) external onlyAdmin {
//         isMarketPlace[_marketPlace] = _add;
//     }

//     function updateGameContract(
//         uint _tokenId, 
//         address _to, 
//         address _gameContract, 
//         uint _minutes, 
//         uint _price,
//         uint _reward,
//         bool _delete
//     ) external onlyAdmin {
//         require(_gameContract != address(0) && !blacklist[_gameContract], "Invalid game");
//         require(getReceiver(_tokenId) == _to, "Invalid token owner");
//         ticketInfo_[_tokenId].gameContract = _gameContract;
//         ticketInfo_[_tokenId].score = 0;
//         ticketInfo_[_tokenId].deadline = 0;
//         ticketInfo_[_tokenId].gameMinutes = _minutes;
//         ticketInfo_[_tokenId].gameCount += _minutes > 0 ? 1 : 0;
//         ticketInfo_[_tokenId].price = _price;
//         ticketInfo_[_tokenId].won += _reward;
//         if(_delete) deleteObjects(_tokenId);
//     }

//     function deleteObjects(uint _tokenId) public {
//         require(msg.sender == devaddr || msg.sender == ticketInfo_[_tokenId].gameContract,
//         "Only factory or game");
//         delete nftObjects[_tokenId];
//     }

//     function deleteObject(uint _tokenId, uint _object) external onlyAdmin {
//         for (uint i = 0; i < nftObjects[_tokenId].length; i++) {
//             if (nftObjects[_tokenId][i] == _object) {
//                 delete nftObjects[_tokenId][i];
//                 break;
//             }
//         }
//     }

//     function updateScoreNDeadline(uint _tokenId, uint _score, uint _deadline) external {
//         require(msg.sender == ticketInfo_[_tokenId].gameContract, "Only game");
//         require(!blacklist[msg.sender], "Blacklisted!");
//         ticketInfo_[_tokenId].score += _score;
//         ticketInfo_[_tokenId].deadline = _deadline;
//     }

//     function updatePricePercentile(uint _tokenId, uint _paid) external onlyAdmin {
//         int256 __zscore = computePercentile(_paid);
//         ticketInfo_[_tokenId].percentile = getPercentile(__zscore);
//     }

//     function updateScorePercentile(
//         uint _tokenId, 
//         uint _totalScore,
//         uint _numPlayers,
//         uint _score,
//         uint _sum_of_diff_squared_invoices
//     ) external onlyAdmin returns(uint) {
//         (uint _percentile, uint _sumDiffSquared) = computePercentileFromData(
//             false,
//             _score,
//             _numPlayers,
//             _totalScore,
//             _sum_of_diff_squared_invoices
//         );
//         if (ticketInfo_[_tokenId].scorePercentile == 0) {
//             ticketInfo_[_tokenId].scorePercentile = _percentile;
//         } else {
//             ticketInfo_[_tokenId].scorePercentile = 
//             (ticketInfo_[_tokenId].scorePercentile + _percentile) / 2;
//         }
//         return _sumDiffSquared;
//     }

//     function updateObjects(uint _tokenId, uint[] memory _objects, bool _delete) external {
//         require(msg.sender == devaddr || msg.sender == ticketInfo_[_tokenId].gameContract,
//         "Only factory or game");
//         require(!blacklist[msg.sender], "Blacklisted!");
//         if(_delete) deleteObjects(_tokenId);
//         for (uint i = 0; i < _objects.length; i++) {
//             nftObjects[_tokenId].push(_objects[i]);
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

//     function changePrice(uint _price) external onlyAdmin {
//         require(_price <= MAX_PRICE, "Price too high");
//         price_ = _price;
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

//     function burn(
//         address account, 
//         uint256 id, 
//         uint256 amount
//     ) external {
//         require(msg.sender == ticketInfo_[id].owner || msg.sender == devaddr, "Only owner or admin");
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
//         if (msg.sender != devaddr) {
//             require(price_ * totalSupply_ <= msg.value, "PayERC1155: Ether value sent is not correct");
//         }

//         for(uint i = 0; i < ids.length; i++) {
//             require(isMarketPlace[to] || to == ticketInfo_[ids[i]].owner, "Only marketplace or owner");
//             require(!attached[ids[i]] && !blacklist[msg.sender], "PayERC1155: Attached!");
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

//     // random number function for color of the day, make the function onlyAdmin
//     // uint256(
//     //     keccak256(
//     //         abi.encodePacked(
//     //             nonce,
//     //             msg.sender,
//     //             block.difficulty,
//     //             block.timestamp
//     //         );
//     //     )
//     // ) % arr.length
// }



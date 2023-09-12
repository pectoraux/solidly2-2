// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;
// pragma experimental ABIEncoderV2;

// import "./Percentile.sol";

// contract BallerNFT is Auth, ERC1155Pausable, Percentile, ReentrancyGuard {
//     // Storage for ticket information
//     struct TicketInfo {
//         address owner;
//         address lender;
//         uint percentile;
//         bool active;
//         uint date;
//         uint timer;
//         uint price; //does not display
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
//     // Token ID => Token information 
//     mapping(uint256 => TicketInfo) public ticketInfo_;
//     // User address =>  Ticket IDs
//     uint[] public allTickets_;
//     mapping(address => uint256[]) public userTickets_;
//     uint public pricePerAttachMinutes = 1;
//     uint internal constant minute = 3600; // allows minting once per week (reset every Thursday 00:00 UTC)
//     uint public active_period;
//     uint TEST_CHAIN = 31337;
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
//         S,
//         X
//     }
//     SERIES public series;
//     uint public teamShare;
//     uint public MaximumArraySize = 50;
//     mapping(uint => bool) public blacklist;
//     uint[4] public boosts;

//     //-------------------------------------------------------------------------
//     // EVENTS
//     //-------------------------------------------------------------------------

//     event InfoBatchMint(
//         address indexed receiving, 
//         string[] indexed codes, 
//         uint256[] tokenIds,
//         uint time
//     );

//     event Message(address indexed from, uint[] tokenIds, uint time);

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
//         address _devaddr,
//         uint _series,  // series S & series X are Payswap's main series
//         address _token,
//         string memory _uri,
//         address _superLikeGaugeFactory,
//         address _randomGenerator
//     ) 
//     ERC1155(_uri)
//     Auth(_devaddr, _superLikeGaugeFactory)
//     {
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
//             if (date >= first && date <= last) length++;
//         }
//         uint256[] memory values = new uint[](length);
//         uint j;
//         for (uint256 i = 0; i < userTickets_[_user].length; i++) {
//             uint256 _ticketID = userTickets_[_user][i];
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

//     function getTicketDate(uint _tokenId) external view returns(uint) {
//         return ticketInfo_[_tokenId].date;
//     }

//     function getTicketPrice(uint _tokenId) external view returns(uint) {
//         return ticketInfo_[_tokenId].price;
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

//     function updatePricePerAttachMinutes(uint _pricePerAttachMinutes) external onlyAdmin {
//         pricePerAttachMinutes = _pricePerAttachMinutes;
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

//     function updateRange(uint _newRange) external onlyAdmin {
//         Range = _newRange;
//     }

//     function updateTeamShare(uint _share) external onlyAdmin {
//         teamShare = _share;
//     }

//     function updateBlacklist(uint[] memory _tokenIds, bool[] memory _blacklists) external onlyAuth {
//         require(_tokenIds.length == _blacklists.length, "Blackist: Uneven lists");
//         for (uint i = 0; i < _tokenIds.length; i++) {
//             blacklist[_tokenIds[i]] = _blacklists[i];
//         }
//     }

//     function updateMaxArraySize(uint _maxArrSize) external onlyAdmin {
//         MaximumArraySize = _maxArrSize;
//     }

//     function batchMint(
//         address _to,
//         uint256 __percentile,
//         uint256 _meanPaid,
//         uint256 _numberOfTickets
//     )
//         external
//         nonReentrant
//         returns(uint256[] memory)
//     {   
//         require(
//             _numberOfTickets <= MaximumArraySize,
//             "Batch mint too large"
//         );
//         if (__percentile > 0 && _meanPaid == 0) {
//             _meanPaid = getPaid4Percentile(__percentile);
//         }
//         _safeTransferFrom(
//             token,
//             msg.sender, 
//             address(this), 
//             _meanPaid * _numberOfTickets
//         );
//         uint _teamFee = _meanPaid * _numberOfTickets * teamShare / 10000;
//         pendingRound[round] += _meanPaid * _numberOfTickets - _teamFee;
//         treasury += _teamFee;
//         // Storage for the amount of tokens to mint (always 1)
//         uint256[] memory amounts = new uint256[](_numberOfTickets);
//         // Storage for the token IDs
//         uint256[] memory tokenIds = new uint256[](_numberOfTickets);
//         int256 _zscore = computePercentile(_meanPaid);
        
//         for (uint8 i = 0; i < _numberOfTickets; i++) {
//             // Incrementing the tokenId counter
//             uint256 _date = block.timestamp;
//             tokenIds[i] = ticketID++;
//             amounts[i] = 1;
//             // Storing the ticket information 
//             ticketInfo_[tokenIds[i]] = TicketInfo({
//                 owner: _to,
//                 lender: address(0),
//                 percentile: getPercentile(_zscore),
//                 active: true,
//                 date: _date,
//                 timer: 0,
//                 price: _meanPaid
//             });
//             totalSupply_ += 1;
//             allTickets_.push(ticketID);
//             userTickets_[_to].push(tokenIds[i]);

//         }
        
//         // Minting the batch of tokens
//         _mintBatch(
//             _to,
//             tokenIds,
//             amounts,
//             msg.data
//         );

//         // Request a random number from the generator based on a seed
//         if (getChainID() != TEST_CHAIN) {
//             randomGenerator_.randomnessIsRequestedHere(uint32(tokenIds.length), msg.sender);
//             // SponsorCard._safeTransferFrom(link, msg.sender, address(this), link_fee);
//         }
//         round++;

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

//     function claimPendingBalance(uint _tokenId) external isNotContract {
//         require(_tokenId <= ticketID, "Invalid token ID");
//         if (getChainID() != TEST_CHAIN) {
//             uint[] memory randomNumbers = 
//             randomGenerator_.viewRandomNumbers(lastClaimedRound, msg.sender);
//             uint randIdx = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % (randomNumbers.length - 1);
//             _percentile = getRandomPercentile(randomNumbers[randIdx] % Range);
//         } else {
//             _percentile = getRandomPercentile(
//                 uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % Range);
//         }
//         if (ticketInfo_[_tokenId].percentile >= _percentile) {
//             uint _pendingBalance = pendingRound[lastClaimedRound];
//             paidPayable[_tokenId] += _pendingBalance;
//             delete pendingRound[lastClaimedRound];
//             _safeTransfer(
//                 token,
//                 getReceiver(_tokenId),
//                 _pendingBalance
//             );
//             lastClaimedRound++;
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

//     function changePrice(uint _rpPrice) external onlyAdmin {
//         require(_rpPrice <= MAX_PRICE, "PayERC1155: Price too high");
//         rpPrice_ = _rpPrice;
//     }

//     function getRandomPercentile(uint _randomNumber) public pure override returns(uint result) {
//         if (_randomNumber <= 2100) {
//             result = 0;
//         } else if (_randomNumber <= 5100) {
//             result = 10;
//         } else if (_randomNumber <= 10000) {
//             result = 20;
//         } else if (_randomNumber <= 90000) {
//             result = 30;
//         } else if (_randomNumber <= 190000) {
//             result = 40;
//         } else if (_randomNumber <= 310000) {
//             result = 50;
//         } else if (_randomNumber <= 450000) {
//             result = 60;
//         } else if (_randomNumber <= 610000) {
//             result = 70;
//         } else if (_randomNumber <= 790000) {
//             result = 80;
//         } else if (_randomNumber <= 1000000) {
//             result = 90;
//         }
//     }

//     function withdrawRound(uint _round) external onlyAdmin {
//         _safeTransfer(
//             token,
//             msg.sender,
//             pendingRound[_round]
//         );
//         pendingRound[_round] = 0;
//     }

//     function messageAll(uint _amount, bool _video, string memory _msg) external {
//         batchMessage(allTickets_, _amount, _video, _msg);
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
//             treasury
//         );
//         treasury = 0;
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

// contract BallerFactory {
//     address public last_baller;
//     address[] public ballers;
//     function createBaller(
//         uint _series,  // series S & series X are Payswap's main series
//         address _token,
//         address _devaddr,
//         string memory _uri,
//         address _superLikeGaugeFactory,
//         address _randomGenerator
//     ) external returns(address) {
//         last_baller = address(new BallerNFT(
//             _devaddr,
//             _series,
//             _token,
//             _uri,
//             _superLikeGaugeFactory,
//             _randomGenerator
//         ));
//         ballers.push(last_baller);
//         return last_baller;
//     }
// }
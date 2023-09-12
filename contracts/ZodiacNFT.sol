// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;
// pragma experimental ABIEncoderV2;

// import "./Library.sol";

// contract ZodiacNFT is Auth, ERC1155Pausable, ReentrancyGuard {
//     // State variables 
//     mapping(address => bool) extractorTypes_;

//     uint256 public totalSupply_;
//     uint256 public constant MAX_PRICE = 80000000000000000; //0.08 ETH
//     mapping(uint => string) public sponsoredMessages;
//     uint public initialPrice;
//     enum ZODIACOLOR {
//         UNDEFINED,
//         GOLD,
//         SILVER
//     }

//     enum SIGN {
//         UNDEFINED,
//         SAGITTARIUS,
//         CAPRICORN,
//         AQUARIUS,
//         LIBRA,
//         SCORPIO,
//         ARIES,
//         VIRGO,
//         TAURUS,
//         PISCES,
//         GEMINI,
//         LEO,
//         CANCER
//     }

//     // Storage for ticket information
//     struct TicketInfo {
//         address owner;
//         address lender;
//         uint timer;
//         uint date;
//         ZODIACOLOR color;
//         SIGN sign;
//         string sponsoredMessage;
//     }
//     // Token ID => Token information 
//     mapping(uint256 => TicketInfo) public ticketInfo_;
//     uint256 public round = 1;
//     uint256 public lastClaimedRound = 1;
//     uint256 public ticketID = 1;
//     address public token;
//     IRandomNumberGenerator randomGenerator_;
//     uint public price_;
//     uint TEST_CHAIN = 31337;
//     uint public Range = 1000000;
//     uint public treasury;
//     mapping(uint => uint) public pendingRound;
//     mapping(uint => uint) public paidPayable;
//     // User address =>  Ticket IDs
//     mapping(address => uint256[]) public userTickets_;
//     uint[] public allTickets_;
//     mapping(uint => bool) public attached;
//     uint public pricePerAttachMinutes = 1;
//     uint internal constant minute = 3600; // allows minting once per week (reset every Thursday 00:00 UTC)
//     uint public active_period;
//     mapping(address => mapping(uint => ZODIACOLOR)) public isNFTLockable;
//     mapping(string => mapping(address => uint)) public backings;
//     uint public MaximumArraySize = 50;
//     int256 public scaler;
//     mapping(uint => uint) public tokenIdToRound;
//     uint public teamShare;
//     address[] public lockableContracts;
//     uint[] public lockableIds;
//     uint public firstMintTime;
//     uint public period = 86400 * 7 * 30;
//     mapping(ZODIACOLOR => uint) public discounts;
//     mapping(ZODIACOLOR => uint) public isDiscounted;
//     mapping(uint => bool) public blacklist;
//     uint[3] public boosts;
//     //-------------------------------------------------------------------------
//     // EVENTS
//     //-------------------------------------------------------------------------

//     event InfoBatchMint(
//         address indexed receiving, 
//         uint256 amountOfTokens, 
//         uint256[] tokenIds
//     );
//     event Message(address indexed from, uint tokenId, uint time);

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
//         address _devaddr,
//         string memory _uri,
//         uint _initialPrice,
//         address _superLikeGaugeFactory,
//         IRandomNumberGenerator _randomGenerator
//     ) 
//     ERC1155(_uri)
//     Auth(_devaddr, _superLikeGaugeFactory)
//     {
//         // Only Mine contract will be able to mint new tokens
//         token = _token;
//         initialPrice = _initialPrice;
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

//     function getReceiver(uint _tokenId) public view returns(address) {
//         return ticketInfo_[_tokenId].lender == address(0) ?
//         ticketInfo_[_tokenId].owner : ticketInfo_[_tokenId].lender;
//     }

//     function getColorNSign(uint _tokenId) external view returns(ZODIACOLOR,SIGN) {
//         return (
//             ticketInfo_[_tokenId].color,
//             ticketInfo_[_tokenId].sign
//         );
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
//     function updateBlacklist(uint[] memory _tokenIds, bool[] memory _blacklists) external onlyAuth {
//         require(_tokenIds.length == _blacklists.length, "Blackist: Uneven lists");
//         for (uint i = 0; i < _tokenIds.length; i++) {
//             blacklist[_tokenIds[i]] = _blacklists[i];
//         }
//     }

//     function updateRange(uint _newRange) external onlyAdmin {
//         Range = _newRange;
//     }

//     function updateScaler(int256 _newScaler) external onlyAdmin {
//         scaler = _newScaler;
//     }

//     function updateTeamShare(uint _share) external onlyAdmin {
//         teamShare = _share;
//     }

//     function updateDiscounts(
//         ZODIACOLOR[] memory _colors, 
//         uint[] memory _isDiscounted,
//         uint[] memory _discounts
//     ) external onlyAdmin {
//         require(_colors.length == _discounts.length, "Uneven discounts");
//         require(_colors.length == _isDiscounted.length, "Uneven isDiscounted");
//         for (uint i = 0; i < _colors.length; i++) {
//             discounts[_colors[i]] = _discounts[i];
//             isDiscounted[_colors[i]] = _isDiscounted[i];
//         }
//     }
    
//     function updatePeriod(uint _times) external onlyAdmin {
//         period = 86400 * _times;
//     }

//     function costToBuyTickets(ZODIACOLOR _color, uint _num) 
//         public
//         view 
//         returns(uint256 totalCost) 
//     {   
//         uint periodSince = (firstMintTime * period) / period * period;
//         uint price = initialPrice * periodSince;
//         uint discounted = _num >= isDiscounted[_color] ? price * discounts[_color] / 10000 : 0;
//         totalCost = price - discounted;
//     }

//     function updateNFTLockables(
//         address _nftContract, 
//         uint _tokenId,  // 0 if entire collection is elligible
//         uint256[] calldata _colors,
//         bool _delete
//     ) external onlyAdmin {
//         if (!_delete) {
//             for(uint i = 0; i < _colors.length; i++) {
//                 isNFTLockable[_nftContract][_tokenId] = ZODIACOLOR(_colors[i]);
//             }
//             lockableContracts.push(_nftContract);
//             lockableIds.push(_tokenId);
//         } else {
//             delete isNFTLockable[_nftContract][_tokenId];
//             for (uint i = 0; i < lockableContracts.length; i++) {
//                 if (lockableContracts[i] == _nftContract) {
//                     delete lockableContracts[i];
//                     delete lockableIds[i];
//                 }
//             }
//         }
//         require(lockableContracts.length == lockableIds.length, "Invalid lockableContracts");
//     }

//     // Used by non creators to back tokens while buying them
//     function lockToken(
//         address _collection, 
//         uint256 _tokenId,
//         SIGN _sign
//     ) public {
//         require(isNFTLockable[_collection][_tokenId] != ZODIACOLOR.UNDEFINED, "Not lockable");

//         IERC721(_collection).safeTransferFrom(msg.sender, address(this), _tokenId);
//         ZODIACOLOR _color = ZODIACOLOR(isNFTLockable[_collection][_tokenId]);
//         uint[] memory tokenIds = _batchMint(
//             msg.sender,
//             _color,
//             _sign,
//             1
//         );
//         string memory cId = string(abi.encodePacked(address(this), tokenIds[0]));
//         backings[cId][_collection] = _tokenId;
//     }
    
//     function unlockToken(
//         address _collection, 
//         uint256 _tokenId
//     ) public {
//         string memory cId = string(abi.encodePacked(address(this), _tokenId));
//         require(backings[cId][_collection] > 0, "Invalid collection");

//         _burn(msg.sender, _tokenId, 1);
//         IERC721(_collection).safeTransferFrom(address(this), msg.sender, backings[cId][_collection]);

//         delete backings[cId][_collection];
//     }

//     function updatePricePerAttachMinutes(uint _pricePerAttachMinutes) external onlyAdmin {
//         pricePerAttachMinutes = _pricePerAttachMinutes;
//     }

//     /**
//      * @param   _to The address being minted to
//      * @param   _numberOfTickets The number of NFT's to mint
//      * @notice  Only the lotto contract is able to mint tokens. 
//         // uint8[][] calldata _lottoNumbers
//      */
//     function batchBuy(
//         address _to,
//         uint256 _numberOfTickets,
//         ZODIACOLOR _color,
//         SIGN _sign
//     )
//         nonReentrant
//         external
//         returns(uint256[] memory tokenIds)
//     {   
//         if (firstMintTime == 0) firstMintTime = block.timestamp;
//         require(_numberOfTickets <= MaximumArraySize, "Batch mint too large");

//         // Getting the cost and discount for the token purchase
//         uint totalCost = costToBuyTickets(_color, _numberOfTickets);
        
//             // Transfers the required amount to this contract
//         _safeTransferFrom(
//             token,
//             msg.sender, 
//             address(this), 
//             totalCost
//         );
//         tokenIds = _batchMint(
//             _to,
//             _color,
//             _sign,
//             _numberOfTickets
//         );
//         uint _teamFee = totalCost * teamShare / 10000;        
//         pendingRound[round++] += totalCost - _teamFee;
//         treasury += _teamFee;

//         // Request a random number from the generator based on a seed
//         if (getChainID() != TEST_CHAIN) {
//             randomGenerator_.randomnessIsRequestedHere(uint32(_numberOfTickets), msg.sender);
//         }
//     }

//     function _batchMint(
//         address _to,
//         ZODIACOLOR _color,
//         SIGN _sign,
//         uint _numberOfTickets
//     ) internal returns(uint[] memory tokenIds) {
//         // Storage for the amount of tokens to mint (always 1)
//         uint256[] memory amounts = new uint256[](_numberOfTickets);
//         // Storage for the token IDs
//         tokenIds = new uint256[](_numberOfTickets);
//         for (uint8 i = 0; i < _numberOfTickets; i++) {
//             // Incrementing the tokenId counter
//             allTickets_.push(ticketID);
//             tokenIds[i] = ticketID++;
//             tokenIdToRound[tokenIds[i]] = round;
//             amounts[i] = 1;
//             // Storing the ticket information 
//             ticketInfo_[tokenIds[i]] = TicketInfo({
//                 owner: _to,
//                 lender: address(0),
//                 color: _color,
//                 sign: _sign,
//                 date: block.timestamp,
//                 timer: 0,
//                 sponsoredMessage: ""
//             });
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
//     }

//     function claimPendingBalance(
//         uint _tokenId, 
//         uint _randNumberFromUser, 
//         uint _randNumbersLength
//     ) external isNotContract {
//         require(_tokenId <= ticketID, "Invalid token ID");
//         require(pendingRound[lastClaimedRound] > 0, "Round cannot be claimed yet");
        
//         uint _randNumberLink;
//         if (getChainID() != TEST_CHAIN) {
//             uint[] memory randomNumbers = 
//             randomGenerator_.viewRandomNumbers(lastClaimedRound, msg.sender);
//             _randNumbersLength = randomNumbers.length;
//             uint randIdx = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % (randomNumbers.length - 1);
//             _randNumberLink = randomNumbers[randIdx] % Range;
//         } else {
//             _randNumberLink = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % Range;
//         }
//         int256 _diff = _randNumberFromUser > _randNumberLink ?
//         int256(_randNumberFromUser-_randNumberLink) : int256(_randNumberLink-_randNumberFromUser); 
//         uint unitCost = pendingRound[lastClaimedRound] / _randNumbersLength;
//         int256 diffRange = int256(Range / unitCost);
        
//         if (_diff <= diffRange + scaler) {
//             uint _pendingBalance = pendingRound[lastClaimedRound];
//             paidPayable[_tokenId] += _pendingBalance;
//             delete pendingRound[lastClaimedRound];
//              _safeTransfer(
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

//     function updateBoosts(uint[3] memory _boosts) external onlyAdmin {
//         require(_boosts.length == 3, "Invalid number of boosts");
//         boosts = _boosts;
//     }

//     function boostingPower(uint _tokenId) external view returns(uint) {
//         require(ticketInfo_[_tokenId].owner != address(0), "Does not exist");
//         if (ticketInfo_[_tokenId].color == ZODIACOLOR.GOLD) {
//             return boosts[2];
//         } else if (ticketInfo_[_tokenId].color == ZODIACOLOR.SILVER) {
//             return boosts[1];
//         } else {
//             return boosts[0];
//         }
//     }

//     function changePrice(uint _price) external onlyAdmin {
//         require(_price <= MAX_PRICE, "Price too high");
//         price_ = _price;
//     }

//     function withdrawRound(uint _round) external onlyAdmin {
//         _safeTransfer(
//             token,
//             msg.sender,
//             pendingRound[_round]
//         );
//         pendingRound[_round] = 0;
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
//             ticketInfo_[_tokenIds[i]].sponsoredMessage = _message;
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
//             require(price_ * totalSupply_ <= msg.value, "PayERC1155: Ether value sent is not correct");
//         }

//         for(uint i = 0; i < ids.length; i++) {
//             ticketInfo_[ids[i]].owner = to;
//             require(!attached[ids[i]] && !blacklist[ids[i]] , "PayERC1155: Attached!");
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
//         uint _period,
//         address from,
//         address to,
//         uint256 id,
//         uint256 amount,
//         bytes memory data
//     ) external {
//         super.safeTransferFrom(from, to, id, amount, data);
//         attach(id, _period, attachTo);
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



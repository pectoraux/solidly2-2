// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;
// pragma experimental ABIEncoderV2;

// import "./Library.sol";

// contract GreenNFT is ERC1155Pausable, Ownable, ReentrancyGuard, Auth {
//     // State variables 
//     mapping(address => bool) extractorTypes_;

//     uint256 public totalSupply_;
//     uint256 public constant MAX_PRICE = 80000000000000000; //0.08 ETH
//     mapping(uint => string) public sponsoredMessages;
    
//     // Storage for ticket information
//     struct TicketInfo {
//         address owner;
//         address lender;
//         uint timer;
//         uint credits;
//         uint ppm;
//         uint date;
//         string first4Chars;
//         string last4Chars;
//         string extension;
//         string resource;
//         uint lockedTill;
//         uint lastUpdate;
//         string sponsoredMessage;
//     }
//     mapping(uint => uint) public prevCredits;
//     mapping(uint => address) public auditors;
//     // Token ID => Token information 
//     mapping(uint256 => TicketInfo) public ticketInfo_;
//     uint256 public round = 1;
//     uint256 public ticketID = 1;
//     address public token;
//     IRandomNumberGenerator randomGenerator_;
//     uint public price_;
//     uint TEST_CHAIN = 31337;
//     uint public Range = 1000000;
//     uint public treasury;
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
//     // code => owner
//     mapping(uint => uint) public ownerOfCode;
//     // token Id => round
//     mapping(uint => uint) public tokenIdToRound;
//     uint public MaximumArraySize = 50;
//     int256 public scaler;
//     uint public teamShare;

//     struct Resource {
//         uint[] i; // resource rpm
//         string[] j; // resource name
//     }
//     // first8Chars => Resource
//     mapping(string => Resource) internal PlusCodeResources;
//     // enables resources updates
//     uint public linkFee = 1;
//     uint public resourceLockTime = 86400 * 7; //1 week
//     // enables resource updates
//     mapping(string => uint) public shouldUpdateTokenBy;
//     mapping(string => uint) public canUpdateTokenBy;
//     mapping(uint => bool) public blacklist;
//     uint[4] public boosts;
//     uint public lastClaimedRound = 1;
//     uint public span = 10000;

//     //-------------------------------------------------------------------------
//     // EVENTS
//     //-------------------------------------------------------------------------
//     event InfoBatchBuy(address to, uint[] codes, uint[] tokenIds, uint time);
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
//         string memory _uri,
//         address _superLikeGaugeFactory,
//         IRandomNumberGenerator _randomGenerator
//     ) 
//     ERC1155(_uri)
//     Auth(msg.sender, _superLikeGaugeFactory)
//     {
//         // Only Mine contract will be able to mint new tokens
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

//     /**
//      * @param   _ticketID: The unique ID of the ticket
//      * @return  uint32[]: The chosen numbers for that ticket
//      */
//     function getFirst4Chars(
//         uint256 _ticketID
//     ) 
//         external 
//         view 
//         returns(string memory) 
//     {
//         return ticketInfo_[_ticketID].first4Chars;
//     }

//     function getLast4Chars(
//         uint256 _ticketID
//     ) 
//         external 
//         view 
//         returns(string memory) 
//     {
//         return ticketInfo_[_ticketID].last4Chars;
//     }

//     function getExtension(
//         uint256 _ticketID
//     ) 
//         external 
//         view 
//         returns(string memory) 
//     {
//         return ticketInfo_[_ticketID].extension;
//     }
    
//     function getTicketResource(
//         uint256 _ticketID
//     ) 
//         external 
//         view 
//         returns(string memory) 
//     {
//         return ticketInfo_[_ticketID].resource;
//     }

//     /**
//      * @param   _ticketID: The unique ID of the ticket
//      * @return  address: Owner of ticket
//      */
//     function getOwnerOfTicket(
//         uint256 _ticketID
//     ) 
//         external 
//         view 
//         returns(address) 
//     {
//         return ticketInfo_[_ticketID].owner;
//     }

//     function getOwnerOfCode(
//         uint code
//     ) 
//         external 
//         view 
//         returns(uint) 
//     {
//         return ownerOfCode[code];
//     }

//     function getTicketLastUpdate(
//         uint256 _ticketID
//     ) 
//         external 
//         view
//         returns(uint) 
//     {
//         return ticketInfo_[_ticketID].lastUpdate;
//     }

//     function getUserTickets(
//         address _user
//     ) 
//         external 
//         view 
//         returns(uint256[] memory) 
//     {
//         return userTickets_[_user];
//     }

//     function getReceiver(uint _tokenId) public view returns(address) {
//         return ticketInfo_[_tokenId].lender == address(0) ?
//         ticketInfo_[_tokenId].owner : ticketInfo_[_tokenId].lender;
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
//     function updateRange(uint _newRange) external onlyAdmin {
//         Range = _newRange;
//     }

//     function updateBlacklist(uint[] memory _tokenIds, bool[] memory _blacklists) external onlyAuth {
//         require(_tokenIds.length == _blacklists.length, "Blackist: Uneven lists");
//         for (uint i = 0; i < _tokenIds.length; i++) {
//             blacklist[_tokenIds[i]] = _blacklists[i];
//         }
//     }

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

//     function updateScaler(int256 _newScaler) external onlyAdmin {
//         scaler = _newScaler;
//     }

//     function updateTeamShare(uint _share) external onlyAdmin {
//         teamShare = _share;
//     }

//     function updateLinkFee(uint _newFee) external onlyAdmin {
//         linkFee = _newFee;
//     }
     
//     /**
//      * @param   _to The address being minted to
//      * @notice  Only the lotto contract is able to mint tokens. 
//         // uint8[][] calldata _lottoNumbers
//      */
//     function batchBuy(
//         address _to,
//         uint[] memory _codes,
//         string[] memory _first4Chars,
//         string[] memory _last4Chars,
//         string[] memory _extensions
//     )
//         nonReentrant
//         onlyAdmin
//         external
//         returns(uint256[] memory tokenIds)
//     {   
//         require(
//             _codes.length == _first4Chars.length &&
//             _codes.length == _last4Chars.length &&
//             _codes.length == _extensions.length,
//             "Invalid code lists"

//         );
//         _safeTransferFrom(
//             token,
//             msg.sender,
//             address(this),
//             linkFee
//         );
//         treasury += linkFee;
//         // Storage for the amount of tokens to mint (always 1)
//         uint256[] memory amounts = new uint256[](_codes.length);
//         // Storage for the token IDs
//         tokenIds = new uint256[](_codes.length);
//         for (uint i = 0; i < _codes.length; i++) {
//             uint codeTicket = ownerOfCode[_codes[i]];
//             if (codeTicket != 0) {
//                 _burn(ticketInfo_[codeTicket].owner, codeTicket, 1);
//                 delete ticketInfo_[codeTicket];
//             }
//             allTickets_.push(ticketID);
//             tokenIds[i] = ticketID++;
//             amounts[i] = 1;
//             tokenIdToRound[tokenIds[i]] = round++;
//             ticketInfo_[tokenIds[i]] = TicketInfo(
//                 _to,
//                 address(0),
//                 0,
//                 0,
//                 0,
//                 block.timestamp,
//                 _first4Chars[i],
//                 _last4Chars[i],
//                 _extensions[i],
//                 "",
//                 0,
//                 0,
//                 ""
//             );
//             userTickets_[_to].push(tokenIds[i]);
//             ownerOfCode[_codes[i]] = tokenIds[i];
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
//             randomGenerator_.randomnessIsRequestedHere(uint32(_codes.length), msg.sender);
//         }
//         // Emitting relevant info
//         emit InfoBatchBuy(
//             _to, 
//             _codes,
//             tokenIds,
//             block.timestamp
//         ); 
//     }

//     function uri(uint256 _tokenId) public view virtual override returns (string memory) {
//         string memory first8Chars = string(abi.encodePacked(
//             ticketInfo_[_tokenId].first4Chars,
//             ticketInfo_[_tokenId].last4Chars
//         ));
//         require(shouldUpdateTokenBy[first8Chars] == ticketInfo_[_tokenId].lastUpdate ||
//             shouldUpdateTokenBy[first8Chars] >= block.timestamp,
//             "Token needs update before viewing"
//         );
//         super.uri(_tokenId);
//     }

//     function setUpdateForToken(
//         string[] memory _tokenFirst8Chars, 
//         uint[] memory _updateBys, 
//         bool hardFork
//     ) external onlyAdmin {
//         require(_tokenFirst8Chars.length == _updateBys.length, "Invalid list of updates");
//         for (uint i = 0; i < _tokenFirst8Chars.length; i++) {
//             if (hardFork) {
//                 shouldUpdateTokenBy[_tokenFirst8Chars[i]] = block.timestamp + _updateBys[i];
//             } else {
//                 canUpdateTokenBy[_tokenFirst8Chars[i]] = block.timestamp + _updateBys[i];
//             }
//         }
//     }
    
//     // used in case a new resource is added to a pluscode
//     function updateUri(uint256[] memory _tokenIds) public nonReentrant {
//         _safeTransferFrom(
//             token,
//             msg.sender,
//             address(this),
//             linkFee
//         );
//         treasury += linkFee;
//         for (uint i = 0; i < _tokenIds.length; i++) {
//             string memory first8Chars = string(abi.encodePacked(
//                 ticketInfo_[_tokenIds[i]].first4Chars,
//                 ticketInfo_[_tokenIds[i]].last4Chars
//             ));
//             require(
//                 shouldUpdateTokenBy[first8Chars] > 0 || canUpdateTokenBy[first8Chars] > 0,
//                 "No update available for token"
//             );
//             tokenIdToRound[_tokenIds[i]] = round++;
//             keccak256(abi.encodePacked(ticketInfo_[_tokenIds[i]].resource)) == keccak256(abi.encodePacked(""));
//         }
//         if (getChainID() != TEST_CHAIN) {
//             randomGenerator_.randomnessIsRequestedHere(uint32(_tokenIds.length), msg.sender);
//         }
//     }

//     function extractCreditFromNFT(
//         address _badgeNFT,
//         uint _tokenId,
//         uint _greenTokenId
//     ) external {
//         require(extractorTypes_[_badgeNFT], "Only Extractors!");
//         require(IBadgeNFT(_badgeNFT).getTicketOwner(_tokenId) == msg.sender, "Only Owner!");
//         require(ticketInfo_[_greenTokenId].owner == msg.sender, "Only green Owner!");

//         checkIdentityProof(msg.sender, false);        
//         (address _factory, address _auditor) = IBadgeNFT(_badgeNFT).getTicketAuditor(_tokenId);
//         require(_factory == superLikeGaugeFactory, "Invalid Badge");

//         (
//             string memory _rating_description,, 
//             int _credit_pm_pd
//         ) = IBadgeNFT(_badgeNFT).getTicketRating(_tokenId);
//         require(keccak256(abi.encodePacked(_rating_description)) == 
//                 keccak256(abi.encodePacked("carbon_credit_per_million_per_day")), "Invalid rating");
//         uint _prevTotal = ticketInfo_[_greenTokenId].credits * (block.timestamp - ticketInfo_[_greenTokenId].date) / 86400;
//         prevCredits[_greenTokenId] += _prevTotal;
//         ticketInfo_[_greenTokenId].date = block.timestamp;
//         ticketInfo_[_greenTokenId].credits = uint(_credit_pm_pd);
//         auditors[_greenTokenId] = _auditor;
//     }

//     function updateExtractorType(
//         address _typeContract, 
//         bool _extractor
//     ) external onlyAdmin {
//         extractorTypes_[_typeContract] = _extractor;
//     }

//     function extractResource(
//         uint _tokenId,
//         address _extractor
//     ) external nonReentrant {
//         require(ticketInfo_[_tokenId].lockedTill <= block.timestamp, "Locked");
//         require(msg.sender == getReceiver(_tokenId), "Invalid receiver");
//         require(keccak256(abi.encodePacked(ticketInfo_[_tokenId].resource)) != keccak256(abi.encodePacked("empty")), 
//         "No resource to extract");
//         require(extractorTypes_[_extractor], "Not a valid extractor");

//         ticketInfo_[_tokenId].lockedTill += resourceLockTime;
//         IExtractor(_extractor).extractResource(ticketInfo_[_tokenId].resource, msg.sender, 1);
//     }

//     function getResource(uint tokenId, uint scaled_random) internal view returns(string memory, uint256) {
//         string memory first8Chars = string(abi.encodePacked(
//             ticketInfo_[tokenId].first4Chars,
//             ticketInfo_[tokenId].last4Chars
//         ));
//         uint256 _length = PlusCodeResources[first8Chars].i.length; 
//         if (_length > 0 && PlusCodeResources[first8Chars].i[_length-1] >= scaled_random) {
//             return getResourceName(first8Chars, scaled_random);
//         }
//         return (string("empty"), 0);
//     }
    
//     function setResource(uint _tokenId) public {
//         if (keccak256(abi.encodePacked(ticketInfo_[_tokenId].resource)) == keccak256(abi.encodePacked(""))) {
//             uint _round = tokenIdToRound[_tokenId];
//             string memory randomResource;
//             uint ppm;
//             if (getChainID() != TEST_CHAIN) {
//                 uint[] memory randomNumbers = 
//                 randomGenerator_.viewRandomNumbers(_round, msg.sender);
//                 uint randIdx = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % (randomNumbers.length - 1);
//                 (randomResource, ppm) = getResource(_tokenId, randomNumbers[randIdx] % Range);
//             } else {
//                 (randomResource, ppm) = getResource(_tokenId, uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % Range);
//             }
//             ticketInfo_[_tokenId].resource = randomResource;
//             ticketInfo_[_tokenId].ppm = ppm;
//             string memory first8Chars = string(abi.encodePacked(
//                 ticketInfo_[_tokenId].first4Chars,
//                 ticketInfo_[_tokenId].last4Chars
//             ));
//             uint _lastUpdate = shouldUpdateTokenBy[first8Chars] > 0 ?
//             shouldUpdateTokenBy[first8Chars] : block.timestamp;
//             ticketInfo_[_tokenId].lastUpdate = _lastUpdate;
//         }
//     } 

//     function updateResource(
//         string calldata first8Chars,
//         string[] calldata _resources, 
//         uint256[] calldata _ppmDeltas
//     ) external onlyAdmin {
//         checkDeltas(_ppmDeltas);
//         require(_resources.length == _ppmDeltas.length, "Invalid resources");
//         PlusCodeResources[first8Chars] = Resource({
//             i: _ppmDeltas, 
//             j: _resources
//         });
//     }

//     // [calcium, Manganese, Aluminium] [3000,5000,10000]
//     function checkDeltas(uint256[] memory deltas) internal pure {
//         for(uint i = 1; i < deltas.length; i++){
//             require(deltas[i] > deltas[i-1], "Invalid Deltas");
//         }
//     }

//     function getResourceName(string memory first8Chars, uint256 scaled_random) internal view returns(string memory, uint256) {
//         uint256 prev = 0;
//         for (uint256 i = 0; i < PlusCodeResources[first8Chars].i.length; i++) {
//             uint curr = PlusCodeResources[first8Chars].i[i];
//             if (scaled_random <= curr) {
//                 return (PlusCodeResources[first8Chars].j[i], curr - prev);
//             }
//             prev = curr;
//         }
//         return (string("empty"), 0);
//     }

//     function updateResourceLockTime(uint newLockTime) external onlyAdmin {
//         resourceLockTime = newLockTime;
//     }

//     function addSponsoredMessages(uint _tokenId, string memory _message) external {
//         require(msg.sender == ticketInfo_[_tokenId].owner, "PayERC1155: Only owner");
//         sponsoredMessages[_tokenId] = _message;
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

//     function withdrawTreasury2(address _token) external onlyAdmin {
//         _token = _token == address(0) ? token : _token;
//         _safeTransfer(
//             _token,
//             msg.sender,
//             erc20(_token).balanceOf(address(this))
//         );
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
//         if (ticketInfo_[_tokenId].ppm >= Q4) {
//             result = boosts[3];
//         } else if (ticketInfo_[_tokenId].ppm >= Q3) {
//             result = boosts[2];
//         } else if (ticketInfo_[_tokenId].ppm >= Q2) {
//             result = boosts[1];
//         } else if (ticketInfo_[_tokenId].ppm >= Q1) {
//             result = boosts[0];
//         }
//     }

//     function changePrice(uint _price) external onlyAdmin {
//         require(_price <= MAX_PRICE, "Price too high");
//         price_ = _price;
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

//         if (msg.sender != devaddr_) {
//             require(price_ * totalSupply_ <= msg.value, "PayERC1155: Ether value sent is not correct");
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



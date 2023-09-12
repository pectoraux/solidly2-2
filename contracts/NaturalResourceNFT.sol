// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;
// pragma experimental ABIEncoderV2;

// import "./Library.sol";

// contract NaturalResourceNFT is Auth, ERC1155Pausable, Ownable, ReentrancyGuard {
//     // State variables 
//     mapping(address => bool) extractorTypes_;
//     uint internal constant week = 86400 * 7; // allows minting once per week (reset every Thursday 00:00 UTC)
//     uint256 public totalSupply_;
//     uint256 public constant MAX_PRICE = 80000000000000000; //0.08 ETH
//     mapping(uint => string) public sponsoredMessages;
//     uint public teamShare;
//     mapping(string => uint) public PPM;
//     mapping(bytes32 => uint) public badgeHolders;
//     uint public FarmersDivisor = 1;
//     uint public FarmersMintPerWeek = 1000000;
//     uint public FarmersMintSoFar;
//     uint public active_period;
//     uint public randNumberLink;
//     // Storage for ticket information
//     struct TicketInfo {
//         address owner;
//         address lender;
//         string resource;
//         uint ppm;
//         uint date;
//         uint timer;
//         string sponsoredMessage;
//     }
//     // Token ID => Token information 
//     mapping(uint256 => TicketInfo) public ticketInfo_;
//     uint256 public round_ = 1;
//     uint256 public lastClaimedRound = 1;
//     uint256 public ticketID = 1;
//     address public token;
//     IRandomNumberGenerator randomGenerator_;
//     uint public price_;
//     uint TEST_CHAIN = 31337;
//     uint public Range = 1000000;
//     uint public treasury;
//     int256 public scaler;
//     mapping(uint => uint) public pendingRound;
//     mapping(uint => uint) public paidPayable;
//     mapping(address => mapping(string => uint)) public pendingTicket;
//     // User address =>  Ticket IDs
//     mapping(address => uint256[]) public userTickets_;
//     uint[] public allTickets_;
//     mapping(uint => bool) public attached;
//     uint public Q1 = 1;
//     uint public Q2 = 25;
//     uint public Q3 = 50;
//     uint public Q4 = 75;
//     uint public MaximumArraySize = 50;
//     string[] public allAdditionalResources;
//     uint[4] public boosts;
//     uint public pricePerAttachMinutes = 1;
//     uint internal constant minute = 3600; // allows minting once per week (reset every Thursday 00:00 UTC)
//     uint public active_period2;
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
//         string memory _uri,
//         address _randomGenerator,
//         address _superLikeGaugeFactory
//     ) 
//     ERC1155(_uri)
//     Auth(msg.sender, _superLikeGaugeFactory)
//     {
//         // Only Mine contract will be able to mint new tokens
//         token = _token;
//         devaddr_ = msg.sender;
//         randomGenerator_ = IRandomNumberGenerator(_randomGenerator);
//         active_period = (block.timestamp + week) / week * week;
//         PPM["oxygen"] = 461000;
//         PPM["silicon"] = 282000;
//         PPM["aluminium"] = 82000;
//         PPM["iron"] = 56300;
//         PPM["calcium"] = 41500;
//         PPM["sodium"] = 23600;
//         PPM["magnesium"] = 23300;
//         PPM["potassium"] = 20900;
//         PPM["titanium"] = 5600;
//         PPM["hydrogen"] = 1400;
//         PPM["fluorine"] = 585;
//         PPM["barium"] = 425;
//         PPM["sulphur"] = 350;
//         PPM["carbon"] = 200;
//         PPM["chlorine"] = 145;
//         PPM["chromium"] = 102;
//         PPM["nickel"] = 84;
//         PPM["zinc"] = 70;
//         PPM["copper"] = 60;
//         PPM["neodymium"] = 42;
//         PPM["cobalt"] = 25;
//         PPM["lithium"] = 20;
//         PPM["nitrogen"] = 19;
//         PPM["lead"] = 14;
//         PPM["boron"] = 10;
//         PPM["thorium"] = 10;
//         PPM["argon"] = 4;
//         PPM["caesium"] = 3;
//         PPM["uranium"] = 3;
//         PPM["bromine"] = 3;
//         PPM["tin"] = 2;
//         PPM["tungsten"] = 2;
//         PPM["lodine"] = 2;
//         PPM["mercury"] = 2;
//         PPM["silver"] = 2;
//         PPM["palladium"] = 1;
//         PPM["bismuth"] = 1;
//         PPM["helium"] = 1;
//         PPM["neon"] = 1;
//         PPM["platinum"] = 1;
//         PPM["osmium"] = 1;
//         PPM["iridium"] = 1;
//         PPM["krypton"] = 1;
//         PPM["xenon"] = 1;
//         PPM["protactinium"] = 1;
//         PPM["radium"] = 1;
//         PPM["polonium"] = 1;
//         PPM["plutonium"] = 1;
//         PPM["neptunium"] = 1;
//         PPM["radon"] = 1;
//         PPM["tritium"] = 1;
//         PPM["francium"] = 1;
//         PPM["astatine"] = 1;
//         PPM["timber"] = 1;
//         PPM["copper"] = 1;
//         PPM["rare_earth_metals"] = 1;
//         PPM["phosphate"] = 1;
//         PPM["bauxite"] = 1;
//         PPM["arsenic"] = 1;
//         PPM["salt"] = 1;
//         PPM["feldspar"] = 1;
//         PPM["graphite"] = 1;
//         PPM["manganese"] = 1;
//         PPM["rubber"] = 1;
//         PPM["sand"] = 1;
//         PPM["oil"] = 1;
//         PPM["gas"] = 1;
//         // tree fruits/animals 
//         // to incentivise forest digital clones
//         PPM["wheat"] = 1;
//         PPM["rice"] = 1;
//         PPM["potatoe"] = 1;
//         PPM["corn"] = 1;
//         PPM["cotton"] = 1;
//         PPM["wagyu_beef"] = 1;
//         PPM["milk"] = 1;
//         // sea food to incentivise sea digital clones
//         PPM["big_eye_tuna"] = 1;
//         PPM["yellow_fin_tuna"] = 1;
//         PPM["blue_fin_tuna"] = 1;
//         PPM["crab"] = 1;
//         PPM["octopus"] = 1;
//         PPM["tilapia"] = 1;
//         PPM["squid"] = 1;
//         PPM["fresh_fish"] = 1;
//         PPM["water"] = 1;
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

//     function getTicketResource(uint _tokenId) external view returns(string memory) {
//         return ticketInfo_[_tokenId].resource;
//     }

//     function getTicketPPM(uint _tokenId) external view returns(uint) {
//         return ticketInfo_[_tokenId].ppm;
//     }

//     function getTicketLender(uint _tokenId) external view returns(address) {
//         return ticketInfo_[_tokenId].lender;
//     }

//     function getTicketOwner(uint _tokenId) external view returns(address) {
//         return ticketInfo_[_tokenId].owner;
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

//     function updatePricePerAttachMinutes(uint _pricePerAttachMinutes) external onlyAdmin {
//         pricePerAttachMinutes = _pricePerAttachMinutes;
//     }

//     function updateScaler(int256 _newScaler) external onlyAdmin {
//         scaler = _newScaler;
//     }
    
//     function updatePPM(string[] calldata _names, uint[] calldata _ppms) external onlyAdmin {
//         require(_names.length == _ppms.length, "Invalid resources");
//         for (uint i = 0; i < _names.length; i++) {
//             if (PPM[_names[i]] == 0) allAdditionalResources.push(_names[i]);
//             PPM[_names[i]] = _ppms[i];
//         }
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

//     function updateMaxArraySize(uint _maxArrSize) external onlyAdmin {
//         MaximumArraySize = _maxArrSize;
//     }

//     /**
//      * @param   _to The address being minted to
//      * @param   _numberOfTickets The number of NFT's to mint
//      * @notice  Only the lotto contract is able to mint tokens. 
//         // uint8[][] calldata _lottoNumbers
//      */
//     function batchMint(
//         address _to,
//         uint256 _costPerTicket,
//         string calldata _resource,
//         uint256 _numberOfTickets
//     )
//         nonReentrant
//         external
//     {
//         require(
//             _numberOfTickets <= MaximumArraySize,
//             "Batch mint too large"
//         );
//         require(PPM[_resource] > 0, "Invalid, resource");
//         _safeTransferFrom(
//             token,
//             _to, 
//             address(this), 
//             _costPerTicket * _numberOfTickets
//         );
//         uint _teamFee = _costPerTicket * _numberOfTickets * teamShare / 10000;
//         pendingTicket[_to][_resource] = _costPerTicket * _numberOfTickets - _teamFee;
//         treasury += _teamFee;

//         // Request a random number from the generator based on a seed
//         if (getChainID() != TEST_CHAIN) {
//             randomGenerator_.randomnessIsRequestedHere(uint32(_numberOfTickets) * 2, _to);
//             // SponsorCard._safeTransferFrom(link, msg.sender, address(this), link_fee);
//         }
//         round_++;
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
//             _randNumbersLength = randomNumbers.length / 2;
//             uint randIdx = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % (randomNumbers.length - 1);
//             _randNumberLink = randomNumbers[randIdx] % Range;
//         } else {
//             _randNumberLink = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % Range;
//         }
//         randNumberLink = _randNumberLink;
//         int256 _diff = _randNumberFromUser > _randNumberLink ?
//         int256(_randNumberFromUser-_randNumberLink) : int256(_randNumberLink-_randNumberFromUser); 
//         uint unitCost = pendingRound[lastClaimedRound] / _randNumbersLength;
//         int256 diffRange = int256(Range / unitCost);

//         if (_diff <= diffRange + scaler) {
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

//     function updateExtractorType(
//         address _typeContract, 
//         bool _extractor
//     ) external onlyAdmin {
//         extractorTypes_[_typeContract] = _extractor;
//     }

//     function extractResource(
//         string memory _resource, 
//         address _to,
//         uint _numberOfTickets
//     ) external {
//         require(extractorTypes_[msg.sender], "Only Extractors!");
//         require(PPM[_resource] > 0, "Invalid resource");
//         _batchMint(
//             _to, 
//             _resource, 
//             _numberOfTickets
//         );
//     }
    
//     function updateFarmersDivisor(uint _divisor, uint _mintPerWeek) external onlyAdmin {
//         require(FarmersDivisor > 0);
//         FarmersDivisor = _divisor; 
//         FarmersMintPerWeek = _mintPerWeek;
//     }

//     function extractResourceFromNFT(
//         address _badgeNFT,
//         uint _tokenId
//     ) external {
//         if (active_period <= block.timestamp) {
//             FarmersMintSoFar = 0;
//             active_period = (block.timestamp + week) / week * week;
//         }
//         require(FarmersMintSoFar < FarmersMintPerWeek, "Reached maximum weekly mint");
//         require(extractorTypes_[_badgeNFT], "Only Extractors!");
//         require(IBadgeNFT(_badgeNFT).getTicketOwner(_tokenId) == msg.sender, "Only Owner!");
        
//         checkIdentityProof(msg.sender, false);        
//         (address _factory,) = IBadgeNFT(_badgeNFT).getTicketAuditor(_tokenId);
//         require(_factory == superLikeGaugeFactory, "Invalid Badge");

//         (
//             string memory _rating_description, 
//             string memory _resource, 
//             int _numberOfTickets
//         ) = IBadgeNFT(_badgeNFT).getTicketRating(_tokenId);
//         require(keccak256(abi.encodePacked(_rating_description)) == 
//                 keccak256(abi.encodePacked("resource")), "Invalid rating");
//         require(PPM[_resource] > 0, "Invalid resource");
//         bytes32 _identityCode = userToIdentityCode[msg.sender];
//         uint _delta = uint(_numberOfTickets) / FarmersDivisor - badgeHolders[_identityCode]; 
//         badgeHolders[_identityCode] += _delta;
//         FarmersMintSoFar += _delta;
//         require(_delta > 0, "Nothing to mint");
//         _batchMint(
//             msg.sender, 
//             _resource, 
//             _delta
//         );
//     }

//     function setTicket(
//         uint _round, 
//         string memory _resource, 
//         uint _numberOfTickets
//     ) external {   
//         require(pendingTicket[msg.sender][_resource] > 0, "Call batchMint first");
//         uint randomNumber;
//         if (getChainID() != TEST_CHAIN) {
//             uint[] memory randomNumbers = 
//             randomGenerator_.viewRandomNumbers(_round, msg.sender);
//             _numberOfTickets = randomNumbers.length / 2;
//             uint randIdx = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % (randomNumbers.length - 1);
//             randomNumber = randomNumbers[randIdx] % Range;
//         } else {
//             randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % Range;
//         }

//         if (randomNumber <= PPM[_resource] * pendingTicket[msg.sender][_resource]) {
//             _batchMint(
//                 msg.sender, 
//                 _resource, 
//                 _numberOfTickets
//             );
//         }
//         pendingRound[lastClaimedRound] += pendingTicket[msg.sender][_resource];
//         delete pendingTicket[msg.sender][_resource];
//     } 

//     function _batchMint(
//         address _to, 
//         string memory _resource, 
//         uint _numberOfTickets
//     ) internal 
//       returns(uint256[] memory tokenIds)
//     {
//         // Storage for the amount of tokens to mint (always 1)
//         uint256[] memory amounts = new uint256[](_numberOfTickets);
//         // Storage for the token IDs
//         tokenIds = new uint256[](_numberOfTickets);

//         for (uint8 i = 0; i < _numberOfTickets; i++) {
//             // Incrementing the tokenId counter
//             uint256 _date = block.timestamp;
//             allTickets_.push(ticketID);
//             tokenIds[i] = ticketID++;
//             amounts[i] = 1;
//             // Storing the ticket information 
//             ticketInfo_[tokenIds[i]] = TicketInfo({
//                 owner: _to,
//                 lender: address(0),
//                 resource: _resource,
//                 ppm: PPM[_resource],
//                 date: _date,
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

//         // // Emitting relevant info
//         // emit InfoBatchMint(
//         //     _to, 
//         //     _numberOfTickets, 
//         //     tokenIds,
//         //     block.timestamp
//         // ); 
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

//     function updateTeamShare(uint _share) external onlyAdmin {
//         teamShare = _share;
//     }

//     function withdrawRound(uint _round) external onlyAdmin {
//         _safeTransfer(
//             token,
//             msg.sender,
//             pendingRound[_round]
//         );
//         pendingRound[_round] = 0;
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

//     function messageAll(uint _tokenId, uint _amount, string memory _message) external {
//         batchMessage(_tokenId, allTickets_, _amount, _message);
//     }

//     function messageFromTo(uint _tokenId, uint _amount, uint _first, uint _last, string memory _message) external {
//         uint[] memory _tokenIds = getTicketsPagination(_first, _last);
//         batchMessage(_tokenId, _tokenIds, _amount, _message);
//     }

//     function batchMessage(uint _tokenId, uint[] memory _tokenIds, uint _amount, string memory _message) public {
//         require(getReceiver(_tokenId) == msg.sender, "Invalid token ID");
//         require(active_period2 < block.timestamp, "Current message not yet expired");
//         _safeTransferFrom(
//             token,
//             address(msg.sender), 
//             address(this),
//             _amount * pricePerAttachMinutes
//         );
//         pendingRound[lastClaimedRound] += _amount * pricePerAttachMinutes;
//         active_period2 = (block.timestamp + (_amount*minute)) / minute * minute;
//         for (uint i = 0; i < _tokenIds.length; i++) {
//             ticketInfo_[_tokenIds[i]].sponsoredMessage = _message;
//         }

//         emit Message(msg.sender, _tokenId, block.timestamp);
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
//             require(!attached[ids[i]], "PayERC1155: Attached!");
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



// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;
// pragma experimental ABIEncoderV2;

// import "./Library.sol";
// import "./slice.sol";

// contract DiamondNFT is Auth, ERC1155Pausable, ReentrancyGuard {
//     using strings for *;
//     enum DIAMONDCOLOR {
//         UNDEFINED,
//         FANCY_RED,
//         FANCY_BLUE,
//         FANCY_PINK,
//         FANCY_PURPLE,
//         FANCY_GREEN,
//         FANCY_YELLOW,
//         D,
//         E,
//         F,
//         G,
//         H,
//         I,
//         J,
//         K,
//         L, 
//         M
//     }
//     enum CLARITY {
//         UNDEFINED,
//         FL,
//         IS,
//         VVS1,
//         VVS2,
//         VS1,
//         VS2,
//         SI1,
//         SI2,
//         I1
//     }
//     // State variables 
//     mapping(address => bool) extractorTypes_;

//     uint256 public totalSupply_;
//     uint256 public constant MAX_PRICE = 80000000000000000; //0.08 ETH
//     mapping(uint => string) public sponsoredMessages;
//     mapping(DIAMONDCOLOR => uint) public PPM;
    
//     // Storage for ticket information
//     struct TicketInfo {
//         address owner;
//         address lender;
//         uint timer;
//         DIAMONDCOLOR color;
//         uint ppm;
//         uint carat;
//         CLARITY clarity;
//         string certificationID;
//         uint date;
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
//     uint public Q1 = 1;
//     uint public Q2 = 25;
//     uint public Q3 = 50;
//     uint public Q4 = 75;
//     uint256 public MIN_CARAT = 3;
//     uint256 public MAX_CARAT = 3000;
//     mapping(string => bool) public isMinted;
//     struct Diamond {
//         CLARITY clarity;
//         uint carat;
//         DIAMONDCOLOR color;
//     }
//     mapping(address => mapping(uint => Diamond[])) public isNFTLockable;
//     mapping(string => mapping(address => uint)) public backings;
//     uint public MaximumArraySize = 50;
//     int256 public scaler;
//     mapping(uint => uint) public tokenIdToRound;
//     uint public teamShare;
//     mapping(string => uint) public COLORS_;
//     mapping(string => uint) public CLARITIES_;
//     mapping (uint256 => mapping(uint256 => uint256)) public priceFactor;
//     address[] public lockableContracts;
//     uint[] public lockableIds;
//     uint[4] public boosts;

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
//         address _superLikeGaugeFactory,
//         IRandomNumberGenerator _randomGenerator
//     ) 
//     ERC1155(_uri)
//     Auth(_devaddr, _superLikeGaugeFactory)
//     {
//         // Only Mine contract will be able to mint new tokens
//         token = _token;
//         randomGenerator_ = IRandomNumberGenerator(_randomGenerator);
//         PPM[DIAMONDCOLOR.FANCY_RED] = 2;
//         PPM[DIAMONDCOLOR.FANCY_BLUE] = 3;
//         PPM[DIAMONDCOLOR.FANCY_PINK] = 5;
//         PPM[DIAMONDCOLOR.FANCY_PURPLE] = 20;
//         PPM[DIAMONDCOLOR.FANCY_GREEN] = 30;
//         PPM[DIAMONDCOLOR.FANCY_YELLOW] = 40;
//         PPM[DIAMONDCOLOR.D] = 2000;
//         PPM[DIAMONDCOLOR.E] = 3000;
//         PPM[DIAMONDCOLOR.F] = 4900;
//         PPM[DIAMONDCOLOR.G] = 80000;
//         PPM[DIAMONDCOLOR.H] = 100000;
//         PPM[DIAMONDCOLOR.I] = 120000;
//         PPM[DIAMONDCOLOR.J] = 140000;
//         PPM[DIAMONDCOLOR.K] = 160000;
//         PPM[DIAMONDCOLOR.L] = 180000;
//         PPM[DIAMONDCOLOR.M] = 210000;

//         COLORS_['01'] = 1;
//         COLORS_['02'] = 2;
//         COLORS_['03'] = 3;
//         COLORS_['04'] = 4;
//         COLORS_['05'] = 5;
//         COLORS_['06'] = 6;
//         COLORS_['07'] = 7;
//         COLORS_['08'] = 8;
//         COLORS_['09'] = 9;
//         COLORS_['10'] = 10;
//         COLORS_['11'] = 11;
//         COLORS_['12'] = 12;
//         COLORS_['13'] = 13;
//         COLORS_['14'] = 14;
//         COLORS_['15'] = 15;
//         COLORS_['16'] = 16;

//         CLARITIES_['01'] = 1;
//         CLARITIES_['02'] = 2;
//         CLARITIES_['03'] = 3;
//         CLARITIES_['04'] = 4;
//         CLARITIES_['05'] = 5;
//         CLARITIES_['06'] = 6;
//         CLARITIES_['07'] = 7;
//         CLARITIES_['08'] = 8;
//         CLARITIES_['09'] = 9;
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

//     function getTicketCarat(uint _tokenId) external view returns(uint) {
//         return ticketInfo_[_tokenId].carat;
//     }

//     function getTicketColor(uint _tokenId) external view returns(DIAMONDCOLOR) {
//         return ticketInfo_[_tokenId].color;
//     }

//     function getTicketClarity(uint _tokenId) external view returns(CLARITY) {
//         return ticketInfo_[_tokenId].clarity;
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

//     function costToBuyTickets(
//         uint256 _clarity,
//         uint256 _carat
//     ) 
//         public
//         view 
//         returns(uint256 totalCost) 
//     {
//         require(_carat >= MIN_CARAT, 'Invalid carat');
//         if (_carat < MAX_CARAT) {
//             totalCost = priceFactor[_clarity][_carat] * _carat / 10000;
//         } else {
//             totalCost = priceFactor[_clarity][MAX_CARAT] * MAX_CARAT / 1000;
//         }
//     }

//     function costToBuyTicketsWithDiscount(uint16[] memory _clarityAndCaratForEachTicket) 
//         public
//         view 
//         returns(
//             uint256 cost, 
//             uint256 costWithDiscount
//         ) 
//     {
//         for(uint i = 0; i < _clarityAndCaratForEachTicket.length; i+=2) {
//             uint256 _clarity = _clarityAndCaratForEachTicket[i];
//             uint256 _carat = _clarityAndCaratForEachTicket[i+1];
//             cost += costToBuyTickets(_clarity, _carat);
//         }
//         costWithDiscount = cost;
//     }

//     function updatePricePerAttachMinutes(uint _pricePerAttachMinutes) external onlyAdmin {
//         pricePerAttachMinutes = _pricePerAttachMinutes;
//     }

//     function updatePriceFactor(
//         uint256[] calldata _caratArr,
//         uint256[] calldata _clarityArr
//     ) external onlyAdmin {
//         uint256 offset = 0;
//         for (uint i = 0; i < _clarityArr.length; i++){
//             uint256 _clarity = _clarityArr[i];
//             for (uint j = 0; j < _caratArr.length; j++){
//                 priceFactor[_clarity][_caratArr[j]] = _caratArr[offset+j];
//             }
//             offset = offset + _caratArr.length - 1;
//         }
//     }
    
//     function updateNFTLockables(
//         address _nftContract, 
//         uint _tokenId,  // 0 if entire collection is elligible
//         uint256[] calldata _clarityCaratNColor,
//         bool _delete
//     ) external onlyAdmin {
//         require(_clarityCaratNColor.length % 3 == 0, 'Invalid spec array');
//         if (!_delete) {
//             for(uint i = 0; i < _clarityCaratNColor.length; i+=3) {
//                 isNFTLockable[_nftContract][_tokenId].push(Diamond({
//                     clarity: CLARITY(_clarityCaratNColor[i]),
//                     carat: _clarityCaratNColor[i+1],
//                     color: DIAMONDCOLOR(_clarityCaratNColor[i+2])
//                 }));
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
//         uint idx
//     ) public {
//         require(isNFTLockable[_collection][_tokenId].length > idx, "Not lockable");

//         IERC721(_collection).safeTransferFrom(msg.sender, address(this), _tokenId);
//         uint16[] memory _clarityAndCaratForEachTicket = new uint16[](2);
//         _clarityAndCaratForEachTicket[0] = 
//         uint16(isNFTLockable[_collection][_tokenId][idx].clarity);
//         _clarityAndCaratForEachTicket[1] = 
//         uint16(isNFTLockable[_collection][_tokenId][idx].carat);
//         uint[] memory tokenIds = _batchMint(
//             msg.sender,
//             1,
//             _clarityAndCaratForEachTicket,
//             isNFTLockable[_collection][_tokenId][idx].color,
//             ""
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

//     /**
//      * @param   _to The address being minted to
//      * @param   _numberOfTickets The number of NFT's to mint
//      * @notice  Only the lotto contract is able to mint tokens. 
//         // uint8[][] calldata _lottoNumbers
//      */
//     function batchBuy(
//         address _to,
//         uint256 _numberOfTickets,
//         uint16[] calldata _clarityAndCaratForEachTicket,
//         DIAMONDCOLOR _color,
//         string calldata _certificationID,
//         bool _freeMint
//     )
//         nonReentrant
//         external
//         returns(uint256[] memory)
//     {   
//         require(_numberOfTickets <= MaximumArraySize, "Batch mint too large");
//         require(
//             _clarityAndCaratForEachTicket.length == _numberOfTickets * 2,
//             "Invalid clarity and carat"
//         );
//         // Getting the cost and discount for the token purchase
//         (,uint256 costWithDiscount) = costToBuyTicketsWithDiscount(_clarityAndCaratForEachTicket);
//         uint256 costPerTicket = 0;
//         if (isAuth[userToIdentityCode[msg.sender]] >= AUTH_THRESHOLD && _freeMint) {
//             require(_to != address(0), "Invalid Owner");
//             require(!isMinted[_certificationID], "NFT already minted for this diamond");
//             uint _clarity = _clarityAndCaratForEachTicket[0];
//             uint _carat = _clarityAndCaratForEachTicket[1];
//             require(priceFactor[_clarity][_carat] > 0, 'Invalid clarity');
//             isMinted[_certificationID] = true;
//         } else {
//             // Transfers the required amount to this contract
//             _safeTransferFrom(
//                 token,
//                 msg.sender, 
//                 address(this), 
//                 costWithDiscount
//             );
//             _color = DIAMONDCOLOR.UNDEFINED;
//             costPerTicket = costWithDiscount / _numberOfTickets;
            
//             uint _teamFee = costWithDiscount * teamShare / 10000;        
//             pendingRound[round++] += costWithDiscount - _teamFee;
//             treasury += _teamFee;
//         }

//         // Request a random number from the generator based on a seed
//         if (getChainID() != TEST_CHAIN) {
//             randomGenerator_.randomnessIsRequestedHere(uint32(_numberOfTickets*2), msg.sender);
//         }

//         return _batchMint(
//             _to,
//             _numberOfTickets,
//             _clarityAndCaratForEachTicket,
//             _color,
//             isAuth[userToIdentityCode[msg.sender]] >= AUTH_THRESHOLD && _freeMint ? _certificationID : ""
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
//             _randNumbersLength = randomNumbers.length / 2;
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
//         string memory _certificationNumber
//     ) external returns(uint[] memory) {
//         require(extractorTypes_[msg.sender], "Only Extractors!");
       
//         return _extractResource(_resource, _to, _certificationNumber);
//     }

//     function extractResourceFromNFT(
//         address _badgeNFT,
//         uint _tokenId
//     ) external returns(uint[] memory) {
//         require(extractorTypes_[_badgeNFT], "Only Extractors!");
//         require(IBadgeNFT(_badgeNFT).getTicketOwner(_tokenId) == msg.sender, "Only Owner!");
        
//         checkIdentityProof(msg.sender, false);        
//         (address _factory,) = IBadgeNFT(_badgeNFT).getTicketAuditor(_tokenId);
//         require(_factory == superLikeGaugeFactory, "Invalid Badge");

//         (
//             string memory _rating_description, 
//             string memory _resource, 
//             int _certificationNumber
//         ) = IBadgeNFT(_badgeNFT).getTicketRating(_tokenId);
//         require(keccak256(abi.encodePacked(_rating_description)) == 
//                 keccak256(abi.encodePacked("diamond")), "Invalid rating");
//         return _extractResource(_resource, msg.sender, string(abi.encodePacked(uint(_certificationNumber))));
//     }

//     function _extractResource(
//         string memory _resource,
//         address _to,
//         string memory certificationNumber    
//     ) internal returns(uint[] memory) {
//         // (Fancy red, VS1, 30) = "01->05->30"
//         strings.slice memory rsrcSlice = _resource.toSlice();
//         strings.slice memory delim = "->".toSlice();
//         string memory color = rsrcSlice.split(delim).toString();
//         string memory clarity = rsrcSlice.split(delim).toString();
//         string memory carat = rsrcSlice.split(delim).toString();

//         DIAMONDCOLOR _color = DIAMONDCOLOR(COLORS_[color]);
//         CLARITY _clarity = CLARITY(CLARITIES_[clarity]);
//         uint256 _carat = st2num(carat);
//         uint16[] memory _clarityAndCaratForEachTicket = new uint16[](2);
//         _clarityAndCaratForEachTicket[0] = uint16(_clarity); 
//         _clarityAndCaratForEachTicket[0] = uint16(_carat); 

//         return _batchMint(
//             _to, 
//             1,
//             _clarityAndCaratForEachTicket,
//             _color,
//             certificationNumber
//         );
//     }

//     function getColor(uint256 _randomNumber) public pure returns(DIAMONDCOLOR result){
//         if (_randomNumber <= 2) {
//             result = DIAMONDCOLOR.FANCY_RED;
//         } else if (_randomNumber <= 5) {
//             result = DIAMONDCOLOR.FANCY_BLUE;
//         } else if (_randomNumber <= 10) {
//             result = DIAMONDCOLOR.FANCY_PINK;
//         } else if (_randomNumber <= 30) {
//             result = DIAMONDCOLOR.FANCY_PURPLE;
//         } else if (_randomNumber <= 60) {
//             result = DIAMONDCOLOR.FANCY_GREEN;
//         } else if (_randomNumber <= 100) {
//             result = DIAMONDCOLOR.FANCY_YELLOW;
//         } else if (_randomNumber <= 2100) {
//             result = DIAMONDCOLOR.D;
//         } else if (_randomNumber <= 5100) {
//             result = DIAMONDCOLOR.E;
//         } else if (_randomNumber <= 10000) {
//             result = DIAMONDCOLOR.F;
//         } else if (_randomNumber <= 90000) {
//             result = DIAMONDCOLOR.G;
//         } else if (_randomNumber <= 190000) {
//             result = DIAMONDCOLOR.H;
//         } else if (_randomNumber <= 310000) {
//             result = DIAMONDCOLOR.I;
//         } else if (_randomNumber <= 450000) {
//             result = DIAMONDCOLOR.J;
//         } else if (_randomNumber <= 610000) {
//             result = DIAMONDCOLOR.K;
//         } else if (_randomNumber <= 790000) {
//             result = DIAMONDCOLOR.L;
//         } else if (_randomNumber <= 1000000) {
//             result = DIAMONDCOLOR.M;
//         }
//     }
    
//     function setColor(uint _tokenId) public { 
//         if (ticketInfo_[_tokenId].color == DIAMONDCOLOR.UNDEFINED) {
//             uint _round = tokenIdToRound[_tokenId];
//             require(pendingRound[_round] > 0, "Call batchMint first");
//             DIAMONDCOLOR randomColor;
//             if (getChainID() != TEST_CHAIN) {
//                 uint[] memory randomNumbers = 
//                 randomGenerator_.viewRandomNumbers(_round, msg.sender);
//                 uint randIdx = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % (randomNumbers.length - 1);
//                 randomColor = getColor(randomNumbers[randIdx] % Range);
//             } else {
//                 randomColor = getColor(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % Range);
//             }
//             ticketInfo_[_tokenId].color = randomColor;
//         }
//     } 

//     function _batchMint(
//         address _to, 
//         uint _numberOfTickets,
//         uint16[] memory _clarityAndCaratForEachTicket,
//         DIAMONDCOLOR _color,
//         string memory _certificationID
//     ) internal 
//       returns(uint256[] memory)
//     {
//         // Storage for the amount of tokens to mint (always 1)
//         uint256[] memory amounts = new uint256[](_numberOfTickets);
//         // Storage for the token IDs
//         uint256[] memory tokenIds = new uint256[](_numberOfTickets);
//         uint256 offset;
//         for (uint8 i = 0; i < _numberOfTickets; i++) {
//             // Incrementing the tokenId counter
//             uint _date = block.timestamp;
//             allTickets_.push(ticketID);
//             tokenIds[i] = ticketID++;
//             tokenIdToRound[tokenIds[i]] = round;
//             amounts[i] = 1;
//             CLARITY _clarity = CLARITY(_clarityAndCaratForEachTicket[offset]);
//             uint256 _carat = _clarityAndCaratForEachTicket[offset + 1];
//             offset += 2;
//             // Storing the ticket information 
//             ticketInfo_[tokenIds[i]] = TicketInfo({
//                 owner: _to,
//                 lender: address(0),
//                 color: _color,
//                 ppm: PPM[_color],
//                 carat: _carat,
//                 clarity: _clarity,
//                 certificationID: _certificationID,
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
//         return tokenIds;
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

//     function withdrawRound(uint _round) external onlyAdmin {
//         _safeTransfer(
//             token,
//             msg.sender,
//             pendingRound[_round]
//         );
//         pendingRound[_round] = 0;
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



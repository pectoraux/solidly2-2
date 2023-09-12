// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;
// pragma experimental ABIEncoderV2;

// import "./Library.sol";
// import "./slice.sol";

// contract GemNFT is Auth, ERC1155Pausable, ReentrancyGuard {
//     using strings for *;
   
//     enum TYPE {
//         UNDEFINED,
//         RUBY,
//         EMERALD,
//         SAPPHIRE,
//         STAR_SAPPHIRE,
//         CAMELEON_SAPPHIRE
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

//     uint TEST_CHAIN = 31337;
//     uint256 public totalSupply_;
//     uint256 public constant MAX_PRICE = 80000000000000000; //0.08 ETH
//     mapping(uint => string) public sponsoredMessages;
//     mapping(TYPE => uint) public PPM;
//     IRandomNumberGenerator randomGenerator_;
    
//     // Storage for ticket information
//     struct TicketInfo {
//         address owner;
//         address lender;
//         uint timer;
//         TYPE type_;
//         uint ppm;
//         uint carat;
//         CLARITY clarity;
//         string certificationID;
//         uint date;
//         string sponsoredMessage;
//     }
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
//     mapping(string => bool) public isMinted;
//     mapping(uint => mapping(address => uint[])) public backings;
//     mapping(uint => mapping(uint => uint)) public isNFTLockable;
//     uint public MaximumArraySize = 50;
//     mapping(string => uint) public TYPES_;
//     mapping(string => uint) public CLARITIES_;
//     uint[] public colorsArr;
//     uint[] public typesArr;
//     uint256 public CARAT_MULTIPLIER = 1000;
//     uint256 public CLARITY_MULTIPLIER = 1000;
//     address public diamondNFT_;
//     mapping(uint => bool) public blacklist;
//     uint[4] public boosts;
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
//         address _devaddr,
//         address _superLikeGaugeFactory,
//         address _diamondNFT,
//         address _randomGenerator
//     ) 
//     ERC1155(_uri)
//     Auth(_devaddr, _superLikeGaugeFactory)
//     {
//         // Only Mine contract will be able to mint new tokens
//         token = _token;
//         diamondNFT_ = _diamondNFT;
//         randomGenerator_ = IRandomNumberGenerator(_randomGenerator);
//         PPM[TYPE.RUBY] = 4;
//         PPM[TYPE.EMERALD] = 9;
//         PPM[TYPE.SAPPHIRE] = 24;
//         PPM[TYPE.STAR_SAPPHIRE] = 15;
//         PPM[TYPE.CAMELEON_SAPPHIRE] = 6;

//         TYPES_['01'] = 1;
//         TYPES_['02'] = 2;
//         TYPES_['03'] = 3;
//         TYPES_['04'] = 4;
//         TYPES_['05'] = 5;

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

//     function getTicketOwner(uint _tokenId) external view returns(address) {
//         return ticketInfo_[_tokenId].owner;
//     }

//     function getReceiver(uint _tokenId) public view returns(address) {
//         return ticketInfo_[_tokenId].lender == address(0) ?
//         ticketInfo_[_tokenId].owner : ticketInfo_[_tokenId].lender;
//     }
    
//     function getTicketCarat(uint _tokenId) external view returns(uint) {
//         return ticketInfo_[_tokenId].carat;
//     }

//     function getTicketType(uint _tokenId) external view returns(TYPE) {
//         return ticketInfo_[_tokenId].type_;
//     }

//     function getTicketClarity(uint _tokenId) external view returns(CLARITY) {
//         return ticketInfo_[_tokenId].clarity;
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
//     function updateDiamondNFT(address _diamondNFT) external onlyAdmin {
//         diamondNFT_ = _diamondNFT;
//     }

//     function updateBlacklist(uint[] memory _tokenIds, bool[] memory _blacklists) external onlyAuth {
//         require(_tokenIds.length == _blacklists.length, "Blackist: Uneven lists");
//         for (uint i = 0; i < _tokenIds.length; i++) {
//             blacklist[_tokenIds[i]] = _blacklists[i];
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

//     function updateMULTIPLIERS(uint _caratMux, uint _clarityMux) external onlyAdmin {
//         CARAT_MULTIPLIER = _caratMux;
//         CLARITY_MULTIPLIER = _clarityMux;
//     }
    
//     function updateNFTLockables(
//         uint256[] calldata _colors,
//         uint256[] calldata _types,
//         bool _delete
//     ) external onlyAdmin {
//         require(_colors.length == 2*_types.length, 'Invalid colors array');
//         if (!_delete) {
//             for (uint i = 0; i < _types.length; i++) {
//                 isNFTLockable[_colors[i]][_colors[i+1]] = _types[i];
//                 colorsArr.push(_colors[i]);
//                 colorsArr.push(_colors[i+1]);
//                 typesArr.push(_types[i]);
//             }
//         } else {
//             for (uint i = 0; i < _types.length; i++) {
//                 if (isNFTLockable[_colors[i]][_colors[i+1]] > 0) {
//                     delete isNFTLockable[_colors[i]][_colors[i+1]];
//                 }
//             }
//         }
//         require(colorsArr.length == 2*typesArr.length, "Invalid colorsArr");
//     }

//     function updatePricePerAttachMinutes(uint _pricePerAttachMinutes) external onlyAdmin {
//         pricePerAttachMinutes = _pricePerAttachMinutes;
//     }

//     // Used by non creators to back tokens while buying them
//     function lockToken(
//         uint256[] memory _tokenIds, 
//         uint256[] memory _amounts, 
//         uint256 _carat,
//         uint256 _clarity
//     ) public returns(uint[] memory tokenIds) {
//         require(_tokenIds.length == _amounts.length, "Uneven lengths");
//         require(_tokenIds.length == 2, "2 tokens only!");
//         // transfer without changing owner so owner can still get
//         // selected randomly for rewards
//         IERC1155(diamondNFT_).safeBatchTransferFrom(
//             msg.sender,
//             address(this),
//             _tokenIds,
//             _amounts,
//             msg.data
//         );
//         uint carat1 = IDiamondNFT(diamondNFT_).getTicketCarat(_tokenIds[0]);
//         uint carat2 = IDiamondNFT(diamondNFT_).getTicketCarat(_tokenIds[1]);
//         uint carat = carat1  > carat2 ? carat2 : carat1;
//         uint clarity1 = IDiamondNFT(diamondNFT_).getTicketClarity(_tokenIds[0]);
//         uint clarity2 = IDiamondNFT(diamondNFT_).getTicketClarity(_tokenIds[1]);
//         uint clarity = clarity1 > clarity2 ? clarity2 : clarity1;
//         uint color1 = IDiamondNFT(diamondNFT_).getTicketColor(_tokenIds[0]);
//         uint color2 = IDiamondNFT(diamondNFT_).getTicketColor(_tokenIds[1]);
//         uint _type = isNFTLockable[color1][color2];
//         uint price;
//         if (_carat > carat) {
//             price += (_carat - carat) * CARAT_MULTIPLIER;
//             carat = _carat;
//         }
//         if (_clarity > clarity) {
//             price += (_clarity - clarity) * CLARITY_MULTIPLIER;
//             clarity = _clarity;
//         }
//         if (price > 0) _safeTransferFrom(token, msg.sender, address(this), price);
//         uint16[] memory _clarityAndCaratForEachTicket = new uint16[](2);
//         _clarityAndCaratForEachTicket[0] = uint16(clarity);
//         _clarityAndCaratForEachTicket[1] = uint16(carat);
//         tokenIds = _batchMint(
//             msg.sender,
//             1,
//             TYPE(_type),
//             _clarityAndCaratForEachTicket,
//             ""
//         );
//         backings[tokenIds[0]][diamondNFT_] = _tokenIds;
//     }
    
//     function unlockToken(
//         uint256 _tokenId
//     ) public {
//         require(backings[_tokenId][diamondNFT_].length > 0, "Nothing to unlock");

//         _burn(msg.sender, _tokenId, 1);
//         for (uint i = 0; i < backings[_tokenId][diamondNFT_].length; i++) {
//             IERC721(diamondNFT_).safeTransferFrom(
//                 address(this), 
//                 msg.sender, 
//                 backings[_tokenId][diamondNFT_][i]
//             );
//         }

//         delete backings[_tokenId][diamondNFT_];
//     }

//     /**
//      * @param   _to The address being minted to
//      * @param   _numberOfTickets The number of NFT's to mint
//      * @notice  Only the lotto contract is able to mint tokens. 
//         // uint8[][] calldata _lottoNumbers
//      */
//     function batchMint(
//         address _to,
//         uint256 _numberOfTickets,
//         uint16[] calldata _clarityAndCaratForEachTicket,
//         TYPE _type,
//         string calldata _certificationID
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
//         require(_to != address(0), "Invalid Owner");
//         require(!isMinted[_certificationID], "NFT already minted for this diamond");
//         isMinted[_certificationID] = true;

//         return _batchMint(
//             _to,
//             _numberOfTickets,
//             TYPE(_type),
//             _clarityAndCaratForEachTicket,
//             _certificationID
//         );
//     }

//     function updateExtractorType(
//         address _typeContract, 
//         bool _extractor
//     ) external onlyAdmin {
//         extractorTypes_[_typeContract] = _extractor;
//     }

//     function extractResource(
//         string memory _resource, 
//         address _to
//     ) external returns(uint[] memory) {
//         require(extractorTypes_[msg.sender], "Only Extractors!");
       
//         // (Fancy red, VS1, 30) = "01->05->30"
//         strings.slice memory rsrcSlice = _resource.toSlice();
//         strings.slice memory delim = "->".toSlice();
//         string memory _type = rsrcSlice.split(delim).toString();
//         string memory clarity = rsrcSlice.split(delim).toString();
//         string memory carat = rsrcSlice.split(delim).toString();

//         TYPE type_ = TYPE(TYPES_[_type]);
//         CLARITY _clarity = CLARITY(CLARITIES_[clarity]);
//         uint256 _carat = st2num(carat);
//         uint16[] memory _clarityAndCaratForEachTicket = new uint16[](2);
//         _clarityAndCaratForEachTicket[0] = uint16(_clarity); 
//         _clarityAndCaratForEachTicket[0] = uint16(_carat); 

//         return _batchMint(
//             _to, 
//             1,
//             type_,
//             _clarityAndCaratForEachTicket,
//             ""
//         );
//     }

//     function _batchMint(
//         address _to, 
//         uint _numberOfTickets,
//         TYPE _type,
//         uint16[] memory _clarityAndCaratForEachTicket,
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
//             amounts[i] = 1;
//             CLARITY _clarity = CLARITY(_clarityAndCaratForEachTicket[offset]);
//             uint256 _carat = _clarityAndCaratForEachTicket[offset + 1];
//             offset += 2;
//             // Storing the ticket information 
//             ticketInfo_[tokenIds[i]] = TicketInfo({
//                 owner: _to,
//                 lender: address(0),
//                 type_: _type,
//                 ppm: PPM[_type],
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



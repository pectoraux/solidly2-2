// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;
// pragma experimental ABIEncoderV2;

// import "./Percentile.sol";

// contract ValentineNFT is Auth, ERC1155Pausable, Percentile, ReentrancyGuard {
//     using EnumerableSet for EnumerableSet.AddressSet;

//     EnumerableSet.AddressSet private _maleToMaleAddressSet;
//     EnumerableSet.AddressSet private _maleToFemaleAddressSet;
//     EnumerableSet.AddressSet private _maleToFemaleTransAddressSet;
//     EnumerableSet.AddressSet private _maleToMaleTransAddressSet;

//     EnumerableSet.AddressSet private _femaleToMaleAddressSet;
//     EnumerableSet.AddressSet private _femaleToFemaleAddressSet;
//     EnumerableSet.AddressSet private _femaleToFemaleTransAddressSet;
//     EnumerableSet.AddressSet private _femaleToMaleTransAddressSet;

//     EnumerableSet.AddressSet private _maleTransToMaleAddressSet;
//     EnumerableSet.AddressSet private _maleTransToFemaleAddressSet;
//     EnumerableSet.AddressSet private _maleTransToFemaleTransAddressSet;
//     EnumerableSet.AddressSet private _maleTransToMaleTransAddressSet;

//     EnumerableSet.AddressSet private _femaleTransToMaleAddressSet;
//     EnumerableSet.AddressSet private _femaleTransToFemaleAddressSet;
//     EnumerableSet.AddressSet private _femaleTransToFemaleTransAddressSet;
//     EnumerableSet.AddressSet private _femaleTransToMaleTransAddressSet;


//     // Storage for ticket information
//     struct TicketInfo {
//         address owner;
//         address lender;
//         address valentine;
//         uint valentineId;
//         uint percentile;
//         uint valentinePercentile;
//         string valentineMessage;
//         bool active;
//         uint date;
//         uint timer;
//         string sponsoredMessage;
//     }
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
//     uint public teamShare;
//     uint public MaximumArraySize = 50;
//     uint public MinimumLengthToPick = 1;
//     mapping(uint => bool) public blacklist;
//     enum Gender {
//         Undefined,
//         Male,
//         Female,
//         MaleTrans,
//         FemaleTrans
//     }
//     enum Series {
//         Undefined,
//         S,
//         X
//     }
//     struct ValentineInfo {
//         uint percentile;
//         string contact;
//     }
//     mapping(address => uint) public percentiles;
//     uint public linkFee = 0;
//     Series public immutable series;
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
//         uint _series,
//         address _devaddr,
//         address _token,
//         string memory _uri,
//         address _superLikeGaugeFactory,
//         address _randomGenerator
//     ) 
//     ERC1155(_uri)
//     Auth(_devaddr, _superLikeGaugeFactory)
//     {
//         series = Series(_series);
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

//     function updateMaxArraySize(uint _maxArrSize, uint _minLenToPick) external onlyAdmin {
//         MaximumArraySize = _maxArrSize;
//         MinimumLengthToPick = _minLenToPick;
//     }

//     function updateLinkFee(uint _linkFee) external onlyAdmin {
//         linkFee = _linkFee;
//     }

//     function getMaleSetLength() external view returns(uint,uint) {
//         return (_maleToFemaleAddressSet.length(), _femaleToMaleAddressSet.length());
//     }

//     function mint(
//         uint256 __percentile,
//         uint256 _meanPaid,
//         Gender _ownerGender,
//         Gender _valentineGender
//     )
//         external
//         nonReentrant
//     {
//         if (__percentile > 0 && _meanPaid == 0) {
//             _meanPaid = getPaid4Percentile(__percentile);
//         }
//         _safeTransferFrom(
//             token,
//             msg.sender, 
//             address(this), 
//             _meanPaid + linkFee
//         );
//         uint _teamFee = _meanPaid * teamShare / 10000;
//         pendingRound[lastClaimedRound] += _meanPaid - _teamFee;
//         treasury += _teamFee + linkFee;
//         int256 _zscore = computePercentile(_meanPaid);
//         percentiles[msg.sender] = getPercentile(_zscore);

//         if (_ownerGender == Gender.Male && _valentineGender == Gender.Male) {
//             _maleToMaleAddressSet.add(msg.sender);
//             (address _user1, address _user2) = pickNSend(_maleToMaleAddressSet, _maleToMaleAddressSet);
//             if(_user1 != address(0) && _user2 != address(0)) {
//                 _maleToMaleAddressSet.remove(_user1);
//                 _maleToMaleAddressSet.remove(_user2);
//             }
//         } else if (_ownerGender == Gender.Male && _valentineGender == Gender.Female) {
//             _maleToFemaleAddressSet.add(msg.sender);
//             (address _user1, address _user2) = pickNSend(_maleToFemaleAddressSet, _femaleToMaleAddressSet);
//             if(_user1 != address(0) && _user2 != address(0)) {
//                 _maleToFemaleAddressSet.remove(_user1);
//                 _femaleToMaleAddressSet.remove(_user2);
//             }
//         } else if (_ownerGender == Gender.Male && _valentineGender == Gender.FemaleTrans) {
//             _maleToFemaleTransAddressSet.add(msg.sender);
//             (address _user1, address _user2) = pickNSend(_maleToFemaleTransAddressSet, _femaleTransToMaleAddressSet);
//             if(_user1 != address(0) && _user2 != address(0)) {
//                 _maleToFemaleTransAddressSet.remove(_user1);
//                 _femaleTransToMaleAddressSet.remove(_user2);
//             }
//         } else if (_ownerGender == Gender.Male && _valentineGender == Gender.MaleTrans) {
//             _maleToMaleTransAddressSet.add(msg.sender);
//             (address _user1, address _user2) = pickNSend(_maleToMaleTransAddressSet, _maleTransToMaleAddressSet);
//             if(_user1 != address(0) && _user2 != address(0)) {
//                 _maleToMaleTransAddressSet.remove(_user1);
//                 _maleTransToMaleAddressSet.remove(_user2);
//             }
//         } else if (_ownerGender == Gender.Female && _valentineGender == Gender.Male) {
//             _femaleToMaleAddressSet.add(msg.sender);
//             (address _user1, address _user2) = pickNSend(_femaleToMaleAddressSet, _maleToFemaleAddressSet);
//             if(_user1 != address(0) && _user2 != address(0)) {
//                 _femaleToMaleAddressSet.remove(_user1);
//                 _maleToFemaleAddressSet.remove(_user2);
//             }
//         } else if (_ownerGender == Gender.Female && _valentineGender == Gender.Female) {
//             _femaleToFemaleAddressSet.add(msg.sender);
//             (address _user1, address _user2) = pickNSend(_femaleToFemaleAddressSet, _femaleToFemaleAddressSet);
//             if(_user1 != address(0) && _user2 != address(0)) {
//                 _femaleToFemaleAddressSet.remove(_user1);
//                 _femaleToFemaleAddressSet.remove(_user2);
//             }
//         } else if (_ownerGender == Gender.Female && _valentineGender == Gender.FemaleTrans) {
//             _femaleToFemaleTransAddressSet.add(msg.sender);
//             (address _user1, address _user2) = pickNSend(_femaleToFemaleTransAddressSet, _femaleTransToFemaleAddressSet);
//             if(_user1 != address(0) && _user2 != address(0)) {
//                 _femaleToFemaleTransAddressSet.remove(_user1);
//                 _femaleTransToFemaleAddressSet.remove(_user2);
//             }
//         } else if (_ownerGender == Gender.Female && _valentineGender == Gender.MaleTrans) {
//             _femaleToMaleTransAddressSet.add(msg.sender);
//             (address _user1, address _user2) = pickNSend(_femaleToMaleTransAddressSet, _maleTransToFemaleAddressSet);
//             if(_user1 != address(0) && _user2 != address(0)) {
//                 _femaleToMaleTransAddressSet.remove(_user1);
//                 _maleTransToFemaleAddressSet.remove(_user2);
//             }
//         } else if (_ownerGender == Gender.MaleTrans && _valentineGender == Gender.Male) {
//             _maleTransToMaleAddressSet.add(msg.sender);
//             (address _user1, address _user2) = pickNSend(_maleTransToMaleAddressSet, _maleToMaleTransAddressSet);
//             if(_user1 != address(0) && _user2 != address(0)) {
//                 _maleTransToMaleAddressSet.remove(_user1);
//                 _maleToMaleTransAddressSet.remove(_user2);
//             }
//         } else if (_ownerGender == Gender.MaleTrans && _valentineGender == Gender.Female) {
//             _maleTransToFemaleAddressSet.add(msg.sender);
//             (address _user1, address _user2) = pickNSend(_maleTransToFemaleAddressSet, _femaleToMaleTransAddressSet);
//             if(_user1 != address(0) && _user2 != address(0)) {
//                 _maleTransToFemaleAddressSet.remove(_user1);
//                 _femaleToMaleTransAddressSet.remove(_user2);
//             }
//         } else if (_ownerGender == Gender.MaleTrans && _valentineGender == Gender.FemaleTrans) {
//             _maleTransToFemaleTransAddressSet.add(msg.sender);
//             (address _user1, address _user2) = pickNSend(_maleTransToFemaleTransAddressSet, _femaleTransToMaleTransAddressSet);
//             if(_user1 != address(0) && _user2 != address(0)) {
//                 _maleTransToFemaleTransAddressSet.remove(_user1);
//                 _femaleTransToMaleTransAddressSet.remove(_user2);
//             }
//         } else if (_ownerGender == Gender.MaleTrans && _valentineGender == Gender.MaleTrans) {
//             _maleToMaleAddressSet.add(msg.sender);
//             (address _user1, address _user2) = pickNSend(_maleToMaleAddressSet, _maleToMaleAddressSet);
//             if(_user1 != address(0) && _user2 != address(0)) {
//                 _maleToMaleAddressSet.remove(_user1);
//                 _maleToMaleAddressSet.remove(_user2);
//             }
//         } else if (_ownerGender == Gender.FemaleTrans && _valentineGender == Gender.Male) {
//             _femaleTransToMaleAddressSet.add(msg.sender);
//             (address _user1, address _user2) = pickNSend(_femaleTransToMaleAddressSet, _maleToFemaleTransAddressSet);
//             if(_user1 != address(0) && _user2 != address(0)) {
//                 _femaleTransToMaleAddressSet.remove(_user1);
//                 _maleToFemaleTransAddressSet.remove(_user2);
//             }
//         } else if (_ownerGender == Gender.FemaleTrans && _valentineGender == Gender.Female) {
//             _femaleTransToFemaleAddressSet.add(msg.sender);
//             (address _user1, address _user2) = pickNSend(_femaleTransToFemaleAddressSet, _femaleToFemaleTransAddressSet);
//             if(_user1 != address(0) && _user2 != address(0)) {
//                 _femaleTransToFemaleAddressSet.remove(_user1);
//                 _femaleToFemaleTransAddressSet.remove(_user2);
//             }
//         } else if (_ownerGender == Gender.FemaleTrans && _valentineGender == Gender.FemaleTrans) {
//             _femaleTransToFemaleTransAddressSet.add(msg.sender);
//             (address _user1, address _user2) = pickNSend(_femaleTransToFemaleTransAddressSet, _femaleTransToFemaleTransAddressSet);
//             if(_user1 != address(0) && _user2 != address(0)) {
//                 _femaleTransToFemaleTransAddressSet.remove(_user1);
//                 _femaleTransToFemaleTransAddressSet.remove(_user2);
//             }
//         } else if (_ownerGender == Gender.FemaleTrans && _valentineGender == Gender.MaleTrans) {
//             _femaleTransToMaleTransAddressSet.add(msg.sender);
//             (address _user1, address _user2) = pickNSend(_femaleTransToMaleTransAddressSet, _maleTransToFemaleTransAddressSet);
//             if(_user1 != address(0) && _user2 != address(0)) {
//                 _femaleTransToMaleTransAddressSet.remove(_user1);
//                 _maleTransToFemaleTransAddressSet.remove(_user2);
//             }
//         }

//         // Request a random number from the generator based on a seed
//         if (getChainID() != TEST_CHAIN) {
//             randomGenerator_.randomnessIsRequestedHere(2, msg.sender);
//         }
//         round++;
//     }

//     function pickNSend(
//         EnumerableSet.AddressSet storage _set1, 
//         EnumerableSet.AddressSet storage _set2
//     ) internal returns(address _picked1, address _picked2) {
//         if (_set1.length() >= MinimumLengthToPick && _set2.length() > 0) {
//             uint _randIdx1;
//             uint _randIdx2;
//             if (getChainID() != TEST_CHAIN) {
//                 uint[] memory randomNumbers = 
//                 randomGenerator_.viewRandomNumbers(round, msg.sender);
//                 _randIdx1 = randomNumbers[0] % _set1.length();
//                 _randIdx2 = randomNumbers[1] % _set2.length();
//             } else {
//                 uint _randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
//                 uint _randomNumber2 = uint256(keccak256(abi.encodePacked(block.timestamp+10000, msg.sender)));
//                 _randIdx1 = _randomNumber % _set1.length();
//                 _randIdx2 = _randomNumber2 % _set2.length();
//             }
//             if (_set1.at(_randIdx1) != address(0) && 
//                 _set2.at(_randIdx2) != address(0) && 
//                 _set1.at(_randIdx1) != _set2.at(_randIdx2)) {
//                 _picked1 = _set1.at(_randIdx1);
//                 _picked2 = _set2.at(_randIdx2);
//                 _mintTo(_picked1, _picked2, ticketID + 1);
//                 _mintTo(_picked2, _picked1, ticketID - 1);
//             }
//         }
//     }

//     function _mintTo(address _to, address _valentine, uint _valentineId) internal {
//         // Storing the ticket information 
//         ticketInfo_[ticketID] = TicketInfo({
//             owner: _to,
//             lender: address(0),
//             valentine: _valentine,
//             valentineId: _valentineId,
//             percentile: percentiles[_to],
//             valentinePercentile: percentiles[_valentine],
//             valentineMessage: "",
//             active: true,
//             date: block.timestamp,
//             timer: 0,
//             sponsoredMessage: ""
//         });
//         totalSupply_ += 1;
//         userTickets_[_to].push(ticketID);
//         allTickets_.push(ticketID);

//         _mint(_to, ticketID++, 1, msg.data);
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

//     function messageValentine(uint _tokenId, string memory _message) external isNotContract {
//         require(getReceiver(_tokenId) == msg.sender, "Invalid token ID");
        
//         uint _valentineId = ticketInfo_[_tokenId].valentineId;
//         ticketInfo_[_valentineId].valentineMessage = _message;
//     }

//     function transferToValentine(address _token, uint _tokenId, uint _amount) external isNotContract {
//         require(_token != address(0), "Invalid token");
//         _safeTransferFrom(
//             _token, 
//             msg.sender, 
//             ticketInfo_[_tokenId].valentine,
//             _amount
//         );
//     }

//     function claimPendingBalance(uint _tokenId) external isNotContract {
//         require(_tokenId <= ticketID, "Invalid token ID");
//         if (getChainID() != TEST_CHAIN) {
//             uint[] memory randomNumbers = 
//             randomGenerator_.viewRandomNumbers(round, msg.sender);
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
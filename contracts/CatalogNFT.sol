// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;
// pragma experimental ABIEncoderV2;

// import "./Percentile.sol";

// contract CatalogNFT is Auth, ERC1155Pausable, Percentile, ReentrancyGuard {
//     using EnumerableSet for EnumerableSet.AddressSet;
//     using EnumerableSet for EnumerableSet.UintSet;

//     // State variables 
//     uint256 public constant MAX_PRICE = 80000000000000000; //0.08 ETH
//     mapping(uint => string) public sponsoredMessages;
//     uint public minSuperChat = 1;
//     uint public maxMessage = 100;
//     uint public treasury;
//     uint public loanFund;
//     uint public sponsorFund;
//     uint public teamShare = 100;
//     uint public loanShare = 4900;
//     mapping(bytes32 => uint) public elligibleForLoan;
//     uint public MaxLoans = 2; // 2 for allowing 1 loan
//     string public  loanValueName;
//     uint public loanMinIDBadgeColor;
//     EnumerableSet.UintSet internal borrowers;
//     bytes32 public loanRequiredIndentity;
//     EnumerableSet.AddressSet private loanTrustWorthyAuditors;
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
//     // edition => edition's content
//     mapping(uint => string[]) internal talentCatalog_;
//     // event number => event NFT's contract
//     mapping(uint => address) internal talentEvents_;
//     // token ID => edition => edition's content id
//     mapping(uint => mapping(uint => uint)) internal userCatalog_;
//     // token ID => event number => event NFT's contract
//     mapping(uint => mapping(uint => address)) internal userEvents_;
//     // event number => ticket price
//     mapping(uint => uint) public talentEventPrices;
//     // edition => price
//     mapping(uint => uint) public talentCatalogPrices;
//     uint public currentEventID = 1;
//     uint public currentCatalogID = 1;
//     TicketSponsor[] private ticketSponsor;
//     struct Loan {
//         uint amount;
//         uint start;
//         uint deadline;
//         uint principal;
//     }
//     uint public totalBorrowers;
//     uint public totalPrincipal;
//     uint public sodfPrincipal;
//     uint public totalDuration;
//     uint public sodfDuration;
//     int public interestRate;
//     uint public maxLoandDuration = 31 days;
//     mapping(uint => Loan) internal loans;
//     uint public price_;
//     uint public Q1 = 1;
//     uint public Q2 = 25;
//     uint public Q3 = 50;
//     uint public Q4 = 75;
//     uint public LQ1 = 1;
//     uint public LQ2 = 25;
//     uint public LQ3 = 50;
//     uint public LQ4 = 75;
//     mapping(address => bool) public blacklist;
//     uint public MaximumArraySize = 50;
//     uint[4] public boosts;
//     uint[4] public Lboosts;
//     address public immutable factory;
//     uint public pricePerAttachMinutes = 1;
//     uint internal constant minute = 3600; // allows minting once per week (reset every Thursday 00:00 UTC)
//     uint public active_period;
//     uint public lastClaimedRound = 1;
//     uint public linkFee = 1;
//     uint public span = 10000;
//     uint public Range = 1000000;
//     uint TEST_CHAIN = 31337;
//     address public token;
//     uint public claimPeriod = 3600 * 60;
//     IRandomNumberGenerator randomGenerator_;
//     uint256 public totalSupply_;
//     EnumerableSet.UintSet private channelMessages;
//     mapping(bytes32 => uint) public dues;
//     // Storage for ticket information
//     struct TicketInfo {
//         address owner;
//         address lender;
//         uint timer;
//         uint date;
//         uint subCount;
//         string email;
//         string superChat;
//         string superChatResponse;
//         uint activePeriod;
//         uint loanPercentile;
//     }

//     // Token ID => Token information 
//     mapping(uint256 => TicketInfo) public ticketInfo_;
//     uint256 public ticketID = 1;
    
//     // User address =>  Ticket IDs
//     mapping(address => uint256[]) public userTickets_;
//     mapping(uint => bool) public attached;
    
//     //-------------------------------------------------------------------------
//     // EVENTS
//     //-------------------------------------------------------------------------

//     event InfoMint(
//         address indexed receiving, 
//         uint256 tokenId, 
//         uint256 time
//     );
    
//     event Message(address indexed from, uint time);
//     event SuperChat(address indexed from, uint tokenId, uint time);

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
//         string memory _uri, 
//         address _factory,
//         address _devaddr, 
//         address _token, 
//         address _randomGenerator,
//         address _superLikeGaugeFactory
//     ) 
//     ERC1155(_uri)
//     Auth(_devaddr, _superLikeGaugeFactory)
//     {
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

//     function getChainID() public view returns (uint256) {
//         uint256 id;
//         assembly {
//             id := chainid()
//         }
//         return id;
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

//     function getSubSpecs(uint _tokenId) external view returns(uint, string memory) {
//         return (
//             ticketInfo_[_tokenId].subCount,
//             ticketInfo_[_tokenId].email
//         );
//     }

//     function getReceiver(uint _tokenId) public view returns(address) {
//         return ticketInfo_[_tokenId].lender == address(0) ?
//         ticketInfo_[_tokenId].owner : ticketInfo_[_tokenId].lender;
//     }

//     function getSuperChats() external view returns(uint[] memory tokenIds, string[] memory superChats) {
//         tokenIds = new uint[](channelMessages.length());
//         superChats = new string[](channelMessages.length());
//         for (uint i = 0; i < channelMessages.length(); i++) {
//             tokenIds[i] = channelMessages.at(i);
//             superChats[i] = ticketInfo_[channelMessages.at(i)].superChat;
//         }
//     }

//     function getMaxBorrow(uint _tokenId) public view returns(uint result) {
//         require(ticketInfo_[_tokenId].owner != address(0), "Does not exist");
//         if (elligibleForLoan[userToIdentityCode[msg.sender]] >= MaxLoans) {
//             return 0;
//         }
//         if (ticketInfo_[_tokenId].loanPercentile >= LQ4) {
//             result = Lboosts[3];
//         } else if (ticketInfo_[_tokenId].loanPercentile >= LQ3) {
//             result = Lboosts[2];
//         } else if (ticketInfo_[_tokenId].loanPercentile >= LQ2) {
//             result = Lboosts[1];
//         } else if (ticketInfo_[_tokenId].loanPercentile >= LQ1) {
//             result = Lboosts[0];
//         }
//     }

//     function getTalentCatalog(uint _edition) external view returns(string[] memory videos) {
//         return talentCatalog_[_edition];
//     }

//     function getTicketSponsor() external view returns(TicketSponsor[] memory) {
//         return ticketSponsor;
//     }

//     function getAllLoanTrustWorthyAuditors() external view returns(address[] memory _auditors) {
//         _auditors = new address[](loanTrustWorthyAuditors.length());
//         for (uint i = 0; i < loanTrustWorthyAuditors.length(); i++) {
//             _auditors[i] = loanTrustWorthyAuditors.at(i);
//         }
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

//     function updateLQs(uint q1, uint q2, uint q3, uint q4) external onlyAdmin {
//         require(q1 < q2, "Invalid LQ1");
//         require(q2 < q3, "Invalid LQ2");
//         require(q3 < q4, "Invalid LQ3");
//         LQ1 = q1;
//         LQ2 = q2;
//         LQ3 = q3;
//         LQ4 = q4;
//     }

//     function updateLoanParams(
//         uint _maxLoans,
//         int _interestRate, 
//         uint _maxLoandDuration
//     ) external onlyAdmin {
//         MaxLoans = _maxLoans;
//         interestRate = _interestRate;
//         maxLoandDuration = _maxLoandDuration;
//     }

//     function updateLoanValueNameNCode(
//         uint _loanMinIDBadgeColor,
//         string memory _loanValueName, //agebt, age, agelt... 
//         string memory _value //18
//     ) external onlyAdmin {
//         if (keccak256(abi.encodePacked(_value)) != keccak256(abi.encodePacked(""))) {
//             loanRequiredIndentity == keccak256(abi.encodePacked(_value));
//         }
//         loanValueName = _loanValueName;   
//         loanMinIDBadgeColor = _loanMinIDBadgeColor;
//     }

//     function updateLoanTrustWorthyAuditors(address[] memory _gauges, bool _add) external onlyAdmin {
//         for (uint i = 0; i < _gauges.length; i++) {
//             if (_add) {
//                 loanTrustWorthyAuditors.add(_gauges[i]);
//             } else {
//                 loanTrustWorthyAuditors.remove(_gauges[i]);
//             }
//         }
//     }

//     function updateLoanElligibility(
//         address _badgeNFT,
//         uint _tokenId
//     ) external {
//         if (keccak256(abi.encodePacked(loanValueName)) != keccak256(abi.encodePacked(""))) {
//             (
//                 string memory ssid,
//                 string memory value, 
//                 address _gauge 
//             ) = ISuperLikeGaugeFactory(superLikeGaugeFactory).getIdentityValue(msg.sender, valueName);
//             require(ISuperLikeGauge(_gauge).badgeColor() >= loanMinIDBadgeColor, "ID Gauge inelligible");
//             require(keccak256(abi.encodePacked(value)) == loanRequiredIndentity || 
//             loanRequiredIndentity == 0, "Invalid comparator");
//             require(loanTrustWorthyAuditors.length() == 0 || loanTrustWorthyAuditors.contains(_gauge),
//             "Only identity proofs from trustworthy auditors"
//             );
//             bytes32 identityCode = keccak256(abi.encodePacked(ssid));
//             require(!blackListedIdentities[identityCode], "You identiyCode is blacklisted");
//             if (identityProofs[identityCode] == address(0)) {
//                 // only register the first time
//                 identityProofs[identityCode] = msg.sender;
//             }
//             userToIdentityCode[msg.sender] = identityCode;
//             require(
//                 ISuperLikeGaugeFactory(superLikeGaugeFactory).isElligibleForLoan(identityCode),
//                 "Ineligible for loan"
//             );
//             elligibleForLoan[identityCode] += 1;
//         }
//     }

//     function updatePricePerAttachMinutes(
//         uint _pricePerAttachMinutes, 
//         uint _teamShare,
//         uint _loanShare
//     ) external onlyAdmin {
//         loanShare = _loanShare;
//         teamShare = _teamShare;
//         pricePerAttachMinutes = _pricePerAttachMinutes;
//     }

//     function updateMaxMinSuperChat(uint _newMax, uint _newMin) external onlyAdmin {
//         maxMessage = _newMax;
//         minSuperChat = _newMin;
//     }

//     function updateCatalog(uint _edition, string memory _videoCid) external onlyAdmin {
//         talentCatalog_[_edition].push(_videoCid);
//     }

//     function updateLinkFeeNSpan(uint _fee, uint _span, uint _range) external onlyAdmin {
//         linkFee = _fee;
//         span = _span;
//         Range = _range;
//     }

//     function updateClaimPeriod(uint _claimPeriod) external onlyAdmin {
//         claimPeriod = _claimPeriod;
//     }

//     function withdrawTreasury(address _token) external onlyAdmin {
//         bool _subToken = _token == address(0) || _token == token;
//         _token =  _subToken ? token : _token;
//         uint _amount = _subToken ? treasury : erc20(_token).balanceOf(address(this));
//         if (_subToken) treasury = 0;
//         _safeTransfer(
//             _token,
//             msg.sender,
//             _amount
//         );
//     }

//     function messageAll(uint _numMinutes, bool _video, string memory _msg) external {
//         batchMessage(_numMinutes, _video, _msg);
//     }

//     function batchMessage(
//         uint _numMinutes,
//         bool _video,
//         string memory _message
//     ) public nonReentrant {
//         checkIdentityProof(msg.sender, false);
//         require(active_period < block.timestamp, "Current message not yet expired");
//         if (msg.sender != devaddr_) {
//             _safeTransferFrom(
//                 token,
//                 address(msg.sender), 
//                 address(this),
//                 _numMinutes * pricePerAttachMinutes
//             );
//             uint _teamFee = _numMinutes * pricePerAttachMinutes * teamShare / 10000; 
//             uint _loanFee = _numMinutes * pricePerAttachMinutes * loanShare / 10000; 
//             treasury += _teamFee;
//             loanFund += _loanFee;
//             sponsorFund += _numMinutes * pricePerAttachMinutes - _teamFee - _loanFee;
//         }
//         active_period = (block.timestamp + (_numMinutes*minute)) / minute * minute;
//         ticketSponsor.push(TicketSponsor({
//             stype: _video ? SponsorshipType.video : SponsorshipType.text,
//             videoCid: _video ? _message : "",
//             message: _video ? "" : _message,
//             deadline: active_period
//         }));

//         emit Message(msg.sender, block.timestamp);
//     }

//     function updateBoosts(uint[4] memory _boosts) external onlyAdmin {
//         require(_boosts.length == 4, "Invalid number of boosts");
//         boosts = _boosts;
//     }

//     function updateLBoosts(uint[4] memory _boosts) external onlyAdmin {
//         require(_boosts.length == 4, "Invalid number of Lboosts");
//         Lboosts = _boosts;
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
//         if (_token == address(this)) 
//         require(!borrowers.contains(_tokenId), "Collaterals are not withdrawable!");
//         IERC721(_token).safeTransferFrom(address(this), address(msg.sender), _tokenId);
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

//     function mintNFTForLoan(
//         uint _subCount,
//         string memory _email
//     ) external {
//         require(elligibleForLoan[userToIdentityCode[msg.sender]] < MaxLoans, "Not elligible for loans");
//         _mintTo(msg.sender, _subCount, _email);
//     }

//     function borrow(uint _tokenId, uint _amount, uint _duration) external nonReentrant {
//         require(ticketInfo_[_tokenId].owner == msg.sender, "Only owner!");
//         require(elligibleForLoan[userToIdentityCode[msg.sender]] < MaxLoans, "Not elligible for loans");
//         require(loanFund >= _amount && _amount > 0, "Not enough fund to lend out");
//         require(getMaxBorrow(_tokenId) >= _amount, "Amount too high!");
//         require(_duration <= maxLoandDuration, "Exceeds max duration");
        
//         if (interestRate > -10000) {
//             safeTransferFrom(msg.sender, address(this), _tokenId, 1, msg.data);
//             attach(_tokenId, 0, msg.sender);
//         }
//         loanFund -= _amount;
//         _safeTransfer(token, msg.sender, _amount);
//         loans[_tokenId] = Loan({
//             amount: _amount * (10000 + uint(interestRate)) / 10000,
//             start: block.timestamp,
//             deadline: block.timestamp + _duration,
//             principal: _amount
//         });
//         borrowers.add(_tokenId);
//     }

//     function liquidateLoans(uint[] memory _tokenIds) external onlyAdmin {
//         for (uint i = 0; i < _tokenIds.length; i++) {
//             if (loans[_tokenIds[i]].deadline < block.timestamp) {
//                 dues[userToIdentityCode[ticketInfo_[_tokenIds[i]].owner]] += 
//                 loans[_tokenIds[i]].principal;
//                 delete loans[_tokenIds[i]];
//                 borrowers.remove(_tokenIds[i]);
//                 elligibleForLoan[userToIdentityCode[ticketInfo_[_tokenIds[i]].owner]] -= 1;
//             }
//         }
//     }   

//     function setElligibilityForLoan(uint[] memory _tokenIds, bool _elligible) external onlyAdmin {
//         bytes32[] memory _idCodes = new bytes32[](_tokenIds.length);
//         for (uint i = 0; i < _tokenIds.length; i++) {
//             require(elligibleForLoan[userToIdentityCode[ticketInfo_[_tokenIds[i]].owner]] == 0);
//             _idCodes[i] = userToIdentityCode[ticketInfo_[_tokenIds[i]].owner];
//         }
//         ICatalogNFTFactory(factory).setElligible(superLikeGaugeFactory, _idCodes, _elligible);
//     }
    
//     function resetElligibilityForLoan(uint[] memory _tokenIds) external nonReentrant {
//         uint _total;
//         for (uint i = 0; i < _tokenIds.length; i++) {
//             require(userToIdentityCode[ticketInfo_[_tokenIds[i]].owner] == 
//             userToIdentityCode[msg.sender], "Only borrower!");
//             _total += dues[userToIdentityCode[ticketInfo_[_tokenIds[i]].owner]];
//             dues[userToIdentityCode[ticketInfo_[_tokenIds[i]].owner]] = 0;
//         }
//         _safeTransferFrom(token, msg.sender, address(this), _total);
//         loanFund += _total;
//         bytes32[] memory _idCodes = new bytes32[](1);
//         _idCodes[0] = userToIdentityCode[msg.sender];
//         ICatalogNFTFactory(factory).setElligible(superLikeGaugeFactory, _idCodes, true);
//     }

//     function reimburse(uint _tokenId, uint _amount) external nonReentrant {
//         require(getReceiver(_tokenId) == msg.sender, "Only receiver!");
//         require(borrowers.contains(_tokenId), "Loan non existant!");

//         _amount = loans[_tokenId].amount >= _amount ? _amount : loans[_tokenId].amount;
//         loans[_tokenId].amount -= _amount;
//         _safeTransferFrom(token, msg.sender, address(this), _amount);
//         loanFund += _amount;
//         if (loans[_tokenId].amount == 0) {
//             detach(_tokenId);
//             (uint _percentile1, uint _sodf1) = computePercentileFromData(
//                 false,
//                 loans[_tokenId].principal,
//                 totalBorrowers,
//                 totalPrincipal,
//                 sodfPrincipal
//             );
//             uint _duration = block.timestamp - loans[_tokenId].start;
//             (uint _percentile2, uint _sodf2) = computePercentileFromData(
//                 false,
//                 _duration,
//                 totalBorrowers,
//                 totalDuration,
//                 sodfDuration
//             );
//             uint _percentile = (_percentile1 + _percentile2) / 2;
            
//             if (ticketInfo_[_tokenId].loanPercentile == 0) {
//                 ticketInfo_[_tokenId].loanPercentile = _percentile;
//             } else {
//                 ticketInfo_[_tokenId].loanPercentile = 
//                 (ticketInfo_[_tokenId].loanPercentile + _percentile) / 2;
//             }
//             if (loans[_tokenId].deadline < block.timestamp &&
//                 ticketInfo_[_tokenId].loanPercentile != 0) {
//                 (uint _p,) = computePercentileFromData(
//                     false,
//                     block.timestamp - loans[_tokenId].deadline,
//                     totalBorrowers,
//                     totalDuration,
//                     sodfDuration
//                 );
//                 ticketInfo_[_tokenId].loanPercentile = 
//                 ticketInfo_[_tokenId].loanPercentile > _p ? 
//                 ticketInfo_[_tokenId].loanPercentile - _p : 0;
//             }
//             totalBorrowers += 1;
//             sodfPrincipal = _sodf1;
//             totalPrincipal += loans[_tokenId].principal;
//             sodfDuration = _sodf2;
//             totalDuration += _duration;
//             safeTransferFrom(address(this), msg.sender, _tokenId, 1, msg.data);
//             borrowers.remove(_tokenId);
//         }
//     }

//     /**
//      * @param   _to The address being minted to
//      * @notice  Only the lotto contract is able to mint tokens. 
//         // uint8[][] calldata _lottoNumbers
//      */
//     function mint(
//         address _to,
//         uint _subCount,
//         string memory _email
//     )
//         external
//         returns(uint256 tokenId)
//     {   
//         require(msg.sender == factory, "Only factory");
//         _mintTo(_to, _subCount, _email);
//     }

//     function _mintTo(
//         address _to,
//         uint _subCount,
//         string memory _email
//     )
//         internal
//         returns(uint256 tokenId)
//     {   
    
//         ticketInfo_[ticketID] = TicketInfo({
//             owner: _to,
//             lender: address(0),
//             date: block.timestamp,
//             timer: 0,
//             subCount: _subCount,
//             email: _email,
//             superChat: "",
//             superChatResponse: "",
//             activePeriod: 0,
//             loanPercentile: 0
//         });
        
//         totalSupply_ += 1;
//         userTickets_[_to].push(ticketID);
//         // Minting the batch of tokens
//         _mint(
//             _to,
//             ticketID++,
//             1,
//             msg.data
//         );

//         // Emitting relevant info
//         emit InfoMint(
//             _to, 
//             ticketID-1, 
//             block.timestamp
//         ); 
//         return ticketID;
//     }

//     function superChat(uint _tokenId, uint _amount, string memory _message) public nonReentrant {
//         require(getReceiver(_tokenId) == msg.sender || devaddr_ == msg.sender, 
//         "Invalid token ID");
//         if (getReceiver(_tokenId) == msg.sender) {
//             require(channelMessages.length() <= maxMessage, 
//             "No more place for superchats!");
//             require(_amount >= minSuperChat, "Not enough for superChat");
//             _safeTransferFrom(
//                 token,
//                 address(msg.sender), 
//                 devaddr_,
//                 _amount
//             );
//             uint _teamFee = _amount * teamShare / 10000;
//             uint _loanFee = _amount * loanShare / 10000; 
//             _safeTransfer(
//                 token, 
//                 devaddr_, 
//                 _amount - _teamFee
//             );
//             treasury += _teamFee;
//             loanFund += _loanFee;
//             channelMessages.add(_tokenId);
//             ticketInfo_[_tokenId].superChat = _message;
//         } else {
//             ticketInfo_[_tokenId].superChatResponse = _message;
//             channelMessages.remove(_tokenId);
//         }
//         emit SuperChat(msg.sender, _tokenId, block.timestamp);
//     }

//     function clearSuperChat(uint _tokenId) external {
//         require(getReceiver(_tokenId) == msg.sender, "Only receiver!");
//         ticketInfo_[_tokenId].superChat = "";
//         ticketInfo_[_tokenId].superChatResponse = "";
//     }

//     function addSponsoredMessages(uint _tokenId, string memory _msg) external {
//         require(msg.sender == ticketInfo_[_tokenId].owner, "PayERC1155: Only owner");
//         sponsoredMessages[_tokenId] = _msg;
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

//     function boostingPower(uint _tokenId) external view returns(uint result) {
//         require(ticketInfo_[_tokenId].owner != address(0), "Does not exist");
//         if (ticketInfo_[_tokenId].subCount >= Q4) {
//             result = boosts[3];
//         } else if (ticketInfo_[_tokenId].subCount >= Q3) {
//             result = boosts[2];
//         } else if (ticketInfo_[_tokenId].subCount >= Q2) {
//             result = boosts[1];
//         } else if (ticketInfo_[_tokenId].subCount >= Q1) {
//             result = boosts[0];
//         }
//     }

//     function burn(
//         address account, 
//         uint256 id, 
//         uint256 amount
//     ) external {
//         require(msg.sender == ticketInfo_[id].owner || msg.sender == devaddr_, "Only owner or admin");
//         _burn(account, id, amount);
//     }


//     function updateEventPrices(uint[] memory _eventIds, uint[] memory _prices) external onlyAdmin {
//         require(_eventIds.length == _prices.length, "Uneven lengths");
//         for (uint i = 0; i < _eventIds.length; i++) {
//             talentEventPrices[_eventIds[i]] = _prices[i];
//         }
//     }

//     function updateCatalogPrices(uint[] memory _catalogIds, uint[] memory _prices) external onlyAdmin {
//         require(_catalogIds.length == _prices.length, "Uneven lengths");
//         for (uint i = 0; i < _catalogIds.length; i++) {
//             talentCatalogPrices[_catalogIds[i]] = _prices[i];
//         }
//     }

//     function buyCatalog(uint[] memory _catalogIds, uint _tokenId) external nonReentrant {
//         require(msg.sender == getReceiver(_tokenId), "Only receiver!");
//         uint _total;
//         for (uint i = 0; i < _catalogIds.length; i++) {
//             if (userCatalog_[_tokenId][_catalogIds[i]] == 0 && 
//                 talentCatalog_[_catalogIds[i]].length > 0) {
//                 _total += talentCatalogPrices[_catalogIds[i]];
//             }
//         }
//         _safeTransferFrom(token, msg.sender, address(this), _total);
//         for (uint i = 0; i < _catalogIds.length; i++) {
//             if (userCatalog_[_tokenId][_catalogIds[i]] == 0 && 
//                 talentCatalog_[_catalogIds[i]].length > 0) {
//                 userCatalog_[_tokenId][_catalogIds[i]] = _catalogIds[i];
//             }
//         }
//     }

//     function buyEvent(uint[] memory _eventIds, uint _tokenId) external nonReentrant {
//         require(msg.sender == getReceiver(_tokenId), "Only receiver!");
//         uint _total;
//         for (uint i = 0; i < _eventIds.length; i++) {
//             if (userEvents_[_tokenId][_eventIds[i]] == address(0) && 
//                 talentEvents_[_eventIds[i]] == address(0)) {
//                 _total += talentEventPrices[_eventIds[i]];
//             }
//         }
//         _safeTransferFrom(token, msg.sender, address(this), _total);
//         for (uint i = 0; i < _eventIds.length; i++) {
//             if (userEvents_[_tokenId][_eventIds[i]] == address(0) && 
//                 talentEvents_[_eventIds[i]] == address(0)) {
//                 userEvents_[_tokenId][_eventIds[i]] = talentEvents_[_eventIds[i]];
//             }
//         }
//     }

//     function addEvent(address _nftAddress) external onlyAdmin {
//         talentEvents_[currentEventID++] = _nftAddress; 
//     }

//     function deleteEvent(uint _eventId) external onlyAdmin {
//         talentEvents_[_eventId] = address(0);
//     }

//     function addToCatalog(uint _catalogId, string[] memory _links) external onlyAdmin {
//         if (currentCatalogID != _catalogId) currentCatalogID++;
//         for (uint i = 0; i < _links.length; i++) {
//             talentCatalog_[currentCatalogID].push(_links[i]);
//         }
//     }

//     function deleteCatalog(uint _catalogId) external onlyAdmin {
//         delete talentCatalog_[_catalogId];
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


// contract CatalogNFTFactory is Ownable {
//     address public last_catalog;
//     address[] public catalogs;
//     mapping(address => bool) public isCatalog;

//     function createCatalog(
//         address _token,
//         address _devaddr,
//         string memory _uri,
//         address _superLikeGaugeFactory,
//         address _randomGenerator
//     ) external returns(address) {
//         last_catalog = address(new CatalogNFT(
//             _uri,
//             address(this),
//             _devaddr,
//             _token,
//             _randomGenerator,
//             _superLikeGaugeFactory
//         ));
//         isCatalog[last_catalog] = true;
//         catalogs.push(last_catalog);
//         return last_catalog;
//     }

//     function setElligible(
//         address _SLGFactory,
//         bytes32[] memory _idCodes, 
//         bool _elligible
//     ) external {
//         require(isCatalog[msg.sender], "Only catalog!");
//         bool _add = !_elligible;
//         ISuperLikeGaugeFactory(_SLGFactory).setElligibleForLoan(_idCodes, msg.sender, _add);
//     }

//     function updateIsCatalog(address[] memory _catalogs, bool _add) external onlyOwner {
//         for (uint i = 0; i < _catalogs.length; i++) {
//             isCatalog[_catalogs[i]] = _add;
//         }
//     }
// }
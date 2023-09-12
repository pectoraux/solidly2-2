// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;

// import "./Percentile.sol";
// import "./SponsorCardReceiver.sol";
// import "./BallerNFT.sol";

// // Gauges are used to incentivize different actions
// contract ValuePool is ERC20Votes, Percentile, Auth, SponsorCardReceiver {
//     using EnumerableSet for EnumerableSet.AddressSet;
//     using EnumerableSet for EnumerableSet.UintSet;

//     address public immutable token; // the governance token
//     address public lenderProtocol;
//     address public dtoken;

//     mapping(address => uint) public lentToLender;
//     // NFT percentile calculation
//     uint public totalpaidNFT;
//     uint public totalNFT;
//     uint public sum_of_diff_squared_nft;
//     int256 public zscore_nft;
//     uint public active_period;
//     uint public active_day;
//     uint internal constant week = 86400 * 7; // allows minting once per week (reset every Thursday 00:00 UTC)
//     uint internal constant day = 86400 * 1; // allows minting once per day
//     uint public REQ_PER_DAY;
//     uint public MAX_REQ_PER_DAY = 100;
//     uint public MaxDueReceivable;
//     struct InvoiceInfo {
//         uint lastPay;
//         uint rank;
//         uint active_period;
//         uint paidReceivable;
//         uint dueReceivable;
//         uint paidPayable;
//         string cartItems;
//         uint lastTimePaidReceivable;
//         uint lastTimePaidPayable;
//         uint periodReceivable;
//         uint user_sum_of_diff_squared;
//         address token;
//         UserToken params;
//     }
//     uint size;
//     mapping(address => InvoiceInfo) public invoiceInfo;
//     mapping(address => EnumerableSet.AddressSet) internal _sponsorVoters;
//     mapping(address => EnumerableSet.UintSet) internal _sponsorVotes;
//     struct UserToken {
//         uint totalInvoices;
//         uint totalpaidInvoices;
//         uint sum_of_diff_squared_invoices;
//     }
//     mapping(address => UserToken) private userTokens;
//     EnumerableSet.AddressSet private userTokensSet;
//     uint public maxWithdrawable = 100;
//     uint public MaximumArraySize = 50;
//     uint public maximumNumberOfActiveInvoices;

//     uint public DEPOSIT_THRESHOLD = 50;
//     uint public round = 0;
//     mapping(address => uint) public callPending;
//     address public marketPlace;
//     IRandomNumberGenerator internal randomGenerator_;
//     uint public treasuryShare = 200;
//     uint public adminShare = 100;
//     uint public rank;
//     mapping(uint => uint) public queue;
//     bool public riskPool = false;
//     bool public withdrawable = true;
//     bool public conditionalWithdrawals;
//     mapping(address => uint) canWithdraw;
//     mapping(address => mapping(address => bool)) public merchants;
//     uint TEST_CHAIN = 31337;
//     address public nft_;
//     address public ballerFactory;
//     mapping(address => bool) public authorizedUsers;
//     bool public BNPL;
//     bool public addToUserBalance = true;
//     uint public percentDueReimbursable = 10000;
//     address public payswapAdmin = 0x0bDabC785a5e1C71078d6242FB52e70181C1F316;
//     uint public tradingFee = 100;
//     bool public checkFactory;
//     mapping(address => bool) public isFactory;
//     string public  merchantValueName;
//     uint public merchantMinIDBadgeColor;
//     bytes32 public merchantRequiredIndentity;
//     EnumerableSet.AddressSet private merchantTrustWorthyAuditors;
//     bool public immutable oneVotePerUser;
//     mapping(bytes32 => true) public lpBalance;

//     event Withdraw(address indexed from, uint amount);
//     event NotifyReward(address indexed from, address indexed reward, uint amount);
//     event AddInvoice(address indexed from, int256 periodReceivable);
//     event UpdateCartItems(address indexed from, string cartItems);
//     event Deposit(address indexed from, uint time, uint amount);
//     event DeleteInvoice(address indexed from, uint time, address _user);

//     constructor(
//         string memory _name,
//         string memory _symbol,
//         address _token, 
//         address _devaddr,
//         address _randomGenerator,
//         address _superLikeGaugeFactory,
//         uint _maximumNumberOfActiveInvoices,
//         address _sponsorCardFactory
//     ) Auth(_devaddr, _superLikeGaugeFactory) 
//       ERC20(_name, _symbol)
//       SponsorCardReceiver(_sponsorCardFactory, _devaddr)
//     {
//         token = _token;
//         maximumNumberOfActiveInvoices = _maximumNumberOfActiveInvoices;
//         randomGenerator_ = IRandomNumberGenerator(_randomGenerator);
//     }

//     function initialize(
//         address _ballerFactory,
//         address _marketPlace, 
//         bool _riskPool,
//         bool _withdrawable,
//         bool _conditionaWithdrawals,
//         bool _onVotePerUser
//     ) external onlyAdmin {
//         riskPool = _riskPool;
//         withdrawable = _withdrawable;
//         conditionaWithdrawals = _conditionaWithdrawals;
//         marketPlace = _marketPlace;
//         ballerFactory = _ballerFactory;
//         onVotePerUser = _onVotePerUser;
//     }

//     function updateDepositThreshold(uint _newThreshold) external onlyAdmin {
//         DEPOSIT_THRESHOLD = _newThreshold;
//     }

//     function updateMaxWithdrawable(uint _maxWithdrawable) external onlyAdmin {
//         maxWithdrawable = _maxWithdrawable;
//     }

//     function updateMaximumArraySize(uint newMax) external onlyAdmin {
//         MaximumArraySize = newMax;
//     }

//     function updateBNPL(bool _bnpl) external onlyAdmin {
//         BNPL = _bnpl;
//     }

//     function updateAddtoUserBalance(bool _add) external onlyAdmin {
//         addToUserBalance = _add;
//     }
    
//     /** LENDER PROTOCOL 
//     */
//     function updateLenderProtocol(address _lenderProtocol) external onlyAdmin {
//         lenderProtocol = _lenderProtocol;
//     }
    
//     function addToLender(address _token, uint _limit) external onlyAdmin {
//         ILender(lenderProtocol).addProtocol(
//             address(this),
//             _token,
//             _limit  
//         );
//     }

//     function lendToLender(address _token, uint _limit) external nonReentrant {
//         require(msg.sender == lenderProtocol, "Only lender");
//         _safeTransfer(_token, msg.sender, _limit);
//         lentToLender[_token] += _limit;
//     }

//     function notifyWithdrawFromLender(address _token, uint _value) external onlyAdmin {
//         ILender(lenderProtocol).withdrawFromBalance(
//             address(this),
//             _token,
//             _value
//         );
//         lentToLender[_token] -= _value;
//     }

//     /** NFT Mine 
//     */
//     function createNFTicket(
//         uint _series,
//         address _token,
//         string memory _uri, 
//         bool _confirm
//     ) external onlyAdmin {
//         require(nft_ == address(0) || _confirm, "MarketPlace: NFT already minted");
//         nft_ = address(new BallerNFT(
//             address(this),
//             _series,
//             _token,
//             _uri,
//             superLikeGaugeFactory,
//             address(randomGenerator_)
//         ));
//     }

//     function withdrawTreasury() external {
//         IBallerNFT(nft_).withdrawTreasury();
//     }

//     function updateNFTDev(address _newDev) external onlyAdmin{
//         IBallerNFT(nft_).updateDev(_newDev);
//     }

//     /**
//      * @notice Change the random generator
//      * @dev The calls to functions are used to verify the new generator implements them properly.
//      * It is necessary to wait for the VRF response before starting a round.
//      * Callable only by the contract owner
//      * @param _randomGeneratorAddress: address of the random generator
//      */
//     function changeRandomGenerator(address _randomGeneratorAddress) external onlyAdmin {
//         // // Request a random number from the generator based on a seed
//         // IRandomNumberGenerator(_randomGeneratorAddress).getRandomNumber(
//         //     uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)))
//         // );

//         // // Calculate the finalNumber based on the randomResult generated by ChainLink's fallback
//         // IRandomNumberGenerator(_randomGeneratorAddress).viewRandomResult();

//         // randomGenerator_ = IRandomNumberGenerator(_randomGeneratorAddress);

//         // emit NewRandomGenerator(_randomGeneratorAddress);
//     }
    
//     function updateMerchant(
//         address _user,
//         bool _add,
//         address _merchant
//     ) public onlyAuth {
//         merchants[_user][_merchant] = _add;
//     }

//     function updateFactory(address _factory, bool _add) external onlyAdmin {
//         isFactory[_factory] = _add;
//     }

//     function updateCheckFactory(bool _check) external onlyAdmin {
//         checkFactory = _check;
//     }

//     function addInvoiceFromFactory(
//         address _owner,
//         int _periodReceivable,
//         address _token,
//         string memory _cartItems
//      ) external {
//         if (checkFactory) require(isFactory[msg.sender], "Only factory");
//         addInvoice(_owner, _periodReceivable, _token, _cartItems);
//     }

//     function addToUserTokensSet(address[] memory _tokens) external onlyAdmin {
//         for (uint i = 0; i < _tokens.length; i++) {
//             if (_tokens[i] != address(0)) userTokensSet.add(_tokens[i]);
//         }
//     }

//     function removeFromUserTokensSet(address[] memory _tokens) external onlyAdmin {
//         for (uint i = 0; i < _tokens.length; i++) {
//             if (_tokens[i] != address(0)) userTokensSet.remove(_tokens[i]);
//         }
//     }

//     function addInvoice(
//         address _owner,
//         int _periodReceivable,
//         address _token,
//         string memory _cartItems
//     ) public {
//         require(_owner != address(0), "Invalid owner");
//         require(userTokensSet.contains(_token), "Invalid user token");
//         require(
//             maximumNumberOfActiveInvoices == 0 || 
//             maximumNumberOfActiveInvoices - size > 0, 
//             'Contract has reached maximum number of invoices'
//         );
//         invoiceInfo[msg.sender] = InvoiceInfo({
//             paidReceivable: 0,
//             paidPayable: 0,
//             cartItems: _cartItems,
//             lastTimePaidReceivable: 0,
//             lastTimePaidPayable: 0,
//             lastPay: 0,
//             rank: 0,
//             active_period: 0,
//             params: UserToken({
//                 totalInvoices: 0, 
//                 totalpaidInvoices: 0, 
//                 sum_of_diff_squared_invoices: 0
//             }),
//             dueReceivable: 0,
//             user_sum_of_diff_squared: 0,
//             token: _token,
//             periodReceivable: _periodReceivable > 0 ? uint(_periodReceivable) : type(uint).max 
//         });
//         size += 1;

//         emit AddInvoice(msg.sender, _periodReceivable);
//     }

//     function updateMaximumNumberOfActiveInvoices(uint256 newMax) public onlyAdmin {
//         maximumNumberOfActiveInvoices = newMax;
//     }

//     function updateCartItems(string memory _cartItems) external {
//         invoiceInfo[msg.sender].cartItems = _cartItems;

//         emit UpdateCartItems(msg.sender, _cartItems);
//     }

//     function updateReimbursable(uint _newReimbursable) external onlyAdmin {
//         percentDueReimbursable = _newReimbursable;
//     }

//     function updateCanWithdraw(address[] memory _users, uint _amount) external onlyAdmin {
//         for (uint i = 0; i < _users.length; i++) {
//             canWithdraw[_users[i]] += _amount;
//         }
//     }

//     function reimburseLoan(uint _amount, bool _fromBalance) public nonReentrant {
//         uint _due = invoiceInfo[msg.sender].dueReceivable * percentDueReimbursable / 10000;
//         uint _toPay = invoiceInfo[msg.sender].dueReceivable >= _amount ? _amount : invoiceInfo[msg.sender].dueReceivable;
//         if (_fromBalance && withdrawable) {
//             _toPay = invoiceInfo[msg.sender].paidReceivable >= _toPay ? 
//             _toPay : invoiceInfo[msg.sender].paidReceivable;
//             invoiceInfo[msg.sender].paidReceivable -= _toPay;
//         } else {
//             // _safeTransferFrom(invoiceInfo[msg.sender].token, msg.sender, address(this), _toPay);
//         }
//         if (_due > _toPay) {
//             invoiceInfo[msg.sender].dueReceivable -= _toPay;
//         } else {
//             invoiceInfo[msg.sender].dueReceivable = 0;
//         }
//     }

//     function _updateAccountsDeposits(address _card, uint _amount) internal override {
//         address[] memory _sponsored = ISponsorCard(_card).getSponsored(address(this));
//         for (uint i = 0; i < _sponsored.length; i++) {
//             if (_sponsorVoters[_sponsored[i]].length() < MaximumArraySize) {
//                 _sponsorVoters[_sponsored[i]].add(_card);
//                 _sponsorVotes[_sponsored[i]].add(_amount / _sponsored.length);
//                 if (_amount / _sponsored.length > 0 && addToUserBalance) {
//                     _deposit(
//                         getPriceInToken(
//                             token, 
//                             invoiceInfo[_sponsored[i]].token,
//                             _amount / _sponsored.length
//                         ), 
//                         _sponsored[i]
//                     );
//                 }
//             } 
//         }
//     }

//     function removeSponsors(address[] memory _cards, uint[] memory _positions, bool _all) external {
//         if (_all) {
//             delete _sponsorVoters[msg.sender];
//             delete _sponsorVotes[msg.sender];
//         } else {
//             for (uint i = 0; i < _cards.length; i++) {
//                 require(_sponsorVoters[msg.sender].at(_positions[i]) == _cards[i], "Invalid positions!");
//                 _sponsorVoters[msg.sender].remove(_cards[i]);
//                 _sponsorVotes[msg.sender].remove(_positions[i]);
//             }
//         }
//     }

//     function deposit(uint _amount) external {
//         require(_amount > 0, "Amount is 0");
//         // _safeTransferFrom(invoiceInfo[msg.sender].token, msg.sender, address(this), _amount);
//         _deposit(_amount, msg.sender);
//     }

//     function getPriceInToken(address _from, address _to, uint _amount) public view returns(uint) {
//         uint _multiplier = 1;
//         return _amount * _multiplier;
//     }

//     function _deposit(uint _amount, address _owner) internal nonReentrant {
//         invoiceInfo[_owner].paidReceivable += _amount;
//         invoiceInfo[_owner].lastTimePaidReceivable = block.timestamp;
//         if (onVotePerUser && lpBalance[userToIdentityCode[_owner]]) {
//             _mint(_owner, 1);
//             lpBalance[userToIdentityCode[_owner]] = true;
//         } else {
//             _mint(_owner, _amount);
//         }
//         (,uint _sods) = computePercentileFromData(
//             false, 
//             _amount,
//             userTokens[invoiceInfo[_owner].token].totalpaidInvoices, 
//             userTokens[invoiceInfo[_owner].token].totalInvoices, 
//             userTokens[invoiceInfo[_owner].token].sum_of_diff_squared_invoices
//         );
//         userTokens[invoiceInfo[_owner].token].totalpaidInvoices += _amount; 
//         userTokens[invoiceInfo[_owner].token].totalInvoices += 1; 
//         userTokens[invoiceInfo[_owner].token].sum_of_diff_squared_invoices = _sods;
//         if (getPriceInToken(
//                 invoiceInfo[_owner].token,
//                 token,
//                 invoiceInfo[_owner].paidReceivable) >= DEPOSIT_THRESHOLD) { 
//             //registers state of blockchain
//             if (invoiceInfo[_owner].params.totalInvoices == 0 ) { 
//                 // first registration
//                 invoiceInfo[_owner].params.totalInvoices = userTokens[invoiceInfo[_owner].token].totalInvoices;
//                 invoiceInfo[_owner].params.totalpaidInvoices = userTokens[invoiceInfo[_owner].token].totalpaidInvoices;
//                 invoiceInfo[_owner].params.sum_of_diff_squared_invoices = _sods;
//             } else {
//                 //update on each payment
//                 invoiceInfo[_owner].params.totalpaidInvoices += _amount; 
//                 invoiceInfo[_owner].params.sum_of_diff_squared_invoices = _sods;
//             }
//             invoiceInfo[_owner].lastPay = _amount;
//             invoiceInfo[_owner].user_sum_of_diff_squared = _sods;
//         }
//         emit Deposit(_owner, block.timestamp, _amount);
//     }

//     function getUserPercentile() public view returns(uint) {
//         if(invoiceInfo[msg.sender].lastPay == 0) return 1;

//         (uint percentile1,) = computePercentileFromData(
//             true,
//             invoiceInfo[msg.sender].lastPay,
//             invoiceInfo[msg.sender].params.totalpaidInvoices - invoiceInfo[msg.sender].lastPay,
//             invoiceInfo[msg.sender].params.totalInvoices - 1,
//             invoiceInfo[msg.sender].params.sum_of_diff_squared_invoices
//         );
//         (uint percentile2,) = computePercentileFromData(
//             true,
//             invoiceInfo[msg.sender].lastPay,
//             userTokens[invoiceInfo[msg.sender].token].totalpaidInvoices - invoiceInfo[msg.sender].lastPay,
//             userTokens[invoiceInfo[msg.sender].token].totalInvoices - 1,
//             userTokens[invoiceInfo[msg.sender].token].sum_of_diff_squared_invoices
//         );
//         return (percentile1 + percentile2) / 2;
//     }

//     function getLinkFeeInBase() public pure returns(uint) {
//         return 1;
//     }

//     function updateTreasuryShare(uint _share) external onlyAdmin {
//         require(_share >= adminShare, "Cannot be lower than admin share");
//         treasuryShare = _share;
//     }

//     function updateAdminShare(uint _share) external onlyAdmin {
//         require(_share <= treasuryShare, "Cannot be higher than treasury share");
//         adminShare = _share;
//     }

//     function getSupplyAvailable() public view returns(uint) {
//         uint _totalSupply = erc20(token).balanceOf(address(this));
//         uint _treasury = _totalSupply * treasuryShare / 10000;
//         return (_totalSupply - _treasury) * maxWithdrawable / 10000;
//     }

//     function _reinitializeQueue() internal {
//         for (uint i = 1; i < 100; i++) {
//             queue[i] = 0;
//         }
//     }

//     function getChainID() public view returns (uint256) {
//         uint256 id;
//         assembly {
//             id := chainid()
//         }
//         return id;
//     }

//     function updateMaxReqPerDay(uint newMax, uint _MaxDueReceivable) external onlyAdmin {
//         MAX_REQ_PER_DAY = newMax;
//         MaxDueReceivable = _MaxDueReceivable;
//     }

//     function pickRank() external nonReentrant {
//         checkIdentityProof(msg.sender, false);
//         require(invoiceInfo[msg.sender].active_period <= block.timestamp, "Only one draw a week");
//         if (BNPL) {
//             require(invoiceInfo[msg.sender].dueReceivable <= MaxDueReceivable, "Please reimburse your previous loan");
//         }
//         require(REQ_PER_DAY <= MAX_REQ_PER_DAY, "Maximum request per day reached");
//         if (active_period <= block.timestamp) {
//             _reinitializeQueue();
//             active_period = (block.timestamp + week) / week * week;
//         }
//         if (active_day <= block.timestamp) {
//             REQ_PER_DAY = 0;
//             active_day = (block.timestamp + day) / day * day;
//         }
        
//         require(callPending[msg.sender] == 0, "Previous request is still unchecked");
//         if (getChainID() != TEST_CHAIN) {
//             // randomGenerator_.getRandomNumber(
//             //     uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)))
//             // );
//         }
//         round++;
//         REQ_PER_DAY++;
//         callPending[msg.sender] = round;
//         invoiceInfo[msg.sender].paidReceivable -= getLinkFeeInBase();
//         invoiceInfo[msg.sender].active_period = (block.timestamp + week) / week * week;
//     }

//     function claimRank() external nonReentrant {
//         require(callPending[msg.sender] > 0, "No request pending");
//         uint roundNumber;
//         if (getChainID() == TEST_CHAIN) {
//             roundNumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 1000000;
//         } else {
//             // roundNumber = IRandomNumberGenerator(randomGenerator_).viewRandomResultFor(callPending[msg.sender]);
//         }
//         require(roundNumber > 0, "Still processing");
//         uint randomPercentile = getRandomPercentile(roundNumber);
//         uint userPercentile =  getUserPercentile();
//         uint _rank = randomPercentile > userPercentile ? 
//         randomPercentile - userPercentile + 1 : userPercentile - randomPercentile + 1;
//         queue[_rank] += 1;
//         invoiceInfo[msg.sender].rank = _rank;
//         if (rank > _rank || rank == 0) {
//             rank = _rank; 
//         }
//     }
    
//     function getPeopleBefore(uint _rank) external view returns(uint) {
//         uint peopleBefore;
//         for (uint i = 1; i < _rank; i++) {
//             peopleBefore += queue[i];
//         }
//         return peopleBefore;
//     }
   
//     function updateMerchantIDProofParams(
//         uint _merchantMinIDBadgeColor,
//         string memory _merchantValueName, //agebt, age, agelt... 
//         string memory _value //18
//     ) external onlyAdmin {
//         if (keccak256(abi.encodePacked(_value)) != keccak256(abi.encodePacked(""))) {
//             merchantRequiredIndentity == keccak256(abi.encodePacked(_value));
//         }
//         merchantValueName = _merchantValueName;   
//         merchantMinIDBadgeColor = _merchantMinIDBadgeColor;
//     }

//     function updateMerchantTrustWorthyAuditors(address[] memory _gauges, bool _add) external onlyAdmin {
//         for (uint i = 0; i < _gauges.length; i++) {
//             if (_add) {
//                 merchantTrustWorthyAuditors.add(_gauges[i]);
//             } else {
//                 merchantTrustWorthyAuditors.remove(_gauges[i]);
//             }
//         }
//     }

//     function getAllMerchantTrustWorthyAuditors() external view returns(address[] memory _auditors) {
//         _auditors = new address[](merchantTrustWorthyAuditors.length());
//         for (uint i = 0; i < merchantTrustWorthyAuditors.length(); i++) {
//             _auditors[i] = merchantTrustWorthyAuditors.at(i);
//         }
//     }

//     function checkIdentityProof2(address _owner, bool _check) public {
//         if (keccak256(abi.encodePacked(merchantValueName)) != keccak256(abi.encodePacked("")) || _check) {
//             (
//                 string memory ssid,
//                 string memory value, 
//                 address _gauge 
//             ) = ISuperLikeGaugeFactory(superLikeGaugeFactory).getIdentityValue(_owner, valueName);
//             require(ISuperLikeGauge(_gauge).badgeColor() >= uint(merchantMinIDBadgeColor), "ID Gauge inelligible");
//             require(keccak256(abi.encodePacked(value)) == merchantRequiredIndentity || 
//             merchantRequiredIndentity == 0, "Invalid comparator");
//             require(merchantTrustWorthyAuditors.length() == 0 || merchantTrustWorthyAuditors.contains(_gauge),
//             "Only identity proofs from trustworthy auditors"
//             );
//             bytes32 identityCode = keccak256(abi.encodePacked(ssid));
//             require(!blackListedIdentities[identityCode], "You identiyCode is blacklisted");
//             if (identityProofs[identityCode] == address(0)) {
//                 // only register the first time
//                 identityProofs[identityCode] = _owner;
//             }
//             userToIdentityCode[_owner] = identityCode;

//             emit CheckIdentityProof(_owner, _gauge, identityCode, block.timestamp);
//         }
//     }

//     function claimReward(
//         uint _paid,
//         string memory _videoId,
//         address _merchant,
//         address _merchantGauge
//     ) external nonReentrant {
//         checkIdentityProof2(_merchant, false);
//         require(invoiceInfo[msg.sender].rank == rank && rank != 0, "Invalid rank");
//         if (riskPool) require(merchants[msg.sender][_merchant], "Unregistered merchant");
//         uint _available = getSupplyAvailable();
//         uint _toPay = _available >= _paid ? _paid : _available;
//         require(_toPay > 0, "Nothing to pay");
//         erc20(token).approve(marketPlace, _toPay);
//         IMarketPlace(marketPlace).processPayment(
//             _merchant, 
//             _videoId, 
//             msg.sender, 
//             _toPay,
//             0
//         );
//         if (BNPL) invoiceInfo[msg.sender].dueReceivable +=
//                   getPriceInToken(token, invoiceInfo[msg.sender].token, _toPay);
//         invoiceInfo[msg.sender].lastTimePaidPayable = block.timestamp;
//         if (invoiceInfo[msg.sender].periodReceivable == type(uint).max) { //infinite
//             removeFootPrint(msg.sender);   
//         }
//         queue[rank] -= 1;
//         invoiceInfo[msg.sender].rank = 0;
//         if (queue[rank] == 0) {
//             rank += 1;
//             for (uint i = rank; i < 100; i++) {
//                 if (queue[i] > 0) {
//                     rank = i;
//                     break;
//                 } 
//             }
//         }
//         callPending[msg.sender] = 0;
//     }

//     function removeFootPrint(address _user) internal {
//         size -= 1;
//         userTokens[invoiceInfo[_user].token].totalInvoices -= 1;
//         userTokens[invoiceInfo[_user].token].totalpaidInvoices -= invoiceInfo[_user].paidReceivable;
//         userTokens[invoiceInfo[_user].token].sum_of_diff_squared_invoices -= invoiceInfo[_user].user_sum_of_diff_squared;

//         invoiceInfo[_user].lastPay = 0;
//         invoiceInfo[_user].rank = 0;
//         invoiceInfo[_user].params.totalInvoices = 0;
//         invoiceInfo[_user].params.totalpaidInvoices = 0;
//         invoiceInfo[_user].user_sum_of_diff_squared = 0;
//         invoiceInfo[_user].params.sum_of_diff_squared_invoices = 0;
//     }

//     function updatePayswapAdmin(address _newAdmin) external {
//         require(msg.sender == payswapAdmin, "Not payswapAdmin");
//         payswapAdmin = _newAdmin;
//     }

//     function updateTradingFee(uint _newFee) external {
//         require(msg.sender == payswapAdmin, "Not payswapAdmin");
//         tradingFee = _newFee;
//     }

//     function withdrawTreasury(address _token, uint amount) public onlyAdmin {
//         if (address(_token) == address(token)) {
//             uint _totalSupply = erc20(token).balanceOf(address(this));
//             amount = _totalSupply * treasuryShare / 10000;
//         }
//         uint _fees = amount * tradingFee / 10000;
//         _safeTransfer(_token, msg.sender, amount - _fees);
//         _safeTransfer(_token, payswapAdmin, _fees);

//         emit Withdraw(msg.sender, amount);
//     }

//     function withdraw(uint _amount) public {
//         require(withdrawable, "Cannot withdraw from risk pool");
//         if (BNPL) reimburseLoan(invoiceInfo[msg.sender].paidReceivable, true);
//         require(invoiceInfo[msg.sender].paidReceivable >= _amount, "Invalid amount");
//         uint newPaidReceivable = invoiceInfo[msg.sender].paidReceivable - _amount;
//         if (newPaidReceivable <= DEPOSIT_THRESHOLD ) {
//             removeFootPrint(msg.sender);
//         }       
//         invoiceInfo[msg.sender].lastPay = 0;
//         invoiceInfo[msg.sender].paidReceivable = newPaidReceivable;
//         _safeTransfer(dtoken, msg.sender, _amount);

//         emit Withdraw(msg.sender, _amount);
//     }

//     function withdrawFromFund(uint _amount) public {
//         require(conditionalWithdrawals && canWithdraw[msg.sender] > 0, "Cannot withdraw from fund");
//         require(canWithdraw[msg.sender] >= _amount, "Invalid amount");
        
//         canWithdraw[msg.sender] -= _amount;
//         _safeTransfer(dtoken, msg.sender, _amount);

//         emit Withdraw(msg.sender, _amount);
//     }

//     function deleteInvoice(address _user) public onlyAuth {
//         removeFootPrint(_user);
//         delete invoiceInfo[_user];
        
//         emit DeleteInvoice(msg.sender, block.timestamp, _user);
//     }

//     function notifyRewardAmount(uint _amount) external nonReentrant {
//         require(_amount > 0, "Invalid amount");

//         _safeTransferFrom(token, msg.sender, address(this), _amount);

//         emit NotifyReward(msg.sender, token, _amount);
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

//     function _safeApprove(address _token, address spender, uint256 value) internal {
//         require(_token.code.length > 0);
//         (bool success, bytes memory data) =
//         _token.call(abi.encodeWithSelector(erc20.approve.selector, spender, value));
//         require(success && (data.length == 0 || abi.decode(data, (bool))));
//     }
// }

// contract BaseV1ValuePoolFactory {
//     address public last_valuepool;
//     address[] public valuepools;

//     function createValuePool(
//         string memory _name,
//         string memory _symbol,
//         address _token, 
//         address _devaddr,
//         address _randomGenerator,
//         address _superLikeGaugeFactory,
//         uint _maximumNumberOfActiveInvoices,
//         address _sponsorCardFactory
//     ) external returns (address) {
//         last_valuepool = address(new ValuePool(
//             _name,
//             _symbol,
//             _token, 
//             _devaddr,
//             _randomGenerator,
//             _superLikeGaugeFactory,
//             _maximumNumberOfActiveInvoices,
//             _sponsorCardFactory
//         ));
//         valuepools.push(last_valuepool);
//         return last_valuepool;
//     }

//     function updateTradingFees(uint _newFee) external {
//         for (uint i = 0; i < valuepools.length; i++) {
//             IARP(valuepools[i]).updateTradingFee(_newFee);
//         }
//     }
// }

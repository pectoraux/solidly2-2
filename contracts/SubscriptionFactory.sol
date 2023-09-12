// import "./SubscriptionNFT.sol";

// // File: contracts/SubscriptionFactory.sol

// pragma solidity ^0.8.4;
// pragma abicoder v2;

// /** @title SubscriptionFactory.
//  * @notice It is a contract for a lottery system using
//  * randomness provided externally.
//  */
// contract SubscriptionFactory is Auth, ReentrancyGuard, Ownable {
//     using SafeERC20 for IERC20;

//     address public injectorAddress;
//     address public operatorAddress;
//     address public treasuryAddress;

//     uint256 public currentLotteryId;
//     uint256 public currentTicketId = 1;

//     uint256 public maxNumberTicketsPerBuyOrClaim = 100;

//     uint256 public maxPriceTicketInCake;
//     uint256 public minPriceTicketInCake;

//     uint256 public MIN_DISCOUNT_DIVISOR = 300;
//     uint256 public MIN_LENGTH_LOTTERY = 4 hours - 5 minutes; // 4 hours
//     uint256 public MAX_LENGTH_LOTTERY = 4 days + 5 minutes; // 4 days
//     uint256 public MAX_TREASURY_FEE = 3000; // 30%
//     uint public treasuryFee = 100;
//     IERC20 public cakeToken;
//     IRandomNumberGenerator public randomGenerator;

//     enum Status {
//         Pending,
//         Open,
//         Close,
//         Claimable
//     }

//     struct Param {
//         string id;
//         uint initialSubCount;
//         uint cursor;
//         uint size;
//         uint subGroupCount;
//         uint subCount;
//         uint[10] ticketsPerGroup;
//         string videoCid;
//     }

//     struct Lottery {
//         Status status;
//         Param params;
//         uint256 endTime;
//         uint256 priceTicketInCake;
//         uint256 discountDivisor;
//         uint256[6] rewardsBreakdown; // 0: 1 matching number // 5: 6 matching numbers
//         uint256[6] cakePerBracket;
//         uint256[6] countWinnersPerBracket;
//         uint256 treasuryFee; // 500: 5% // 200: 2% // 50: 0.5%
//         uint256 firstTicketId;
//         uint256 firstTicketIdNextLottery;
//         uint256 amountCollectedInCake;
//         uint32 finalNumber;
//     }

//     struct Ticket {
//         uint32 number;
//         address owner;
//     }

//     // Mapping are cheaper than arrays
//     mapping(address => Lottery) public _lotteries;
//     mapping(uint256 => Ticket) private _tickets;

//     address public valuePoolAddress;
//     uint TEST_CHAIN = 31337;
//     address[] public nfts;
//     address public nft;

//     // Bracket calculator is used for verifying claims for ticket prizes
//     mapping(uint32 => uint32) private _bracketCalculator;

//     // Keeps track of number of ticket per unique combination for each lotteryId
//     mapping(address => mapping(uint32 => uint256)) private _numberTicketsPerLotteryId;

//     // Keep track of user ticket ids for a given lotteryId
//     mapping(address => mapping(address => uint256[])) private _userTicketIdsPerLotteryId;

//     mapping(address => mapping(uint => uint)) private _usedNFTs;
//     mapping(address => mapping(uint => uint)) private bonus;

//     bool public requireIdentityProof;
//     mapping(address => mapping(bytes32 => bool)) public isSubscriberCode;
//     mapping(address => mapping(string => bool)) public isSubscriber;

//     modifier notContract() {
//         require(!_isContract(msg.sender), "Contract not allowed");
//         require(msg.sender == tx.origin, "Proxy contract not allowed");
//         _;
//     }

//     modifier onlyOperator() {
//         require(msg.sender == operatorAddress, "Not operator");
//         _;
//     }

//     modifier onlyOwnerOrInjector() {
//         require((msg.sender == owner()) || (msg.sender == injectorAddress), "Not owner or injector");
//         _;
//     }

//     event AdminTokenRecovery(address token, uint256 amount);
//     event LotteryClose(address indexed lotteryId, uint256 firstTicketIdNextLottery);
//     event LotteryInjection(address indexed lotteryId, uint256 injectedAmount);
//     event LotteryOpen(
//         uint256 indexed lotteryId,
//         uint256 startTime,
//         uint256 endTime,
//         uint256 priceTicketInCake,
//         uint256 firstTicketId,
//         uint256 injectedAmount
//     );
//     event LotteryNumberDrawn(address indexed lotteryId, uint256 finalNumber, uint256 countWinningTickets);
//     event NewOperatorAndTreasuryAndInjectorAddresses(address operator, address treasury, address injector);
//     event NewRandomGenerator(address indexed randomGenerator);
//     event TicketsPurchase(address indexed buyer, address indexed lotteryId, uint256 numberTickets);
//     event TicketsClaim(address indexed claimer, uint256 amount, address indexed lotteryId, uint256 numberTickets);
//     event Reimburse(address indexed claimer, uint256 tokenId, uint256 total);
//     event ProcessPayment(address indexed valuepool, address indexed to, string, uint256 amount);
//     /**
//      * @notice Constructor
//      * @dev RandomNumberGenerator must be deployed prior to this contract
//      * @param _cakeTokenAddress: address of the CAKE token
//      * @param _randomGeneratorAddress: address of the RandomGenerator contract used to work with ChainLink VRF
//      */
//     constructor(
//         address _devaddr, 
//         address _cakeTokenAddress, 
//         address _superLikeGaugeFactory,
//         address _randomGeneratorAddress
//     ) 
//     Auth(_devaddr, _superLikeGaugeFactory)
//     {
//         cakeToken = IERC20(_cakeTokenAddress);
//         randomGenerator = IRandomNumberGenerator(_randomGeneratorAddress);

//         // Initializes a mapping
//         _bracketCalculator[0] = 1;
//         _bracketCalculator[1] = 11;
//         _bracketCalculator[2] = 111;
//         _bracketCalculator[3] = 1111;
//         _bracketCalculator[4] = 11111;
//         _bracketCalculator[5] = 111111;
//     }

//     function updateLotteryVariables(
//         uint _newDiscountDivisor,
//         uint _newMinLengthLottery,
//         uint _newMaxLengthLottery,
//         uint _newMaxTreasuryFee
//     ) external onlyOwner {
//         MIN_DISCOUNT_DIVISOR = _newDiscountDivisor;
//         MIN_LENGTH_LOTTERY = _newMinLengthLottery;
//         MAX_LENGTH_LOTTERY = _newMaxLengthLottery;
//         MAX_TREASURY_FEE = _newMaxTreasuryFee;
//     }

//     function updateIdentityProof(bool _requireIdentityProof) external onlyOwner {
//         requireIdentityProof = _requireIdentityProof;
//     }

//     function getUsedFreeTickets(address _channel, uint _tokenId) external view returns(uint) {
//         return _usedNFTs[_channel][_tokenId];
//     }

//     /**
//      * @notice Buy tickets for the current lottery
//      * @param _lotteryId: lotteryId
//      * @param _ticketNumbers: array of ticket numbers between 1,000,000 and 1,999,999
//      * @dev Callable by users
//      */
//     function buyTickets(
//         address _lotteryId, uint _tokenId, uint32[] calldata _ticketNumbers)
//         external
//         notContract
//         nonReentrant
//     {   
//         require(ISubscriptionNFT(nft).getReceiver(_tokenId) == msg.sender, "Only receiver!");
//         require(_ticketNumbers.length != 0, "No ticket specified");
//         require(_ticketNumbers.length <= maxNumberTicketsPerBuyOrClaim, "Too many tickets");
//         require(_lotteries[_lotteryId].status == Status.Open, "Lottery is not open");
//         require(block.timestamp < _lotteries[_lotteryId].endTime, "Lottery is over");
        
//         uint _numOfTickets = Math.min(
//             _ticketNumbers.length, 
//             getNumTicketsAllowed(
//                 _lotteryId, 
//                 _tokenId
//             )
//         );
//         _usedNFTs[_lotteryId][_tokenId] += _numOfTickets;

//         if (maxPriceTicketInCake > 0) {
//             // Calculate number of CAKE to this contract
//             uint256 amountCakeToTransfer = _calculateTotalPriceForBulkTickets(
//                 _lotteries[_lotteryId].discountDivisor,
//                 _lotteries[_lotteryId].priceTicketInCake,
//                 Math.max(_ticketNumbers.length - _numOfTickets, 0)
//             );

//             // Transfer cake tokens to this contract
//             cakeToken.safeTransferFrom(address(msg.sender), address(this), amountCakeToTransfer);

//             // Increment the total amount collected for the lottery round
//             _lotteries[_lotteryId].amountCollectedInCake += amountCakeToTransfer;
//         }
       
//         for (uint256 i = 0; i < _numOfTickets; i++) {
//             uint32 thisTicketNumber = _ticketNumbers[i];

//             require(
//                 (thisTicketNumber >= _lotteries[_lotteryId].params.cursor) && 
//                 (thisTicketNumber <= _lotteries[_lotteryId].params.cursor+_lotteries[_lotteryId].params.size), 
//                 "Outside range"
//             );

//             _numberTicketsPerLotteryId[_lotteryId][1 + (thisTicketNumber % 10)]++;
//             _numberTicketsPerLotteryId[_lotteryId][11 + (thisTicketNumber % 100)]++;
//             _numberTicketsPerLotteryId[_lotteryId][111 + (thisTicketNumber % 1000)]++;
//             _numberTicketsPerLotteryId[_lotteryId][1111 + (thisTicketNumber % 10000)]++;
//             _numberTicketsPerLotteryId[_lotteryId][11111 + (thisTicketNumber % 100000)]++;
//             _numberTicketsPerLotteryId[_lotteryId][111111 + (thisTicketNumber % 1000000)]++;

//             _userTicketIdsPerLotteryId[msg.sender][_lotteryId].push(currentTicketId);

//             _tickets[currentTicketId] = Ticket({number: thisTicketNumber, owner: msg.sender});

//             // Increase lottery ticket number
//             currentTicketId++;
//         }

//         emit TicketsPurchase(msg.sender, _lotteryId, _ticketNumbers.length);
//     }

//     /**
//      * @notice Claim a set of winning tickets for a lottery
//      * @param _lotteryId: lottery id
//      * @param _ticketIds: array of ticket ids
//      * @param _brackets: array of brackets for the ticket ids
//      * @dev Callable by users only, not contract!
//      */
//     function claimTickets(
//         address _lotteryId,
//         uint256[] calldata _ticketIds,
//         uint32[] calldata _brackets
//     ) external notContract nonReentrant {
//         require(_ticketIds.length == _brackets.length, "Not same length");
//         require(_ticketIds.length != 0, "Length must be >0");
//         require(_ticketIds.length <= maxNumberTicketsPerBuyOrClaim, "Too many tickets");
//         require(_lotteries[_lotteryId].status == Status.Claimable, "Lottery not claimable");

//         // Initializes the rewardInCakeToTransfer
//         uint256 rewardInCakeToTransfer;

//         for (uint256 i = 0; i < _ticketIds.length; i++) {
//             require(_brackets[i] < 6, "Bracket out of range"); // Must be between 0 and 5

//             uint256 thisTicketId = _ticketIds[i];

//             require(_lotteries[_lotteryId].firstTicketIdNextLottery > thisTicketId, "TicketId too high");
//             require(_lotteries[_lotteryId].firstTicketId <= thisTicketId, "TicketId too low");
//             require(msg.sender == _tickets[thisTicketId].owner, "Not the owner");

//             // Update the lottery ticket owner to 0x address
//             _tickets[thisTicketId].owner = address(0);

//             uint256 rewardForTicketId = _calculateRewardsForTicketId(_lotteryId, thisTicketId, _brackets[i]);

//             // Check user is claiming the correct bracket
//             require(rewardForTicketId != 0, "No prize for this bracket");

//             if (_brackets[i] != 5) {
//                 require(
//                     _calculateRewardsForTicketId(_lotteryId, thisTicketId, _brackets[i] + 1) == 0,
//                     "Bracket must be higher"
//                 );
//             }

//             // Increment the reward to transfer
//             rewardInCakeToTransfer += rewardForTicketId;
//         }

//         // Transfer money to msg.sender
//         cakeToken.safeTransfer(msg.sender, rewardInCakeToTransfer);
        
//         emit TicketsClaim(msg.sender, rewardInCakeToTransfer, _lotteryId, _ticketIds.length);
//     }

//     /**
//      * @notice Close lottery
//      * @dev Callable by operator
//      */
//     function closeLottery() external nonReentrant {
//         require(_lotteries[msg.sender].status == Status.Open, "Lottery not open");
//         require(block.timestamp > _lotteries[msg.sender].endTime, "Lottery not over");
//         _lotteries[msg.sender].firstTicketIdNextLottery = currentTicketId;

//         // Request a random number from the generator based on a seed
//         randomGenerator.randomnessIsRequestedHere(1, msg.sender);
//         _lotteries[msg.sender].status = Status.Close;

//         emit LotteryClose(msg.sender, currentTicketId);
//     }

//     function getChainID() public view returns (uint256) {
//         uint256 id;
//         assembly {
//             id := chainid()
//         }
//         return id;
//     }

//     /**
//      * @notice Draw the final number, calculate reward in CAKE per group, and make lottery claimable
//      * @dev Callable by operator
//      */
//     function drawFinalNumberAndMakeLotteryClaimable()
//         external
//         nonReentrant
//     {
//         require(_lotteries[msg.sender].status == Status.Close, "Lottery not close");
        
//         // Calculate the finalNumber based on the randomResult generated by ChainLink's fallback
//         uint[] memory randomNumbers = 
//         IRandomNumberGenerator(randomGenerator).viewRandomNumbers(_lotteries[msg.sender].firstTicketIdNextLottery, msg.sender);
//         uint32 finalNumber = uint32(_lotteries[msg.sender].params.cursor + 
//         (randomNumbers[0] % _lotteries[msg.sender].params.size));

//         // Initialize a number to count addresses in the previous bracket
//         uint256 numberAddressesInPreviousBracket;

//         // Calculate the amount to share post-treasury fee
//         uint teamFee = _lotteries[msg.sender].amountCollectedInCake * _lotteries[msg.sender].treasuryFee / 10000;
//         uint256 amountToShareToWinners = _lotteries[msg.sender].amountCollectedInCake - teamFee;

//         // Initializes the amount to withdraw to treasury
//         uint256 amountToWithdrawToTreasury;

//         // Calculate prizes in CAKE for each bracket by starting from the highest one
//         for (uint32 i = 0; i < 6; i++) {
//             uint32 j = 5 - i;
//             uint32 transformedWinningNumber = _bracketCalculator[j] + (finalNumber % (uint32(10)**(j + 1)));

//             _lotteries[msg.sender].countWinnersPerBracket[j] =
//                 _numberTicketsPerLotteryId[msg.sender][transformedWinningNumber] -
//                 numberAddressesInPreviousBracket;

//             // A. If number of users for this _bracket number is superior to 0
//             if (
//                 (_numberTicketsPerLotteryId[msg.sender][transformedWinningNumber] - numberAddressesInPreviousBracket) !=
//                 0
//             ) {
//                 // B. If rewards at this bracket are > 0, calculate, else, report the numberAddresses from previous bracket
//                 if (_lotteries[msg.sender].rewardsBreakdown[j] != 0) {
//                     _lotteries[msg.sender].cakePerBracket[j] =
//                         ((_lotteries[msg.sender].rewardsBreakdown[j] * amountToShareToWinners) /
//                             (_numberTicketsPerLotteryId[msg.sender][transformedWinningNumber] -
//                                 numberAddressesInPreviousBracket)) /
//                         10000;

//                     // Update numberAddressesInPreviousBracket
//                     numberAddressesInPreviousBracket = _numberTicketsPerLotteryId[msg.sender][transformedWinningNumber];
//                 }
//                 // A. No CAKE to distribute, they are added to the amount to withdraw to treasury address
//             } else {
//                 _lotteries[msg.sender].cakePerBracket[j] = 0;

//                 amountToWithdrawToTreasury +=
//                     (_lotteries[msg.sender].rewardsBreakdown[j] * amountToShareToWinners) /
//                     10000;
//             }
//         }

//         // Update internal statuses for lottery
//         _lotteries[msg.sender].finalNumber = finalNumber;
//         _lotteries[msg.sender].status = Status.Claimable;

//         amountToWithdrawToTreasury += (_lotteries[msg.sender].amountCollectedInCake - amountToShareToWinners);

//         // Transfer CAKE to treasury address
//         cakeToken.safeTransfer(treasuryAddress, amountToWithdrawToTreasury);

//         emit LotteryNumberDrawn(msg.sender, finalNumber, numberAddressesInPreviousBracket);
//     }

//     /**
//      * @notice Change the random generator
//      * @dev The calls to functions are used to verify the new generator implements them properly.
//      * It is necessary to wait for the VRF response before starting a round.
//      * Callable only by the contract owner
//      * @param _randomGeneratorAddress: address of the random generator
//      */
//     function changeRandomGenerator(address _randomGeneratorAddress) external onlyOwner {
//         // Request a random number from the generator based on a seed
//         IRandomNumberGenerator(_randomGeneratorAddress).randomnessIsRequestedHere(1, msg.sender);

//         // Calculate the finalNumber based on the randomResult generated by ChainLink's fallback
//         // IRandomNumberGenerator(_randomGeneratorAddress).viewRandomResult();

//         randomGenerator = IRandomNumberGenerator(_randomGeneratorAddress);

//         emit NewRandomGenerator(_randomGeneratorAddress);
//     }

//     /**
//      * @notice Inject funds
//      * @param _channel: channel address
//      * @param _amount: amount to inject in CAKE token
//      * @dev Callable by owner or injector address
//      */
//     function injectFunds(address _channel, uint256 _amount) public {
//         cakeToken.safeTransferFrom(msg.sender, address(this), _amount);
//         _lotteries[_channel].amountCollectedInCake += _amount;

//         emit LotteryInjection(_channel, _amount);
//     }

//     function fundWithNFTFund() public {
//         uint _amount = ISubscriptionNFT(nft).fundLottery(msg.sender);

//         _lotteries[msg.sender].amountCollectedInCake += _amount;

//         emit LotteryInjection(msg.sender, _amount);
//     }

//     // can be used to add bonuses based on actions like: comment/like/views
//     function addBonusAdmin(
//         address _channel,
//         uint _tokenId,
//         uint _bonus
//     ) external onlyOwner {
//         bonus[_channel][_tokenId] += _bonus;
//     }

//     function addBonus(
//         uint _tokenId,
//         uint _bonus
//     ) external {
//         bonus[msg.sender][_tokenId] += _bonus;
//     }

//     function startChannel(
//         string memory _channelId,
//         address _channel,
//         uint _initialSubCount,
//         uint _subGroupCount,
//         uint _subCount,
//         string memory _videoCid,
//         uint[10] calldata _ticketsPerGroup
//     ) external onlyOwner {
//         require(_lotteries[_channel].endTime == 0, "Channel already started");
//         checkIdentityProof(_channel, false);

//         _lotteries[_channel] = Lottery({
//             status: Status.Pending,
//             endTime: block.timestamp,
//             priceTicketInCake: 0,
//             discountDivisor: 0,
//             rewardsBreakdown: [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)],
//             treasuryFee: treasuryFee,
//             cakePerBracket: [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)],
//             countWinnersPerBracket: [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)],
//             firstTicketId: 0,
//             firstTicketIdNextLottery: 0,
//             amountCollectedInCake: 0,
//             finalNumber: 0,
//             params : Param({
//                 id: _channelId,
//                 initialSubCount: _initialSubCount,
//                 cursor: 0,
//                 size: 0,
//                 subCount: _subCount,
//                 subGroupCount: _subGroupCount,
//                 ticketsPerGroup: _ticketsPerGroup,
//                 videoCid: _videoCid
//             })
//         });
//     }

//     function updateChannel(
//         uint _subGroupCount,
//         string memory _videoCid,
//         uint[10] calldata _ticketsPerGroup
//     ) external {
//         require(
//             (_lotteries[msg.sender].status == Status.Pending) || (_lotteries[msg.sender].status == Status.Claimable),
//             "Not time to start lottery"
//         );
//         _lotteries[msg.sender].params.subGroupCount = _subGroupCount;
//         _lotteries[msg.sender].params.videoCid = _videoCid;
//         _lotteries[msg.sender].params.ticketsPerGroup = _ticketsPerGroup;
//     }

//     function updateContracts(
//         address _valuePoolAddress,
//         address _superLikeGaugeFactory
//     ) external onlyOperator {
//         valuePoolAddress = _valuePoolAddress;
//         superLikeGaugeFactory = _superLikeGaugeFactory;
//     }

//     function fundWithValuePool(address _valuePool, address _channel, uint _amount) external nonReentrant {
//         if (_valuePool == address(0)) {
//             _valuePool = valuePoolAddress;
//         }
//         IValuePool(_valuePool).claimReward(
//             _amount,
//             string(abi.encodePacked("fundWithValuePool")),
//             _channel,
//             ISuperLikeGaugeFactory(superLikeGaugeFactory).userGauge(msg.sender)
//         );
//     }

//     function processPayment(address _to, string memory _id, address _from, uint _amount, uint _direction) external nonReentrant {
//         require(_direction == 1, "Invalid direction");
//         if (keccak256(abi.encodePacked(_id)) == keccak256(abi.encodePacked("fundWithValuePool"))) {
//             injectFunds(_to, _amount);
//         }
        
//         emit ProcessPayment(_from, _to, _id, _amount);
//     }

//     /**
//      * @notice Start the lottery
//      * @dev Callable by operator
//      * @param _endTime: endTime of the lottery
//      * @param _priceTicketInCake: price of a ticket in CAKE
//      * @param _discountDivisor: the divisor to calculate the discount magnitude for bulks
//      * @param _rewardsBreakdown: breakdown of rewards per bracket (must sum to 10,000)
//      */
//     function startLottery(
//         uint256 _endTime,
//         uint256 _priceTicketInCake,
//         uint256 _discountDivisor,
//         uint256[6] calldata _rewardsBreakdown,
//         uint _cursor,
//         uint _size
//     ) external {
//         require(
//             (_lotteries[msg.sender].status == Status.Pending) || (_lotteries[msg.sender].status == Status.Claimable),
//             "Not time to start lottery"
//         );
//         require(
//             (_endTime >= MIN_LENGTH_LOTTERY && _endTime <= MAX_LENGTH_LOTTERY),
//             "Lottery length outside of range"
//         );

//         require(
//             (_priceTicketInCake >= minPriceTicketInCake) && (_priceTicketInCake <= maxPriceTicketInCake),
//             "Outside of limits"
//         );

//         require(_discountDivisor >= MIN_DISCOUNT_DIVISOR, "Discount divisor too low");

//         require(
//             (_rewardsBreakdown[0] +
//                 _rewardsBreakdown[1] +
//                 _rewardsBreakdown[2] +
//                 _rewardsBreakdown[3] +
//                 _rewardsBreakdown[4] +
//                 _rewardsBreakdown[5]) == 10000,
//             "Rewards must equal 10000"
//         );
//         _lotteries[msg.sender].status = Status.Open;
//         _lotteries[msg.sender].endTime = block.timestamp + _endTime;
//         _lotteries[msg.sender].priceTicketInCake = _priceTicketInCake;
//         _lotteries[msg.sender].discountDivisor = _discountDivisor;
//         _lotteries[msg.sender].rewardsBreakdown = _rewardsBreakdown;
//         _lotteries[msg.sender].treasuryFee = treasuryFee;
//         _lotteries[msg.sender].cakePerBracket = [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)];
//         _lotteries[msg.sender].countWinnersPerBracket = [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)];
//         _lotteries[msg.sender].firstTicketId = currentTicketId;
//         _lotteries[msg.sender].firstTicketIdNextLottery = currentTicketId;
//         _lotteries[msg.sender].finalNumber = 0;
//         _lotteries[msg.sender].params.cursor = _cursor;
//         _lotteries[msg.sender].params.size = _size;

//         // reinitialise usedNFTs
//         uint[] memory _tokenIds = ISubscriptionNFT(nft).getChannelTickets(msg.sender);
//         for (uint i = 0; i < _tokenIds.length; i++) {
//             _usedNFTs[msg.sender][_tokenIds[i]] = 0;
//             bonus[msg.sender][_tokenIds[i]] = 0;
//         }

//         emit LotteryOpen(
//             currentLotteryId,
//             block.timestamp,
//             _endTime,
//             _priceTicketInCake,
//             currentTicketId,
//             treasuryFee
//         );
//     }

//     function createNFT(string memory _uri, bool _confirm) external onlyAdmin {
//         require(nft == address(0) || _confirm, "Already exists");

//         nft = address(new SubscriptionNFT(
//             _uri, 
//             address(this),
//             msg.sender,
//             address(cakeToken), 
//             address(randomGenerator),
//             superLikeGaugeFactory
//         ));
//         nfts.push(nft);
//     }
    
//     function mintSubscriptionNFT(
//         address _channel, 
//         address _to, 
//         uint _subCount,
//         string memory _email
//     ) external onlyOwner returns(uint) {
//         if (requireIdentityProof) {
//             require(!isSubscriberCode[_channel][userToIdentityCode[_to]], "You have already subscribed to channel");
//             isSubscriberCode[_channel][userToIdentityCode[_to]] = true;
//         } else {
//             require(!isSubscriber[_channel][_email], "You have already subscribed to channel");
//             isSubscriber[_channel][_email] = true;
//         }
//         _lotteries[_channel].params.subCount = _subCount;
//         return ISubscriptionNFT(nft).mint(_channel, _to, _subCount, _email);
//     }

//     function getNumTicketsAllowed(address _channel, uint _tokenId) public view returns(uint) {
//         uint diff = _lotteries[_channel].params.subCount - _lotteries[_channel].params.initialSubCount;
//         diff = diff / _lotteries[_channel].params.subGroupCount;
//          (,uint _userSubCount,) = ISubscriptionNFT(nft).getSubSpecs(_tokenId); 
//         uint totalAllowed = _lotteries[_channel].params.ticketsPerGroup[_userSubCount / diff];
//         return totalAllowed - _usedNFTs[_channel][_tokenId] + bonus[_channel][_tokenId];
//     }

//     function channelSubCount(address _channel) external view returns(uint) {
//         return _lotteries[_channel].params.subCount;
//     }

//     /**
//      * @notice It allows the admin to recover wrong tokens sent to the contract
//      * @param _tokenAddress: the address of the token to withdraw
//      * @param _tokenAmount: the number of token amount to withdraw
//      * @dev Only callable by owner.
//      */
//     function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
//         require(_tokenAddress != address(cakeToken), "Cannot be CAKE token");

//         IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

//         emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
//     }

//     /**
//      * @notice Set CAKE price ticket upper/lower limit
//      * @dev Only callable by owner
//      * @param _minPriceTicketInCake: minimum price of a ticket in CAKE
//      * @param _maxPriceTicketInCake: maximum price of a ticket in CAKE
//      */
//     function setMinAndMaxTicketPriceInCake(uint256 _minPriceTicketInCake, uint256 _maxPriceTicketInCake)
//         external
//         onlyOwner
//     {
//         require(_minPriceTicketInCake <= _maxPriceTicketInCake, "minPrice must be < maxPrice");

//         minPriceTicketInCake = _minPriceTicketInCake;
//         maxPriceTicketInCake = _maxPriceTicketInCake;
//     }

//     /**
//      * @notice Set max number of tickets
//      * @dev Only callable by owner
//      */
//     function setMaxNumberTicketsPerBuy(uint256 _maxNumberTicketsPerBuy) external onlyOwner {
//         require(_maxNumberTicketsPerBuy != 0, "Must be > 0");
//         maxNumberTicketsPerBuyOrClaim = _maxNumberTicketsPerBuy;
//     }

//     /**
//      * @notice Set operator, treasury, and injector addresses
//      * @dev Only callable by owner
//      * @param _operatorAddress: address of the operator
//      * @param _treasuryAddress: address of the treasury
//      * @param _injectorAddress: address of the injector
//      */
//     function setOperatorAndTreasuryAndInjectorAddresses(
//         address _operatorAddress,
//         address _treasuryAddress,
//         address _injectorAddress
//     ) external onlyOwner {
//         require(_operatorAddress != address(0), "Cannot be zero address");
//         require(_treasuryAddress != address(0), "Cannot be zero address");
//         require(_injectorAddress != address(0), "Cannot be zero address");

//         operatorAddress = _operatorAddress;
//         treasuryAddress = _treasuryAddress;
//         injectorAddress = _injectorAddress;

//         emit NewOperatorAndTreasuryAndInjectorAddresses(_operatorAddress, _treasuryAddress, _injectorAddress);
//     }

//     /**
//      * @notice Calculate price of a set of tickets
//      * @param _discountDivisor: divisor for the discount
//      * @param _priceTicket price of a ticket (in CAKE)
//      * @param _numberTickets number of tickets to buy
//      */
//     function calculateTotalPriceForBulkTickets(
//         uint256 _discountDivisor,
//         uint256 _priceTicket,
//         uint256 _numberTickets
//     ) external view returns (uint256) {
//         require(_discountDivisor >= MIN_DISCOUNT_DIVISOR, "Must be >= MIN_DISCOUNT_DIVISOR");
//         require(_numberTickets != 0, "Number of tickets must be > 0");

//         return _calculateTotalPriceForBulkTickets(_discountDivisor, _priceTicket, _numberTickets);
//     }

//     /**
//      * @notice View current lottery id
//      */
//     function viewCurrentLotteryId() external view returns (uint256) {
//         return currentLotteryId;
//     }

//     /**
//      * @notice View lottery information
//      * @param _lotteryId: lottery id
//      */
//     function viewLottery(address _lotteryId) external view returns (Lottery memory) {
//         return _lotteries[_lotteryId];
//     }

//     /**
//      * @notice View ticker statuses and numbers for an array of ticket ids
//      * @param _ticketIds: array of _ticketId
//      */
//     function viewNumbersAndStatusesForTicketIds(uint256[] calldata _ticketIds)
//         external
//         view
//         returns (uint32[] memory, bool[] memory)
//     {
//         uint256 length = _ticketIds.length;
//         uint32[] memory ticketNumbers = new uint32[](length);
//         bool[] memory ticketStatuses = new bool[](length);

//         for (uint256 i = 0; i < length; i++) {
//             ticketNumbers[i] = _tickets[_ticketIds[i]].number;
//             if (_tickets[_ticketIds[i]].owner == address(0)) {
//                 ticketStatuses[i] = true;
//             } else {
//                 ticketStatuses[i] = false;
//             }
//         }

//         return (ticketNumbers, ticketStatuses);
//     }

//     /**
//      * @notice View rewards for a given ticket, providing a bracket, and lottery id
//      * @dev Computations are mostly offchain. This is used to verify a ticket!
//      * @param _lotteryId: lottery id
//      * @param _ticketId: ticket id
//      * @param _bracket: bracket for the ticketId to verify the claim and calculate rewards
//      */
//     function viewRewardsForTicketId(
//         address _lotteryId,
//         uint256 _ticketId,
//         uint32 _bracket
//     ) external view returns (uint256) {
//         // Check lottery is in claimable status
//         if (_lotteries[_lotteryId].status != Status.Claimable) {
//             return 0;
//         }

//         // Check ticketId is within range
//         if (
//             (_lotteries[_lotteryId].firstTicketIdNextLottery < _ticketId) &&
//             (_lotteries[_lotteryId].firstTicketId >= _ticketId)
//         ) {
//             return 0;
//         }

//         return _calculateRewardsForTicketId(_lotteryId, _ticketId, _bracket);
//     }

//     /**
//      * @notice View user ticket ids, numbers, and statuses of user for a given lottery
//      * @param _user: user address
//      * @param _lotteryId: lottery id
//      * @param _cursor: cursor to start where to retrieve the tickets
//      * @param _size: the number of tickets to retrieve
//      */
//     function viewUserInfoForLotteryId(
//         address _user,
//         address _lotteryId,
//         uint256 _cursor,
//         uint256 _size
//     )
//         external
//         view
//         returns (
//             uint256[] memory,
//             uint32[] memory,
//             bool[] memory,
//             uint256
//         )
//     {
//         uint256 length = _size;
//         uint256 numberTicketsBoughtAtLotteryId = _userTicketIdsPerLotteryId[_user][_lotteryId].length;

//         if (length > (numberTicketsBoughtAtLotteryId - _cursor)) {
//             length = numberTicketsBoughtAtLotteryId - _cursor;
//         }

//         uint256[] memory lotteryTicketIds = new uint256[](length);
//         uint32[] memory ticketNumbers = new uint32[](length);
//         bool[] memory ticketStatuses = new bool[](length);

//         for (uint256 i = 0; i < length; i++) {
//             lotteryTicketIds[i] = _userTicketIdsPerLotteryId[_user][_lotteryId][i + _cursor];
//             ticketNumbers[i] = _tickets[lotteryTicketIds[i]].number;

//             // True = ticket claimed
//             if (_tickets[lotteryTicketIds[i]].owner == address(0)) {
//                 ticketStatuses[i] = true;
//             } else {
//                 // ticket not claimed (includes the ones that cannot be claimed)
//                 ticketStatuses[i] = false;
//             }
//         }

//         return (lotteryTicketIds, ticketNumbers, ticketStatuses, _cursor + length);
//     }

//     /**
//      * @notice Calculate rewards for a given ticket
//      * @param _lotteryId: lottery id
//      * @param _ticketId: ticket id
//      * @param _bracket: bracket for the ticketId to verify the claim and calculate rewards
//      */
//     function _calculateRewardsForTicketId(
//         address _lotteryId,
//         uint256 _ticketId,
//         uint32 _bracket
//     ) internal view returns (uint256) {
//         // Retrieve the winning number combination
//         uint32 userNumber = _lotteries[_lotteryId].finalNumber;

//         // Retrieve the user number combination from the ticketId
//         uint32 winningTicketNumber = _tickets[_ticketId].number;

//         // Apply transformation to verify the claim provided by the user is true
//         uint32 transformedWinningNumber = _bracketCalculator[_bracket] +
//             (winningTicketNumber % (uint32(10)**(_bracket + 1)));

//         uint32 transformedUserNumber = _bracketCalculator[_bracket] + (userNumber % (uint32(10)**(_bracket + 1)));

//         // Confirm that the two transformed numbers are the same, if not throw
//         if (transformedWinningNumber == transformedUserNumber) {
//             return _lotteries[_lotteryId].cakePerBracket[_bracket];
//         } else {
//             return 0;
//         }
//     }

//     /**
//      * @notice Calculate final price for bulk of tickets
//      * @param _discountDivisor: divisor for the discount (the smaller it is, the greater the discount is)
//      * @param _priceTicket: price of a ticket
//      * @param _numberTickets: number of tickets purchased
//      */
//     function _calculateTotalPriceForBulkTickets(
//         uint256 _discountDivisor,
//         uint256 _priceTicket,
//         uint256 _numberTickets
//     ) internal pure returns (uint256) {
//         return (_priceTicket * _numberTickets * (_discountDivisor + 1 - _numberTickets)) / _discountDivisor;
//     }

//     /**
//      * @notice Check if an address is a contract
//      */
//     function _isContract(address _addr) internal view returns (bool) {
//         uint256 size;
//         assembly {
//             size := extcodesize(_addr)
//         }
//         return size > 0;
//     }
// }
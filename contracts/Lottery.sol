// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import "./Library.sol";

/** @title Lottery.
 * @notice It is a contract for a lottery system using
 * randomness provided externally.
 */
contract LotteryContract {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 private currentTicketId = 1;

    mapping(uint => EnumerableSet.AddressSet) private _lotteryTokens;
    uint private MINIMUM_REWARD;
    uint256 private MIN_TICKET_NUMBER = 1000000;
    uint256 private TICKET_RANGE = 999999;
    uint256 private treasuryFee = 100; // 1%
    
    address private randomGenerator;
    mapping(uint => mapping(address => uint)) public amountCollected;
    mapping(uint => mapping(address => uint256[6])) public tokenPerBracket;
    
    // Mapping are cheaper than arrays
    mapping(uint256 => Lottery) private _lotteries;
    mapping(uint256 => Ticket) private _tickets;
    
    address private contractAddress;
    mapping(address => mapping(address => uint)) private usedLotteryCredits;
    mapping(address => mapping(bytes32 => uint)) private pendingReward;
    mapping(address => mapping(address => uint)) public toReinject;
    mapping(address => mapping(bytes32 => uint)) private pendingReferrerFee;

    // Bracket calculator is used for verifying claims for ticket prizes
    mapping(uint => uint) private _bracketCalculator;

    // Keeps track of number of ticket per unique combination for each lotteryId
    mapping(uint256 => mapping(uint => uint256)) private _numberTicketsPerLotteryId;
    
    // Keep track of user ticket ids for a given lotteryId
    mapping(address => mapping(uint256 => uint256[])) private _userTicketIdsPerLotteryId;
    
    event LotteryClose(uint256 indexed lotteryId,uint256[6] countWinnersPerBracket);
    event LotteryInjection(uint256 indexed lotteryId, uint256 injectedAmount, address token);
    event LotteryOpen(
        uint lotteryId,
        uint treasuryFee,
        uint referrerFee,
        uint priceTicket,
        uint firstTicketId,
        uint discountDivisor,
        uint startTime,
        uint endTime,
        uint collectionId
    );
    event LotteryNumberDrawn(uint256 indexed lotteryId, uint256 finalNumber, uint256 countWinningTickets);
    event TicketsPurchase(address indexed buyer, uint256 indexed lotteryId, uint256 ticketId, uint256 numberTicket);
    event TicketsClaim(address indexed claimer, address token, uint256 amount, uint256 indexed lotteryId, uint256 ticketId);
    event UpdateMiscellaneous(
        uint idx, 
        uint collectionId, 
        string paramName, 
        string paramValue, 
        uint paramValue2, 
        uint paramValue3, 
        address sender,
        address paramValue4,
        string paramValue5
    );
    
    /**
     * @notice Constructor
     * @dev RandomNumberGenerator must be deployed prior to this contract
     * @param _randomGeneratorAddress: address of the RandomGenerator contract used to work with ChainLink VRF
     */
    constructor(address _randomGeneratorAddress) {
        randomGenerator = _randomGeneratorAddress;

        // Initializes a mapping
        _bracketCalculator[0] = 1;
        _bracketCalculator[1] = 11;
        _bracketCalculator[2] = 111;
        _bracketCalculator[3] = 1111;
        _bracketCalculator[4] = 11111;
        _bracketCalculator[5] = 111111;
    }

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    // function setRandomGenerator(address _randomGenerator) external {
    //     require(IAuth(contractAddress).devaddr_() == msg.sender);
    //     randomGenerator = _randomGenerator;
    // }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }

    function viewNumberTicketsPerLotteryId(uint _lotteryId, uint _winningNumberTransformed) external view returns(uint) {
        return _numberTicketsPerLotteryId[_lotteryId][_winningNumberTransformed];
    }
    
    function emitUpdateMiscellaneous(
        uint _idx, 
        uint _collectionId, 
        string memory paramName, 
        string memory paramValue, 
        uint paramValue2, 
        uint paramValue3,
        address paramValue4,
        string memory paramValue5
    ) external {
        emit UpdateMiscellaneous(
            _idx, 
            _collectionId, 
            paramName, 
            paramValue, 
            paramValue2, 
            paramValue3, 
            msg.sender,
            paramValue4,
            paramValue5
        );
    }

    function getUserTicketIdsPerLotteryId(address _user, uint _lotteryId) external view returns(uint[] memory) {
        return _userTicketIdsPerLotteryId[_user][_lotteryId];
    }

    function getAllTokens(uint _lotteryId, uint _start) external view returns(address[] memory _tokens) {
        _tokens = new address[](_lotteryTokens[_lotteryId].length() - _start);
        for (uint i = _start; i < _lotteryTokens[_lotteryId].length(); i++) {
            _tokens[i] = _lotteryTokens[_lotteryId].at(i);
        }
    }

    function _marketCollections() internal view returns(address) {
        return IContract(contractAddress).marketCollections();
    }
    
    function _getPayment(
        address _user, 
        address _token, 
        address _referrer, 
        uint _lotteryId, 
        uint _lotteryCredits, 
        uint _amountToTransfer
    ) internal returns(uint) {
        // Transfer cake tokens to this contract
        address lotteryHelper = IContract(contractAddress).lotteryHelper();
        uint _paymentCredits = ILottery(lotteryHelper).paymentCredits(_user, _lotteryId);
        if (_amountToTransfer > _lotteryCredits + _paymentCredits) {
            _amountToTransfer -= _lotteryCredits - _paymentCredits;
            usedLotteryCredits[_user][_token] += _lotteryCredits;
            ILottery(lotteryHelper).deletePaymentCredits(_user, _lotteryId);
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amountToTransfer);
            if (_referrer != address(0x0) && _referrer != _user) {
                pendingReferrerFee[_referrer][keccak256(abi.encodePacked(_lotteryId, _token))] += _lotteries[_lotteryId].treasury.referrerFee * _amountToTransfer / 10000;
            }
        } else {
            if (_amountToTransfer < _paymentCredits) {
                ILottery(lotteryHelper).decreasePaymentCredits(_user, _lotteryId, _amountToTransfer);
                _amountToTransfer = 0;
            } else {
                ILottery(lotteryHelper).deletePaymentCredits(_user, _lotteryId);
                _amountToTransfer -= _paymentCredits;
            }
            if (_amountToTransfer < usedLotteryCredits[_user][_token]) {
                usedLotteryCredits[_user][_token] -= _amountToTransfer;
                _amountToTransfer = 0;
            } else {
                usedLotteryCredits[_user][_token] += _amountToTransfer;
                _amountToTransfer = 0;
            }
        }
        if (!_lotteryTokens[_lotteryId].contains(_token)) {
            require(amountCollected[_lotteryId][_token] >= MINIMUM_REWARD, "L01");
            _lotteryTokens[_lotteryId].add(_token);
        }
        // Increment the total amount collected for the lottery round
        amountCollected[_lotteryId][_token] += _amountToTransfer;
        
        return _amountToTransfer;
    }

    /**
     * @notice Buy tickets for the current lottery
     * @param _ticketNumbers: array of ticket numbers between 1,000,000 and 1,999,999
     * @dev Callable by users
     */
    function buyWithContract(
        address _collection, 
        address _user, 
        address _referrer, 
        string memory _lotteryName, 
        uint256 _nfticketId, 
        uint256 _identityTokenId, 
        uint[] calldata _ticketNumbers
    )
        external
        lock
    {
        (uint _lotteryId,) = ILottery(IContract(contractAddress).lotteryHelper()).checkIdentity(_collection, _user, _nfticketId, _identityTokenId, _ticketNumbers);
        // Calculate number of CAKE to this contract
        (uint256 amountToTransfer, uint256 _lotteryCredits, address _token) = calculateTotalPriceForBulkTickets(
            _ticketNumbers.length,
            _lotteryId,
            _nfticketId,
            _user
        );
        amountToTransfer = _getPayment(
            _user, 
            _token, 
            _referrer, 
            _lotteryId, 
            _lotteryCredits, 
            amountToTransfer
        );
        for (uint256 i = 0; i < _ticketNumbers.length; i++) {
            uint thisTicketNumber = _ticketNumbers[i];

            require((thisTicketNumber >= MIN_TICKET_NUMBER) && (thisTicketNumber <= MIN_TICKET_NUMBER+TICKET_RANGE), "L6");

            _numberTicketsPerLotteryId[_lotteryId][1 + (thisTicketNumber % 10)]++;
            _numberTicketsPerLotteryId[_lotteryId][11 + (thisTicketNumber % 100)]++;
            _numberTicketsPerLotteryId[_lotteryId][111 + (thisTicketNumber % 1000)]++;
            _numberTicketsPerLotteryId[_lotteryId][1111 + (thisTicketNumber % 10000)]++;
            _numberTicketsPerLotteryId[_lotteryId][11111 + (thisTicketNumber % 100000)]++;
            _numberTicketsPerLotteryId[_lotteryId][111111 + (thisTicketNumber % 1000000)]++;
            
            _userTicketIdsPerLotteryId[_user][_lotteryId].push(currentTicketId);
            _tickets[currentTicketId] = Ticket({number: thisTicketNumber, owner: _user});
    
            emit TicketsPurchase(_user, _lotteryId, currentTicketId, thisTicketNumber);

            // Increase lottery ticket number
            currentTicketId++;
        }
    }

    function updateLotteryVariables(
        uint _newMinTicketNumber,
        uint _newTicketRange,
        uint _newMaxTreasuryFee,
        uint _minReward
    ) external {
        require(msg.sender == IAuth(contractAddress).devaddr_());
        MIN_TICKET_NUMBER = _newMinTicketNumber;
        TICKET_RANGE = _newTicketRange;
        MINIMUM_REWARD = _minReward;
        treasuryFee = _newMaxTreasuryFee;
    }
    
    /**
     * @notice Claim a set of winning tickets for a lottery
     * @param _lotteryId: lottery id
     * @param _ticketIds: array of ticket ids
     * @param _brackets: array of brackets for the ticket ids
     * @dev Callable by users only, not contract!
     */
    function claimTickets(
        uint256 _lotteryId,
        uint256[] calldata _ticketIds,
        uint[] calldata _brackets
    ) external lock {
        require(_ticketIds.length == _brackets.length, "L7");
        require(_ticketIds.length <= IContract(contractAddress).maximumSize(), "L8");
        require(_lotteries[_lotteryId].status == LotteryStatus.Claimable, "L10");
        address lotteryHelper = IContract(contractAddress).lotteryHelper();

        for (uint j = 0; j < _lotteryTokens[_lotteryId].length(); j++) {
            address _token = _lotteryTokens[_lotteryId].at(j);
            for (uint256 i = 0; i < _ticketIds.length; i++) {
                require(_brackets[i] < 6, "L11"); // Must be between 0 and 5

                uint256 thisTicketId = _ticketIds[i];

                require(_lotteries[_lotteryId].firstTicketId <= thisTicketId, "L12");
                require(msg.sender == _tickets[thisTicketId].owner);

                // Update the lottery ticket owner to 0x address
                _tickets[thisTicketId].owner = address(0);
                uint256 rewardForTicketId = ILottery(lotteryHelper).calculateRewardsForTicketId(_lotteryId, thisTicketId, _brackets[i], _token);

                // Check user is claiming the correct bracket
                require(rewardForTicketId != 0, "L14");

                if (_brackets[i] != 5) {
                    require(
                        ILottery(lotteryHelper).calculateRewardsForTicketId(_lotteryId, thisTicketId, _brackets[i] + 1, _token) == 0,
                        "L15"
                    );
                }
                // Transfer money to msg.sender
                pendingReward[msg.sender][keccak256(abi.encodePacked(_lotteryId, _token))] += rewardForTicketId;
                
                emit TicketsClaim(msg.sender, _token, rewardForTicketId, _lotteryId, thisTicketId);
            }
        }
    }

    function getPendingReward(uint _lotteryId, address _user, address _token, bool _referrer) external view returns(uint) {
        if (!_referrer) {
            return pendingReward[_user][keccak256(abi.encodePacked(_lotteryId, _token))];
        }
        return pendingReferrerFee[_user][keccak256(abi.encodePacked(_lotteryId, _token))];
    }

    /**
     * @notice Close lottery
     * @param _lotteryId: lottery id
     * @dev Callable by operator
     */
    function closeLottery(uint256 _lotteryId, uint _tokenId) external {
        require(_lotteries[_lotteryId].status == LotteryStatus.Open, "L16");
        require(
            block.timestamp > _lotteries[_lotteryId].endTime ||
            (   _lotteries[_lotteryId].endAmount > 0 &&
                amountCollected[_lotteryId][_lotteryTokens[_lotteryId].at(_tokenId)] >= _lotteries[_lotteryId].endAmount), 
            "L17"
        );
        ILottery(randomGenerator).getRandomNumber(_lotteryId);
        _lotteries[_lotteryId].status = LotteryStatus.Close;

        emit LotteryClose(_lotteryId, _lotteries[_lotteryId].countWinnersPerBracket);
    }

    /**
     * @notice Draw the final number, calculate reward in CAKE per group, and make lottery claimable
     * @param _lotteryId: lottery id
     * @dev Callable by operator
     */
    function drawFinalNumberAndMakeLotteryClaimable(uint256 _lotteryId)
        external
        lock
    {
        require(_lotteries[_lotteryId].status == LotteryStatus.Close, "L18");

        // Calculate the finalNumber based on the randomResult generated by ChainLink's fallback
        uint finalNumber = ILottery(randomGenerator).viewRandomResult(_lotteryId);

        // Initialize a number to count addresses in the previous bracket
        uint256 numberAddressesInPreviousBracket;

        for (uint k = 0; k < _lotteryTokens[_lotteryId].length(); k++) {
            address _token = _lotteryTokens[_lotteryId].at(k);
            // Calculate the amount to share post-treasury fee
            uint256 amountToShareToWinners = (
                (amountCollected[_lotteryId][_token] * (10000 - _lotteries[_lotteryId].treasury.fee))
            ) / 10000;
            // Initializes the amount to withdraw to treasury
            uint256 amountToWithdrawToTreasury;

            // Calculate prizes in CAKE for each bracket by starting from the highest one
            for (uint i = 0; i < 6; i++) {
                uint j = 5 - i;
                uint transformedWinningNumber = _bracketCalculator[j] + (finalNumber % (uint(10)**(j + 1)));

                _lotteries[_lotteryId].countWinnersPerBracket[j] =
                    _numberTicketsPerLotteryId[_lotteryId][transformedWinningNumber] -
                    numberAddressesInPreviousBracket;

                // A. If number of users for this _bracket number is superior to 0
                if (
                    (_numberTicketsPerLotteryId[_lotteryId][transformedWinningNumber] - numberAddressesInPreviousBracket) != 0
                ) {
                    // B. If rewards at this bracket are > 0, calculate, else, report the numberAddresses from previous bracket
                    if (_lotteries[_lotteryId].rewardsBreakdown[j] != 0) {
                        tokenPerBracket[_lotteryId][_token][j] = 
                            ((_lotteries[_lotteryId].rewardsBreakdown[j] * amountToShareToWinners) /
                                (_numberTicketsPerLotteryId[_lotteryId][transformedWinningNumber] -
                                    numberAddressesInPreviousBracket)) / 10000;

                        // Update numberAddressesInPreviousBracket
                        numberAddressesInPreviousBracket = _numberTicketsPerLotteryId[_lotteryId][transformedWinningNumber];
                    }
                    // A. No CAKE to distribute, they are added to the amount to withdraw to treasury address
                } else {
                    tokenPerBracket[_lotteryId][_token][j] = 0;

                    amountToWithdrawToTreasury +=
                        (_lotteries[_lotteryId].rewardsBreakdown[j] * amountToShareToWinners) / 10000;
                }
            }

            amountToWithdrawToTreasury += (amountCollected[_lotteryId][_token] - amountToShareToWinners);

            // Transfer token to admin address
            toReinject[_lotteries[_lotteryId].owner][_token] += amountToWithdrawToTreasury;
        }
        // Update internal statuses for lottery
        _lotteries[_lotteryId].finalNumber = finalNumber;
        _lotteries[_lotteryId].status = LotteryStatus.Claimable;

        emit LotteryNumberDrawn(_lotteryId, finalNumber, numberAddressesInPreviousBracket);
    }

    function withdrawPendingReward(address _token, uint _lotteryId, uint _identityTokenId) external lock {
        uint _pendingReward = pendingReward[msg.sender][keccak256(abi.encodePacked(_lotteryId, _token))];
        pendingReward[msg.sender][keccak256(abi.encodePacked(_lotteryId, _token))] = 0;
        uint _fee1 = _pendingReward * _lotteries[_lotteryId].treasury.fee / 10000;
        uint _fee2 = _pendingReward * treasuryFee / 10000;
        pendingReward[_lotteries[_lotteryId].owner][keccak256(abi.encodePacked(_lotteryId, _token))] += _fee1;
        pendingReward[IAuth(contractAddress).devaddr_()][keccak256(abi.encodePacked(_lotteryId, _token))] += _fee2;
        _pendingReward -=  (_fee1 + _fee2);
        if (_lotteries[_lotteryId].valuepool != address(0x0)) {
            address _ve = IValuePool(_lotteries[_lotteryId].valuepool)._ve();
            erc20(_token).approve(_ve, _pendingReward);
            IValuePool(_ve).create_lock_for(
                _pendingReward,
                _lotteries[_lotteryId].lockDuration,
                _identityTokenId,
                msg.sender
            );
        } else {
            IERC20(_token).safeTransfer(msg.sender, _pendingReward);
        }
    }

    function withdrawTreasury(uint _lotteryId, address _token) external lock {
        require(_lotteries[_lotteryId].owner == msg.sender || IAuth(contractAddress).devaddr_() == msg.sender);
        IERC20(_token).safeTransfer(msg.sender, pendingReward[msg.sender][keccak256(abi.encodePacked(_lotteryId, _token))]);
        pendingReward[msg.sender][keccak256(abi.encodePacked(_lotteryId, _token))] = 0;
    }

    function withrawReferrerFee(uint _lotteryId, address _token) external lock {
        uint _pendingReward = pendingReferrerFee[msg.sender][keccak256(abi.encodePacked(_lotteryId, _token))];
        require(pendingReward[_lotteries[_lotteryId].owner][keccak256(abi.encodePacked(_lotteryId, _token))] >= _pendingReward);
        pendingReferrerFee[msg.sender][keccak256(abi.encodePacked(_lotteryId, _token))] = 0;
        IERC20(_token).safeTransfer(msg.sender, _pendingReward);
    }

    /**
     * @notice Inject funds
     * @param _lotteryId: lottery id
     * @param _amount: amount to inject in CAKE token
     * @dev Callable by owner or injector address
     */
    function injectFunds(uint256 _lotteryId, uint256 _amount, address _token, bool _reinject) external lock {
        require(_lotteries[_lotteryId].status == LotteryStatus.Open);
        if (_reinject) {
            _amount = toReinject[_lotteries[_lotteryId].owner][_token];
            toReinject[_lotteries[_lotteryId].owner][_token] = 0;
        } else {
            IERC20(_token).safeTransferFrom(address(msg.sender), address(this), _amount);
        }
        if (amountCollected[_lotteryId][_token] + _amount >= MINIMUM_REWARD) {
            address marketHelpers3 = IContract(contractAddress).marketHelpers3();
            require(
                IMarketPlace(marketHelpers3).dTokenSetContains(_token) ||
                IMarketPlace(marketHelpers3).veTokenSetContains(_token)
            );
            _lotteryTokens[_lotteryId].add(_token);
        }
        amountCollected[_lotteryId][_token] += _amount;

        emit LotteryInjection(_lotteryId, _amount, _token);
    }

    function claimLotteryRevenue(uint256 _lotteryId, address _token) external {
        require(_lotteries[_lotteryId].status == LotteryStatus.Open, "L21");
        address _marketTrades = IContract(contractAddress).marketTrades();
        address _paywallMarketTrades = IContract(contractAddress).paywallMarketTrades();
        address _nftMarketTrades = IContract(contractAddress).nftMarketTrades();
        uint _amount = IMarketPlace(_marketTrades).lotteryRevenue(_token);
        _amount += IMarketPlace(_paywallMarketTrades).lotteryRevenue(_token);
        _amount += IMarketPlace(_nftMarketTrades).lotteryRevenue(_token);
        
        IMarketPlace(_marketTrades).claimLotteryRevenue(_token);
        IMarketPlace(_paywallMarketTrades).claimLotteryRevenue(_token);
        IMarketPlace(_nftMarketTrades).claimLotteryRevenue(_token);

        require(IMarketPlace(_marketTrades).lotteryRevenue(_token) == 0);
        require(IMarketPlace(_paywallMarketTrades).lotteryRevenue(_token) == 0);
        require(IMarketPlace(_nftMarketTrades).lotteryRevenue(_token) == 0);
        
        if (amountCollected[_lotteryId][_token] + _amount >= MINIMUM_REWARD) {
            _lotteryTokens[_lotteryId].add(_token);
        }
        amountCollected[_lotteryId][_token] += _amount;
    }
    
    function claimLotteryRevenueFomSponsors(uint256 _lotteryId) external {
        require(_lotteries[_lotteryId].status == LotteryStatus.Open, "L22");
        address nfticketHelper = IContract(contractAddress).nfticketHelper();
        address _token = IMarketPlace(nfticketHelper).token();
        uint _amount = IMarketPlace(nfticketHelper).lottery();
        IMarketPlace(nfticketHelper).claimLotteryRevenue();
        require(IMarketPlace(nfticketHelper).lottery() == 0);
        
        if (amountCollected[_lotteryId][_token] + _amount >= MINIMUM_REWARD) {
            _lotteryTokens[_lotteryId].add(_token);
        }
        amountCollected[_lotteryId][_token] += _amount;
    }

    function startLottery(
        address _owner,
        address _valuepool,
        uint256 _currentLotteryId,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _endAmount,
        uint256 _lockDuration,
        uint256 _collectionId,
        bool _useNFTicket,
        uint256[4] calldata _values, //_treasuryFee, _referrerFee, _priceTicket, _discountDivisor
        uint256[6] calldata _rewardsBreakdown
    ) external {
        require(IContract(contractAddress).lotteryHelper() == msg.sender, "L022");
        _lotteries[_currentLotteryId] = Lottery({
            status: LotteryStatus.Open,
            startTime: _startTime,
            endTime: _endTime,
            endAmount: _endAmount,
            owner: _owner,
            discountDivisor: _values[3],
            rewardsBreakdown: _rewardsBreakdown,
            countWinnersPerBracket: [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)],
            firstTicketId: currentTicketId,
            valuepool: _valuepool,
            lockDuration: _lockDuration,
            treasury: Treasury({
                fee: _values[0],
                referrerFee: _values[1],
                useNFTicket: _useNFTicket,
                priceTicket: _values[2]
            }),
            finalNumber: 0
        });
        emit LotteryOpen(
            _currentLotteryId,
            _values[0],
            _values[1],
            _values[2],
            currentTicketId,
            _values[3],
            _startTime,
            _endTime,
            _collectionId
        );
    }

    /**
     * @notice View lottery information
     * @param _lotteryId: lottery id
     */
    function viewLottery(uint256 _lotteryId) external view returns (Lottery memory) {
        return _lotteries[_lotteryId];
    }

    /**
     * @notice View ticket information
     * @param _ticketId: ticket id
     */
    function viewTicket(uint256 _ticketId) external view returns (Ticket memory) {
        return _tickets[_ticketId];
    }

    function viewBracketCalculator(uint _braket) external view returns(uint) {
        return _bracketCalculator[_braket];
    }

    /**
     * @notice Calculate final price for bulk of tickets
     * @param _numberTickets: number of tickets purchased
     */
    function calculateTotalPriceForBulkTickets(
        uint256 _numberTickets,
        uint256 _lotteryId,
        uint256 _nfticketId,
        address _user
    ) public view returns (uint256 _price,uint256 _lotteryCredits,address _token) {
        uint256 _discountDivisor = _lotteries[_lotteryId].discountDivisor;
        if (_lotteries[_lotteryId].treasury.useNFTicket) {
            TicketInfo memory _data = INFTicket(IContract(contractAddress).nfticket()).getTicketInfo(_nfticketId);
            _lotteryCredits = IMarketPlace(IContract(contractAddress).nfticketHelper()).lotteryCredits(_user, _data.token);
            _lotteryCredits -= usedLotteryCredits[_user][_data.token];
            _token = _data.token;
        } else {
            _token = _lotteryTokens[_lotteryId].length() != 0 ? _lotteryTokens[_lotteryId].at(_nfticketId) : IContract(contractAddress).token();
        }
        _price = (_lotteries[_lotteryId].treasury.priceTicket * _numberTickets * (_discountDivisor + 1 - _numberTickets)) / _discountDivisor;
        if (_price > _lotteryCredits) {
            _price -= _lotteryCredits;
        } else {
            _lotteryCredits -= _price;
            _price = 0;
        }
    }
}

contract LotteryHelper {
    using SafeERC20 for IERC20;

    uint256 public currentLotteryId;
    mapping(uint => Credit[]) public burnTokenForCredit;
    mapping(address => mapping(uint => uint)) public paymentCredits;
    address public contractAddress;
    uint256 private maxNumberTicketsPerBuyOrClaim = 100;
    uint256 private minLengthLottery = 4 hours - 5 minutes; // 4 hours
    uint256 public treasuryFee = 100; // 1%
    uint256 public minDiscountDivisor = 300;
    mapping(uint => uint) public collectionIdToLotteryId;
    
    function updateParams(
        uint _treasuryFee,
        uint _minDiscountDivisor,
        uint _minLengthLottery,
        uint _maxNumberTicketsPerBuyOrClaim
    ) external {
        require(IAuth(contractAddress).devaddr_() == msg.sender, "PMHHH3");
        treasuryFee = _treasuryFee;
        minLengthLottery = _minLengthLottery;
        minDiscountDivisor = _minDiscountDivisor;
        maxNumberTicketsPerBuyOrClaim = _maxNumberTicketsPerBuyOrClaim;
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender, "PMHHH3");
        contractAddress = _contractAddress;
    }

    function _checkParams(address lotteryAddress) internal view {
        uint _collectionId = IMarketPlace(_marketCollections()).addressToCollectionId(msg.sender);
        Lottery memory _lottery = ILottery(lotteryAddress).viewLottery(currentLotteryId);
        require(_collectionId > 0, "L23");
        require(
            (_lottery.status == LotteryStatus.Pending) || (_lottery.status == LotteryStatus.Claimable),
            "L24"
        );
    }

    function withdrawPendingRewardFromLottery(uint _lotteryId, uint _identityTokenId) external {
        address lotteryAddress = IContract(contractAddress).lotteryAddress();
        address[] memory _tokens = ILottery(lotteryAddress).getAllTokens(_lotteryId, 0);
        for (uint k = 0; k < _tokens.length; k++) {
            ILottery(lotteryAddress).withdrawPendingReward(_tokens[k], _lotteryId, _identityTokenId);
        }
    }

    /**
     * @notice Start the lottery
     * @dev Callable by operator
     * @param _endTime: endTime of the lottery
     * @param _rewardsBreakdown: breakdown of rewards per bracket (must sum to 10,000)
     */
    function startLottery(
        address _owner,
        address _valuepool,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _endAmount,
        uint256 _lockDuration,
        bool _useNFTicket,
        uint256[4] calldata _values, //_treasuryFee, _referrerFee, _priceTicket,_discountDivisor
        uint256[6] calldata _rewardsBreakdown
    ) external {
        address lotteryAddress = IContract(contractAddress).lotteryAddress();
        _checkParams(lotteryAddress);
        require(_values[0] >= _values[1] && _values[0] + treasuryFee <= 10000, "L25");
        if (_endTime < minLengthLottery) _endTime = minLengthLottery;
        require(_values[3] >= minDiscountDivisor, "L27");
        require(
            (_rewardsBreakdown[0] +
                _rewardsBreakdown[1] +
                _rewardsBreakdown[2] +
                _rewardsBreakdown[3] +
                _rewardsBreakdown[4] +
                _rewardsBreakdown[5]) == 10000,
            "L28"
        );
        currentLotteryId++;
        uint _collectionId = IMarketPlace(_marketCollections()).addressToCollectionId(msg.sender);
        collectionIdToLotteryId[_collectionId] = currentLotteryId;
        ILottery(lotteryAddress).startLottery(
            _owner,
            _valuepool,
            currentLotteryId,
            block.timestamp + _startTime,
            block.timestamp + _endTime,
            _endAmount,
            _lockDuration,
            _collectionId,
            _useNFTicket,
            _values,
            _rewardsBreakdown
        );
    }

    function decreasePaymentCredits(address _user, uint _lotteryId, uint _amount) external {
        require(msg.sender == IContract(contractAddress).lotteryAddress());
        paymentCredits[_user][_lotteryId] -= _amount;
    }

    function deletePaymentCredits(address _user, uint _lotteryId) external {
        require(msg.sender == IContract(contractAddress).lotteryAddress());
        paymentCredits[_user][_lotteryId] = 0;
    }

    function updateBurnTokenForCredit(
        address _token,
        address _checker,
        address _destination,
        uint _discount, 
        uint __collectionId,
        bool _clear,
        string memory _item
    ) external {
        uint _collectionId = IMarketPlace(_marketCollections()).addressToCollectionId(msg.sender);
        if(_clear) delete burnTokenForCredit[_collectionId];
        burnTokenForCredit[_collectionId].push(Credit({
            token: _token,
            item: _item,
            checker: _checker,
            discount: _discount,
            destination: _destination,
            collectionId: __collectionId
        }));
    }

    function _marketCollections() internal view returns(address) {
        return IContract(contractAddress).marketCollections();
    }

    function checkIdentity(
        address _collection,
        address _user,
        uint _nfticketId, 
        uint _identityTokenId,
        uint[] calldata _ticketNumbers
    ) external returns(uint _lotteryId, uint _merchantId) {
        address lotteryAddress = IContract(contractAddress).lotteryAddress();
        uint _collectionId = IMarketPlace(_marketCollections()).addressToCollectionId(_collection);
        _merchantId = _collectionId;
        IMarketPlace(IContract(contractAddress).marketHelpers2()).checkPartnerIdentityProof(_collectionId, _identityTokenId, _user);
        _lotteryId = collectionIdToLotteryId[_collectionId];
        Lottery memory _lottery = ILottery(lotteryAddress).viewLottery(_lotteryId);
        if (_lottery.treasury.useNFTicket) {
            require(ve(IContract(contractAddress).nfticketHelper2()).ownerOf(_nfticketId) == _user, "L1");
            TicketInfo memory _data = INFTicket(IContract(contractAddress).nfticket()).getTicketInfo(_nfticketId);
            _merchantId = _data.merchant;
        }
        require(_ticketNumbers.length != 0, "L2");
        require(_ticketNumbers.length <= maxNumberTicketsPerBuyOrClaim, "L3");
        require(_lottery.status == LotteryStatus.Open, "L4");
        require(block.timestamp < _lottery.endTime, "L5");
        return (_lotteryId, _merchantId);
    }

    function burnForCredit(
        address _collection, 
        uint _position, 
        uint256 _number  // tokenId in case of NFTs and amount otherwise 
    ) external {
        address lotteryAddress = IContract(contractAddress).lotteryAddress();
        uint _collectionId = IMarketPlace(_marketCollections()).addressToCollectionId(_collection);
        uint _lotteryId = collectionIdToLotteryId[_collectionId];
        address _destination = burnTokenForCredit[_collectionId][_position].destination == lotteryAddress 
        ? msg.sender : burnTokenForCredit[_collectionId][_position].destination;
        uint credit;
        if (burnTokenForCredit[_collectionId][_position].checker == address(0x0)) { //FT
            IERC20(burnTokenForCredit[_collectionId][_position].token).safeTransferFrom(msg.sender, _destination, _number);
            credit = burnTokenForCredit[_collectionId][_position].discount * _number / 10000;
        } else { //NFT
            uint _times = IMarketPlace(burnTokenForCredit[_collectionId][_position].checker).verifyNFT(
                _number,  
                burnTokenForCredit[_collectionId][_position].collectionId,
                burnTokenForCredit[_collectionId][_position].item
            );
            IERC721(burnTokenForCredit[_collectionId][_position].token).safeTransferFrom(msg.sender, _destination, _number);
            credit = burnTokenForCredit[_collectionId][_position].discount * _times / 10000;
        }
        paymentCredits[msg.sender][_lotteryId] += credit;
    }

    function onERC721Received(address,address,uint256,bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector; 
    }

    /**
     * @notice View user ticket ids, numbers, and statuses of user for a given lottery
     * @param _user: user address
     * @param _lotteryId: lottery id
     * @param _cursor: cursor to start where to retrieve the tickets
     * @param length: the number of tickets to retrieve
     */
    function viewUserInfoForLotteryId(
        address _user,
        uint256 _lotteryId,
        uint256 _cursor,
        uint256 length
    )
        external
        view
        returns (
            uint256[] memory lotteryTicketIds,
            uint[] memory ticketNumbers,
            bool[] memory ticketStatuses,
            uint256
        )
    {
        address lotteryAddress = IContract(contractAddress).lotteryAddress();
        uint numberTicketsBoughtAtLotteryId = ILottery(lotteryAddress).getUserTicketIdsPerLotteryId(_user,_lotteryId).length;

        if (length > (numberTicketsBoughtAtLotteryId - _cursor)) {
            length = numberTicketsBoughtAtLotteryId - _cursor;
        }

        lotteryTicketIds = new uint256[](length);
        ticketNumbers = new uint[](length);
        ticketStatuses = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            lotteryTicketIds[i] = ILottery(lotteryAddress).getUserTicketIdsPerLotteryId(_user,_lotteryId)[i + _cursor];
            Ticket memory _ticket = ILottery(lotteryAddress).viewTicket(lotteryTicketIds[i]);
            ticketNumbers[i] = _ticket.number;

            // True = ticket claimed
            if (_ticket.owner == address(0)) {
                ticketStatuses[i] = true;
            } else {
                // ticket not claimed (includes the ones that cannot be claimed)
                ticketStatuses[i] = false;
            }
        }

        return (lotteryTicketIds, ticketNumbers, ticketStatuses, _cursor + length);
    }

    /**
     * @notice View ticker statuses and numbers for an array of ticket ids
     * @param _ticketIds: array of _ticketId
     */
    function viewNumbersAndStatusesForTicketIds(uint256[] calldata _ticketIds)
        external
        view
        returns (uint[] memory, bool[] memory)
    {
        uint256 length = _ticketIds.length;
        uint[] memory ticketNumbers = new uint[](length);
        bool[] memory ticketStatuses = new bool[](length);
        address lotteryAddress = IContract(contractAddress).lotteryAddress();
        for (uint256 i = 0; i < length; i++) {
            Ticket memory _ticket = ILottery(lotteryAddress).viewTicket(_ticketIds[i]);
            ticketNumbers[i] = _ticket.number;
            if (_ticket.owner == address(0)) {
                ticketStatuses[i] = true;
            } else {
                ticketStatuses[i] = false;
            }
        }

        return (ticketNumbers, ticketStatuses);
    }

    /**
     * @notice View rewards for a given ticket, providing a bracket, and lottery id
     * @dev Computations are mostly offchain. This is used to verify a ticket!
     * @param _lotteryId: lottery id
     * @param _ticketId: ticket id
     * @param _bracket: bracket for the ticketId to verify the claim and calculate rewards
     */
    function viewRewardsForTicketId(
        uint256 _lotteryId,
        uint256 _ticketId,
        uint _bracket,
        address _token
    ) external view returns (uint256) {
        // Check lottery is in claimable status
        address lotteryAddress = IContract(contractAddress).lotteryAddress();
        Lottery memory _lottery = ILottery(lotteryAddress).viewLottery(_lotteryId);
        if (_lottery.status != LotteryStatus.Claimable) {
            return 0;
        }

        // Check ticketId is within range
        if (
            _lottery.firstTicketId >= _ticketId
        ) {
            return 0;
        }

        return calculateRewardsForTicketId(_lotteryId, _ticketId, _bracket, _token);
    }

    /**
     * @notice Calculate rewards for a given ticket
     * @param _lotteryId: lottery id
     * @param _ticketId: ticket id
     * @param _bracket: bracket for the ticketId to verify the claim and calculate rewards
     */
    function calculateRewardsForTicketId(
        uint256 _lotteryId,
        uint256 _ticketId,
        uint _bracket,
        address _token
    ) public view returns (uint256) {
        address lotteryAddress = IContract(contractAddress).lotteryAddress();
        // Retrieve the winning number combination
        uint userNumber = ILottery(lotteryAddress).viewLottery(_lotteryId).finalNumber;

        // Retrieve the user number combination from the ticketId
        uint winningTicketNumber = ILottery(lotteryAddress).viewTicket(_ticketId).number;
        uint _bracketValue = ILottery(lotteryAddress).viewBracketCalculator(_bracket);
        // Apply transformation to verify the claim provided by the user is true
        uint transformedWinningNumber = _bracketValue +(winningTicketNumber % (uint(10)**(_bracket + 1)));

        uint transformedUserNumber = _bracketValue + (userNumber % (uint(10)**(_bracket + 1)));

        // Confirm that the two transformed numbers are the same, if not throw
        if (transformedWinningNumber == transformedUserNumber) {
            return ILottery(lotteryAddress).tokenPerBracket(_lotteryId, _token, _bracket);
        } else {
            return 0;
        }
    }

}

contract RandomNumberGenerator is VRFConsumerBase, Ownable {
    using SafeERC20 for IERC20;

    address public lotteryAddress;
    address public contractAddress;
    bytes32 public keyHash;
    mapping(bytes32 => uint) public latestTokenId;
    mapping(uint => uint) private randomResult;
    uint public fee;
    // mapping(uint => uint) public fulfilled;
    // bool public freeRequests;
    uint TEST_CHAIN = 31337;
    uint nextRandomResult;

    /**
     * @notice Constructor
     * @dev RandomNumberGenerator must be deployed before the lottery
     * https://docs.chain.link/docs/vrf-contracts/
     * @param _vrfCoordinator: address of the VRF coordinator
     * @param _linkToken: address of the LINK token
     */
    constructor(
        address _vrfCoordinator, 
        address _linkToken,
        address _contractAddress
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        contractAddress = _contractAddress;
    }

    function setLotteryAddress(address _lotteryAddress) external {
        require(IAuth(contractAddress).devaddr_() == msg.sender);
        lotteryAddress = _lotteryAddress;
    }

    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    // used only for testing
    function setNextRandomResult(uint256 _nextRandomResult) external onlyOwner {
        nextRandomResult = _nextRandomResult;
    }

    /**
     * @notice Request randomness from a user-provided seed
     */
    function getRandomNumber(uint256 _lotteryId) external {
        require(msg.sender == lotteryAddress, "Only lottery");
        if (getChainID() != TEST_CHAIN && getChainID() != 4002) {
            require(keyHash != bytes32(0), "Must have valid key hash");
            require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK tokens");
            latestTokenId[requestRandomness(keyHash, fee)] = _lotteryId;
        }
    }

    /**
     * @notice Change the fee
     * @param _fee: new fee (in LINK)
     */
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    /**
     * @notice Change the keyHash
     * @param _keyHash: new keyHash
     */
    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    /**
     * @notice It allows the admin to withdraw tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev Only callable by owner.
     */
    function withdrawTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
    }

    function addFee(uint256 _tokenAmount) external {
        IERC20(address(LINK)).safeTransferFrom(address(msg.sender), address(this), _tokenAmount == 0 ? fee : _tokenAmount);
    }

    /**
     * @notice View random result
     */
    function viewRandomResult(uint _lotteryId) external view returns (uint) {
        if (getChainID() == TEST_CHAIN || getChainID() == 4002) {
            return 1000000 + (nextRandomResult % 1000000);
        }
        require(randomResult[_lotteryId] != 0, "random result is null");
        return randomResult[_lotteryId];
    }
    
    /**
     * @notice Callback function used by ChainLink's VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(latestTokenId[requestId] != 0 , "Wrong requestId");
        randomResult[latestTokenId[requestId]] = 1000000 + (randomness % 1000000);
        delete latestTokenId[requestId];
    }
}
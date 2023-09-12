// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import "./Library.sol";

contract GameFactory {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    // Storage for ticket information
    struct GameInfo {
        address owner;
        address token;
        address gameContract;
        uint pricePerMinutes;
        uint teamShare;
        uint creatorShare;
        uint referrerFee;
        uint numPlayers;
        uint totalScore;
        uint totalPaid;
        bool claimable;
    }
    mapping(uint => uint) private attachedTokenId;
    mapping(uint => mapping(uint => uint)) public paidPayable;
    // game => object int => object string
    mapping(uint => mapping(uint => string)) private objectStrings;
    // game ID => Token information 
    mapping(uint => GameInfo) public ticketInfo_;
    EnumerableSet.UintSet internal tickets;
    // User address =>  Ticket IDs
    // mapping(token ID => mapping(game ID => deadline))
    mapping(uint => mapping(uint => uint)) public userDeadLines_;
    uint private teamShare = 100;
    uint private minPricePerMinutes;
    mapping(address => bool) private isWhitelisted;
    mapping(address => uint) public treasury;
    mapping(address => mapping(address => uint)) public pendingRevenue;
    mapping(address => uint) public addressToCollectionId;
    mapping(uint => Credit[]) public burnTokenForCredit;
    mapping(address => mapping(uint => uint)) public paymentCredits;
    mapping(uint => uint) public totalEarned;
    uint private collectionId = 1;
    uint private minPoolSizeB4Delete;
    address private contractAddress;
    //-------------------------------------------------------------------------
    // EVENTS
    //-------------------------------------------------------------------------

    event AddProtocol(
        address indexed user, 
        address token,
        address gameContract,
        uint pricePerMinutes, 
        uint creatorShare,
        uint referrerFee,
        uint teamShare,
        uint collectionId,
        bool claimable
    );
    event UpdateProtocol(
        address owner,
        address gameContract,
        uint collectionId,
        uint pricePerMinutes,
        uint creatorShare,
        uint referrerFee,
        uint teamShare,
        bool claimable
    );
    event DeleteGame(uint collectionId);
    event UpdateTokenId(uint collectionId, uint tokenId);
    event UpdateOwner(uint collectionId, address owner);
    event BuyGameTicket(address indexed user, uint collectionId, uint tokenId, uint numMinute);
    event MintObject(
        uint collectionId,
        string objectName,
        uint[] tokenIds
    );
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
    event UpdateScore(
        uint collectionId, 
        uint tokenId, 
        uint score, 
        uint userFee
    );

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    //-------------------------------------------------------------------------
    // VIEW FUNCTIONS
    //-------------------------------------------------------------------------
    function getTickets() external view returns(uint[] memory _tickets) {
        _tickets = new uint[](tickets.length());
        for (uint i = 0; i < tickets.length(); i++) {
            _tickets[i] = tickets.at(i);
        }
    }

    function burnTokenForCreditLength(uint _collectionId) external view returns(uint) {
        return burnTokenForCredit[_collectionId].length;
    }
    //-------------------------------------------------------------------------
    // STATE MODIFYING FUNCTIONS 
    //-------------------------------------------------------------------------
    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }

    function updateWhitelist(address _token, bool _whitelist) external {
        require(IAuth(contractAddress).devaddr_() == msg.sender);
        isWhitelisted[_token] = _whitelist;
    }

    function updateMinPoolSizeB4Delete(uint _minPoolSizeB4Delete) external {
        require(IAuth(contractAddress).devaddr_() == msg.sender);
        minPoolSizeB4Delete = _minPoolSizeB4Delete;
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

    function addProtocol(
        address _token,
        address _gameContract,
        uint _pricePerMinutes, 
        uint _creatorShare,
        uint _referrerFee,
        bool _claimable
    ) external {
        require(_pricePerMinutes >= minPricePerMinutes
        , "GF1"
        );
        require(_creatorShare + _referrerFee + teamShare <= 10000
        , "GF2"
        );
        require(isWhitelisted[_token], "GF02");
        // checkIdentityProof(msg.sender, false);
        uint _collectionId = IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(msg.sender);
        require(_collectionId > 0, "GF3");
        ticketInfo_[_collectionId] = GameInfo({
            owner: msg.sender,
            gameContract: _gameContract,
            pricePerMinutes: _pricePerMinutes,
            token: _token,
            teamShare: teamShare,
            creatorShare: _creatorShare,
            referrerFee: _referrerFee,
            totalPaid: 0,
            numPlayers: 0,
            totalScore: 0,
            claimable: _claimable
        });
        tickets.add(_collectionId);
        addressToCollectionId[msg.sender] = _collectionId;
        
        emit AddProtocol(
            msg.sender,
            _token, 
            _gameContract,
            _pricePerMinutes,
            _creatorShare,
            _referrerFee,
            teamShare, 
            _collectionId,
            _claimable
        );
    }

    function updateProtocol(
        address _owner, 
        address _gameContract,
        uint _pricePerMinutes, 
        uint _creatorShare,
        uint _referrerFee,
        bool _claimable
    ) external {
        uint _collectionId = IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(_owner);
        require(_pricePerMinutes > minPricePerMinutes, "GF4");
        require(ticketInfo_[_collectionId].owner == msg.sender, "GF5");
        require(_creatorShare + _referrerFee + teamShare <= 10000, "GF6");
        require(_collectionId > 0);
        ticketInfo_[_collectionId].owner = _owner;
        ticketInfo_[_collectionId].gameContract = _gameContract;
        ticketInfo_[_collectionId].pricePerMinutes = _pricePerMinutes;
        ticketInfo_[_collectionId].creatorShare = _creatorShare;
        ticketInfo_[_collectionId].referrerFee = _referrerFee;
        ticketInfo_[_collectionId].claimable = _claimable;
        ticketInfo_[_collectionId].teamShare = teamShare;
        addressToCollectionId[_owner] = _collectionId;

        emit UpdateProtocol(
            _owner,
            _gameContract,
            _collectionId,
            _pricePerMinutes,
            _creatorShare,
            _referrerFee,
            teamShare,
            _claimable
        );
    }
    
    function deleteGame(uint _collectionId) external {
        require(tickets.contains(_collectionId) && ticketInfo_[_collectionId].owner == msg.sender, "GF7");
        require(ticketInfo_[_collectionId].totalPaid - totalEarned[_collectionId] <= minPoolSizeB4Delete, "GF8");
        treasury[ticketInfo_[_collectionId].token] += ticketInfo_[_collectionId].totalPaid - totalEarned[_collectionId];
        tickets.remove(_collectionId);
        delete addressToCollectionId[ticketInfo_[_collectionId].owner];
        delete ticketInfo_[_collectionId];

        emit DeleteGame(_collectionId);
    }

    function updateTokenId(uint _tokenId, uint _collectionId) external {
        require(ve(IContract(contractAddress).gameHelper()).ownerOf(_tokenId) == ticketInfo_[_collectionId].owner, "GF9");
        attachedTokenId[_collectionId] = _tokenId;
        emit UpdateTokenId(_collectionId, _tokenId);
    }

    function updateOwner(uint _collectionId) external {
        require(ve(IContract(contractAddress).gameHelper()).ownerOf(attachedTokenId[_collectionId]) == msg.sender, "GF10");
        ticketInfo_[_collectionId].owner = msg.sender;
        addressToCollectionId[msg.sender] = _collectionId;

        emit UpdateOwner(_collectionId, msg.sender);
    }

    // function createGamingNFT(address _to, uint _collectionId) external {
    //     IGameNFT(IContract(contractAddress).gameMinter()).mint(_to, _collectionId);
    // }
    
    /**
     * @param   _tokenId The token's ID
     * @param   _numMinutes The number of minutes to buy
     */
    function buyWithContract(
        address _collection, 
        address _user,
        address _referrer,
        string memory _reason, 
        uint _tokenId, 
        uint _identityTokenId, 
        uint[] memory _numMinutes
    ) external {   
        uint _collectionId = addressToCollectionId[_collection];
        IMarketPlace(IContract(contractAddress).marketHelpers2()).checkPartnerIdentityProof(_collectionId, _identityTokenId, _user);
        uint _price = ticketInfo_[_collectionId].pricePerMinutes * _numMinutes[0];
        address gameMinter = IContract(contractAddress).gameMinter();
        (,,address _ticketGame,,,uint _deadline,,,,,,) = IGameNFT(gameMinter).gameInfo_(_tokenId);
        ticketInfo_[_collectionId].numPlayers += _ticketGame == address(0x0) ? 1 : 0;
        require(_referrer != _user, "GF010");
        _processPayments(_collection, _user, _referrer, _price);
        IGameNFT(gameMinter).updatePricePercentile(_collectionId, _tokenId, _price);
        IGameNFT(gameMinter).updateGameContract(
            _user, 
            ticketInfo_[_collectionId].gameContract, 
            _tokenId, 
            _numMinutes[0],
            _price, 
            0
        );
        userDeadLines_[_tokenId][_collectionId] = block.timestamp + _numMinutes[0];
        emit BuyGameTicket(_user, _collectionId, _tokenId, _numMinutes[0]);
    }

    function _processPayments(address _collection, address _user, address _referrer, uint _price) internal {
        uint _collectionId = addressToCollectionId[_collection];
        if (paymentCredits[_user][_collectionId] > _price) {
            paymentCredits[_user][_collectionId] -= _price;
            _price = 0;
        } else {
            _price -= paymentCredits[_user][_collectionId];
            paymentCredits[_user][_collectionId] = 0;
        }
        uint adminFee = ticketInfo_[_collectionId].creatorShare * _price / 10000;
        uint teamFee = ticketInfo_[_collectionId].teamShare * _price / 10000;
        uint referrerFee = _referrer == address(0x0) ? 0 : ticketInfo_[_collectionId].referrerFee * _price / 10000;
        pendingRevenue[_collection][ticketInfo_[_collectionId].token] += adminFee;
        pendingRevenue[IAuth(contractAddress).devaddr_()][ticketInfo_[_collectionId].token] += teamFee;
        pendingRevenue[_referrer][ticketInfo_[_collectionId].token] += referrerFee;
        _price -= (adminFee + teamFee + referrerFee);
        IERC20(ticketInfo_[_collectionId].token).safeTransferFrom(msg.sender, address(this), _price);
        ticketInfo_[_collectionId].totalPaid += _price;
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
        uint _collectionId = addressToCollectionId[msg.sender];
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

    function burnForCredit(
        address _collection, 
        uint _position, 
        uint256 _number  // tokenId in case of NFTs and amount otherwise 
    ) external {
        uint _collectionId = addressToCollectionId[_collection];
        address _destination = burnTokenForCredit[_collectionId][_position].destination == address(this) 
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
        paymentCredits[msg.sender][_collectionId] += credit;
    }

    function claimGameTicket(address _collection, uint _identityTokenId, uint _tokenId) external lock {
        uint _collectionId = addressToCollectionId[_collection];
        require(ve(IContract(contractAddress).gameHelper()).ownerOf(_tokenId) == msg.sender, "GF11");
        (,,address _game,,uint _score,uint _deadline,,,,,,) = IGameNFT(IContract(contractAddress).gameMinter()).gameInfo_(_tokenId);
        require(userDeadLines_[_tokenId][_collectionId] > _deadline && _deadline != 0, "GF13");
        require(_game == ticketInfo_[_collectionId].gameContract);
        IMarketPlace(IContract(contractAddress).marketHelpers2()).checkUserIdentityProof(_collectionId, _identityTokenId, msg.sender);
        _claim(_game, _collectionId, _tokenId, _score);
    }
    
    function _claim(address _game, uint _collectionId, uint _tokenId, uint _score) internal {
        address gameMinter = IContract(contractAddress).gameMinter();
        require(ticketInfo_[_collectionId].claimable, "GF12");
        delete userDeadLines_[_tokenId][_collectionId];
        ticketInfo_[_collectionId].totalScore += _score;
        uint _userFee = ticketInfo_[_collectionId].totalPaid * _score / ticketInfo_[_collectionId].totalScore;  
        _userFee -= paidPayable[_collectionId][_tokenId];
        paidPayable[_collectionId][_tokenId] += _userFee;
        _processTx(_tokenId, _collectionId, _userFee);
        totalEarned[_collectionId] += _userFee;
        IGameNFT(gameMinter).updateScorePercentile(_collectionId, _tokenId, _score);        
        IGameNFT(gameMinter).updateGameContract(msg.sender, _game, _tokenId, 0, 0, _userFee);
        emit UpdateScore(_collectionId, _tokenId, _score, _userFee);
    }

    function _processTx(uint _tokenId, uint _collectionId, uint _userFee) internal {
        address _destination = IGameNFT(IContract(contractAddress).gameHelper2()).isContract(_tokenId);
        if (_destination != address(0x0)) {
            erc20(ticketInfo_[_collectionId].token).approve(_destination, _userFee);
            IARP(_destination).notifyReward(ticketInfo_[_collectionId].token, _userFee);
        } else {
            IERC20(ticketInfo_[_collectionId].token).safeTransfer(msg.sender, _userFee);
        }
    }

    function claimPendingRevenue(address _token) external lock {
        IERC20(_token).safeTransfer(address(msg.sender), pendingRevenue[msg.sender][_token]);
        pendingRevenue[msg.sender][_token] = 0;
    }

    function emitMintObject(
        uint _CollectionId, 
        string memory _objectName,
        uint[] memory _tokenIds
    ) external {
        require(IContract(contractAddress).gameHelper() == msg.sender);
        emit MintObject(
            _CollectionId,
            _objectName,
            _tokenIds
        );
    }

    function withdrawNonFungible(address _token, uint _tokenId) external {
        require(IAuth(contractAddress).devaddr_() == msg.sender);
        IERC721(_token).safeTransferFrom(address(this), address(msg.sender), _tokenId);
    }

    function withdrawFungible(address _token, uint _amount) external {
        require(IAuth(contractAddress).devaddr_() == msg.sender);
        uint amount = Math.min(_amount, treasury[_token]);
        treasury[_token] -= amount;
        IERC20(_token).safeTransferFrom(address(this), address(msg.sender), amount);
    }
    //-------------------------------------------------------------------------
    // INTERNAL FUNCTIONS 
    //-------------------------------------------------------------------------
    function onERC721Received(address,address,uint256,bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector; 
    }
}

contract GameMinter {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using Percentile for *; 

    uint public tokenId = 1;
    mapping(uint => uint) public tokenIdToCollectionId;
    mapping(uint => uint) public pendingRevenue;
    address private contractAddress;
    address private valuepoolAddress;
    uint public treasury;
    uint public valuepool;
    uint public totalSupply_;
    mapping(uint => uint) private price_sum_of_diff_squared;
    mapping(uint => uint) private score_sum_of_diff_squared;
    struct GameNFT {
        address owner;
        address lender;
        address game;
        uint timer;
        uint score;
        uint deadline;
        uint pricePercentile;
        uint price;
        uint won;
        uint gameCount;
        uint scorePercentile;
        uint gameMinutes;
    }
    mapping(address => EnumerableSet.UintSet) private userTickets_;
    mapping(uint256 => GameNFT) public gameInfo_;
    mapping(uint => bool) public attached;
    mapping(uint => uint) public used;
    mapping(uint => uint) public maxUse;

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    modifier onlyAdmin () {
        require(IAuth(contractAddress).devaddr_() == msg.sender);
        _;
    }
    
    function updateValuepool(address _valuepoolAddress) external onlyAdmin {
        valuepoolAddress = _valuepoolAddress;
    }

    function _ve() external view returns(address) {
        return address(this); // to enable lenders to use the arp to distribute rewards
    }

    function getUserPercentile(uint _tokenId) external view returns(uint) {
        return sqrt(
            gameInfo_[_tokenId].scorePercentile * gameInfo_[_tokenId].scorePercentile -
            gameInfo_[_tokenId].pricePercentile * gameInfo_[_tokenId].pricePercentile
        );
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function getReceiver(uint _tokenId) public view returns(address) {
        return gameInfo_[_tokenId].lender == address(0x0) ?
        gameInfo_[_tokenId].owner : gameInfo_[_tokenId].lender;
    }
    
    function updateAfterSponsorPayment(uint _gameProfileId, uint _price, address _user) external {
        require(IContract(contractAddress).gameHelper2() == msg.sender);
        uint valuepoolShare = IContract(contractAddress).valuepoolShare();
        uint adminShare = IContract(contractAddress).adminShare();
        IERC20(IContract(contractAddress).token()).safeTransferFrom(_user, address(this), _price);
        pendingRevenue[_gameProfileId] += _price * (10000 - adminShare - valuepoolShare) / 10000;
        valuepool += _price * valuepoolShare / 10000;
        if (_gameProfileId > 0) {
            treasury += _price * adminShare / 10000;
            
        } else {
            treasury += _price * (10000 - valuepoolShare) / 10000;
        }
    }

    function updateGameContract(
        address _to, 
        address _gameContract, 
        uint _tokenId, 
        uint _minutes, 
        uint _price,
        uint _reward
    ) external {
        if (gameInfo_[_tokenId].deadline > gameInfo_[_tokenId].gameMinutes) {
            gameInfo_[_tokenId].score = 0;
        }
        require(IContract(contractAddress).gameFactory() == msg.sender);
        if (_gameContract != address(0x0)) {
            require(!IGameNFT(IContract(contractAddress).gameHelper()).blacklistedTickets(_tokenId));
        }
        require(getReceiver(_tokenId) == _to, "GM4");
        gameInfo_[_tokenId].gameCount += gameInfo_[_tokenId].game == address(0x0) ? 1 : 0;
        gameInfo_[_tokenId].game = _gameContract;
        if (gameInfo_[_tokenId].gameMinutes == 0) {
            gameInfo_[_tokenId].gameMinutes = block.timestamp + _minutes;
        } else {
            gameInfo_[_tokenId].gameMinutes += _minutes;
        }
        gameInfo_[_tokenId].price = _price;
        gameInfo_[_tokenId].won += _reward;
    }

    function updateScoreNDeadline(uint _tokenId, uint _score, uint _deadline) external {
        require(msg.sender == gameInfo_[_tokenId].game, "GM5");
        address gameHelper = IContract(contractAddress).gameHelper();
        require(!IGameNFT(gameHelper).blacklist(msg.sender), "GM6");
        gameInfo_[_tokenId].score = _score;
        gameInfo_[_tokenId].deadline = _deadline == 0 ? block.timestamp : _deadline;
    }
    
    function updatePricePercentile(uint _collectionId, uint _tokenId, uint _value) external {
        require(IContract(contractAddress).gameFactory() == msg.sender);
         (,,,,,,,uint numPlayers,,uint totalPaid,) = IGameNFT(IContract(contractAddress).gameFactory()).ticketInfo_(_collectionId);
        (uint percentile, uint sodq) = Percentile.computePercentileFromData(
            false,
            _value,
            totalPaid + _value,
            numPlayers,
            price_sum_of_diff_squared[_collectionId]
        );
        price_sum_of_diff_squared[_collectionId] = sodq;
        gameInfo_[_tokenId].pricePercentile = percentile;
    }

    function updateScorePercentile(uint _collectionId, uint _tokenId, uint _value) external {
        require(IContract(contractAddress).gameFactory() == msg.sender);
         (,,,,,,,uint numPlayers,uint totalScore,,) = IGameNFT(IContract(contractAddress).gameFactory()).ticketInfo_(_collectionId);
        // score
        (uint percentile2, uint sodq2) = Percentile.computePercentileFromData(
            false,
            _value,
            totalScore + _value,
            numPlayers,
            score_sum_of_diff_squared[_collectionId]
        );
        score_sum_of_diff_squared[_collectionId] = sodq2;
        gameInfo_[_tokenId].scorePercentile = percentile2;
        
    }

    function attach(uint256 _tokenId, uint256 _period, address _lender) external { 
        //can be used for collateral for lending
        require(gameInfo_[_tokenId].owner == msg.sender, "GM7");
        require(!attached[_tokenId], "GM8");
        attached[_tokenId] = true;
        gameInfo_[_tokenId].lender = _lender;
        gameInfo_[_tokenId].timer = block.timestamp + _period;
    }

    function detach(uint _tokenId) external {
        require(gameInfo_[_tokenId].timer <= block.timestamp, "GM9");
        attached[_tokenId] = false;
        gameInfo_[_tokenId].lender = address(0);
        gameInfo_[_tokenId].timer = 0;   
    }

    function killTimer(uint256 _tokenId) external {
        require(gameInfo_[_tokenId].lender == msg.sender, "GM10");
        gameInfo_[_tokenId].timer = 0;
    }

    function decreaseTimer(uint256 _tokenId, uint256 _timer) external {
        require(gameInfo_[_tokenId].lender == msg.sender, "GM11");
        gameInfo_[_tokenId].timer -= _timer;
    }

    function getAllTokenIds(address _user, uint _start) external view returns(uint[] memory _tokenIds) {
        _tokenIds = new uint[](userTickets_[_user].length() - _start);
        for (uint i = _start; i < userTickets_[_user].length(); i++) {
            _tokenIds[i] = userTickets_[_user].at(i);
        }
    }

    function claimPendingRevenue() external lock {
        uint _gameProfileId = IGameNFT(IContract(contractAddress).gameFactory()).addressToCollectionId(msg.sender);
        IERC20(IContract(contractAddress).token()).safeTransfer(address(msg.sender), pendingRevenue[_gameProfileId]);
        pendingRevenue[_gameProfileId] = 0;
    }

    function withdrawTreasury(address _token, uint _amount) external lock {
        address token = IContract(contractAddress).token();
        address devaddr_ = IAuth(contractAddress).devaddr_();
        _token = _token == address(0x0) ? token : _token;
        uint _price = _amount == 0 ? treasury : Math.min(_amount, treasury);
        if (_token == token) {
            treasury -= _price;
            IERC20(_token).safeTransfer(devaddr_, _price);
        } else {
            IERC20(_token).safeTransfer(devaddr_, erc20(_token).balanceOf(address(this)));
        }
    }

    function claimValuepoolRevenue() external {
        require(msg.sender == IAuth(contractAddress).devaddr_(), "GM16");
        IERC20(IContract(contractAddress).token()).safeTransfer(valuepoolAddress, valuepool);
        valuepool = 0;
    }
    
    function updateMaxUse(uint _maxUse) external {
        maxUse[IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(msg.sender)] = _maxUse;
    }

    function mint(address _to, uint _collectionId) external returns(uint) {
        tokenIdToCollectionId[tokenId] = _collectionId;
        if (maxUse[_collectionId] > 0) {
            address _profile = IContract(contractAddress).profile();
            uint _profileId = IProfile(_profile).addressToProfileId(_to);
            require(IProfile(_profile).isUnique(_profileId), "GM016");
            require(used[_profileId] < maxUse[_collectionId]);
            used[_profileId] += 1;
        }
        IGameNFT(IContract(contractAddress).gameHelper()).safeMint(_to, tokenId);
        gameInfo_[tokenId].owner = _to;
        totalSupply_ += 1;
        userTickets_[_to].add(tokenId);
        IGameNFT(IContract(contractAddress).gameFactory()).emitUpdateMiscellaneous(
            3,
            _collectionId,
            "",
            "",
            tokenId,
            0,
            _to,
            ""
        );
        return tokenId++;
    }

    function burn(uint _tokenId) external {
        require(ve(IContract(contractAddress).gameHelper()).ownerOf(_tokenId) == msg.sender);
        userTickets_[msg.sender].remove(tokenId);
        totalSupply_ -= 1;
        IGameNFT(IContract(contractAddress).gameHelper()).safeBurn(_tokenId);
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }
    
}

contract GameHelper is ERC721Pausable {
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(uint => mapping(uint => string)) private _objects;
    mapping(uint => EnumerableSet.UintSet) private _isObject;
    address private contractAddress;
    mapping(address => bool) public blacklist;
    mapping(uint => bool) public blacklistedTickets;
    mapping(uint => mapping(address => bool)) public isBlacklisted;
    struct Ingredient {
        uint category;
        uint[] ratings;
    }
    // resourceToObject = mapping(gameaddress => mapping(objectsNum => Recipe))
    mapping(uint => mapping(string => Ingredient[])) internal resourceToObject;
    // objectToResource = mapping(gameaddress => mapping(objectsNum => NumRecipeStruct))
    mapping(uint => mapping(string => EnumerableSet.UintSet)) private _protocolObjects;

    constructor() ERC721("GameNFT", "GameNFT")  {}

    modifier onlyAdmin () {
        require(IAuth(contractAddress).devaddr_() == msg.sender);
        _;
    }

    function getResourceToObject(uint _collectionId, uint _idx, string memory _objName) external view returns(Ingredient memory) {
        return resourceToObject[_collectionId][_objName][_idx];
    }

    function resourceToObjectLength(uint _collectionId, string memory _objName) external view returns(uint) {
        return resourceToObject[_collectionId][_objName].length;
    }

    function safeMint(address _to, uint _tokenId) external {
        require(IContract(contractAddress).gameMinter() == msg.sender);
        _safeMint(_to, _tokenId, msg.data);
    }

    function safeBurn(uint _tokenId) external {
        require(IContract(contractAddress).gameMinter() == msg.sender);
        _burn(_tokenId);
    }

    function updateObject(uint _collectionId, string memory _objectName, uint[] memory _tokenIds, uint _add) external {
        (address _owner,,,,,,,,,,) = IGameNFT(IContract(contractAddress).gameFactory()).ticketInfo_(_collectionId);
        require(msg.sender == _owner);
        address auditorHelper = IContract(contractAddress).auditorHelper();
        if (_add > 0) {
            for (uint i = 0; i < _tokenIds.length; i++) {
                (address _auditor,) = IAuditor(auditorHelper).tokenIdToAuditor(_tokenIds[i]);
                uint _category = IAuditor(auditorHelper).categories(_auditor);
                resourceToObject[_collectionId][_objectName].push(Ingredient({
                    category: _category,
                    ratings: IAuditor(_auditor).getProtocolRatings(_tokenIds[i])
                }));
            }
        } else {
            delete resourceToObject[_collectionId][_objectName];
        }
        IGameNFT(IContract(contractAddress).gameFactory()).
        emitUpdateMiscellaneous(
            _add, //0 = remove; 1 = add
            _collectionId,
            _objectName,
            "",
            0,
            0,
            address(0x0),
            ""
        );
    }

    function mintObject(string memory _objectName, uint _collectionId, uint _gameTokenId, uint[] memory _ingredients) external {
        // mints game object to user
        for (uint i = 0; i < _ingredients.length; i++) {
            uint _tokenId = _ingredients[i];
            address auditorHelper = IContract(contractAddress).auditorHelper();
            (address _auditor,) = IAuditor(auditorHelper).tokenIdToAuditor(_tokenId);
            require(!isBlacklisted[_collectionId][_auditor]);
            uint _category = IAuditor(auditorHelper).categories(_auditor);
            require(resourceToObject[_collectionId][_objectName][i].category == _category);
            uint[] memory protocolRatings = IAuditor(_auditor).getProtocolRatings(_tokenId);
            for (uint j = 0; j < resourceToObject[_collectionId][_objectName][i].ratings.length; j++) {
                Ingredient memory _resourceToObject = resourceToObject[_collectionId][_objectName][i];
                require(protocolRatings[j] == _resourceToObject.ratings[j]);
            }
            IERC721(auditorHelper).safeTransferFrom(msg.sender, address(this), _tokenId);
            _protocolObjects[_collectionId][_objectName].add(_tokenId);
        }
        _addObject(_gameTokenId, _objectName); 
        IGameNFT(IContract(contractAddress).gameFactory()).
        emitMintObject(
            _collectionId,
            _objectName,
            _ingredients
        );
    }

    function burnObject(string memory _objectName, uint _collectionId, uint _gameTokenId, address _to) external {
        // burns game object owned by user
        require(ownerOf(_gameTokenId) == msg.sender);
        (bool _exists, uint pos) = isObject(_gameTokenId, _objectName);
        require(_exists);
        uint _tokenId = _protocolObjects[_collectionId][_objectName].at(0);
        _removeObject(_gameTokenId, pos);
        IERC721(IContract(contractAddress).auditorHelper()).safeTransferFrom(address(this), _to, _tokenId);
        _protocolObjects[_collectionId][_objectName].remove(_tokenId);
    }

    function getAllProtocolObjects(uint _collectionId, string memory _objectName, uint _start) external view returns(uint[] memory _tokenIds) {
        // gets all resources added to mint game's object
        _tokenIds = new uint[](_protocolObjects[_collectionId][_objectName].length() - _start);
        for (uint i = _start; i < _protocolObjects[_collectionId][_objectName].length(); i++) {
            _tokenIds[i] = _protocolObjects[_collectionId][_objectName].at(i);
        }
    }

    function updateBlacklist(address[] memory _users, bool _blacklist) external onlyAdmin {
        for (uint i = 0; i < _users.length; i++) {
            blacklist[_users[i]] = _blacklist;
        }
    }

    function updateBlacklistedTicket(uint _collectionId, uint _tokenId, bool _add) external {
        (address _owner,,address gameContract,,,,,,,,) = IGameNFT(IContract(contractAddress).gameFactory()).ticketInfo_(_collectionId);
        require(msg.sender == _owner || msg.sender == gameContract);
        blacklistedTickets[_tokenId] = _add;
    }
    
    function updateBlacklist(uint _collectionId, address _auditor, bool _add) external {
        (address _owner,,address gameContract,,,,,,,,) = IGameNFT(IContract(contractAddress).gameFactory()).ticketInfo_(_collectionId);
        require(msg.sender == _owner || msg.sender == gameContract);
        isBlacklisted[_collectionId][_auditor] = _add;
    }

    function onERC721Received(address,address,uint256,bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector; 
    }
    
    function isObject(uint _tokenId, string memory _objectName) public view returns(bool found,uint k) {
        // checks if object is written on user's game token
        for(uint i = 0; i < _isObject[_tokenId].length(); i++) {
            if (keccak256(abi.encodePacked(_objectName)) == keccak256(abi.encodePacked(_objects[_tokenId][_isObject[_tokenId].at(i)]))) {
                found = true;
                k = i;
                break;
            }
        }
    }

    function _addObject(uint _tokenId, string memory _objectName) internal {
        // write object on user's game token id
        require(IContract(contractAddress).maximumSize() > _isObject[_tokenId].length());
        uint _idx = _isObject[_tokenId].length();
        _objects[_tokenId][_idx] = _objectName;
        _isObject[_tokenId].add(_idx); 
    }

    function getAllObjects(uint _tokenId, uint _start) external view returns(string[] memory _objectNames) {
        // get all objects written on user's game token
      _objectNames = new string[](_isObject[_tokenId].length() - _start);
        for (uint i = _start; i < _isObject[_tokenId].length(); i++) {
            _objectNames[i] = _objects[_tokenId][_isObject[_tokenId].at(i)];
        }  
    }

    function _removeObject(uint _tokenId, uint _idx) internal {
        // erase object name from user's game token
        delete _objects[_tokenId][_idx];
        _isObject[_tokenId].remove(_idx); 
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }
    
    function _getOptions(uint _collectionId, uint _tokenId) internal view returns(string[] memory, string[] memory) {
        (,,,
            uint timer,
            uint score,
            uint deadline,
            uint pricePercentile,
            uint price,
            uint won,
            uint gameCount,
            uint scorePercentile, 
            uint gameMinutes
        ) = IGameNFT(IContract(contractAddress).gameMinter()).gameInfo_(_tokenId);
        uint decimals = uint(IGameNFT(_getToken(_collectionId)).decimals());
        return _populate(
            _collectionId,
            timer,
            score,
            deadline,
            pricePercentile,
            price / decimals,
            won / decimals,
            gameCount,
            scorePercentile,
            gameMinutes
        );
    }

    function _getSymbol(uint _collectionId) internal view returns(string memory symbol) {
        return IGameNFT(_getToken(_collectionId)).symbol();
    }

    function safeTransferNAttach(
        address attachTo,
        uint period,
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) external {
        super.safeTransferFrom(from, to, id, data);
        IGameNFT(IContract(contractAddress).gameMinter()).attach(id, period, attachTo);
    }

    function _populate(
        uint _collectionId, 
        uint _timer,
        uint _score,
        uint _deadline,
        uint _pricePercentile,
        uint _price,
        uint _won,
        uint _gameCount,
        uint _scorePercentile,
        uint _gameMinutes
    ) internal view returns(string[] memory optionNames, string[] memory optionValues) {
        uint idx;
        optionNames = new string[](11);
        optionValues = new string[](11);
        optionNames[idx] = "Game ID";
        optionValues[idx++] = toString(_collectionId);
        optionNames[idx] = "Is Lended";
        optionValues[idx++] = _timer > 0 ? "No" : "Yes";
        if (_timer > 0) {
            optionNames[idx] = "Ends";
            optionValues[idx++] = toString(_timer);
        }
        optionNames[idx] = "Score";
        optionValues[idx++] = toString(_score);
        optionNames[idx] = "Deadline";
        optionValues[idx++] = toString(_deadline);
        optionNames[idx] = "Price Percentile";
        optionValues[idx++] = string(abi.encodePacked(toString(_pricePercentile), "%"));
        optionNames[idx] = "price";
        optionValues[idx++] = string(abi.encodePacked(toString(_price), " ", _getSymbol(_collectionId)));
        optionNames[idx] = "won";
        optionValues[idx++] = string(abi.encodePacked(toString(_won), " ", _getSymbol(_collectionId)));
        optionNames[idx] = "# Players";
        optionValues[idx++] = toString(_gameCount);
        optionNames[idx] = "Score Percentile";
        optionValues[idx++] = string(abi.encodePacked(toString(_scorePercentile), "%"));
        optionNames[idx] = "Minutes";
        optionValues[idx++] = toString(_gameMinutes);
    }

    function _getToken(uint _collectionId) internal view returns(address) {
        (,address _token,,,,,,,,,) = IGameNFT(IContract(contractAddress).gameFactory()).ticketInfo_(_collectionId);
        return _token;
    }

    function tokenURI(uint _tokenId) public view virtual override returns (string memory output) {
        address gameMinter = IContract(contractAddress).gameMinter();
        (,,address _game,,,,,,,,,) = IGameNFT(gameMinter).gameInfo_(_tokenId);
        uint _collectionId = IGameNFT(gameMinter).tokenIdToCollectionId(_tokenId);
        address uriGenerator = IGameNFT(IContract(contractAddress).gameHelper2()).uriGenerator(_collectionId);
        if (uriGenerator != address(0x0)) {
            output = IGameNFT(uriGenerator).uri(_tokenId);
        } else {
            return _tokenURI(
                _tokenId, 
                _collectionId, 
                _game, 
                IGameNFT(IContract(contractAddress).gameHelper2()).getMedia(_tokenId)
            );
        }
    }

    function _tokenURI(uint _tokenId, uint _collectionId, address _game, string[] memory _media) internal view returns (string memory output) {
        (string[] memory optionNames, string[] memory optionValues) = _getOptions(_collectionId, _tokenId);
        output = IMarketPlace(IContract(contractAddress).nftSvg()).constructTokenURI(
            _tokenId,
            '',
            _game,
            _getToken(_collectionId),
            ownerOf(_tokenId),
            IGameNFT(IContract(contractAddress).gameHelper2()).getTaskContract(_tokenId, _collectionId),
            _media,
            optionNames,
            optionValues,
            new string[](1)
        );
    }

    function toString(uint value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

contract GameHelper2 {
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(uint => mapping(string => EnumerableSet.UintSet)) private excludedContents;
    address public contractAddress;
    struct Channel {
        string message;
        uint active_period;
    }
    mapping(uint => mapping(string => Channel)) public channels;
    mapping(uint => mapping(string => bool)) public tagRegistrations;
    mapping(uint => mapping(uint => string)) public tags;
    struct ScheduledMedia {
        uint amount;
        string message;
    }
    uint private maxNumMedia = 3;
    uint internal minute = 3600; // allows minting once per week (reset every Thursday 00:00 UTC)
    uint private currentMediaIdx = 1;
    mapping(uint => address) public destination;
    mapping(uint => uint) public pricePerAttachMinutes;
    mapping(uint => ScheduledMedia) public scheduledMedia;
    mapping(uint => mapping(string => EnumerableSet.UintSet)) private _scheduledMedia;
    mapping(uint => string) private descriptions;
    mapping(uint => address) private taskContract;
    mapping(uint => address) public uriGenerator;

    modifier onlyAdmin () {
        require(IAuth(contractAddress).devaddr_() == msg.sender);
        _;
    }

    function isContract(uint _tokenId) external view returns(address) {
        return destination[_tokenId] == address(0x0) || !_isContract(destination[_tokenId])
        ? address(0x0) 
        : destination[_tokenId];
    }

    function _isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint _size;
        assembly {
            _size := extcodesize(account)
        }
        return _size > 0;
    }

    function updateDestination(uint _tokenId, address _destination) external {
        (address _owner,,,,,,,,,,,) = IGameNFT(IContract(contractAddress).gameMinter()).gameInfo_(_tokenId);
        require(msg.sender == _owner && destination[_tokenId] == address(0x0));
        destination[_tokenId] = _destination;
    }

    function updateUriGenerator(uint _collectionId, address _uriGenerator) external {
        (address _owner,,,,,,,,,,) = IGameNFT(IContract(contractAddress).gameFactory()).ticketInfo_(_collectionId);
        require(msg.sender == _owner);
        uriGenerator[_collectionId] = _uriGenerator;
    }

    function updateTaskContract(uint _collectionId, address _taskContract) external {
        (address _owner,,,,,,,,,,) = IGameNFT(IContract(contractAddress).gameFactory()).ticketInfo_(_collectionId);
        require(msg.sender == _owner);
        taskContract[_collectionId] = _taskContract;
    }

    function updateDescription(uint _collectionId, string memory _description) external {
        (address _owner,,,,,,,,,,) = IGameNFT(IContract(contractAddress).gameFactory()).ticketInfo_(_collectionId);
        require(msg.sender == _owner);
        descriptions[_collectionId] = _description;
    }

    function getDescription(uint _collectionId) external view returns(string[] memory) {
        string[] memory description = new string[](1);
        description[0] = descriptions[_collectionId];
        return description;
    }

    function getTaskContract(uint _tokenId, uint _collectionId) external view returns(address) {
        address _taskContract = taskContract[_collectionId];
        return _taskContract != address(0x0) && IGameNFT(_taskContract).pendingTask(_tokenId)
            ? _taskContract : address(0x0);
    }

    function updateMaxNumMedia(uint _maxNumMedia) external {
        require(IAuth(contractAddress).devaddr_() == msg.sender);
        maxNumMedia = _maxNumMedia;
    }

    function updateExcludedContent(string memory _tag, string memory _contentName, bool _add) external {
        uint _gameProfileId = IGameNFT(IContract(contractAddress).gameFactory()).addressToCollectionId(msg.sender);
        if (_add) {
            require(IContent(contractAddress).contains(_contentName), "GM12");
            excludedContents[_gameProfileId][_tag].add(uint(keccak256(abi.encodePacked(_contentName))));
        } else {
            excludedContents[_gameProfileId][_tag].remove(uint(keccak256(abi.encodePacked(_contentName))));
        }
    }

    function _getExcludedContents(uint _gameProfileId, string memory _tag) internal view returns(string[] memory _excluded) {
        _excluded = new string[](excludedContents[_gameProfileId][_tag].length());
        for (uint i = 0; i < _excluded.length; i++) {
            _excluded[i] = IContent(contractAddress).indexToName(excludedContents[_gameProfileId][_tag].at(i));
        }
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }

    function getMedia(uint _tokenId) public view returns(string[] memory _media) {
        uint _collectionId = IGameNFT(IContract(contractAddress).gameMinter()).tokenIdToCollectionId(_tokenId);
        string memory _tag = tags[_collectionId][_tokenId];
        if (tagRegistrations[_collectionId][_tag]) {
            _media = new string[](_scheduledMedia[1][_tag].length() + 1);
            uint idx;
            for (uint i = 0; i < _scheduledMedia[1][_tag].length(); i++) {
                uint _currentMediaIdx = _scheduledMedia[1][_tag].at(i);
                _media[idx] = scheduledMedia[_currentMediaIdx].message;
            }
        } else {
            _media = new string[](_scheduledMedia[_collectionId][_tag].length() + 1);
            uint idx;
            for (uint i = 0; i < _scheduledMedia[_collectionId][_tag].length(); i++) {
                uint _currentMediaIdx = _scheduledMedia[_collectionId][_tag].at(i);
                _media[idx] = scheduledMedia[_currentMediaIdx].message;
            }
        }
    }

    function updateTagRegistration(string memory _tag, bool _add) external {
        address gameFactory = IContract(contractAddress).gameFactory();
        uint _gameProfileId = IGameNFT(gameFactory).addressToCollectionId(msg.sender);
        tagRegistrations[_gameProfileId][_tag] = _add;
        IGameNFT(gameFactory).emitUpdateMiscellaneous(
            2,
            _gameProfileId,
            _tag,
            "",
            _add ? 1 : 0,
            0,
            address(0x0),
            ""
        );
    }

    function updatePricePerAttachMinutes(uint _pricePerAttachMinutes) external {
        uint _gameProfileId = IGameNFT(IContract(contractAddress).gameFactory()).addressToCollectionId(msg.sender);
        pricePerAttachMinutes[_gameProfileId] = _pricePerAttachMinutes;
    }

    function sponsorTag(
        address _sponsor,
        uint _gameProfileId,
        uint _amount, 
        string memory _tag, 
        string memory _message
    ) external {
        require(IAuth(_sponsor).isAdmin(msg.sender), "GM13");
        require(!ISponsor(_sponsor).contentContainsAny(_getExcludedContents(_gameProfileId, _tag)), "GM14");
        uint _pricePerAttachMinutes = pricePerAttachMinutes[_gameProfileId];
        if (_pricePerAttachMinutes > 0) {
            IGameNFT(IContract(contractAddress).gameMinter()).updateAfterSponsorPayment(
                _gameProfileId,
                _amount * _pricePerAttachMinutes,
                msg.sender
            );
            scheduledMedia[currentMediaIdx] = ScheduledMedia({
                amount: _amount,
                message: _message
            });
            _scheduledMedia[_gameProfileId][_tag].add(currentMediaIdx++);
            updateSponsorMedia(_gameProfileId, _tag);
        }
    }

    function updateSponsorMedia(uint _gameProfileId, string memory _tag) public {
        require(channels[_gameProfileId][_tag].active_period < block.timestamp, "GM15");
        uint idx = _scheduledMedia[_gameProfileId][_tag].at(0);
        channels[_gameProfileId][_tag].active_period = block.timestamp + scheduledMedia[idx].amount*minute / minute * minute;
        channels[_gameProfileId][_tag].message = scheduledMedia[idx].message;
        if (_scheduledMedia[_gameProfileId][_tag].length() > maxNumMedia) {
            _scheduledMedia[_gameProfileId][_tag].remove(idx);
        }
    }
}
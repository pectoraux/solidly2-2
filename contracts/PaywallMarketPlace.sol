
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import "./Library.sol";

contract NFTicket {
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(uint => EnumerableSet.UintSet) private merchantMessages;
    // Token ID => Token information 
    mapping(uint256 => TicketInfo) public ticketInfo_;
    mapping(uint256 => uint) public isPaywall;
    uint256 public ticketID = 1;
    // User address => Merchant address => Ticket IDs
    mapping(address => mapping(uint => uint256[])) private userTickets_;
    uint[] private allTickets_;
    // Merchant address => User address => Ticket IDs
    mapping(uint => mapping(address => uint256[])) private merchantTickets_;
    // Merchant address => Ticket IDs
    mapping(uint => uint256[]) private allMerchantTickets_;
    mapping(uint => address) private uriGenerator;
    uint public adminFee = 1000;
    uint public treasury;
    uint internal INIT_DATE;
    mapping(address => uint) public transactionVolume;
    mapping(uint => address) public taxContracts;
    mapping(uint => uint) public pendingRevenue;
    address private contractAddress;
    mapping(uint => address) public referrer;
    mapping(uint => uint) public userTokenId;
    // channel => set of trusted auditors
    //-------------------------------------------------------------------------
    // EVENTS
    //-------------------------------------------------------------------------

    event InfoMint(
        uint indexed ticketID, 
        address to,
        uint merchant,
        uint price, 
        string item,
        uint[] options,
        Source source
    );
    event SuperChat(address indexed from, uint tokenId, uint time);
    event UpdateActive(uint indexed ticketID, bool active);
    
    constructor() { INIT_DATE = block.timestamp; }

    //-------------------------------------------------------------------------
    // MODIFIERS
    //-------------------------------------------------------------------------
    modifier onlyAdmin() {
        require(msg.sender == IAuth(contractAddress).devaddr_());
        _;
    }

    // simple re-entrancy check 
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }
    
    function getTicketInfo(uint _ticketID) external view returns(TicketInfo memory) {
        return ticketInfo_[_ticketID];
    }

    function getUserTicketsPagination(
        address _user, 
        uint _merchant,
        uint256 first, 
        uint256 last,
        string memory _item
    ) public view returns (uint256[] memory, uint256) {
        uint256 totalPrice;
        uint length;
        first = first < INIT_DATE ? block.timestamp - first : first;
        for (uint256 i = 0; i < userTickets_[_user][_merchant].length; i++) {
            uint256 _ticketID = userTickets_[_user][_merchant][i];
            uint256 date = ticketInfo_[_ticketID].date;
            if (date >= first && date <= last && 
            (keccak256(abi.encodePacked(_item)) == keccak256(abi.encodePacked(ticketInfo_[_ticketID].item)) ||
            keccak256(abi.encodePacked(_item)) == keccak256(abi.encodePacked("")))) length++;
        }
        uint256[] memory values = new uint[](length);
        uint j;
        for (uint256 i = 0; i < userTickets_[_user][_merchant].length; i++) {
            uint256 _ticketID = userTickets_[_user][_merchant][i];
            uint256 date = ticketInfo_[_ticketID].date;
            if (date >= first && date <= last && 
            (keccak256(abi.encodePacked(_item)) == keccak256(abi.encodePacked(ticketInfo_[_ticketID].item)) ||
            keccak256(abi.encodePacked(_item)) == keccak256(abi.encodePacked("")))) {
                totalPrice = totalPrice + ticketInfo_[_ticketID].price;
                values[j] = _ticketID;
                j++;
            }
        }
        return (values, totalPrice);
    }

    function getMerchantTicketsPagination(
        uint _merchant,
        uint256 first, 
        uint256 last,
        string memory _item
    ) 
        public 
        view 
        returns (uint256[] memory, uint256) 
    {
        uint256 totalPrice;
        uint length;
        first = first < INIT_DATE ? block.timestamp - first : first;
        for (uint256 i = 0; i < allMerchantTickets_[_merchant].length; i++) {
            uint256 _ticketID = allMerchantTickets_[_merchant][i];
            uint256 date = ticketInfo_[_ticketID].date;
            if (date >= first && date <= last && 
            (keccak256(abi.encodePacked(_item)) == keccak256(abi.encodePacked(ticketInfo_[_ticketID].item)) ||
            keccak256(abi.encodePacked(_item)) == keccak256(abi.encodePacked("")))) length++;
        }
        uint256[] memory values = new uint[](length);
        uint j;
        for (uint256 i = 0; i < allMerchantTickets_[_merchant].length; i++) {
            uint256 _ticketID = allMerchantTickets_[_merchant][i];
            uint256 date = ticketInfo_[_ticketID].date;
            if (date >= first && date <= last && 
            (keccak256(abi.encodePacked(_item)) == keccak256(abi.encodePacked(ticketInfo_[_ticketID].item)) ||
            keccak256(abi.encodePacked(_item)) == keccak256(abi.encodePacked("")))) {
                totalPrice += ticketInfo_[_ticketID].price;
                values[j] = _ticketID;
                j++;
            }
        }
        return (values, totalPrice);
    }

    function getReceiver(uint _tokenId) public view returns(address) {
        address nfticketHelper2 = IContract(contractAddress).nfticketHelper2();
        return ticketInfo_[_tokenId].lender == address(0) ?
        ve(nfticketHelper2).ownerOf(_tokenId) : ticketInfo_[_tokenId].lender;
    }

    function getTicketsPagination(
        uint256 first, 
        uint256 last
    ) 
        external
        view 
        returns (uint256[] memory) 
    {
        uint length;
        first = first < INIT_DATE ? block.timestamp - first : first;
        for (uint256 i = 0; i < allTickets_.length; i++) {
            uint256 _ticketID = allTickets_[i];
            uint256 date = ticketInfo_[_ticketID].date;
            if (date >= first && date <= last) length++;
        }
        uint256[] memory values = new uint[](length);
        uint j;
        for (uint256 i = 0; i < allTickets_.length; i++) {
            uint256 _ticketID = allTickets_[i];
            uint256 date = ticketInfo_[_ticketID].date;
            if (date >= first && date <= last) {
                values[j] = _ticketID;
                j++;
            }
        }
        return values;
    }
    //-------------------------------------------------------------------------
    // STATE MODIFYING FUNCTIONS 
    //-------------------------------------------------------------------------
    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender, "NT2");
        contractAddress = _contractAddress;
    }

    function _getAskDetails(uint _collectionId, bytes32 _tokenId) internal view returns(Ask memory) {
        address marketOrders = IContract(contractAddress).paywallMarketHelpers() == msg.sender
        ? IContract(contractAddress).paywallMarketOrders()
        : IContract(contractAddress).nftMarketHelpers() == msg.sender
        ? IContract(contractAddress).nftMarketOrders()
        : IContract(contractAddress).marketOrders();
        return IMarketPlace(marketOrders).getAskDetails(_collectionId, _tokenId);
    }

    function _notifyDebit(uint _merchant, address _to, uint _price) internal {
        address marketCollections = IContract(contractAddress).marketCollections();
        Collection memory _collection = IMarketPlace(marketCollections).getCollection(_merchant);
        uint _toCollectionId = IMarketPlace(marketCollections).addressToCollectionId(_to);
        if (taxContracts[_toCollectionId] != address(0x0) && _toCollectionId != 0) {
            IBILL(taxContracts[_toCollectionId]).notifyDebit(_collection.owner, _to, _price);
        }
    }

    function _checkIsPaywall() internal {
        address paywallMarketHelpers = IContract(contractAddress).paywallMarketHelpers();
        address nftMarketHelpers = IContract(contractAddress).nftMarketHelpers();
        address marketHelpers = IContract(contractAddress).marketHelpers();
        require(
            IAuth(contractAddress).devaddr_() == msg.sender || 
            marketHelpers == msg.sender || 
            nftMarketHelpers == msg.sender ||
            paywallMarketHelpers == msg.sender, 
            "NT3"
        );
        isPaywall[ticketID] = paywallMarketHelpers == msg.sender
        ? 1 
        : nftMarketHelpers == msg.sender
        ? 2 : 0;
    }

    function _nfticketHelper() internal view returns(address) {
        return IContract(contractAddress).nfticketHelper();
    }

    function _getToken(uint _merchant, bytes32 _tokenId) internal view returns(address,bool) {
        Ask memory _ask = _getAskDetails(_merchant, _tokenId);
        address _token = _ask.tokenInfo.usetFIAT ? _ask.tokenInfo.tFIAT : ve(_ask.tokenInfo.ve).token();
        return (
            _token,
            _ask.transferrable
        );
    }

    /**
     * @param   _to The address being minted to
     * @notice  Only the lotto contract is able to mint tokens. 
        // uint8[][] calldata _lottoNumbers
     */
    function mint(
        address _to,
        address _referrer,
        uint _merchant,
        string memory _item,
        uint[5] memory _voteParams,
        uint[] memory _options,
        bool _external
    ) external returns(uint) {
        _checkIsPaywall();
        uint _timeEstimate = INFTicket(_nfticketHelper()).getTimeEstimates(
            keccak256(abi.encodePacked(_merchant, _item, msg.sender)), 
            _options
        );
        _notifyDebit(_merchant, _to, _voteParams[4]);
        (address _token, bool _transferrable) = _getToken(_merchant, keccak256(abi.encodePacked(_item)));
        transactionVolume[_token] += _voteParams[4];
        // Storage for the token IDs
        // Incrementing the tokenId counter
        allTickets_.push(ticketID);
        referrer[ticketID] = _referrer;
        userTokenId[ticketID] = _voteParams[0];
        ticketInfo_[ticketID].token = _token;
        ticketInfo_[ticketID].merchant = _merchant;
        ticketInfo_[ticketID].timeEstimate = _timeEstimate;
        ticketInfo_[ticketID].transferrable = _transferrable;
        ticketInfo_[ticketID].item = _item;
        ticketInfo_[ticketID].price = _voteParams[4];
        ticketInfo_[ticketID].active = true;
        ticketInfo_[ticketID].date = block.timestamp;
        ticketInfo_[ticketID].source = _external ? Source.Local : Source.External;
        userTickets_[_to][_merchant].push(ticketID);
        merchantTickets_[_merchant][_to].push(ticketID);
        allMerchantTickets_[_merchant].push(ticketID);
        INFTicket(IContract(contractAddress).nfticketHelper2())
        .safeMint(_merchant, _item, _to, msg.sender, ticketID, msg.data, _options, _external);
        INFTicket(_nfticketHelper()).cancanVote(_to, _item, _merchant, ticketID, msg.sender, _voteParams);
        // Emitting relevant info
        emit InfoMint(
            ticketID, 
            _to, 
            _merchant, 
            _voteParams[4], 
            _item, 
            _options,
            _external ? Source.Local : Source.External
        );
        return ticketID++;
    }

    function updateTaxContract(address _taxContract) external {
        address marketCollections = IContract(contractAddress).marketCollections();
        uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
        taxContracts[_collectionId] = _taxContract;
    }

    function updateAdminFee(uint _adminFee) external onlyAdmin {
        adminFee = _adminFee;
    }

    function superChatAll(string memory _message) external {
        address marketCollections = IContract(contractAddress).marketCollections();
        uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
        batchSuperChat(allMerchantTickets_[_collectionId], _message);
    }

    function messageFromTo(uint _first, uint _last, string memory _item, string memory _message) external {
        address marketCollections = IContract(contractAddress).marketCollections();
        uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
        (uint[] memory _tokenIds,) = getMerchantTicketsPagination(_collectionId, _first, _last, _item);
        batchSuperChat(_tokenIds, _message);
    }

    // used by merchant to message clients
    function batchSuperChat(uint[] memory _tokenIds, string memory _message) public {
        for (uint i = 0; i < _tokenIds.length; i++) {
            superChat(_tokenIds[i], 0, _message);
        }
    }
    
    function superChat(uint _tokenId, uint _amount, string memory _message) internal lock {
        uint _merchant = ticketInfo_[_tokenId].merchant;
        address marketCollections = IContract(contractAddress).marketCollections();
        uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
        require(getReceiver(_tokenId) == msg.sender || _merchant == _collectionId, "NT4");
        if (getReceiver(_tokenId) == msg.sender) {
            require(merchantMessages[_merchant].length() <= IContract(contractAddress).maxMessage(), "NT5");
            require(_amount >= IContract(contractAddress).minSuperChat(), "NT6");
            IARPHelper(_nfticketHelper())._safeTransferFrom(IContract(contractAddress).token(), address(msg.sender), address(this), _amount);
            uint _fee = _amount*adminFee/10000;
            pendingRevenue[_collectionId] += _amount - _fee;
            treasury += _fee;
            merchantMessages[_merchant].add(_tokenId);
            ticketInfo_[_tokenId].superChatOwner = _message;
        } else {
            ticketInfo_[_tokenId].superChatResponse = _message;
            merchantMessages[ticketInfo_[_tokenId].merchant].remove(_tokenId);
        }
        emit SuperChat(msg.sender, _tokenId, block.timestamp);
    }

    function batchUpdateActive(
        address _user, 
        uint256 _merchant,
        uint256 first, 
        uint256 last,
        bool _activate,
        string memory _item
    ) external returns(bool) {
        (uint[] memory _ticketIDs,) = getUserTicketsPagination(_user, _merchant, first, last, _item);
        return batchUpdateActive2(_ticketIDs, _activate);
    }

    function batchUpdateActive2(
        uint[] memory _ticketIDs,
        bool _activate
    ) public returns(bool) {
        for (uint i = 0; i < _ticketIDs.length; i++) {
            updateActive(_ticketIDs[i], _activate);
        }
        return true;
    }

    function updateUriGenerator(address _uriGenerator) external {
        address marketCollections = IContract(contractAddress).marketCollections();
        uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
        uriGenerator[_collectionId] = _uriGenerator;
    }

    function updateActive(uint256 _ticketID, bool _active) internal returns(bool) {
        address marketCollections = IContract(contractAddress).marketCollections();
        uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
        require(
            ticketInfo_[_ticketID].merchant == _collectionId || IAuth(contractAddress).devaddr_() == msg.sender,
            "NT7"
        );

        ticketInfo_[_ticketID].active = _active;
        emit UpdateActive(_ticketID, _active);
        return true;
    }

    function withdrawTreasury(address _token, uint _amount) external onlyAdmin lock {
        // address token = IContract(contractAddress).token();
        address nfticketHelper = _nfticketHelper();
        // _token = _token == address(0x0) ? token : _token;
        uint _price = _amount == 0 ? treasury : Math.min(_amount, treasury);
        if (_token ==  IContract(contractAddress).token()) {
            treasury -= _price;
            IARPHelper(nfticketHelper)._safeTransfer(_token, msg.sender, _price);
        } else {
            IARPHelper(nfticketHelper)._safeTransfer(_token, msg.sender, erc20(_token).balanceOf(address(this)));
        }
    }

    function withdrawRevenue(uint _amount) external lock {
        // address marketCollections = IContract(contractAddress).marketCollections();
        // address nfticketHelper = IContract(contractAddress).nfticketHelper();
        uint _collectionId = IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(msg.sender);
        uint _price = _amount == 0 ? pendingRevenue[_collectionId] : Math.min(_amount, pendingRevenue[_collectionId]);
        pendingRevenue[_collectionId] -= _price;
        IARPHelper(_nfticketHelper())._safeTransfer(IContract(contractAddress).token(), msg.sender, _price);
    }

    // function batchAttach(uint256[] memory _tokenIds, uint256 _period, address _lender) external { 
    //     for (uint8 i = 0; i < _tokenIds.length; i++) {
    //         attach(_tokenIds[i], _period, _lender);
    //     }
    // }

    function attach(uint256 _tokenId, uint256 _period, address _lender) external { 
        address nfticketHelper2 = IContract(contractAddress).nfticketHelper2();
        //can be used for collateral for lending
        require(ve(nfticketHelper2).ownerOf(_tokenId) == msg.sender ||
        ve(nfticketHelper2).ownerOf(_tokenId) == nfticketHelper2, "NT8");
        require(!INFTicket(nfticketHelper2).attached(_tokenId), "NT9");
        INFTicket(nfticketHelper2).updateAttach(_tokenId, true);
        ticketInfo_[_tokenId].lender = _lender;
        ticketInfo_[_tokenId].timer = block.timestamp + _period;
    }

    // function batchDetach(uint256[] memory _tokenIds) external {
    //     for (uint8 i = 0; i < _tokenIds.length; i++) {
    //         detach(_tokenIds[i]);
    //     }
    // }

    function detach(uint _tokenId) external {
        require(ticketInfo_[_tokenId].timer <= block.timestamp, "NT10");
        address nfticketHelper2 = IContract(contractAddress).nfticketHelper2();
        INFTicket(nfticketHelper2).updateAttach(_tokenId, false);
        ticketInfo_[_tokenId].lender = address(0x0);
        ticketInfo_[_tokenId].timer = 0;   
    }

    function killTimer(uint256 _tokenId) external {
        require(ticketInfo_[_tokenId].lender == msg.sender, "NT11");
        ticketInfo_[_tokenId].timer = 0;
    }

    function decreaseTimer(uint256 _tokenId, uint256 _timer) external {
        require(ticketInfo_[_tokenId].lender == msg.sender, "NT12");
        ticketInfo_[_tokenId].timer -= _timer;
    }

    // function withdrawNonFungible(address _token, uint _tokenId) external onlyAdmin {
    //     IERC721(_token).safeTransferFrom(address(this), address(msg.sender), _tokenId);
    // }

    // function withdrawFungible(address _token, uint _amount) external onlyAdmin lock {
    //     _safeTransferFrom(_token, address(this), address(msg.sender), _amount);
    // }
}

contract NFTicketHelper {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    // merchantId => item => tags
    mapping(uint => mapping(string => string)) private tags;
    mapping(uint => address) public taskContracts;
    mapping(uint => mapping(string => EnumerableSet.UintSet)) private _scheduledMedia;
    mapping(uint => mapping(string => bool)) public tagRegistrations;
    uint public adminFee = 100;
    uint public lotteryFee = 1000;
    uint public firstCollectionId = 1;
    uint public treasury;
    uint public lottery;
    struct ScheduledMedia {
        uint amount;
        string message;
    }
    mapping(uint => uint) public pricePerAttachMinutes;
    mapping(uint => ScheduledMedia) public scheduledMedia;
    mapping(uint => uint) public pendingRevenue;
    uint internal minute = 3600; // allows minting once per week (reset every Thursday 00:00 UTC)
    uint public currentMediaIdx = 1;
    uint public maxNumMedia = 3;
    struct Channel {
        string message;
        uint active_period;
    }
    mapping(uint => mapping(string => Channel)) public channels;
    mapping(bytes32 => uint) private itemTimeEstimate;
    mapping(bytes32 => mapping(uint => uint)) private timeEstimates;
    struct Vote {
        uint likes;
        uint dislikes;
    }
    mapping(uint => Vote) public estimateVotes;
    mapping(uint => mapping(uint => int)) public voted;
    mapping(uint => mapping(string => EnumerableSet.UintSet)) private excludedContents;
    address public contractAddress;
    mapping(address => mapping(address => uint)) public lotteryCredits;

    event Voted(uint indexed merchant, uint likes, uint dislikes, bool like);


    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1, "NTH1");
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function addTimeEstimates(string memory _item, bool _isPaywall, uint _itemTimeEstimate, uint[] memory _options, uint[] memory _estimates) external {
        require(_options.length == _estimates.length, "NTH2");
        address marketCollections = IContract(contractAddress).marketCollections();
        uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
        bytes32 _tokenId = keccak256(abi.encodePacked(_collectionId, _item, _isPaywall));
        for (uint i = 0; i < _options.length; i++) {
            timeEstimates[_tokenId][_options[i]] = _estimates[i];
        }
        itemTimeEstimate[_tokenId] = _itemTimeEstimate;
    }

    function getTimeEstimates(bytes32 _tokenId, uint[] memory _options) external view returns(uint _timeEstimate) {
        _timeEstimate = itemTimeEstimate[_tokenId];
        for (uint i = 0; i < _options.length; i++) {
            _timeEstimate += timeEstimates[_tokenId][_options[i]];
        }
    }

    function verifyNFT(uint ticketId, uint merchantId, string memory item) external view returns(uint) {
        TicketInfo memory _ticketInfo = INFTicket(IContract(contractAddress).nfticket()).getTicketInfo(ticketId);
        if (
            _ticketInfo.merchant == merchantId &&
            keccak256(abi.encodePacked(item)) == keccak256(abi.encodePacked(_ticketInfo.item))
            ) {
            return 1;
        }
        return 0;
    }

    function _resetVote(uint _merchant, uint _profileId) internal {
        if (voted[_profileId][_merchant] > 0) {
            estimateVotes[_merchant].likes -= 1;
        } else if (voted[_profileId][_merchant] < 0) {
            estimateVotes[_merchant].dislikes -= 1;
        }
    }
    
    function vote(uint _merchant, uint _profileId, bool like) external {
        require(IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender) == _profileId, "NTH3");
        SSIData memory metadata = ISSI(IContract(contractAddress).ssi()).getSSID(_profileId);
        require(keccak256(abi.encodePacked(metadata.answer)) != keccak256(abi.encodePacked("")), "NTH4");
        _resetVote(_merchant, _profileId);        
        if (like) {
            estimateVotes[_merchant].likes += 1;
            voted[_profileId][_merchant] = 1;
        } else {
            estimateVotes[_merchant].dislikes += 1;
            voted[_profileId][_merchant] = -1;
        }
        emit Voted(
            _merchant, 
            estimateVotes[_merchant].likes, 
            estimateVotes[_merchant].dislikes, 
            like
        );
    }

    function updateTag(string memory _tokenId, string memory _tag) external {
        uint _merchantId = IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(msg.sender);
        tags[_merchantId][_tokenId] = _tag;
        IMarketPlace(IContract(contractAddress).marketPlaceEvents()).emitUpdateMiscellaneous(
            6,
            _merchantId,
            _tokenId,
            _tag,
            0,
            0,
            address(0x0),
            ""
        );
    }
    
    function updateTagRegistration(string memory _tag, bool _add) external {
        uint _merchantId = IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(msg.sender);
        tagRegistrations[_merchantId][_tag] = _add;
        IMarketPlace(IContract(contractAddress).marketPlaceEvents()).emitUpdateMiscellaneous(
            7,
            _merchantId,
            _tag,
            "",
            _add ? 1 : 0,
            0,
            address(0x0),
            ""
        );
    }

    function getSponsorsMedia(uint _merchantId, string memory _tokenId) external view returns(string[] memory _media) {
        string memory _tag = tags[_merchantId][_tokenId];
        if (tagRegistrations[_merchantId][_tag]) {
            _media = new string[](_scheduledMedia[firstCollectionId][_tag].length());
            for (uint i = 0; i < _scheduledMedia[firstCollectionId][_tag].length(); i++) {
                uint _currentMediaIdx = _scheduledMedia[firstCollectionId][_tag].at(i);
                _media[i] = scheduledMedia[_currentMediaIdx].message;
            }
        } else {
            _media = new string[](_scheduledMedia[_merchantId][_tag].length());
            for (uint i = 0; i < _scheduledMedia[_merchantId][_tag].length(); i++) {
                uint _currentMediaIdx = _scheduledMedia[_merchantId][_tag].at(i);
                _media[i] = scheduledMedia[_currentMediaIdx].message;
            }
        }
    }

    function updateExcludedContent(string memory _tag, string memory _contentName, bool _add) external {
        address marketCollections = IContract(contractAddress).marketCollections();
        uint _merchantId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
        if (_add) {
            require(IContent(contractAddress).contains(_contentName), "NTH6");
            excludedContents[_merchantId][_tag].add(uint(keccak256(abi.encodePacked(_contentName))));
        } else {
            excludedContents[_merchantId][_tag].remove(uint(keccak256(abi.encodePacked(_contentName))));
        }
    }

    function claimPendingRevenue() external lock {
        address marketCollections = IContract(contractAddress).marketCollections();
        uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
        IERC20(IContract(contractAddress).token()).safeTransfer(address(msg.sender), pendingRevenue[_collectionId]);
        pendingRevenue[_collectionId] = 0;
    }

    function getExcludedContents(uint _merchantId, string memory _tag) public view returns(string[] memory _excluded) {
        _excluded = new string[](excludedContents[_merchantId][_tag].length());
        for (uint i = 0; i < _excluded.length; i++) {
            _excluded[i] = IContent(contractAddress).indexToName(excludedContents[_merchantId][_tag].at(i));
        }
    }

    function updatePricePerAttachMinutes(uint _pricePerAttachMinutes) external {
        address marketCollections = IContract(contractAddress).marketCollections();
        uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
        pricePerAttachMinutes[_collectionId] = _pricePerAttachMinutes;
    }

    function addTask(address _taskContract) external {
        // used to display forms on the nft
        address marketCollections = IContract(contractAddress).marketCollections();
        uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
        taskContracts[_collectionId] = _taskContract;
    }

    function updateAdminNLotteryFee(
        uint _pricePerAttachMinutes, 
        uint _adminFee,
        uint _lotteryFee,
        uint _maxNumMedia,
        uint _firstCollectionId
    ) external {
        require(msg.sender == IAuth(contractAddress).devaddr_(), "NTH7");
        require(adminFee + lotteryFee <= 10000, "NTH8");
        adminFee = _adminFee;
        lotteryFee = _lotteryFee;
        maxNumMedia = _maxNumMedia;
        firstCollectionId = _firstCollectionId;
        pricePerAttachMinutes[_firstCollectionId] = _pricePerAttachMinutes;
    }
    
    function sponsorTag(
        address _sponsor,
        uint _merchantId, 
        uint _amount, 
        string memory _tag, 
        string memory _message
    ) external {
        require(IAuth(_sponsor).isAdmin(msg.sender), "NTH9");
        require(!ISponsor(_sponsor).contentContainsAny(getExcludedContents(_merchantId, _tag)), "NTH10");
        uint _pricePerAttachMinutes = pricePerAttachMinutes[_merchantId];
        if (_pricePerAttachMinutes > 0) {
            uint price = _amount * _pricePerAttachMinutes;
            _safeTransferFrom(IContract(contractAddress).token(), address(msg.sender), address(this), price);
            lottery += price * lotteryFee / 10000;
            if (_merchantId > 0) {
                treasury += price * adminFee / 10000;
                pendingRevenue[_merchantId] += price * (10000 - adminFee - lotteryFee) / 10000;
            } else {
                treasury += price * (10000 - lotteryFee) / 10000;
            }
            scheduledMedia[currentMediaIdx] = ScheduledMedia({
                amount: _amount,
                message: _message
            });
            _scheduledMedia[_merchantId][_tag].add(currentMediaIdx++);
            updateSponsorMedia(_merchantId, _tag);
        }
    }

    function withdrawTreasury(address _token, uint _amount) external lock {
        address token = IContract(contractAddress).token();
        address devaddr_ = IAuth(contractAddress).devaddr_();
        _token = _token == address(0x0) ? token : _token;
        uint _price = _amount == 0 ? treasury : Math.min(_amount, treasury);
        if (_token == token) {
            treasury -= _price;
            _safeTransfer(_token, devaddr_, _price);
        } else {
            _safeTransfer(_token, devaddr_, erc20(_token).balanceOf(address(this)));
        }
    }

    function claimLotteryRevenue() external {
        address lotteryAddress = IContract(contractAddress).lotteryAddress();
        require(msg.sender == lotteryAddress, "NTH11");
        IERC20(IContract(contractAddress).token()).safeTransfer(msg.sender, lottery);
        lottery = 0;
    }

    function updateSponsorMedia(uint _merchantId, string memory _tag) public {
        require(channels[_merchantId][_tag].active_period < block.timestamp, "NTH12");
        uint idx = _scheduledMedia[_merchantId][_tag].at(0);
        channels[_merchantId][_tag].active_period = block.timestamp + scheduledMedia[idx].amount*minute / minute * minute;
        channels[_merchantId][_tag].message = scheduledMedia[idx].message;
        if (_scheduledMedia[_merchantId][_tag].length() > maxNumMedia) {
            _scheduledMedia[_merchantId][_tag].remove(idx);
        }
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender, "NTH13");
        contractAddress = _contractAddress;
    }

    function _businessVoter() internal view returns(address) {
        return IContract(contractAddress).businessVoter();
    }

    function _referralVoter() internal view returns(address) {
        return IContract(contractAddress).referralVoter();
    }
    
    function cancanVote(
        address _user, 
        string memory _tokenId, 
        uint _collectionId,
        uint _ticketId,
        address _sender,
        uint[5] memory _voteParams //[_userTokenId, _tradingFee, _lotteryFee, _netPrice, _price]
    ) external {
        // voting
        uint _isPaywall = IContract(contractAddress).paywallMarketHelpers() == _sender
        ? 1 : IContract(contractAddress).nftMarketHelpers() == _sender ? 2 : 0;
        address _seller = _vote(_voteParams, _collectionId, _isPaywall, _user, _tokenId);
        IMarketPlace(IContract(contractAddress).marketPlaceEvents()).
        emitTrade(_collectionId, _tokenId, _seller, _user, _voteParams[4], _voteParams[3], _ticketId, _isPaywall);
    }

    function _marketOrders(uint _isPaywall) internal view returns(address) {
        return _isPaywall == 1 
        ? IContract(contractAddress).paywallMarketOrders()
        : _isPaywall == 2
        ? IContract(contractAddress).nftMarketOrders()
        : IContract(contractAddress).marketOrders();
    }
    
    function _vote(
        uint[5] memory _voteParams,
        uint _collectionId,
        uint _isPaywall,
        address _user,
        string memory _tokenId
    ) internal returns(address) {
        Ask memory ask = IMarketPlace(_marketOrders(_isPaywall)).getAskDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
        if (_voteParams[0] > 0) {
            uint _referrerProfileId = IProfile(IContract(contractAddress).profile()).referrerFromAddress(_user);
            uint _weight = ve(ask.tokenInfo.ve).balanceOfNFT(_voteParams[0]);
            try IBusinessVoter(_businessVoter()).vote(
                _voteParams[0], 
                _collectionId, 
                _referrerProfileId,
                _weight > 0 ? _weight : _voteParams[1],
                ask.tokenInfo.ve, 
                _user,
                _weight > 0
            ) {
                lotteryCredits[_user][ask.tokenInfo.usetFIAT ? ask.tokenInfo.tFIAT : ve(ask.tokenInfo.ve).token()] += _voteParams[2];
            } catch{}
            // if user has been referred
            if (_referrerProfileId > 0) {
                try IReferralVoter(_referralVoter()).vote(
                    _voteParams[0], 
                    _referrerProfileId,
                    _weight > 0 ? _weight : _voteParams[1],
                    ask.tokenInfo.ve, 
                    _user,
                    _weight > 0
                ) {} catch{}
            }
        }
        return ask.seller;
    }

    function _safeTransfer(address _token, address to, uint256 value) internal {
        require(_token.code.length > 0, "NTH14");
        (bool success, bytes memory data) =
        _token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "NTH16");
    }

    function _safeTransferFrom(address _token, address from, address to, uint256 value) internal {
        require(_token.code.length > 0, "NTH17");
        (bool success, bytes memory data) =
        _token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "NTH18");
    }
}

contract NFTicketHelper2 is ERC721Pausable {
    mapping(uint => bool) private attached;
    mapping(uint => uint[]) private optionIndices;
    mapping(uint => address) private uriGenerator;
    address contractAddress;
    
    constructor() ERC721("NFTicket", "NFTicket") {}

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }

    function updateAttach(uint _tokenId, bool _attach) external {
        require(IContract(contractAddress).nfticket() == msg.sender);
        attached[_tokenId] = _attach;
    }

    function safeMint(uint _merchantId, string memory _item, address _to, address _sender, uint _tokenId, bytes memory _data, uint[] memory _options, bool _external) external {
        require(IContract(contractAddress).nfticket() == msg.sender, "NTHH02");
        uint _isPaywall = IContract(contractAddress).paywallMarketHelpers() == _sender
        ? 1 : IContract(contractAddress).nftMarketHelpers() == _sender ? 2 : 0;
        if (!_external && _isPaywall == 2) {
            MintValues memory mintValues = IMarketPlace(IContract(contractAddress).nftMarketHelpers3()).minter(_merchantId, _item); 
            if (mintValues.tokenId == 0) {
                IMarketPlace(mintValues.minter).mint(_merchantId, _item, _to, _options);
            } else {
                if (mintValues.nftype == NFTYPE.erc721) {
                    IERC721(mintValues.minter).safeTransferFrom(address(this), _to, mintValues.tokenId);
                } else {
                    IERC1155(mintValues.minter).safeTransferFrom(address(this), _to, mintValues.tokenId, 1, msg.data);
                }
            }
        }
        _safeMint(_to, _tokenId, _data);
        optionIndices[_tokenId] = _options;
    }

    function onERC721Received(address,address,uint256,bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector; 
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    //-------------------------------------------------------------------------
    // VIEW FUNCTIONS
    //-------------------------------------------------------------------------
    /**
     * @param   _ticketID: The unique ID of the ticket
     */
    function getTicketOptions(
        uint256 _ticketID
    ) 
        public 
        view 
        returns(Option[] memory _options) 
    {
        address nfticket = IContract(contractAddress).nfticket();
        uint _isPaywall = INFTicket(nfticket).isPaywall(_ticketID);
        if (_isPaywall != 1) {
            _options = new Option[](optionIndices[_ticketID].length);
            TicketInfo memory _ticketInfo = INFTicket(nfticket).getTicketInfo(_ticketID);
            address marketHelpers = _isPaywall == 0 
            ? IContract(contractAddress).marketHelpers()
            : IContract(contractAddress).paywallMarketHelpers();
            _options = IMarketPlace(marketHelpers).getOptions(
                _ticketInfo.merchant, 
                _ticketInfo.item, 
                optionIndices[_ticketID]
            );
        }
    }

    function getTicketPaywallOptions(
        uint256 _ticketID
    ) 
        public 
        view 
        returns(PaywallOption[] memory _options) 
    {
        address nfticket = IContract(contractAddress).nfticket();
        if (INFTicket(nfticket).isPaywall(_ticketID) == 1) {
            _options = new PaywallOption[](optionIndices[_ticketID].length);
            TicketInfo memory _ticketInfo = INFTicket(nfticket).getTicketInfo(_ticketID);
            _options = IMarketPlace(IContract(contractAddress).paywallMarketHelpers()).getPaywallOptions(
                _ticketInfo.merchant, 
                _ticketInfo.item, 
                optionIndices[_ticketID]
            );
        }
    }

    function _getCount(uint idx, uint _ticketID) internal view returns(uint count) {
        for (uint i = 0; i < optionIndices[_ticketID].length; i++) {
            if (optionIndices[_ticketID][i] == idx) count += 1;
        }
    }

    function _getCredits(address _token, uint _ticketID) internal view returns(string memory _credits) {
        _credits = toString(IMarketPlace(IContract(contractAddress).nfticketHelper()).lotteryCredits(ownerOf(_ticketID), _token));
    }

    function _getOptions(uint _ticketID, TicketInfo memory _ticketInfo) internal view returns(string[] memory optionNames, string[] memory optionValues) {
        address nfticket = IContract(contractAddress).nfticket();
        optionNames = new string[](optionIndices[_ticketID].length + 6);
        optionValues = new string[](optionIndices[_ticketID].length + 6);
        uint idx;
        uint decimals = uint(IMarketPlace(_ticketInfo.token).decimals());
        optionNames[idx] = "Active";
        optionValues[idx++] = _ticketInfo.active ? "Yes" : "No";
        optionNames[idx] = "TE";
        optionValues[idx++] = toString(_ticketInfo.timeEstimate);
        optionNames[idx] = "Bought";
        optionValues[idx++] = toString(_ticketInfo.date);
        optionNames[idx] = "Lottery Credits";
        optionValues[idx++] = _getCredits(_ticketInfo.token, _ticketID);
        optionValues[idx++] = string(abi.encodePacked(_ticketInfo.item, "(", toString(_ticketInfo.price), " ", IMarketPlace(_ticketInfo.token).symbol(), ")"));
        for (uint i = 0; i < optionIndices[_ticketID].length; i++) {
            string memory count = toString(_getCount(optionIndices[_ticketID][i], _ticketID));
            if (INFTicket(nfticket).isPaywall(_ticketID) == 1) {
                PaywallOption[] memory _options = getTicketPaywallOptions(_ticketID);
                optionNames[idx] = _options[i].traitType;
                optionValues[idx++] = string(abi.encodePacked(_options[i].element, "(", count, ")", "[", toString(_options[i].unitPrice/10**decimals), "]"));
            } else {
                Option[] memory _options = getTicketOptions(_ticketID);
                optionNames[idx] = _options[i].traitType;
                optionValues[idx++] = string(abi.encodePacked(_options[i].value, "(", count, ")", "[", toString(_options[i].unitPrice/10**decimals), "]"));
            }
        }
        optionNames[idx] = "External";
        optionValues[idx++] = _ticketInfo.source == Source.Local ? "No" : "Yes";
    }

    function _orders(uint _ticketID, uint _collectionId, bytes32 _tokenId) internal view returns(Ask memory _ask) {
        uint _idx = INFTicket(IContract(contractAddress).nfticket()).isPaywall(_ticketID);
        if (_idx == 0) {
            _ask = IMarketPlace(IContract(contractAddress).marketOrders()).getAskDetails(_collectionId, _tokenId);
        } else if(_idx == 1) {
            _ask = IMarketPlace(IContract(contractAddress).nftMarketOrders()).getAskDetails(_collectionId, _tokenId);
        } else {
            _ask = IMarketPlace(IContract(contractAddress).paywallMarketOrders()).getAskDetails(_collectionId, _tokenId);
        }
    }

    function _isEmpty(string memory val) internal pure returns(bool) {
        return keccak256(abi.encodePacked(val)) == keccak256(abi.encodePacked(""));
    }

    function _taskContract(uint _tokenId, uint _merchantId) internal view returns(address) {
        address taskContract = INFTicket(IContract(contractAddress).nfticketHelper()).taskContracts(_merchantId);
        return taskContract != address(0x0) && IMarketPlace(taskContract).pendingTask(_tokenId)
            ? taskContract : address(0x0);
    }
    
    function updateUriGenerator(address _uriGenerator) external {
        uint merchantId = IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(msg.sender);
        if (merchantId > 0) {
            uriGenerator[merchantId] = _uriGenerator;
        }
    }

    function tokenURI(uint _tokenId) public view virtual override returns (string memory output) {
        TicketInfo memory _ticketInfo = INFTicket(IContract(contractAddress).nfticket()).getTicketInfo(_tokenId);
        if (uriGenerator[_ticketInfo.merchant] != address(0x0)) {
            output = IMarketPlace(uriGenerator[_ticketInfo.merchant]).uri(_tokenId);
        } else {
            Ask memory _ask = _orders(_tokenId, _ticketInfo.merchant, keccak256(abi.encodePacked(_ticketInfo.item)));
            (string[] memory optionNames, string[] memory optionValues) = _getOptions(_tokenId, _ticketInfo);
            string[] memory media = INFTicket(IContract(contractAddress).nfticketHelper())
            .getSponsorsMedia(_ticketInfo.merchant, _ticketInfo.item);
            string[] memory chat = new string[](1);
            if (!_isEmpty(_ticketInfo.superChatOwner)) {
                chat[0] = _ticketInfo.superChatOwner;
            }
            if (!_isEmpty(_ticketInfo.superChatResponse)) {
                chat[1] = _ticketInfo.superChatResponse;
            }
            output = IMarketPlace(IContract(contractAddress).nftSvg()).constructTokenURI(
                _tokenId,
                '',
                _ask.tokenInfo.tFIAT,
                _ask.tokenInfo.ve,
                ownerOf(_tokenId),
                _taskContract(_tokenId, _ticketInfo.merchant),
                media.length > 0 ? media : new string[](1),
                optionNames,
                optionValues,
                chat
            );
        }
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

    //-------------------------------------------------------------------------
    // INTERNAL FUNCTIONS 
    //-------------------------------------------------------------------------
    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        virtual
        override 
    {
        super._beforeTokenTransfer(from, to, tokenId);
        require(!attached[tokenId]);
        if (msg.sender != IAuth(contractAddress).devaddr_() && from != address(0x0) && to != address(0x0)) {
            address nfticket = IContract(contractAddress).nfticket();
            TicketInfo memory _ticketInfo = INFTicket(nfticket).getTicketInfo(tokenId);
            require(_ticketInfo.transferrable);
        }
    }

    // function safeTransferNAttach(
    //     address attachTo,
    //     uint period,
    //     address from,
    //     address to,
    //     uint256 id,
    //     bytes memory data
    // ) external {
    //     super.safeTransferFrom(from, to, id, data);
    //     require(ownerOf(id) == msg.sender);
    //     INFTicket(IContract(contractAddress).nfticket()).attach(id, period, attachTo);
    // }
}

contract MarketPlaceEvents {
    address contractAddress;
    mapping(uint => bool) private attachedBounties;

    // Collection is closed for trading and new listings
    event CollectionClose(uint256 indexed collection);

    // New collection is added
    event CollectionNew(
        uint256 indexed collectionId,
        address collection,
        address baseToken,
        uint256 referrerFee,
        uint256 badgeId,
        uint256 tradingFee,
        uint256 recurringBounty,
        uint256 minBounty,
        uint256 userMinBounty,
        bool requestUserRegistration,
        bool requestPartnerRegistration
    );

    event CollectionUpdateIdentity(
        uint256 indexed collectionId,
        string requiredIndentity,
        string valueName,
        bool onlyTrustWorthyAuditors,
        uint maxUse,
        bool isUserIdentity,
        bool dataKeeperOnly,
        COLOR minIDBadgeColor
    );
    
    // Existing collection is updated
    event CollectionUpdate(
        uint256 indexed collectionId,
        address indexed collection,
        uint256 referrerFee,
        uint256 badgeId,
        uint256 tradingFee,
        uint256 recurringBounty,
        uint256 minBounty,
        uint256 userMinBounty,
        bool requestUserRegistration,
        bool requestPartnerRegistration
    );

    event UpdateOptions(
        uint _collectionId,
        string _tokenId,
        address _sender,
        uint _min,
        uint _max,
        uint _unitPrice,
        string _category,
        string _element,
        string _traitType,
        string _value,
        string _currency
    );

    event PaywallUpdateOptions(
        uint _collectionId,
        string _tokenId,
        uint _min,
        uint _max,
        uint _value,
        uint _unitPrice,
        string _category,
        string _element,
        string _traitType,
        string _currency
    );
    
    event Voted(uint indexed collectionId, uint profileId, string tokenId, uint likes, uint disLikes, bool like);
    
    event PaywallVoted(uint indexed collectionId, uint profileId, string tokenId, uint likes, uint disLikes, bool like, address sender);

    // Ask order is cancelled
    event AskCancel(uint256 indexed collection, uint256 indexed tokenId);
    
    event PaywallAskCancel(uint256 indexed collection, uint256 indexed tokenId, address sender);
    
    event UserRegistration(uint256 indexed collectionId, uint256 userCollectionId, bool active);

    event PartnerRegistrationRequest(uint256 indexed collectionId, uint256 partnerCollectionId, uint256 identityProofId);

    event UpdateAnnouncement(uint256 indexed collectionId, uint256 position, bool active, string anouncementTitle, string anouncementContent);
    
    // Ask order is created
    event AskNew(
        uint indexed _collectionId,
        string _tokenId,
        uint _askPrice,
        uint _bidDuration,
        int _minBidIncrementPercentage,
        bool _transferrable,
        uint _rsrcTokenId,
        uint _maxSupply,
        uint _dropinTimer,
        address _tFIAT,
        address _ve
    );

    event PaywallAskNew(
        uint indexed _collectionId,
        string _tokenId,
        uint _askPrice,
        uint _bidDuration,
        int _minBidIncrementPercentage,
        bool _transferrable,
        uint _rsrcTokenId,
        uint _maxSupply,
        uint _dropinTimer,
        address _tFIAT,
        address _ve,
        address _sender
    );

    event AskInfo(
        uint indexed collectionId,
        string _tokenId,
        string description,
        uint[] prices,
        uint start,
        uint period,
        uint isPaywall,
        bool isTradeable,
        string images,
        string countries,
        string cities,
        string products
    );

    // Ask order is updated
    event AskUpdate(
        string _tokenId,
        address _seller,
        uint256 indexed _collectionId,
        uint256 _newPrice,
        uint256 _bidDuration,
        int256 _minBidIncrementPercentage,
        bool _transferrable,
        uint256 _rsrcTokenId,
        uint256 _maxSupply,
        uint _dropinTimer
    );

    event PaywallAskUpdate(
        string _tokenId,
        address _seller,
        address _sender,
        uint256 indexed _collectionId,
        uint256 _newPrice,
        uint256 _bidDuration,
        int256 _minBidIncrementPercentage,
        bool _transferrable,
        uint256 _rsrcTokenId,
        uint256 _maxSupply,
        uint _dropinTimer
    );

    event AskUpdateDiscount(
        uint _collectionId, 
        string _tokenId, 
        Status _discountStatus,
        uint _discountStart,
        bool _cashNotCredit,
        bool _checkItemOnly,
        bool _checkIdentityCode,
        uint[6] _discountNumbers,
        uint[6] _discountCost
    );

    event PaywallAskUpdateDiscount(
        uint _collectionId, 
        string _tokenId, 
        Status _discountStatus,
        uint _discountStart,
        bool _cashNotCredit,
        bool _checkItemOnly,
        bool _checkIdentityCode,
        address _sender,
        uint[6] _discountNumbers,
        uint[6] _discountCost
    );

    event AskUpdateCashback(
        uint _collectionId, 
        string _tokenId, 
        Status _cashbackStatus,
        uint _cashbackStart,
        bool _cashNotCredit,
        bool _checkItemOnly,
        uint[6] _cashbackNumbers,
        uint[6] _cashbackCost
    );

    event PaywallAskUpdateCashback(
        uint _collectionId, 
        string _tokenId, 
        Status _cashbackStatus,
        uint _cashbackStart,
        bool _cashNotCredit,
        bool _checkItemOnly,
        address _sender,
        uint[6] _cashbackNumbers,
        uint[6] _cashbackCost
    );

    event AskUpdateIdentity(
        uint _collectionId, 
        string _tokenId,
        string _requiredIndentity,
        string _valueName,
        bool _onlyTrustWorthyAuditors,
        bool _dataKeeperOnly,
        uint _maxUse,
        COLOR _minIDBadgeColor
    );

    event PaywallAskUpdateIdentity(
        uint _collectionId, 
        string _tokenId,
        string _requiredIndentity,
        string _valueName,
        address _sender,
        bool _onlyTrustWorthyAuditors,
        bool _dataKeeperOnly,
        uint _maxUse,
        COLOR _minIDBadgeColor
    );

    event UpdateTaskEvent(
        uint collectionId,
        uint eventType,
        string tokenId,
        bool isSurvey,
        bool required,
        bool active,
        string linkToTask,
        string codes
    );

    event AddReferral(uint indexed _referrerCollectionId, uint _collectionId, string _tokenId, uint _bountyId, uint _identityProofId, address _sender);

    event CloseReferral(uint indexed _referrerCollectionId, uint _collectionId, string _tokenId, bool _deactivate, address _sender);

    // // Recover NFT tokens sent by accident
    // event NonFungibleTokenRecovery(address indexed token, uint256 indexed tokenId);

    // Pending revenue is claimed
    event RevenueClaim(address indexed claimer, uint256 amount);

    // // Recover ERC20 tokens sent by accident
    // event TokenRecovery(address indexed token, uint256 amount);

    event UpdateCollection(
        uint indexed collectionId,
        string name,
        string desc,
        string large,
        string small,
        string avatar,
        string contactChannels,
        string contacts,
        string workspaces,
        string countries,
        string cities,
        string products
    );
    event UpdatePaywall(
        uint _collectionId, 
        string _tokenId, 
        string _paywallId, 
        bool _add,
        bool _isNFT,
        string _images
    );
    
    // Ask order is matched by a trade
    event Trade(
        uint indexed collectionId,
        string tokenId,
        address indexed seller,
        address buyer,
        uint256 askPrice,
        uint256 netPrice,
        uint256 nfTicketId
    );

    event PaywallTrade(
        uint256 indexed collectionId,
        string tokenId,
        address indexed seller,
        address buyer,
        uint256 eventType,
        uint256 askPrice,
        uint256 netPrice,
        uint256 nfTicketId
    );
    event CreatePaywallARP(address subscriptionARP, uint collectionId);
    event DeletePaywallARP(uint collectionId);
    event UpdateSubscriptionInfo(uint collectionId, uint optionId, uint freeTrialPeriod);
    
    event CreateReview(
        uint indexed collectionId, 
        string tokenId, 
        uint userTokenId, 
        uint votingPower, 
        uint reviewTime, 
        bool good,
        uint isPaywall,
        string review,
        address reviewer
    );
    event UpdateValuepools(uint collectionId, address valuepool, bool add);
    event UpdateProtocol(
        uint collectionId, 
        uint nfticketId, 
        uint referrerCollectionId, 
        uint protocolId, 
        uint optionId,
        uint amountReceivable,
        uint periodReceivable,
        uint startReceivable,
        string paywallId
    );
    event DeleteProtocol(uint collectionId, uint protocolId);
    event UpdateAutoCharge(uint collectionId, uint protocolId, bool autocharge);
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

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }

    function emitUpdateProtocol(
        uint collectionId,
        uint nfticketId,
        uint referrerCollectionId,
        uint protocolId,
        uint optionId,
        uint amountReceivable,
        uint periodReceivable,
        uint startReceivable,
        string memory productId
    ) external {
        require(IMarketPlace(IContract(contractAddress).paywallARPHelper()).isGauge(msg.sender));

        emit UpdateProtocol(
            collectionId, 
            nfticketId, 
            referrerCollectionId, 
            protocolId, 
            optionId,
            amountReceivable,
            periodReceivable,
            startReceivable,
            productId
        );
    }

    function emitDeleteProtocol(uint collectionId, uint protocolId) external {
        require(IMarketPlace(IContract(contractAddress).paywallARPHelper()).isGauge(msg.sender));

        emit DeleteProtocol(collectionId, protocolId);
    }

    function emitUpdateAutoCharge(
        uint collectionId,
        uint protocolId,
        bool autoCharge
    ) external {
        require(IMarketPlace(IContract(contractAddress).paywallARPHelper()).isGauge(msg.sender));

        emit UpdateAutoCharge(collectionId, protocolId, autoCharge);
    }

    function emitCollectionNew(
        uint256 _collectionId,
        address _collection,
        address _baseToken,
        uint256 _referrerFee,
        uint256 _badgeId,
        uint256 tradingFee,
        uint256 _recurringBounty,
        uint256 _minBounty,
        uint256 _userMinBounty,
        bool _requestUserRegistration,
        bool _requestPartnerRegistration
    ) external {
        require(msg.sender == IContract(contractAddress).marketCollections());
        address marketHelpers3 = IContract(contractAddress).marketHelpers3();
        require(IMarketPlace(marketHelpers3).dTokenSetContains(_baseToken));
        emit CollectionNew(
            _collectionId,
            _collection, 
            _baseToken,
            _referrerFee,
            _badgeId,
            tradingFee,
            _recurringBounty,
            _minBounty,
            _userMinBounty,
            _requestUserRegistration,
            _requestPartnerRegistration
        );
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

    function updatePaywall(
        string memory _productId, 
        string memory _paywallId, 
        bool _add,
        bool _isNFT,
        string memory images
    ) external {
        uint _collectionId = IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(msg.sender);
        emit UpdatePaywall(_collectionId, _productId, _paywallId, _add, _isNFT, images);
    }

    function emitUserRegistration(uint _collectionId, uint _userCollectionId, bool active) external  {
        require(IContract(contractAddress).marketHelpers3() == msg.sender);
        emit UserRegistration(_collectionId, _userCollectionId, active);
    }

    function emitUpdateTaskEvent(
        bool isSurvey,
        bool required,
        bool active,
        uint eventType,
        string memory _tokenId,
        string memory linkToTask,
        string memory codes
    ) external {
        uint _collectionId = IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(msg.sender);

        emit UpdateTaskEvent(
            _collectionId,
            eventType,
            _tokenId,
            isSurvey,
            required,
            active,
            linkToTask,
            codes
        );
    }

    function emitPartnerRegistrationRequest(uint _collectionId, uint _identityProofId) external  {
        uint _partnerCollectionId = IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(msg.sender);
        IMarketPlace(IContract(contractAddress).marketHelpers2()).checkPartnerIdentityProof(_collectionId, _identityProofId, msg.sender);
        emit PartnerRegistrationRequest(_collectionId, _partnerCollectionId, _identityProofId);
    }
    
    function emitCollectionUpdateIdentity(
        uint _collectionId,
        string memory _requiredIndentity,
        string memory _valueName,
        bool _onlyTrustWorthyAuditors,
        uint _maxUse,
        bool _isUserIdentity,
        bool _dataKeeperOnly,
        COLOR _minIDBadgeColor
    ) external {
        require(msg.sender == IContract(contractAddress).marketCollections());
        emit CollectionUpdateIdentity(
            _collectionId,
            _requiredIndentity,
            _valueName,
            _onlyTrustWorthyAuditors,
            _maxUse,
            _isUserIdentity,
            _dataKeeperOnly,
            _minIDBadgeColor
        );
    }

    function emitCollectionUpdate(
        uint256 _collectionId,
        address _collection,
        uint256 _referrerFee,
        uint256 _badgeId,
        uint256 tradingFee,
        uint256 _recurringBounty,
        uint256 _minBounty,
        uint256 _userMinBounty,
        bool _requestUserRegistration,
        bool _requestPartnerRegistration
    ) external {
        require(msg.sender == IContract(contractAddress).marketCollections());
        emit CollectionUpdate(
            _collectionId, 
            _collection, 
            _referrerFee,
            _badgeId,
            tradingFee,
            _recurringBounty,
            _minBounty,
            _userMinBounty,
            _requestUserRegistration,
            _requestPartnerRegistration
        );
    }

    function emitCollectionClose(uint _collectionId) external {
        require(msg.sender == IContract(contractAddress).marketCollections());

        emit CollectionClose(_collectionId);
    }

    function emitAskCancel(uint256 collection, uint256 tokenId) external {
        if(msg.sender == IContract(contractAddress).marketOrders()) {
            emit AskCancel(collection, tokenId);
        } else {
            emit PaywallAskCancel(collection, tokenId, msg.sender);
        }
    }

    function emitAskNew(
        uint256 collection, 
        string memory tokenId, 
        uint256 askPrice, 
        uint _bidDuration,
        int _minBidIncrementPercentage,
        bool _transferrable,
        uint _rsrcTokenId,
        uint _maxSupply,
        uint _dropinTimer,
        address _tFIAT,
        address _ve
    ) external {
        if(msg.sender == IContract(contractAddress).marketOrders()) {
            emit AskNew(
                collection, 
                tokenId, 
                askPrice, 
                _bidDuration,
                _minBidIncrementPercentage,
                _transferrable,
                _rsrcTokenId,
                _maxSupply,
                _dropinTimer,
                _tFIAT,
                _ve
            );
        } else {
            emit PaywallAskNew(
                collection, 
                tokenId, 
                askPrice, 
                _bidDuration,
                _minBidIncrementPercentage,
                _transferrable,
                _rsrcTokenId,
                _maxSupply,
                _dropinTimer,
                _tFIAT,
                _ve,
                msg.sender
            );
        }
    }

    function emitAskUpdate(
        string memory _tokenId,
        address _seller,
        uint256 _collectionId,
        uint256 _newPrice,
        uint256 _bidDuration,
        int256 _minBidIncrementPercentage,
        bool _transferrable,
        uint256 _rsrcTokenId,
        uint256 _maxSupply,
        uint _dropinTimer
    ) external {
        if(msg.sender == IContract(contractAddress).marketOrders()) {
            emit AskUpdate(
                _tokenId, 
                _seller,
                _collectionId, 
                _newPrice,
                _bidDuration,
                _minBidIncrementPercentage,
                _transferrable,
                _rsrcTokenId,
                _maxSupply,
                _dropinTimer
            );
        } else {
            emit PaywallAskUpdate(
                _tokenId, 
                _seller,
                msg.sender,
                _collectionId, 
                _newPrice,
                _bidDuration,
                _minBidIncrementPercentage,
                _transferrable,
                _rsrcTokenId,
                _maxSupply,
                _dropinTimer
            );
        }
    }

    function emitAskUpdateDiscount(
        uint _collectionId, 
        string memory _tokenId, 
        Status _discountStatus,
        uint _discountStart,
        bool _cashNotCredit,
        bool _checkItemOnly,
        bool _checkIdentityCode,
        uint[6] memory _discountNumbers,
        uint[6] memory _discountCost   
    ) external {
        if(msg.sender == IContract(contractAddress).marketOrders()) {
            emit AskUpdateDiscount(
                _collectionId, 
                _tokenId, 
                _discountStatus,
                _discountStart,
                _cashNotCredit,
                _checkItemOnly,
                _checkIdentityCode,
                _discountNumbers,
                _discountCost
            );
        } else {
            emit PaywallAskUpdateDiscount(
                _collectionId, 
                _tokenId, 
                _discountStatus,
                _discountStart,
                _cashNotCredit,
                _checkItemOnly,
                _checkIdentityCode,
                msg.sender,
                _discountNumbers,
                _discountCost
            );
        }
    }

    function emitAskUpdateCashback(
        uint _collectionId, 
        string memory _tokenId, 
        Status _cashbackStatus,
        uint _cashbackStart,
        bool _cashNotCredit,
        bool _checkItemOnly,
        uint[6] memory _cashbackNumbers,
        uint[6] memory _cashbackCost   
    ) external {
        if(msg.sender == IContract(contractAddress).marketOrders()) {
            emit AskUpdateCashback(
                _collectionId, 
                _tokenId, 
                _cashbackStatus,
                _cashbackStart,
                _cashNotCredit,
                _checkItemOnly,
                _cashbackNumbers,
                _cashbackCost
            );
        } else {
            emit PaywallAskUpdateCashback(
                _collectionId, 
                _tokenId, 
                _cashbackStatus,
                _cashbackStart,
                _cashNotCredit,
                _checkItemOnly,
                msg.sender,
                _cashbackNumbers,
                _cashbackCost
            );
        }
    }

    function emitAskUpdateIdentity(
        uint _collectionId, 
        string memory _tokenId,
        string memory _requiredIndentity,
        string memory _valueName,
        bool _onlyTrustWorthyAuditors,
        bool _dataKeeperOnly,
        uint _maxUse,
        COLOR _minIDBadgeColor
    ) external {
        if(msg.sender == IContract(contractAddress).marketOrders()) {
            emit AskUpdateIdentity(
                _collectionId,
                _tokenId,
                _requiredIndentity,
                _valueName,
                _onlyTrustWorthyAuditors,
                _dataKeeperOnly,
                _maxUse,
                _minIDBadgeColor
            );
        } else {
            emit PaywallAskUpdateIdentity(
                _collectionId,
                _tokenId,
                _requiredIndentity,
                _valueName,
                msg.sender,
                _onlyTrustWorthyAuditors,
                _dataKeeperOnly,
                _maxUse,
                _minIDBadgeColor
            );
        }
    }

    function emitRevenueClaim(address _user, uint revenueToClaim) external {
        require(
            msg.sender == IContract(contractAddress).marketTrades() ||
            msg.sender == IContract(contractAddress).nftMarketTrades() ||
            msg.sender == IContract(contractAddress).paywallMarketTrades()
        );
        emit RevenueClaim(_user, revenueToClaim);
    }

    function emitTrade(
        uint _collectionId, 
        string memory _tokenId, 
        address _seller, 
        address _user, 
        uint _price, 
        uint _netPrice,
        uint _nfTicketId,
        uint _eventType
    ) external {
        require(msg.sender == IContract(contractAddress).nfticketHelper());
        if (_eventType != 0) {
            emit PaywallTrade(_collectionId, _tokenId, _seller, _user, _eventType, _price, _netPrice, _nfTicketId);
        } else {
            emit Trade(_collectionId, _tokenId, _seller, _user, _price, _netPrice, _nfTicketId);
        }
    }

    function emitAddReferral(
        uint _referrerCollectionId, 
        uint _collectionId, 
        string memory _tokenId,
        uint _bountyId, 
        uint _identityProofId
    ) external {
        require(
            msg.sender == IContract(contractAddress).marketOrders() ||
            msg.sender == IContract(contractAddress).nftMarketOrders() ||
            msg.sender == IContract(contractAddress).paywallMarketOrders()
        );
        if (_bountyId > 0 && !attachedBounties[_bountyId]) {
            require(ITrustBounty(IContract(contractAddress).trustBountyHelper()).attachments(_bountyId) == 0);
            ITrustBounty(IContract(contractAddress).trustBountyHelper()).attach(_bountyId);
        }
        attachedBounties[_bountyId] = _bountyId > 0;
        emit AddReferral(
            _referrerCollectionId, 
            _collectionId, 
            _tokenId, 
            _bountyId, 
            _identityProofId, 
            msg.sender
        );
    }

    function emitCloseReferral(
        uint _referrerCollectionId, 
        uint _collectionId, 
        uint _bountyId, 
        address _user, 
        string memory _tokenId,
        bool deactivate
    ) external {
        if (attachedBounties[_bountyId]) {
            Collection memory _collection = IMarketPlace(IContract(contractAddress).marketCollections()).getCollection(_collectionId);
            (address owner,address _token,,address claimableBy,,,,,,) = ITrustBounty(IContract(contractAddress).trustBounty()).bountyInfo(_bountyId);
            require(owner == _user && _collection.baseToken == _token && claimableBy == address(0x0));
            ITrustBounty(IContract(contractAddress).trustBountyHelper()).detach(_bountyId);
        }
        attachedBounties[_bountyId] = false;
        emit CloseReferral(
            _referrerCollectionId, 
            _collectionId, 
            _tokenId,
            deactivate,
            msg.sender
        );
    }

    function emitUpdateSubscriptionInfo(
        uint _collectionId, 
        uint _optionId,
        uint _freeTrialPeriod
    ) external {
        require(msg.sender == IContract(contractAddress).paywallMarketHelpers());

        emit UpdateSubscriptionInfo(_collectionId, _optionId, _freeTrialPeriod);   
    }

    function emitCreatePaywallARP(address _subscriptionARP, uint _collectionId) external {
        require(msg.sender == IContract(contractAddress).paywallARPHelper());

        emit CreatePaywallARP(_subscriptionARP, _collectionId);   
    }

    function emitDeletePaywallARP(uint collectionId) external {
        require(msg.sender == IContract(contractAddress).paywallARPHelper());

        emit DeletePaywallARP(collectionId);   
    }
    
    function emitUpdateOptions(
        uint _collectionId,
        string memory _tokenId,
        uint _min,
        uint _max,
        uint _unitPrice,
        string memory _category,
        string memory _element,
        string memory _traitType,
        string memory _value,
        string memory _currency
    ) external {
        require(
            msg.sender == IContract(contractAddress).marketHelpers() ||
            msg.sender == IContract(contractAddress).nftMarketHelpers()
        );
        emit UpdateOptions(
            _collectionId,
            _tokenId,
            msg.sender,
            _min,
            _max,
            _unitPrice,
            _category,
            _element,
            _traitType,
            _value,
            _currency
        );
    }

    function emitPaywallUpdateOptions(
        uint _collectionId,
        string memory _tokenId,
        uint _min,
        uint _max,
        uint _value,
        uint _unitPrice,
        string memory _category,
        string memory _element,
        string memory _traitType,
        string memory _currency
    ) external {
        emit PaywallUpdateOptions(
            _collectionId,
            _tokenId,
            _min,
            _max,
            _value,
            _unitPrice,
            _category,
            _element,
            _traitType,
            _currency
        );
    }

    function emitUpdateCollection(
        uint collectionId,
        string memory name,
        string memory description,
        string memory large,
        string memory small,
        string memory avatar,
        string memory contactChannels,
        string memory contacts,
        string memory workspaces,
        string memory countries,
        string memory cities,
        string memory products
    ) external {
        require(IContract(contractAddress).marketCollections() == msg.sender);
        emit UpdateCollection(
            collectionId,
            name,
            description,
            large,
            small,
            avatar,
            contactChannels,
            contacts,
            workspaces,
            countries,
            cities,
            products
        );
    }

    function emitAskInfo(
        uint collectionId,
        string memory tokenId,
        string memory description,
        uint[] memory prices,
        uint start,
        uint period, // currPriceIdx = Math.roundDown((block.timestamp - start) / period)
        uint isPaywall,
        bool isTradeable,
        string memory images,
        string memory countries,
        string memory cities,
        string memory products
    ) external {
        require(IContract(contractAddress).marketCollections() == msg.sender);
        emit AskInfo(
            collectionId,
            tokenId,
            description,
            prices,
            start,
            period,
            isPaywall,
            isTradeable,
            images,
            countries,
            cities,
            products
        );
    }

    function emitReview(
        uint collectionId,
        string memory tokenId,
        uint userTokenId,
        uint votingPower,
        bool good,
        uint isPaywall,
        string memory review,
        address reviewer
    ) external {
        require(IContract(contractAddress).marketCollections() == msg.sender);
        emit CreateReview(
            collectionId,
            tokenId,
            userTokenId,
            votingPower,
            block.timestamp,
            good,
            isPaywall,
            review, 
            reviewer
        );
    }

    function emitUpdateAnnouncement(
        uint position,
        bool active,
        string memory anouncementTitle,
        string memory anouncementContent
    ) external {
        uint collectionId = IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(msg.sender);
        emit UpdateAnnouncement(collectionId, position, active, anouncementTitle, anouncementContent);
    }

    function emitUpdateValuepools(address _valuepool, bool _add) external {
        uint collectionId = IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(msg.sender);
        emit UpdateValuepools(collectionId, _valuepool, _add);
    }

    function emitVoted(
        uint collectionId, 
        uint _profileId,
        string memory _tokenId, 
        uint likes, 
        uint dislikes, 
        bool like
    ) external {
        if(IContract(contractAddress).marketHelpers2() == msg.sender) {
            emit Voted(collectionId, _profileId, _tokenId, likes, dislikes, like);
        } else {
            emit PaywallVoted(collectionId, _profileId, _tokenId, likes, dislikes, like, msg.sender);
        }
    }
}

contract ContractAddresses {
    using EnumerableSet for EnumerableSet.UintSet;
    
    mapping(uint => string) public indexToName;
    EnumerableSet.UintSet private _contentIndices;

    address public badgeNft;
    address public gameMinter;
    address public gameFactory;
    address public gameHelper;
    address public gameHelper2;
    address public willNote;
    address public willFactory;
    address public auditorHelper;
    address public auditorHelper2;
    address public auditorNote;
    address public auditorFactory;
    address public arpMinter;
    address public arpNote;
    address public arpHelper;
    address public arpFactory;
    address public bettingFactory;
    address public bettingHelper;
    address public bettingMinter;
    address public rampAds;
    address public rampHelper;
    address public rampHelper2;
    address public rampFactory;
    address public worldNote;
    address public worldHelper;
    address public worldHelper2;
    address public worldHelper3;
    address public worldFactory;
    address public billNote;
    address public billMinter;
    address public billHelper;
    address public billFactory;
    address public businessMinter;
    address public nftSvg;
    address public businessGaugeFactory;
    address public businessBribeFactory;
    address public referralBribeFactory;
    address public veFactory;
    address public minterFactory;
    address public sponsorFactory;
    address public sponsorNote;
    address public valuepoolVoter;
    address public valuepoolFactory;
    address public valuepoolHelper;
    address public valuepoolHelper2;
    address public stakeMarketBribe;
    address public stakeMarket;
    address public stakeMarketHelper;
    address public stakeMarketNote;
    address public stakeMarketVoter;
    address public profileHelper;
    address public lotteryAddress;
    address public lotteryHelper;
    address public marketPlaceEvents;
    address public marketCollections;
    address public marketOrders;
    address public paywallMarketOrders;
    address public nftMarketOrders;
    address public marketTrades;
    address public nftMarketTrades;
    address public paywallMarketTrades;
    address public marketHelpers;
    address public nftMarketHelpers;
    address public paywallMarketHelpers;
    address public marketHelpers2;
    address public nftMarketHelpers2;
    address public paywallMarketHelpers2;
    address public marketHelpers3;
    address public nftMarketHelpers3;
    address public paywallMarketHelpers3;
    address public trustBounty;
    address public trustBountyHelper;
    address public trustBountyVoter;
    address public profile;
    address public ssi;
    address public businessVoter;
    address public referralVoter;
    address public contributorVoter;
    address public acceleratorVoter;
    address public nfticket;
    address public nfticketHelper;
    address public nfticketHelper2;
    address public poolGauge;
    address public token;
    address public paywallARPHelper;
    address public paywallARPFactory;
    address public lenderFactory;
    address public vrfCoordinator;
    address public linkToken;
    uint public maxMessage = 100;
    uint public minSuperChat = 1;
    uint public maximumSize = 50;
    uint public adminShare = 100;
    uint public valuepoolShare = 900;
    mapping(address => address) public veValuepool;
    mapping(address => uint) public cap;
    address public devaddr_;
    mapping(string => address) public nameToContractAddress;

    modifier onlyAdmin {
        require(msg.sender == devaddr_);
        _;
    }

    function setContractWithName(string memory _contractName, address _contractAddr) external onlyAdmin {
        require(devaddr_ == msg.sender);
        nameToContractAddress[_contractName] = _contractAddr;
    }
    
    function setVeValuePool(address _ve, address _valuepool) external onlyAdmin {
        veValuepool[_ve] = _valuepool;
    }

    function setCap(address _token, uint _cap) external onlyAdmin {
        cap[_token] = _cap;
    }

    function setBadgeNft(address _badgeNft) external onlyAdmin {
        badgeNft = _badgeNft;
    }
    
    function setGameMinter(address _gameMinter) external onlyAdmin {
        gameMinter = _gameMinter;
    }

    function setWillFactory(address _willFactory) external onlyAdmin {
        willFactory = _willFactory;
    }

    function setWillNote(address _willNote) external onlyAdmin {
        willNote = _willNote;
    }

    function setGameFactory(address _gameFactory) external onlyAdmin {
        gameFactory = _gameFactory;
    }

    function setGameHelper(address _gameHelper) external onlyAdmin {
        gameHelper = _gameHelper;
    }

    function setGameHelper2(address _gameHelper2) external onlyAdmin {
        gameHelper2 = _gameHelper2;
    }

    function setAuditorHelper(address _auditorHelper) external onlyAdmin {
        auditorHelper = _auditorHelper;
    }

    function setAuditorHelper2(address _auditorHelper2) external onlyAdmin {
        auditorHelper2 = _auditorHelper2;
    }
    
    function setAuditorNote(address _auditorNote) external onlyAdmin {
        auditorNote = _auditorNote;
    }
    
    function setAuditorFactory(address _auditorFactory) external onlyAdmin {
        auditorFactory = _auditorFactory;
    }

    function setARPMinter(address _arpMinter) external onlyAdmin {
        arpMinter = _arpMinter;
    }
    
    function setRampAds(address _rampAds) external onlyAdmin {
        rampAds = _rampAds;
    }
    
    function setRampFactory(address _rampFactory) external onlyAdmin {
        rampFactory = _rampFactory;
    }

    function setRampHelper(address _rampHelper) external onlyAdmin {
        rampHelper = _rampHelper;
    }

    function setRampHelper2(address _rampHelper2) external onlyAdmin {
        rampHelper2 = _rampHelper2;
    }

    function setARPNote(address _arpNote) external onlyAdmin {
        arpNote = _arpNote;
    }
    
    function setARPFactory(address _arpFactory) external onlyAdmin {
        arpFactory = _arpFactory;
    }

    function setARPHelper(address _arpHelper) external onlyAdmin {
        arpHelper = _arpHelper;
    }

    function setBettingFactory(address _bettingFactory) external onlyAdmin {
        bettingFactory = _bettingFactory;
    }

    function setBettingHelper(address _bettingHelper) external onlyAdmin {
        bettingHelper = _bettingHelper;
    }

    function setBettingMinter(address _bettingMinter) external onlyAdmin {
        bettingMinter = _bettingMinter;
    }

    function setBILLNote(address _billNote) external onlyAdmin {
        billNote = _billNote;
    }

    function setBILLMinter(address _billMinter) external onlyAdmin {
        billMinter = _billMinter;
    }
    
    function setBILLFactory(address _billFactory) external onlyAdmin {
        billFactory = _billFactory;
    }

    function setBILLHelper(address _billHelper) external onlyAdmin {
        billHelper = _billHelper;
    }

    function setWorldNote(address _worldNote) external onlyAdmin {
        worldNote = _worldNote;
    }

    function setWorldHelper(address _worldHelper) external onlyAdmin {
        worldHelper = _worldHelper;
    }

    function setWorldHelper2(address _worldHelper2) external onlyAdmin {
        worldHelper2 = _worldHelper2;
    }

    function setWorldHelper3(address _worldHelper3) external onlyAdmin {
        worldHelper3 = _worldHelper3;
    }
    
    function setWorldFactory(address _worldFactory) external onlyAdmin {
        worldFactory = _worldFactory;
    }

    function setBusinessMinter(address _businessMinter) external onlyAdmin {
        businessMinter = _businessMinter;
    }

    function setNftSvg(address _nftSvg) external onlyAdmin {
        nftSvg = _nftSvg;
    }

    function setBusinessBribeFactory(address _businessBribeFactory) external onlyAdmin {
        businessBribeFactory = _businessBribeFactory;
    }
    
    function setBusinessGaugeFactory(address _businessGaugeFactory) external onlyAdmin {
        businessGaugeFactory = _businessGaugeFactory;
    }

    function setReferralBribeFactory(address _referralBribeFactory) external onlyAdmin {
        referralBribeFactory = _referralBribeFactory;
    }
    
    function setMinterFactory(address _minterFactory) external onlyAdmin {
        minterFactory = _minterFactory;
    }

    function setVeFactory(address _veFactory) external onlyAdmin {
        veFactory = _veFactory;
    }

    function setSponsorFactory(address _sponsorFactory) external onlyAdmin {
        sponsorFactory = _sponsorFactory;
    }

    function setSponsorNote(address _sponsorNote) external onlyAdmin {
        sponsorNote = _sponsorNote;
    }

    function setValuepoolFactory(address _valuepoolFactory) external onlyAdmin {
        valuepoolFactory = _valuepoolFactory;
    }

    function setValuepoolVoter(address _valuepoolVoter) external onlyAdmin {
        valuepoolVoter = _valuepoolVoter;
    }
    
    function setValuepoolHelper(address _valuepoolHelper) external onlyAdmin {
        valuepoolHelper = _valuepoolHelper;
    }

    function setValuepoolHelper2(address _valuepoolHelper2) external onlyAdmin {
        valuepoolHelper2 = _valuepoolHelper2;
    }

    function setStakeMarketBribe(address _stakeMarketBribe) external onlyAdmin {
        stakeMarketBribe = _stakeMarketBribe;
    }

    function setStakeMarketNote(address _stakeMarketNote) external onlyAdmin {
        stakeMarketNote = _stakeMarketNote;
    }

    function setStakeMarketHelper(address _stakeMarketHelper) external onlyAdmin {
        stakeMarketHelper = _stakeMarketHelper;
    }
    
    function setStakeMarketVoter(address _stakeMarketVoter) external onlyAdmin {
        stakeMarketVoter = _stakeMarketVoter;
    }

    function setStakeMarket(address _stakeMarket) external onlyAdmin {
        stakeMarket = _stakeMarket;
    }

    function setProfileHelper(address _profileHelper) external onlyAdmin {
        profileHelper = _profileHelper;
    }

    function setPaywallARPHelper(address _paywallARPHelper) external onlyAdmin {
        paywallARPHelper = _paywallARPHelper;
    }

    function setPaywallARPFactory(address _paywallARPFactory) external onlyAdmin {
        paywallARPFactory = _paywallARPFactory;
    }

    function setLenderFactory(address _lenderFactory) external onlyAdmin {
        lenderFactory = _lenderFactory;
    }

    function setVrfCoordinator(address _vrfCoordinator) external onlyAdmin {
        vrfCoordinator = _vrfCoordinator;
    }

    function setLinkToken(address _linkToken) external onlyAdmin {
        linkToken = _linkToken;
    }

    function setLotteryAddress(address _lotteryAddress) external onlyAdmin {
        lotteryAddress = _lotteryAddress;
    }

    function setLotteryHelper(address _lotteryHelper) external onlyAdmin {
        lotteryHelper = _lotteryHelper;
    }

    function setMarketOrders(address _marketOrders) external onlyAdmin {
        marketOrders = _marketOrders;
    }

    function setNFTMarketOrders(address _nftMarketOrders) external onlyAdmin {
        nftMarketOrders = _nftMarketOrders;
    }

    function setPaywallMarketOrders(address _paywallMarketOrders) external onlyAdmin {
        paywallMarketOrders = _paywallMarketOrders;
    }

    function setMarketPlaceEvents(address _marketPlaceEvents) external onlyAdmin {
        marketPlaceEvents = _marketPlaceEvents;
    }

    function setMarketCollections(address _marketCollections) external onlyAdmin {
        marketCollections = _marketCollections;
    }

    function setMarketTrades(address _marketTrades) external onlyAdmin {
        marketTrades = _marketTrades;
    }

    function setPaywallMarketTrades(address _paywallMarketTrades) external onlyAdmin {
        paywallMarketTrades = _paywallMarketTrades;
    }

    function setNFTMarketTrades(address _nftMarketTrades) external onlyAdmin {
        nftMarketTrades = _nftMarketTrades;
    }

    function setMarketHelpers(address _marketHelpers) external onlyAdmin {
        marketHelpers = _marketHelpers;
    }

    function setPaywallMarketHelpers(address _paywallMarketHelpers) external onlyAdmin {
        paywallMarketHelpers = _paywallMarketHelpers;
    }

    function setNFTMarketHelpers(address _nftMarketHelpers) external onlyAdmin {
        nftMarketHelpers = _nftMarketHelpers;
    }

    function setMarketHelpers2(address _marketHelpers2) external onlyAdmin {
        marketHelpers2 = _marketHelpers2;
    }

    function setPaywallMarketHelpers2(address _paywallMarketHelpers2) external onlyAdmin {
        paywallMarketHelpers2 = _paywallMarketHelpers2;
    }

    function setNFTMarketHelpers2(address _nftMarketHelpers2) external onlyAdmin {
        nftMarketHelpers2 = _nftMarketHelpers2;
    }

    function setMarketHelpers3(address _marketHelpers3) external onlyAdmin {
        marketHelpers3 = _marketHelpers3;
    }

    function setPaywallMarketHelpers3(address _paywallMarketHelpers3) external onlyAdmin {
        paywallMarketHelpers3 = _paywallMarketHelpers3;
    }

    function setNFTMarketHelpers3(address _nftMarketHelpers3) external onlyAdmin {
        nftMarketHelpers3 = _nftMarketHelpers3;
    }

    function setTrustBounty(address _trustBounty) external onlyAdmin {
        trustBounty = _trustBounty;
    }
    
    function setTrustBountyHelper(address _trustBountyHelper) external onlyAdmin {
        trustBountyHelper = _trustBountyHelper;
    }

    function setTrustBountyVoter(address _trustBountyVoter) external onlyAdmin {
        trustBountyVoter = _trustBountyVoter;
    }

    function setProfile(address _profile) external onlyAdmin {
        profile = _profile;
    }

    function setSSI(address _ssi) external onlyAdmin {
        ssi = _ssi;
    }

    function setBusinessVoter(address _businessVoter) external onlyAdmin {
        businessVoter = _businessVoter;
    }

    function setReferralVoter(address _referralVoter) external onlyAdmin {
        referralVoter = _referralVoter;
    }

    function setAcceleratorVoter(address _acceleratorVoter) external onlyAdmin {
        acceleratorVoter = _acceleratorVoter;
    }

    function setContributorVoter(address _contributorVoter) external onlyAdmin {
        contributorVoter = _contributorVoter;
    }

    function setNfticket(address _nfticket) external onlyAdmin {
        nfticket = _nfticket;
    }

    function setNfticketHelper(address _nfticketHelper) external onlyAdmin {
        nfticketHelper = _nfticketHelper;
    }

    function setNfticketHelper2(address _nfticketHelper2) external onlyAdmin {
        nfticketHelper2 = _nfticketHelper2;
    }

    function setPoolGauge(address _poolGauge) external onlyAdmin {
        poolGauge = _poolGauge;
    }

    function setToken(address _token) external onlyAdmin {
        token = _token;
    }

    function setMaxMessage(uint _maxMessage) external onlyAdmin {
        maxMessage = _maxMessage;
    }

    function setMinSuperChat(uint _minSuperChat) external onlyAdmin {
        minSuperChat = _minSuperChat;
    }
    
    function setMaximumSize(uint _maximumSize) external onlyAdmin {
        maximumSize = _maximumSize;
    }

    function setAdminShare(uint _adminShare) external onlyAdmin {
        adminShare = _adminShare;
    }

    function setValuepoolShare(uint _valuepoolShare) external onlyAdmin {
        valuepoolShare = _valuepoolShare;
    }

    function setDevaddr(address _devaddr) external {
        require(devaddr_ == address(0x0) || devaddr_ == msg.sender || 
            IProfile(profile).addressToProfileId(msg.sender) == 1
        );
        devaddr_ = _devaddr;
    }

    function getContents() external view returns(string[] memory _contents) {
        _contents = new string[](_contentIndices.length());
        for (uint i = 0; i < _contentIndices.length(); i++) {
            _contents[i] = indexToName[_contentIndices.at(i)];
        }
        return _contents;
    }

    function contains(string memory _contentName) public view returns(bool) {
        return _contentIndices.contains(uint(keccak256(abi.encodePacked(_contentName))));
    }

    function addContent(string memory _contentName) external onlyAdmin {
        indexToName[uint(keccak256(abi.encodePacked(_contentName)))] = _contentName;
        _contentIndices.add(uint(keccak256(abi.encodePacked(_contentName))));
    }

    function removeContent(string memory _contentName) external onlyAdmin {
        _contentIndices.remove(uint(keccak256(abi.encodePacked(_contentName))));
        delete indexToName[uint(keccak256(abi.encodePacked(_contentName)))];
    }
}

contract MarketPlaceCollection is Auth {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    
    mapping(uint => Collection) private _collections; // Details about the collections
    EnumerableSet.UintSet private _collectionAddressSet;
    mapping(address => uint) public addressToCollectionId;
    struct PriceInfo {
        uint start;
        uint period;
    }
    mapping(uint => uint[]) private _dynamicPrices;
    mapping(uint => PriceInfo) private _dynamicPriceInfo;
    address public contractAddress;
    uint collectionId = 1;
    uint public maximumArrayLength = 50;
    mapping(uint => EnumerableSet.AddressSet) private collectionTrustWorthyAuditors;
    
    uint256 public tradingFee = 1000;
    uint256 public lotteryFee;
    mapping(address => bool) public isBlacklisted;
    mapping(uint => uint) public collectionIdToProfileId;
    uint public maxDropinTimer = 86400 * 7;
    uint public cashbackBuffer;

    /**
     * @notice Constructor
     * @param _adminAddress: address of the admin
     */
    constructor(
        address _adminAddress,
        address __contractAddress
    ) Auth(__contractAddress, _adminAddress, __contractAddress) {
        contractAddress = __contractAddress;
    }

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1, "PMC0");
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function updateMaxDropinTimer(uint _newMaxDropinTimer, uint _cashbackBuffer) external onlyAdmin {
        maxDropinTimer = _newMaxDropinTimer;
        cashbackBuffer = _cashbackBuffer;
    }

    function updateProfileId() external {
        collectionIdToProfileId[addressToCollectionId[msg.sender]] = IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender);
    }

    function updateAddressToCollectionId(uint _collectionId, address _oldOwner) external {
        uint _profileId1 = collectionIdToProfileId[_collectionId];
        uint _profileId2 = IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender);
        require(_profileId1 == _profileId2 && _profileId2 > 0 && addressToCollectionId[_oldOwner] == _collectionId);
        addressToCollectionId[msg.sender] = _collectionId;
        delete addressToCollectionId[_oldOwner];
    }

    function updateCollectionTrustWorthyAuditors(address[] memory _gauges, bool _add) external {
        for (uint i = 0; i < _gauges.length; i++) {
            if (_add) {
                collectionTrustWorthyAuditors[addressToCollectionId[msg.sender]].add(_gauges[i]);
            } else {
                collectionTrustWorthyAuditors[addressToCollectionId[msg.sender]].remove(_gauges[i]);
            }
        }
    }

    function dynamicPrices(uint _collectionId) external view returns(uint[] memory, uint, uint) {
        return (
            _dynamicPrices[_collectionId],
            _dynamicPriceInfo[_collectionId].start,
            _dynamicPriceInfo[_collectionId].period
        );
    }
    
    function getAllCollectionTrustWorthyAuditors(address _collection, uint _start) external view returns(address[] memory _auditors) {
        _auditors = new address[](collectionTrustWorthyAuditors[addressToCollectionId[_collection]].length() - _start);
        for (uint i = _start; i < collectionTrustWorthyAuditors[addressToCollectionId[_collection]].length(); i++) {
            _auditors[i] = collectionTrustWorthyAuditors[addressToCollectionId[_collection]].at(i);
        }
    }

    function isCollectionTrustWorthyAuditor(uint _collectionId, address _auditor) external view returns(bool) {
        return collectionTrustWorthyAuditors[_collectionId].contains(_auditor);
    }

    function updateBlacklist(address[] memory _users, bool _add) external onlyChangeMinCosigners(msg.sender, 0) {
        for (uint i = 0; i < _users.length; i++) {
            isBlacklisted[_users[i]] = _add;
        }
    }

    function getCollection(uint _collectionId) external view returns(Collection memory) {
        return _collections[_collectionId];
    }

    function marketPlaceEvents() internal view returns(address) { 
        return IContract(contractAddress).marketPlaceEvents();
    }

    function badgeNft() internal view returns(address) { 
        return IContract(contractAddress).badgeNft();
    }

    /**
     * @notice Add a new collection
     * @param _referrerFee: referrer fee
     */
    function addCollection(
        uint _referrerFee,
        uint _badgeId,
        uint _minBounty,
        uint _userMinBounty,
        uint _recurringBounty,
        uint _identityTokenId,
        address _baseToken,
        bool _requestUserRegistration,
        bool _requestPartnerRegistration
    ) external {
        checkIdentityProof(msg.sender, _identityTokenId, true);
        require(!isBlacklisted[msg.sender], "PMC1");
        require(IProfile(IContract(contractAddress).profile()).sharedEmail(msg.sender), "PMC01");
        require(addressToCollectionId[msg.sender] == 0, "PMC2");
        require(_referrerFee + lotteryFee + tradingFee <= 10000, "PMC3");
        if (_badgeId > 0) require(ve(badgeNft()).ownerOf(_badgeId) == msg.sender, "PMC4");
        addressToCollectionId[msg.sender] = collectionId;
        _collectionAddressSet.add(collectionId);
        _collections[collectionId].status = Status.Open;
        _collections[collectionId].tradingFee = tradingFee;
        _collections[collectionId].referrerFee = _referrerFee;
        _collections[collectionId].owner = msg.sender;
        _collections[collectionId].badgeId = _badgeId;
        _collections[collectionId].recurringBounty = _recurringBounty;
        _collections[collectionId].minBounty = _minBounty;
        _collections[collectionId].userMinBounty = _userMinBounty;
        _collections[collectionId].baseToken = _baseToken;
        _collections[collectionId].requestUserRegistration = _requestUserRegistration;
        _collections[collectionId].requestPartnerRegistration = _requestPartnerRegistration;

        IMarketPlace(marketPlaceEvents()).
        emitCollectionNew(
            collectionId++, 
            msg.sender, 
            _baseToken,
            _referrerFee,
            _badgeId,
            tradingFee,
            _recurringBounty,
            _minBounty,
            _userMinBounty,
            _requestUserRegistration,
            _requestPartnerRegistration
        );
    }

    function updateCollection(
        string memory name, 
        string memory description, 
        string memory large,
        string memory small,
        string memory avatar,
        string memory contactChannels,
        string memory contacts,
        string memory workspaces,
        string memory countries,
        string memory cities,
        string memory products
    ) external {
        IMarketPlace(marketPlaceEvents()).
        emitUpdateCollection(
            addressToCollectionId[msg.sender],
            name,
            description,
            large,
            small,
            avatar,
            contactChannels,
            contacts,
            workspaces,
            countries,
            cities,
            products
        );
    }

    function _marketOrders(uint isPaywall) internal view returns(address) {
        if (isPaywall == 1) {
            return IContract(contractAddress).paywallMarketOrders();
        }
        return IContract(contractAddress).marketOrders();
    }

    function emitReview(
        uint _collectionId,
        string memory tokenId,
        uint userTokenId,
        uint isPaywall,
        bool superLike,
        string memory review
    ) external {
        uint vp;
        if (userTokenId > 0) {
            address marketOrders = _marketOrders(isPaywall);
            Ask memory ask = IMarketPlace(marketOrders).getAskDetails(_collectionId, keccak256(abi.encodePacked(tokenId)));
            require(ve(ask.tokenInfo.ve).ownerOf(userTokenId) == msg.sender, "PMC5");
            vp = ve(ask.tokenInfo.ve).balanceOfNFT(userTokenId);
        }
        IMarketPlace(marketPlaceEvents()).emitReview(
            _collectionId,
            tokenId,
            userTokenId,
            vp,
            superLike,
            isPaywall,
            review,
            msg.sender
        );
    }

    function emitAskInfo(
        string memory tokenId,
        string memory description,
        uint[] memory prices,
        uint start,
        uint period,
        uint isPaywall,
        bool isTradeable,
        string memory images,
        string memory countries,
        string memory cities,
        string memory products
    ) external {
        _dynamicPrices[addressToCollectionId[msg.sender]] = prices;
        _dynamicPriceInfo[addressToCollectionId[msg.sender]].start = start;
        _dynamicPriceInfo[addressToCollectionId[msg.sender]].period = Math.max(1,period);
        IMarketPlace(marketPlaceEvents()).
        emitAskInfo(
            addressToCollectionId[msg.sender],
            tokenId,
            description,
            prices,
            start,
            period,
            isPaywall,
            isTradeable,
            images,
            countries,
            cities,
            products
        );
    }

    /**
     * @notice Modify collection characteristics
     * @param _referrerFee: referrer fee
     */
    function modifyCollection(
        address _collection,
        uint256 _referrerFee,
        uint _badgeId,
        uint _minBounty,
        uint _userMinBounty,
        uint _recurringBounty,
        bool _requestUserRegistration,
        bool _requestPartnerRegistration
    ) external {
        require(!isBlacklisted[msg.sender] && !isBlacklisted[_collection], "PMC6");
        require(_referrerFee + lotteryFee + tradingFee <= 10000, "PMC7");
        require(addressToCollectionId[msg.sender] > 0, "PMC8");
        if (_badgeId > 0) require(ve(badgeNft()).ownerOf(_badgeId) == msg.sender, "PMC08");
        if (_collection != msg.sender) {
            require(addressToCollectionId[_collection] == 0, "PMC9");
            addressToCollectionId[_collection] = addressToCollectionId[msg.sender];
            delete addressToCollectionId[msg.sender];
        }
        _collections[addressToCollectionId[_collection]].status = Status.Open;
        _collections[addressToCollectionId[_collection]].owner = _collection;
        _collections[addressToCollectionId[_collection]].tradingFee = tradingFee;
        _collections[addressToCollectionId[_collection]].badgeId = _badgeId;
        _collections[addressToCollectionId[_collection]].minBounty = _minBounty;
        _collections[addressToCollectionId[_collection]].userMinBounty = _userMinBounty;
        _collections[addressToCollectionId[_collection]].referrerFee = _referrerFee;
        _collections[addressToCollectionId[_collection]].recurringBounty = _recurringBounty;
        _collections[addressToCollectionId[_collection]].requestUserRegistration = _requestUserRegistration;
        _collections[addressToCollectionId[_collection]].requestPartnerRegistration = _requestPartnerRegistration;
        IMarketPlace(marketPlaceEvents()).
        emitCollectionUpdate(
            addressToCollectionId[_collection],
            _collection,
            _referrerFee,
            _badgeId,
            tradingFee,
            _recurringBounty,
            _minBounty,
            _userMinBounty,
            _requestUserRegistration,
            _requestPartnerRegistration
        );
    }

    function modifyIdentityProof(
        address _collection,
        string memory _requiredIndentity,
        string memory _valueName,
        bool _onlyTrustWorthyAuditors,
        uint _maxUse,
        bool _isUserIdentity,
        bool _dataKeeperOnly,
        COLOR _minIDBadgeColor
    ) external {
        require(!isBlacklisted[msg.sender] && !isBlacklisted[_collection], "PMC10");
        require(addressToCollectionId[msg.sender] > 0, "PMC11");

        if (_isUserIdentity) {
            _collections[addressToCollectionId[_collection]].userIdentityProof.requiredIndentity = _requiredIndentity;
            _collections[addressToCollectionId[_collection]].userIdentityProof.minIDBadgeColor = _minIDBadgeColor;
            _collections[addressToCollectionId[_collection]].userIdentityProof.dataKeeperOnly = _dataKeeperOnly;
            _collections[addressToCollectionId[_collection]].userIdentityProof.valueName = _valueName;
            _collections[addressToCollectionId[_collection]].userIdentityProof.maxUse = _maxUse;
            _collections[addressToCollectionId[_collection]].userIdentityProof.onlyTrustWorthyAuditors = _onlyTrustWorthyAuditors;
        } else {
            _collections[addressToCollectionId[_collection]].partnerIdentityProof.requiredIndentity = _requiredIndentity;
            _collections[addressToCollectionId[_collection]].partnerIdentityProof.dataKeeperOnly = _dataKeeperOnly;
            _collections[addressToCollectionId[_collection]].partnerIdentityProof.minIDBadgeColor = _minIDBadgeColor;
            _collections[addressToCollectionId[_collection]].partnerIdentityProof.valueName = _valueName;
            _collections[addressToCollectionId[_collection]].partnerIdentityProof.maxUse = _maxUse;
            _collections[addressToCollectionId[_collection]].partnerIdentityProof.onlyTrustWorthyAuditors = _onlyTrustWorthyAuditors;
        }
        IMarketPlace(marketPlaceEvents()).
        emitCollectionUpdateIdentity(
            addressToCollectionId[_collection],
            _requiredIndentity,
            _valueName,
            _onlyTrustWorthyAuditors,
            _maxUse,
            _isUserIdentity,
            _dataKeeperOnly,
            _minIDBadgeColor
        );
    }

    /**
     * @notice Allows the admin to close collection for trading and new listing
     * @param _collection: collection address
     * @dev Callable by admin
     */
    function closeCollectionForTradingAndListing(address _collection) external onlyChangeMinCosigners(msg.sender, 0) {
        require(addressToCollectionId[_collection] != 0, "PMC12");

        _collections[addressToCollectionId[_collection]].status = Status.Close;
        _collectionAddressSet.remove(addressToCollectionId[_collection]);
        delete addressToCollectionId[_collection];

        IMarketPlace(marketPlaceEvents()).
        emitCollectionClose(addressToCollectionId[_collection]);
    }

    function updateParams(
        uint256 _tradingFee,
        uint256 _lotteryFee,
        uint256 _maximumArrayLength
    ) external onlyAdmin {
        tradingFee = _tradingFee;
        lotteryFee = _lotteryFee;
        maximumArrayLength = _maximumArrayLength;
    }

    /**
     * @notice Set admin address
     * @dev Only callable by owner
     */
    function setContractAddress(address __contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender, "PMC13");
        contractAddress = __contractAddress;
    }
}

contract PaywallMarketPlaceOrders {
    mapping(uint => mapping(bytes32 => Ask)) private _askDetails; // Ask details (price + seller address) for a given collection and a tokenId
    mapping(address => mapping(string => uint)) internal paymentCredits;
    address public contractAddress;

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender, "PPMO2");
        contractAddress = _contractAddress;
    }

    function getPaymentCredits(address _user, uint _collectionId, string memory _tokenId) external view returns(uint) {
        return paymentCredits[_user][string(abi.encodePacked(_collectionId, _tokenId))];
    }

    function updatePaymentCredits(address _user, uint _collectionId, string memory _tokenId) external {
        require(IContract(contractAddress).paywallMarketTrades() == msg.sender, "PPMO3");
        paymentCredits[_user][string(abi.encodePacked(_collectionId, _tokenId))] += 
        paymentCredits[_user][string(abi.encodePacked(_collectionId, ""))];
        paymentCredits[_user][string(abi.encodePacked(_collectionId, ""))] = 0;
    }

    function incrementPaymentCredits(address _user, uint _collectionId, string memory _tokenId, uint _price) external {
        address marketTrades = IContract(contractAddress).paywallMarketTrades();
        address marketHelpers = IContract(contractAddress).paywallMarketHelpers();
        address marketCollections = IContract(contractAddress).marketCollections();
        uint __collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
        require(marketTrades == msg.sender || marketHelpers == msg.sender || __collectionId == _collectionId, "PPMO4");
        paymentCredits[_user][string(abi.encodePacked(_collectionId, _tokenId))] += _price;
    }

    function decrementPaymentCredits(address _user, uint _collectionId, string memory _tokenId, uint _price) external {
        require(IContract(contractAddress).paywallMarketTrades() == msg.sender, "PPMO5");
        paymentCredits[_user][string(abi.encodePacked(_collectionId, _tokenId))] -= _price;
    }

    function getAskDetails(uint _collectionId, bytes32 _tokenId) external view returns(Ask memory) {
        return _askDetails[_collectionId][_tokenId];
    }

    function updateAfterSale(
        uint _collectionId,
        string memory _tokenId,
        uint _price, 
        uint _lastBidTime,
        address _lastBidder
    ) external {
        require(IContract(contractAddress).paywallMarketHelpers() == msg.sender, "PPMO6");
        _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].price = _price;
        _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].lastBidTime = _lastBidTime;
        _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].lastBidder = _lastBidder;
    }

    function decrementMaxSupply(uint _collectionId, bytes32 _tokenId) external {
        require(IContract(contractAddress).paywallMarketHelpers() == msg.sender, "PPMO7");
        if (_askDetails[_collectionId][_tokenId].maxSupply > 0) {
            _askDetails[_collectionId][_tokenId].maxSupply -= 1;
        }
    }

    /**
     * @notice Create ask order
     * @param _tokenId: tokenId of the NFT
     * @param _askPrice: price for listing (in wei)
     */
    function createAskOrder(
        string memory _tokenId,
        uint _askPrice,
        uint _bidDuration,
        int _minBidIncrementPercentage,
        bool _transferrable,
        bool _requireUpfrontPayment,
        bool _usetFIAT,
        uint _rsrcTokenId,
        uint _maxSupply,
        uint _dropinTimer,
        address _tFIAT,
        address _ve
    ) external {
        // Verify collection is accepted
        IMarketPlace(IContract(contractAddress).paywallMarketHelpers2())
        .checkRequirements(
            _ve, 
            msg.sender,
            _tFIAT, 
            _maxSupply, 
            _dropinTimer,
            _rsrcTokenId
        );
        uint _collectionId = _addOrder(
            _askPrice, 
            _tokenId,
            _bidDuration,
            _minBidIncrementPercentage,
            _transferrable,
            _rsrcTokenId,
            _maxSupply,
            _dropinTimer,
            _usetFIAT,
            _tFIAT,
            _ve
        );
        if (_requireUpfrontPayment) {
            _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].tokenInfo.requireUpfrontPayment = _requireUpfrontPayment;
        }
    }

    function _addOrder(
        uint _askPrice,
        string memory _tokenId,
        uint _bidDuration,
        int _minBidIncrementPercentage,
        bool _transferrable,
        uint _rsrcTokenId,
        uint _maxSupply,
        uint _dropinTimer,
        bool _usetFIAT,
        address _tFIAT,
        address _ve
    ) internal returns(uint _collectionId) {
        // Adjust the information
        address marketCollections = IContract(contractAddress).marketCollections();
        _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
        _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))] = Ask({
            seller: msg.sender,
            price: _askPrice,
            lastBidder: address(0x0),
            bidDuration: _bidDuration,
            lastBidTime: 0,
            minBidIncrementPercentage: _minBidIncrementPercentage,
            transferrable: _transferrable,
            rsrcTokenId: _rsrcTokenId,
            maxSupply: _maxSupply > 0 ? _maxSupply : type(uint).max,
            dropinTimer: block.timestamp + _dropinTimer,
            identityProof: IdentityProof({
                minIDBadgeColor: COLOR.BLACK,
                dataKeeperOnly: false,
                valueName: "",
                requiredIndentity: "",
                onlyTrustWorthyAuditors: false,
                maxUse: 0
            }),
            priceReductor: PriceReductor({
                discountStatus: Status.Close,  
                discountStart: 0, 
                cashbackStatus: Status.Close,
                cashbackStart: 0,
                cashNotCredit: false,   
                checkItemOnly: false,
                checkIdentityCode: false,
                discountNumbers: Discount(0,0,0,0,0,0),
                discountCost: Discount(0,0,0,0,0,0),    
                cashbackNumbers: Discount(0,0,0,0,0,0),
                cashbackCost: Discount(0,0,0,0,0,0)
            }),
            tokenInfo: TokenInfo({
                tFIAT: _tFIAT,
                ve: _ve,
                usetFIAT: _usetFIAT,
                requireUpfrontPayment: false
            })
        });
        
        // Emit event
        _emitAskNew(
            _collectionId, 
            _tokenId, 
            _askPrice, 
            _bidDuration,
            _minBidIncrementPercentage,
            _transferrable,
            _rsrcTokenId,
            _maxSupply,
            _dropinTimer,
            _tFIAT, 
            _ve
        );
    }

    function _emitAskNew(
        uint _collectionId, 
        string memory _tokenId, 
        uint _askPrice, 
        uint _bidDuration,
        int _minBidIncrementPercentage,
        bool _transferrable,
        uint _rsrcTokenId,
        uint _maxSupply,
        uint _dropinTimer,
        address _tFIAT, 
        address _ve
    ) internal {
        IMarketPlace(IContract(contractAddress).marketPlaceEvents()).
        emitAskNew(
            _collectionId, 
            _tokenId, 
            _askPrice, 
            _bidDuration,
            _minBidIncrementPercentage,
            _transferrable,
            _rsrcTokenId,
            _maxSupply,
            _dropinTimer,
            _tFIAT, 
            _ve
        );
    }
    
    /**
     * @notice Cancel existing ask order
     * @param __tokenId: tokenId of the NFT
     */
    function cancelAskOrder(string memory __tokenId) external {
        uint _tokenId = uint(keccak256(abi.encodePacked(__tokenId)));
        // Verify the sender has listed it
        address marketCollections = IContract(contractAddress).marketCollections();
        uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
        
        // Adjust the information
        delete _askDetails[_collectionId][keccak256(abi.encodePacked(__tokenId))];
        
        // Emit event
        address marketPlaceEvents = IContract(contractAddress).marketPlaceEvents();
        IMarketPlace(marketPlaceEvents).emitAskCancel(_collectionId, _tokenId);
    }

    function modifyAskOrderIdentity(
        string memory _tokenId,
        string memory _requiredIndentity,
        string memory _valueName,
        bool _onlyTrustWorthyAuditors,
        bool _dataKeeperOnly,
        uint _maxUse,
        COLOR _minIDBadgeColor
    ) external {
        address marketCollections = IContract(contractAddress).marketCollections();
        uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
        _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].identityProof.requiredIndentity = _requiredIndentity;
        _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].identityProof.minIDBadgeColor = _minIDBadgeColor;
        _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].identityProof.dataKeeperOnly = _dataKeeperOnly;
        _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].identityProof.valueName = _valueName;
        _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].identityProof.maxUse = _maxUse;
        _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].identityProof.onlyTrustWorthyAuditors = _onlyTrustWorthyAuditors;
    
        address marketPlaceEvents = IContract(contractAddress).marketPlaceEvents();
        IMarketPlace(marketPlaceEvents).
        emitAskUpdateIdentity(
            _collectionId,
            _tokenId,
            _requiredIndentity,
            _valueName,
            _onlyTrustWorthyAuditors,
            _dataKeeperOnly,
            _maxUse,
            _minIDBadgeColor
        );
    }
    
    /**
     * @notice Modify existing ask order
     * @param _tokenId: tokenId of the NFT
     */
    function modifyAskOrderDiscountPriceReductors(
        string memory _tokenId,
        Status _discountStatus,   
        uint _discountStart,   
        bool _cashNotCredit,
        bool _checkItemOnly,
        bool _checkIdentityCode,
        uint[6] memory __discountNumbers,
        uint[6] memory __discountCost 
    ) external {
        // Verify collection is accepted
        require(__discountNumbers[2] + __discountCost[2] <= 10000, "PPMO8");
        address marketCollections = IContract(contractAddress).marketCollections();
        uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
        {
            if (_discountStatus == Status.Open) {
                _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.discountStatus = _discountStatus;
                _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.discountStart = block.timestamp + _discountStart;
                _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.cashNotCredit = _cashNotCredit;
                _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.checkItemOnly = _checkItemOnly;
                _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.checkIdentityCode = _checkIdentityCode;
                _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.discountNumbers = Discount({
                    cursor: __discountNumbers[0],
                    size: __discountNumbers[1],
                    perct: __discountNumbers[2],
                    lowerThreshold: __discountNumbers[3],
                    upperThreshold: __discountNumbers[4],
                    limit: __discountNumbers[5]
                });
                _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.discountCost = Discount({
                    cursor: __discountCost[0],
                    size: __discountCost[1],
                    perct: __discountCost[2],
                    lowerThreshold: __discountCost[3],
                    upperThreshold: __discountCost[4],
                    limit: __discountCost[5]
                });
            }
        }
        // Emit event
        address marketPlaceEvents = IContract(contractAddress).marketPlaceEvents();
        IMarketPlace(marketPlaceEvents).
        emitAskUpdateDiscount(
            _collectionId, 
            _tokenId, 
            _discountStatus,   
            block.timestamp + _discountStart,   
            _cashNotCredit,
            _checkItemOnly,
            _checkIdentityCode,
            __discountNumbers,
            __discountCost
        );
    }
    
    /**
     * @notice Modify existing ask order
     * @param _tokenId: tokenId of the NFT
     */
    function modifyAskOrderCashbackPriceReductors(
        string memory _tokenId,
        Status _cashbackStatus,
        uint _cashbackStart,
        bool _checkItemOnly,
        bool _cashNotCredit,
        uint[6] memory __cashbackNumbers,
        uint[6] memory __cashbackCost
    ) external {
        // Verify collection is accepted
        require(__cashbackNumbers[2] + __cashbackCost[2] <= 10000, "PPMO9");
        address marketCollections = IContract(contractAddress).marketCollections();
        address marketHelpers2 = IContract(contractAddress).paywallMarketHelpers2();
        uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
        IMarketPlace(marketHelpers2).updateCashbackRevenue(msg.sender, _tokenId);
        {
            if (_cashbackStatus == Status.Open) {
                _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.cashbackStatus = _cashbackStatus;
                _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.cashbackStart = block.timestamp + _cashbackStart;
                _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.cashNotCredit = _cashNotCredit;
                _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.checkItemOnly = _checkItemOnly;
                _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.cashbackNumbers = Discount({
                    cursor: __cashbackNumbers[0],
                    size: __cashbackNumbers[1],
                    perct: __cashbackNumbers[2],
                    lowerThreshold: __cashbackNumbers[3],
                    upperThreshold: __cashbackNumbers[4],
                    limit: __cashbackNumbers[5]
                });
                _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.cashbackCost = Discount({
                    cursor: __cashbackCost[0],
                    size: __cashbackCost[1],
                    perct: __cashbackCost[2],
                    lowerThreshold: __cashbackCost[3],
                    upperThreshold: __cashbackCost[4],
                    limit: __cashbackCost[5]
                });
            }
        }
        // Emit event
        address marketPlaceEvents = IContract(contractAddress).marketPlaceEvents();
        IMarketPlace(marketPlaceEvents).
        emitAskUpdateCashback(
            _collectionId, 
            _tokenId, 
            _cashbackStatus,   
            block.timestamp + _cashbackStart,   
            _cashNotCredit,
            _checkItemOnly,
            __cashbackNumbers,
            __cashbackNumbers
        );
    }

    function addReferral(
        address _seller,
        address _referrer,
        string memory _tokenId,
        string memory _partnerTokenId,
        string memory _images,
        uint[3] memory _vals //[_referrerFee, _bountyId, type]
    ) external {
        require(msg.sender == _seller || msg.sender == _referrer, "PMO10");
        address marketCollections = IContract(contractAddress).marketCollections();
        address marketHelpers2 = IContract(contractAddress).paywallMarketHelpers2();
        uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_seller);
        uint _referrerCollectionId = IMarketPlace(marketCollections).addressToCollectionId(_referrer);
        if (_vals[2] == 5) {
            IMarketPlace(IContract(contractAddress).marketPlaceEvents()).emitAddReferral(
                _referrerCollectionId, 
                _collectionId, 
                _tokenId, 
                _vals[0],
                _vals[1]
            );
        } else {
            IMarketPlace(marketHelpers2).checkPaywallBounty(
                _referrer,
                _vals[0],
                _collectionId, 
                _vals[1],
                keccak256(abi.encodePacked(_tokenId))
            );
            IMarketPlace(IContract(contractAddress).marketPlaceEvents()).emitUpdateMiscellaneous(
                _vals[2], //isItem: 2, isNFT: 3, isPaywall: 4
                _collectionId, 
                _tokenId, 
                _partnerTokenId, 
                _referrerCollectionId, 
                _vals[0],
                address(0x0),
                _images
            );
        }
    }

    /**
     * @notice Modify existing ask order
     * @param _tokenId: tokenId of the NFT
     * @param _newPrice: new price for listing (in wei)
     */
    function modifyAskOrder(
        address _seller,
        string memory _tokenId,
        uint256 _newPrice,
        uint256 _bidDuration,
        int256 _minBidIncrementPercentage,
        bool _transferrable,
        bool _requireUpfrontPayment,
        uint256 _rsrcTokenId,
        uint256 _maxSupply,
        uint _dropinTimer
    ) external {
        // Verify collection is accepted
        address marketCollections = IContract(contractAddress).marketCollections();
        address marketPlaceEvents = IContract(contractAddress).marketPlaceEvents();
        uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
        require(_dropinTimer <= IMarketPlace(marketCollections).maxDropinTimer(), "PMO16");

        if (_rsrcTokenId != 0) {
            address badgeNft = IContract(contractAddress).badgeNft();
            require(IERC721(badgeNft).ownerOf(_rsrcTokenId) == msg.sender, "PMO17");
        }

        // Adjust the information
        _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].price = _newPrice;
        _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].seller = _seller;
        _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].bidDuration = _bidDuration;
        _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].rsrcTokenId = _rsrcTokenId;
        _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].minBidIncrementPercentage = _minBidIncrementPercentage;
        _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].transferrable = _transferrable;
        _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].dropinTimer = block.timestamp + _dropinTimer;
        _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].maxSupply = _maxSupply > 0 ? _maxSupply : type(uint).max;
        _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].tokenInfo.requireUpfrontPayment = _requireUpfrontPayment;
        
        // Emit event
        IMarketPlace(marketPlaceEvents).
        emitAskUpdate(
            _tokenId, 
            _seller,
            _collectionId, 
            _newPrice,
            _bidDuration,
            _minBidIncrementPercentage,
            _transferrable,
            _rsrcTokenId,
            _maxSupply,
            _dropinTimer
        );
    }
}

contract PaywallMarketPlaceTrades {
    using SafeERC20 for IERC20;

    mapping(address => uint) public treasuryRevenue;
    mapping(address => uint) public lotteryRevenue;
    mapping(address => mapping(uint => address)) public taxContracts;
    mapping(address => mapping(uint => uint256)) public pendingRevenue; // For creator/treasury to claim
    mapping(address => mapping(uint256 => uint256)) public pendingRevenueFromNote;
    mapping(address => mapping(uint => uint)) public cashbackFund;
    mapping(uint => mapping(address => uint)) public recurringBountyBalance;
    address public contractAddress;
    
    mapping(string => mapping(address => uint)) public discountLimits;
    mapping(string => mapping(address => uint)) private cashbackLimits;
    mapping(string => mapping(bytes32 => uint)) public identityLimits;
    struct Limits {
        uint cashbackLimits;
        uint discountLimits;
        uint identityLimits;
    }
    // collectionId => tokenId => version
    mapping(uint => mapping(bytes32 => Limits)) public merchantVersion;
    mapping(uint => mapping(bytes32 => Limits)) public userVersion;

    struct MerchantNote {
        uint start;
        uint end;
        uint lender;
    }
    mapping(address => MerchantNote) public notes;
    uint public permissionaryNoteTokenId = 1;

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }

    function marketOrders() internal view returns(address) {
        return IContract(contractAddress).paywallMarketOrders();
    }

    function marketHelpers() internal view returns(address) {
        return IContract(contractAddress).paywallMarketHelpers();
    }

    function marketHelpers2() internal view returns(address) {
        return IContract(contractAddress).paywallMarketHelpers2();
    }

    function marketHelpers3() internal view returns(address) {
        return IContract(contractAddress).paywallMarketHelpers3();
    }

    function marketPlaceEvents() internal view returns(address) {
        return IContract(contractAddress).marketPlaceEvents();
    }

    /**
     * @notice Buy token with WBNB by matching the price of an existing ask order
     * @param _collection: contract address of the NFT
     * @param _tokenId: tokenId of the NFT purchased
     */
    function buyWithContract(
        address _collection,
        address _user,
        address _referrer,
        string memory _tokenId,
        uint _userTokenId,
        uint _identityTokenId,
        uint256[] calldata _options
    ) external lock {
        uint _reducedPrice = _beforePurchase(_collection, _user, _identityTokenId, _tokenId, _options);
        _buyToken(_collection, _referrer, _user, _tokenId, _userTokenId, _reducedPrice, _options);
    }

    function _beforePurchase(
        address _collection,
        address _user,
        uint _identityTokenId,
        string memory _tokenId,
        uint[] memory _options
    ) internal returns(uint) {
        uint _collectionId = IMarketPlace(marketCollections()).addressToCollectionId(_collection);
        address _marketOrders = marketOrders();
        Ask memory ask = IMarketPlace(_marketOrders).getAskDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
        require(ask.dropinTimer < block.timestamp, "PPMT1");
        require(ask.maxSupply > 0, "PPMT2");
        bytes32 _identityCode = IMarketPlace(marketHelpers2()).checkOrderIdentityProof(
            _collectionId,
            _identityTokenId,
            _user, 
            _tokenId
        );
        IMarketPlace(_marketOrders).updatePaymentCredits(_user, _collectionId, _tokenId);
        (uint _price, bool _applied) = IMarketPlace(marketHelpers()).getRealPrice(_collection, _user, _tokenId, _options, _identityTokenId, ask.price);
        if (_price >= IMarketPlace(_marketOrders).getPaymentCredits(_user, _collectionId, _tokenId)) {
            _price -= IMarketPlace(_marketOrders).getPaymentCredits(_user, _collectionId, _tokenId);
            uint _credits = IMarketPlace(_marketOrders).getPaymentCredits(_user, _collectionId, _tokenId);
            IMarketPlace(_marketOrders).decrementPaymentCredits(
                _user, 
                _collectionId, 
                _tokenId, 
                _credits
            );
        } else {
            IMarketPlace(_marketOrders).decrementPaymentCredits(_user, _collectionId, _tokenId, _price);
            _price = 0;
        }
        if (_applied) {
            if (ask.priceReductor.checkIdentityCode) {
                identityLimits[string(abi.encodePacked(_collectionId, _tokenId))][_identityCode] += 1;
            }
            discountLimits[string(abi.encodePacked(_collectionId, _tokenId))][_user] += 1;
        }
        return _price;
    }

    function updateTaxContract(address _taxContract, address _token) external {
        uint _collectionId = IMarketPlace(marketCollections()).addressToCollectionId(msg.sender);
        taxContracts[_token][_collectionId] = _taxContract;
    }

    function updateIdVersion(uint _collectionId, string memory _tokenId, uint _identityTokenId) external {
        if (
            merchantVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].identityLimits > 
            userVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].identityLimits
        ) {
            address ssi = IContract(contractAddress).ssi();
            SSIData memory metadata = ISSI(ssi).getSSIData(_identityTokenId);
            SSIData memory metadata2 = ISSI(ssi).getSSID(metadata.senderProfileId);
            require(metadata.deadline > block.timestamp, "PPMT3");
            if (keccak256(abi.encodePacked(metadata2.answer)) != keccak256(abi.encodePacked(""))) {
                identityLimits[string(abi.encodePacked(_collectionId, _tokenId))][keccak256(abi.encodePacked(metadata2.answer))] = 0;
                userVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].identityLimits =
                merchantVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].identityLimits;
            }
        }
    }

    function updateVersion(uint _collectionId, string memory _tokenId, address _user) external {
        if (
            merchantVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].discountLimits > 
            userVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].discountLimits
        ) {
            discountLimits[string(abi.encodePacked(_collectionId, _tokenId))][_user] = 0;
            userVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].discountLimits =
            merchantVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].discountLimits;
        }
        if (
            merchantVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].cashbackLimits > 
            userVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].cashbackLimits
        ) {
            cashbackLimits[string(abi.encodePacked(_collectionId, _tokenId))][_user] = 0;
            userVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].cashbackLimits =
            merchantVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].cashbackLimits;
        }
    }

    function processCashBack(
        address _collection, 
        string memory _tokenId,
        bool _creditNotCash,
        string memory _applyToTokenId
    ) external lock {
        uint256 cashback1;
        uint256 cashback2;
        address nft_ = nfticket();
        uint _collectionId = IMarketPlace(marketCollections()).addressToCollectionId(_collection);
        Ask memory ask = IMarketPlace(marketOrders()).getAskDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
        {
            if (ask.priceReductor.cashbackStatus == Status.Open &&
                ask.priceReductor.cashbackStart <= block.timestamp
            ) {
                require(
                    cashbackLimits[string(abi.encodePacked(_collectionId, _tokenId))][msg.sender] < Math.max(ask.priceReductor.cashbackCost.limit, ask.priceReductor.cashbackNumbers.limit),
                    "PPMT4"
                );

                (uint256[] memory values1,) = INFTicket(nft_).getMerchantTicketsPagination(
                    _collectionId, 
                    ask.priceReductor.cashbackNumbers.cursor,
                    ask.priceReductor.cashbackNumbers.size,
                    ask.priceReductor.checkItemOnly ? _tokenId : ""
                );
                (,uint256 totalPrice2) = INFTicket(nft_).getMerchantTicketsPagination(
                    _collectionId, 
                    ask.priceReductor.cashbackCost.cursor,
                    ask.priceReductor.cashbackCost.size,
                    ask.priceReductor.checkItemOnly ? _tokenId : ""
                );
                
                if (values1.length >= ask.priceReductor.cashbackNumbers.lowerThreshold && 
                    values1.length <= ask.priceReductor.cashbackNumbers.upperThreshold
                ) {
                    cashback1 += ask.priceReductor.cashbackNumbers.perct;
                    if (totalPrice2 >= ask.priceReductor.cashbackCost.lowerThreshold && 
                        totalPrice2 <= ask.priceReductor.cashbackCost.upperThreshold
                    ) {
                        cashback2 += ask.priceReductor.cashbackCost.perct;
                    }
                }
            }
            if (!ask.priceReductor.cashNotCredit) {
                _creditNotCash = true;
            }
            (, uint256 totalPrice11) = INFTicket(nft_).getUserTicketsPagination(
                msg.sender, 
                _collectionId, 
                ask.priceReductor.cashbackNumbers.cursor,
                ask.priceReductor.cashbackNumbers.size,
                ask.priceReductor.checkItemOnly ? _tokenId : ""
            );
            (, uint256 totalPrice22) = INFTicket(nft_).getUserTicketsPagination(
                msg.sender, 
                _collectionId, 
                ask.priceReductor.cashbackCost.cursor,
                ask.priceReductor.cashbackCost.size,
                ask.priceReductor.checkItemOnly ? _tokenId : ""
            );
            uint256 totalCashback = cashback1 * totalPrice11 / 10000;
            totalCashback += cashback2 * totalPrice22 / 10000;  
            if (totalCashback > 0) cashbackLimits[string(abi.encodePacked(_collectionId, _tokenId))][msg.sender] += 1;
            address _token = ask.tokenInfo.usetFIAT ? ask.tokenInfo.tFIAT : ve(ask.tokenInfo.ve).token();

            if (!_creditNotCash) {
                IERC20(_token).safeTransfer(address(msg.sender), totalCashback);            
            } else {
                IMarketPlace(marketOrders()).incrementPaymentCredits(msg.sender,_collectionId, _applyToTokenId, totalCashback);
                pendingRevenue[_token][_collectionId] += Math.min(totalCashback, cashbackFund[_token][_collectionId]);
            }
            if (cashbackFund[_token][_collectionId] > totalCashback) {
                cashbackFund[_token][_collectionId] -= totalCashback; 
            } else {
                cashbackFund[_token][_collectionId] = 0;
            }
        }
    }

    function marketCollections() internal view returns(address) {
        return IContract(contractAddress).marketCollections();
    }

    function nfticket() internal view returns(address) {
        return IContract(contractAddress).nfticket();
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

    /**
     * @notice Claim pending revenue (treasury or creators)
     */
    function claimPendingRevenue(address _token, address _user, uint _identityTokenId) external lock {
        uint _collectionId = IMarketPlace(marketCollections()).addressToCollectionId(msg.sender);
        IMarketPlace(marketCollections()).checkIdentityProof(msg.sender, _identityTokenId, false);
        IERC20(_token).safeTransfer(address(_user), pendingRevenue[_token][_collectionId]);
        if (_isContract(_user)) {
            try IMarketPlace(_user).notifyRewardAmount(_token, pendingRevenue[_token][_collectionId])
            {} catch {}
        }
        IMarketPlace(marketPlaceEvents()).emitRevenueClaim(_user, pendingRevenue[_token][_collectionId]);
        pendingRevenue[_token][_collectionId] = 0;
    }

    function fundPendingRevenue(address _collection, address _token, uint _amount, bool _cashbackFund) external lock returns(uint) {
        IERC20(_token).safeTransferFrom(address(msg.sender), address(this), _amount);
        uint _collectionId = IMarketPlace(marketCollections()).addressToCollectionId(_collection);
        if (_cashbackFund) {
            cashbackFund[_token][_collectionId] += _amount;
            return cashbackFund[_token][_collectionId];
        }
        pendingRevenue[_token][_collectionId] += _amount;
        return pendingRevenue[_token][_collectionId];
    }

    function claimPendingRevenueFromNote(address _token, uint _tokenId, uint _identityTokenId) external lock {
        require(ve(marketHelpers3()).ownerOf(_tokenId) == msg.sender, "PPMT5");
        IMarketPlace(marketCollections()).checkIdentityProof(msg.sender, _identityTokenId, false);
        IERC20(_token).safeTransfer(address(msg.sender), pendingRevenueFromNote[_token][_tokenId]);
        IMarketPlace(marketPlaceEvents()).emitRevenueClaim(msg.sender, pendingRevenueFromNote[_token][_tokenId]);
        pendingRevenueFromNote[_token][_tokenId] = 0;
    }
    
    function transferDueToNote(uint _start, uint _end) external {
        require(notes[msg.sender].end < block.timestamp, "PPMT6");
        require(_end > _start, "PPMT7");
        notes[msg.sender] = MerchantNote({
            start: block.timestamp + _start,
            end: block.timestamp + _end,
            lender: permissionaryNoteTokenId
        });
        IMarketPlace(marketHelpers3()).mintNote(msg.sender, permissionaryNoteTokenId++);
    }
    
    function updatePendingRevenue(address _token, address _merchant, uint _revenue, bool _isReferrer) external {
        require(msg.sender == marketHelpers() || msg.sender == marketHelpers2(), "PPMT8");
        if (notes[_merchant].start < block.timestamp && 
            notes[_merchant].end >= block.timestamp && !_isReferrer) {
            pendingRevenueFromNote[_token][notes[_merchant].lender] += _revenue;
        } else {
            uint _collectionId = IMarketPlace(marketCollections()).addressToCollectionId(_merchant);
            pendingRevenue[_token][_collectionId] += _revenue;
            if (taxContracts[_token][_collectionId] != address(0x0)) {
                IBILL(taxContracts[_token][_collectionId]).notifyCredit(address(this), _merchant, _revenue);
            }
        }
    }

    function updateCashbackFund(address _token, uint _collectionId, uint _cashbackFee, bool _add) external {
        require(msg.sender == marketHelpers() || msg.sender == marketHelpers2(), "PPMT11");
        if (_add) {
            cashbackFund[_token][_collectionId] += _cashbackFee;
        } else {
            cashbackFund[_token][_collectionId] -= _cashbackFee;
        }
    }

    function updateTreasuryRevenue(address _token, uint _tradingFee) external {
        require(msg.sender == marketHelpers(), "PPMT12");
    
        treasuryRevenue[_token] += _tradingFee;
    }

    function updateLotteryRevenue(address _token, uint _lotteryFee) external {
        require(msg.sender == marketHelpers(), "PPMT13");
    
        lotteryRevenue[_token] += _lotteryFee;
    }

    function claimLotteryRevenue(address _token) external {
        require(msg.sender == IContract(contractAddress).lotteryAddress(), "PPMT14");
        IERC20(_token).safeTransfer(msg.sender, lotteryRevenue[_token]);
        lotteryRevenue[_token] = 0;
    }

    function claimTreasuryRevenue(address _token) external {
        require(msg.sender == IAuth(contractAddress).devaddr_(), "PPMT15");
        IERC20(_token).safeTransfer(msg.sender, treasuryRevenue[_token]);
        treasuryRevenue[_token] = 0;
    }

    function reinitializeIdentityLimits(string memory _tokenId) external {
        uint _collectionId = IMarketPlace(marketCollections()).addressToCollectionId(msg.sender);
        merchantVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].identityLimits += 1;
    }

    function reinitializeDiscountLimits(string memory _tokenId) external {
        uint _collectionId = IMarketPlace(marketCollections()).addressToCollectionId(msg.sender);
        merchantVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].discountLimits += 1;
    }

    function reinitializeCashbackLimits(string memory _tokenId) external {
        uint _collectionId = IMarketPlace(marketCollections()).addressToCollectionId(msg.sender);
        merchantVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].cashbackLimits += 1;
    }

    // /**
    //  * @notice Allows the owner to recover tokens sent to the contract by mistake
    //  * @param _token: token address
    //  * @dev Callable by owner
    //  */
    // function recoverFungibleTokens(address _token, uint amountToRecover) external {
    //     require(marketCollections == msg.sender);
    //     IERC20(_token).safeTransfer(address(msg.sender), amountToRecover);
    // }

    // /**
    //  * @notice Allows the owner to recover NFTs sent to the contract by mistake
    //  * @param _token: NFT token address
    //  * @param _tokenId: tokenId
    //  * @dev Callable by owner
    //  */
    // function recoverNonFungibleToken(address _token, uint _tokenId) external {
    //     require(marketCollections == msg.sender);
    //     IERC721(_token).safeTransferFrom(address(this), address(msg.sender), _tokenId);
    // }
    
    /**
     * @notice Buy token by matching the price of an existing ask order
     * @param _collection: contract address of the NFT
     * @param _tokenId: tokenId of the NFT purchased
     * @param _price: price (must match the askPrice from the seller)
     */
    function _buyToken(
        address _collection,
        address _referrer,
        address _user,
        string memory _tokenId,
        uint256 _userTokenId,
        uint256 _price,
        uint[] memory _options
    ) internal {
        address _marketHelpers = marketHelpers();
        uint _collectionId = IMarketPlace(marketCollections()).addressToCollectionId(_collection);
        Collection memory _itemCollection = IMarketPlace(marketCollections()).getCollection(_collectionId);
        require(_itemCollection.status == Status.Open, "PPMT16");
        Ask memory ask = IMarketPlace(marketOrders()).getAskDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
        address _token = ask.tokenInfo.usetFIAT ? ask.tokenInfo.tFIAT : ve(ask.tokenInfo.ve).token();
        if (ask.bidDuration != 0) { // Auction
            erc20(_token).approve(_marketHelpers, ask.price);
            IMarketPlace(_marketHelpers).checkAuction(_price, _collection, msg.sender, _tokenId);
        } else {
            if (IMarketPlace(IContract(contractAddress).paywallARPHelper()).isGauge(msg.sender)) {
                IERC20(_token).safeTransferFrom(_user, address(this), 100);
            } else {
                IERC20(_token).safeTransferFrom(msg.sender, address(this), _price);
            }
            IMarketPlace(_marketHelpers).processTrade(
                _collection,
                _referrer,
                _user,
                _tokenId,
                _userTokenId,
                _price,
                _options
            );
        }
    }

    function updateRecurringBountyRevenue(address _token, uint _collectionId, uint _amount) external {
        if (marketHelpers() != msg.sender) {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }
        recurringBountyBalance[_collectionId][_token] += _amount;
    }

    function withdrawRecurringBounty(address _referrer, address _token) external returns(uint _amount) {
        require(IContract(contractAddress).trustBounty() == msg.sender, "PPMT17");
        uint _referrerCollectionId = IMarketPlace(marketCollections()).addressToCollectionId(_referrer);
        _amount = recurringBountyBalance[_referrerCollectionId][_token];
        recurringBountyBalance[_referrerCollectionId][_token] = 0;
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }
}

contract PaywallMarketPlaceHelper {
    using SafeERC20 for IERC20;

    mapping(uint => Credit[]) public burnTokenForCredit;
    mapping(uint => mapping(string => PaywallOption[])) private paywallOptions;
    // The minimum amount of time left in an auction after a new bid is created
    address contractAddress;

    function getPaywallOptions(uint _collectionId, string memory _item, uint[] memory _indices) external view returns(PaywallOption[] memory) {
        return paywallOptions[_collectionId][_item];
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }

    function _beforePaymentApplyOptions(
        uint _collectionId, 
        string memory _tokenId,
        uint[] memory _options
    ) internal view returns(uint price) {
        for (uint i = 0; i < _options.length; i++) {
            price += paywallOptions[_collectionId][_tokenId][_options[i]].unitPrice;
        }
    }

    function getRealPrice(
        address _collection,
        address _user,
        string memory _tokenId,
        uint[] memory _options,
        uint _identityTokenId,
        uint _price
    ) external view returns(uint, bool) {
        address marketCollections = IContract(contractAddress).marketCollections();
        uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_collection);
        (uint [] memory _prices, uint _start, uint _period) = IMarketPlace(marketCollections).dynamicPrices(_collectionId);
        _period = Math.max(1,_period);
        if (block.timestamp >= _start &&
            ((block.timestamp - _start) / _period < _prices.length)
        ) {
            _price = _prices[(block.timestamp - _start) / _period];
        }
        _price += _beforePaymentApplyOptions(_collectionId, _tokenId, _options);
        uint __price = _beforePaymentApplyDiscount(
            _collectionId,
            IContract(contractAddress).paywallMarketTrades(), 
            _user, 
            _tokenId, 
            _identityTokenId, 
            _price
        );
        __price = _beforePaymentGetState(
            _collectionId,
            _user, 
            _tokenId, 
            __price
        );
        return (__price, _price != __price);
    }

    function _beforePaymentGetState(
        uint _collectionId,
        address _user,
        string memory _tokenId,
        uint _price
    ) internal view returns(uint) {
        address _paywallARP = IMarketPlace(IContract(contractAddress).paywallARPHelper())
        .collectionIdToPaywallARP(_collectionId);
        if (_paywallARP != address(0x0)) {
            return IMarketPlace(_paywallARP).getState(_user, _tokenId, _price);
        }
        return _price;
    }

    function _beforePaymentApplyDiscount(
        uint _collectionId,
        address marketTrades,
        address _user,
        string memory _tokenId,
        uint _identityTokenId,
        uint _price
    ) internal view returns(uint) {
        uint256 discount;
        Ask memory ask = IMarketPlace(IContract(contractAddress).paywallMarketOrders()).getAskDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));

        if (ask.priceReductor.discountStatus == Status.Open &&
            ask.priceReductor.discountStart <= block.timestamp
        ) {
            string memory cid = string(abi.encodePacked(_collectionId, _tokenId));
            bytes32 _ssid = _getSSID(_identityTokenId);
            uint _limit = ask.priceReductor.checkIdentityCode
            ? IMarketPlace(marketTrades).identityLimits(cid, _ssid)
            : IMarketPlace(marketTrades).discountLimits(cid, _user);
            if(_limit >= Math.max(ask.priceReductor.discountCost.limit, ask.priceReductor.discountNumbers.limit) ||
                (_ssid == keccak256(abi.encodePacked("")) && ask.priceReductor.checkIdentityCode)
            ) {
                return _price;
            }
            discount = IMarketPlace(IContract(contractAddress).paywallMarketHelpers3()).getDiscount(_collectionId, _user, _tokenId);
        }
        return discount == 0 ? _price : _price - _price * discount / 10000;
    }

    function _getSSID(uint _identityTokenId) internal view returns(bytes32) {
        address ssi = IContract(contractAddress).ssi();
        if (_identityTokenId > 0) {
            SSIData memory metadata = ISSI(ssi).getSSIData(_identityTokenId);
            SSIData memory metadata2 = ISSI(ssi).getSSID(metadata.senderProfileId);
            return keccak256(abi.encodePacked(metadata2.answer));
        }
        return keccak256(abi.encodePacked(""));
    }

    // /**
    //  * @notice Allows the owner to recover tokens sent to the contract by mistake
    //  * @param _token: token address
    //  * @dev Callable by owner
    //  */
    // function recoverFungibleTokens(address _token, uint amountToRecover) external {
    //     require(marketCollections == msg.sender);
    //     IERC20(_token).safeTransfer(address(msg.sender), amountToRecover);
    // }

    // /**
    //  * @notice Allows the owner to recover NFTs sent to the contract by mistake
    //  * @param _token: NFT token address
    //  * @param _tokenId: tokenId
    //  * @dev Callable by owner
    //  */
    // function recoverNonFungibleToken(address _token, uint _tokenId) external {
    //     require(marketCollections == msg.sender);
    //     IERC721(_token).safeTransferFrom(address(this), address(msg.sender), _tokenId);
    // }

    function checkAuction(
        uint256 _price,
        address _collection,
        address _user,
        string memory _tokenId
    ) external {
        address marketTrades = IContract(contractAddress).paywallMarketTrades();
        address marketOrders = IContract(contractAddress).paywallMarketOrders();
        require(marketTrades == msg.sender, "PPMH4");
        uint _collectionId = IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(_collection);
        Ask memory ask = IMarketPlace(marketOrders).getAskDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
        require(ask.lastBidTime == 0 || ask.lastBidTime + ask.bidDuration > block.timestamp, "PPMH5");
        uint _askPrice = ask.price;
        if (ask.lastBidTime != 0 && ask.minBidIncrementPercentage > 0) {
            _price += ask.price * uint(ask.minBidIncrementPercentage) / 10000;
            _askPrice += ask.price * uint(ask.minBidIncrementPercentage) / 10000;
        } else if (ask.lastBidTime != 0 && ask.minBidIncrementPercentage < 0) {
            if (ask.price * uint(-ask.minBidIncrementPercentage) / 10000 > _price) {
                _price = 0;
            } else {
                _price -= ask.price * uint(-ask.minBidIncrementPercentage) / 10000;
            }
            _askPrice -= ask.price * uint(-ask.minBidIncrementPercentage) / 10000;
        }
        // If this is the first valid bid, we should set the starting time now.
        // If it's not, then we should refund the last bidder
        address _token = ask.tokenInfo.usetFIAT ? ask.tokenInfo.tFIAT : ve(ask.tokenInfo.ve).token();
        IERC20(_token).safeTransferFrom(_user, marketTrades, _price);
        if(ask.lastBidTime != 0) {
            IERC20(_token).safeTransferFrom(marketTrades, ask.lastBidder, ask.price);
        }
        ask.price = _askPrice;
        ask.lastBidder = _user;
        ask.lastBidTime = block.timestamp;

        IMarketPlace(marketOrders).updateAfterSale(
            _collectionId,
            _tokenId,
            ask.price, 
            ask.lastBidTime,
            ask.lastBidder
        );
    }

    function processAuction(
        address _collection,
        address _referrer,
        address _user,
        string memory _tokenId,
        uint _userTokenId,
        uint[] memory _options
    ) external {
        uint _collectionId = IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(_collection);
        Ask memory ask = IMarketPlace(IContract(contractAddress).paywallMarketOrders()).getAskDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
        require(ask.lastBidTime + ask.bidDuration <= block.timestamp);
        require(ask.lastBidder == msg.sender, "PPMH7");
        _processTrade(
            _collection,
            _referrer,
            _tokenId,
            _collectionId,
            ask.price,
            ask
        );
        (uint256 netPrice, uint256 _tradingFee, uint256 _lotteryFee,,,) = _calculatePriceAndFeesForCollection(
            _collection,
            _referrer,
            _tokenId,
            ask.price
        );
        uint[5] memory _voteParams;
        _voteParams[0] = _userTokenId;
        _voteParams[1] = _tradingFee;
        _voteParams[2] = _lotteryFee;
        _voteParams[3] = netPrice;
        _voteParams[4] = ask.price;
        _mintNFTicket(_user, _referrer, _collectionId, _voteParams, _tokenId, _options, false);
    }

    function mintNFTicket(address _user, address _referrer, string memory _tokenId, uint[] memory _options) external {
        uint _collectionId = IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(msg.sender);
        IMarketPlace(IContract(contractAddress).paywallMarketOrders()).decrementMaxSupply(_collectionId, keccak256(abi.encodePacked(_tokenId)));
        uint[5] memory _voteParams;
        _mintNFTicket(_user, _referrer, _collectionId, _voteParams, _tokenId, _options, true);
    }

    function _mintNFTicket(address _user, address _referrer, uint _collectionId, uint[5] memory _voteParams, string memory _tokenId, uint[] memory _options, bool _external) internal {
        // Mint NFTicket to buyer
        INFTicket(IContract(contractAddress).nfticket()).mint(
            _user,
            _referrer,
            _collectionId,
            _tokenId,
            _voteParams,
            _options, 
            _external
        );
    }

    function processTrade(
        address _collection,
        address _referrer,
        address _user,
        string memory _tokenId,
        uint _userTokenId,
        uint _price,
        uint[] memory _options
    ) external {
        require(IContract(contractAddress).paywallMarketTrades() == msg.sender, "PPMH9");
        uint _collectionId = IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(_collection);
        Ask memory ask = IMarketPlace(IContract(contractAddress).paywallMarketOrders()).getAskDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
        _processTrade(
            _collection,
            _referrer,
            _tokenId,
            _collectionId,
            _price,
            ask
        );
        (uint256 netPrice, uint256 _tradingFee, uint256 _lotteryFee,,,) = _calculatePriceAndFeesForCollection(
            _collection,
            _referrer,
            _tokenId,
            _price
        );
        uint[5] memory _voteParams;
        _voteParams[0] = _userTokenId;
        _voteParams[1] = _tradingFee;
        _voteParams[2] = _lotteryFee;
        _voteParams[3] = netPrice;
        _voteParams[4] = ask.price;
        _mintNFTicket(_user, _referrer, _collectionId, _voteParams, _tokenId, _options, false);
    }

    function _processTrade(
        address _collection,
        address _referrer,
        string memory _tokenId,
        uint _collectionId,
        uint _price,
        Ask memory ask
    ) internal {
        // require(ask.seller != _user, "PMH10");
        // Calculate the net price (collected by seller), trading fee (collected by treasury), creator fee (collected by creator)
        (uint256 netPrice, uint256 _tradingFee, uint256 _lotteryFee, uint256 _referrerFee, uint256 _cashbackFee, uint _recurringFee) = 
        _calculatePriceAndFeesForCollection(
            _collection,
            _referrer,
            _tokenId,
            _price
        );
        uint[6] memory prices;
        prices[0] = netPrice;
        prices[1] = _tradingFee;
        prices[2] = _lotteryFee;
        prices[3] = _referrerFee;
        prices[4] = _cashbackFee;
        prices[5] = _recurringFee;
        _processTx(
            _referrer,
            _tokenId,
            _collectionId,
            prices,
            ask
        );
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
        uint _collectionId = IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(msg.sender);
        if(_clear) {
            delete burnTokenForCredit[_collectionId];
        }
        burnTokenForCredit[_collectionId].push(Credit({
            token: _token,
            item: _item,
            checker: _checker,
            discount: _discount,
            destination: _destination,
            collectionId: __collectionId
        }));
    }

    function burnTokenForCreditLength(uint _collectionId) external view returns(uint) {
        return burnTokenForCredit[_collectionId].length;
    }

    function burnForCredit(
        address _collection, 
        uint _position, 
        uint _number,  // tokenId in case of NFTs and amount otherwise 
        string memory _applyToTokenId
    ) external {
        uint _collectionId = IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(_collection);
        address _destination = burnTokenForCredit[_collectionId][_position].destination == IContract(contractAddress).paywallMarketTrades() 
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
        IMarketPlace(IContract(contractAddress).paywallMarketOrders()).
        incrementPaymentCredits(msg.sender, _collectionId, _applyToTokenId, credit);
    }

    function updateOptions(
        string memory _tokenId,
        uint[] memory _mins,
        uint[] memory _maxs,
        uint[] memory _values,
        uint[] memory _unitPrices,
        string[] memory _categories,
        string[] memory _elements,
        string[] memory _traitTypes,
        string[] memory _currencies
    ) external {
        // Verify collection is accepted
        address marketCollections = IContract(contractAddress).marketCollections();
        uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
        require(_mins.length <= IMarketPlace(marketCollections).maximumArrayLength());
        
        delete paywallOptions[_collectionId][_tokenId];
        for (uint i = 0; i < _mins.length; i++) {
            paywallOptions[_collectionId][_tokenId].push(PaywallOption({
                id: i,
                min: _mins[i],
                max: _maxs[i],
                value: _values[i],
                unitPrice: _unitPrices[i],
                category: _categories[i],
                element: _elements[i],
                traitType: _traitTypes[i],
                currency: _currencies[i]
            }));
            IMarketPlace(IContract(contractAddress).marketPlaceEvents()).
            emitPaywallUpdateOptions(_collectionId,_tokenId,_mins[i],_maxs[i],_values[i],_unitPrices[i],_categories[i],_elements[i],_traitTypes[i],_currencies[i]);
        }
    }

    function _processTx(
        address _referrer,
        string memory _tokenId,
        uint _collectionId,
        uint[6] memory prices,
        Ask memory ask
    ) internal {
        address marketTrades = IContract(contractAddress).paywallMarketTrades();
        address marketOrders = IContract(contractAddress).paywallMarketOrders();
        address _token = ask.tokenInfo.usetFIAT ? ask.tokenInfo.tFIAT : ve(ask.tokenInfo.ve).token();
        
        // Transfer _token
        IMarketPlace(marketTrades).
        updatePendingRevenue(_token, ask.seller, prices[0], false);
        IMarketPlace(marketTrades).
        updateCashbackFund(_token, _collectionId, prices[4], true);
        // Update pending revenues for treasury/creator (if any!)
        if (prices[3] != 0 && _referrer != address(0x0)) {
            IMarketPlace(marketTrades).
            updatePendingRevenue(_token, _referrer, prices[3], true);
        }
        // Update trading fee if not equal to 0
        if (prices[1] != 0) {
            IMarketPlace(marketTrades).updateTreasuryRevenue(_token, prices[1]);
        }
        if (prices[2] != 0) {
            IMarketPlace(marketTrades).updateLotteryRevenue(_token, prices[2]);
        }
        if (prices[5] != 0) {
            IMarketPlace(marketTrades).updateRecurringBountyRevenue(_token, _collectionId, prices[5]);
        }
        IMarketPlace(marketOrders).decrementMaxSupply(_collectionId, keccak256(abi.encodePacked(_tokenId)));
    }

    /**
     * @notice Calculate price and associated fees for a collection
     * @param _collection: address of the collection
     * @param _askPrice: listed price
     */
    function _calculatePriceAndFeesForCollection(
        address _collection, 
        address _referrer, 
        string memory _tokenId,
        uint256 _askPrice
    )
        internal
        view
        returns (
            uint256 netPrice,
            uint256 _tradingFee,
            uint256 _lotteryFee,
            uint256 _referrerFee,
            uint256 _cashbackFee,
            uint256 _recurringFee
        )
    {
        address marketCollections = IContract(contractAddress).marketCollections();
        uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_collection);
        Collection memory __collection = IMarketPlace(marketCollections).getCollection(_collectionId);
        _tradingFee = (_askPrice * __collection.tradingFee) / 10000;
        _lotteryFee = (_askPrice * IMarketPlace(marketCollections).lotteryFee()) / 10000;
        if (_referrer != address(0x0)) {
            uint _referrerCollectionId = IMarketPlace(marketCollections).addressToCollectionId(_referrer);
            (,uint _referrerShare,) = IMarketPlace(IContract(contractAddress).marketHelpers2()).getReferral(_referrerCollectionId, _tokenId);
            _referrerFee = (_askPrice * _referrerShare) / 10000;
            if (__collection.recurringBounty > 0) _recurringFee = (_askPrice * __collection.recurringBounty) / 10000;
        }
        Ask memory ask = IMarketPlace(IContract(contractAddress).marketOrders()).getAskDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
        netPrice = _askPrice - _tradingFee - _lotteryFee - _referrerFee - _recurringFee;
        if (ask.priceReductor.cashNotCredit) { 
            _cashbackFee = netPrice * (ask.priceReductor.cashbackNumbers.perct + ask.priceReductor.cashbackCost.perct) / 10000;
        }
        netPrice -= _cashbackFee;
    }
}

contract PaywallMarketPlaceHelper2 {
    using EnumerableSet for EnumerableSet.UintSet;
    using Percentile for *;

    mapping(bytes32 => mapping(bytes32 => uint)) private identityProofs;
    mapping(uint => mapping(bytes32 => bool)) private blackListedIdentities;
    mapping(uint => mapping(bytes32 => Referral)) internal _referrals; // Ask details (price + seller address) for a given collection and a tokenId
    struct CB {
        uint bufferTime;
        uint amount;
    }
    mapping(uint => mapping(bytes32 => CB)) public cashbackRevenue;
    address contractAddress;
    EnumerableSet.UintSet private _allVoters;
    mapping(string => uint) public percentiles;
    struct Vote {
        uint likes;
        uint dislikes;
    }
    uint private sum_of_diff_squared;
    mapping(string => Vote) public votes;
    mapping(uint => mapping(string => int)) public voted;
    mapping(uint => address) public tokenIdToAuditor;
    mapping(uint => mapping(bytes32 => bool)) private _canPublish;

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender, "PMHH1");
        contractAddress = _contractAddress;
    }

    function _bountyInfo(uint _bountyId) internal view returns (address,address,address,bool,uint) {
        address trustBounty = IContract(contractAddress).trustBounty();
        (address owner,address _token,,address claimableBy,,,,,,bool recurring) = ITrustBounty(trustBounty).bountyInfo(_bountyId);
        uint _limit = ITrustBounty(trustBounty).getBalance(_bountyId);
        return (
            owner,
            _token,
            claimableBy,
            recurring,
            _limit
        );
    }

    function getCanPublish(uint _collectionId, string memory _tokenId) external view returns(bool) {
        return _canPublish[_collectionId][keccak256(abi.encodePacked(_tokenId))];
    }
    
    function updateCanPublish(string memory _tokenId, bool _add) external {
        uint _collectionId = IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(msg.sender);
        _canPublish[_collectionId][keccak256(abi.encodePacked(_tokenId))] = _add;
        IMarketPlace(IContract(contractAddress).marketPlaceEvents()).
        emitUpdateMiscellaneous(
            1,
            _collectionId, 
            _tokenId, 
            "", 
            _add ? 1 : 0, 
            0,
            address(0x0),
            ""
        );
    }

    function checkPaywallBounty(
        address _referrer,
        uint _referrerFee,
        uint _collectionId, 
        uint _bountyId,
        bytes32 _tokenId
    ) external {
        address marketCollections = IContract(contractAddress).marketCollections();
        uint _referrerCollectionId = IMarketPlace(marketCollections).addressToCollectionId(_referrer);
        Collection memory _collection = IMarketPlace(marketCollections).getCollection(_collectionId);
        require(IMarketPlace(IContract(contractAddress).marketHelpers2()).partnerShip(_collectionId, _referrerCollectionId), "PPMHH2");
        require(_referrerFee >= _collection.referrerFee, "PPMHH002");
        require(_canPublish[_collectionId][_tokenId], "PPMHH02");
        if (_collection.minBounty > 0) {
            (address owner,address _token,address claimableBy,bool recurring,uint _limit) = _bountyInfo(_bountyId);
            Ask memory _ask = IMarketPlace(IContract(contractAddress).paywallMarketOrders()).getAskDetails(_collectionId, _tokenId);
            address __token = _ask.tokenInfo.usetFIAT ? _ask.tokenInfo.tFIAT : ve(_ask.tokenInfo.ve).token();
            require(
                owner == _referrer && __token == _token && 
                claimableBy == address(0x0) && _collection.minBounty <= _limit, 
                "PPMHH3"
            );
            if(_collection.recurringBounty > 0) require(recurring, "PPMHH4");
        }
        _referrals[_referrerCollectionId][_tokenId] = Referral({
            collectionId: _collectionId,
            referrerFee: _referrerFee,
            bountyId: _bountyId
        });
    }
    
    function closeReferral(
        address _seller,
        address _referrer,
        uint _idx,
        string memory _tokenId,
        string memory _partnerTokenId,
        string memory _images
    ) external {
        require(msg.sender == _seller || msg.sender == _referrer, "PPMHH5");
        address marketCollections = IContract(contractAddress).marketCollections();
        address marketPlaceEvents = IContract(contractAddress).marketPlaceEvents();
        uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_seller);
        uint _referrerCollectionId = IMarketPlace(marketCollections).addressToCollectionId(_referrer);
        require(_referrals[_referrerCollectionId][keccak256(abi.encodePacked(_tokenId))].collectionId == _collectionId, "PPMHH6");
        delete _referrals[_referrerCollectionId][keccak256(abi.encodePacked(_tokenId))];
        
        IMarketPlace(marketPlaceEvents).emitUpdateMiscellaneous(
            _idx, //removeItem: 5, removeNFT: 6, removePaywall: 7, removePaywallFromPartnerWall: 8&9
            _collectionId, 
            _tokenId, 
            _partnerTokenId, 
            _referrerCollectionId, 
            0,
            address(0x0),
            _images
        );
    }

    function checkRequirements(
        address _ve, 
        address _user,
        address _tFIAT, 
        uint _maxSupply, 
        uint _dropinTimer,
        uint _rsrcTokenId
    ) external view {
        address marketCollections = IContract(contractAddress).marketCollections();
        address marketHelpers3 = IContract(contractAddress).marketHelpers3();
        uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_user);
        Collection memory _collection = IMarketPlace(marketCollections).getCollection(_collectionId);
        require(_collection.status == Status.Open && _maxSupply != 0, "PPMHH7");
        require(_dropinTimer <= IMarketPlace(marketCollections).maxDropinTimer(), "PPMHH8");
        require(IMarketPlace(marketHelpers3).veTokenSetContains(_ve), "PPMHH9");
        require(IMarketPlace(marketHelpers3).dTokenSetContains(_tFIAT), "PPMHH10");
        
        if (_rsrcTokenId != 0) {
            require(ve(IContract(contractAddress).badgeNft()).ownerOf(_rsrcTokenId) == _user, "PPMHH11");
        }
    }

    function _resetVote(string memory _cid, uint profileId) internal {
        if (voted[profileId][_cid] > 0) {
            votes[_cid].likes -= 1;
        } else if (voted[profileId][_cid] < 0) {
            votes[_cid].dislikes -= 1;
        }
    }

    function vote(uint _merchant, string memory _tokenId, uint profileId, bool like) external {
        require(IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender) == profileId, "PPMHH12");
        SSIData memory metadata = ISSI(IContract(contractAddress).ssi()).getSSID(profileId);
        require(keccak256(abi.encodePacked(metadata.answer)) != keccak256(abi.encodePacked("")), "PPMHH13");
        string memory cid = string(abi.encodePacked(_merchant, _tokenId));
        _resetVote(cid, profileId);        
        if (like) {
            votes[cid].likes += 1;
            voted[profileId][cid] = 1;
        } else {
            votes[cid].dislikes += 1;
            voted[profileId][cid] = -1;
        }
        uint _merchantVotes;
        if (votes[cid].likes > votes[cid].dislikes) {
            _merchantVotes = votes[cid].likes - votes[cid].dislikes;
        }
        _allVoters.add(profileId);
        (uint percentile, uint sods) = Percentile.computePercentileFromData(
            false,
            _merchantVotes,
            _allVoters.length(),
            _allVoters.length(),
            sum_of_diff_squared
        );
        sum_of_diff_squared = sods;
        percentiles[cid] = percentile;
        IMarketPlace(IContract(contractAddress).marketPlaceEvents()).
        emitVoted(_merchant, profileId, _tokenId, votes[cid].likes, votes[cid].dislikes, like);
    }

    function checkOrderIdentityProof(
        uint _collectionId, 
        uint _identityTokenId,
        address _owner,
        string memory _tokenId
     ) external returns(bytes32) {
        Ask memory ask = IMarketPlace(IContract(contractAddress).paywallMarketOrders()).getAskDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
        string memory valueName = ask.identityProof.valueName;
        string memory requiredIndentity = ask.identityProof.requiredIndentity;
        bool onlyTrustWorthyAuditors = ask.identityProof.onlyTrustWorthyAuditors;
        bool dataKeeperOnly = ask.identityProof.dataKeeperOnly;
        uint maxUse = ask.identityProof.maxUse;
        COLOR minIDBadgeColor = ask.identityProof.minIDBadgeColor;
        _checkIdentityProof(
            _owner,
            IContract(contractAddress).ssi(),
            _collectionId,
            _identityTokenId,
            valueName,
            requiredIndentity,
            onlyTrustWorthyAuditors,
            dataKeeperOnly,
            minIDBadgeColor
        );
        return _checkMaxUse(
            keccak256(abi.encodePacked(_collectionId, _tokenId)),
            keccak256(abi.encodePacked(valueName)),
            maxUse,
            _identityTokenId
        );
    }

    function _checkMaxUse(
        bytes32 _productCode,
        bytes32 _valueNameCode,
        uint maxUse,
        uint _identityTokenId
    ) internal returns(bytes32) {
        if (_valueNameCode != keccak256(abi.encodePacked(""))) {
            address ssi = IContract(contractAddress).ssi();
            SSIData memory metadata = ISSI(ssi).getSSIData(_identityTokenId);
            SSIData memory metadata2 = ISSI(ssi).getSSID(metadata.senderProfileId);
            if (maxUse > 0) {
                require(keccak256(abi.encodePacked(metadata2.answer)) != keccak256(abi.encodePacked("")), "PPMHH14");
                require(identityProofs[_productCode][keccak256(abi.encodePacked(metadata2.answer))] < maxUse, "PPMHH15");
            }
            identityProofs[_productCode][keccak256(abi.encodePacked(metadata2.answer))] += 1;
            return keccak256(abi.encodePacked(metadata2.answer));
        }
        return keccak256(abi.encodePacked(""));
    }
    
    function _checkIdentityProof(
        address _owner, 
        address ssi,
        uint _collectionId, 
        uint _identityTokenId,
        string memory valueName,
        string memory requiredIndentity,
        bool onlyTrustWorthyAuditors,
        bool dataKeeperOnly,
        COLOR minIDBadgeColor
    ) internal view {
        if (keccak256(abi.encodePacked(valueName)) != keccak256(abi.encodePacked(""))) {
            address marketHelpers3 = IContract(contractAddress).marketHelpers3();
            require(ve(ssi).ownerOf(_identityTokenId) == _owner, "PPMHH16");
            SSIData memory metadata = ISSI(ssi).getSSIData(_identityTokenId);
            require(metadata.deadline > block.timestamp, "PPMHH17");
            bytes32 _ssid = IMarketPlace(marketHelpers3).getGaugeNColor(
                metadata,
                _collectionId,
                minIDBadgeColor,
                dataKeeperOnly,
                onlyTrustWorthyAuditors
            );
            require(keccak256(abi.encodePacked(metadata.question)) == keccak256(abi.encodePacked(requiredIndentity)), "PPMHH19"); 
            require(keccak256(abi.encodePacked(metadata.answer)) == keccak256(abi.encodePacked(valueName)), "PPMHH20");
            require(!blackListedIdentities[_collectionId][_ssid], "PPMHH22");
        }
    }

    function updateBlacklistedIdentities(uint[] memory userProfileIds, bool blacklist) external {
        uint _collectionId = IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(msg.sender);
        for (uint i = 0; i < userProfileIds.length; i++) {
            SSIData memory metadata = ISSI(IContract(contractAddress).ssi()).getSSID(userProfileIds[i]);
            if (keccak256(abi.encodePacked(metadata.answer)) != keccak256(abi.encodePacked(""))) {
                blackListedIdentities[_collectionId][keccak256(abi.encodePacked(metadata.answer))] = blacklist;
            }
        }
    }

    function updateCashbackRevenue(address _collection, string memory _tokenId) external {
        address nft_ = IContract(contractAddress).nfticket();
        address marketOrders = IContract(contractAddress).paywallMarketOrders();
        require(marketOrders == msg.sender, "PPMHH24");
        uint _collectionId = IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(_collection);
        Ask memory ask = IMarketPlace(marketOrders).getAskDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
        if (ask.priceReductor.cashbackStatus == Status.Open &&
            ask.priceReductor.cashbackStart <= block.timestamp
        ) {
            require(ask.priceReductor.cashbackNumbers.size < block.timestamp &&
                ask.priceReductor.cashbackCost.size < block.timestamp, "PPMHH25");
            (uint256[] memory values1,) = INFTicket(nft_).getMerchantTicketsPagination(
                _collectionId, 
                ask.priceReductor.cashbackNumbers.cursor,
                ask.priceReductor.cashbackNumbers.size,
                ask.priceReductor.checkItemOnly ? _tokenId : ""
            );
            (,uint256 totalPrice2) = INFTicket(nft_).getMerchantTicketsPagination(
                _collectionId, 
                ask.priceReductor.cashbackCost.cursor,
                ask.priceReductor.cashbackCost.size,
                ask.priceReductor.checkItemOnly ? _tokenId : ""
            );
            bool _passedFirstTest = values1.length >= ask.priceReductor.cashbackNumbers.lowerThreshold && 
                values1.length <= ask.priceReductor.cashbackNumbers.upperThreshold;
            bool _passedSecondTest = totalPrice2 >= ask.priceReductor.cashbackCost.lowerThreshold && 
                    totalPrice2 <= ask.priceReductor.cashbackCost.upperThreshold;
            if (!_passedFirstTest || !_passedSecondTest) {
                address marketTrades = IContract(contractAddress).paywallMarketTrades();
                address _token = ask.tokenInfo.usetFIAT ? ask.tokenInfo.tFIAT : ve(ask.tokenInfo.ve).token();
                uint _amount = IMarketPlace(marketTrades).cashbackFund(_token, _collectionId);
                cashbackRevenue[_collectionId][keccak256(abi.encodePacked(_tokenId))].amount = _amount;
                cashbackRevenue[_collectionId][keccak256(abi.encodePacked(_tokenId))].bufferTime = block.timestamp + ask.priceReductor.cashbackNumbers.size +
                ask.priceReductor.cashbackCost.size - ask.priceReductor.cashbackNumbers.cursor - ask.priceReductor.cashbackCost.cursor;
                IMarketPlace(marketTrades).updateCashbackFund(_token, _collectionId, _amount, false);
            }
        }
    }

    function addCashBackToRevenue(string memory _tokenId) external {
        uint _collectionId = IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(msg.sender);
        require(cashbackRevenue[_collectionId][keccak256(abi.encodePacked(_tokenId))].bufferTime < block.timestamp, "PPMHH26");
        Ask memory ask = IMarketPlace(IContract(contractAddress).paywallMarketOrders()).getAskDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
        address _token = ask.tokenInfo.usetFIAT ? ask.tokenInfo.tFIAT : ve(ask.tokenInfo.ve).token();
        IMarketPlace(IContract(contractAddress).paywallMarketTrades()).updatePendingRevenue(
            _token, 
            ask.seller, 
            cashbackRevenue[_collectionId][keccak256(abi.encodePacked(_tokenId))].amount,
            false
        );
        cashbackRevenue[_collectionId][keccak256(abi.encodePacked(_tokenId))].amount = 0;
    }

    function getReferral(uint _referrerCollectionId, string memory _tokenId) external view returns(Referral memory) {
        return _referrals[_referrerCollectionId][keccak256(abi.encodePacked(_tokenId))];
    }
}

contract PaywallMarketPlaceHelper3 is ERC721Pausable {
    address public contractAddress;

    /**
     * @notice Constructor
     */
    constructor() ERC721("CanCanPaywallNote", "pwnCanCan") {}

    modifier onlyAdmin() {
        require(IAuth(contractAddress).devaddr_() == msg.sender, "PPMHHH1");
        _;
    }

    function mintNote(address to, uint tokenId) external {
        require(msg.sender == IContract(contractAddress).paywallMarketTrades(), "PPMHHH2");
        _safeMint(to, tokenId, msg.data);
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender, "PPMHHH3");
        contractAddress = _contractAddress;
    }

    function _constructTokenURI(uint _tokenId, string[] memory description, string[] memory optionNames, string[] memory optionValues) internal view returns(string memory) {
        return IMarketPlace(IContract(contractAddress).nftSvg()).constructTokenURI(
            _tokenId,
            "",
            address(this),
            ownerOf(_tokenId),
            ownerOf(_tokenId),
            address(0x0),
            new string[](1),
            optionNames,
            optionValues,
            description
        );
    }

    function tokenURI(uint _tokenId) public override view returns (string memory output) {
        uint idx;
        string[] memory optionNames = new string[](5);
        string[] memory optionValues = new string[](5);
        address owner = ownerOf(_tokenId);
        uint merchantId = IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(owner);
        (uint start, uint end,) = IMarketPlace(IContract(contractAddress).nftMarketTrades()).notes(owner);
        optionValues[idx++] = toString(_tokenId);
        optionNames[idx] = "MID";
        optionValues[idx++] = toString(merchantId);
        optionNames[idx] = "Start";
        optionValues[idx++] = toString(start);
        optionNames[idx] = "End";
        optionValues[idx++] = toString(end);
        optionNames[idx] = "Expired";
        optionValues[idx++] = end < block.timestamp ? "Yes" : "No";
        string[] memory _description = new string[](1);
        _description[0] = "This note gives you access to revenues generated by the merchant from start time to end time in the paywall marketplace";
        output = _constructTokenURI(
            _tokenId, 
            _description,
            optionNames, 
            optionValues 
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

    function getDiscount(
        uint _collectionId,
        address _user, 
        string memory _tokenId 
    ) external view returns(uint _discount) {
        address nft_ = IContract(contractAddress).nfticket();
        Ask memory ask = IMarketPlace(IContract(contractAddress).paywallMarketOrders()).getAskDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
        Discount memory discountCost = ask.priceReductor.discountCost;
        Discount memory discountNumbers = ask.priceReductor.discountNumbers;
        (uint256[] memory values1,) = INFTicket(nft_).getUserTicketsPagination(
            _user, 
            _collectionId, 
            discountNumbers.cursor,
            discountNumbers.size,
            ask.priceReductor.checkItemOnly ? _tokenId : ""
        );
        (,uint256 totalPrice2) = INFTicket(nft_).getUserTicketsPagination(
            _user, 
            _collectionId, 
            discountCost.cursor,
            discountCost.size,
            ask.priceReductor.checkItemOnly ? _tokenId : ""
        );
        if (values1.length >= discountNumbers.lowerThreshold && 
            values1.length <= discountNumbers.upperThreshold
        ) {
            _discount += discountNumbers.perct;
            if (totalPrice2 >= discountCost.lowerThreshold && 
                totalPrice2 <= discountCost.upperThreshold
            )
                {
                _discount += discountCost.perct;
            }
        }
    }
}

contract Paywall {
    using SafeERC20 for IERC20;
    
    uint public collectionId;
    mapping(address => uint) private addressToProtocolId;
    struct ProtocolInfo {
        uint ticketId;
        uint startReceivable;
        uint amountReceivable;
        uint periodReceivable;
        uint paidReceivable;
        uint freeTrialPeriod;
        uint userTokenId;
        uint optionId;
        uint profileId;
        uint referrerCollectionId;
        bool autoCharge;
        string item;
    }
    mapping(uint => ProtocolInfo) public protocolInfo;
    uint public lastProtocolId = 1;
    mapping(address => uint) public pendingRevenue;
    uint public bufferTime;
    mapping(uint => uint) public freeTrialPeriod;
    address public devaddr_;
    address private helper;
    bool public profileIdRequired;
    bool public paused;
    address public contractAddress;
    uint public pricePerSecond;
    mapping(uint => Divisor) public  penaltyDivisor;
    mapping(uint => Divisor) public discountDivisor;
    mapping(uint => mapping(string => uint)) public partnershipEnds;

    constructor(address _contractAddress, address _devaddr, uint _collectionId) {
        devaddr_ = _devaddr;
        collectionId = _collectionId;
        contractAddress = _contractAddress;
    }

    modifier onlyAdmin() {
        uint _collectionId = IMarketPlace(_marketCollections()).addressToCollectionId(msg.sender);
        require(collectionId == _collectionId);
        _;
    }

    // simple re-entrancy check 
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function updateDevaddr() external onlyAdmin {
        devaddr_ = msg.sender;
    }

    function isAdmin(address _user) external view returns(bool) {
        return devaddr_ == _user;
    }

    function getProfileId(uint _protocolId) external view returns(uint) {
        return protocolInfo[_protocolId].profileId;
    }

    function getToken(uint _protocolId) external view returns(address) {
        TicketInfo memory _ticketInfo = INFTicket(_nfticket()).getTicketInfo(protocolInfo[_protocolId].ticketId);
        return _ticketInfo.token;
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || helper == msg.sender);
        contractAddress = _contractAddress;
        helper = IContract(_contractAddress).paywallARPHelper();
    }

    function updateSubscriptionInfo(uint _optionId, uint _freeTrialPeriod) external onlyAdmin {
        freeTrialPeriod[_optionId] = _freeTrialPeriod;
        IMarketPlace(IContract(contractAddress).marketPlaceEvents()).emitUpdateSubscriptionInfo(
            collectionId, 
            _optionId, 
            _freeTrialPeriod
        );
    }
    
    function updateDiscountDivisor(uint _optionId, uint _factor, uint _period, uint _cap) external onlyAdmin {
        discountDivisor[_optionId] = Divisor({
            factor: _factor,
            period: _period,
            cap: _cap == 0 ? 10000 : _cap
        });
    }

    function updatePenaltyDivisor(uint _optionId, uint _factor, uint _period, uint _cap) external onlyAdmin {
        penaltyDivisor[_optionId] = Divisor({
            factor: _factor,
            period: _period,
            cap: _cap == 0 ? 10000 : _cap
        });
    }


    function updateProfileId() external {
        address profile = IContract(contractAddress).profile();
        uint _profileId = IProfile(profile).addressToProfileId(msg.sender);
        require(IProfile(profile).isUnique(_profileId), "Profile is not unique");
        protocolInfo[addressToProtocolId[msg.sender]].profileId = _profileId;
    }

    function updateParams(
        uint _bufferTime, 
        uint _pricePerSecond,
        bool _profileIdRequired,
        bool _paused
    ) external onlyAdmin {
        bufferTime = _bufferTime;
        pricePerSecond = _pricePerSecond;
        profileIdRequired = _profileIdRequired;
        paused = _paused;
    }

    function updateAutoCharge(uint _protocolId, bool _autoCharge) external {
        require(ve(_nfticketHelper2()).ownerOf(protocolInfo[_protocolId].ticketId) == msg.sender);
        protocolInfo[_protocolId].autoCharge = _autoCharge;
        IMarketPlace(_marketPlaceEvents()).emitUpdateAutoCharge(collectionId, _protocolId, _autoCharge);
    }

    function _nfticket() internal view returns(address) {
        return IContract(contractAddress).nfticket();
    }
    function _nfticketHelper2() internal view returns(address) {
        return IContract(contractAddress).nfticketHelper2();
    }

    function _marketCollections() internal view returns(address) {
        return IContract(contractAddress).marketCollections();
    }

    function _marketOrders() internal view returns(address) {
        return IContract(contractAddress).paywallMarketOrders();
    }

    function _marketTrades() internal view returns(address) {
        return IContract(contractAddress).paywallMarketTrades();
    }
    
    function _marketHelpers() internal view returns(address) {
        return IContract(contractAddress).paywallMarketHelpers();
    }

    function _marketPlaceEvents() internal view returns(address) {
        return IContract(contractAddress).marketPlaceEvents();
    }

    function _helper() internal view returns(address) {
        return IContract(contractAddress).paywallARPHelper();
    }

    function updateProtocol(
        uint _nfticketId, 
        uint _pickedOption, // optionId + 1 
        address[] memory _users
    ) external {
        require(!paused, "Paused!");
        address nfticket = _nfticket();
        address nfticketHelper2 = _nfticketHelper2();
        require(ve(nfticketHelper2).ownerOf(_nfticketId) == msg.sender);
        address _referrer = IMarketPlace(nfticket).referrer(_nfticketId);
        uint _referrerCollectionId;
        if (_referrer != address(0x0)) {
           _referrerCollectionId = IMarketPlace(_marketCollections()).addressToCollectionId(_referrer);
        }
        TicketInfo memory _ticketInfo = INFTicket(nfticket).getTicketInfo(_nfticketId);
        uint _userTokenId = INFTicket(nfticket).userTokenId(_nfticketId);
        PaywallOption[] memory _options = INFTicket(nfticketHelper2).getTicketPaywallOptions(_nfticketId);
        for (uint i = 0; i < _options.length; i++) {
            if (
                _pickedOption > 0 && _options[i].id == _pickedOption - 1 || _pickedOption == 0
            ) {
                if (_users.length == _options.length) {
                    addressToProtocolId[_users[i]] = lastProtocolId;
                } else {
                    addressToProtocolId[msg.sender] = lastProtocolId;
                }
                uint _startReceivable = block.timestamp + freeTrialPeriod[_options[i].id];
                protocolInfo[lastProtocolId].amountReceivable = _ticketInfo.price + _options[i].unitPrice;
                protocolInfo[lastProtocolId].periodReceivable = _options[i].value;
                protocolInfo[lastProtocolId].startReceivable = _startReceivable;
                protocolInfo[lastProtocolId].userTokenId = _userTokenId;
                protocolInfo[lastProtocolId].optionId = _options[i].id;
                protocolInfo[lastProtocolId].ticketId = _nfticketId;
                protocolInfo[lastProtocolId].item = _ticketInfo.item;
                protocolInfo[lastProtocolId].freeTrialPeriod = freeTrialPeriod[_options[i].id];
                protocolInfo[lastProtocolId].referrerCollectionId = _referrerCollectionId;
                IMarketPlace(_marketPlaceEvents()).emitUpdateProtocol(
                    collectionId, 
                    _nfticketId,
                    _referrerCollectionId, 
                    lastProtocolId++, 
                    _options[i].id,
                    _options[i].unitPrice,
                    _options[i].value,
                    _startReceivable,
                    _ticketInfo.item
                );
            }
        }
    }

    function deleteProtocol (uint protocolId) public onlyAdmin {
        delete protocolInfo[protocolId];
        IMarketPlace(_marketPlaceEvents()).emitDeleteProtocol(collectionId, protocolId);
    }
    
    function owner(uint _protocolId) public view returns(address) {
        return protocolInfo[_protocolId].ticketId == 0
        ? address(0x0)
        : ve(_nfticketHelper2()).ownerOf(protocolInfo[_protocolId].ticketId);
    }

    function autoCharge(uint _protocolId, uint _identityTokenId) external lock {
        bool _isAdmin = collectionId == IMarketPlace(_marketCollections()).addressToCollectionId(msg.sender); 
        address _owner = owner(_protocolId);
        require(
            _isAdmin && protocolInfo[_protocolId].autoCharge || _owner == msg.sender,
            "Either merchant or protocol owner only!"
        );
        Collection memory _referrerCollection = 
        IMarketPlace(_marketCollections()).getCollection(protocolInfo[_protocolId].referrerCollectionId);
        uint[] memory _option = new uint[](1);
        _option[0] = protocolInfo[_protocolId].optionId;
        protocolInfo[_protocolId].paidReceivable += protocolInfo[_protocolId].amountReceivable;
        IMarketPlace(_marketTrades()).buyWithContract(
            devaddr_,
            _owner,
            protocolInfo[_protocolId].referrerCollectionId > 0 
            ? _referrerCollection.owner : address(0x0),
            protocolInfo[_protocolId].item,
            protocolInfo[_protocolId].userTokenId,
            _identityTokenId,
            _option
        );
    }

    function partner(uint _partnerCollectionId, string memory _paywallId, string memory _tokenId, uint _numOfSeconds, bool _secondCall) external {
        address paywallARPHelper = IContract(contractAddress).paywallARPHelper();
        if(devaddr_ != msg.sender && pricePerSecond > 0 &&
            !IMarketPlace(paywallARPHelper).isGauge(msg.sender)
        ) {
            require(IMarketPlace(IContract(contractAddress).marketHelpers2()).partnerShip(collectionId, _partnerCollectionId));
            address marketTrades = _marketTrades();
            address _token = IContract(contractAddress).token();
            Collection memory _collection = IMarketPlace(_marketCollections()).getCollection(collectionId);
            uint _askPrice = _numOfSeconds * pricePerSecond;
            uint _tradingFee = (_askPrice * _collection.tradingFee) / 10000;
            IERC20(_token).safeTransferFrom(
                address(msg.sender), 
                marketTrades, 
                _askPrice
            );
            IMarketPlace(marketTrades).updatePendingRevenue(_token, devaddr_, _askPrice - _tradingFee, false);
            IMarketPlace(marketTrades).updateTreasuryRevenue(_token, _tradingFee);
        }
        uint _endTime = block.timestamp + _numOfSeconds;   
        partnershipEnds[_partnerCollectionId][_tokenId] = _endTime;
        address partnerPaywall = IMarketPlace(paywallARPHelper).collectionIdToPaywallARP(_partnerCollectionId);
        if (!_secondCall) IMarketPlace(partnerPaywall).partner(collectionId, _tokenId, _paywallId, _numOfSeconds, true);
        IMarketPlace(_marketPlaceEvents()).emitUpdateMiscellaneous(
            0,
            collectionId, 
            _paywallId, 
            _tokenId, 
            _partnerCollectionId, 
            _endTime,
            address(0x0),
            ""
        );
    }
    
    function getState(address _user, string memory _tokenId, uint _price) external view returns(uint) {
        uint _protocolId = addressToProtocolId[_user];
        if (owner(_protocolId) == _user && 
            keccak256(abi.encodePacked(protocolInfo[_protocolId].item)) == keccak256(abi.encodePacked(_tokenId))
        ) {
            uint _optionId = protocolInfo[_protocolId].optionId;
            (,,int secondsReceivable) = 
            IMarketPlace(_helper()).getDueReceivable(address(this), addressToProtocolId[_user]);
            if (secondsReceivable > 0) {
                uint _factor = Math.min(penaltyDivisor[_optionId].cap, (uint(secondsReceivable) / Math.max(1,penaltyDivisor[_optionId].period)) * penaltyDivisor[_optionId].factor);
                uint _penalty = _price * _factor / 10000; 
                return _price + _penalty;
            } else {
                uint _factor = Math.min(discountDivisor[_optionId].cap, (uint(-secondsReceivable) / Math.max(1,discountDivisor[_optionId].period)) * discountDivisor[_optionId].factor);
                uint _discount = _price * _factor / 10000; 
                return _price > _discount ? _price - _discount : 0;
            }
        }
        return _price;
    }

    function ongoingSubscription(address _user, uint _nfticketId, string memory _tokenId) external view returns(bool) {
        uint _protocolId = addressToProtocolId[_user];
        if (owner(_protocolId) == _user && 
            keccak256(abi.encodePacked(protocolInfo[_protocolId].item)) == keccak256(abi.encodePacked(_tokenId))
        ) {
            if (profileIdRequired && protocolInfo[_protocolId].profileId == 0) return false;
            (uint dueReceivable,,int secondsReceivable) = 
            IMarketPlace(_helper()).getDueReceivable(address(this), addressToProtocolId[_user]);
            return dueReceivable == 0 || secondsReceivable < 0 || uint(secondsReceivable) < bufferTime;
        } else if (_nfticketId > 0) {
            require(ve(_nfticketHelper2()).ownerOf(_nfticketId) == _user);
    
            TicketInfo memory _ticketInfo = INFTicket(_nfticket()).getTicketInfo(_nfticketId);
            require(partnershipEnds[_ticketInfo.merchant][_tokenId] > block.timestamp);
            address _partnerPaywall = IMarketPlace(IContract(contractAddress).paywallARPHelper()).collectionIdToPaywallARP(_ticketInfo.merchant);
            return IMarketPlace(_partnerPaywall).ongoingSubscription(_user, _nfticketId, _tokenId);
        }
        return false;
    }

    function withdraw(address _token) external onlyAdmin {
        IERC20(_token).safeTransfer(msg.sender, erc20(_token).balanceOf(address(this)));
    }
}

contract PaywallARPHelper {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private gauges;
    mapping(uint => address) public collectionIdToPaywallARP;
    address public contractAddress;
    address private factory;
    
    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender, "NT2");
        contractAddress = _contractAddress;
    }

    function setContractAddressAt(address _paywallARP) external {
        IMarketPlace(_paywallARP).setContractAddress(contractAddress);
    }

    function getAllARPs(uint _start) external view returns(address[] memory arps) {
        arps = new address[](gauges.length() - _start);
        for (uint i = _start; i < gauges.length(); i++) {
            arps[i] = gauges.at(i);
        }    
    }

    function updateGauge(address _last_gauge, uint _collectionId) external {
        require(IContract(contractAddress).paywallARPFactory() == msg.sender);
        gauges.add(_last_gauge);
        collectionIdToPaywallARP[_collectionId] = _last_gauge;
        IMarketPlace(IContract(contractAddress).marketPlaceEvents()).emitCreatePaywallARP(_last_gauge, _collectionId);
    }

    function isGauge(address _gauge) external view returns(bool) {
        return gauges.contains(_gauge);
    }

    function deleteARP(address _arp) external {
        require(msg.sender == IAuth(contractAddress).devaddr_() || IAuth(_arp).devaddr_() == msg.sender);
        gauges.remove(_arp);
        IMarketPlace(IContract(contractAddress).marketPlaceEvents()).emitDeletePaywallARP(IMarketPlace(_arp).collectionId());
    }

    function getNumPeriods(uint tm1, uint tm2, uint _period) public view returns(uint) {
        if (tm2 == 0) tm2 = block.timestamp;
        if (tm1 == 0 || tm2 == 0 || tm2 < tm1) return 0;
        return _period > 0 ? (tm2 - tm1) / _period : 1;
    }
    
    function getDueReceivable(address _arp, uint _protocolId) public view returns(uint, uint, int) {   
        (,uint startReceivable,uint amountReceivable,uint periodReceivable,uint paidReceivable,,,,,,) 
        = IMarketPlace(_arp).protocolInfo(_protocolId);
        // uint numPeriods = paidReceivable / amountReceivable;
        uint numPeriods = getNumPeriods(startReceivable, block.timestamp, periodReceivable);
        uint nextDue = startReceivable + periodReceivable * Math.min(1, numPeriods);
        uint due = amountReceivable * numPeriods > paidReceivable ? amountReceivable * numPeriods - paidReceivable : 0;
        return (
            due, // due
            nextDue, // next
            int(block.timestamp) - int(nextDue) //late or seconds in advance
        );
    }

}

contract PaywallARPFactory {
    address public contractAddress;
    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender, "NT2");
        contractAddress = _contractAddress;
    }

    function createGauge() external {
        uint _collectionId = IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(msg.sender);
        address last_gauge = address(new Paywall(
            contractAddress,
            msg.sender,
            _collectionId
        ));
        IMarketPlace(IContract(contractAddress).paywallARPHelper()).updateGauge(last_gauge, _collectionId);
    }
}
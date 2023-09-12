// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Library.sol";

// Gauges are used to incentivize different actions
contract Valuepool {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using Percentile for *; 

    address public token; // the governance token
    address public _ve; // the governance token
    address public devaddr_;
    address private helper;
    address public contractAddress;
    uint private maxUse = type(uint).max;
    uint private active_period;
    uint private minReceivable;
    uint private maxDueReceivable;
    uint private lenderFactor = 10000; // percent of borrowed money to return
    mapping(bytes32 => uint) private usedSSID; 
    mapping(uint => bytes32) private ssidFromTokenId;
    struct UserInfo {
        uint percentile;
        uint dueReceivable;
    }
    struct SponsorInfo {
        uint cardId;
        uint geoTag;
        uint amount;
        uint numClients;
        uint clientPaid;
        uint clientSODS;
        uint percentile;
    }
    uint private sum_of_diff_squared;
    uint public totalpaidBySponsors;
    string private valueName;
    string private requiredIndentity;
    uint private minIDBadgeColor;
    bool private dataKeeperOnly;
    bool private uniqueAccounts;
    bool public onlyTrustWorthyAuditors;
    mapping(uint => UserInfo) public userInfo;
    mapping(address => SponsorInfo) public sponsors;
    mapping(uint => address) private sponsorIds;
    EnumerableSet.AddressSet private sponsorAddresses;
    EnumerableSet.AddressSet private latestPayingSponsors;
    mapping(uint => bool) private usedTickets;
    uint public epoch;
    uint private queueDuration = 86400 * 7; // 1 week
    mapping(address => mapping(address => uint)) public lenderBalance;
    uint public maxWithdrawable = 100;
    uint private minimumSponsorPercentile;
    mapping(uint => mapping(string => bool)) private alreadyCalled;
    uint public treasuryShare = 200;
    uint private maxTreasuryShare = 10000;
    bool private bnpl;
    string public  merchantValueName;
    bool public onlyTrustWorthyMerchants;
    uint public merchantMinIDBadgeColor;
    bool public merchantDataKeeperOnly;
    string public merchantRequiredIndentity;
    struct ScheduledPurchase {
        address collection;
        address referrer;
        address owner;
        string productId;
        uint[] options;
        uint userTokenId;
        uint identityTokenId;
        uint price;
        uint rank;
    }
    mapping(uint => mapping(uint => ScheduledPurchase)) public scheduledPurchases;
    mapping(uint => mapping(uint => EnumerableSet.UintSet)) private queue;

    constructor(
        address _token, 
        address _devaddr,
        address _helper,
        address _contractAddress
    ) {   
        token = _token;
        helper = _helper;
        devaddr_ = _devaddr;
        contractAddress = _contractAddress;
    }

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier nonreentrant() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    modifier onlyAdmin() {
        require(devaddr_ == msg.sender);
        _;
    }

    function getParams() external view returns(uint,uint,uint,uint,uint,uint,uint,uint,bool,bool,string memory,string memory) {
        return (
            maxUse,
            queueDuration,
            minReceivable, 
            maxDueReceivable,
            maxTreasuryShare,
            lenderFactor,
            minimumSponsorPercentile,
            minIDBadgeColor,
            dataKeeperOnly,
            uniqueAccounts,
            requiredIndentity,
            valueName
        );
    }

    function updateDev(address _devaddr) external {
        uint _collectionId = IValuePool(IContract(contractAddress).valuepoolVoter()).collectionId(_ve);
        require(_collectionId > 0 && _collectionId == IMarketPlace(IContract(contractAddress).marketCollections())
        .addressToCollectionId(msg.sender));
        devaddr_ = _devaddr;
    }
    
    function onERC721Received(address,address,uint256,bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector; 
    }

    function updateVa() external {
        require(_ve == address(0));
        _ve = msg.sender;
        IValuePool(helper).emitInitialize(msg.sender);
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IContract(_contractAddress).valuepoolHelper2() == msg.sender);
        contractAddress = _contractAddress;
        helper = IContract(_contractAddress).valuepoolHelper();
    }

    function _marketCollections() internal view returns(address) {
        return IContract(contractAddress).marketCollections();
    }

    function notifyLoan(address _token, address _arp, uint _amount) external nonreentrant {
        uint _limit = IValuePool(IContract(contractAddress).valuepoolVoter()).getBalance(_ve, _arp);
        require(_limit >= lenderBalance[_token][_arp] + _amount);
        lenderBalance[_token][_arp] += _amount * lenderFactor / 10000;
        if (IERC721(_token).supportsInterface(0x80ac58cd) || IERC721(_token).supportsInterface(0xd9b67a26)) {
            IERC721(_token).setApprovalForAll(_arp, true);
        } else {
            erc20(_token).approve(_arp, _amount);
        }    
        IARP(_arp).notifyReward(_token, _amount);
        IValuePool(helper).emitNotifyLoan(_arp, _token, _amount * lenderFactor / 10000);
    }

    function notifyReimbursement(address _token, address _arp, uint _amount) external nonreentrant {
        _amount = _amount == 0 ? lenderBalance[_token][_arp] : Math.min(lenderBalance[_token][_arp],_amount);
        assert(IERC20(_token).transferFrom(msg.sender, address(this), _amount));
        bool _active = lenderBalance[_token][_arp] > _amount;
        lenderBalance[_token][_arp] -= _amount;
        IValuePool(helper).emitNotifyReimbursement(_arp, _token, _amount, _active);
    }

    function reimburseBNPL(uint _tokenId, uint _amount) external {
        _amount = _amount == 0 ? userInfo[_tokenId].dueReceivable : Math.min(
            userInfo[_tokenId].dueReceivable,_amount);
        assert(IERC20(token).transferFrom(msg.sender, address(this), _amount));
        bool _active = userInfo[_tokenId].dueReceivable > _amount;
        userInfo[_tokenId].dueReceivable -= _amount;
        IValuePool(helper).emitNotifyReimbursement(msg.sender, token, _amount, _active);
    }

    function addSponsor(address _card, uint _cardId, uint _geoTag) external {
        CardInfo memory _cardInfo = ISponsorCard(_card).protocolInfoCard(_cardId);
        uint _sponsorId = IMarketPlace(_marketCollections()).addressToCollectionId(msg.sender);
        require(_cardInfo.owner == address(this) && _cardInfo.amountPayable > minReceivable, "Va5");
        require(msg.sender == ISponsorCard(_card).devaddr_() && _sponsorId > 0);
        sponsors[_card].cardId = _cardId;
        sponsors[_card].geoTag = _geoTag;
        sponsorAddresses.add(_card);
        sponsorIds[_sponsorId] = _card;
        IValuePool(helper).emitAddSponsor(_card, _cardId, _geoTag, _sponsorId);
    }

    function removeSponsorAt(address _card) external onlyAdmin {
        address owner = ISponsorCard(_card).devaddr_();
        uint _sponsorId = IMarketPlace(_marketCollections()).addressToCollectionId(owner);
        delete sponsors[_card];
        sponsorAddresses.remove(_card);
        delete sponsorIds[_sponsorId];
        if (latestPayingSponsors.contains(_card)) latestPayingSponsors.remove(_card);
        IValuePool(helper).emitRemoveSponsor(_card);
    }

    function notifyPayment(address _card) external nonreentrant {
        uint _amount = ISponsorCard(_card).payInvoicePayable(address(this));
        if (_amount > 0) {
            (uint percentile, uint sods) = Percentile.computePercentileFromData(
                false,
                sponsors[_card].amount + _amount,
                totalpaidBySponsors + _amount,
                sponsorAddresses.length(),
                sum_of_diff_squared
            );
            sponsors[_card].amount += _amount;
            sum_of_diff_squared = sods;
            uint _percentile = _computePercentile(sponsors[_card].percentile, percentile);
            sponsors[_card].percentile = _percentile;
            if (sponsors[_card].percentile >= minimumSponsorPercentile) {
                if (latestPayingSponsors.length() >= IContract(contractAddress).maximumSize()) {
                    latestPayingSponsors.remove(latestPayingSponsors.at(0));
                }
                latestPayingSponsors.add(_card);
            }
            IValuePool(helper).emitNotifyPayment(_card, _amount, _percentile);
        }
    }

    function isPayingSponsor(address _card) external view returns(bool) {
        return latestPayingSponsors.contains(_card);
    }

    function _computePercentile(uint _old, uint _new) internal pure returns(uint) {
        return _old > 0 ? (_old + _new) / 2 : _new;
    }

    function addCredit(uint _tokenId) external {
        address nfticket = IContract(contractAddress).nfticket();
        TicketInfo memory _ticketInfo = INFTicket(nfticket).ticketInfo_(_tokenId);
        require(ve(nfticket).ownerOf(_tokenId) == msg.sender, "Va7");
        address _sponsor = sponsorIds[_ticketInfo.merchant];
        require(sponsorAddresses.contains(_sponsor) && !usedTickets[_tokenId], "Va8");
        usedTickets[_tokenId] = true;
        (uint percentile, uint sods) = Percentile.computePercentileFromData(
            false,
            _ticketInfo.price,
            sponsors[_sponsor].clientPaid + _ticketInfo.price,
            sponsors[_sponsor].numClients + 1,
            sponsors[_sponsor].clientSODS
        );
        sponsors[_sponsor].clientPaid += _ticketInfo.price;
        sponsors[_sponsor].numClients += 1;
        sponsors[_sponsor].clientSODS = sods;
        uint _percentile = _computePercentile(
            userInfo[_tokenId].percentile, 
            percentile * sponsors[_sponsor].percentile / 10000 // percent of sponsor's percentile
        );
        userInfo[_tokenId].percentile = _percentile;
        IValuePool(helper).emitAddCredit(msg.sender, _tokenId, _percentile);
    }
    
    function getAllSponsors(uint _start, uint _geoTag, bool _onlyPaying) external view returns(address[] memory _sponsors) {
        _sponsors = new address[](sponsorAddresses.length() - _start);
         if (_onlyPaying) {
            for (uint i = _start; i < latestPayingSponsors.length(); i++) {
                if (sponsors[sponsorAddresses.at(i)].geoTag == _geoTag) {
                    _sponsors[i] = sponsorAddresses.at(i);
                }
            }    
         } else {
            for (uint i = _start; i < sponsorAddresses.length(); i++) {
                if (sponsors[sponsorAddresses.at(i)].geoTag == _geoTag) {
                    _sponsors[i] = sponsorAddresses.at(i);
                }  
            }  
         }
    }

    function updateParameters(
        bool _bnpl,
        uint _maxUse,
        uint _queueDuration, 
        uint _minReceivable,
        uint _maxDueReceivable, 
        uint _treasuryShare,
        uint _maxTreasuryShare,
        uint _maxWithdrawable,
        uint _lenderFactor,
        uint _minimumSponsorPercentile
    ) external onlyAdmin {
        bnpl = _bnpl;
        maxUse = _maxUse == 0 ? type(uint).max : _maxUse;
        queueDuration = _queueDuration;
        if (maxTreasuryShare >= _treasuryShare) {
            treasuryShare = _treasuryShare;
        }
        if (_maxTreasuryShare > 0 && maxTreasuryShare > _maxTreasuryShare) {
            maxTreasuryShare = _maxTreasuryShare;
        }
        maxWithdrawable = _maxWithdrawable;
        minReceivable = _minReceivable;
        maxDueReceivable = _maxDueReceivable;
        lenderFactor = _lenderFactor;
        minimumSponsorPercentile = _minimumSponsorPercentile;
        if (active_period == 0) {
            active_period = (block.timestamp + queueDuration) / queueDuration * queueDuration;
        }
        IValuePool(helper).emitUpdateParameters(
            _bnpl,
            _queueDuration,
            _minReceivable,
            _maxDueReceivable,
            _treasuryShare,
            _maxWithdrawable,
            _lenderFactor,
            _minimumSponsorPercentile
        );
    }
   
    function updateMerchantIDProofParams(
        uint _merchantMinIDBadgeColor,
        string memory _merchantValueName, //agebt, age, agelt... 
        string memory _value, //18
        bool _merchantDataKeeperOnly,
        bool _onlyTrustWorthyMerchants
    ) external onlyAdmin {
        merchantValueName = _merchantValueName; 
        merchantDataKeeperOnly = _merchantDataKeeperOnly;  
        merchantMinIDBadgeColor = _merchantMinIDBadgeColor;
        merchantRequiredIndentity = _value;
        onlyTrustWorthyMerchants = _onlyTrustWorthyMerchants;
    }

    function updateUserIDProofParams(
        uint _minIDBadgeColor,
        string memory _valueName, //agebt, age, agelt... 
        string memory _requiredIndentity, //18
        bool _uniqueAccounts,
        bool _dataKeeperOnly,
        bool _onlyTrustWorthyAuditors
    ) external onlyAdmin {
        uniqueAccounts = _uniqueAccounts;
        valueName = _valueName;   
        dataKeeperOnly = _dataKeeperOnly;
        minIDBadgeColor = _minIDBadgeColor;
        requiredIndentity = _requiredIndentity;
        onlyTrustWorthyAuditors = _onlyTrustWorthyAuditors;
    }

    function _reinitializeQueue() internal {
        if (active_period <= block.timestamp) {
            epoch += 1; // reinitializes queue
            active_period = (block.timestamp + queueDuration) / queueDuration * queueDuration;
        }
    }
    
    function _checkIdentityProof(uint _tokenId, uint _identityTokenId, bool checkUnique) internal {
        if (keccak256(abi.encodePacked(valueName)) != keccak256(abi.encodePacked(""))) {
            address _owner = va(_ve).ownerOf(_tokenId);
            address ssi = IContract(contractAddress).ssi();
            require(ve(ssi).ownerOf(_identityTokenId) == _owner);
            SSIData memory metadata = ISSI(ssi).getSSIData(_identityTokenId);
            require(metadata.deadline > block.timestamp);
            (string memory _ssid, address _gauge, address _gauge2) = _checkProfiles(metadata);
            require(keccak256(abi.encodePacked(metadata.question)) == keccak256(abi.encodePacked(valueName)));
            require(keccak256(abi.encodePacked(metadata.answer)) == keccak256(abi.encodePacked(requiredIndentity))); 
            IValuePool(IContract(contractAddress).valuepoolHelper2()).checkContains(onlyTrustWorthyAuditors, _gauge, _gauge2, _owner);
            if (uniqueAccounts && checkUnique) {
                require(keccak256(abi.encodePacked(_ssid)) != keccak256(abi.encodePacked("")));
                require(!alreadyCalled[epoch][_ssid], "Va10");
                alreadyCalled[epoch][_ssid] = true;
                ssidFromTokenId[_tokenId] = keccak256(abi.encodePacked(_ssid));
                require(usedSSID[keccak256(abi.encodePacked(_ssid))] < maxUse, "Va010");
            }
        }
    }

    function _checkProfiles(SSIData memory metadata) internal view returns(string memory,address,address) {
        address _auditorNote = IContract(contractAddress).auditorNote();
        SSIData memory metadata2 = ISSI(IContract(contractAddress).ssi()).getSSID(metadata.senderProfileId);
        (address gauge, bool dk, COLOR _badgeColor) = IAuditor(_auditorNote).getGaugeNColor(metadata.auditorProfileId);
        (address gauge2, bool dk2, COLOR _badgeColor2) = IAuditor(_auditorNote).getGaugeNColor(metadata2.auditorProfileId);
        require(uint(_badgeColor) >= minIDBadgeColor && uint(_badgeColor2) >= minIDBadgeColor, "VaHH06");
        if (dataKeeperOnly) require(dk && dk2);
        return (metadata2.answer, gauge, gauge2);
    }

    function pickRank(uint _tokenId, uint _identityTokenId) external nonreentrant {
        _reinitializeQueue();
        _checkIdentityProof(_tokenId, _identityTokenId, true);
        
        require(va(_ve).isApprovedOrOwner(msg.sender, _tokenId), "Va11");
        require(scheduledPurchases[epoch][_tokenId].owner == address(0x0), "Va12");
        if (bnpl) {
            require(userInfo[_tokenId].dueReceivable <= maxDueReceivable, "Va13");
        }
        IValuePool(IValuePool(helper).randomGenerators(address(this))).getRandomNumber(_tokenId);
    }
    
    function getQueue(uint _rank) external view returns(uint[] memory q) {
        q = new uint[](queue[epoch][_rank].length());
        for(uint i = 0; i < queue[epoch][_rank].length(); i++) {
            q[i] = queue[epoch][_rank].at(i);
        }
    }

    function schedulePurchase(
        address _collection, 
        address _owner, 
        address _referrer,
        string memory _productId, 
        uint[] memory _options, 
        uint _userTokenId,
        uint _identityTokenId,
        uint _tokenId,
        uint _price,
        uint _rank
    ) external {
        require(msg.sender == helper, "Va14");
        queue[epoch][_rank].add(_tokenId);
        scheduledPurchases[epoch][_tokenId] = ScheduledPurchase({
            collection: _collection,
            referrer: _referrer,
            productId: _productId,
            userTokenId: _userTokenId,
            identityTokenId: _identityTokenId,
            options: _options,
            owner: _owner,
            price: _price,
            rank: _rank
        });
    }
    
    function _getNextPurchase() internal view returns(uint) {
        for (uint i = 1; i < 101; i++) {
            if (queue[epoch][i].length() > 0) {
                return queue[epoch][i].at(0);
            }
        }
    }

    function executeNextPurchase() external {
        ScheduledPurchase memory purchase = scheduledPurchases[epoch][_getNextPurchase()];
        uint _tokenId = queue[epoch][purchase.rank].at(0);
        uint _available = IValuePool(helper).getSupplyAvailable(address(this));
        require(_available > purchase.price, "Va15");
        address marketPlace = IValuePool(helper).getMarketPlace();
        erc20(token).approve(marketPlace, purchase.price);
        IMarketPlace(marketPlace).buyWithContract(
            purchase.collection, 
            purchase.owner,
            purchase.referrer,
            purchase.productId, 
            purchase.userTokenId, 
            purchase.identityTokenId, 
            purchase.options
        );
        userInfo[_tokenId].dueReceivable += purchase.price;
        usedSSID[ssidFromTokenId[_tokenId]] += 1;
        queue[epoch][purchase.rank].remove(_tokenId);
        IValuePool(helper).emitExecuteNextPurchase(msg.sender, purchase.rank, _tokenId, purchase.price);
    }

    function notifyWithdraw(address _token, address to, uint amount) external {
        require(msg.sender == helper);
        assert(IERC20(_token).transfer(to, amount));
    }
}

contract ValuepoolHelper {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint public tradingFee;
    address contractAddress;
    mapping(address => mapping(uint => bool)) private _cardIdVerification;
    mapping(address => address) private marketPlaces;
    mapping(address => bool) private isMarketPlace;
    mapping(address => bool) public onePersonOneVote;
    mapping(address => address) public randomGenerators;
    mapping(address => string) private description;
    mapping(uint => address) private taxContracts;
    EnumerableSet.AddressSet private valuepools;

    event CheckRank(
        address vava, 
        address collection, 
        address from, 
        address referrer,
        string productId, 
        uint[] options, 
        uint userTokenId, 
        uint identityTokenId, 
        uint tokenId, 
        uint price,
        uint rank,
        uint epoch
    );
    event WithdrawFromVava(address indexed from, address vava, uint amount);
    event CreateVava(address vava, address tokenAddress, address devaddr_, bool riskpool, bool onePersonOneVote);
    event NotifyLoan(address vava, address borrower, address token, uint amount);
    event Initialize(address vava, address ve);
    event NotifyReimbursement(address vava, address borrower, address token, uint amount, bool active);
    event AddCredit(address va, address user, uint tokenId, uint percentile);
    event NotifyPayment(address vava, address card, uint amount, uint percentile);
    event AddSponsor(address vava, address card, uint cardId, uint geoTag, uint sponsorId);
    event RemoveSponsor(address vava, address card);
    event UpdateParameters(
        address vava,
        bool bnpl,
        uint queueDuration,
        uint minReceivable,
        uint maxDueReceivable,
        uint treasuryShare,
        uint maxWithdrawable,
        uint lenderFactor,
        uint minimumSponsorPercentile
    );
    event ExecuteNextPurchase(address vava, address user, uint rank, uint tokenId, uint amount);
    event Deposit(address va, address vava, address owner, uint tokenId, uint value, uint balanceOf, uint lockTime, DepositType deposit_type, uint percentile);
    event Withdraw(address va, address owner, uint tokenId, uint value, uint balanceOf, uint percentile);
    event UpdateMinimumBalance(address va, address owner, uint tokenId, uint amount);
    event DeleteMinimumBalance(address va, address owner, uint tokenId, uint amount);
    event Supply(address vava, uint prevSupply, uint supply);
    event Transfer(address va, address from, address to, uint tokenId);
    event Approval(address va, address owner, address approved, uint tokenId);
    event ApprovalForAll(address va, address owner, address operator, bool approved);
    event SetParams(address vava, string name, string symbol, uint8 decimals, uint maxSupply, uint minTicketPrice, uint minToSwitch);
    event Switch(address vava);
    event Delete(address vava);
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

    function getAllVavas(uint _start) external view returns(address[] memory vavas) {
        vavas = new address[](valuepools.length() - _start);
        for (uint i = _start; i < valuepools.length(); i++) {
            vavas[i] = valuepools.at(i);
        }    
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

    function deleteVava(address _vava) external {
        require(msg.sender == IAuth(contractAddress).devaddr_() || IAuth(_vava).devaddr_() == msg.sender, "VaH1");
        valuepools.remove(_vava);
        emit Delete(_vava);
    }

    function isGauge(address _vava) external view returns(bool) {
        return valuepools.contains(_vava);
    }

    function updateVava(
        address _last_vava,
        address _marketPlace, 
        address _token,
        address _devaddr,
        bool riskpool,
        bool _onePersonOneVote
    ) external {
        require(msg.sender == IContract(contractAddress).valuepoolFactory(), "VaH2");
        valuepools.add(_last_vava);
        onePersonOneVote[_last_vava] = _onePersonOneVote;
        marketPlaces[_last_vava] = _marketPlace;
        randomGenerators[_last_vava] = address(new RandomNumberGenerator(
            IContract(contractAddress).vrfCoordinator(), 
            IContract(contractAddress).linkToken(),
            _last_vava
        ));
        emit CreateVava(
            _last_vava,
            _token,
            _devaddr,
            riskpool, 
            _onePersonOneVote
        );
    }
    
    function updateValuepool(address vava, string memory _description) external {
        require(IAuth(vava).devaddr_() == msg.sender);
        description[vava] = _description;
    }

    function getDescription(address _vava) external view returns(string[] memory desc) {
        desc = new string[](1);
        desc[0] = description[_vava];
    }

    function emitApproval(address owner, address _approved, uint _tokenId) external {
        emit Approval(msg.sender, owner, _approved, _tokenId);
    }

    function emitApprovalForAll(address owner, address operator, bool approved) external {
        emit ApprovalForAll(msg.sender, owner, operator, approved);
    }

    function emitWithdraw(address provider, uint tokenId, uint value, uint balanceOf, uint percentile) external {
        uint _profileId = IProfile(IContract(contractAddress).profile()).addressToProfileId(provider);
        if (taxContracts[_profileId] != address(0x0) && _profileId != 0) {
            IBILL(taxContracts[_profileId]).notifyCredit(msg.sender, provider, value);
        }
        emit Withdraw(msg.sender, provider, tokenId, value, balanceOf, percentile);
    }

    function emitSwitch(address _vava) external {
        require(IValuePool(_vava)._ve() == msg.sender, "VaH4");
        emit Switch(_vava);
    }

    function emitSetParams(
        address _vava,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint _maxSupply,
        uint _minTicketPrice,
        uint _minToSwitch
    ) external {
        require(IValuePool(_vava)._ve() == msg.sender, "VaH5");
        emit SetParams(_vava, _name, _symbol, _decimals, _maxSupply, _minTicketPrice, _minToSwitch);
    }

    function emitUpdateMinimumBalance(address owner, uint tokenId, uint amount) external {
        emit UpdateMinimumBalance(msg.sender, owner, tokenId, amount);
    }

    function emitDeleteMinimumBalance(address owner, uint tokenId, uint amount) external {
        emit DeleteMinimumBalance(msg.sender, owner, tokenId, amount);
    }

    function emitSupply(address _valuepool, uint prevSupply, uint supply) external {
        require(IValuePool(_valuepool)._ve() == msg.sender, "VaH6");
        emit Supply(_valuepool, prevSupply, supply);
    }

    function emitTransfer(address from, address to, uint tokenId) external {
        emit Transfer(msg.sender, from, to, tokenId);
    }

    function updateTaxContract(address _taxContract) external {
        uint _profileId = IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender);
        if (_profileId > 0) {
            taxContracts[_profileId] = _taxContract;
        }
    }

    function emitDeposit(address vava, address owner, uint tokenId, uint value, uint locktime, DepositType deposit_type, uint percentile) external {
        uint _profileId = IProfile(IContract(contractAddress).profile()).addressToProfileId(owner);
        if (taxContracts[_profileId] != address(0x0) && _profileId != 0) {
            IBILL(taxContracts[_profileId]).notifyDebit(msg.sender, owner, value);
        }
        emit Deposit(
            msg.sender, 
            vava, 
            owner, 
            tokenId, 
            value, 
            ve(msg.sender).balanceOfNFT(tokenId), 
            locktime, 
            deposit_type, 
            percentile
        );
    }

    function emitNotifyLoan(address _to, address _token, uint __amount) external {
        emit NotifyLoan(msg.sender, _to, _token, __amount);
    }

    function emitInitialize(address _ve) external {
        emit Initialize(msg.sender, _ve);
    }

    function emitNotifyReimbursement(address _from, address _token, uint __amount, bool _active) external {
        emit NotifyReimbursement(msg.sender, _from, _token, __amount, _active);
    }

    function emitAddCredit(address _user, uint _tokenId, uint _percentile) external {
        emit AddCredit(IValuePool(msg.sender)._ve(), _user, _tokenId, _percentile);
    }

    function emitNotifyPayment(address _card, uint _amount, uint _percentile) external {
        emit NotifyPayment(msg.sender, _card, _amount, _percentile);
    }

    function emitAddSponsor(address _card, uint _cardId, uint _geoTag, uint _sponsorId) external {
        _cardIdVerification[IValuePool(msg.sender)._ve()][_cardId] = true;
        emit AddSponsor(msg.sender, _card, _cardId, _geoTag, _sponsorId);
    }

    function verifyCardId(uint _cardId) external view returns(bool) {
        return _cardIdVerification[address(this)][_cardId];
    }

    function emitRemoveSponsor(address _card) external {
        emit RemoveSponsor(msg.sender, _card);
    }

    function emitExecuteNextPurchase(address _user, uint _rank, uint _tokenId, uint _amount) external {
        emit ExecuteNextPurchase(msg.sender, _user, _rank, _tokenId, _amount);
    }

    function emitUpdateParameters(
        bool _bnpl,
        uint _queueDuration,
        uint _minReceivable,
        uint _maxDueReceivable,
        uint _treasuryShare,
        uint _maxWithdrawable,
        uint _lenderFactor,
        uint _minimumSponsorPercentile
    ) external {
        emit UpdateParameters(
            msg.sender, 
            _bnpl,
            _queueDuration,
            _minReceivable,
            _maxDueReceivable,
            _treasuryShare,
            _maxWithdrawable,
            _lenderFactor,
            _minimumSponsorPercentile
        );
    }

    function withdrawTreasury(address _vava, address _token, uint amount) external {
        require(msg.sender == IAuth(_vava).devaddr_(), "VaH7");
        if (address(_token) == address(IContract(_vava).token())) {
            uint _totalSupply = erc20(_token).balanceOf(_vava);
            amount = _totalSupply * IValuePool(_vava).treasuryShare() / 10000;
        }
        uint _fees = amount * tradingFee / 10000;
        uint collectionId = IMarketPlace(IContract(contractAddress).marketCollections())
        .addressToCollectionId(msg.sender);
        address businessGauge = IMarketPlace(IContract(contractAddress).businessGaugeFactory())
        .hasGauge(collectionId);
        IVava(_vava).notifyWithdraw(_token, businessGauge, amount - _fees);
        IVava(_vava).notifyWithdraw(_token, address(this), _fees);
        emit WithdrawFromVava(msg.sender, _vava, amount);
    }

    function updateTradingFee(uint _tradingFee) external {
        require(msg.sender == IAuth(contractAddress).devaddr_());
        tradingFee = _tradingFee;
    }

    function getSupplyAvailable(address _vava) external view returns(uint) {
        uint _totalSupply = erc20(IVava(_vava).token()).balanceOf(_vava);
        uint _treasury = _totalSupply * IVava(_vava).treasuryShare() / 10000;
        return (_totalSupply - _treasury) * IVava(_vava).maxWithdrawable() / 10000;
    }

    function updateMarketPlace(address _marketPlace, bool _add) external {
        require(msg.sender == IAuth(contractAddress).devaddr_());
        isMarketPlace[_marketPlace] = _add;
    }

    function updateMarketPlace(address _vava, address _marketPlace) external {
        require(IAuth(_vava).devaddr_() == msg.sender);
        require(isMarketPlace[_marketPlace], "VaH11");
        marketPlaces[_vava] = _marketPlace;
    }

    function getMarketPlace() external view returns(address) {
        return marketPlaces[msg.sender];
    }

    function _getUserPercentile(address _vava, uint _tokenId) internal view returns(uint) {
        uint vePercentile = va(IValuePool(_vava)._ve()).percentiles(_tokenId);
        (uint _percentile,) = IValuePool(_vava).userInfo(_tokenId);
        return (vePercentile + _percentile) / 2;
    }

    function _getRank(
        address _vava, 
        address _collection, 
        address _owner, 
        address _referrer,
        string memory _productId, 
        uint[] memory _options, 
        uint[5] memory _tokenIds
    ) internal returns(uint _rank) {
        IValuePool(IContract(contractAddress).valuepoolHelper2()).checkIdentityProof(_collection, _vava, _tokenIds[2]);
        // Calculate the finalNumber based on the randomResult generated by ChainLink's fallback
        uint32 roundNumber = IValuePool(randomGenerators[_vava]).viewRandomResult(_tokenIds[3]);
        uint _userPercentile = _getUserPercentile(_vava, _tokenIds[3]);
        if (_userPercentile > roundNumber % 100) {
            _rank = _userPercentile - roundNumber % 100;
        } else {
            _rank = Math.max(roundNumber % 100 - _userPercentile, 1);
        }
        
        IVava(_vava).schedulePurchase(
            _collection, 
            _owner, 
            _referrer, 
            _productId, 
            _options, 
            _tokenIds[0], 
            _tokenIds[1], 
            _tokenIds[3], 
            _tokenIds[4],
            _rank
        );
    }

    function checkRank(
        address _vava, 
        address _collection, 
        address _referrer,
        string memory _productId, 
        uint[] memory _options,
        uint[5] memory _tokenIds // [_userTokenId, _identityTokenId, _merchantIdentityTokenId, _tokenId, _price]
    ) external {
        uint _epoch = IValuePool(_vava).epoch();
        require(_epoch == IValuePool(randomGenerators[_vava]).fulfilled(_tokenIds[3]), "VaH12");
        uint _rank = _getRank(
            _vava, 
            _collection, 
            msg.sender, 
            _referrer, 
            _productId, 
            _options, 
            _tokenIds
        );
        
        emit CheckRank(
            _vava, 
            _collection, 
            msg.sender, 
            _referrer, 
            _productId, 
            _options, 
            _tokenIds[0], 
            _tokenIds[1], 
            _tokenIds[3], 
            _tokenIds[4],
            _rank,
            _epoch
        );
    }
}

contract ValuepoolHelper2 {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    address public contractAddress;
    uint private maxNumMedia = 2;
    mapping(address => bool) public autoUpdateTag;
    mapping(address => mapping(uint => uint)) public geoTag;
    mapping(address => EnumerableSet.AddressSet) private merchantTrustWorthyAuditors;
    mapping(address => EnumerableSet.AddressSet) private vavaTrustWorthyMerchants;
    mapping(address => mapping(address => bool)) public blackListedMerchant;
    mapping(address => mapping(address => string)) public media;
    mapping(address => EnumerableSet.UintSet) private excludedContents;

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }

    function setContractAddressAt(address _valuepool) external {
        IMarketPlace(_valuepool).setContractAddress(contractAddress);
    }
    
    function updateMerchantTrustWorthyAuditors(address _valuepool, address _auditor, bool _add) external {
        require(IAuth(_valuepool).devaddr_() == msg.sender, "VaHH1");
        if (_add) {
            merchantTrustWorthyAuditors[_valuepool].add(_auditor);
        } else {
            merchantTrustWorthyAuditors[_valuepool].remove(_auditor);
        }
    }

    function updateVavaTrustWorthyMerchants(address _valuepool, address _merchant, bool _add) external {
        require(IAuth(_valuepool).devaddr_() == msg.sender, "VaHH2");
        if (_add) {
            vavaTrustWorthyMerchants[_valuepool].add(_merchant);
        } else {
            vavaTrustWorthyMerchants[_valuepool].remove(_merchant);
        }
    }

    function getAllMerchantTrustWorthyAuditors(address _valuepool, uint _start) external view returns(address[] memory _auditors) {
        _auditors = new address[](merchantTrustWorthyAuditors[_valuepool].length() - _start);
        for (uint i = _start; i < merchantTrustWorthyAuditors[_valuepool].length(); i++) {
            _auditors[i] = merchantTrustWorthyAuditors[_valuepool].at(i);
        }
    }

    function getAllVavaTrustWorthyMerchants(address _valuepool, uint _start) external view returns(address[] memory _merchants) {
        _merchants = new address[](vavaTrustWorthyMerchants[_valuepool].length() - _start);
        for (uint i = _start; i < vavaTrustWorthyMerchants[_valuepool].length(); i++) {
            _merchants[i] = vavaTrustWorthyMerchants[_valuepool].at(i);
        }
    }

    function _ssi() internal view returns(address) {
        return IContract(contractAddress).ssi();
    }

    function _auditorNote() internal view returns(address) {
        return IContract(contractAddress).auditorNote();
    }

    function checkIdentityProof(
        address _owner, 
        address _vava, 
        uint _identityTokenId
    ) external view {
        string memory _valueName = IValuePool(_vava).merchantValueName();
        bool _dataKeeperOnly = IValuePool(_vava).merchantDataKeeperOnly();
        COLOR _minIDBadgeColor = COLOR(IValuePool(_vava).merchantMinIDBadgeColor());
        if (IValuePool(_vava).onlyTrustWorthyMerchants()) {
            require(vavaTrustWorthyMerchants[_vava].contains(_owner), "VaHH3");
        } else if (!vavaTrustWorthyMerchants[_vava].contains(_owner)) {
            if (keccak256(abi.encodePacked(_valueName)) != keccak256(abi.encodePacked(""))) {
                require(ve(_ssi()).ownerOf(_identityTokenId) == _owner, "VaHH4");
                SSIData memory metadata = ISSI(_ssi()).getSSIData(_identityTokenId);
                require(metadata.deadline > block.timestamp, "VaHH5");
                (address gauge,address gauge2) = _checkProfiles(metadata, _dataKeeperOnly, _minIDBadgeColor);
                require(keccak256(abi.encodePacked(metadata.question)) == keccak256(abi.encodePacked(
                    IValuePool(_vava).merchantRequiredIndentity()
                )), "VaHH7"); 
                require(keccak256(abi.encodePacked(metadata.answer)) == keccak256(abi.encodePacked(_valueName)), "VaHH8");
                _checkContains(_vava, gauge, gauge2, _owner);
            }
        }
    }

    function _checkProfiles(SSIData memory metadata, bool _dataKeeperOnly, COLOR _minIDBadgeColor) internal view returns(address,address) {
        SSIData memory metadata2 = ISSI(_ssi()).getSSID(metadata.senderProfileId);
        (address gauge, bool dk, COLOR _badgeColor) = IAuditor(_auditorNote()).getGaugeNColor(metadata.auditorProfileId);
        (address gauge2, bool dk2, COLOR _badgeColor2) = IAuditor(_auditorNote()).getGaugeNColor(metadata2.auditorProfileId);
        require(_badgeColor >= _minIDBadgeColor && _badgeColor2 >= _minIDBadgeColor, "VaHH6");
        if (_dataKeeperOnly) require(dk && dk2);
        return (gauge, gauge2);
    }

    function checkContains(bool _onlyTrustWorthyAuditors, address _gauge, address _gauge2, address _owner) external view {
        require(!_onlyTrustWorthyAuditors || (
            merchantTrustWorthyAuditors[msg.sender].contains(_gauge) && 
            merchantTrustWorthyAuditors[msg.sender].contains(_gauge2)), 
            "VaHH09"
        );
        require(!blackListedMerchant[address(this)][_owner] && !blackListedMerchant[msg.sender][_owner], "VaHH010");
    }

    function _checkContains(address _vava, address _gauge, address _gauge2, address _owner) internal view {
        require(!IValuePool(_vava).onlyTrustWorthyAuditors() || (
            merchantTrustWorthyAuditors[_vava].contains(_gauge) && 
            merchantTrustWorthyAuditors[_vava].contains(_gauge2)), 
            "VaHH9"
        );
        require(!blackListedMerchant[address(this)][_owner] && !blackListedMerchant[_vava][_owner], "VaHH10");
    }
    
    function updateBlacklistMerchant(address _valuepool, address _merchant, bool _blacklist) external {
        if (msg.sender == IAuth(contractAddress).devaddr_()) {
            blackListedMerchant[address(this)][_merchant] = _blacklist;
        } else {
            require(IAuth(_valuepool).devaddr_() == msg.sender, "VaHH11");
            blackListedMerchant[_valuepool][_merchant] = _blacklist;
        }
    }

    function updateExcludedContent(address _vava, string memory _contentName, bool _add) external {
        require(IAuth(_vava).devaddr_() == msg.sender, "VaHH12");
        if (_add) {
            require(IContent(contractAddress).contains(_contentName), "VaHH13");
            excludedContents[_vava].add(uint(keccak256(abi.encodePacked(_contentName))));
        } else {
            excludedContents[_vava].remove(uint(keccak256(abi.encodePacked(_contentName))));
        }
    }

    function getExcludedContents(address _vava) public view returns(string[] memory _excluded) {
        _excluded = new string[](excludedContents[_vava].length());
        for (uint i = 0; i < _excluded.length; i++) {
            _excluded[i] = IContent(contractAddress).indexToName(excludedContents[_vava].at(i));
        }
    }

    function updateMedia(address _sponsor, address _vava, string memory _media) external {
        require(IAuth(_sponsor).isAdmin(msg.sender), "VaHH14");
        require(IValuePool(_vava).isPayingSponsor(_sponsor));
        require(!ISponsor(_sponsor).contentContainsAny(getExcludedContents(_vava)), "VaHH15");
        media[_vava][_sponsor] = _media;
    }

    function _isEmpty(string memory val) internal pure returns(bool) {
        return keccak256(abi.encodePacked(val)) == keccak256(abi.encodePacked(""));
    }
    
    function autoUpdateGeoTag(address _vava, bool _add) external {
        require(IAuth(_vava).devaddr_() == msg.sender);
        autoUpdateTag[_vava] = _add;
    }

    function updateGeoTag(address _vava, uint _geoTag, uint _tokenId) external {
        address _ve = IValuePool(_vava)._ve();
        require(
            ve(_ve).ownerOf(_tokenId) == msg.sender || 
            IAuth(_vava).devaddr_() == msg.sender ||
            IAuth(contractAddress).devaddr_() == msg.sender
        );
        geoTag[_vava][_tokenId] = _geoTag;
    }
    
    function updateMaxNumMedia(uint _maxNumMedia) external {
        require(IAuth(contractAddress).devaddr_() == msg.sender);
        maxNumMedia = _maxNumMedia;
    }

    function getMedia(address _vava, uint _tokenId) external view returns(string[] memory mediaData) {
        address[] memory _sponsors = IValuePool(_vava).getAllSponsors(0,geoTag[_vava][_tokenId],true);
        uint _maxMedia = Math.min(maxNumMedia, _sponsors.length);
        mediaData = new string[](Math.max(1, _maxMedia));
        uint idx;
        for (uint i = 0; i < _maxMedia; i++) {
            string memory _mediaData = media[_vava][_sponsors[i]];
            // if (!_isEmpty(_mediaData)) {
                mediaData[idx++] = _mediaData;
            // }
        }
    }
}

contract ValuepoolVoter {
    address public contractAddress;
    enum VoteOption {
        Percentile,
        VotingPower,
        Unique
    }
    mapping(address => VoteOption) public voteOption;
    mapping(address => uint) public minPeriod;
    mapping(address => uint) public minBountyRequired;
    mapping(address => mapping(address => uint)) public totalWeight; // total voting weight
    mapping(address => uint) public period;
    mapping(address => uint) public collectionId;
    mapping(address => address[]) public pools; // all pools viable for incentives
    mapping(address => mapping(address => int256)) public weights; // pool => weight
    mapping(string => mapping(address => int256)) public votes; // nft => pool => votes
    mapping(address => mapping(uint => address[])) public poolVote; // nft => pools
    mapping(address => mapping(uint => uint)) public usedWeights;  // nft => total voting weight of user
    mapping(address => uint) public minimumLockValue;
    struct Gauge {
        uint amount;
        uint start;
        address token;
    }
    mapping(address => mapping(address => Gauge)) public gauges;
    mapping(address => mapping(address => bool)) public isGauge;
    mapping(address => mapping(address => bool)) public isBlacklisted;
    mapping(address => uint) public minDifference;
    
    event GaugeCreated(
        address user, 
        address ve, 
        address pool, 
        uint amount, 
        uint endTime, 
        string title, 
        string content
    );
    event UpdateTags(
        address ve,
        address pool,
        string countries,
        string cities,
        string products
    );
    event AddVa(
        address vava, 
        uint period, 
        uint minPeriod, 
        uint minDifference,
        uint collectionId, 
        uint minBountyRequired,
        uint minimumLockValue,
        VoteOption voteOption
    );
    event Voted(address indexed ve, address indexed pool, uint tokenId, uint profileId, uint _identityTokenId, uint weight, bool like);
    event Abstained(address indexed ve, uint tokenId, int256 weight);

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

    function getTotalWeight(address _ve, address _pool) public view returns(uint) {
        return totalWeight[_ve][_pool];
    }

    // function reset(address _ve, uint _tokenId, uint _profileId) external {
    //     require(ve(_ve).isApprovedOrOwner(msg.sender, _tokenId), "VaV1");
    //     _reset(_ve, _tokenId, _profileId);
    //     ve(_ve).abstain(_tokenId);
    // }

    function _reset(address _ve, uint _tokenId, uint _profileId) internal {
        address[] storage _poolVote = poolVote[_ve][_tokenId];
        uint _poolVoteCnt = _poolVote.length;
        require(IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender) == _profileId && _profileId > 0, "VaV2");
        for (uint i = 0; i < _poolVoteCnt; i ++) {
            int256 _totalWeight = 0;
            address _pool = _poolVote[i];
            string memory va_tokenId = string(abi.encodePacked(_ve, _profileId, _tokenId));
            int256 _votes = votes[va_tokenId][_pool];

            if (_votes != 0) {
                weights[_ve][_pool] -= _votes;
                votes[va_tokenId][_pool] -= _votes;
                if (_votes > 0) {
                    _totalWeight += _votes;
                    _totalWeight += _votes;
                } else {
                    _totalWeight -= _votes;
                }
                emit Abstained(_ve, _tokenId, _votes);
            }
            totalWeight[_ve][_pool] -= uint256(_totalWeight);
        }
        usedWeights[_ve][_tokenId] = 0;
        delete poolVote[_ve][_tokenId];
    }

    // function poke(address _ve, uint _tokenId, uint _profileId, uint _identityTokenId) external {
    //     address[] memory _poolVote = poolVote[_ve][_tokenId];
    //     uint _poolCnt = _poolVote.length;
    //     int256[] memory _weights = new int256[](_poolCnt);
    //     string memory ve_tokenId = string(abi.encodePacked(_ve, _profileId, _tokenId));

    //     for (uint i = 0; i < _poolCnt; i ++) {
    //         _weights[i] = votes[ve_tokenId][_poolVote[i]];
    //         _vote(_ve, _tokenId, _profileId, _identityTokenId, _poolVote[i], _weights[i]);
    //     }
    // }
    
    function _vote(
        address _ve, 
        address _pool, 
        uint _tokenId, 
        uint _profileId,
        uint _identityTokenId,
        bool _like
    ) internal {
        _reset(_ve, _tokenId, _profileId);
        int _totalWeight = 0;
        int _usedWeight = 0;
        uint _weight = voteOption[_ve] == VoteOption.VotingPower ? 
        ve(_ve).balanceOfNFT(_tokenId) :
        voteOption[_ve] == VoteOption.Percentile ? 
        ve(_ve).percentiles(_tokenId) :
        uint(1);
        address profile = IContract(contractAddress).profile();
        require(IProfile(profile).addressToProfileId(msg.sender) == _profileId && _profileId > 0, "VaV3");
        SSIData memory metadata = ISSI(IContract(contractAddress).ssi()).getSSID(_profileId);
        if (voteOption[_ve] == VoteOption.Unique) {
            require(IProfile(profile).isUnique(_profileId), "VaV4");
        }
        if (isGauge[_ve][_pool]) {
            int _poolWeight;
            _poolWeight = _like ? int(1) : int(-1);
            string memory va_tokenId = string(abi.encodePacked(_ve, _profileId, _tokenId));
            require(votes[va_tokenId][_pool] == 0, "VaV5");
            require(_poolWeight != 0, "VaV6");

            poolVote[_ve][_tokenId].push(_pool);
            
            weights[_ve][_pool] += _poolWeight * int(_weight);
            votes[va_tokenId][_pool] += _poolWeight * int(_weight);
            
            emit Voted(_ve, _pool, _tokenId, _profileId, _identityTokenId, _weight, _like);
            _usedWeight += _poolWeight * int(_weight);
            _totalWeight += _poolWeight * int(_weight);
        }
        totalWeight[_ve][_pool] += uint256(_totalWeight);
        usedWeights[_ve][_tokenId] = uint256(_usedWeight);
    }

    // identitytokenId can be required when info like the distribution of voters per country/gender,etc. is needed
    function vote(address _ve, address _pool, uint _tokenId, uint _profileId, uint _identityTokenId, bool _like) external {
        require(ve(_ve).isApprovedOrOwner(msg.sender, _tokenId), "VaV7");
        require(period[_ve] >= block.timestamp - gauges[_ve][_pool].start, "VaV07");
        _checkIdentityProof(_ve, msg.sender, _identityTokenId);
        _vote(_ve, _pool, _tokenId, _profileId, _identityTokenId, _like);
    }

    function _checkIdentityProof(address _ve, address _owner, uint _identityTokenId) internal {
        if (collectionId[_ve] > 0) {
            IMarketPlace(IContract(contractAddress).marketHelpers2())
            .checkUserIdentityProof(collectionId[_ve], _identityTokenId, _owner);
        }
    }

    function addVa(
        address _vava, 
        uint _period, 
        uint _minPeriod, 
        uint _minDifference,
        uint _collectionId, 
        uint _minBountyRequired, 
        uint _minimumLockValue,
        VoteOption _voteOption
    ) external {
        require(IAuth(_vava).devaddr_() == msg.sender && _period > 0, "VaV9");
        address _ve = IValuePool(_vava)._ve();
        period[_ve] = _period;
        voteOption[_ve] = _voteOption;
        minPeriod[_ve] = _minPeriod;
        minBountyRequired[_ve] = _minBountyRequired;
        minDifference[_ve] = _minDifference;
        minimumLockValue[_ve] = _minimumLockValue;
        if (_collectionId > 0) {
            collectionId[_ve] = IMarketPlace(IContract(contractAddress).marketCollections())
            .addressToCollectionId(msg.sender);
        }
        emit AddVa(
            _vava, 
            _period, 
            _minPeriod, 
            _minDifference,
            _collectionId, 
            _minBountyRequired,
            _minimumLockValue,
            _voteOption
        );
    }
    
    function updateBlacklist(address _vava, address _user, bool _add) external {
        require(IAuth(_vava).devaddr_() == msg.sender, "VaV09");
        isBlacklisted[IValuePool(_vava)._ve()][_user] = _add;
    }
    
    function createGauge(
        address _ve, 
        address _pool, 
        address _token,
        uint _tokenId, 
        uint _amount,
        string memory _title, 
        string memory _content
    ) external {
        require(period[_ve] > 0 && !isBlacklisted[_ve][_pool], "VaV10");
        require(_amount == 0 || 
        IARP(IContract(contractAddress).arpNote()).isLender(_pool, _ve, minPeriod[_ve], minBountyRequired[_ve]), "VaV11");
        require(_pool == msg.sender || IAuth(_pool).devaddr_() == msg.sender, "VaV12");
        require(va(_ve).balanceOfNFT(_tokenId) >= minimumLockValue[_ve] && va(_ve).ownerOf(_tokenId) == msg.sender, "VaV13");
        if (!isGauge[_ve][_pool]) pools[_ve].push(_pool);
        if (gauges[_ve][_pool].amount <= _amount || gauges[_ve][_pool].token != _token) {
            gauges[_ve][_pool].start = block.timestamp;
            gauges[_ve][_pool].token = _token;
        }
        gauges[_ve][_pool].amount = _amount;
        isGauge[_ve][_pool] = true;

        emit GaugeCreated(
            msg.sender, 
            _ve, 
            _pool, 
            _amount,
            block.timestamp + period[_ve] / period[_ve] * period[_ve],
            _title,
            _content
        );
    }

    function updateTags(
        address _ve,
        address _pool,
        string memory _countries,
        string memory _cities,
        string memory _products
    ) external {
        require(_pool == msg.sender || IAuth(_pool).devaddr_() == msg.sender, "VaV012");
        emit UpdateTags(
            _ve,
            _pool,
            _countries,
            _cities,
            _products
        );
    }

    function getBalance(address _ve, address _pool) external view returns(uint) {
        Gauge memory _gauge = gauges[_ve][_pool];
        uint _voteDifference = weights[_ve][_pool] > 0 ? uint(weights[_ve][_pool]) * 10000 / Math.max(1,totalWeight[_ve][_pool]) : 0;
        if (period[_ve] <= block.timestamp - _gauge.start && _voteDifference > minDifference[_ve]) {
            return _gauge.amount;
        }
        return 0;
    }

    function length(address _ve) external view returns (uint) {
        return pools[_ve].length;
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0, "VaV14");
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "VaV15");
    }
}

contract RandomNumberGenerator is VRFConsumerBase {
    using SafeERC20 for IERC20;

    address public valuepool;
    bytes32 public keyHash;
    mapping(bytes32 => uint) public latestTokenId;
    mapping(uint => uint32) private randomResult;
    uint public fee;
    mapping(uint => uint) public fulfilled;
    bool public freeRequests;
    uint TEST_CHAIN = 31337;
    uint TEST_CHAIN2 = 4002;
    uint nextRandomResult;

    /**
     * @notice Constructor
     * @dev RandomNumberGenerator must be deployed before the valuepool.
     * Once the valuepool contract is deployed, setValuepoolAddress must be called.
     * https://docs.chain.link/docs/vrf-contracts/
     * @param _vrfCoordinator: address of the VRF coordinator
     * @param _linkToken: address of the LINK token
     */
    constructor(
        address _vrfCoordinator, 
        address _linkToken,
        address _valuepool
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        valuepool = _valuepool;
    }

    function isTestChain() public view returns (bool) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id == TEST_CHAIN || id == TEST_CHAIN2;
    }

    // used only for testing
    function setNextRandomResult(uint256 _nextRandomResult) external {
        require(IAuth(valuepool).devaddr_() == msg.sender);
        nextRandomResult = _nextRandomResult;
    }

    /**
     * @notice Request randomness from a user-provided seed
     */
    function getRandomNumber(uint256 _tokenId) external {
        require(msg.sender == valuepool, "Only Valuepool");
        if (isTestChain()) {
            latestTokenId[0] = _tokenId;
            fulfillRandomness(0, nextRandomResult);
        } else {
            require(keyHash != bytes32(0), "Must have valid key hash");
            if (freeRequests) {
                require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK tokens");
            } else {
                assert(LINK.transferFrom(
                    ve(IValuePool(valuepool)._ve()).ownerOf(_tokenId), 
                    address(this), 
                    fee
                ));
            }
            latestTokenId[requestRandomness(keyHash, fee)] = _tokenId;
        }
    }

    /**
     * @notice Change the fee
     * @param _fee: new fee (in LINK)
     */
    function setFee(uint256 _fee, bool _freeRequests) external {
        require(IAuth(valuepool).devaddr_() == msg.sender);
        fee = _fee;
        freeRequests = _freeRequests;
    }

    /**
     * @notice Change the keyHash
     * @param _keyHash: new keyHash
     */
    function setKeyHash(bytes32 _keyHash) external {
        require(IAuth(valuepool).devaddr_() == msg.sender);
        keyHash = _keyHash;
    }

    /**
     * @notice It allows the admin to withdraw tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev Only callable by owner.
     */
    function withdrawTokens(address _tokenAddress, uint256 _tokenAmount) external {
        require(IAuth(valuepool).devaddr_() == msg.sender);
        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
    }

    /**
     * @notice View random result
     */
    function viewRandomResult(uint _tokenId) external view returns (uint32) {
        return randomResult[_tokenId];
    }
    
    /**
     * @notice Callback function used by ChainLink's VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(latestTokenId[requestId] != 0 || isTestChain(), "Wrong requestId");
        randomResult[latestTokenId[requestId]] = uint32(1000000 + (randomness % 1000000));
        fulfilled[latestTokenId[requestId]] = IValuePool(valuepool).epoch();
        delete latestTokenId[requestId];
    }
}

contract Ve {
    using SafeERC20 for IERC20;
    using Percentile for *;

    uint internal constant WEEK = 1 weeks;
    uint internal constant MAXTIME = 4 * 365 * 86400;
    int128 internal constant iMAXTIME = 4 * 365 * 86400;
    uint internal constant MULTIPLIER = 1 ether;

    address immutable public token;
    address immutable private valuepool;
    uint private supply;
    uint private maxSupply;
    uint private sods;
    uint private estimatedSize;
    uint private minTicketPrice;
    mapping(uint => uint) private deadlines;
    mapping(uint => uint) public percentiles;
    mapping(uint => LockedBalance) public locked;
    mapping(uint => uint) private minimumBalance;
    mapping(uint => uint) private ownership_change;

    uint private epoch;
    mapping(uint => Point) private point_history; // epoch -> unsigned point
    mapping(uint => Point[1000000000]) private user_point_history; // user -> Point[user_epoch]
    
    mapping(uint => uint) private user_point_epoch;
    mapping(uint => int128) private slope_changes; // time -> signed slope change
    mapping(uint => uint) private attachments;
    mapping(uint => bool) public voted; //maps to active voting period
    mapping(address => bool) private voters;
    bool public riskpool;
    uint private minToSwitch;
    uint private collectionId;
    address private contractAddress;
    address private valuepoolHelper;
    string public name;
    string public symbol;
    // string public version = "1.0.0";
    uint8 public decimals;
    bool public withdrawable;
    uint internal constant week = 86400 * 7; // allows minting once per week (reset every Thursday 00:00 UTC)

    /// @dev Current count of token
    uint public tokenId;

    /// @dev Mapping from NFT ID to the address that owns it.
    mapping(uint => address) internal idToOwner;

    /// @dev Mapping from NFT ID to approved address.
    mapping(uint => address) internal idToApprovals;

    /// @dev Mapping from owner address to count of his tokens.
    mapping(address => uint) internal ownerToNFTokenCount;

    /// @dev Mapping from owner address to mapping of index to tokenIds
    mapping(address => mapping(uint => uint)) internal ownerToNFTokenIdList;

    /// @dev Mapping from NFT ID to index of owner
    mapping(uint => uint) internal tokenToOwnerIndex;

    /// @dev Mapping from owner address to mapping of operator addresses.
    mapping(address => mapping(address => bool)) internal ownerToOperators;

    /// @dev Mapping of interface id to bool about whether or not it's supported
    mapping(bytes4 => bool) internal supportedInterfaces;

    /// @dev ERC165 interface ID of ERC165
    bytes4 internal constant ERC165_INTERFACE_ID = 0x01ffc9a7;

    /// @dev ERC165 interface ID of ERC721
    bytes4 internal constant ERC721_INTERFACE_ID = 0x80ac58cd;

    /// @dev ERC165 interface ID of ERC721Metadata
    bytes4 internal constant ERC721_METADATA_INTERFACE_ID = 0x5b5e139f;

    // /// @dev reentrancy guard
    // uint8 internal constant _not_entered = 1;
    // uint8 internal constant _entered = 2;
    // uint8 internal _entered_state = 1;
    // modifier nonreentrant() {
    //     require(_entered_state == _not_entered);
    //     _entered_state = _entered;
    //     _;
    //     _entered_state = _not_entered;
    // }
    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier nonreentrant() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }
    
    constructor(
        address token_addr,
        address _valuepool,
        // address _contractAddress,
        bool _riskpool
    ) {
        token = token_addr;
        riskpool = _riskpool;
        valuepool = _valuepool;
        point_history[0].blk = block.number;
        point_history[0].ts = block.timestamp;
        supportedInterfaces[ERC165_INTERFACE_ID] = true;
        supportedInterfaces[ERC721_INTERFACE_ID] = true;
        supportedInterfaces[ERC721_METADATA_INTERFACE_ID] = true;
        address _contractAddress = IValuePool(_valuepool).contractAddress();
        contractAddress = _contractAddress;
        valuepoolHelper = IContract(_contractAddress).valuepoolHelper();
        IValuePool(_valuepool).updateVa();
        // // mint-ish
        // IValuePool(valuepoolHelper).emitTransfer(address(0), address(this), tokenId);
        // // burn-ish
        // IValuePool(valuepoolHelper).emitTransfer(address(this), address(0), tokenId);
    }

    function _trustBounty() internal view returns(address) {
        return IContract(contractAddress).trustBounty();
    }

    /// @dev Interface identification is specified in ERC-165.
    /// @param _interfaceID Id of the interface
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return supportedInterfaces[_interfaceID];
    }

    function switchPool() external {
        require(IAuth(valuepool).devaddr_() == msg.sender);
        if (supply >= minToSwitch) {
            riskpool = !riskpool;
            IValuePool(valuepoolHelper).emitSwitch(valuepool);
        }
    }

    function getParams() external view returns(uint,uint,uint,uint,uint) {
        return (
            supply,
            maxSupply,
            estimatedSize,
            minTicketPrice,
            minToSwitch
        );
    }

    function setParams(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint _minToSwitch,
        uint _maxSupply,
        uint _estimatedSize,
        uint _minTicketPrice,
        bool _withdrawable
    ) external {
        if (decimals == 0) {
            name = _name;
            symbol = _symbol;
            decimals = _decimals;
            estimatedSize = _estimatedSize;
            minTicketPrice = _minTicketPrice;
            minToSwitch = _minToSwitch;
            withdrawable = _withdrawable;
            maxSupply = maxSupply == 0 ? type(uint).max : _maxSupply;
            IValuePool(valuepoolHelper).emitSetParams(
                valuepool,
                _name,
                _symbol,
                _decimals,
                _maxSupply,
                minTicketPrice,
                minToSwitch
            );
        }
    }
    
    function setCollectionId(uint _collectionId) external {
        require(IAuth(valuepool).devaddr_() == msg.sender);
        collectionId = _collectionId;
    }

    function verifyNFT(uint ticketId, uint cardId, string memory item) external view returns(uint) {
        if(ticketId <= tokenId && IValuePool(IContract(contractAddress).valuepoolHelper()).verifyCardId(cardId)) {
            return 1;
        }
        return 0;
    }

    /// @notice Get the most recently recorded rate of voting power decrease for `_tokenId`
    /// @param _tokenId token of the NFT
    /// @return Value of the slope
    function get_last_user_slope(uint _tokenId) external view returns (int128) {
        uint uepoch = user_point_epoch[_tokenId];
        return user_point_history[_tokenId][uepoch].slope;
    }

    /// @notice Get the timestamp for checkpoint `_idx` for `_tokenId`
    /// @param _tokenId token of the NFT
    /// @param _idx User epoch number
    /// @return Epoch time of the checkpoint
    function user_point_history__ts(uint _tokenId, uint _idx) external view returns (uint) {
        return user_point_history[_tokenId][_idx].ts;
    }

    /// @dev Returns the number of NFTs owned by `_owner`.
    ///      Throws if `_owner` is the zero address. NFTs assigned to the zero address are considered invalid.
    /// @param _owner Address for whom to query the balance.
    function _balance(address _owner) internal view returns (uint) {
        return ownerToNFTokenCount[_owner];
    }

    /// @dev Returns the number of NFTs owned by `_owner`.
    ///      Throws if `_owner` is the zero address. NFTs assigned to the zero address are considered invalid.
    /// @param _owner Address for whom to query the balance.
    function balanceOf(address _owner) external view returns (uint) {
        return _balance(_owner);
    }

    /// @dev Returns the address of the owner of the NFT.
    /// @param _tokenId The identifier for an NFT.
    function ownerOf(uint _tokenId) public view returns (address) {
        return idToOwner[_tokenId];
    }

    /// @dev Get the approved address for a single NFT.
    /// @param _tokenId ID of the NFT to query the approval of.
    function getApproved(uint _tokenId) external view returns (address) {
        return idToApprovals[_tokenId];
    }

    /// @dev Checks if `_operator` is an approved operator for `_owner`.
    /// @param _owner The address that owns the NFTs.
    /// @param _operator The address that acts on behalf of the owner.
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return (ownerToOperators[_owner])[_operator];
    }

    /// @dev  Get token by index
    function tokenOfOwnerByIndex(address _owner, uint _tokenIndex) external view returns (uint) {
        return ownerToNFTokenIdList[_owner][_tokenIndex];
    }

    /// @dev Returns whether the given spender can transfer a given token ID
    /// @param _spender address of the spender to query
    /// @param _tokenId uint ID of the token to be transferred
    /// @return bool whether the msg.sender is approved for the given token ID, is an operator of the owner, or is the owner of the token
    function _isApprovedOrOwner(address _spender, uint _tokenId) internal view returns (bool) {
        address owner = idToOwner[_tokenId];
        bool spenderIsOwner = owner == _spender;
        bool spenderIsApproved = _spender == idToApprovals[_tokenId];
        bool spenderIsApprovedForAll = (ownerToOperators[owner])[_spender];
        return spenderIsOwner || spenderIsApproved || spenderIsApprovedForAll;
    }

    function isApprovedOrOwner(address _spender, uint _tokenId) external view returns (bool) {
        return _isApprovedOrOwner(_spender, _tokenId);
    }

    /// @dev Add a NFT to an index mapping to a given address
    /// @param _to address of the receiver
    /// @param _tokenId uint ID Of the token to be added
    function _addTokenToOwnerList(address _to, uint _tokenId) internal {
        uint current_count = _balance(_to);

        ownerToNFTokenIdList[_to][current_count] = _tokenId;
        tokenToOwnerIndex[_tokenId] = current_count;
    }

    /// @dev Remove a NFT from an index mapping to a given address
    /// @param _from address of the sender
    /// @param _tokenId uint ID Of the token to be removed
    function _removeTokenFromOwnerList(address _from, uint _tokenId) internal {
        // Delete
        uint current_count = _balance(_from)-1;
        uint current_index = tokenToOwnerIndex[_tokenId];

        if (current_count == current_index) {
            // update ownerToNFTokenIdList
            ownerToNFTokenIdList[_from][current_count] = 0;
            // update tokenToOwnerIndex
            tokenToOwnerIndex[_tokenId] = 0;
        } else {
            uint lastTokenId = ownerToNFTokenIdList[_from][current_count];

            // Add
            // update ownerToNFTokenIdList
            ownerToNFTokenIdList[_from][current_index] = lastTokenId;
            // update tokenToOwnerIndex
            tokenToOwnerIndex[lastTokenId] = current_index;

            // Delete
            // update ownerToNFTokenIdList
            ownerToNFTokenIdList[_from][current_count] = 0;
            // update tokenToOwnerIndex
            tokenToOwnerIndex[_tokenId] = 0;
        }
    }

    /// @dev Add a NFT to a given address
    ///      Throws if `_tokenId` is owned by someone.
    function _addTokenTo(address _to, uint _tokenId) internal {
        // Throws if `_tokenId` is owned by someone
        assert(idToOwner[_tokenId] == address(0));
        // Change the owner
        idToOwner[_tokenId] = _to;
        // Update owner token index tracking
        _addTokenToOwnerList(_to, _tokenId);
        // Change count tracking
        ownerToNFTokenCount[_to] += 1;
    }

    /// @dev Remove a NFT from a given address
    ///      Throws if `_from` is not the current owner.
    function _removeTokenFrom(address _from, uint _tokenId) internal {
        // Throws if `_from` is not the current owner
        assert(idToOwner[_tokenId] == _from);
        // Change the owner
        idToOwner[_tokenId] = address(0);
        // Update owner token index tracking
        _removeTokenFromOwnerList(_from, _tokenId);
        // Change count tracking
        ownerToNFTokenCount[_from] -= 1;
    }

    /// @dev Clear an approval of a given address
    ///      Throws if `_owner` is not the current owner.
    function _clearApproval(address _owner, uint _tokenId) internal {
        // Throws if `_owner` is not the current owner
        assert(idToOwner[_tokenId] == _owner);
        if (idToApprovals[_tokenId] != address(0)) {
            // Reset approvals
            idToApprovals[_tokenId] = address(0);
        }
    }

    /// @dev Execute transfer of a NFT.
    ///      Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
    ///      address for this NFT. (NOTE: `msg.sender` not allowed in internal function so pass `_sender`.)
    ///      Throws if `_to` is the zero address.
    ///      Throws if `_from` is not the current owner.
    ///      Throws if `_tokenId` is not a valid NFT.
    function _transferFrom(
        address _from,
        address _to,
        uint _tokenId,
        address _sender
    ) internal {
        require(attachments[_tokenId] == 0 && !voted[_tokenId]);
        // Check requirements
        require(_isApprovedOrOwner(_sender, _tokenId));
        // Clear approval. Throws if `_from` is not the current owner
        _clearApproval(_from, _tokenId);
        // Remove NFT. Throws if `_tokenId` is not a valid NFT
        _removeTokenFrom(_from, _tokenId);
        // Add NFT
        _addTokenTo(_to, _tokenId);
        // Set the block of ownership transfer (for Flash NFT protection)
        ownership_change[_tokenId] = block.number;
        // Log the transfer
        // IValuePool(valuepoolHelper).emitTransfer(_from, _to, _tokenId);
    }

    // /* TRANSFER FUNCTIONS */
    // /// @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for this NFT.
    // ///      Throws if `_from` is not the current owner.
    // ///      Throws if `_to` is the zero address.
    // ///      Throws if `_tokenId` is not a valid NFT.
    // /// @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
    // ///        they maybe be permanently lost.
    // /// @param _from The current owner of the NFT.
    // /// @param _to The new owner.
    // /// @param _tokenId The NFT to transfer.
    // function transferFrom(
    //     address _from,
    //     address _to,
    //     uint _tokenId
    // ) external {
    //     _transferFrom(_from, _to, _tokenId, msg.sender);
    // }

    function _isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    // /// @dev Transfers the ownership of an NFT from one address to another address.
    // ///      Throws unless `msg.sender` is the current owner, an authorized operator, or the
    // ///      approved address for this NFT.
    // ///      Throws if `_from` is not the current owner.
    // ///      Throws if `_to` is the zero address.
    // ///      Throws if `_tokenId` is not a valid NFT.
    // ///      If `_to` is a smart contract, it calls `onERC721Received` on `_to` and throws if
    // ///      the return value is not `bytes4(keccak256("onERC721Received(address,address,uint,bytes)"))`.
    // /// @param _from The current owner of the NFT.
    // /// @param _to The new owner.
    // /// @param _tokenId The NFT to transfer.
    // function safeTransferFrom(
    //     address _from,
    //     address _to,
    //     uint _tokenId,
    //     bytes memory _data
    // ) public {
    //     _transferFrom(_from, _to, _tokenId, msg.sender);

        // if (_isContract(_to)) {
        //     // Throws if transfer destination is a contract which does not implement 'onERC721Received'
        //     try IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, '') returns (bytes4) {} catch (
        //         bytes memory reason
        //     ) {
        //         if (reason.length == 0) {
        //             revert('ERC721: Ve1');
        //         } else {
        //             assembly {
        //                 revert(add(32, reason), mload(reason))
        //             }
        //         }
        //     }
        // }
    // }

    /// @dev Transfers the ownership of an NFT from one address to another address.
    ///      Throws unless `msg.sender` is the current owner, an authorized operator, or the
    ///      approved address for this NFT.
    ///      Throws if `_from` is not the current owner.
    ///      Throws if `_to` is the zero address.
    ///      Throws if `_tokenId` is not a valid NFT.
    ///      If `_to` is a smart contract, it calls `onERC721Received` on `_to` and throws if
    ///      the return value is not `bytes4(keccak256("onERC721Received(address,address,uint,bytes)"))`.
    /// @param _from The current owner of the NFT.
    /// @param _to The new owner.
    /// @param _tokenId The NFT to transfer.
    function safeTransferFrom(
        address _from,
        address _to,
        uint _tokenId
    ) external {
        _transferFrom(_from, _to, _tokenId, msg.sender);
        // safeTransferFrom(_from, _to, _tokenId, '');
    }

    /// @dev Set or reaffirm the approved address for an NFT. The zero address indicates there is no approved address.
    ///      Throws unless `msg.sender` is the current NFT owner, or an authorized operator of the current owner.
    ///      Throws if `_tokenId` is not a valid NFT. (NOTE: This is not written the EIP)
    ///      Throws if `_approved` is the current owner. (NOTE: This is not written the EIP)
    /// @param _approved Address to be approved for the given NFT ID.
    /// @param _tokenId ID of the token to be approved.
    function approve(address _approved, uint _tokenId) public {
        address owner = idToOwner[_tokenId];
        // Throws if `_tokenId` is not a valid NFT
        require(owner != address(0));
        // Throws if `_approved` is the current owner
        require(_approved != owner);
        // Check requirements
        bool senderIsOwner = (idToOwner[_tokenId] == msg.sender);
        bool senderIsApprovedForAll = (ownerToOperators[owner])[msg.sender];
        require(senderIsOwner || senderIsApprovedForAll);
        // Set the approval
        idToApprovals[_tokenId] = _approved;
        // IValuePool(valuepoolHelper).emitApproval(owner, _approved, _tokenId);
    }

    /// @dev Enables or disables approval for a third party ("operator") to manage all of
    ///      `msg.sender`'s assets. It also emits the ApprovalForAll event.
    ///      Throws if `_operator` is the `msg.sender`. (NOTE: This is not written the EIP)
    /// @notice This works even if sender doesn't own any tokens at the time.
    /// @param _operator Address to add to the set of authorized operators.
    /// @param _approved True if the operators is approved, false to revoke approval.
    function setApprovalForAll(address _operator, bool _approved) external {
        // Throws if `_operator` is the `msg.sender`
        assert(_operator != msg.sender);
        ownerToOperators[msg.sender][_operator] = _approved;
        // IValuePool(_valuepoolHelper()).emitApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @dev Function to mint tokens
    ///      Throws if `_to` is zero address.
    ///      Throws if `_tokenId` is owned by someone.
    /// @param _to The address that will receive the minted tokens.
    /// @param _tokenId The token id to mint.
    /// @return A boolean that indicates if the operation was successful.
    function _mint(address _to, uint _tokenId) internal returns (bool) {
        // Throws if `_to` is zero address
        assert(_to != address(0));
        // Add NFT. Throws if `_tokenId` is owned by someone
        _addTokenTo(_to, _tokenId);
        // IValuePool(valuepoolHelper).emitTransfer(address(0), _to, _tokenId);
        return true;
    }

    /// @notice Record global and per-user data to checkpoint
    /// @param _tokenId NFT token ID. No user checkpoint if 0
    /// @param old_locked Pevious locked amount / end lock time for the user
    /// @param new_locked New locked amount / end lock time for the user
    function _checkpoint(
        uint _tokenId,
        LockedBalance memory old_locked,
        LockedBalance memory new_locked
    ) internal {
        Point memory u_old;
        Point memory u_new;
        int128 old_dslope = 0;
        int128 new_dslope = 0;
        uint _epoch = epoch;

        if (_tokenId != 0) {
            // Calculate slopes and biases
            // Kept at zero when they have to
            if (old_locked.end > block.timestamp && old_locked.amount > 0) {
                u_old.slope = old_locked.amount / iMAXTIME;
                u_old.bias = u_old.slope * int128(int256(old_locked.end - block.timestamp));
            }
            if (new_locked.end > block.timestamp && new_locked.amount > 0) {
                u_new.slope = new_locked.amount / iMAXTIME;
                u_new.bias = u_new.slope * int128(int256(new_locked.end - block.timestamp));
            }

            // Read values of scheduled changes in the slope
            // old_locked.end can be in the past and in the future
            // new_locked.end can ONLY by in the FUTURE unless everything expired: then zeros
            old_dslope = slope_changes[old_locked.end];
            if (new_locked.end != 0) {
                if (new_locked.end == old_locked.end) {
                    new_dslope = old_dslope;
                } else {
                    new_dslope = slope_changes[new_locked.end];
                }
            }
        }

        Point memory last_point = Point({bias: 0, slope: 0, ts: block.timestamp, blk: block.number});
        if (_epoch > 0) {
            last_point = point_history[_epoch];
        }
        uint last_checkpoint = last_point.ts;
        // initial_last_point is used for extrapolation to calculate block number
        // (approximately, for *At methods) and save them
        // as we cannot figure that out exactly from inside the contract
        Point memory initial_last_point = last_point;
        uint block_slope = 0; // dblock/dt
        if (block.timestamp > last_point.ts) {
            block_slope = (MULTIPLIER * (block.number - last_point.blk)) / (block.timestamp - last_point.ts);
        }
        // If last point is already recorded in this block, slope=0
        // But that's ok b/c we know the block in such case

        // Go over weeks to fill history and calculate what the current point is
        {
            uint t_i = (last_checkpoint / WEEK) * WEEK;
            for (uint i = 0; i < 255; ++i) {
                // Hopefully it won't happen that this won't get used in 5 years!
                // If it does, users will be able to withdraw but vote weight will be broken
                t_i += WEEK;
                int128 d_slope = 0;
                if (t_i > block.timestamp) {
                    t_i = block.timestamp;
                } else {
                    d_slope = slope_changes[t_i];
                }
                last_point.bias -= last_point.slope * int128(int256(t_i - last_checkpoint));
                last_point.slope += d_slope;
                if (last_point.bias < 0) {
                    // This can happen
                    last_point.bias = 0;
                }
                if (last_point.slope < 0) {
                    // This cannot happen - just in case
                    last_point.slope = 0;
                }
                last_checkpoint = t_i;
                last_point.ts = t_i;
                last_point.blk = initial_last_point.blk + (block_slope * (t_i - initial_last_point.ts)) / MULTIPLIER;
                _epoch += 1;
                if (t_i == block.timestamp) {
                    last_point.blk = block.number;
                    break;
                } else {
                    point_history[_epoch] = last_point;
                }
            }
        }

        epoch = _epoch;
        // Now point_history is filled until t=now

        if (_tokenId != 0) {
            // If last point was in this block, the slope change has been applied already
            // But in such case we have 0 slope(s)
            last_point.slope += (u_new.slope - u_old.slope);
            last_point.bias += (u_new.bias - u_old.bias);
            if (last_point.slope < 0) {
                last_point.slope = 0;
            }
            if (last_point.bias < 0) {
                last_point.bias = 0;
            }
        }

        // Record the changed point into history
        point_history[_epoch] = last_point;

        if (_tokenId != 0) {
            // Schedule the slope changes (slope is going down)
            // We subtract new_user_slope from [new_locked.end]
            // and add old_user_slope to [old_locked.end]
            if (old_locked.end > block.timestamp) {
                // old_dslope was <something> - u_old.slope, so we cancel that
                old_dslope += u_old.slope;
                if (new_locked.end == old_locked.end) {
                    old_dslope -= u_new.slope; // It was a new deposit, not extension
                }
                slope_changes[old_locked.end] = old_dslope;
            }

            if (new_locked.end > block.timestamp) {
                if (new_locked.end > old_locked.end) {
                    new_dslope -= u_new.slope; // old slope disappeared at this point
                    slope_changes[new_locked.end] = new_dslope;
                }
                // else: we recorded it already in old_dslope
            }
            // Now handle user history
            uint user_epoch = user_point_epoch[_tokenId] + 1;

            user_point_epoch[_tokenId] = user_epoch;
            u_new.ts = block.timestamp;
            u_new.blk = block.number;
            user_point_history[_tokenId][user_epoch] = u_new;
        }
    }

    /// @notice Deposit and lock tokens for a user
    /// @param _tokenId NFT that holds lock
    /// @param _value Amount to deposit
    /// @param unlock_time New time when to unlock the tokens, or 0 if unchanged
    /// @param locked_balance Previous locked amount / timestamp
    /// @param deposit_type The type of deposit
    function _deposit_for(
        uint _tokenId,
        uint _value,
        uint unlock_time,
        LockedBalance memory locked_balance,
        DepositType deposit_type
    ) internal {
        LockedBalance memory _locked = locked_balance;
        uint supply_before = supply;

        require(supply_before + _value <= maxSupply);
        supply = supply_before + _value;
        LockedBalance memory old_locked;
        (old_locked.amount, old_locked.end) = (_locked.amount, _locked.end);
        // Adding to existing lock, or if a lock is expired - creating a new one
        _locked.amount += int128(int256(_value));
        if (unlock_time != 0) {
            _locked.end = unlock_time;
        }
        locked[_tokenId] = _locked;

        // Possibilities:
        // Both old_locked.end could be current or expired (>/< block.timestamp)
        // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
        // _locked.end > block.timestamp (always)
        _checkpoint(_tokenId, old_locked, _locked);
        (uint _percentile, uint _sods) = Percentile.computePercentileFromData(
            false, 
            _balanceOfNFT(_tokenId, block.timestamp), 
            Math.max(estimatedSize, supply_before), 
            _tokenId, 
            sods
        );
        sods = _sods;
        percentiles[_tokenId] = _percentile;
        // address from = msg.sender;
        if (_value != 0 && deposit_type != DepositType.MERGE_TYPE) {
            IERC20(token).safeTransferFrom(msg.sender, address(this), _value);
            // assert(IERC20(token).transferFrom(from, address(this), _value));
        }

        IValuePool(valuepoolHelper).emitDeposit(
            valuepool, 
            msg.sender, 
            _tokenId, 
            _value,
            _locked.end, 
            deposit_type, 
            _percentile
        );
        // IValuePool(valuepoolHelper).emitSupply(valuepool, supply_before, supply_before + _value);
    }

    function setVoter(address _voter) external {
        require(voters[msg.sender]);
        voters[_voter] = true;
    }

    function voting(uint _tokenId) external {
        require(voters[msg.sender]);
        voted[_tokenId] = true;
    }

    function abstain(uint _tokenId) external {
        require(voters[msg.sender]);
        voted[_tokenId] = false;
    }

    // function attach(uint _tokenId) external {
    //     require(voters[msg.sender]);
    //     attachments[_tokenId] = attachments[_tokenId]+1;
    // }

    // function detach(uint _tokenId) external {
    //     require(voters[msg.sender]);
    //     attachments[_tokenId] = attachments[_tokenId]-1;
    // }

    function merge(uint _from, uint _to) external {
        require(attachments[_from] == 0 && !voted[_from]);

        require(_from != _to);
        require(_isApprovedOrOwner(msg.sender, _from));
        require(_isApprovedOrOwner(msg.sender, _to));

        LockedBalance memory _locked0 = locked[_from];
        LockedBalance memory _locked1 = locked[_to];
        uint value0 = uint(int256(_locked0.amount));
        uint end = _locked0.end >= _locked1.end ? _locked0.end : _locked1.end;

        locked[_from] = LockedBalance(0, 0);
        _checkpoint(_from, _locked0, LockedBalance(0, 0));
        _burn(_from);
        _deposit_for(_to, value0, end, _locked1, DepositType.MERGE_TYPE);
    }

    /// @notice Record global data to checkpoint
    function checkpoint() external {
        _checkpoint(0, LockedBalance(0, 0), LockedBalance(0, 0));
    }

    /// @notice Deposit `_value` tokens for `_tokenId` and add to the lock
    /// @dev Anyone (even a smart contract) can deposit for someone else, but
    ///      cannot extend their locktime and deposit for a brand new user
    /// @param _tokenId lock NFT
    /// @param _value Amount to add to user's lock
    function deposit_for(uint _tokenId, uint _value) external nonreentrant {
        LockedBalance memory _locked = locked[_tokenId];

        require(_value > 0); // dev: need non-zero value
        require(_locked.amount > 0);
        require(_locked.end > block.timestamp);
        _deposit_for(_tokenId, _value, 0, _locked, DepositType.DEPOSIT_FOR_TYPE);
    }

    /// @notice Deposit `_value` tokens for `_to` and lock for `_lock_duration`
    /// @param _value Amount to deposit
    /// @param _lock_duration Number of seconds to lock tokens for (rounded down to nearest week)
    /// @param _to Address to deposit
    function _create_lock(uint _value, uint _lock_duration, uint _identityTokenId, address _to) internal returns (uint) {
        require(_value >= minTicketPrice);
        uint unlock_time = (block.timestamp + _lock_duration) / WEEK * WEEK; // Locktime is rounded down to weeks

        require(_value > 0); // dev: need non-zero value
        require(unlock_time > block.timestamp);
        require(unlock_time <= block.timestamp + MAXTIME);
        if (collectionId > 0) {
            IMarketPlace(IContract(contractAddress).marketHelpers2()).checkPartnerIdentityProof(
                collectionId, 
                _identityTokenId, 
                _to
            );
        }
        // ++tokenId;
        // uint _tokenId = tokenId;
        _mint(_to, ++tokenId);

        _deposit_for(tokenId, _value, unlock_time, locked[tokenId], DepositType.CREATE_LOCK_TYPE);
        return tokenId;
    }

    /// @notice Deposit `_value` tokens for `_to` and lock for `_lock_duration`
    /// @param _value Amount to deposit
    /// @param _lock_duration Number of seconds to lock tokens for (rounded down to nearest week)
    /// @param _to Address to deposit
    function create_lock_for(uint _value, uint _lock_duration, uint _identityTokenId, address _to) external nonreentrant returns (uint) {
        return _create_lock(_value, _lock_duration, _identityTokenId, _to);
    }

    // /// @notice Deposit `_value` tokens for `msg.sender` and lock for `_lock_duration`
    // /// @param _value Amount to deposit
    // /// @param _lock_duration Number of seconds to lock tokens for (rounded down to nearest week)
    // function create_lock(uint _value, uint _lock_duration, uint _identityTokenId) external nonreentrant returns (uint) {
    //     return _create_lock(_value, _lock_duration, _identityTokenId, msg.sender);
    // }

    // function increase_amount_and_unlock_time(uint _tokenId, uint _value, uint _lock_duration) external nonreentrant {
    //     assert(_isApprovedOrOwner(msg.sender, _tokenId));

    //     LockedBalance memory _locked = locked[_tokenId];

    //     assert(_value > 0); // dev: need non-zero value
    //     require(_locked.amount > 0);
    //     require(_locked.end > block.timestamp);

    //     uint unlock_time = _lock_duration > 0 ? (block.timestamp + _lock_duration) / WEEK * WEEK : 0; // Locktime is rounded down to weeks
    //     require(unlock_time > _locked.end || unlock_time == 0);
    //     require(unlock_time <= block.timestamp + MAXTIME);

    //     _deposit_for(_tokenId, _value, unlock_time, _locked, DepositType.INCREASE_LOCK_AMOUNT_AND_UNLOCK_TIME);
    // }

    /// @notice Deposit `_value` additional tokens for `_tokenId` without modifying the unlock time
    /// @param _value Amount of tokens to deposit and add to the lock
    function increase_amount(uint _tokenId, uint _value) external nonreentrant {
        assert(_isApprovedOrOwner(msg.sender, _tokenId));

        LockedBalance memory _locked = locked[_tokenId];

        assert(_value > 0); // dev: need non-zero value
        require(_locked.amount > 0 && _locked.end > block.timestamp);
        // require(_locked.end > block.timestamp);

        _deposit_for(_tokenId, _value, 0, _locked, DepositType.INCREASE_LOCK_AMOUNT);
    }

    /// @notice Extend the unlock time for `_tokenId`
    /// @param _lock_duration New number of seconds until tokens unlock
    function increase_unlock_time(uint _tokenId, uint _lock_duration) external nonreentrant {
        assert(_isApprovedOrOwner(msg.sender, _tokenId));

        LockedBalance memory _locked = locked[_tokenId];
        uint unlock_time = (block.timestamp + _lock_duration) / WEEK * WEEK; // Locktime is rounded down to weeks

        require(_locked.end > block.timestamp);
        require(_locked.amount > 0 && unlock_time > _locked.end);
        // require(unlock_time > _locked.end);
        require(unlock_time <= block.timestamp + MAXTIME);

        _deposit_for(_tokenId, 0, unlock_time, _locked, DepositType.INCREASE_UNLOCK_TIME);
    }

    function adminWithdraw(bool _toVava) external {
        address businessGauge = _toVava 
        ? valuepoolHelper
        : IMarketPlace(IContract(contractAddress).businessGaugeFactory()).hasGauge(collectionId);
        require(riskpool && businessGauge != address(0x0));
        // uint _amount = erc20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(businessGauge, erc20(token).balanceOf(address(this)));
        // assert(IERC20(token).transfer(businessGauge, erc20(token).balanceOf(address(this))));
    } 

    function getWithdrawable(uint _tokenId) public view  returns(uint) {
        uint _percent_withdrawable =  block.timestamp * 10000 / locked[_tokenId].end;
        if(!withdrawable) {
            return block.timestamp >= locked[_tokenId].end ? uint(int(locked[_tokenId].amount)) : 0;
        } 
        return uint(int(locked[_tokenId].amount)) * _percent_withdrawable / 10000 - minimumBalance[_tokenId];
    }
    
    function updateMinimumBalance(address _owner, uint _tokenId, uint _amount, uint _deadline) external {
        require(msg.sender == _trustBounty());
        // assert(_isApprovedOrOwner(_owner, _tokenId));
        require(_amount <= getWithdrawable(_tokenId));
        minimumBalance[_tokenId] += _amount;
        deadlines[_tokenId] = _deadline;
        // IValuePool(_valuepoolHelper()).emitUpdateMinimumBalance(_owner, _tokenId, _amount);
    }

    function deleteMinimumBalance(address _owner, uint _tokenId, uint _amount) external {
        require(msg.sender == _trustBounty());
        // assert(_isApprovedOrOwner(_owner, _tokenId));
        require(
            // _amount <= minimumBalance[_tokenId] && 
        deadlines[_tokenId] < block.timestamp);
        minimumBalance[_tokenId] -= _amount;
        // IValuePool(_valuepoolHelper()).emitDeleteMinimumBalance(_owner, _tokenId, _amount);
    }

    function withdrawBounty(address _owner, uint _tokenId, uint _amount) external {
        require(msg.sender == _trustBounty());
        // assert(_isApprovedOrOwner(_owner, _tokenId));
        minimumBalance[_tokenId] -= _amount;
    }

    /// @notice Withdraw all tokens for `_tokenId`
    /// @dev Only possible if the lock has expired
    function withdraw(uint _tokenId) external nonreentrant {
        assert(_isApprovedOrOwner(msg.sender, _tokenId));
        assert(!riskpool);
        require(attachments[_tokenId] == 0 && !voted[_tokenId]);
        
        LockedBalance memory _locked = locked[_tokenId];
        uint value = getWithdrawable(_tokenId);

        locked[_tokenId] = LockedBalance(_locked.amount - int128(int(value)), _locked.end);
        uint supply_before = supply;
        supply = supply_before - value;

        // old_locked can have either expired <= timestamp or zero end
        // _locked has only 0 end
        // Both can have >= 0 amount
        _checkpoint(_tokenId, _locked, LockedBalance(_locked.amount - int128(int(value)), _locked.end));
        uint payswapFees = value * IValuePool(valuepoolHelper).tradingFee() / 10000;
        value -= payswapFees;
        (uint percentile, uint _sods) = Percentile.computePercentileFromData(
            false, 
            uint(int(_locked.amount)) - value, 
            Math.max(estimatedSize, supply), 
            _tokenId, 
            sods
        );
        sods = _sods;
        percentiles[_tokenId] = percentile;
        IERC20(token).safeTransfer(msg.sender, value);
        // assert(IERC20(token).transfer(msg.sender, value));
        IERC20(token).safeTransfer(valuepoolHelper, payswapFees);
        // assert(IERC20(token).transfer(valuepoolHelper, payswapFees));

        // Burn the NFT
        if (_locked.amount <= int128(int(value))) _burn(_tokenId);
        IValuePool(valuepoolHelper).emitWithdraw(
            msg.sender, 
            _tokenId, 
            value,
            _balanceOfNFT(_tokenId, block.timestamp),
            percentile
        );
        // IValuePool(valuepoolHelper).emitSupply(valuepool, supply_before, supply_before - value);
    }

    // The following ERC20/minime-compatible methods are not real balanceOf and supply!
    // They measure the weights for the purpose of voting, so they don't represent
    // real coins.

    /// @notice Binary search to estimate timestamp for block number
    /// @param _block Block to find
    /// @param max_epoch Don't go beyond this epoch
    /// @return Approximate timestamp for block
    function _find_block_epoch(uint _block, uint max_epoch) internal view returns (uint) {
        // Binary search
        uint _min = 0;
        uint _max = max_epoch;
        for (uint i = 0; i < 128; ++i) {
            // Will be always enough for 128-bit numbers
            if (_min >= _max) {
                break;
            }
            uint _mid = (_min + _max + 1) / 2;
            if (point_history[_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    /// @notice Get the current voting power for `_tokenId`
    /// @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
    /// @param _tokenId NFT for lock
    /// @param _t Epoch time to return voting power at
    /// @return User voting power
    function _balanceOfNFT(uint _tokenId, uint _t) internal view returns (uint) {
        uint _epoch = user_point_epoch[_tokenId];
        if (_epoch == 0) {
            return 0;
        } else {
            Point memory last_point = user_point_history[_tokenId][_epoch];
            last_point.bias -= last_point.slope * int128(int256(_t) - int256(last_point.ts));
            if (last_point.bias < 0) {
                last_point.bias = 0;
            }
            return uint(int256(last_point.bias));
        }
    }

    /// @dev Returns current token URI metadata
    /// @param _tokenId Token ID to fetch URI for.
    function tokenURI(uint _tokenId) public view returns (string memory) {
        require(idToOwner[_tokenId] != address(0));
        (string[] memory optionNames, string[] memory optionValues) = _populate(_tokenId);
        return IMarketPlace(IContract(contractAddress).nftSvg()).constructTokenURI(
            _tokenId,
            '',
            valuepool,
            token,
            ownerOf(_tokenId),
            address(0x0),
            IValuePool(IContract(contractAddress).valuepoolHelper2()).getMedia(valuepool,_tokenId),
            optionNames,
            optionValues,
            new string[](1) //IValuePool(valuepoolHelper).getDescription(valuepool);
        );
    }

    function _populate(uint _tokenId) internal view returns(string[] memory optionNames,string[] memory optionValues) {
        optionNames = new string[](12);
        optionValues = new string[](12);
        uint idx;
        (uint _percentile,) = IValuePool(valuepool).userInfo(_tokenId);
        optionNames[idx] = "Type";
        optionValues[idx++] = riskpool ? "RiskPool" : "ValuePool"; 
        optionValues[idx++] = string(abi.encodePacked(name, ", ", symbol));
        optionNames[idx] = "Balance";
        optionValues[idx++] = toString(_balanceOfNFT(_tokenId, block.timestamp) / 10**decimals);
        optionNames[idx] = "Locked";
        optionValues[idx++] = toString(uint(int256(locked[_tokenId].amount)) / 10**decimals);
        optionNames[idx] = "Ending";
        optionValues[idx++] = toString(locked[_tokenId].end);
        optionNames[idx] = "Vested Percentile";
        optionValues[idx++] = string(abi.encodePacked(toString(percentiles[_tokenId]), " %"));
        optionNames[idx] = "Credit Percentile";
        optionValues[idx++] = string(abi.encodePacked(toString(_percentile), " %"));
        optionNames[idx] = "Sponsor Supply";
        optionValues[idx++] = toString(erc20(token).balanceOf(valuepool) / 10**decimals);
        optionNames[idx] = "Attachments";
        optionValues[idx++] = string(abi.encodePacked("# ", toString(attachments[_tokenId])));
        optionNames[idx] = "Min Ticket Price";
        optionValues[idx++] = toString(minTicketPrice / 10**decimals);
        optionNames[idx] = "Ve Supply";
        optionValues[idx++] = toString(supply / 10**decimals);
        optionNames[idx] = "Min To Switch";
        optionValues[idx++] = toString(minToSwitch / 10**decimals);
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

    function balanceOfNFT(uint _tokenId) external view returns (uint) {
        if (ownership_change[_tokenId] == block.number) return 0;
        return _balanceOfNFT(_tokenId, block.timestamp);
    }

    function balanceOfNFTAt(uint _tokenId, uint _t) external view returns (uint) {
        return _balanceOfNFT(_tokenId, _t);
    }

    function balanceOfAtNFT(uint _tokenId, uint _block) external view returns (uint) {
        return _balanceOfAtNFT(_tokenId, _block);
    }

    /// @notice Measure voting power of `_tokenId` at block height `_block`
    /// @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
    /// @param _tokenId User's wallet NFT
    /// @param _block Block to calculate the voting power at
    /// @return Voting power
    function _balanceOfAtNFT(uint _tokenId, uint _block) internal view returns (uint) {
        // Copying and pasting totalSupply code because Vyper cannot pass by
        // reference yet
        assert(_block <= block.number);

        // Binary search
        uint _min = 0;
        uint _max = user_point_epoch[_tokenId];
        for (uint i = 0; i < 128; ++i) {
            // Will be always enough for 128-bit numbers
            if (_min >= _max) {
                break;
            }
            uint _mid = (_min + _max + 1) / 2;
            if (user_point_history[_tokenId][_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }

        Point memory upoint = user_point_history[_tokenId][_min];

        uint max_epoch = epoch;
        uint _epoch = _find_block_epoch(_block, max_epoch);
        Point memory point_0 = point_history[_epoch];
        uint d_block = 0;
        uint d_t = 0;
        if (_epoch < max_epoch) {
            Point memory point_1 = point_history[_epoch + 1];
            d_block = point_1.blk - point_0.blk;
            d_t = point_1.ts - point_0.ts;
        } else {
            d_block = block.number - point_0.blk;
            d_t = block.timestamp - point_0.ts;
        }
        uint block_time = point_0.ts;
        if (d_block != 0) {
            block_time += (d_t * (_block - point_0.blk)) / d_block;
        }

        upoint.bias -= upoint.slope * int128(int256(block_time - upoint.ts));
        if (upoint.bias >= 0) {
            return uint(uint128(upoint.bias));
        } else {
            return 0;
        }
    }

    /// @notice Calculate total voting power at some point in the past
    /// @param point The point (bias/slope) to start search from
    /// @param t Time to calculate the total voting power at
    /// @return Total voting power at that time
    function _supply_at(Point memory point, uint t) internal view returns (uint) {
        Point memory last_point = point;
        uint t_i = (last_point.ts / WEEK) * WEEK;
        for (uint i = 0; i < 255; ++i) {
            t_i += WEEK;
            int128 d_slope = 0;
            if (t_i > t) {
                t_i = t;
            } else {
                d_slope = slope_changes[t_i];
            }
            last_point.bias -= last_point.slope * int128(int256(t_i - last_point.ts));
            if (t_i == t) {
                break;
            }
            last_point.slope += d_slope;
            last_point.ts = t_i;
        }

        if (last_point.bias < 0) {
            last_point.bias = 0;
        }
        return uint(uint128(last_point.bias));
    }

    /// @notice Calculate total voting power
    /// @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
    /// @return Total voting power
    function totalSupplyAtT(uint t) external view returns (uint) {
        if (t == 0) t = block.timestamp;
        uint _epoch = epoch;
        Point memory last_point = point_history[_epoch];
        return _supply_at(last_point, t);
        // return IValuePool(IContract(contractAddress).valuepoolHelper2()).supply_at(last_point, t);
    }

    // function totalSupply() external view returns (uint) {
    //     return totalSupplyAtT(block.timestamp);
    // }

    // /// @notice Calculate total voting power at some point in the past
    // /// @param _block Block to calculate the total voting power at
    // /// @return Total voting power at `_block`
    // function totalSupplyAt(uint _block) external view returns (uint) {
    //     assert(_block <= block.number);
    //     uint _epoch = epoch;
    //     uint target_epoch = _find_block_epoch(_block, _epoch);

    //     Point memory point = point_history[target_epoch];
    //     uint dt = 0;
    //     if (target_epoch < _epoch) {
    //         Point memory point_next = point_history[target_epoch + 1];
    //         if (point.blk != point_next.blk) {
    //             dt = ((_block - point.blk) * (point_next.ts - point.ts)) / (point_next.blk - point.blk);
    //         }
    //     } else {
    //         if (point.blk != block.number) {
    //             dt = ((_block - point.blk) * (block.timestamp - point.ts)) / (block.number - point.blk);
    //         }
    //     }
    //     // Now dt contains info on how far are we beyond point
    //     return _supply_at(point, point.ts + dt);
    //     // return IValuePool(IContract(contractAddress).valuepoolHelper2()).supply_at(point, point.ts + dt);
    // }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || valuepoolHelper == msg.sender);
        contractAddress = _contractAddress;
        valuepoolHelper = IContract(_contractAddress).valuepoolHelper();
        voters[IContract(_contractAddress).valuepoolVoter()] = true;
    }

    // function _valuepoolHelper() internal view returns(address) {
    //     return IContract(contractAddress).valuepoolHelper();
    // }

    function _burn(uint _tokenId) internal {
        require(_isApprovedOrOwner(msg.sender, _tokenId));

        // address owner = ownerOf(_tokenId);

        // Clear approval
        approve(address(0), _tokenId);
        // Remove token
        _removeTokenFrom(msg.sender, _tokenId);
        // IValuePool(_valuepoolHelper()).emitTransfer(owner, address(0), _tokenId);
    }
}

contract veFactory {
    // address last_ve;
//     address contractAddress;
//     constructor(address _contractAddress) {
//         contractAddress = _contractAddress;
//     }

    function createVe(
        address token_addr,
        address _valuepool,
        bool _riskpool
    ) external {
        // last_ve = address(
        new Ve(
            token_addr,
            _valuepool,
            _riskpool
        // )
        );
        // IValuePool(_valuepool).updateVa(last_ve);
    }
}

contract ValuepoolFactory {
    address contractAddress;

    constructor(address _contractAddress) {
        contractAddress = _contractAddress;
    }

    function createValuePool(
        address _token,
        address _devaddr,
        address _marketPlace,
        bool _onePersonOneVote,
        bool riskpool
    ) external {
        address valuepoolHelper = IContract(contractAddress).valuepoolHelper();
        address last_valuepool = address(new Valuepool(
            _token,
            _devaddr,
            valuepoolHelper,
            contractAddress
        ));
        IValuePool(valuepoolHelper).updateVava(
            last_valuepool, 
            _marketPlace,
            _token,
            _devaddr,
            riskpool,
            _onePersonOneVote
        );
    }
}
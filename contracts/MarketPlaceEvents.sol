// /**
//  *Submitted for verification at BscScan.com on 2021-09-30
// */

// // File: @openzeppelin/contracts/utils/Context.sol

// // SPDX-License-Identifier: MIT

// pragma solidity 0.8.17;
// pragma abicoder v2;

// // import "./NFTicket.sol";
// import "./Library.sol";
// // File: contracts/ERC721NFTMarketV1.sol

// contract MarketPlaceEvents {

//     address marketPlaceCollections;
//     address nfticketHelper;
//     address trustBounty;
//     address marketPlaceOrders;
//     address marketPlaceTrades;
//     address marketPlaceHelper;
//     address marketPlaceHelper2;
//     address paywallNote;
//     address marketPlaceSubscriptionOrders;
//     address marketPlaceSubscriptionTrades;
//     mapping(uint => bool) public attachedBounties;

//     // Collection is closed for trading and new listings
//     event CollectionClose(uint256 indexed collection);

//     // New collection is added
//     event CollectionNew(
//         uint256 indexed collectionId,
//         address collection,
//         address baseToken,
//         uint256 referrerFee,
//         uint256 badgeId,
//         uint256 tradingFee,
//         uint256 recurringBounty,
//         uint256 minBounty,
//         uint256 userMinBounty,
//         bool requestUserRegistration,
//         bool requestPartnerRegistration
//     );

//     event CollectionUpdateIdentity(
//         uint256 indexed collectionId,
//         string requiredIndentity,
//         string valueName,
//         bool onlyTrustWorthyAuditors,
//         bool uniqueAccounts,
//         bool isUserIdentity,
//         COLOR minIDBadgeColor
//     );
    
//     // Existing collection is updated
//     event CollectionUpdate(
//         uint256 indexed collectionId,
//         address indexed collection,
//         uint256 referrerFee,
//         uint256 badgeId,
//         uint256 tradingFee,
//         uint256 recurringBounty,
//         uint256 minBounty,
//         uint256 userMinBounty,
//         bool requestUserRegistration,
//         bool requestPartnerRegistration
//     );

//     event UpdateOptions(
//         uint _collectionId,
//         string _tokenId,
//         uint[] _mins,
//         uint[] _maxs,
//         uint[] _unitPrices,
//         string[] _categories,
//         string[] _elements,
//         string[] _traitTypes,
//         string[] _values,
//         string[] _currencies
//     );
//     event Voted(uint indexed collectionId, string tokenId, uint likes, uint disLikes, bool like);

//     // Ask order is cancelled
//     event AskCancel(uint256 indexed collection, uint256 indexed tokenId);
    
//     event PaywallAskCancel(uint256 indexed collection, uint256 indexed tokenId);
    
//     event UserRegistration(uint256 indexed collectionId, uint256 userCollectionId, bool active);

//     event PartnerRegistrationRequest(uint256 indexed collectionId, uint256 partnerCollectionId, uint256 identityProofId);

//     event UpdateAnnouncement(uint256 indexed collectionId, uint256 position, bool active, string anouncementTitle, string anouncementContent);
//     // Ask order is created
//     event AskNew(
//         uint indexed _collectionId,
//         string _tokenId,
//         uint _askPrice,
//         uint _bidDuration,
//         int _minBidIncrementPercentage,
//         bool _transferrable,
//         uint _rsrcTokenId,
//         uint _maxSupply,
//         uint _dropinTimer,
//         address _tFIAT,
//         address _ve,
//         DIRECTION _direction
//     );

//     event AskInfo(
//         uint indexed collectionId,
//         string _tokenId,
//         string description,
//         uint[] AB,
//         uint ABStart,
//         uint ABPeriod,
//         string[5] images,
//         string[] behindPaywall,
//         address workspace,
//         string[] countries,
//         string[] cities,
//         string[] products
//     );

//     event PaywallAskNew(
//         uint indexed _collectionId,
//         string _tokenId,
//         uint _askPrice,
//         uint _bidDuration,
//         int _minBidIncrementPercentage,
//         bool _transferrable,
//         uint _rsrcTokenId,
//         uint _maxSupply,
//         uint _dropinTimer,
//         address _tFIAT,
//         address _ve,
//         DIRECTION _direction
//     );
//     // Ask order is updated
//     event AskUpdate(
//         string _tokenId,
//         address _seller,
//         uint256 indexed _collectionId,
//         uint256 _newPrice,
//         uint256 _bidDuration,
//         int256 _minBidIncrementPercentage,
//         bool _transferrable,
//         uint256 _rsrcTokenId,
//         uint256 _maxSupply,
//         uint _dropinTimer
//     );

//     event PaywallAskUpdate(
//         string _tokenId,
//         address _seller,
//         uint256 indexed _collectionId,
//         uint256 _newPrice,
//         uint256 _bidDuration,
//         int256 _minBidIncrementPercentage,
//         bool _transferrable,
//         uint256 _rsrcTokenId,
//         uint256 _maxSupply,
//         uint _dropinTimer
//     );
    
//     event AskUpdateDiscount(
//         uint _collectionId, 
//         string _tokenId, 
//         Status _discountStatus,
//         uint _discountStart,
//         bool _cashNotCredit,
//         bool _checkIdentityCode,
//         uint[6] _discountNumbers,
//         uint[6] _discountCost
//     );

//     event PaywallAskUpdateDiscount(
//         uint _collectionId, 
//         string _tokenId, 
//         Status _discountStatus,
//         uint _discountStart,
//         bool _cashNotCredit,
//         bool _checkIdentityCode,
//         uint[] _discountNumbers,
//         uint[] _discountCost
//     );

//     event AskUpdateCashback(
//         uint _collectionId, 
//         string _tokenId, 
//         Status _cashbackStatus,
//         uint _cashbackStart,
//         bool _cashNotCredit,
//         uint[6] _cashbackNumbers,
//         uint[6] _cashbackCost
//     );

//     event PaywallAskUpdateCashback(
//         uint _collectionId, 
//         string _tokenId, 
//         Status _cashbackStatus,
//         uint _cashbackStart,
//         bool _cashNotCredit,
//         bool _checkIdentityCode,
//         uint[] _cashbackNumbers,
//         uint[] _cashbackCost
//     );

//     event AskUpdateIdentity(
//         uint _collectionId, 
//         string _tokenId,
//         string _requiredIndentity,
//         string _valueName,
//         bool _onlyTrustWorthyAuditors,
//         bool _uniqueAccounts,
//         COLOR _minIDBadgeColor
//     );

//     event PaywallAskUpdateIdentity(
//         uint _collectionId, 
//         string _tokenId,
//         string _requiredIndentity,
//         string _valueName,
//         bool _onlyTrustWorthyAuditors,
//         bool _uniqueAccounts,
//         COLOR _minIDBadgeColor
//     );

//     event AddReferral(uint indexed _referrerCollectionId, uint _collectionId, string _tokenId, uint _bountyId, uint _identityProofId);
    
//     event PaywallAddReferral(uint indexed _referrerCollectionId, uint _collectionId, string _tokenId, uint _bountyId);

//     event CloseReferral(uint indexed _referrerCollectionId, uint _collectionId, string[] tokenIds, bool deactivate);
    
//     event PaywallCloseReferral(uint indexed _referrerCollectionId, uint _collectionId, string _tokenId);

//     // Recover NFT tokens sent by accident
//     event NonFungibleTokenRecovery(address indexed token, uint256 indexed tokenId);

//     // Pending revenue is claimed
//     event RevenueClaim(address indexed claimer, uint256 amount);

//     // Recover ERC20 tokens sent by accident
//     event TokenRecovery(address indexed token, uint256 amount);

//     // Ask order is matched by a trade
//     event Trade(
//         uint indexed collectionId,
//         string tokenId,
//         address indexed seller,
//         address buyer,
//         uint256 askPrice,
//         uint256 netPrice,
//         uint256 nfTicketId
//     );

//     event PaywallTrade(
//         uint indexed collectionId,
//         string tokenId,
//         address indexed seller,
//         address buyer,
//         uint256 askPrice,
//         uint256 netPrice
//     );

//     event UpdateScubscriptionTiers(uint _collectionId, uint[] _times, uint[] _prices);
    
//     event UpdateSubscriptionInfo(uint _collectionId, uint _freeTrialPeriod, uint _period);
    
//     event UpdateCollection(
//         uint indexed collectionId,
//         string name,
//         string desc,
//         string large,
//         string small,
//         string avatar,
//         string[] contactChannels,
//         string[] contacts,
//         string[] workspaces,
//         string[] countries,
//         string[] cities,
//         string[] products
//     );
    
//     event CreateReview(
//         uint indexed collectionId, 
//         string tokenId, 
//         uint userTokenId, 
//         uint votingPower, 
//         uint reviewTime, 
//         bool good,
//         string review,
//         address reviewer
//     );


//     function setContracts(
//         address _nfticketHelper,
//         address _marketPlaceCollections,
//         address _marketPlaceOrders,
//         address _marketPlaceTrades,
//         address _marketPlaceHelper,
//         address _marketPlaceHelper2,
//         address _paywallNote,
//         address _trustBounty,
//         address _marketPlaceSubscriptionOrders,
//         address _marketPlaceSubscriptionTrades
//     ) external {
//         // require(marketPlaceCollections == address(0x0) || IAuth(marketPlaceCollections).isAdmin(msg.sender));
//         nfticketHelper = _nfticketHelper;
//         trustBounty = _trustBounty;
//         marketPlaceCollections = _marketPlaceCollections;
//         marketPlaceOrders = _marketPlaceOrders;
//         marketPlaceTrades = _marketPlaceTrades;
//         marketPlaceHelper = _marketPlaceHelper;
//         marketPlaceHelper2 = _marketPlaceHelper2;
//         paywallNote = _paywallNote;
//         marketPlaceSubscriptionOrders = _marketPlaceSubscriptionOrders;
//         marketPlaceSubscriptionTrades = _marketPlaceSubscriptionTrades;
//     }

//     function emitCollectionNew(
//         uint256 _collectionId,
//         address _collection,
//         address _baseToken,
//         uint256 _referrerFee,
//         uint256 _badgeId,
//         uint256 tradingFee,
//         uint256 _recurringBounty,
//         uint256 _minBounty,
//         uint256 _userMinBounty,
//         bool _requestUserRegistration,
//         bool _requestPartnerRegistration
//     ) external {
//         // require(msg.sender == marketPlaceCollections);

//         emit CollectionNew(
//             _collectionId,
//             _collection, 
//             _baseToken,
//             _referrerFee,
//             _badgeId,
//             tradingFee,
//             _recurringBounty,
//             _minBounty,
//             _userMinBounty,
//             _requestUserRegistration,
//             _requestPartnerRegistration
//         );
//     }

//     function emitUserRegistration(uint _collectionId, uint _userCollectionId, uint _identityProofId, uint _bountyId, bool active) external  {
//         Collection memory _userCollection = IMarketPlace(marketPlaceCollections).getCollection(_userCollectionId);
//         Collection memory _collection = IMarketPlace(marketPlaceCollections).getCollection(_collectionId);
//         require(_userCollection.owner == msg.sender || msg.sender == _collection.owner);
//         if (_collection.requestUserRegistration && msg.sender != _collection.owner) {
//             active = false;
//         }
//         if (msg.sender != _collection.owner) {
//             (address owner,address _token,,address claimableBy,,,,,,) = ITrustBounty(trustBounty).bountyInfo(_bountyId);
//             uint _limit = ITrustBounty(trustBounty).getBalance(_bountyId);
//             if (_collection.userMinBounty > 0) {
//                 require(
//                     owner == msg.sender && 
//                     _collection.baseToken == _token && 
//                     claimableBy == address(0x0) &&
//                     _collection.userMinBounty <= _limit &&
//                     ITrustBounty(trustBounty).attachements(_bountyId) == 0
//                 );
//                 if (_bountyId > 0 && !attachedBounties[_bountyId]) {
//                     ITrustBounty(trustBounty).attach(_bountyId);
//                 } else if (_bountyId == 0 && attachedBounties[_bountyId]) {
//                     ITrustBounty(trustBounty).detach(_bountyId);
//                 }
//                 attachedBounties[_bountyId] = _bountyId > 0;
//             }
//             IMarketPlace(marketPlaceHelper2).checkUserIdentityProof(_collectionId, _identityProofId, msg.sender);
//         }
//         emit UserRegistration(_collectionId, _userCollectionId, active);
//     }

//     function emitPartnerRegistrationRequest(uint _collectionId, uint _partnerCollectionId, uint _identityProofId) external  {
//         Collection memory _collection = IMarketPlace(marketPlaceCollections).getCollection(_partnerCollectionId);
//         // require(_collection.owner == msg.sender);
//         IMarketPlace(marketPlaceHelper2).checkPartnerIdentityProof(_collectionId, _identityProofId, msg.sender);
//         emit PartnerRegistrationRequest(_collectionId, _partnerCollectionId, _identityProofId);
//     }
    
//     function emitCollectionUpdateIdentity(
//         uint _collectionId,
//         string memory _requiredIndentity,
//         string memory _valueName,
//         bool _onlyTrustWorthyAuditors,
//         bool _uniqueAccounts,
//         bool _isUserIdentity,
//         COLOR _minIDBadgeColor
//     ) external {
//         // require(msg.sender == marketPlaceCollections);
//         emit CollectionUpdateIdentity(
//             _collectionId,
//             _requiredIndentity,
//             _valueName,
//             _onlyTrustWorthyAuditors,
//             _uniqueAccounts,
//             _isUserIdentity,
//             _minIDBadgeColor
//         );
//     }

//     function emitCollectionUpdate(
//         uint256 _collectionId,
//         address _collection,
//         uint256 _referrerFee,
//         uint256 _badgeId,
//         uint256 tradingFee,
//         uint256 _recurringBounty,
//         uint256 _minBounty,
//         uint256 _userMinBounty,
//         bool _requestUserRegistration,
//         bool _requestPartnerRegistration
//     ) external {
//         // require(msg.sender == marketPlaceCollections);

//         emit CollectionUpdate(
//             _collectionId, 
//             _collection, 
//             _referrerFee,
//             _badgeId,
//             tradingFee,
//             _recurringBounty,
//             _minBounty,
//             _userMinBounty,
//             _requestUserRegistration,
//             _requestPartnerRegistration
//         );
//     }

//     function emitCollectionClose(uint _collectionId) external {
//         // require(msg.sender == marketPlaceCollections);

//         emit CollectionClose(_collectionId);
//     }

//     function emitAskCancel(uint256 collection, uint256 tokenId) external {
//         // require(msg.sender == marketPlaceOrders);

//         emit AskCancel(collection, tokenId);
//     }

//     function emitPaywallAskCancel(uint256 collection, uint256 tokenId) external {
//         // require(msg.sender == marketPlaceSubscriptionOrders);

//         emit PaywallAskCancel(collection, tokenId);
//     }

//     function emitAskNew(
//         uint256 collection, 
//         string memory tokenId, 
//         uint256 askPrice, 
//         uint _bidDuration,
//         int _minBidIncrementPercentage,
//         bool _transferrable,
//         uint _rsrcTokenId,
//         uint _maxSupply,
//         uint _dropinTimer,
//         address _tFIAT,
//         address _ve,
//         DIRECTION _direction
//     ) external {
//         // require(msg.sender == marketPlaceOrders);

//         emit AskNew(
//             collection, 
//             tokenId, 
//             askPrice, 
//             _bidDuration,
//             _minBidIncrementPercentage,
//             _transferrable,
//             _rsrcTokenId,
//             _maxSupply,
//             _dropinTimer,
//             _tFIAT,
//             _ve,
//             _direction
//         );
//     }

//     function emitPaywallAskNew(
//         uint256 collection, 
//         string memory tokenId, 
//         uint256 askPrice, 
//         uint _bidDuration,
//         int _minBidIncrementPercentage,
//         bool _transferrable,
//         uint _rsrcTokenId,
//         uint _maxSupply,
//         uint _dropinTimer,
//         address _tFIAT,
//         address _ve,
//         DIRECTION _direction
//     ) external {
//         // require(msg.sender == marketPlaceOrders);

//         emit PaywallAskNew(
//             collection, 
//             tokenId, 
//             askPrice, 
//             _bidDuration,
//             _minBidIncrementPercentage,
//             _transferrable,
//             _rsrcTokenId,
//             _maxSupply,
//             _dropinTimer,
//             _tFIAT,
//             _ve,
//             _direction
//         );
//     }

//     function emitAskUpdate(
//         string memory _tokenId,
//         address _seller,
//         uint256 _collectionId,
//         uint256 _newPrice,
//         uint256 _bidDuration,
//         int256 _minBidIncrementPercentage,
//         bool _transferrable,
//         uint256 _rsrcTokenId,
//         uint256 _maxSupply,
//         uint _dropinTimer
//     ) external {
//         // require(msg.sender == marketPlaceOrders);
        
//         emit AskUpdate(
//             _tokenId, 
//             _seller,
//             _collectionId, 
//             _newPrice,
//             _bidDuration,
//             _minBidIncrementPercentage,
//             _transferrable,
//             _rsrcTokenId,
//             _maxSupply,
//             _dropinTimer
//         );
//     }

//     function emitPaywallAskUpdate(
//         string memory _tokenId,
//         address _seller,
//         uint256 _collectionId,
//         uint256 _newPrice,
//         uint256 _bidDuration,
//         int256 _minBidIncrementPercentage,
//         bool _transferrable,
//         uint256 _rsrcTokenId,
//         uint256 _maxSupply,
//         uint _dropinTimer
//     ) external {
//         // require(msg.sender == marketPlaceSubscriptionOrders);
        
//         emit PaywallAskUpdate(
//             _tokenId, 
//             _seller,
//             _collectionId, 
//             _newPrice,
//             _bidDuration,
//             _minBidIncrementPercentage,
//             _transferrable,
//             _rsrcTokenId,
//             _maxSupply,
//             _dropinTimer
//         );
//     }

//     function emitAskUpdateDiscount(
//         uint _collectionId, 
//         string memory _tokenId, 
//         Status _discountStatus,
//         uint _discountStart,
//         bool _cashNotCredit,
//         bool _checkIdentityCode,
//         uint[6] memory _discountNumbers,
//         uint[6] memory _discountCost   
//     ) external {
//         // require(msg.sender == marketPlaceOrders);
      
//         emit AskUpdateDiscount(
//             _collectionId, 
//             _tokenId, 
//             _discountStatus,
//             _discountStart,
//             _cashNotCredit,
//             _checkIdentityCode,
//             _discountNumbers,
//             _discountCost
//         );
//     }

//     function emitPaywallAskUpdateDiscount(
//         uint _collectionId, 
//         string memory _tokenId, 
//         Status _discountStatus,
//         uint _discountStart,
//         bool _cashNotCredit,
//         bool _checkIdentityCode,
//         uint[] memory _discountNumbers,
//         uint[] memory _discountCost   
//     ) external {
//         // require(msg.sender == marketPlaceSubscriptionOrders);
      
//         emit PaywallAskUpdateDiscount(
//             _collectionId, 
//             _tokenId, 
//             _discountStatus,
//             _discountStart,
//             _cashNotCredit,
//             _checkIdentityCode,
//             _discountNumbers,
//             _discountCost
//         );
//     }

//     function emitAskUpdateCashback(
//         uint _collectionId, 
//         string memory _tokenId, 
//         Status _cashbackStatus,
//         uint _cashbackStart,
//         bool _cashNotCredit,
//         uint[6] memory _cashbackNumbers,
//         uint[6] memory _cashbackCost   
//     ) external {
//         // require(msg.sender == marketPlaceOrders);
      
//         emit AskUpdateCashback(
//             _collectionId, 
//             _tokenId, 
//             _cashbackStatus,
//             _cashbackStart,
//             _cashNotCredit,
//             _cashbackNumbers,
//             _cashbackCost
//         );
//     }

//     function emitPaywallAskUpdateCashback(
//         uint _collectionId, 
//         string memory _tokenId, 
//         Status _cashbackStatus,
//         uint _cashbackStart,
//         bool _cashNotCredit,
//         bool _checkIdentityCode,
//         uint[] memory _cashbackNumbers,
//         uint[] memory _cashbackCost   
//     ) external {
//         // require(msg.sender == marketPlaceSubscriptionOrders);
      
//         emit PaywallAskUpdateCashback(
//             _collectionId, 
//             _tokenId, 
//             _cashbackStatus,
//             _cashbackStart,
//             _cashNotCredit,
//             _checkIdentityCode,
//             _cashbackNumbers,
//             _cashbackCost
//         );
//     }

//     function emitAskUpdateIdentity(
//         uint _collectionId, 
//         string memory _tokenId,
//         string memory _requiredIndentity,
//         string memory _valueName,
//         bool _onlyTrustWorthyAuditors,
//         bool _uniqueAccounts,
//         COLOR _minIDBadgeColor
//     ) external {
//         // require(msg.sender == marketPlaceOrders);

//         emit AskUpdateIdentity(
//             _collectionId,
//             _tokenId,
//             _requiredIndentity,
//             _valueName,
//             _onlyTrustWorthyAuditors,
//             _uniqueAccounts,
//             _minIDBadgeColor
//         );
//     }

//     function emitPaywallAskUpdateIdentity(
//         uint _collectionId, 
//         string memory _tokenId,
//         string memory _requiredIndentity,
//         string memory _valueName,
//         bool _onlyTrustWorthyAuditors,
//         bool _uniqueAccounts,
//         COLOR _minIDBadgeColor
//     ) external {
//         // require(msg.sender == marketPlaceSubscriptionOrders);

//         emit PaywallAskUpdateIdentity(
//             _collectionId,
//             _tokenId,
//             _requiredIndentity,
//             _valueName,
//             _onlyTrustWorthyAuditors,
//             _uniqueAccounts,
//             _minIDBadgeColor
//         );
//     }
    
//     function emitRevenueClaim(address _user, uint revenueToClaim) external {
//         // require(msg.sender == marketPlaceTrades);

//         emit RevenueClaim(_user, revenueToClaim);
//     }

//     function emitTrade(
//         uint _collectionId, 
//         string memory _tokenId, 
//         address _seller, 
//         address _user, 
//         uint _price, 
//         uint _netPrice,
//         uint _nfTicketId
//     ) external {
//         // require(msg.sender == marketPlaceHelper);

//         emit Trade(_collectionId, _tokenId, _seller, _user, _price, _netPrice, _nfTicketId);
//     }

//     function emitPaywallTrade(
//         uint _collectionId, 
//         string memory _tokenId, 
//         address _seller, 
//         address _user, 
//         uint _price, 
//         uint _netPrice
//     ) external {
//         // require(msg.sender == marketPlaceSubscriptionTrades);

//         emit PaywallTrade(_collectionId, _tokenId, _seller, _user, _price, _netPrice);
//     }

//     function emitAddReferral(uint _referrerCollectionId, uint _collectionId, string memory _tokenId, uint _bountyId, uint _identityProofId) external {
//         // require(msg.sender == marketPlaceOrders);
//         if (_bountyId > 0 && !attachedBounties[_bountyId]) {
//             require(ITrustBounty(trustBounty).attachements(_bountyId) == 0);
//             ITrustBounty(trustBounty).attach(_bountyId);
//         }
//         attachedBounties[_bountyId] = _bountyId > 0;
//         emit AddReferral(_referrerCollectionId, _collectionId, _tokenId, _bountyId, _identityProofId);
//     }

//     function emitPaywallAddReferral(uint _referrerCollectionId, uint _collectionId, string memory _tokenId, uint _bountyId) external {
//         // require(msg.sender == marketPlaceSubscriptionOrders);

//         emit PaywallAddReferral(_referrerCollectionId, _collectionId, _tokenId, _bountyId);
//     }

//     function emitCloseReferral(uint _referrerCollectionId, uint _collectionId, uint _bountyId, address _user, string[] memory tokenIds, bool deactivate) external {
//         // require(msg.sender == marketPlaceOrders);
//         if (attachedBounties[_bountyId]) {
//             Collection memory _collection = IMarketPlace(marketPlaceCollections).getCollection(_collectionId);
//             (address owner,address _token,,address claimableBy,,,,,,) = ITrustBounty(trustBounty).bountyInfo(_bountyId);
//             require(owner == _user && _collection.baseToken == _token && claimableBy == address(0x0));
//             ITrustBounty(trustBounty).detach(_bountyId);
//         }
//         attachedBounties[_bountyId] = false;
//         emit CloseReferral(_referrerCollectionId, _collectionId, tokenIds, deactivate);
//     }

//     function emitPaywallCloseReferral(uint _referrerCollectionId, uint _collectionId, string memory _tokenId) external {
//         // require(msg.sender == marketPlaceSubscriptionOrders);

//         emit PaywallCloseReferral(_referrerCollectionId, _collectionId, _tokenId);
//     }

//     function emitUpdateScubscriptionTiers(
//         uint _collectionId, 
//         uint[] memory _times, 
//         uint[] memory _prices
//     ) external {
//         // require(IPaywall(paywallNote).isGauge(msg.sender));

//         emit UpdateScubscriptionTiers(_collectionId, _times, _prices);   
//     }

//     function emitUpdateSubscriptionInfo(
//         uint _collectionId, 
//         uint _freeTrialPeriod, 
//         uint _period
//     ) external {
//         // require(IPaywall(paywallNote).isGauge(msg.sender));

//         emit UpdateSubscriptionInfo(_collectionId, _freeTrialPeriod, _period);   
//     }
    
//     function emitUpdateOptions(
//         uint _collectionId,
//         string memory _tokenId,
//         uint[] memory _mins,
//         uint[] memory _maxs,
//         uint[] memory _unitPrices,
//         string[] memory _categories,
//         string[] memory _elements,
//         string[] memory _traitTypes,
//         string[] memory _values,
//         string[] memory _currencies) external {
//         // require(msg.sender == marketPlaceHelper);
//             emit UpdateOptions(
//                 _collectionId,
//                 _tokenId,
//                 _mins,
//                 _maxs,
//                 _unitPrices,
//                 _categories,
//                 _elements,
//                 _traitTypes,
//                 _values,
//                 _currencies
//             );
//         }

//         function emitUpdateCollection(
//             uint collectionId,
//             string memory name,
//             string memory description,
//             string memory large,
//             string memory small,
//             string memory avatar,
//             string[] memory contactChannels,
//             string[] memory contacts,
//             string[] memory workspaces,
//             string[] memory countries,
//             string[] memory cities,
//             string[] memory products
//         ) external {
//             // require(marketPlaceCollections == msg.sender);
//             emit UpdateCollection(
//                 collectionId,
//                 name,
//                 description,
//                 large,
//                 small,
//                 avatar,
//                 contactChannels,
//                 contacts,
//                 workspaces,
//                 countries,
//                 cities,
//                 products
//             );
//         }

//         function emitAskInfo(
//             uint collectionId,
//             string memory tokenId,
//             string memory description,
//             uint[] memory AB,
//             uint ABStart,
//             uint ABPeriod, // currPriceIdx = Math.roundDown((block.timestamp - ABStart) / ABPeriod)
//             string[5] memory images,
//             string[] memory behindPaywall,
//             address workspace,
//             string[] memory countries,
//             string[] memory cities,
//             string[] memory products
//         ) external {
//             // require(marketPlaceCollections == msg.sender);
//             // require(products.length <= IMarketPlace(marketPlaceCollections).maximumArrayLength());
//             INFTicket(nfticketHelper).updateTags(collectionId, tokenId, products);
//             emit AskInfo(
//                 collectionId,
//                 tokenId,
//                 description,
//                 AB,
//                 ABStart,
//                 ABPeriod,
//                 images,
//                 behindPaywall,
//                 workspace,
//                 countries,
//                 cities,
//                 products
//             );
//         }

//         function emitReview(
//             uint collectionId,
//             string memory tokenId,
//             uint userTokenId,
//             uint votingPower,
//             bool good,
//             string memory review,
//             address reviewer
//         ) external {
//             // require(marketPlaceCollections == msg.sender);
//             emit CreateReview(
//                 collectionId,
//                 tokenId,
//                 userTokenId,
//                 votingPower,
//                 block.timestamp,
//                 good,
//                 review, 
//                 reviewer
//             );
//         }

//         function emitUpdateAnnouncement(
//             uint position,
//             bool active,
//             string memory anouncementTitle,
//             string memory anouncementContent
//         ) external {
//             uint collectionId = IMarketPlace(marketPlaceCollections).addressToCollectionId(msg.sender);
//             emit UpdateAnnouncement(collectionId, position, active, anouncementTitle, anouncementContent);
//         }

//         function emitVoted(
//             uint collectionId, 
//             string memory _tokenId, 
//             uint likes, 
//             uint dislikes, 
//             bool like
//         ) external {
//             // require(marketPlaceHelper2 == msg.sender);
//             emit Voted(collectionId, _tokenId, likes, dislikes, like);
//         }
// }
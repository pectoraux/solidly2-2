// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;
// pragma experimental ABIEncoderV2;

// import './Library.sol';

// // File: contracts/ERC721NFTMarketV1.sol

// contract NFTMarketPlaceOrders {
//     using EnumerableSet for EnumerableSet.AddressSet;
//     using EnumerableSet for EnumerableSet.UintSet;

//     using SafeERC20 for IERC20;

//     EnumerableSet.AddressSet private _dtokenSet;
//     EnumerableSet.AddressSet private _veTokenSet;

//     struct Referral {
//         uint collectionId;
//         uint referrerFee;
//         uint bountyId;
//     }
//     // referee => videoId => Referral
//     mapping(uint => mapping(address => uint)) internal recurringBountyBalance;
//     mapping(uint => mapping(uint => Referral)) public _referrals; // NFTAsk details (price + seller address) for a given collection and a tokenId
//     mapping(uint => mapping(string => NFTAsk)) public _askDetails; // NFTAsk details (price + seller address) for a given collection and a tokenId
//     mapping(uint => mapping(uint => NFTAsk)) public _loans; // NFTAsk details (price + seller address) for a given collection and a tokenId
//     mapping(uint => mapping(address => EnumerableSet.UintSet)) private _askTokenIds; // Set of tokenIds for a collection
//     mapping(uint => EnumerableSet.UintSet) private _loanTokenIds; // Set of tokenIds for a collection
//     mapping(uint => mapping(address => EnumerableSet.UintSet)) private _tokenIdsOfSellerForCollection;
//     mapping(uint => mapping(uint => uint)) public backings;
//     mapping(address => bool) public unAuthorizedContracts;
//     mapping(address => mapping(string => uint)) public paymentCredits;
//     mapping(uint => mapping(address => uint)) public burnTokenForCredit;
//     mapping(uint => mapping(string => bool)) public isTransferrable;

//     // The minimum amount of time left in an auction after a new bid is created
//     address public marketCollections;
//     address private marketTrades;
//     address private badgeNft;
//     address private trustBounty;
//     mapping(address => int256) internal weights;
//     mapping(string => address[]) internal poolVote;
//     mapping(string => mapping(string => int)) internal votes;

//     // NFTAsk order is cancelled
//     event AskCancel(address indexed collection, address indexed seller, uint256 indexed tokenId);

//     // NFTAsk order is created
//     event AskNew(address indexed collection, address indexed seller, uint256 indexed tokenId, uint256 askPrice);

//     // NFTAsk order is updated
//     event AskUpdate(address indexed collection, address indexed seller, uint256 indexed tokenId, uint256 askPrice);

//     event TokenRecovery(address indexed token, uint256 amount);

//     event UpdateBurnTokenForCredit(address indexed Collection, address token, uint256 discountNumber);

//     /**
//      * @notice Constructor
//      * @param _marketCollections: address of the admin
//      * @param _badgeNft: address of the admin
//      */
//     constructor(
//         address _marketCollections,
//         address _trustBounty,
//         address _badgeNft
//     ) {
//         badgeNft = _badgeNft;
//         trustBounty = _trustBounty;
//         marketCollections = _marketCollections;
//     }

//     // simple re-entrancy check
//     uint internal _unlocked = 1;
//     modifier lock() {
//         require(_unlocked == 1);
//         _unlocked = 2;
//         _;
//         _unlocked = 1;
//     }

//     modifier onlyAdmin() {
//         require(IAuth(marketCollections).isAdmin(msg.sender), "Only dev");
//         _;
//     }

//     function setMarketTrades(address _marketTrades) external {
//         if(marketTrades == address(0x0)) {
//             marketTrades = _marketTrades;
//         }
//     }

//     function updatePaymentCredits(address _user, uint _collectionId, uint _tokenId) external {
//         require(marketTrades == msg.sender);
//         paymentCredits[_user][string(abi.encodePacked(_collectionId, _tokenId))] += 
//         paymentCredits[_user][string(abi.encodePacked(_collectionId, uint(0)))];
//         paymentCredits[_user][string(abi.encodePacked(_collectionId, uint(0)))] = 0;
//     }

//     function incrementPaymentCredits(address _user, uint _collectionId, uint _tokenId, uint _price) external {
//         require(marketTrades == msg.sender);
//         paymentCredits[_user][string(abi.encodePacked(_collectionId, _tokenId))] += _price;
//     }

//     function decrementPaymentCredits(address _user, uint _collectionId, uint _tokenId, uint _price) external {
//         require(marketTrades == msg.sender);
//         paymentCredits[_user][string(abi.encodePacked(_collectionId, _tokenId))] -= _price;
//     }

//     function updateAfterSale(
//         uint _collectionId,
//         uint _tokenId,
//         uint _price, 
//         uint _bidDuration, 
//         uint _firstBidTime,
//         address _collection,
//         address _lastBidder
//     ) external {
//         require(marketTrades == msg.sender);
//         string memory ve_tokenId = string(abi.encodePacked(_collection, _tokenId));
//         _askDetails[_collectionId][ve_tokenId].price = _price;
//         _askDetails[_collectionId][ve_tokenId].bidDuration = _bidDuration;
//         _askDetails[_collectionId][ve_tokenId].firstBidTime = _firstBidTime;
//         _askDetails[_collectionId][ve_tokenId].lastBidder = _lastBidder;
//     }

//     function updateBurnTokenForCredit(
//         address _token,
//         uint256 _discountNumber
//     ) external {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         burnTokenForCredit[_collectionId][_token] = _discountNumber;

//         emit UpdateBurnTokenForCredit(msg.sender, _token, _discountNumber);
//     }

//     /**
//      * @notice Create ask order
//      * @param _collection: contract address of the NFT
//      * @param _tokenId: tokenId of the NFT
//      * @param _askPrice: price for listing (in wei)
//      */
//     function createAskOrder(
//         address _collection,
//         address _tFIAT,
//         address _ve,
//         uint256 _tokenId,
//         uint256 _askPrice,
//         uint256 _bidDuration,
//         uint256 _dropinTimer,
//         int256 _minBidIncrementPercentage,
//         uint256 _rsrcTokenId,
//         bool _usetFIAT,
//         bool _transferrable,
//         DIRECTION _direction
//     ) external lock {
//         _checkRequirements(
//             _collection, _ve, _tFIAT, _dropinTimer, _askPrice, _tokenId, _rsrcTokenId
//         );
//         _addOrder(
//             _askPrice,
//             _tokenId,
//             _bidDuration,
//             _minBidIncrementPercentage,
//             _transferrable,
//             _usetFIAT,
//             _rsrcTokenId,
//             _dropinTimer,
//             _collection,
//             _tFIAT,
//             _ve,
//             _direction
//         );
        
//         // Emit event
//         emit AskNew(_collection, msg.sender, _tokenId, _askPrice);
//     }

//     function _checkRequirements(
//         address _collection, 
//         address _ve, 
//         address _tFIAT, 
//         uint _dropinTimer,
//         uint _askPrice,
//         uint _tokenId,
//         uint _rsrcTokenId
//     ) internal {
//         if (_rsrcTokenId != 0) {
//             require(IERC721(badgeNft).ownerOf(_rsrcTokenId) == msg.sender);
//         }
//         // Verify price is not too low/high
//         require(_askPrice >= IMarketPlace(marketCollections).minimumAskPrice() &&
//         _askPrice <= IMarketPlace(marketCollections).maximumAskPrice(), "Order: Price not within range");
//         require(_dropinTimer <= IMarketPlace(marketCollections).maxDropinTimer(), "Too long before dropin");
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         (Status status,,,address tokenMinter,,,,,,,,address rsrcCollection,) = 
//         IMarketPlace(marketCollections)._collections(_collectionId);
//         // Verify collection is accepted
//         require(status == Status.Open, "Collection: Not for listing");
//         require(_veTokenSet.contains(_ve) && _dtokenSet.contains(_tFIAT));

//         // Verify token has restriction
//         require(_canTokenBeListed(_collection, _tokenId), "Order: tokenId not eligible");
//         // Transfer NFT to this contract
//         if (!tokenMinter) {
//             IERC721(_collection).safeTransferFrom(msg.sender, address(this), _tokenId);
//         } else {
//             Mintables(_collection)._safeMint(address(this), _tokenId);
//         }
//     }

//     function _addOrder(
//         uint _askPrice,
//         uint _tokenId,
//         uint _bidDuration,
//         int _minBidIncrementPercentage,
//         bool _transferrable,
//         bool _usetFIAT,
//         uint _rsrcTokenId,
//         uint _dropinTimer,
//         address _collection,
//         address _tFIAT,
//         address _ve,
//         DIRECTION _direction
//     ) internal {
//         // Adjust the information
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         _tokenIdsOfSellerForCollection[_collectionId][_collection].add(_tokenId);
//         string memory ve_tokenId = string(abi.encodePacked(_collection, _tokenId));
//         _askDetails[_collectionId][ve_tokenId] = NFTAsk({
//             seller: msg.sender, 
//             price: _askPrice,
//             lastBidder: address(0),
//             loanDuration: 0, 
//             bidDuration: _bidDuration,
//             firstBidTime: 0,
//             loanInterestRate: 0,
//             rsrcTokenId: _rsrcTokenId,
//             minBidIncrementPercentage: _minBidIncrementPercentage,
//             dropinTimer: block.timestamp + _dropinTimer,
//             priceReductor: PriceReductor({
//                 discountStatus: Status.Close,  
//                 discountStart: 0, 
//                 cashbackStatus: Status.Close,
//                 cashbackStart: 0,
//                 cashNotCredit: false,   
//                 checkIdentityCode: false,
//                 discountNumbers: Discount(0,0,0,0,0,0),
//                 discountCost: Discount(0,0,0,0,0,0),    
//                 cashbackNumbers: Discount(0,0,0,0,0,0),
//                 cashbackCost: Discount(0,0,0,0,0,0)
//             }),
//             identityProof: IdentityProof({
//                 minIDBadgeColor: COLOR.BLACK,
//                 requiredIndentity: "",
//                 valueName: "",
//                 onlyTrustWorthyAuditors: false,
//                 uniqueAccounts: false
//             }),
//             tokenInfo: TokenInfo({
//                 tFIAT: _tFIAT,
//                 ve: _ve,
//                 usetFIAT: _usetFIAT,
//                 direction: _direction,
//                 superLikes: 0,
//                 superDisLikes: 0
//             })
//         });
//         isTransferrable[_collectionId][ve_tokenId] = _transferrable;

//         // Emit event
//         emit AskNew(msg.sender, _tokenId, _askPrice);
//     }

//     /**
//      * @notice Cancel existing ask order
//      * @param _collection: contract address of the NFT
//      * @param _tokenId: tokenId of the NFT
//      */
//     function cancelAskOrder(address _collection, uint256 _tokenId) external {
//         // Verify the sender has listed it
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         string memory ve_tokenId = string(abi.encodePacked(_collection, _tokenId));
//         require(_tokenIdsOfSellerForCollection[_collectionId][_collection].contains(_tokenId), "Order: Token not listed");
//         require(_loanTokenIds[_collectionId][ve_tokenId] == 0, "Order: Token is being used as a collateral");
        
//         // Adjust the information
//         _tokenIdsOfSellerForCollection[_collectionId][_collection].remove(_tokenId);
//         delete _askDetails[_collectionId][ve_tokenId];
//         _askTokenIds[_collectionId][_collection].remove(ve_tokenId);
        
//         // Transfer the NFT back to the user
//         IERC721(_collection).transferFrom(address(this), address(msg.sender), _tokenId);

//         // Emit event
//         emit AskCancel(_collection, msg.sender, _tokenId);
//     }

//      function _reset(string memory ve_tokenId, string memory tokenId, uint _collectionId) internal {
//         address[] storage _poolVote = poolVote[ve_tokenId];
//         uint _poolVoteCnt = _poolVote.length;

//         for (uint i = 0; i < _poolVoteCnt; i ++) {
//             address _pool = _poolVote[i];
//             int256 _votes = votes[ve_tokenId][tokenId];

//             if (_votes != 0) {
//                 weights[_pool] -= _votes;
//                 votes[ve_tokenId][tokenId] -= _votes;
//                 if (_votes > 0) {
//                     _askDetails[_collectionId][tokenId].tokenInfo.superLikes -= uint256(_votes);
//                 } else {
//                     _askDetails[_collectionId][tokenId].tokenInfo.superDisLikes -= uint256(_votes);
//                 }
//             }
//         }
//         delete poolVote[ve_tokenId];
//     }
    
//     function vote(
//         address _pool, 
//         uint tokenId,
//         uint _tokenId, 
//         int256 _weights
//     ) internal {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_pool);
//         string memory collectionTokenId = string(abi.encodePacked(_pool, _tokenId));
//         address _ve = _askDetails[_collectionId][collectionTokenId].tokenInfo.ve;
//         require(ve(_ve).isApprovedOrOwner(msg.sender, _tokenId));
//         string memory ve_tokenId = string(abi.encodePacked(_ve, _tokenId));
//         _reset(ve_tokenId, collectionTokenId, _collectionId);
//         int256 _weight = int256(ve(_ve).balanceOfNFT(_tokenId));
//         int256 _totalVoteWeight = 0;
//         int256 _usedWeight = 0;
        
//         _totalVoteWeight += _weights > 0 ? _weights : -_weights;
//         if (_collectionId > 0) {
//             int256 _poolWeight = _weights * _weight / _totalVoteWeight;
//             require(votes[ve_tokenId][collectionTokenId] == 0);
//             require(_poolWeight != 0);

//             poolVote[ve_tokenId].push(_pool);

//             weights[_pool] += _poolWeight;
//             votes[ve_tokenId][collectionTokenId] += _poolWeight;
//             if (_poolWeight > 0) {
//                 _askDetails[_collectionId][collectionTokenId].tokenInfo.superLikes += uint(_poolWeight);
//             } else {
//                 _askDetails[_collectionId][collectionTokenId].tokenInfo.superDisLikes += uint(_poolWeight);
//                 _poolWeight = -_poolWeight;
//             }
//             _usedWeight += _poolWeight;
//         }
//         if (_usedWeight > 0) ve(_ve).voting(_tokenId);
//     }
    
//     function burnForCredit(
//         address _collection, 
//         address _token, 
//         uint256 _number,  // tokenId in case of NFTs and amount otherwise 
//         uint256 _applyToTokenId
//     ) external {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_collection);
//         uint discount = burnTokenForCredit[_collectionId][_token];
//         require(discount > 0);
//         bool _isNFT;
//         try IERC721(_token).supportsInterface(0x80ac58cd) {
//             _isNFT = true;
//         } catch {
//             _isNFT = false;
//         }
//         IERC20(_token).safeTransferFrom(msg.sender, address(this), _number);
//         uint credit = _isNFT ? discount * 1 / 10000 : discount * _number / 10000;
//         string memory contract_tokenId = string(
//             abi.encodePacked(_collectionId, _applyToTokenId
//         ));
//         paymentCredits[msg.sender][contract_tokenId] += credit;
//     }

//     function modifyAskOrderIdentity(
//         uint _tokenId,
//         bytes32 _requiredIndentity,
//         bytes32 _valueName,
//         bool _onlyTrustWorthyAuditors,
//         bool _uniqueAccounts,
//         COLOR _minIDBadgeColor
//     ) external {
//         // Verify the sender has listed it
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         require(_tokenIdsOfSellerForCollection[_collectionId].contains(_tokenId), "Order: Token not listed");
//         _askDetails[_collectionId][_tokenId].identityProof.requiredIndentity = _requiredIndentity;
//         _askDetails[_collectionId][_tokenId].identityProof.minIDBadgeColor = _minIDBadgeColor;
//         _askDetails[_collectionId][_tokenId].identityProof.valueName = _valueName;
//         _askDetails[_collectionId][_tokenId].identityProof.uniqueAccounts = _uniqueAccounts;
//         _askDetails[_collectionId][_tokenId].identityProof.onlyTrustWorthyAuditors = _onlyTrustWorthyAuditors;
//     }

//     function modifyAskOrderDiscountPriceReductors(
//         address _collection,
//         uint _tokenId,
//         Status _discountStatus,   
//         uint _discountStart,
//         bool _cashNotCredit,
//         bool _checkIdentityCode,
//         uint[] memory __discountNumbers,
//         uint[] memory __discountCost
//     ) external {
//         // Verify collection is accepted
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         (Status status,,,,,,,,,,,,) = IMarketPlace(marketCollections)._collections(_collectionId);
//         require(status == Status.Open);
//         // Verify the sender has listed it
//         require(_tokenIdsOfSellerForCollection[msg.sender][_collection].contains(_tokenId), "Order: Token not listed");
        
//         if (_discountStatus == Status.Open) {
//             require(__discountNumbers.length == 6 || __discountCost.length == 6, "Invalid discounts");
//             _askDetails[_collectionId][_tokenId].priceReductor.discountStatus = _discountStatus;
//                 _askDetails[_collectionId][_tokenId].priceReductor.discountStart = block.timestamp + _discountStart;
//                 _askDetails[_collectionId][_tokenId].priceReductor.cashNotCredit = _cashNotCredit;
//                 _askDetails[_collectionId][_tokenId].priceReductor.checkIdentityCode = _checkIdentityCode;
//             _askDetails[_collection][_tokenId].priceReductor.discountNumbers = Discount({
//                 cursor: __discountNumbers[0],
//                 size: __discountNumbers[1],
//                 perct: __discountNumbers[2],
//                 lowerThreshold: __discountNumbers[3],
//                 upperThreshold: __discountNumbers[4],
//                 limit: __discountNumbers[5]
//             });
//             _askDetails[_collection][_tokenId].priceReductor.discountCost = Discount({
//                 cursor: __discountCost[0],
//                 size: __discountCost[1],
//                 perct: __discountCost[2],
//                 lowerThreshold: __discountCost[3],
//                 upperThreshold: __discountCost[4],
//                 limit: __discountCost[5]
//             });
//         }

//         // Emit event
//         emit AskUpdate(_collection, msg.sender, _tokenId, _askDetails[_collection][_tokenId].price);
//     }

//     function modifyAskOrderCashbackPriceReductors(
//         address _collection,
//         uint _tokenId,
//         Status _cashbackStatus,   
//         uint _cashbackStart,
//         bool _cashNotCredit,
//         bool _checkIdentityCode,
//         uint[] memory __cashbackNumbers,
//         uint[] memory __cashbackCost
//     ) external lock {
//         // Verify collection is accepted
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         (Status status,,,,,,,,,,,,) = IMarketPlace(marketCollections)._collections(_collectionId);
//         require(status == Status.Open);
//         // Verify the sender has listed it
//         require(_tokenIdsOfSellerForCollection[msg.sender][_collection].contains(_tokenId), "Order: Token not listed");
        
//         if (_askDetails[_collection][_tokenId].priceReductor.cashbackStart > 0) {
//             require(_askDetails[_collection][_tokenId].priceReductor.cashbackStart + 
//             IMarketPlace(marketCollections).cashbackBuffer() < block.timestamp,
//                 "Cashback is already active on this product"
//             );
//         }
        
//         if (_cashbackStatus == Status.Open && _askDetails[_collectionId][_tokenId].priceReductor.cashbackStart > 0) {
//             require(_askDetails[_collectionId][_tokenId].priceReductor.cashbackStart + 
//             IMarketPlace(marketCollections).cashbackBuffer() < block.timestamp);
//             require(__cashbackNumbers.length == 6 || __cashbackCost.length == 6, "Invalid cashbacks");
//             _askDetails[_collectionId][_tokenId].priceReductor.cashbackStatus = _cashbackStatus;
//                 _askDetails[_collectionId][_tokenId].priceReductor.cashbackStart = block.timestamp + _cashbackStart;
//                 _askDetails[_collectionId][_tokenId].priceReductor.cashNotCredit = _cashNotCredit;
//                 _askDetails[_collectionId][_tokenId].priceReductor.checkIdentityCode = _checkIdentityCode;
//             _askDetails[_collection][_tokenId].priceReductor.cashbackNumbers = Discount({
//                 cursor: __cashbackNumbers[0],
//                 size: __cashbackNumbers[1],
//                 perct: __cashbackNumbers[2],
//                 lowerThreshold: __cashbackNumbers[3],
//                 upperThreshold: __cashbackNumbers[4],
//                 limit: __cashbackNumbers[5]
//             });
//             _askDetails[_collection][_tokenId].priceReductor.cashbackCost = Discount({
//                 cursor: __cashbackCost[0],
//                 size: __cashbackCost[1],
//                 perct: __cashbackCost[2],
//                 lowerThreshold: __cashbackCost[3],
//                 upperThreshold: __cashbackCost[4],
//                 limit: __cashbackCost[5]
//             });
//         }

//         // Emit event
//         emit AskUpdate(_collection, msg.sender, _tokenId, _askDetails[_collection][_tokenId].price);
//     }

//     /**
//      * @notice Modify existing ask order
//      * @param _collection: contract address of the NFT
//      * @param _tokenId: tokenId of the NFT
//      * @param _newPrice: new price for listing (in wei)
//      */
//     function modifyAskOrder(
//         address _collection,
//         address _seller,
//         uint256 _tokenId,
//         uint256 _newPrice,
//         uint256 _loanDuration,
//         uint256 _bidDuration,
//         uint256 _dropinTimer,
//         uint256 _loanInterestRate,
//         uint256 _rsrcTokenId,
//         bool _transferrable,
//         int256 _minBidIncrementPercentage
//     ) public lock {
//         // Verify new price is not too low/high
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         (Status status,,,,,,,) = IMarketPlace(marketCollections)._collections(_collectionId);
//         require(status == Status.Open);
//         require(_dropinTimer <= IMarketPlace(marketCollections).maxDropinTimer());
//         require(_newPrice >= IMarketPlace(marketCollections).minimumAskPrice() &&
//         _newPrice <= IMarketPlace(marketCollections).maximumAskPrice());

//         // Verify the sender has listed it
//         require(_tokenIdsOfSellerForCollection[msg.sender][_collection].contains(_tokenId), "Order: Token not listed");

//         // Verify for auctions
//         require(_loanDuration <= IMarketPlace(marketCollections).maximumLoanDuration(), 'Order: Duration too high');
//         require(_loanInterestRate <= IMarketPlace(marketCollections).maximumInterestRate(), 'Order: Interest rate too high');

//         // Adjust the information
//         _askDetails[_collectionId][_tokenId].price = _newPrice;
//         _askDetails[_collectionId][_tokenId].seller = _seller;
//         _askDetails[_collectionId][_tokenId].bidDuration = _bidDuration;
//         _askDetails[_collectionId][_tokenId].loanInterestRate = _loanInterestRate;
//         _askDetails[_collectionId][_tokenId].transferrable = _transferrable;
//         _askDetails[_collectionId][_tokenId].loanDuration = block.timestamp + _loanDuration;
//         _askDetails[_collectionId][_tokenId].minBidIncrementPercentage = _minBidIncrementPercentage;
//         _askDetails[_collectionId][_tokenId].dropinTimer = block.timestamp + _dropinTimer;
        
//         // Emit event
//         emit AskUpdate(_collection, msg.sender, _tokenId, _newPrice);
//     }

//     /**
//      * @notice Checks if an array of tokenIds can be listed
//      * @param _collection: address of the collection
//      * @param _tokenIds: array of tokenIds
//      * @dev if collection is not for trading, it returns array of bool with false
//      */
//     function canTokensBeListed(address _collection, uint256[] calldata _tokenIds)
//         external
//         view
//         returns (bool[] memory listingStatuses)
//     {
//         listingStatuses = new bool[](_tokenIds.length);
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_collection);
//         (Status status,,,,,,,) = IMarketPlace(marketCollections)._collections(_collectionId);
//         if (status != Status.Open) {
//             return listingStatuses;
//         }

//         for (uint256 i = 0; i < _tokenIds.length; i++) {
//             listingStatuses[i] = _canTokenBeListed(_collection, _tokenIds[i]);
//         }

//         return listingStatuses;
//     }

//     // bring token for resource
//     function swapIn(
//         address _collection,
//         uint _tokenId,
//         address _rsrcCollection
//     ) external {
//         string memory contract_tokenId = string(abi.encodePacked(_collection, _tokenId));
//         if (_rsrcCollection == address(0)) {
//             uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//             (,,,,,,,,,,,address rsrcCollection,) = 
//             IMarketPlace(marketCollections)._collections(_collectionId);
//             _rsrcCollection = rsrcCollection;
//         }
//         uint _rsrcTokenId = backings[contract_tokenId][_rsrcCollection];

//         IERC721(_collection).safeTransferFrom(msg.sender, address(this), _tokenId);
//         string memory cid = string(abi.encodePacked(_rsrcCollection, _rsrcTokenId));
//         backings[cid][_collection] = _tokenId;
//         uint[] memory _ids = new uint[](1);
//         _ids[0] = _rsrcTokenId;
//         IMarketPlace(marketCollections)._rsrcBatchTransferCollection(
//             _rsrcCollection, 
//             address(this),
//             msg.sender,
//             _ids
//         );
//     }

//     // bring resource to attach backing token
//     // can be used after swapin to attach non resource but attachable tokens
//     function reattach(
//         address _rsrcCollection,
//         uint _rsrcTokenId,
//         address _collection
//     ) external {
//         require(_collection != address(0), "reattach: Collection is undefined");
//         string memory contract_tokenId = string(
//         abi.encodePacked(_rsrcCollection, _rsrcTokenId));
//         uint _tokenId = backings[contract_tokenId][_collection];
//         INaturalResourceNFT(_collection).attach(_tokenId, 0, msg.sender);

//     }

//     // bring resource for external token
//     function swapOut(
//         address _rsrcCollection,
//         uint _rsrcTokenId,
//         address _collection
//     ) external {
//         require(_collection != address(0), "SwapOut: Collection is undefined");
//         string memory contract_tokenId = string(
//         abi.encodePacked(_rsrcCollection, _rsrcTokenId));
//         uint _tokenId = backings[contract_tokenId][_collection];
//         uint[] memory _ids = new uint[](1);
//         _ids[0] = _rsrcTokenId;
//         IMarketPlace(marketCollections)._rsrcBatchTransferCollection(
//             _rsrcCollection, 
//             msg.sender,
//             address(this),
//             _ids
//         );

//         string memory cid = string(abi.encodePacked(_collection, _tokenId));
//         backings[cid][_rsrcCollection] = _rsrcTokenId;
//         IERC721(_collection).safeTransferFrom(address(this), msg.sender, _tokenId);
//     }

//     /**
//      * @notice Checks if a token can be listed
//      * @param _collection: address of the collection
//      * @param _tokenId: tokenId
//      */
//     function _canTokenBeListed(address _collection, uint256 _tokenId) internal view returns (bool) {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         (,,,,address whitelistCheckerAddress,,,) = IMarketPlace(marketCollections)._collections(_collectionId);
//         return
//             (whitelistCheckerAddress == address(0)) ||
//             ICollectionWhitelistChecker(whitelistCheckerAddress).canList(_collection, _tokenId);
//     }

//     function addDtoken(address _dtoken) external onlyAdmin {
//         if (!_dtokenSet.contains(_dtoken)) {
//             _dtokenSet.add(_dtoken);
//         }
//     }

//     function removeDtoken(address _dtoken) external onlyAdmin {
//         if (_dtokenSet.contains(_dtoken)) {
//             _dtokenSet.remove(_dtoken);
//         }
//     }

//     function addVe(address _dtoken) external onlyAdmin {
//         if (!_veTokenSet.contains(_dtoken)) {
//             _veTokenSet.add(_dtoken);
//         }
//     }

//     function removeVe(address _dtoken) external onlyAdmin {
//         if (_veTokenSet.contains(_dtoken)) {
//             _veTokenSet.remove(_dtoken);
//         }
//     }

//     function closeListing(address _collection, uint _tokenId) external {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         string memory collectionTokenId = string(abi.encodePacked(_collection, _tokenId));
//         require(_askDetails[_collectionId][collectionTokenId].priceReductor.cashbackStart + 
//         IMarketPlace(marketCollections).cashbackBuffer() < block.timestamp);
//         // Update storage information
//         _tokenIdsOfSellerForCollection[_collectionId][_collection].remove(_tokenId);
//         delete _askDetails[_collectionId][collectionTokenId];
//         _askTokenIds[_collectionId][_collection].remove(_tokenId);
//     }

// }
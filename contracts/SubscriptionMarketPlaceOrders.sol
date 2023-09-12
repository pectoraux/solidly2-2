// /**
//  *Submitted for verification at BscScan.com on 2021-09-30
// */

// // File: @openzeppelin/contracts/utils/Context.sol

// // SPDX-License-Identifier: MIT

// pragma solidity 0.8.17;
// pragma abicoder v2;

// import "./Library.sol";

// contract SubscriptionMarketPlaceOrders {
//     using EnumerableSet for EnumerableSet.UintSet;

//     using SafeERC20 for IERC20;

//     // referee => videoId => Referral
//     mapping(uint => mapping(address => uint)) public recurringBountyBalance;
//     mapping(uint => mapping(bytes32 => Referral)) public _referrals; // Ask details (price + seller address) for a given collection and a tokenId
//     mapping(uint => mapping(bytes32 => Ask)) public _askDetails; // Ask details (price + seller address) for a given collection and a tokenId
//     mapping(uint => EnumerableSet.UintSet) private _askTokenIds; // Set of tokenIds for a collection
//     mapping(uint => EnumerableSet.UintSet) private _tokenIdsOfSellerForCollection;
//     mapping(uint => bytes32) private _convertToTokenId;
//     mapping(uint => address) private arps;
//     address private marketCollections;
//     address private marketPlaceEvents;
//     address private paywallMarketTrades;
//     address private badgeNft;
//     address private trustBounty;
//     address private marketOrders;
//     // mapping(address => int256) private weights;
//     // mapping(string => address[]) private poolVote;
//     // mapping(string => mapping(bytes32 => int)) private votes;
//     // mapping(uint => uint[]) public AllTiers;
//     // mapping(uint => mapping(uint => uint)) public subscriptionTiers;

//     // // Ask order is cancelled
//     // event AskCancel(uint indexed seller, uint256 indexed tokenId);

//     // // Ask order is created
//     // event AskNew(uint indexed seller, bytes32 indexed tokenId, uint256 askPrice);

//     // // Ask order is updated
//     // event AskUpdate(uint indexed seller, bytes32 indexed tokenId, uint256 askPrice);

//     // event TokenRecovery(address indexed token, uint256 amount);

//     // event UpdateBurnTokenForCredit(address indexed Collection, address token, uint256 discountNumber);

//     /**
//      * @notice Constructor
//      * @param _marketCollections: address of the admin
//      * @param _badgeNft: address of the admin
//      */
//     constructor(
//         address _marketCollections,
//         address _marketPlaceEvents,
//         address _marketOrders,
//         address _trustBounty,
//         address _badgeNft
//     ) {
//         marketCollections = _marketCollections;
//         marketPlaceEvents = _marketPlaceEvents;
//         badgeNft = _badgeNft;
//         trustBounty = _trustBounty;
//         marketOrders = _marketOrders;
//     }

//     function setMarketTrades(address _marketTrades) external {
//         require(paywallMarketTrades == address(0x0));
//         paywallMarketTrades = _marketTrades;
//     }

//     function updateAfterSale(
//         uint _collectionId,
//         bytes32 _tokenId,
//         uint _price, 
//         uint _bidDuration, 
//         uint _firstBidTime,
//         address _lastBidder
//     ) external {
//         require(paywallMarketTrades == msg.sender);
//         _askDetails[_collectionId][_tokenId].price = _price;
//         _askDetails[_collectionId][_tokenId].bidDuration = _bidDuration;
//         _askDetails[_collectionId][_tokenId].firstBidTime = _firstBidTime;
//         _askDetails[_collectionId][_tokenId].lastBidder = _lastBidder;
//     }

//     function decrementMaxSupply(uint _collectionId, bytes32 _tokenId) external {
//         require(paywallMarketTrades == msg.sender);
//         _askDetails[_collectionId][_tokenId].maxSupply -= 1;
//     }
    
//     /**
//      * @notice Create ask order
//      * @param _tokenId: tokenId of the NFT
//      * @param _askPrice: price for listing (in wei)
//      */
//     function createAskOrder(
//         string memory _tokenId,
//         uint _askPrice,
//         uint _bidDuration,
//         int _minBidIncrementPercentage,
//         bool _transferrable,
//         uint _rsrcTokenId,
//         uint _maxSupply,
//         uint _dropinTimer,
//         address _tFIAT,
//         address _ve,
//         address _arp,
//         DIRECTION _direction
//     ) external {
//         // Verify collection is accepted
//         _checkRequirements(
//             _ve, 
//             _tFIAT, 
//             _askPrice, 
//             _maxSupply, 
//             _dropinTimer,
//             _rsrcTokenId
//         );
//         _addOrder(
//             _askPrice, 
//             _tokenId,
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
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         arps[_collectionId] = _arp;
//         // Emit event
//         IMarketPlace(marketPlaceEvents).
//         emitPaywallAskNew(
//             _collectionId, 
//             _tokenId, 
//             _askPrice, 
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

//     function _checkRequirements(
//         address _ve, 
//         address _tFIAT, 
//         uint _askPrice, 
//         uint _maxSupply, 
//         uint _dropinTimer,
//         uint _rsrcTokenId
//     ) internal view {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         (Status status,,,,,,,) = IMarketPlace(marketCollections)._collections(_collectionId);
//         require(status == Status.Open && _maxSupply != 0);
//         require(_dropinTimer <= IMarketPlace(marketCollections).maxDropinTimer());
//         require(IMarketPlace(marketOrders).veTokenSetContains(_ve));
//         require(_askPrice >= IMarketPlace(marketCollections).minimumAskPrice() &&
//         _askPrice <= IMarketPlace(marketCollections).maximumAskPrice());
//         if (_tFIAT != address(0x0)) {
//             require(IMarketPlace(marketOrders).dTokenSetContains(_tFIAT));
//         }
//         if (_rsrcTokenId != 0) {
//             require(IERC721(badgeNft).ownerOf(_rsrcTokenId) == msg.sender);
//         }
//     }

//     function _addOrder(
//         uint _askPrice,
//         string memory  _tokenId,
//         uint _bidDuration,
//         int _minBidIncrementPercentage,
//         bool _transferrable,
//         uint _rsrcTokenId,
//         uint _maxSupply,
//         uint _dropinTimer,
//         address _tFIAT,
//         address _ve,
//         DIRECTION _direction
//     ) internal {
//         // Adjust the information
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         _tokenIdsOfSellerForCollection[_collectionId].add(uint(keccak256(abi.encodePacked(_tokenId))));
//         // Add tokenId to the askTokenIds set
//         _askTokenIds[_collectionId].add(uint(keccak256(abi.encodePacked(_tokenId))));
//         _convertToTokenId[uint(keccak256(abi.encodePacked(_tokenId)))] = keccak256(abi.encodePacked(_tokenId));
//         // Adjust the information
//         _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))] = Ask({
//             seller: msg.sender,
//             price: _askPrice,
//             lastBidder: address(0x0),
//             bidDuration: _bidDuration,
//             firstBidTime: 0,
//             minBidIncrementPercentage: _minBidIncrementPercentage,
//             transferrable: _transferrable,
//             rsrcTokenId: _rsrcTokenId,
//             maxSupply: _maxSupply > 0 ? uint(_maxSupply) : type(uint).max,
//             dropinTimer: block.timestamp + _dropinTimer,
//             identityProof: IdentityProof({
//                 minIDBadgeColor: COLOR.BLACK,
//                 valueName: "",
//                 requiredIndentity: "",
//                 onlyTrustWorthyAuditors: false,
//                 uniqueAccounts: false
//             }),
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
//             tokenInfo: TokenInfo({
//                 tFIAT: _tFIAT,
//                 ve: _ve,
//                 usetFIAT: _tFIAT == address(0x0),
//                 direction: _direction,
//                 superLikes: 0,
//                 superDisLikes: 0
//             })
//         });
//     }

//     // function _reset(string memory ve_tokenId, uint _collectionId, bytes32 tokenId) internal {
//     //     address[] storage _poolVote = poolVote[ve_tokenId];
//     //     uint _poolVoteCnt = _poolVote.length;

//     //     for (uint i = 0; i < _poolVoteCnt; i ++) {
//     //         address _pool = _poolVote[i];
//     //         int256 _votes = votes[ve_tokenId][tokenId];

//     //         if (_votes != 0) {
//     //             weights[_pool] -= _votes;
//     //             votes[ve_tokenId][tokenId] -= _votes;
//     //             if (_votes > 0) {
//     //                 _askDetails[_collectionId][tokenId].tokenInfo.superLikes -= uint256(_votes);
//     //             } else {
//     //                 _askDetails[_collectionId][tokenId].tokenInfo.superDisLikes -= uint256(_votes);
//     //             }
//     //         }
//     //     }
//     //     delete poolVote[ve_tokenId];
//     // }
    
//     // function vote(
//     //     address _pool, 
//     //     bytes32 tokenId,
//     //     uint _tokenId, 
//     //     int256 _weights
//     // ) internal {
//     //     uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_pool);
//     //     address _ve = _askDetails[_collectionId][tokenId].tokenInfo.ve;
//     //     require(ve(_ve).isApprovedOrOwner(msg.sender, _tokenId));
//     //     string memory ve_tokenId = string(abi.encodePacked(_ve, _tokenId));
//     //     _reset(ve_tokenId, _collectionId, tokenId);
//     //     int256 _weight = int256(ve(_ve).balanceOfNFT(_tokenId));
//     //     int256 _totalVoteWeight = 0;
//     //     int256 _usedWeight = 0;
        
//     //     _totalVoteWeight += _weights > 0 ? _weights : -_weights;
//     //     if (_collectionId > 0) {
//     //         int256 _poolWeight = _weights * _weight / _totalVoteWeight;
//     //         require(votes[ve_tokenId][tokenId] == 0);
//     //         require(_poolWeight != 0);

//     //         poolVote[ve_tokenId].push(_pool);

//     //         weights[_pool] += _poolWeight;
//     //         votes[ve_tokenId][tokenId] += _poolWeight;
//     //         if (_poolWeight > 0) {
//     //             _askDetails[_collectionId][tokenId].tokenInfo.superLikes += uint(_poolWeight);
//     //         } else {
//     //             _askDetails[_collectionId][tokenId].tokenInfo.superDisLikes += uint(_poolWeight);
//     //             _poolWeight = -_poolWeight;
//     //         }
//     //         _usedWeight += _poolWeight;
//     //     }
//     //     if (_usedWeight > 0) ve(_ve).voting(_tokenId);
//     // }

//     /**
//      * @notice Cancel existing ask order
//      * @param __tokenId: tokenId of the NFT
//      */
//     function cancelAskOrder(string memory __tokenId) external {
//         uint _tokenId = uint(keccak256(abi.encodePacked(__tokenId)));
//         // Verify the sender has listed it
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         require(_tokenIdsOfSellerForCollection[_collectionId].contains(_tokenId));
        
//         // Adjust the information
//         _tokenIdsOfSellerForCollection[_collectionId].remove(_tokenId);
//         delete _askDetails[_collectionId][keccak256(abi.encodePacked(__tokenId))];
//         delete _convertToTokenId[_tokenId];
//         _askTokenIds[_collectionId].remove(_tokenId);
        
//         // Emit event
//         IMarketPlace(marketPlaceEvents).emitPaywallAskCancel(_collectionId, _tokenId);
//     }

//     function modifyAskOrderIdentity(
//         string memory _tokenId,
//         string memory _requiredIndentity,
//         string memory _valueName,
//         bool _onlyTrustWorthyAuditors,
//         bool _uniqueAccounts,
//         COLOR _minIDBadgeColor
//     ) external {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].identityProof.requiredIndentity = _requiredIndentity;
//         _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].identityProof.minIDBadgeColor = _minIDBadgeColor;
//         _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].identityProof.valueName = _valueName;
//         _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].identityProof.uniqueAccounts = _uniqueAccounts;
//         _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].identityProof.onlyTrustWorthyAuditors = _onlyTrustWorthyAuditors;

//         IMarketPlace(marketPlaceEvents).
//         emitPaywallAskUpdateIdentity(
//             _collectionId,
//             _tokenId,
//             _requiredIndentity,
//             _valueName,
//             _onlyTrustWorthyAuditors,
//             _uniqueAccounts,
//             _minIDBadgeColor
//         );
//     }
    
//     /**
//      * @notice Modify existing ask order
//      * @param _tokenId: tokenId of the NFT
//      */
//     function modifyAskOrderDiscountPriceReductors(
//         string memory _tokenId,
//         Status _discountStatus,   
//         uint _discountStart,   
//         bool _cashNotCredit,
//         bool _checkIdentityCode,
//         uint[] memory __discountNumbers,
//         uint[] memory __discountCost 
//     ) external {
//         // Verify collection is accepted
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         {
//             if (_discountStatus == Status.Open) {
//                 require(__discountNumbers.length == 6 || __discountCost.length == 6);
//                 _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.discountStatus = _discountStatus;
//                 _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.discountStart = block.timestamp + _discountStart;
//                 _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.cashNotCredit = _cashNotCredit;
//                 _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.checkIdentityCode = _checkIdentityCode;
//                 _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.discountNumbers = Discount({
//                     cursor: __discountNumbers[0],
//                     size: __discountNumbers[1],
//                     perct: __discountNumbers[2],
//                     lowerThreshold: __discountNumbers[3],
//                     upperThreshold: __discountNumbers[4],
//                     limit: __discountNumbers[5]
//                 });
//                 _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.discountCost = Discount({
//                     cursor: __discountCost[0],
//                     size: __discountCost[1],
//                     perct: __discountCost[2],
//                     lowerThreshold: __discountCost[3],
//                     upperThreshold: __discountCost[4],
//                     limit: __discountCost[5]
//                 });
//             }
//         }
//         // Emit event
//         IMarketPlace(marketPlaceEvents).
//         emitPaywallAskUpdateDiscount(
//             _collectionId, 
//             _tokenId, 
//             _discountStatus,   
//             _discountStart,   
//             _cashNotCredit,
//             _checkIdentityCode,
//             __discountNumbers,
//             __discountCost
//         );
//     }

//     /**
//      * @notice Modify existing ask order
//      * @param _tokenId: tokenId of the NFT
//      */
//     function modifyAskOrderCashbackPriceReductors(
//         string memory  _tokenId,
//         Status _cashbackStatus,
//         uint _cashbackStart,
//         bool _cashNotCredit,
//         bool _checkIdentityCode,
//         uint[] memory __cashbackNumbers,
//         uint[] memory __cashbackCost
//     ) external {
//         // Verify collection is accepted
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         {
//             if (_cashbackStatus == Status.Open && _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.cashbackStart > 0) {
//                 require(_askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.cashbackStart + IMarketPlace(marketCollections).cashbackBuffer() < block.timestamp);
//                 require(__cashbackNumbers.length == 6 || __cashbackCost.length == 6);
//                 _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.cashbackStatus = _cashbackStatus;
//                 _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.cashbackStart = block.timestamp + _cashbackStart;
//                 _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.cashNotCredit = _cashNotCredit;
//                 _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.checkIdentityCode = _checkIdentityCode;
//                 _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.cashbackNumbers = Discount({
//                     cursor: __cashbackNumbers[0],
//                     size: __cashbackNumbers[1],
//                     perct: __cashbackNumbers[2],
//                     lowerThreshold: __cashbackNumbers[3],
//                     upperThreshold: __cashbackNumbers[4],
//                     limit: __cashbackNumbers[5]
//                 });
//                 _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.cashbackCost = Discount({
//                     cursor: __cashbackCost[0],
//                     size: __cashbackCost[1],
//                     perct: __cashbackCost[2],
//                     lowerThreshold: __cashbackCost[3],
//                     upperThreshold: __cashbackCost[4],
//                     limit: __cashbackCost[5]
//                 });
//             }
//         }
//         // Emit event
//         IMarketPlace(marketPlaceEvents).
//         emitPaywallAskUpdateCashback(
//             _collectionId, 
//             _tokenId, 
//             _cashbackStatus,   
//             _cashbackStart,   
//             _cashNotCredit,
//             _checkIdentityCode,
//             __cashbackNumbers,
//             __cashbackNumbers
//         );
//     }

//     function addReferral(
//         address _referrer,
//         string memory _tokenId,
//         uint _bountyId
//     ) external {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         uint _referrerCollectionId = IMarketPlace(marketCollections).addressToCollectionId(_referrer);
//         (,,,,,uint _referrerFee,uint minBounty,uint recurringBounty) = IMarketPlace(marketCollections)._collections(_collectionId);
//         if (minBounty > 0) {
//             address _token = _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].tokenInfo.usetFIAT 
//             ? _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].tokenInfo.tFIAT 
//             : ve(_askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].tokenInfo.ve).token();
//             (address owner,address __token,address claimableBy,,,,,,bool recurring) = ITrustBounty(trustBounty).bountyInfo(_bountyId);
//             uint _limit = ITrustBounty(trustBounty).getBalance(_bountyId);
//             require(
//                 owner == _referrer && _token == __token && 
//                 claimableBy == address(0x0) && minBounty <= _limit
//             );
//             if(recurringBounty > 0) require(recurring);
//         }
//         _referrals[_referrerCollectionId][keccak256(abi.encodePacked(_tokenId))] = Referral({
//             collectionId: _collectionId,
//             referrerFee: _referrerFee,
//             bountyId: _bountyId
//         });
     
//         IMarketPlace(marketPlaceEvents).emitPaywallAddReferral(_referrerCollectionId, _collectionId, _tokenId, _bountyId);
//     }

//     function closeReferral(
//         address _referrer,
//         string memory _tokenId
//     ) external {
//         uint _referrerCollectionId = IMarketPlace(marketCollections).addressToCollectionId(_referrer);
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         require(_referrals[_referrerCollectionId][keccak256(abi.encodePacked(_tokenId))].collectionId == _collectionId);
//         delete _referrals[_referrerCollectionId][keccak256(abi.encodePacked(_tokenId))];

//         IMarketPlace(marketPlaceEvents).
//         emitPaywallCloseReferral(_referrerCollectionId, _collectionId, _tokenId);
//     }

//     function updateRecurringBountyRevenue(address _token, uint _collectionId, uint _amount) external {
//         IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
//         recurringBountyBalance[_collectionId][_token] += _amount;
//     }

//     function withdrawBounty(address _referrer, address _token, uint _toWithdraw) external {
//         require(trustBounty == msg.sender);
//         uint _referrerCollectionId = IMarketPlace(marketCollections).addressToCollectionId(_referrer);
//         _toWithdraw = Math.min(recurringBountyBalance[_referrerCollectionId][_token], _toWithdraw);
//         IERC20(_token).safeTransferFrom(msg.sender, address(this), _toWithdraw);
//         recurringBountyBalance[_referrerCollectionId][_token] -= _toWithdraw;
//     }

//     /**
//      * @notice Modify existing ask order
//      * @param _tokenId: tokenId of the NFT
//      * @param _newPrice: new price for listing (in wei)
//      */
//     function modifyAskOrder(
//         address _seller,
//         string memory _tokenId,
//         uint256 _newPrice,
//         uint256 _bidDuration,
//         int256 _minBidIncrementPercentage,
//         bool _transferrable,
//         uint256 _rsrcTokenId,
//         uint256 _maxSupply,
//         uint _dropinTimer
//     ) external {
//         // Verify collection is accepted
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         require(_dropinTimer <= IMarketPlace(marketCollections).maxDropinTimer());
//         require(_newPrice >= IMarketPlace(marketCollections).minimumAskPrice() &&
//         _newPrice <= IMarketPlace(marketCollections).maximumAskPrice());

//         if (_rsrcTokenId != 0) {
//             require(IERC721(badgeNft).ownerOf(_rsrcTokenId) == msg.sender);
//         }

//         // Adjust the information
//         _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].price = _newPrice;
//         _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].seller = _seller;
//         _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].bidDuration = _bidDuration;
//         _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].rsrcTokenId = _rsrcTokenId;
//         _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].minBidIncrementPercentage = _minBidIncrementPercentage;
//         _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].transferrable = _transferrable;
//         _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].dropinTimer = block.timestamp + _dropinTimer;
//         _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].maxSupply = _maxSupply > 0 ? uint(_maxSupply) : type(uint).max;
        
//         // Emit event
//         IMarketPlace(marketPlaceEvents).
//         emitPaywallAskUpdate(
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

//     function closeListing(string memory _tokenId) external {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         require(_askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.cashbackStart + 
//         IMarketPlace(marketCollections).cashbackBuffer() < block.timestamp);
//         // Update storage information
//         _tokenIdsOfSellerForCollection[_collectionId].remove(uint(keccak256(abi.encodePacked(_tokenId))));
//         delete _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))];
//         _askTokenIds[_collectionId].remove(uint(keccak256(abi.encodePacked(_tokenId))));
//         delete _convertToTokenId[uint(keccak256(abi.encodePacked(_tokenId)))];
    
//         IMarketPlace(marketPlaceEvents).emitPaywallCloseListing(_collectionId, _tokenId);
//     }

//     /**
//      * @notice Allows the owner to recover tokens sent to the contract by mistake
//      * @param _token: token address
//      * @dev Callable by owner
//      */
//     function recoverFungibleTokens(address _token, uint amountToRecover) external {
//         require(marketCollections == msg.sender);
//         IERC20(_token).safeTransfer(address(msg.sender), amountToRecover);
//     }

//     // /**
//     //  * @notice Allows the owner to recover NFTs sent to the contract by mistake
//     //  * @param _token: NFT token address
//     //  * @param _tokenId: tokenId
//     //  * @dev Callable by owner
//     //  */
//     // function recoverNonFungibleToken(address _token, uint _tokenId) external {
//     //     require(marketCollections == msg.sender);
//     //     IERC721(_token).safeTransferFrom(address(this), address(msg.sender), _tokenId);
//     // }

//     // function checkIdentityProof2(
//     //     uint _collectionId,
//     //     bytes32 _tokenId, 
//     //     address _owner, 
//     //     bool _check
//     // ) public returns(bytes32 identityCode) {
//     //     bytes32 _valueName = _askDetails[_collectionId][_tokenId].identityProof.valueName;
//     //     bytes32 _requiredIndentity = _askDetails[_collectionId][_tokenId].identityProof.requiredIndentity;
//     //     (
//     //         string memory ssid,
//     //         string memory value, 
//     //         address _gauge 
//     //     ) = ISuperLikeGaugeFactory(IMarketPlace(marketCollections).superLikeGaugeFactory()).getIdentityValue(_owner, _valueName);
//     //     identityCode = keccak256(abi.encodePacked(ssid));
//     //     if (keccak256(abi.encodePacked(_valueName)) != keccak256(abi.encodePacked("")) || _check) {
//     //         require(ISuperLikeGauge(_gauge).badgeColor() >= uint(_askDetails[_collectionId][_tokenId].identityProof.minIDBadgeColor), "ID Gauge inelligible");
//     //         require(keccak256(abi.encodePacked(value)) == keccak256(abi.encodePacked(_requiredIndentity)) || 
//     //         keccak256(abi.encodePacked(_requiredIndentity)) == keccak256(abi.encodePacked("")), "Invalid comparator");
//     //         require(!_askDetails[_collectionId][_tokenId].identityProof.onlyTrustWorthyAuditors || 
//     //         IMarketPlace(marketCollections).isCollectionTrustWorthyAuditor(_gauge),
//     //         "Only identity proofs from trustworthy auditors"
//     //         );
//     //         require(!IMarketPlace(marketCollections).blackListedIdentities(identityCode), "You identiyCode is blacklisted");
//     //         require(IMarketPlace(marketCollections).identityProofs(identityCode) == address(0x0) || 
//     //             !_askDetails[_collectionId][_tokenId].identityProof.uniqueAccounts || 
//     //             IMarketPlace(marketCollections).identityProofs(identityCode) == _owner
//     //         );
//     //     }
//     // }

//     // /**
//     //  * @notice View ask orders for a given collection across all sellers
//     //  * @param collection: address of the collection
//     //  * @param cursor: cursor
//     //  * @param size: size of the response
//     //  */
//     // function viewAsksByCollection(
//     //     address collection,
//     //     uint256 cursor,
//     //     uint256 size
//     // )
//     //     external
//     //     view
//     //     returns (
//     //         uint256[] memory tokenIds,
//     //         Ask[] memory askInfo,
//     //         uint256
//     //     )
//     // {
//     //     uint256 length = size;
//     //     uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(collection);

//     //     if (length > _askTokenIds[_collectionId].length() - cursor) {
//     //         length = _askTokenIds[_collectionId].length() - cursor;
//     //     }

//     //     tokenIds = new uint256[](length);
//     //     askInfo = new Ask[](length);

//     //     for (uint256 i = 0; i < length; i++) {
//     //         tokenIds[i] = _askTokenIds[_collectionId].at(cursor + i);
//     //         bytes32 _tokenId = _convertToTokenId[tokenIds[i]];
//     //         askInfo[i] = _askDetails[_collectionId][_tokenId];
//     //     }

//     //     return (tokenIds, askInfo, cursor + length);
//     // } 

//     // function updateSubscriptionTiers(
//     //     uint[] memory _times, 
//     //     uint[] memory _prices
//     // ) external onlyAdmin {
//     //     require(_times.length == _prices.length, "Uneven lists");
//     //     uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//     //     AllTiers[_collectionId] = _times;
//     //     for (uint i = 0; i < _times.length; i++) {
//     //         subscriptionTiers[_collectionId][_times[i]] = _prices[i];
//     //     }
     
//     //     IMarketPlace(marketPlaceEvents).
//     //     emitUpdateScubscriptionTiers(_collectionId, _times, _prices);
//     // }
// }
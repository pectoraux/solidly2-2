// /**
//  *Submitted for verification at BscScan.com on 2021-09-30
// */

// // File: @openzeppelin/contracts/utils/Context.sol

// // SPDX-License-Identifier: MIT

// pragma solidity 0.8.17;
// pragma abicoder v2;

// import "./Library.sol";

// contract MarketPlaceOrders {
//     // referee => videoId => Referral
//     mapping(uint => mapping(uint => bool)) internal _partnerShip;
//     mapping(uint => mapping(bytes32 => Referral)) internal _referrals; // Ask details (price + seller address) for a given collection and a tokenId
//     mapping(uint => mapping(bytes32 => Ask)) private _askDetails; // Ask details (price + seller address) for a given collection and a tokenId
//     mapping(address => mapping(string => uint)) internal paymentCredits;
    
//     address internal marketCollections;
//     address internal marketPlaceEvents;
//     address internal marketTrades;
//     address internal marketHelpers;
//     address internal marketHelpers2;
//     address internal badgeNft;
//     address internal trustBounty;

//     /**
//      * @notice Constructor
//      */
//     constructor(
//         address _marketCollections,
//         address _marketPlaceEvents,
//         address _trustBounty,
//         address _badgeNft
//     ) {
//         marketCollections = _marketCollections;
//         marketPlaceEvents = _marketPlaceEvents;
//         badgeNft = _badgeNft;
//         trustBounty = _trustBounty;
//     }
    
//     modifier onlyAdmin() {
//         require(IAuth(marketCollections).isAdmin(msg.sender));
//         _;
//     }

//     function setMarkets(
//         address _marketTrades, 
//         address _marketHelpers,
//         address _marketHelpers2
//     ) external onlyAdmin {
//         marketTrades = _marketTrades;
//         marketHelpers = _marketHelpers;
//         marketHelpers2 = _marketHelpers2;
//     }

//     // function getContracts() external view returns(address,address,address,address,address) {
//     //     return (marketCollections, marketPlaceEvents, marketTrades, marketHelpers, marketHelpers2);
//     // }

//     function getPaymentCredits(address _user, uint _collectionId, string memory _tokenId) external view returns(uint) {
//         return paymentCredits[_user][string(abi.encodePacked(_collectionId, _tokenId))];
//     }

//     function getReferral(uint _referrerCollectionId, string memory _tokenId) external view returns(Referral memory) {
//         return _referrals[_referrerCollectionId][keccak256(abi.encodePacked(_tokenId))];
//     }

//     function updatePaymentCredits(address _user, uint _collectionId, string memory _tokenId) external {
//         require(marketTrades == msg.sender);
//         paymentCredits[_user][string(abi.encodePacked(_collectionId, _tokenId))] += 
//         paymentCredits[_user][string(abi.encodePacked(_collectionId, ""))];
//         paymentCredits[_user][string(abi.encodePacked(_collectionId, ""))] = 0;
//     }

//     function incrementPaymentCredits(address _user, uint _collectionId, string memory _tokenId, uint _price) external {
//         uint __collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         require(marketTrades == msg.sender || marketHelpers == msg.sender || __collectionId == _collectionId);
//         paymentCredits[_user][string(abi.encodePacked(_collectionId, _tokenId))] += _price;
//     }

//     function decrementPaymentCredits(address _user, uint _collectionId, string memory _tokenId, uint _price) external {
//         require(marketTrades == msg.sender);
//         paymentCredits[_user][string(abi.encodePacked(_collectionId, _tokenId))] -= _price;
//     }

//     function getAskDetails(uint _collectionId, bytes32 _tokenId) external view returns(Ask memory) {
//         return _askDetails[_collectionId][_tokenId];
//     }

//     function updateAfterSale(
//         uint _collectionId,
//         string memory _tokenId,
//         uint _price, 
//         uint _lastBidTime,
//         address _lastBidder
//     ) external {
//         require(marketHelpers == msg.sender);
//         _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].price = _price;
//         _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].lastBidTime = _lastBidTime;
//         _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].lastBidder = _lastBidder;
//     }

//     function decrementMaxSupply(uint _collectionId, bytes32 _tokenId) external {
//         require(marketHelpers == msg.sender);
//         if (_askDetails[_collectionId][_tokenId].maxSupply > 0) {
//             _askDetails[_collectionId][_tokenId].maxSupply -= 1;
//         }
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
//         bool _requireUpfrontPayment,
//         uint _rsrcTokenId,
//         uint _maxSupply,
//         uint _dropinTimer,
//         address _tFIAT,
//         address _ve,
//         DIRECTION _direction
//     ) external {
//         // Verify collection is accepted
//         IMarketPlace(marketHelpers2)
//         .checkRequirements(
//             _ve, 
//             msg.sender,
//             _tFIAT, 
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
//         if (_requireUpfrontPayment) {
//             uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//             _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].tokenInfo.requireUpfrontPayment = _requireUpfrontPayment;
//         }
//     }

//     function _addOrder(
//         uint _askPrice,
//         string memory _tokenId,
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
//         _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))] = Ask({
//             seller: msg.sender,
//             price: _askPrice,
//             lastBidder: address(0x0),
//             bidDuration: _bidDuration,
//             lastBidTime: 0,
//             minBidIncrementPercentage: _minBidIncrementPercentage,
//             transferrable: _transferrable,
//             rsrcTokenId: _rsrcTokenId,
//             maxSupply: _maxSupply > 0 ? _maxSupply : type(uint).max,
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
//                 usetFIAT: _tFIAT != address(0x0),
//                 direction: _direction,
//                 requireUpfrontPayment: false
//             })
//         });
        
//         // Emit event
//         IMarketPlace(marketPlaceEvents).
//         emitAskNew(
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

//     function updateVe(
//         uint _collectionId,
//         string memory _tokenId,
//         address _ve
//     ) external {
//         require(marketCollections == msg.sender);
//         require(IMarketPlace(marketHelpers).veTokenSetContains(_ve));
//         _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].tokenInfo.ve = _ve;
//     }
    
//     /**
//      * @notice Cancel existing ask order
//      * @param __tokenId: tokenId of the NFT
//      */
//     function cancelAskOrder(string memory __tokenId) external {
//         uint _tokenId = uint(keccak256(abi.encodePacked(__tokenId)));
//         // Verify the sender has listed it
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
        
//         // Adjust the information
//         delete _askDetails[_collectionId][keccak256(abi.encodePacked(__tokenId))];
        
//         // Emit event
//         IMarketPlace(marketPlaceEvents).emitAskCancel(_collectionId, _tokenId);
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
//         emitAskUpdateIdentity(
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
//         uint[6] memory __discountNumbers,
//         uint[6] memory __discountCost 
//     ) external {
//         // Verify collection is accepted
//         require(__discountNumbers[2] + __discountCost[2] <= 10000);
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         {
//             if (_discountStatus == Status.Open) {
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
//         emitAskUpdateDiscount(
//             _collectionId, 
//             _tokenId, 
//             _discountStatus,   
//             block.timestamp + _discountStart,   
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
//         string memory _tokenId,
//         Status _cashbackStatus,
//         uint _cashbackStart,
//         bool _cashNotCredit,
//         uint[6] memory __cashbackNumbers,
//         uint[6] memory __cashbackCost
//     ) external {
//         // Verify collection is accepted
//         require(__cashbackNumbers[2] + __cashbackCost[2] <= 10000);
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         IMarketPlace(marketHelpers2).updateCashbackRevenue(msg.sender, _tokenId);
//         {
//             if (_cashbackStatus == Status.Open) {
//                 _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.cashbackStatus = _cashbackStatus;
//                 _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.cashbackStart = block.timestamp + _cashbackStart;
//                 _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].priceReductor.cashNotCredit = _cashNotCredit;
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
//         emitAskUpdateCashback(
//             _collectionId, 
//             _tokenId, 
//             _cashbackStatus,   
//             block.timestamp + _cashbackStart,   
//             _cashNotCredit,
//             __cashbackNumbers,
//             __cashbackNumbers
//         );
//     }

//     function addReferral(
//         address _seller,
//         address _referrer,
//         string memory _tokenId,
//         uint _bountyId,
//         uint _identityProofId
//     ) external {
//         require(msg.sender == _seller || msg.sender == _referrer);
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_seller);
//         uint _referrerCollectionId = IMarketPlace(marketCollections).addressToCollectionId(_referrer);
//         IMarketPlace(marketHelpers2).checkPartnerIdentityProof(_collectionId, _identityProofId, _referrer);
//         Collection memory _collection = IMarketPlace(marketCollections).getCollection(_collectionId);
//         if (_collection.requestPartnerRegistration && !_partnerShip[_collectionId][_referrerCollectionId]) {
//             require(_seller == msg.sender);
//         }
//         if (_collection.minBounty > 0) {
//             (address owner,address _token,,address claimableBy,,,,,,bool recurring) = ITrustBounty(trustBounty).bountyInfo(_bountyId);
//             uint _limit = ITrustBounty(trustBounty).getBalance(_bountyId);
//             Ask memory _ask = _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))];
//             address __token = _ask.tokenInfo.usetFIAT ? _ask.tokenInfo.tFIAT : ve(_ask.tokenInfo.ve).token();
//             require(
//                 owner == _referrer && __token == _token && 
//                 claimableBy == address(0x0) && _collection.minBounty <= _limit
//             );
//             if(_collection.recurringBounty > 0) require(recurring);
//         }
//         _partnerShip[_collectionId][_referrerCollectionId] = true;
//         _referrals[_referrerCollectionId][keccak256(abi.encodePacked(_tokenId))] = Referral({
//             collectionId: _collectionId,
//             referrerFee: _collection.referrerFee,
//             bountyId: _bountyId
//         });

//         IMarketPlace(marketPlaceEvents).emitAddReferral(
//             _referrerCollectionId, 
//             _collectionId, 
//             _tokenId, 
//             _bountyId,
//             _identityProofId
//         );
//     }
    
//     function closeReferral(
//         address _seller,
//         address _referrer,
//         uint _bountyId,
//         string memory _tokenId,
//         string[] memory tokenIds,
//         bool deactivate
//     ) external {
//         require(msg.sender == _seller || msg.sender == _referrer);
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_seller);
//         uint _referrerCollectionId = IMarketPlace(marketCollections).addressToCollectionId(_referrer);
//         require(_referrals[_referrerCollectionId][keccak256(abi.encodePacked(_tokenId))].collectionId == _collectionId);
//         delete _referrals[_referrerCollectionId][keccak256(abi.encodePacked(_tokenId))];
//         if (deactivate) {
//             delete _partnerShip[_collectionId][_referrerCollectionId];
//         }
//         IMarketPlace(marketPlaceEvents).emitCloseReferral(_referrerCollectionId, _collectionId, _bountyId, msg.sender, tokenIds, deactivate);
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
//         bool _requireUpfrontPayment,
//         uint256 _rsrcTokenId,
//         uint256 _maxSupply,
//         uint _dropinTimer
//     ) external {
//         // Verify collection is accepted
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         require(_dropinTimer <= IMarketPlace(marketCollections).maxDropinTimer());

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
//         _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].maxSupply = _maxSupply > 0 ? _maxSupply : type(uint).max;
//         _askDetails[_collectionId][keccak256(abi.encodePacked(_tokenId))].tokenInfo.requireUpfrontPayment = _requireUpfrontPayment;
        
//         // Emit event
//         IMarketPlace(marketPlaceEvents).
//         emitAskUpdate(
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
// }
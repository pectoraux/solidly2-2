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

// contract MarketPlaceCollection is Auth, ERC721Holder {
//     using EnumerableSet for EnumerableSet.AddressSet;
//     using EnumerableSet for EnumerableSet.UintSet;
    
//     mapping(uint => Collection) private _collections; // Details about the collections
//     EnumerableSet.UintSet private _collectionAddressSet;
//     mapping(address => uint) public addressToCollectionId;

//     address private lotteryAddress;
//     uint collectionId = 1;
//     uint public maximumArrayLength = 50;
//     address private marketPlaceEvents;
//     address private marketOrders;
//     mapping(uint => EnumerableSet.AddressSet) private collectionTrustWorthyAuditors;
    
//     uint256 public tradingFee = 1000;
//     uint256 public lotteryFee;
//     address public nft_;
//     mapping(address => bool) public isBlacklisted;
//     uint public maxDropinTimer = 86400 * 7;
//     uint public cashbackBuffer;
//     address private badgeNft;

//     /**
//      * @notice Constructor
//      * @param _adminAddress: address of the admin
//      */
//     constructor(
//         address _nft,
//         address _adminAddress,
//         address _helper,
//         address _marketPlaceEvents,
//         address _superLikeGaugeFactory
//     ) Auth(_helper, _adminAddress, _superLikeGaugeFactory) {
//         nft_ = _nft;
//         marketPlaceEvents = _marketPlaceEvents;
//     }

//     // simple re-entrancy check
//     uint internal _unlocked = 1;
//     modifier lock() {
//         require(_unlocked == 1);
//         _unlocked = 2;
//         _;
//         _unlocked = 1;
//     }

//     function setMarketOrders(address _marketOrders) external {
//         require(devaddr_ == msg.sender);
//         marketOrders = _marketOrders;
//     }

//     function setBadgeNFT(address _badgeNft) external {
//         require(msg.sender == devaddr_);
//         badgeNft = _badgeNft;
//     }

//     function updateMaxDropinTimer(uint _newMaxDropinTimer, uint _cashbackBuffer) external onlyAdmin {
//         maxDropinTimer = _newMaxDropinTimer;
//         cashbackBuffer = _cashbackBuffer;
//     }

//     function updateCollectionTrustWorthyAuditors(address[] memory _gauges, bool _add) external {
//         for (uint i = 0; i < _gauges.length; i++) {
//             if (_add) {
//                 collectionTrustWorthyAuditors[addressToCollectionId[msg.sender]].add(_gauges[i]);
//             } else {
//                 collectionTrustWorthyAuditors[addressToCollectionId[msg.sender]].remove(_gauges[i]);
//             }
//         }
//     }

//     function getAllCollectionTrustWorthyAuditors(address _collection, uint _start) external view returns(address[] memory _auditors) {
//         _auditors = new address[](collectionTrustWorthyAuditors[addressToCollectionId[_collection]].length() - _start);
//         for (uint i = _start; i < collectionTrustWorthyAuditors[addressToCollectionId[_collection]].length(); i++) {
//             _auditors[i] = collectionTrustWorthyAuditors[addressToCollectionId[_collection]].at(i);
//         }
//     }

//     function isCollectionTrustWorthyAuditor(uint _collectionId, address _auditor) external view returns(bool) {
//         return collectionTrustWorthyAuditors[_collectionId].contains(_auditor);
//     }

//     function updateBlacklist(address[] memory _users, bool _add) 
//     external onlyChangeMinCosigners(msg.sender, 0) {
//         for (uint i = 0; i < _users.length; i++) {
//             isBlacklisted[_users[i]] = _add;
//         }
//     }

//     function getCollection(uint _collectionId) external view returns(Collection memory) {
//         return _collections[_collectionId];
//     }

//     /**
//      * @notice Add a new collection
//      * @param _referrerFee: referrer fee
//      */
//     function addCollection(
//         uint _referrerFee,
//         uint _badgeId,
//         uint _minBounty,
//         uint _userMinBounty,
//         uint _recurringBounty,
//         uint _identityTokenId,
//         address _baseToken,
//         bool _requestUserRegistration,
//         bool _requestPartnerRegistration
//     ) external {
//         checkIdentityProof(msg.sender, _identityTokenId, true);
//         require(!isBlacklisted[msg.sender], "Blacklisted!");
//         require(addressToCollectionId[msg.sender] == 0, "Operations: Collection already listed");
//         require(_referrerFee + lotteryFee + tradingFee <= 10000, "Invalid referrerFee");
//         if (_badgeId > 0) require(ve(badgeNft).ownerOf(_badgeId) == msg.sender);
//         addressToCollectionId[msg.sender] = collectionId;
//         _collectionAddressSet.add(collectionId);
//         _collections[collectionId] = Collection({
//             status: Status.Open,
//             tradingFee: tradingFee,
//             referrerFee: _referrerFee,
//             owner: msg.sender,
//             badgeId: _badgeId,
//             recurringBounty: _recurringBounty,
//             minBounty: _minBounty,
//             userMinBounty: _userMinBounty,
//             baseToken: _baseToken,
//             requestUserRegistration: _requestUserRegistration,
//             requestPartnerRegistration: _requestPartnerRegistration,
//             userIdentityProof: IdentityProof({
//                 minIDBadgeColor: COLOR.BLACK,
//                 valueName: "",
//                 requiredIndentity: "",
//                 onlyTrustWorthyAuditors: false,
//                 uniqueAccounts: false
//             }),
//             partnerIdentityProof: IdentityProof({
//                 minIDBadgeColor: COLOR.BLACK,
//                 valueName: "",
//                 requiredIndentity: "",
//                 onlyTrustWorthyAuditors: false,
//                 uniqueAccounts: false
//             })
//         });

//         IMarketPlace(marketPlaceEvents).
//         emitCollectionNew(
//             collectionId++, 
//             msg.sender, 
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

//     function updateCollection(
//         string memory name, 
//         string memory description, 
//         string memory large,
//         string memory small,
//         string memory avatar,
//         string[] memory contactChannels,
//         string[] memory contacts,
//         string[] memory workspaces,
//         string[] memory countries,
//         string[] memory cities,
//         string[] memory products
//     ) external {
//         IMarketPlace(marketPlaceEvents).
//         emitUpdateCollection(
//             addressToCollectionId[msg.sender],
//             name,
//             description,
//             large,
//             small,
//             avatar,
//             contactChannels,
//             contacts,
//             workspaces,
//             countries,
//             cities,
//             products
//         );
//     }

//     function emitReview(
//         uint _collectionId,
//         string memory tokenId,
//         uint userTokenId,
//         bool superLike,
//         string memory review
//     ) external {
//         uint vp;
//         if (userTokenId > 0) {
//             Ask memory ask = IMarketPlace(marketOrders).getAskDetails(_collectionId, keccak256(abi.encodePacked(tokenId)));
//             require(ve(ask.tokenInfo.ve).ownerOf(userTokenId) == msg.sender);
//             vp = ve(ask.tokenInfo.ve).balanceOfNFT(userTokenId);
//         }
//         IMarketPlace(marketPlaceEvents).
//         emitReview(
//             _collectionId,
//             tokenId,
//             userTokenId,
//             vp,
//             superLike,
//             review,
//             msg.sender
//         );
//     }

//     function emitAskInfo(
//         string memory tokenId,
//         string memory description,
//         uint[] memory AB,
//         uint ABStart,
//         uint ABPeriod,
//         string[5] memory images,
//         string[] memory behindPaywall,
//         address workspace,
//         string[] memory countries,
//         string[] memory cities,
//         string[] memory products
//     ) external {
//         IMarketPlace(marketOrders).updateVe(
//             addressToCollectionId[msg.sender],
//             tokenId,
//             workspace
//         );
//         IMarketPlace(marketPlaceEvents).
//         emitAskInfo(
//             addressToCollectionId[msg.sender],
//             tokenId,
//             description,
//             AB,
//             ABStart,
//             ABPeriod,
//             images,
//             behindPaywall,
//             workspace,
//             countries,
//             cities,
//             products
//         );
//     }

//     /**
//      * @notice Modify collection characteristics
//      * @param _referrerFee: referrer fee
//      */
//     function modifyCollection(
//         address _collection,
//         uint256 _referrerFee,
//         uint _badgeId,
//         uint _minBounty,
//         uint _userMinBounty,
//         uint _recurringBounty,
//         bool _requestUserRegistration,
//         bool _requestPartnerRegistration
//     ) external {
//         require(!isBlacklisted[msg.sender] && !isBlacklisted[_collection], "Blacklisted!");
//         require(_referrerFee + lotteryFee + tradingFee <= 10000, "Invalid referrerFee");
//         require(addressToCollectionId[msg.sender] > 0, "Operations: Collection not listed");
//         // require(ve(badgeNft).ownerOf(_badgeId) == _collection);
//         if (_collection != msg.sender) {
//             require(addressToCollectionId[_collection] == 0, "Operations: Collection already listed");
//             addressToCollectionId[_collection] = addressToCollectionId[msg.sender];
//             delete addressToCollectionId[msg.sender];
//         }
//         _collections[addressToCollectionId[_collection]].status = Status.Open;
//         _collections[addressToCollectionId[_collection]].owner = _collection;
//         _collections[addressToCollectionId[_collection]].tradingFee = tradingFee;
//         _collections[addressToCollectionId[_collection]].badgeId = _badgeId;
//         _collections[addressToCollectionId[_collection]].minBounty = _minBounty;
//         _collections[addressToCollectionId[_collection]].userMinBounty = _userMinBounty;
//         _collections[addressToCollectionId[_collection]].referrerFee = _referrerFee;
//         _collections[addressToCollectionId[_collection]].recurringBounty = _recurringBounty;
//         _collections[addressToCollectionId[_collection]].requestUserRegistration = _requestUserRegistration;
//         _collections[addressToCollectionId[_collection]].requestPartnerRegistration = _requestPartnerRegistration;

//         IMarketPlace(marketPlaceEvents).
//         emitCollectionUpdate(
//             addressToCollectionId[_collection],
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

//     function modifyIdentityProof(
//         address _collection,
//         string memory _requiredIndentity,
//         string memory _valueName,
//         bool _onlyTrustWorthyAuditors,
//         bool _uniqueAccounts,
//         bool _isUserIdentity,
//         COLOR _minIDBadgeColor
//     ) external {
//         require(!isBlacklisted[msg.sender] && !isBlacklisted[_collection], "Blacklisted!");
//         require(addressToCollectionId[msg.sender] > 0, "Operations: Collection not listed");

//         if (_isUserIdentity) {
//             _collections[addressToCollectionId[_collection]].userIdentityProof.requiredIndentity = _requiredIndentity;
//             _collections[addressToCollectionId[_collection]].userIdentityProof.minIDBadgeColor = _minIDBadgeColor;
//             _collections[addressToCollectionId[_collection]].userIdentityProof.valueName = _valueName;
//             _collections[addressToCollectionId[_collection]].userIdentityProof.uniqueAccounts = _uniqueAccounts;
//             _collections[addressToCollectionId[_collection]].userIdentityProof.onlyTrustWorthyAuditors = _onlyTrustWorthyAuditors;
//         } else {
//             _collections[addressToCollectionId[_collection]].partnerIdentityProof.requiredIndentity = _requiredIndentity;
//             _collections[addressToCollectionId[_collection]].partnerIdentityProof.minIDBadgeColor = _minIDBadgeColor;
//             _collections[addressToCollectionId[_collection]].partnerIdentityProof.valueName = _valueName;
//             _collections[addressToCollectionId[_collection]].partnerIdentityProof.uniqueAccounts = _uniqueAccounts;
//             _collections[addressToCollectionId[_collection]].partnerIdentityProof.onlyTrustWorthyAuditors = _onlyTrustWorthyAuditors;
//         }
//         IMarketPlace(marketPlaceEvents).
//         emitCollectionUpdateIdentity(
//             addressToCollectionId[_collection],
//             _requiredIndentity,
//             _valueName,
//             _onlyTrustWorthyAuditors,
//             _uniqueAccounts,
//             _isUserIdentity,
//             _minIDBadgeColor
//         );
//     }

//     /**
//      * @notice Allows the admin to close collection for trading and new listing
//      * @param _collection: collection address
//      * @dev Callable by admin
//      */
//     function closeCollectionForTradingAndListing(address _collection) external onlyChangeMinCosigners(msg.sender, 0) {
//         require(addressToCollectionId[_collection] != 0, "Operations: Collection not listed");

//         _collections[addressToCollectionId[_collection]].status = Status.Close;
//         _collectionAddressSet.remove(addressToCollectionId[_collection]);
//         delete addressToCollectionId[_collection];

//         IMarketPlace(marketPlaceEvents).
//         emitCollectionClose(addressToCollectionId[_collection]);
//     }

//     function updateTradingFeeNTimeBuffer(
//         uint256 _tradingFee,
//         uint256 _lotteryFee,
//         uint256 _maximumArrayLength
//     ) external onlyAdmin {
//         tradingFee = _tradingFee;
//         lotteryFee = _lotteryFee;
//         maximumArrayLength = _maximumArrayLength;
//     }

//     /**
//      * @notice Set admin address
//      * @dev Only callable by owner
//      */
//     function setLotteryAddresses(
//         address _lotteryAddress
//     ) external {
//         require(devaddr_ == msg.sender);
//         lotteryAddress = _lotteryAddress;
//     }
// }
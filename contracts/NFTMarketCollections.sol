// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;
// pragma experimental ABIEncoderV2;

// import './Library.sol';

// // File: contracts/ERC721NFTMarketV1.sol

// contract NFTMarketPlace is Auth, ERC721Holder {
//     using EnumerableSet for EnumerableSet.AddressSet;
//     using EnumerableSet for EnumerableSet.UintSet;

//     using SafeERC20 for IERC20;

//     struct Collection {
//         Status status; // status of the collection
//         address creatorAddress; // address of the creator
//         address merchant;
//         address tokenMinter;
//         address whitelistChecker; // whitelist checker (if not set --> 0x00)
//         uint256 tradingFee; // trading fee (100 = 1%, 500 = 5%, 5 = 0.05%)
//         uint256 creatorFee; // creator fee (100 = 1%, 500 = 5%, 5 = 0.05%)
//         uint256 referrerFee; // creator fee (100 = 1%, 500 = 5%, 5 = 0.05%)
//         uint256 minBounty;
//         uint256 badgeId;
//         uint256 recurringBounty;
//         address rsrcCollection;
//         uint256[] rsrcTokenIds;
//     }
//     EnumerableSet.UintSet private _collectionAddressSet;
//     EnumerableSet.AddressSet private _rsrcCollectionAddressSet;

//     mapping(uint => Collection) public _collections; // Details about the collections
//     mapping(uint => EnumerableSet.AddressSet) private collectionTrustWorthyAuditors;
//     mapping(address => uint) public addressToCollectionId;

//     address public adminAddress;
//     address public treasuryAddress;
//     address public lotteryAddress;
//     uint public collectionId = 1;
//     uint256 public minimumAskPrice; // in wei
//     uint256 public maximumAskPrice; // in wei
//     uint public maximumArrayLength;
//     uint256 public tradingFee;
//     uint256 public lotteryFee;
//     address public nft_;
//     address private badgeNft;
//     mapping(address => bool) public isBlacklisted;
//     uint public maxDropinTimer = 86400;
//     uint public cashbackBuffer;
//     uint256 public timeBuffer;
//     uint public maximumLoanDuration = type(uint).max;
//     uint public maximumInterestRate = 10000;

//     // Collection is closed for trading and new listings
//     event CollectionClose(address indexed collection);

//     // Admin and Treasury Addresses are updated
//     event NewAdminAndTreasuryAddresses(address indexed admin, address indexed treasury);

//     // Minimum/maximum ask prices are updated
//     event NewMinimumAndMaximumAskPrices(uint256 minimumAskPrice, uint256 maximumAskPrice);

//     // New collection is added
//     event CollectionNew(
//         address indexed collection,
//         address indexed creator,
//         address indexed whitelistChecker,
//         uint256 tradingFee,
//         uint256 creatorFee
//     );

//     // Existing collection is updated
//     event CollectionUpdate(
//         address indexed collection,
//         address indexed creator,
//         address indexed whitelistChecker,
//         uint256 tradingFee,
//         uint256 creatorFee
//     );

//     /**
//      * @notice Constructor
//      * @param _adminAddress: address of the admin
//      * @param _superLikeGaugeFactory: maximum ask price
//      */
//     constructor(
//         address _nft,
//         address _adminAddress,
//         address _treasuryAddress,
//         address _helper,
//         address _badgeNft,
//         uint256 _minimumAskPrice,
//         uint256 _maximumAskPrice,
//         address _superLikeGaugeFactory
//     ) Auth(_helper, _adminAddress, _superLikeGaugeFactory){
//         require(_adminAddress != address(0), "Operations: Admin address cannot be zero");
//         require(_treasuryAddress != address(0), "Operations: Treasury address cannot be zero");

//         adminAddress = _adminAddress;
//         treasuryAddress = _treasuryAddress;
//         nft_ = _nft;
//         badgeNft = _badgeNft;
//         minimumAskPrice = _minimumAskPrice;
//         maximumAskPrice = _maximumAskPrice;
//     }

//     // simple re-entrancy check
//     uint internal _unlocked = 1;
//     modifier lock() {
//         require(_unlocked == 1);
//         _unlocked = 2;
//         _;
//         _unlocked = 1;
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

//     function isCollectionTrustWorthyAuditor(uint _collectionId, address _auditor) external view returns(bool) {
//         return collectionTrustWorthyAuditors[_collectionId].contains(_auditor);
//     }

//     function updateBlacklist(address[] memory _users, bool _add) 
//     external onlyChangeMinCosigners(msg.sender, 0) {
//         for (uint i = 0; i < _users.length; i++) {
//             isBlacklisted[_users[i]] = _add;
//         }
//     }

//     function addResourceCollection(address _rsrcCollection) external onlyChangeMinCosigners(msg.sender, 0) {
//         if (!_rsrcCollectionAddressSet.contains(_rsrcCollection)) {
//             _rsrcCollectionAddressSet.add(_rsrcCollection);
//         }
//     }

//     function removeResourceCollection(address _rsrcCollection) external onlyChangeMinCosigners(msg.sender, 0) {
//         if (_rsrcCollectionAddressSet.contains(_rsrcCollection)) {
//             _rsrcCollectionAddressSet.remove(_rsrcCollection);
//         }
//     }

//     function setAuctionVariables(
//         uint _timeBuffer,
//         uint maxDuration, 
//         uint maxInterestRate,
//         uint _newMaxDropinTimer,
//         uint _cashbackBuffer
//     ) external onlyAdmin {
//         timeBuffer = _timeBuffer;
//         maximumInterestRate = maxInterestRate;
//         maximumLoanDuration = maxDuration == 0 ? type(uint).max : maxDuration;
//         maxDropinTimer = _newMaxDropinTimer;
//         cashbackBuffer = _cashbackBuffer;
//     }

//     /**
//      * @notice Add a new collection
//      * @param _collection: collection address
//      * @param _creator: creator address (must be 0x00 if none)
//      * @param _whitelistChecker: whitelist checker (for additional restrictions, must be 0x00 if none)
//      * @param _creatorFee: creator fee (100 = 1%, 500 = 5%, 5 = 0.05%, 0 if creator is 0x00)
//      * @dev Callable by admin
//      */
//     function addCollection(
//         address _collection,
//         address _creator,
//         address _tokenMinter,
//         address _whitelistChecker,
//         uint256 _creatorFee,
//         uint256 _referrerFee,
//         address _rsrcCollection,
//         uint256[] memory _rsrcTokenIds,
//         uint _minBounty,
//         uint _badgeId,
//         uint _recurringBounty
//     ) external {
//         require(!isBlacklisted[msg.sender], "Blacklisted!");
//         require(addressToCollectionId[msg.sender] != 0, "Operations: Collection already listed");
//         require(_rsrcCollectionAddressSet.contains(_rsrcCollection), "Operations: Not a resource Collection");
//         // require(IERC721(_collection).supportsInterface(0x80ac58cd), "Operations: Not ERC721");
//         require(_referrerFee + lotteryFee + tradingFee + _creatorFee <= 10000, "Invalid referrerFee");
//         require(ve(badgeNft).ownerOf(_badgeId) == msg.sender);
        
//         // Needed to be able to mine from here
//         if (_tokenMinter != address(0x0)) {
//             (,,address _gauge 
//             ) = ISuperLikeGaugeFactory(superLikeGaugeFactory).getIdentityValue(_tokenMinter, 'tokenMinter');
//             require(isTrustWorthyAuditor(_gauge), "ID Gauge inelligible");
//         }
//         addressToCollectionId[msg.sender] = collectionId;
//         _collectionAddressSet.add(collectionId);
//         // Transfer resource NFT from buyer to contract
//         _rsrcBatchTransferCollection(
//             _rsrcCollection, 
//             msg.sender, 
//             address(this),
//             _rsrcTokenIds
//         );

//         _collections[collectionId++] = Collection({
//             status: Status.Open,
//             creatorAddress: _creator,
//             merchant: msg.sender,
//             tokenMinter: _tokenMinter,
//             whitelistChecker: _whitelistChecker,
//             tradingFee: tradingFee,
//             creatorFee: _creatorFee,
//             referrerFee: _referrerFee,
//             rsrcCollection: _rsrcCollection,
//             rsrcTokenIds: _rsrcTokenIds,
//             recurringBounty: _recurringBounty,
//             badgeId: _badgeId,
//             minBounty: _minBounty
//         });

//         emit CollectionNew(_collection, _creator, _whitelistChecker, tradingFee, _creatorFee);
//     }

//         /**
//      * @notice Modify collection characteristics
//      * @param _collection: collection address
//      * @param _creator: creator address (must be 0x00 if none)
//      * @param _whitelistChecker: whitelist checker (for additional restrictions, must be 0x00 if none)
//      * @param _creatorFee: creator fee (100 = 1%, 500 = 5%, 5 = 0.05%, 0 if creator is 0x00)
//      * @dev Callable by admin
//      */
//     function modifyCollection(
//         address _collection,
//         address _merchant,
//         address _creator,
//         address _tokenMinter,
//         address _whitelistChecker,
//         uint256 _creatorFee,
//         uint256 _referrerFee,
//         uint256 _badgeId,
//         uint _recurringBounty,
//         address _rsrcCollection,
//         uint256[] memory _rsrcTokenIds
//     ) external {
//         require(!isBlacklisted[msg.sender] && !isBlacklisted[_collection] && !isBlacklisted[_merchant], "Blacklisted!");
//         require(_referrerFee + lotteryFee + tradingFee + _creatorFee <= 10000, "Invalid referrerFee");
//         require(addressToCollectionId[msg.sender] > 0, "Operations: Collection not listed");
//         require(ve(badgeNft).ownerOf(_badgeId) == _collection);
//         require(_rsrcCollectionAddressSet.contains(_rsrcCollection) || 
//         _rsrcCollection == address(0x0), "Operations: Not a resource Collection");
//         if (_merchant != msg.sender) {
//             require(addressToCollectionId[_merchant] == 0, "Operations: Collection already listed");
//             addressToCollectionId[_merchant] = addressToCollectionId[msg.sender];
//             delete addressToCollectionId[msg.sender];
//         }
//         // Needed to be able to mine from here
//         if (_tokenMinter != address(0x0)) {
//             (,,address _gauge 
//             ) = ISuperLikeGaugeFactory(superLikeGaugeFactory).getIdentityValue(_tokenMinter, 'tokenMinter');
//             require(isTrustWorthyAuditor(_gauge), "ID Gauge inelligible");
//         }
//         if (_rsrcCollection != address(0x0)) {
//             // Transfer resource NFT from contract to buyer
//             _rsrcBatchTransferCollection(
//                 _collections[addressToCollectionId[_merchant]].rsrcCollection, 
//                 address(this),
//                 msg.sender,
//                 _collections[addressToCollectionId[_merchant]].rsrcTokenIds
//             );
//             // Transfer resource NFT from buyer to contract
//             _rsrcBatchTransferCollection(
//                 _rsrcCollection, 
//                 msg.sender, 
//                 address(this),
//                 _rsrcTokenIds 
//             );
            
//             _collections[addressToCollectionId[_merchant]].rsrcCollection = _rsrcCollection;
//             _collections[addressToCollectionId[_merchant]].rsrcTokenIds = _rsrcTokenIds;
//         } 
//         if (_tokenMinter != address(0x0)) {
//             require(Ownable(_collection).owner() == address(this), "Transfer ownership to contract first");
//             _collections[addressToCollectionId[_merchant]].tokenMinter = _tokenMinter; 
//         }
//         _collections[addressToCollectionId[_merchant]].status = Status.Open;
//         _collections[addressToCollectionId[_merchant]].creatorAddress = _creator;
//         _collections[addressToCollectionId[_merchant]].tokenMinter = _tokenMinter;
//         _collections[addressToCollectionId[_merchant]].whitelistChecker = _whitelistChecker;
//         _collections[addressToCollectionId[_merchant]].tradingFee = tradingFee;
//         _collections[addressToCollectionId[_merchant]].badgeId = _badgeId;
//         _collections[addressToCollectionId[_merchant]].creatorFee = _creatorFee;
//         _collections[addressToCollectionId[_merchant]].referrerFee = _referrerFee;
//         _collections[addressToCollectionId[_merchant]].recurringBounty = _recurringBounty;

//         emit CollectionUpdate(_collection, _creator, _whitelistChecker, tradingFee, _creatorFee);
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

//         emit CollectionClose(_collection);
//     }
    
//     function _rsrcBatchTransferCollection(
//         address _collection, 
//         address _from,
//         address _to,    
//         uint[] memory _ids
//     ) public {
//         if (_ids.length == 0) return;
        
//         uint[] memory _amounts = new uint[](_ids.length);
//         for (uint i = 0; i < _ids.length; i++) {
//             if(IRSRC(_collection).balanceOf(_from, _ids[i]) > 0){
//                 _amounts[i] = 1;
//             }
//             if (INaturalResourceNFT(_collection).attached(_ids[i]) && 
//                 INaturalResourceNFT(_collection).getTicketOwner(_ids[i]) == address(this)
//             ) {
//                 INaturalResourceNFT(_collection).detach(_ids[i]); 
//             }
//         }
//         IRSRC(_collection).safeBatchTransferFrom(_from, _to, _ids, _amounts, msg.data);

//         if (_from == address(this)) {
//             INaturalResourceNFT(_collection).batchDetach(_ids);
//         } else { 
//             INaturalResourceNFT(_collection).batchAttach(_ids, 0, msg.sender);
//         }
//     }

//     /**
//      * @notice Allows the admin to update minimum and maximum prices for a token (in wei)
//      * @param _minimumAskPrice: minimum ask price
//      * @param _maximumAskPrice: maximum ask price
//      * @dev Callable by admin
//      */
//     function updateMinimumAndMaximumPrices(
//         uint256 _minimumAskPrice, 
//         uint256 _maximumAskPrice,
//         uint256 _maximumArrayLength
//     ) external onlyAdmin {
//         require(_minimumAskPrice < _maximumAskPrice, "Operations: _minimumAskPrice < _maximumAskPrice");

//         minimumAskPrice = _minimumAskPrice;
//         maximumAskPrice = _maximumAskPrice;
//         maximumArrayLength = _maximumArrayLength;
        
//         emit NewMinimumAndMaximumAskPrices(_minimumAskPrice, _maximumAskPrice);
//     }

//     function updateTradingFeeNTimeBuffer(
//         uint256 _lotteryFee,
//         uint256 _tradingFee
//     ) external onlyAdmin {
//         tradingFee = _tradingFee;
//         lotteryFee = _lotteryFee;
//     }

//     /**
//      * @notice Set admin address
//      * @dev Only callable by owner
//      * @param _adminAddress: address of the admin
//      * @param _treasuryAddress: address of the treasury
//      */
//     function setAdminAndTreasuryAddresses(
//         address _adminAddress, 
//         address _lotteryAddress,
//         address _treasuryAddress
//     ) external onlyAdmin {
//         require(_adminAddress != address(0), "Operations: Admin address cannot be zero");
//         require(_treasuryAddress != address(0), "Operations: Treasury address cannot be zero");
//         require(_lotteryAddress != address(0), "Operations: Treasury address cannot be zero");
//         adminAddress = _adminAddress;
//         lotteryAddress = _lotteryAddress;
//         treasuryAddress = _treasuryAddress;

//         emit NewAdminAndTreasuryAddresses(_adminAddress, _treasuryAddress);
//     }

//     function getAllCollectionTrustWorthyAuditors(address _collection) external view returns(address[] memory _auditors) {
//         _auditors = new address[](collectionTrustWorthyAuditors[addressToCollectionId[_collection]].length());
//         for (uint i = 0; i < collectionTrustWorthyAuditors[addressToCollectionId[_collection]].length(); i++) {
//             _auditors[i] = collectionTrustWorthyAuditors[addressToCollectionId[_collection]].at(i);
//         }
//     }

//     function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
//         return this.onERC1155Received.selector;
//     }

//     function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
//         return this.onERC1155BatchReceived.selector;
//     }

//     /*
//      * @notice View addresses and details for all the collections available for trading
//      * @param cursor: cursor
//      * @param size: size of the response
//      */
//     function viewCollections(uint256 cursor, uint256 size)
//         external
//         view
//         returns (
//             uint[] memory collectionAddresses,
//             Collection[] memory collectionDetails,
//             uint256
//         )
//     {
//         uint256 length = size;

//         if (length > _collectionAddressSet.length() - cursor) {
//             length = _collectionAddressSet.length() - cursor;
//         }

//         collectionAddresses = new uint[](length);
//         collectionDetails = new Collection[](length);

//         for (uint256 i = 0; i < length; i++) {
//             collectionAddresses[i] = _collectionAddressSet.at(cursor + i);
//             collectionDetails[i] = _collections[collectionAddresses[i]];
//         }

//         return (collectionAddresses, collectionDetails, cursor + length);
//     }
// }
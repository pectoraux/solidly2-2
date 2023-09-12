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

// contract MarketPlaceHelper {
//     using SafeERC20 for IERC20;
//     using EnumerableSet for EnumerableSet.AddressSet;

//     address private businessVoter;
//     address private referralVoter;
//     mapping(uint => mapping(string => uint)) public lotteryCredits;
//     address private marketTrades;
//     address private marketOrders;
//     address private marketCollections;
//     address private marketPlaceEvents;
//     mapping(uint => mapping(string => Option[])) public options;
//     mapping(uint => mapping(address => uint)) public burnTokenForCredit;
//     EnumerableSet.AddressSet internal _dtokenSet;
//     EnumerableSet.AddressSet internal _veTokenSet;
//     // The minimum amount of time left in an auction after a new bid is created
//     address private profile;
//     uint256 private timeBuffer;
    
//     /**
//      * @notice Constructor
//      * @param _marketCollections: address of the admin
//      * @param _marketOrders: address of the treasury
//      */
//     constructor(
//         address _marketCollections,
//         address _marketPlaceEvents,
//         address _marketOrders,
//         address _profile
//     ) {
//         marketCollections = _marketCollections;
//         marketPlaceEvents = _marketPlaceEvents;
//         marketOrders = _marketOrders;
//         profile = _profile;
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
//         require(IAuth(marketCollections).isAdmin(msg.sender));
//         _;
//     }

//     function setMarketTrades(address _marketTrades) external onlyAdmin {
//         marketTrades = _marketTrades;
//     }

//     // function getContracts() external view returns(address,address,address,address) {
//     //     return (marketCollections, marketPlaceEvents, marketOrders, marketTrades);
//     // }

//     function beforePaymentApplyOptions(
//         uint _collectionId, 
//         string memory _tokenId,
//         uint[] memory _options
//     ) internal view returns(uint price) {
//         for (uint i = 0; i < _options.length; i++) {
//             price += options[_collectionId][_tokenId][_options[i]].unitPrice;
//         }
//     }

//     function getRealPrice(
//         address _collection,
//         string memory _tokenId,
//         uint[] memory _options,
//         uint _identityTokenId,
//         uint _price
//     ) external view returns(uint, bool) {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_collection);
//         _price += beforePaymentApplyOptions(_collectionId, _tokenId, _options);
//         uint __price = _beforePaymentApplyDiscount(_collection, msg.sender, _tokenId, _identityTokenId, _price);
//         return (__price, _price != __price);
//     }

//     function _beforePaymentApplyDiscount(
//         address _collection,
//         address _user,
//         string memory _tokenId,
//         uint _identityTokenId,
//         uint _price
//     ) internal view returns(uint) {
//         uint256 discount;
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_collection);
//         Ask memory ask = IMarketPlace(marketOrders).getAskDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
//         Discount memory discountCost = ask.priceReductor.discountCost;
//         Discount memory discountNumbers = ask.priceReductor.discountNumbers;
//         string memory cid = string(abi.encodePacked(_collectionId, _tokenId));

//         if (ask.priceReductor.discountStatus == Status.Open &&
//             ask.priceReductor.discountStart <= block.timestamp
//         ) {
//             if (ask.priceReductor.checkIdentityCode) {
//                 address ssi = IMarketPlace(marketCollections).ssi();
//                 SSIData memory metadata = ISSI(ssi).getSSIData(_identityTokenId);
//                 (string memory _ssid,) = ISSI(ssi).getSSID(metadata.senderProfileId);
//                 if(
//                     IMarketPlace(marketTrades).identityLimits(cid, keccak256(abi.encodePacked(_ssid))) 
//                     >= Math.max(discountCost.limit, discountNumbers.limit) ||
//                     keccak256(abi.encodePacked(_ssid)) == keccak256(abi.encodePacked(""))
//                 ) {
//                     return _price;
//                 }
//             } else if (IMarketPlace(marketTrades).discountLimits(cid, _user) >= Math.max(discountCost.limit, discountNumbers.limit)){
//                 return _price;
//             }
//             discount = _getDiscount(_collection, _user, _tokenId);
//         }
//         uint256 costWithDiscount = discount == 0 ? _price : _price-_price*discount/10000;
//         return costWithDiscount;
//     }

//     function _getDiscount(
//         address _collection,
//         address _user, 
//         string memory _tokenId 
//     ) internal view returns(uint _discount) {
//         address nft_ = IMarketPlace(marketCollections).nft_();
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_collection);
//         Ask memory ask = IMarketPlace(marketOrders).getAskDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
//         Discount memory discountCost = ask.priceReductor.discountCost;
//         Discount memory discountNumbers = ask.priceReductor.discountNumbers;
//         (uint256[] memory values1,) = INFTicket(nft_).getUserTicketsPagination(
//             _user, 
//             _collectionId, 
//             discountNumbers.cursor,
//             discountNumbers.size
//         );
//         (,uint256 totalPrice2) = INFTicket(nft_).getUserTicketsPagination(
//             _user, 
//             _collectionId, 
//             discountCost.cursor,
//             discountCost.size
//         );
//         if (values1.length >= discountNumbers.lowerThreshold && 
//             values1.length <= discountNumbers.upperThreshold
//         ) {
//             _discount += discountNumbers.perct;
//             if (totalPrice2 >= discountCost.lowerThreshold && 
//                 totalPrice2 <= discountCost.upperThreshold
//             )
//                 {
//                 _discount += discountCost.perct;
//             }
//         }
//     }

//     // /**
//     //  * @notice Allows the owner to recover tokens sent to the contract by mistake
//     //  * @param _token: token address
//     //  * @dev Callable by owner
//     //  */
//     // function recoverFungibleTokens(address _token, uint amountToRecover) external {
//     //     require(marketCollections == msg.sender);
//     //     IERC20(_token).safeTransfer(address(msg.sender), amountToRecover);
//     // }

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

//     function checkAuction(
//         uint256 _price,
//         address _collection,
//         address _user,
//         string memory _tokenId
//     ) external {
//         require(marketTrades == msg.sender);
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_collection);
//         Ask memory ask = IMarketPlace(marketOrders).getAskDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
//         require(ask.lastBidTime == 0 || ask.lastBidTime + ask.bidDuration > block.timestamp);
//         uint _askPrice = ask.price;
//         if (ask.lastBidTime != 0 && ask.minBidIncrementPercentage > 0) {
//             _price += ask.price * uint(ask.minBidIncrementPercentage) / 10000;
//             _askPrice += ask.price * uint(ask.minBidIncrementPercentage) / 10000;
//         } else if (ask.lastBidTime != 0 && ask.minBidIncrementPercentage < 0) {
//             if (ask.price * uint(-ask.minBidIncrementPercentage) / 10000 > _price) {
//                 _price = 0;
//             } else {
//                 _price -= ask.price * uint(-ask.minBidIncrementPercentage) / 10000;
//             }
//             _askPrice -= ask.price * uint(-ask.minBidIncrementPercentage) / 10000;
//         }
//         // If this is the first valid bid, we should set the starting time now.
//         // If it's not, then we should refund the last bidder
//         address _token = ask.tokenInfo.usetFIAT ? ask.tokenInfo.tFIAT : ve(ask.tokenInfo.ve).token();
//         IERC20(_token).safeTransferFrom(_user, marketTrades, _price);
//         if(ask.lastBidTime != 0) {
//             IERC20(_token).safeTransferFrom(marketTrades, ask.lastBidder, ask.price);
//         }
//         ask.price = _askPrice;
//         ask.lastBidder = _user;
//         ask.lastBidTime = block.timestamp;

//         IMarketPlace(marketOrders).updateAfterSale(
//             _collectionId,
//             _tokenId,
//             ask.price, 
//             ask.lastBidTime,
//             ask.lastBidder
//         );
//     }

//     function processAuction(
//         address _collection,
//         address _referrer,
//         address _user,
//         string memory _tokenId,
//         uint _userTokenId,
//         uint[] memory _options
//     ) external {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_collection);
//         Ask memory ask = IMarketPlace(marketOrders).getAskDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
//         require(ask.lastBidTime + ask.bidDuration <= block.timestamp);
//         require(ask.lastBidder == msg.sender);
//         _processTrade(
//             _collection,
//             _referrer,
//             _user,
//             _tokenId,
//             _userTokenId,
//             ask.price,
//             _options
//         );
//     }

//     function _vote(
//         address _ve, 
//         address _user, 
//         string memory _tokenId, 
//         uint _userTokenId, 
//         uint _collectionId, 
//         uint _tradingFee,
//         uint _lotteryFee 
//     ) internal {
//         // voting
//         address _ssi = IMarketPlace(marketCollections).ssi();
//         if (_ssi != address(0x0) && _userTokenId > 0) {
//             uint _weight = ve(_ve).balanceOfNFT(_userTokenId);
//             uint _referrerProfileId = IProfile(profile).referrerFromAddress(_user);
//             IBusinessVoter(businessVoter).vote(
//                 _userTokenId, 
//                 _collectionId, 
//                 _referrerProfileId,
//                 _weight > 0 ? _weight : _tradingFee,
//                 _ve, 
//                 _user,
//                 _weight > 0
//             );
//             lotteryCredits[_collectionId][_tokenId] += _lotteryFee;
//             // if user has been referred
//             if (_referrerProfileId > 1 && referralVoter != address(0x0)) {
//                 IReferralVoter(referralVoter).vote(
//                     _userTokenId, 
//                     _weight > 0 ? _weight : _tradingFee,
//                     _ve, 
//                     _user,
//                     _weight > 0
//                 );
//             }
//         }
//     }

//     function mintNFTicket(address _user, string memory _tokenId, uint[] memory _options) external {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         IMarketPlace(marketOrders).decrementMaxSupply(_collectionId, keccak256(abi.encodePacked(_tokenId)));
//         _mintNFTicket(_user, _collectionId, _tokenId, _options, true);
//     }

//     function _mintNFTicket(address _user, uint _collectionId, string memory _tokenId, uint[] memory _options, bool _external) internal returns(uint nfTicketID) {
//         // Mint NFTicket to buyer
//         Ask memory ask = IMarketPlace(marketOrders).getAskDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
//         nfTicketID = INFTicket(IMarketPlace(marketCollections).nft_()).mint(_user,_collectionId,ask.price,_tokenId,_options, _external);
//     }

//     function updateVoterNGaugeFactory(
//         address _businessVoter,
//         address _referralVoter,
//         uint _timeBuffer
//     ) external {
//         require(IAuth(marketCollections).devaddr_() == msg.sender);
//         timeBuffer = _timeBuffer;
//         businessVoter = _businessVoter;
//         referralVoter = _referralVoter;
//     }

//     function processTrade(
//         address _collection,
//         address _referrer,
//         address _user,
//         string memory _tokenId,
//         uint _userTokenId,
//         uint _price,
//         uint[] memory _options
//     ) external {
//         require(marketTrades == msg.sender);
//         _processTrade(
//             _collection,
//             _referrer,
//             _user,
//             _tokenId,
//             _userTokenId,
//             _price,
//             _options
//         );
//     }

//     function _processTrade(
//         address _collection,
//         address _referrer,
//         address _user,
//         string memory _tokenId,
//         uint _userTokenId,
//         uint _price,
//         uint[] memory _options
//     ) internal {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_collection);
//         Ask memory ask = IMarketPlace(marketOrders).getAskDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
//         // require(ask.seller != _user);
//         _processTx(
//             _collection,
//             _referrer,
//             _user,
//             _tokenId,
//             _price,
//             ask
//         );
//         (uint256 netPrice, uint256 _tradingFee, uint256 _lotteryFee,,,) = 
//         _calculatePriceAndFeesForCollection(
//             _collection,
//             _referrer,
//             _tokenId,
//             _price
//         );
//         uint nfTicketID = _mintNFTicket(_user, _collectionId, _tokenId, _options, false);
//         _vote(
//             ask.tokenInfo.ve, 
//             _user, 
//             _tokenId, 
//             _userTokenId, 
//             _collectionId, 
//             _tradingFee,
//             _lotteryFee
//         );
//         IMarketPlace(marketPlaceEvents).
//         emitTrade(_collectionId, _tokenId, ask.seller, _user, _price, netPrice, nfTicketID);
//     }

//     function updateBurnTokenForCredit(address _token, uint256 _discountNumber) external {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         burnTokenForCredit[_collectionId][_token] = _discountNumber;
//     }

//     function burnForCredit(
//         address _collection, 
//         address _token, 
//         uint256 _number,  // tokenId in case of NFTs and amount otherwise 
//         string memory _applyToTokenId
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
//         if (!_isNFT) {
//             IERC20(_token).safeTransferFrom(msg.sender, marketTrades, _number);
//         } else {
//             IERC721(_token).safeTransferFrom(msg.sender, _collection, _number);
//         }
//         uint credit = _isNFT ? discount * 1 / 10000 : discount * _number / 10000;
//         IMarketPlace(marketOrders).
//         incrementPaymentCredits(msg.sender, _collectionId, _applyToTokenId, credit);
//     }

//     function updateOptions(
//         string memory _tokenId,
//         uint[] memory _mins,
//         uint[] memory _maxs,
//         uint[] memory _unitPrices,
//         string[] memory _categories,
//         string[] memory _elements,
//         string[] memory _traitTypes,
//         string[] memory _values,
//         string[] memory _currencies
//     ) external {
//         // Verify collection is accepted
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         Collection memory _collection = IMarketPlace(marketCollections).getCollection(_collectionId);
//         require(_collection.status == Status.Open);
//         require(_mins.length <= IMarketPlace(marketCollections).maximumArrayLength());
//         // require(_mins.length == _maxs.length);
//         // require(_maxs.length == _unitPrices.length);
//         // require(_unitPrices.length == _categories.length);
//         // require(_categories.length == _elements.length);
//         // require(_elements.length == _traitTypes.length);
//         // require(_traitTypes.length == _values.length);
//         // require(_values.length == _currencies.length);
        
//         if (options[_collectionId][_tokenId].length > 0) {
//             delete options[_collectionId][_tokenId];
//         } 
//         for (uint i = 0; i < _mins.length; i++) {
//             options[_collectionId][_tokenId].push(Option({
//                 id: i,
//                 min: _mins[i],
//                 max: _maxs[i],
//                 unitPrice: _unitPrices[i],
//                 category: _categories[i],
//                 element: _elements[i],
//                 traitType: _traitTypes[i],
//                 value: _values[i],
//                 currency: _currencies[i]
//             }));
//         }
//         IMarketPlace(marketPlaceEvents).
//         emitUpdateOptions(_collectionId,_tokenId,_mins,_maxs,_unitPrices,_categories,_elements,_traitTypes,_values,_currencies);
//     }

//     function _processTx(
//         address _collection,
//         address _referrer,
//         address _user,
//         string memory _tokenId,
//         uint _price,
//         Ask memory ask
//     ) internal {
//         address _token = ask.tokenInfo.usetFIAT ? ask.tokenInfo.tFIAT : ve(ask.tokenInfo.ve).token();
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_collection);
//         // Calculate the net price (collected by seller), trading fee (collected by treasury), creator fee (collected by creator)
//         (uint256 netPrice, uint256 _tradingFee, uint256 _lotteryFee, uint256 _referrerFee, uint256 _cashbackFee, uint _recurringFee) = 
//         _calculatePriceAndFeesForCollection(
//             _collection,
//             _referrer,
//             _tokenId,
//             _price
//         );
//         // Transfer _token
//         if (ask.tokenInfo.direction == DIRECTION.senderToReceiver || ask.bidDuration != 0) {
//             IMarketPlace(marketTrades).
//             updatePendingRevenue(_token, ask.seller, netPrice, false);
//             IMarketPlace(marketTrades).
//             updateCashbackFund(_token, _collectionId, _cashbackFee, true);
//         } else if (ask.bidDuration == 0) {
//             IMarketPlace(marketTrades).
//             decreasePendingRevenue(_token, _user, _collectionId, _price);
//         }
//         // Update pending revenues for treasury/creator (if any!)
//         if (_referrerFee != 0 && _referrer != address(0x0)) {
//             IMarketPlace(marketTrades).
//             updatePendingRevenue(_token, _referrer, _referrerFee, true);
//         }
//         // Update trading fee if not equal to 0
//         if (_tradingFee != 0) {
//             IMarketPlace(marketTrades).updateTreasuryRevenue(_token, _tradingFee);
//         }
//         if (_lotteryFee != 0) {
//             IMarketPlace(marketTrades).updateLotteryRevenue(_token, _lotteryFee);
//         }
//         if (_recurringFee != 0) {
//             IMarketPlace(marketTrades).updateRecurringBountyRevenue(_token, _collectionId, _recurringFee);
//         }
//         IMarketPlace(marketOrders).decrementMaxSupply(_collectionId, keccak256(abi.encodePacked(_tokenId)));
//     }

//     /**
//      * @notice Calculate price and associated fees for a collection
//      * @param _collection: address of the collection
//      * @param _askPrice: listed price
//      */
//     function _calculatePriceAndFeesForCollection(
//         address _collection, 
//         address _referrer, 
//         string memory _tokenId,
//         uint256 _askPrice
//     )
//         internal
//         view
//         returns (
//             uint256 netPrice,
//             uint256 _tradingFee,
//             uint256 _lotteryFee,
//             uint256 _referrerFee,
//             uint256 _cashbackFee,
//             uint256 _recurringFee
//         )
//     {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_collection);
//         Collection memory __collection = IMarketPlace(marketCollections).getCollection(_collectionId);
//         _tradingFee = (_askPrice * __collection.tradingFee) / 10000;
//         _lotteryFee = (_askPrice * IMarketPlace(marketCollections).lotteryFee()) / 10000;
//         if (_referrer != address(0x0)) {
//             uint _referrerCollectionId = IMarketPlace(marketCollections).addressToCollectionId(_referrer);
//             (,uint _referrerShare,) = IMarketPlace(marketOrders).getReferral(_referrerCollectionId, _tokenId);
//             _referrerFee = (_askPrice * _referrerShare) / 10000;
//             if (__collection.recurringBounty > 0) _recurringFee = (_askPrice * __collection.recurringBounty) / 10000;
//         }
//         Ask memory ask = IMarketPlace(marketOrders).getAskDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
//         netPrice = _askPrice - _tradingFee - _lotteryFee - _referrerFee - _recurringFee;
//         if (ask.priceReductor.cashNotCredit) { 
//             _cashbackFee = netPrice * (ask.priceReductor.cashbackNumbers.perct + ask.priceReductor.cashbackCost.perct) / 10000;
//         }
//         netPrice -= _cashbackFee;
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

//     function addVetoken(address _veToken) external onlyAdmin {
//         if (!_veTokenSet.contains(_veToken)) {
//             _veTokenSet.add(_veToken);
//         }
//     }

//     function removeVetoken(address _veToken) external onlyAdmin {
//         if (_veTokenSet.contains(_veToken)) {
//             _veTokenSet.remove(_veToken);
//         }
//     }

//     function veTokenSetContains(address _veToken) external view returns(bool) {
//         return _veTokenSet.contains(_veToken);
//     }

//     function dTokenSetContains(address _dToken) external view returns(bool) {
//         return _dtokenSet.contains(_dToken);
//     }
// }

// contract MarketPlaceHelper2 is ERC721Pausable {
//     using EnumerableSet for EnumerableSet.UintSet;
//     using Percentile for *; 

//     mapping(bytes32 => mapping(bytes32 => uint)) private identityProofs;
//     mapping(uint => mapping(bytes32 => bool)) private blackListedIdentities;
//     struct CB {
//         uint bufferTime;
//         uint amount;
//     }
//     mapping(uint => mapping(bytes32 => CB)) public cashbackRevenue;
//     address marketCollections;
//     address marketOrders;
//     address auditorNote;
//     address marketHelpers;
//     address marketTrades;
//     address marketEvents;
//     address profile;
//     address badgeNft;
//     EnumerableSet.UintSet private _allVoters;
//     mapping(string => uint) public percentiles;
//     struct Vote {
//         uint likes;
//         uint dislikes;
//     }
//     uint private sum_of_diff_squared;
//     mapping(string => Vote) public  votes;
//     mapping(uint => mapping(string => int)) public voted;
//     mapping(uint => address) public tokenIdToAuditor;

//     /**
//      * @notice Constructor
//      * @param _marketCollections: address of the admin
//      */
//     constructor(
//         address _profile,
//         address _badgeNft,
//         address _auditorNote,
//         address _marketOrders,
//         address _marketHelpers,
//         address _marketEvents,
//         address _marketCollections
//     ) ERC721("CanCanNote", "nCanCan") {
//         profile = _profile;
//         badgeNft = _badgeNft;
//         auditorNote = _auditorNote;
//         marketOrders = _marketOrders;
//         marketHelpers = _marketHelpers;
//         marketEvents = _marketEvents;
//         marketCollections = _marketCollections;
//     }

//     function setMarketTrades(address _marketTrades) external {
//        require(IAuth(marketCollections).isAdmin(msg.sender));
//         marketTrades = _marketTrades;
//     }

//     function checkRequirements(
//         address _ve, 
//         address _user,
//         address _tFIAT, 
//         uint _maxSupply, 
//         uint _dropinTimer,
//         uint _rsrcTokenId
//     ) external view {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_user);
//         Collection memory _collection = IMarketPlace(marketCollections).getCollection(_collectionId);
//         require(_collection.status == Status.Open && _maxSupply != 0);
//         require(_dropinTimer <= IMarketPlace(marketCollections).maxDropinTimer());
//         require(IMarketPlace(marketHelpers).veTokenSetContains(_ve));
//         if (_tFIAT != address(0x0)) {
//             require(IMarketPlace(marketHelpers).dTokenSetContains(_tFIAT));
//         }
//         if (_rsrcTokenId != 0) {
//             require(ve(badgeNft).ownerOf(_rsrcTokenId) == _user);
//         }
//     }

//     function _resetVote(string memory _cid, uint profileId) internal {
//         if (voted[profileId][_cid] > 0) {
//             votes[_cid].likes -= 1;
//         } else if (voted[profileId][_cid] < 0) {
//             votes[_cid].dislikes -= 1;
//         }
//     }

//     function vote(uint _merchant, string memory _tokenId, uint profileId, bool like) external {
//         require(IProfile(profile).addressToProfileId(msg.sender) == profileId);
//         address ssi = IMarketPlace(marketCollections).ssi();
//         (string memory _ssid,) = ISSI(ssi).getSSID(profileId);
//         require(keccak256(abi.encodePacked(_ssid)) != keccak256(abi.encodePacked("")));
//         string memory cid = string(abi.encodePacked(_merchant, _tokenId));
//         _resetVote(cid, profileId);        
//         if (like) {
//             votes[cid].likes += 1;
//             voted[profileId][cid] = 1;
//         } else {
//             votes[cid].dislikes += 1;
//             voted[profileId][cid] = -1;
//         }
//         uint _merchantVotes;
//         if (votes[cid].likes > votes[cid].dislikes) {
//             _merchantVotes = votes[cid].likes - votes[cid].dislikes;
//         }
//         _allVoters.add(profileId);
//         (uint percentile, uint sods) = Percentile.computePercentileFromData(
//             false,
//             _merchantVotes,
//             _allVoters.length(),
//             _allVoters.length(),
//             sum_of_diff_squared
//         );
//         sum_of_diff_squared = sods;
//         percentiles[cid] = percentile;
//         IMarketPlace(marketEvents).
//         emitVoted(_merchant, _tokenId, votes[cid].likes, votes[cid].dislikes, like);
//     }

//     function getColor(uint _collectionId, string memory _tokenId) external view returns(COLOR) {
//         string memory cid = string(abi.encodePacked(_collectionId, _tokenId));
//         if (percentiles[cid] > 75) {
//             return COLOR.GOLD;
//         } else if (percentiles[cid] > 50) {
//             return COLOR.SILVER;
//         } else if (percentiles[cid] > 25) {
//             return COLOR.BROWN;
//         } else {
//             return COLOR.BLACK;
//         }
//     }

//     function checkPartnerIdentityProof(
//         uint _collectionId, 
//         uint _identityTokenId,
//         address _owner
//      ) external {
//         Collection memory _collection = IMarketPlace(marketCollections).getCollection(_collectionId);
//         string memory valueName = _collection.partnerIdentityProof.valueName;
//         string memory requiredIndentity = _collection.partnerIdentityProof.requiredIndentity;
//         bool onlyTrustWorthyAuditors = _collection.partnerIdentityProof.onlyTrustWorthyAuditors;
//         bool uniqueAccounts = _collection.partnerIdentityProof.uniqueAccounts;
//         COLOR minIDBadgeColor = _collection.partnerIdentityProof.minIDBadgeColor;
//         address ssi = IMarketPlace(marketCollections).ssi();
//         _checkIdentityProof(
//             _owner,
//             ssi,
//             _collectionId,
//             _identityTokenId,
//             "partner",
//             valueName,
//             requiredIndentity,
//             onlyTrustWorthyAuditors,
//             uniqueAccounts,
//             minIDBadgeColor
//         );
//     }

//     function checkOrderIdentityProof(
//         uint _collectionId, 
//         uint _identityTokenId,
//         address _owner,
//         string memory _tokenId
//      ) external {
//         Ask memory ask = IMarketPlace(marketOrders).getAskDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
//         string memory valueName = ask.identityProof.valueName;
//         string memory requiredIndentity = ask.identityProof.requiredIndentity;
//         bool onlyTrustWorthyAuditors = ask.identityProof.onlyTrustWorthyAuditors;
//         bool uniqueAccounts = ask.identityProof.uniqueAccounts;
//         COLOR minIDBadgeColor = ask.identityProof.minIDBadgeColor;
//         address ssi = IMarketPlace(marketCollections).ssi();
//         _checkIdentityProof(
//             _owner,
//             ssi,
//             _collectionId,
//             _identityTokenId,
//             _tokenId,
//             valueName,
//             requiredIndentity,
//             onlyTrustWorthyAuditors,
//             uniqueAccounts,
//             minIDBadgeColor
//         );
//     }

//     function checkUserIdentityProof(
//         uint _collectionId, 
//         uint _identityTokenId,
//         address _owner
//      ) external {
//         Collection memory _collection = IMarketPlace(marketCollections).getCollection(_collectionId);
//         string memory valueName = _collection.userIdentityProof.valueName;
//         string memory requiredIndentity = _collection.userIdentityProof.requiredIndentity;
//         bool onlyTrustWorthyAuditors = _collection.userIdentityProof.onlyTrustWorthyAuditors;
//         bool uniqueAccounts = _collection.userIdentityProof.uniqueAccounts;
//         COLOR minIDBadgeColor = _collection.userIdentityProof.minIDBadgeColor;
//         address ssi = IMarketPlace(marketCollections).ssi();
//         _checkIdentityProof(
//             _owner,
//             ssi,
//             _collectionId,
//             _identityTokenId,
//             "register",
//             valueName,
//             requiredIndentity,
//             onlyTrustWorthyAuditors,
//             uniqueAccounts,
//             minIDBadgeColor
//         );
//     } 
    
//     function _checkIdentityProof(
//         address _owner, 
//         address ssi,
//         uint _collectionId, 
//         uint _identityTokenId,
//         string memory _tokenId,
//         string memory valueName,
//         string memory requiredIndentity,
//         bool onlyTrustWorthyAuditors,
//         bool uniqueAccounts,
//         COLOR minIDBadgeColor
//     ) internal {
//         if (keccak256(abi.encodePacked(valueName)) != keccak256(abi.encodePacked(""))) {
//             require(ve(ssi).ownerOf(_identityTokenId) == _owner);
//             SSIData memory metadata = ISSI(ssi).getSSIData(_identityTokenId);
//             require(metadata.deadline > block.timestamp);
//             (string memory _ssid, uint _ssidAuditorId) = ISSI(ssi).getSSID(metadata.senderProfileId);
//             (address gauge, COLOR _badgeColor) = IAuditor(auditorNote).getGaugeNColor(metadata.auditorProfileId);
//             (address gauge2, COLOR _badgeColor2) = IAuditor(auditorNote).getGaugeNColor(_ssidAuditorId);
//             require(_badgeColor >= minIDBadgeColor && _badgeColor2 >= minIDBadgeColor);
//             require(keccak256(abi.encodePacked(metadata.question)) == keccak256(abi.encodePacked(requiredIndentity))); 
//             require(keccak256(abi.encodePacked(metadata.answer)) == keccak256(abi.encodePacked(valueName)));
//             _updateIdentityCode(
//                 _collectionId, 
//                 metadata.senderProfileId, 
//                 _tokenId,
//                 keccak256(abi.encodePacked(_ssid)),
//                 onlyTrustWorthyAuditors,
//                 uniqueAccounts,
//                 gauge,
//                 gauge2
//             );
//         }
//     }

//     function _updateIdentityCode(
//         uint _collectionId, 
//         uint _profileId, 
//         bytes32 _identityCode,
//         string memory _tokenId,
//         bool onlyTrustWorthyAuditors,
//         bool uniqueAccounts,
//         address _gauge,
//         address _gauge2
//     ) internal {
//         require(!onlyTrustWorthyAuditors || (
//             IMarketPlace(marketCollections).isCollectionTrustWorthyAuditor(_collectionId, _gauge) && 
//             IMarketPlace(marketCollections).isCollectionTrustWorthyAuditor(_collectionId, _gauge2)
//         ));
//         require(!blackListedIdentities[_collectionId][_identityCode]);
//         if (uniqueAccounts) {
//             require(_identityCode != keccak256(abi.encodePacked("")));
//             require(identityProofs[keccak256(abi.encodePacked(_collectionId, _tokenId))][_identityCode] == 0);
//         }
//         identityProofs[keccak256(abi.encodePacked(_collectionId, _tokenId))][_identityCode] = _profileId;
//     }

//     function updateBlacklistedIdentities(uint[] memory userProfileIds, bool blacklist) external {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         address ssi = IMarketPlace(marketCollections).ssi();
//         for (uint i = 0; i < userProfileIds.length; i++) {
//             (string memory _ssid,) = ISSI(ssi).getSSID(userProfileIds[i]);
//             if (keccak256(abi.encodePacked(_ssid)) != keccak256(abi.encodePacked(""))) {
//                 blackListedIdentities[_collectionId][keccak256(abi.encodePacked(_ssid))] = blacklist;
//             }
//         }
//     }

//     function mintNote(address to, uint tokenId) external {
//         require(msg.sender == marketTrades);
//         _safeMint(to, tokenId, msg.data);
//     }

//     function updateCashbackRevenue(address _collection, string memory _tokenId) external {
//         require(marketOrders == msg.sender);
//         address nft_ = IMarketPlace(marketCollections).nft_();
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_collection);
//         Ask memory ask = IMarketPlace(marketOrders).getAskDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
//         if (ask.priceReductor.cashbackStatus == Status.Open &&
//             ask.priceReductor.cashbackStart <= block.timestamp
//         ) {
//             require(ask.priceReductor.cashbackNumbers.size < block.timestamp &&
//                 ask.priceReductor.cashbackCost.size < block.timestamp);
//             (uint256[] memory values1,) = INFTicket(nft_).getMerchantTicketsPagination(
//                 _collectionId, 
//                 ask.priceReductor.cashbackNumbers.cursor,
//                 ask.priceReductor.cashbackNumbers.size
//             );
//             (,uint256 totalPrice2) = INFTicket(nft_).getMerchantTicketsPagination(
//                 _collectionId, 
//                 ask.priceReductor.cashbackCost.cursor,
//                 ask.priceReductor.cashbackCost.size
//             );
//             bool _passedFirstTest = values1.length >= ask.priceReductor.cashbackNumbers.lowerThreshold && 
//                 values1.length <= ask.priceReductor.cashbackNumbers.upperThreshold;
//             bool _passedSecondTest = totalPrice2 >= ask.priceReductor.cashbackCost.lowerThreshold && 
//                     totalPrice2 <= ask.priceReductor.cashbackCost.upperThreshold;
//             if (!_passedFirstTest || !_passedSecondTest) {
//                 address _token = ask.tokenInfo.usetFIAT ? ask.tokenInfo.tFIAT : ve(ask.tokenInfo.ve).token();
//                 uint _amount = IMarketPlace(marketTrades).cashbackFund(_token, _collectionId);
//                 cashbackRevenue[_collectionId][keccak256(abi.encodePacked(_tokenId))].amount = _amount;
//                 cashbackRevenue[_collectionId][keccak256(abi.encodePacked(_tokenId))].bufferTime = block.timestamp + ask.priceReductor.cashbackNumbers.size +
//                 ask.priceReductor.cashbackCost.size - ask.priceReductor.cashbackNumbers.cursor - ask.priceReductor.cashbackCost.cursor;
//                 IMarketPlace(marketTrades).updateCashbackFund(_token, _collectionId, _amount, false);
//             }
//         }
//     }

//     function addCashBackToRevenue(string memory _tokenId) external {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         require(cashbackRevenue[_collectionId][keccak256(abi.encodePacked(_tokenId))].bufferTime < block.timestamp);
//         Ask memory ask = IMarketPlace(marketOrders).getAskDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
//         address _token = ask.tokenInfo.usetFIAT ? ask.tokenInfo.tFIAT : ve(ask.tokenInfo.ve).token();
//         IMarketPlace(marketTrades).updatePendingRevenue(
//             _token, 
//             ask.seller, 
//             cashbackRevenue[_collectionId][keccak256(abi.encodePacked(_tokenId))].amount,
//             false
//         );
//         cashbackRevenue[_collectionId][keccak256(abi.encodePacked(_tokenId))].amount = 0;
//     }
// }
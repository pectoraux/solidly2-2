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

// contract SubscriptionMarketPlaceHelper {
//     using SafeERC20 for IERC20;

//     address private businessVoter;
//     address private referralVoter;
//     mapping(string => uint) public lotteryCredits;
//     address private marketTrades;
//     address private marketOrders;
//     address private marketCollections;
//     address private marketPlaceEvents;
//     // The minimum amount of time left in an auction after a new bid is created
//     uint256 public timeBuffer;

//     /**
//      * @notice Constructor
//      * @param _marketCollections: address of the admin
//      * @param _marketOrders: address of the treasury
//      */
//     constructor(
//         address _marketCollections,
//         address _marketPlaceEvents,
//         address _marketOrders
//     ) {
//         marketCollections = _marketCollections;
//         marketPlaceEvents = _marketPlaceEvents;
//         marketOrders = _marketOrders;
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
//         if (marketTrades == address(0x0)) {
//             marketTrades = _marketTrades;
//         }
//     }
//     // function updateBlacklist(address[] memory _users, bool[] memory _blacklists) external onlyAdmin {
//     //     require(_users.length == _blacklists.length, "Blackist: Uneven lists");
//     //     for (uint i = 0; i < _users.length; i++) {
//     //         isBlacklisted[_users[i]] = _blacklists[i];
//     //     }
//     // }

//     function getRealPrice(
//         address _collection,
//         string memory _tokenId,
//         uint _price,
//         bytes32 _identityCode
//     ) public view returns(uint, bool) {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_collection);
//         uint __price = beforePaymentApplyDiscount(_collection, msg.sender, _tokenId, _price, _identityCode);
//         return (__price, _price != __price);
//     }

//     function beforePaymentApplyDiscount(
//         address _collection,
//         address _user,
//         string memory _tokenId,
//         uint _price,
//         bytes32 _identityCode
//     ) public view returns(uint) {
//         uint256 discount;
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_collection);
//         Ask memory ask = IMarketPlace(marketOrders)._askDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
//         Discount memory discountCost = ask.priceReductor.discountCost;
//         Discount memory discountNumbers = ask.priceReductor.discountNumbers;
//         string memory cid = string(abi.encodePacked(_collectionId, _tokenId));

//         if (ask.priceReductor.discountStatus == Status.Open &&
//             ask.priceReductor.discountStart < block.timestamp
//         ) {
//             if (ask.priceReductor.checkIdentityCode) {
//                 require(
//                     IMarketPlace(marketTrades).identityLimits(cid, _identityCode) < Math.max(discountCost.limit, discountNumbers.limit),
//                     "_beforePaymentApplyDiscount: limit reached"
//                 );
//             } else {
//                 require(
//                     IMarketPlace(marketTrades).discountLimits(cid, _user) < Math.max(discountCost.limit, discountNumbers.limit),
//                     "_beforePaymentApplyDiscount: limit reached"
//                 );
//             }
//             discount = _getDiscount(_user, _collection, _tokenId);
//         }
//         uint256 costWithDiscount = discount == 0 ? _price : _price-_price*discount/10000;
//         return costWithDiscount;
//     }

//     function _getDiscount(
//         address _user, 
//         address _collection,
//         string memory _tokenId 
//     ) internal view returns(uint _discount) {
//         address nft_ = IMarketPlace(marketCollections).nft_();
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_collection);
//         Ask memory ask = IMarketPlace(marketOrders)._askDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
//         Discount memory discountCost = ask.priceReductor.discountCost;
//         Discount memory discountNumbers = ask.priceReductor.discountNumbers;
//         (uint256[] memory values1,) = INFTicket(nft_).getUserTicketsPagination(
//                 _user, 
//                 _collection, 
//                 discountNumbers.cursor,
//                 discountNumbers.size
//             );
//             (,uint256 totalPrice2) = INFTicket(nft_).getUserTicketsPagination(
//                 _user, 
//                 _collection, 
//                 discountCost.cursor,
//                 discountCost.size
//             );
//             if (values1.length >= discountNumbers.lowerThreshold && 
//                 values1.length <= discountNumbers.upperThreshold
//             ) {
//                 _discount += discountNumbers.perct;
//                 if (totalPrice2 >= discountCost.lowerThreshold && 
//                     totalPrice2 <= discountCost.upperThreshold
//                 )
//                  {
//                     _discount += discountCost.perct;
//                 }
//             }
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

//     /**
//      * @notice Allows the owner to recover NFTs sent to the contract by mistake
//      * @param _token: NFT token address
//      * @param _tokenId: tokenId
//      * @dev Callable by owner
//      */
//     function recoverNonFungibleToken(address _token, uint _tokenId) external {
//         require(marketCollections == msg.sender);
//         IERC721(_token).safeTransferFrom(address(this), address(msg.sender), _tokenId);
//     }

//     /**
//      * @notice Calculate price and associated fees for a collection
//      * @param collection: address of the collection
//      * @param price: listed price
//      */
//     function calculatePriceAndFeesForCollection(
//         address collection, 
//         address referrer,
//         string memory tokenId, 
//         uint256 price
//     )
//         external
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
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(collection);
//         (Status status,,,,,,,) = IMarketPlace(marketCollections)._collections(_collectionId);
//         if (status != Status.Open) {
//             return (0, 0, 0, 0, 0, 0);
//         }

//         return (_calculatePriceAndFeesForCollection(collection, referrer, tokenId, price));
//     }

//     function checkAuction(
//         uint256 _price,
//         address _collection,
//         address _user,
//         string memory _tokenId
//     ) external {
//         require(marketTrades == msg.sender);
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_collection);
//         Ask memory ask = IMarketPlace(marketOrders)._askDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
//         require(ask.firstBidTime == 0 || ask.firstBidTime + ask.bidDuration > block.timestamp, 
//                 "Auction: Not available"
//         );

//         if (ask.firstBidTime != 0 || ask.minBidIncrementPercentage < 0) {
//             int256 _minIncrement = ask.minBidIncrementPercentage * int256(ask.price) / 10000;
//             require(int256(_price) >= int256(ask.price) + _minIncrement, "Auction: Invalid bid");
//         } else {
//             // first bidder
//             require(_price >= ask.price, "Auction: Invalid bid");
//         }
//         // If this is the first valid bid, we should set the starting time now.
//         // If it's not, then we should refund the last bidder
//         if(ask.firstBidTime == 0) {
//             ask.firstBidTime = block.timestamp;
//         } else {
//             address _token = ask.tokenInfo.usetFIAT ? ask.tokenInfo.tFIAT : ve(ask.tokenInfo.ve).token();
//             IERC20(_token).safeTransfer(ask.lastBidder, ask.price);
//         }
//         ask.price = _price;
//         ask.lastBidder = _user;

//         // at this point we know that the timestamp is less than start + duration (since the auction would be over, otherwise)
//         // we want to know by how much the timestamp is less than start + duration
//         // if the difference is less than the timeBuffer, increase the duration by the timeBuffer
//         if (
//             ask.firstBidTime + ask.bidDuration - block.timestamp < timeBuffer
//         ) {
//             // Playing code golf for gas optimization:
//             uint256 oldDuration = ask.bidDuration;
//             ask.bidDuration = 2*oldDuration+timeBuffer-ask.firstBidTime-block.timestamp;
//         }
//         IMarketPlace(marketOrders).updateAfterSale(
//             _collectionId,
//             _tokenId,
//             ask.price, 
//             ask.bidDuration, 
//             ask.firstBidTime,
//             ask.lastBidder
//         );
//     }

//     function vote(address _ve, address _user, string memory _tokenId, uint _userTokenId, uint _collectionId, uint _lotteryFee) external {
//         require(marketTrades == msg.sender);
//         // voting
//         if (ve(_ve).ownerOf(_userTokenId) == _user) {
//             address _superLikeGaugeFactory = IMarketPlace(marketCollections).superLikeGaugeFactory();
//             if (_superLikeGaugeFactory != address(0x0)) {
//                 IBusinessVoter(businessVoter).vote(
//                     _ve, 
//                     _userTokenId, 
//                     _collectionId, 
//                     int256(ve(_ve).balanceOfNFT(_userTokenId))
//                 );
//                 lotteryCredits[string(abi.encodePacked(_collectionId, _tokenId))] += _lotteryFee;
//                 // if user has been referred
//                 if (ISuperLikeGaugeFactory(_superLikeGaugeFactory).referrers(_user) != 0) {
//                     IReferralVoter(referralVoter).vote(
//                         _ve, 
//                         _userTokenId, 
//                         ISuperLikeGaugeFactory(_superLikeGaugeFactory).referrers(_user), 
//                         int256(ve(_ve).balanceOfNFT(_userTokenId))
//                     );
//                 }
//             }
//         }
//     }

//     function mintNFTicket(address _user, uint _collectionId, string memory _tokenId) external {
//         require(marketTrades == msg.sender);
//         // Mint NFTicket to buyer
//         (,,,address _tokenMinter,,,,) = IMarketPlace(marketCollections)._collections(_collectionId);
//         if (_tokenMinter == address(0x0)) {
//             _tokenMinter = IMarketPlace(marketCollections).nft_();
//         }
//         Ask memory ask = IMarketPlace(marketOrders)._askDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
//         INFTicket(_tokenMinter).batchMint(_user,_collectionId,1,ask.price,keccak256(abi.encodePacked(_tokenId)), new uint[](0));
//     }

//     function updateVoterNGaugeFactory(
//         address _businessVoter,
//         address _referralVoter,
//         uint _timeBuffer
//     ) external onlyAdmin {
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
//         uint _price
//     ) external {
//         require(msg.sender == marketTrades);
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_collection);
//         uint _referrerCollectionId = IMarketPlace(marketCollections).addressToCollectionId(_referrer);
//         Ask memory ask = IMarketPlace(marketOrders)._askDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
//         require(ask.seller != msg.sender && ask.seller != _user, "Buy: Buyer cannot be seller");
        
//         // Transfer _token
//         (uint period,) = IMarketPlace(marketOrders).subscriptionInfo(_collectionId);
//         address _arp = IMarketPlace(marketOrders).arps(_collectionId);
//         if (ask.tokenInfo.direction == DIRECTION.senderToReceiver) {
//             IMarketPlace(marketCollections).checkIdentityProof(_collection, false);
//             IPaywall(_arp).updateProtocol(_user, 0, ask.price, 0, period, _referrerCollectionId, "paywall");
//         } else {
//             IPaywall(_arp).updateProtocol(_user, ask.price, 0, period, 0, _referrerCollectionId, "paywall");
//             IPaywall(_arp).startAccount(_user, _userTokenId);
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
//         (,,,,uint tradingFee,,,) = IMarketPlace(marketCollections)._collections(_collectionId);
//         _tradingFee = (_askPrice * tradingFee) / 10000;
//         _lotteryFee = (_askPrice * IMarketPlace(marketCollections).lotteryFee()) / 10000;
//         if (_referrer != address(0x0)) {
//             uint _referrerCollectionId = IMarketPlace(marketCollections).addressToCollectionId(_referrer);
//             (,uint _referrerShare,) = IMarketPlace(marketOrders)._referrals(_referrerCollectionId, keccak256(abi.encodePacked(_tokenId)));
//             _referrerFee = (_askPrice * _referrerShare) / 10000;
//             (,,,,,,,uint _recurringBountyShare) = IMarketPlace(marketCollections)._collections(_referrerCollectionId);
//             if (_recurringBountyShare > 0) _recurringFee = (_askPrice * _recurringBountyShare) / 10000;
//         }
//         Ask memory ask = IMarketPlace(marketOrders)._askDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
//         if (ask.priceReductor.cashNotCredit) { 
//             uint _netPrice = _askPrice - _tradingFee - _lotteryFee - _referrerFee - _cashbackFee;
//             _cashbackFee = _netPrice * (ask.priceReductor.cashbackNumbers.perct + ask.priceReductor.cashbackCost.perct) / 10000;
//         }
//         netPrice = _askPrice - _tradingFee - _lotteryFee - _referrerFee - _cashbackFee - _recurringFee;
//     }
// }
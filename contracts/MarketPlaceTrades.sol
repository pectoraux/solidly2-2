// /**
//  *Submitted for verification at BscScan.com on 2021-09-30
// */

// // File: @openzeppelin/contracts/utils/Context.sol

// // SPDX-License-Identifier: MIT

// pragma solidity 0.8.17;
// pragma abicoder v2;

// import "./Library.sol";

// contract MarketPlaceTrades {
//     using SafeERC20 for IERC20;

//     mapping(address => uint) public treasuryRevenue;
//     mapping(address => uint) public lotteryRevenue;
//     mapping(address => mapping(uint => address)) public taxContracts;
//     mapping(address => mapping(uint => uint256)) public pendingRevenue; // For creator/treasury to claim
//     mapping(address => mapping(uint256 => uint256)) public pendingRevenueFromNote;
//     mapping(address => mapping(uint => uint)) public cashbackFund;
//     mapping(uint => mapping(address => uint)) public recurringBountyBalance;
//     address private marketHelpers;
//     address private marketHelpers2;
//     address private marketOrders;
//     address private marketCollections;
//     address private marketPlaceEvents;
//     address private trustBounty;
    
//     mapping(string => mapping(address => uint)) public discountLimits;
//     mapping(string => mapping(address => uint)) private cashbackLimits;
//     mapping(string => mapping(bytes32 => uint)) public identityLimits;
//     struct Limits {
//         uint cashbackLimits;
//         uint discountLimits;
//         uint identityLimits;
//     }
//     // collectionId => tokenId => version
//     mapping(uint => mapping(bytes32 => Limits)) public merchantVersion;
//     mapping(uint => mapping(bytes32 => Limits)) public userVersion;

//     struct MerchantNote {
//         uint start;
//         uint end;
//         uint lender;
//     }
//     mapping(address => MerchantNote) public notes;
//     uint public permissionaryNoteTokenId = 1;

//     /**
//      * @notice Constructor
//      * @param _marketCollections: address of the admin
//      * @param _marketOrders: address of the treasury
//      * @param _marketHelpers: address of the treasury
//      */
//     constructor(
//         address _marketCollections,
//         address _marketPlaceEvents,
//         address _marketOrders,
//         address _marketHelpers,
//         address _marketHelpers2,
//         address _trustBounty
//     ) {
//         marketCollections = _marketCollections;
//         marketPlaceEvents = _marketPlaceEvents;
//         marketOrders = _marketOrders;
//         marketHelpers = _marketHelpers;
//         marketHelpers2 = _marketHelpers2;
//         trustBounty = _trustBounty;
//     }

//     // simple re-entrancy check
//     uint internal _unlocked = 1;
//     modifier lock() {
//         require(_unlocked == 1);
//         _unlocked = 2;
//         _;
//         _unlocked = 1;
//     }

//     // function getContracts() external view returns(address,address,address,address,address) {
//     //     return (marketCollections, marketPlaceEvents, marketOrders, marketHelpers, marketHelpers2);
//     // }

//     function _checkIdentity(uint _collectionId, uint _identityTokenId, address _user, string memory _tokenId) internal returns(bytes32) {
//         address ssi = IMarketPlace(marketCollections).ssi();
//         SSIData memory metadata = ISSI(ssi).getSSIData(_identityTokenId);
//         (string memory _ssid,) = ISSI(ssi).getSSID(metadata.senderProfileId);
//         IMarketPlace(marketHelpers2).checkOrderIdentityProof(
//             _collectionId,
//             _identityTokenId,
//             _user, 
//             _tokenId
//         );
//         return keccak256(abi.encodePacked(_ssid));
//     }

//     /**
//      * @notice Buy token with WBNB by matching the price of an existing ask order
//      * @param _collection: contract address of the NFT
//      * @param _tokenId: tokenId of the NFT purchased
//      */
//     function buyWithContract(
//         address _collection,
//         address _user,
//         address _referrer,
//         string memory _tokenId,
//         uint _userTokenId,
//         uint _identityTokenId,
//         uint256[] calldata _options
//     ) external lock {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_collection);
//         Ask memory ask = IMarketPlace(marketOrders).getAskDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
//         uint _reducedPrice = ask.price;
//         if (ask.tokenInfo.direction == DIRECTION.senderToReceiver) {
//             require(ask.dropinTimer < block.timestamp, "Not yet available");
//             require(ask.maxSupply > 0, "Not enough supply");
//             bytes32 _identityCode = _checkIdentity(_collectionId, _identityTokenId, _user, _tokenId);
//             IMarketPlace(marketOrders).updatePaymentCredits(_user, _collectionId, _tokenId);
//             (uint _price, bool _applied) = IMarketPlace(marketHelpers).getRealPrice(_collection, _tokenId, _options, _identityTokenId, ask.price);
//             if (_price >= IMarketPlace(marketOrders).getPaymentCredits(_user, _collectionId, _tokenId)) {
//                 _price -= IMarketPlace(marketOrders).getPaymentCredits(_user, _collectionId, _tokenId);
//                 uint _credits = IMarketPlace(marketOrders).getPaymentCredits(_user, _collectionId, _tokenId);
//                 IMarketPlace(marketOrders).decrementPaymentCredits(
//                     _user, 
//                     _collectionId, 
//                     _tokenId, 
//                     _credits
//                 );
//             } else {
//                 _price = 0;
//                 IMarketPlace(marketOrders).decrementPaymentCredits(_user, _collectionId, _tokenId, _price);
//             }
//             if (_applied) {
//                 if (ask.priceReductor.checkIdentityCode) {
//                     identityLimits[string(abi.encodePacked(_collectionId, _tokenId))][_identityCode] += 1;
//                 }
//                 discountLimits[string(abi.encodePacked(_collectionId, _tokenId))][_user] += 1;
//             }
//             _reducedPrice = _price;
//         }
//         _buyToken(_collection, _referrer, _user, _tokenId, _userTokenId, _reducedPrice, _options);
//     }

//     function updateTaxContract(address _taxContract, address _token) external {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         taxContracts[_token][_collectionId] = _taxContract;
//     }

//     function updateIdVersion(uint _collectionId, string memory _tokenId, uint _identityTokenId) external {
//         if (
//             merchantVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].identityLimits > 
//             userVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].identityLimits
//         ) {
//             address ssi = IMarketPlace(marketCollections).ssi();
//             SSIData memory metadata = ISSI(ssi).getSSIData(_identityTokenId);
//             (string memory _ssid,) = ISSI(ssi).getSSID(metadata.senderProfileId);
//             require(metadata.deadline > block.timestamp);
//             if (keccak256(abi.encodePacked(_ssid)) != keccak256(abi.encodePacked(""))) {
//                 identityLimits[string(abi.encodePacked(_collectionId, _tokenId))][keccak256(abi.encodePacked(_ssid))] = 0;
//                 userVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].identityLimits =
//                 merchantVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].identityLimits;
//             }
//         }
//     }

//     function updateVersion(uint _collectionId, string memory _tokenId, address _user) external {
//         if (
//             merchantVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].discountLimits > 
//             userVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].discountLimits
//         ) {
//             discountLimits[string(abi.encodePacked(_collectionId, _tokenId))][_user] = 0;
//             userVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].discountLimits =
//             merchantVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].discountLimits;
//         }
//         if (
//             merchantVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].cashbackLimits > 
//             userVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].cashbackLimits
//         ) {
//             cashbackLimits[string(abi.encodePacked(_collectionId, _tokenId))][_user] = 0;
//             userVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].cashbackLimits =
//             merchantVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].cashbackLimits;
//         }
//     }

//     function processCashBack(
//         address _collection, 
//         string memory _tokenId,
//         bool _creditNotCash,
//         string memory _applyToTokenId
//     ) external lock {
//         uint256 cashback1;
//         uint256 cashback2;
//         address nft_ = IMarketPlace(marketCollections).nft_();
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_collection);
//         Ask memory ask = IMarketPlace(marketOrders).getAskDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
//         string memory cid = string(abi.encodePacked(_collectionId, _tokenId));
//         {
//         if (ask.priceReductor.cashbackStatus == Status.Open &&
//             ask.priceReductor.cashbackStart <= block.timestamp
//         ) {
//             require(
//                 cashbackLimits[cid][msg.sender] < Math.max(ask.priceReductor.cashbackCost.limit, ask.priceReductor.cashbackNumbers.limit),
//                 "processCashBack: limit reached"
//             );

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
            
//             if (values1.length >= ask.priceReductor.cashbackNumbers.lowerThreshold && 
//                 values1.length <= ask.priceReductor.cashbackNumbers.upperThreshold
//             ) {
//                 cashback1 += ask.priceReductor.cashbackNumbers.perct;
//                 if (totalPrice2 >= ask.priceReductor.cashbackCost.lowerThreshold && 
//                     totalPrice2 <= ask.priceReductor.cashbackCost.upperThreshold
//                 ) {
//                     cashback2 += ask.priceReductor.cashbackCost.perct;
//                 }
//             }
//         }
//         if (!ask.priceReductor.cashNotCredit) {
//             _creditNotCash = true;
//         }
//         (, uint256 totalPrice11) = INFTicket(nft_).getUserTicketsPagination(
//             msg.sender, 
//             _collectionId, 
//             ask.priceReductor.cashbackNumbers.cursor,
//             ask.priceReductor.cashbackNumbers.size
//         );
//         (, uint256 totalPrice22) = INFTicket(nft_).getUserTicketsPagination(
//             msg.sender, 
//             _collectionId, 
//             ask.priceReductor.cashbackCost.cursor,
//             ask.priceReductor.cashbackCost.size
//         );
//         uint256 totalCashback = cashback1 * totalPrice11 / 10000;
//         totalCashback += cashback2 * totalPrice22 / 10000;  
//         if (totalCashback > 0) cashbackLimits[cid][msg.sender] += 1;
//         address _token = ask.tokenInfo.usetFIAT ? ask.tokenInfo.tFIAT : ve(ask.tokenInfo.ve).token();

//         if (!_creditNotCash) {
//             IERC20(_token).safeTransfer(address(msg.sender), totalCashback);            
//         } else {
//             IMarketPlace(marketOrders).incrementPaymentCredits(msg.sender,_collectionId, _applyToTokenId,totalCashback);
//             pendingRevenue[_token][_collectionId] += Math.min(totalCashback, cashbackFund[_token][_collectionId]);
//         }
//         if (cashbackFund[_token][_collectionId] > totalCashback) {
//             cashbackFund[_token][_collectionId] -= totalCashback; 
//         } else {
//             cashbackFund[_token][_collectionId] = 0;
//         }
//         }
//     }

//     /**
//      * @notice Claim pending revenue (treasury or creators)
//      */
//     function claimPendingRevenue(address _token, uint _identityTokenId) external lock {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         IMarketPlace(marketCollections).checkIdentityProof(msg.sender, _identityTokenId, false);
//         IERC20(_token).safeTransfer(address(msg.sender), pendingRevenue[_token][_collectionId]);
        
//         IMarketPlace(marketPlaceEvents).emitRevenueClaim(msg.sender, pendingRevenue[_token][_collectionId]);
//         pendingRevenue[_token][_collectionId] = 0;
//     }

//     function fundPendingRevenue(address _collection, address _token, uint _amount, bool _cashbackFund) external lock returns(uint) {
//         IERC20(_token).safeTransferFrom(address(msg.sender), address(this), _amount);
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_collection);
//         if (_cashbackFund) {
//             cashbackFund[_token][_collectionId] += _amount;
//             return cashbackFund[_token][_collectionId];
//         }
//         pendingRevenue[_token][_collectionId] += _amount;
//         return pendingRevenue[_token][_collectionId];
//     }

//     function claimPendingRevenueFromNote(address _token, uint _tokenId, uint _identityTokenId) external lock {
//         require(ve(marketHelpers2).ownerOf(_tokenId) == msg.sender);
//         IMarketPlace(marketCollections).checkIdentityProof(msg.sender, _identityTokenId, false);
//         IERC20(_token).safeTransfer(address(msg.sender), pendingRevenueFromNote[_token][_tokenId]);
//         IMarketPlace(marketPlaceEvents).emitRevenueClaim(msg.sender, pendingRevenueFromNote[_token][_tokenId]);
//         pendingRevenueFromNote[_token][_tokenId] = 0;
//     }
    
//     function transferDueToNote(uint _start, uint _end) external {
//         require(notes[msg.sender].end < block.timestamp);
//         require(_end > _start);
//         notes[msg.sender] = MerchantNote({
//             start: block.timestamp + _start,
//             end: block.timestamp + _end,
//             lender: permissionaryNoteTokenId
//         });
//         IMarketPlace(marketHelpers2).mintNote(msg.sender, permissionaryNoteTokenId++);
//     }
    
//     function updatePendingRevenue(address _token, address _merchant, uint _revenue, bool _isReferrer) external {
//         require(msg.sender == marketHelpers);
//         if (notes[_merchant].start < block.timestamp && 
//             notes[_merchant].end >= block.timestamp && !_isReferrer) {
//             pendingRevenueFromNote[_token][notes[_merchant].lender] += _revenue;
//         } else {
//             uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_merchant);
//             pendingRevenue[_token][_collectionId] += _revenue;
//             if (taxContracts[_token][_collectionId] != address(0x0)) {
//                 IBILL(taxContracts[_token][_collectionId]).notifyCredit(_merchant, _revenue);
//             }
//         }
//     }

//     function decreasePendingRevenue(address _token, address _user, uint _collectionId, uint _price) external {
//         require(msg.sender == marketHelpers);
//         require(pendingRevenue[_token][_collectionId] >= _price);
    
//         pendingRevenue[_token][_collectionId] -= _price; 
//         IERC20(_token).safeTransfer(_user, _price);
//     }

//     function updateCashbackFund(address _token, uint _collectionId, uint _cashbackFee, bool _add) external {
//         require(msg.sender == marketHelpers);
//         if (_add) {
//             cashbackFund[_token][_collectionId] += _cashbackFee;
//         } else {
//             cashbackFund[_token][_collectionId] -= _cashbackFee;
//         }
//     }

//     function updateTreasuryRevenue(address _token, uint _tradingFee) external {
//         require(msg.sender == marketHelpers);
    
//         treasuryRevenue[_token] += _tradingFee;
//     }

//     function updateLotteryRevenue(address _token, uint _lotteryFee) external {
//         require(msg.sender == marketHelpers);
    
//         lotteryRevenue[_token] += _lotteryFee;
//     }

//     function claimLotteryRevenue(address _token) external {
//         require(msg.sender == IMarketPlace(marketCollections).lotteryAddress());
//         IERC20(_token).safeTransfer(msg.sender, lotteryRevenue[_token]);
//         lotteryRevenue[_token] = 0;
//     }

//     function claimTreasuryRevenue(address _token) external {
//         require(msg.sender == IAuth(marketCollections).devaddr_());
//         IERC20(_token).safeTransfer(msg.sender, treasuryRevenue[_token]);
//         treasuryRevenue[_token] = 0;
//     }

//     function reinitializeIdentityLimits(string memory _tokenId) external {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         merchantVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].identityLimits += 1;
//     }

//     function reinitializeDiscountLimits(string memory _tokenId) external {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         merchantVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].discountLimits += 1;
//     }

//     function reinitializeCashbackLimits(string memory _tokenId) external {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         merchantVersion[_collectionId][keccak256(abi.encodePacked(_tokenId))].cashbackLimits += 1;
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

//     /**
//      * @notice Buy token by matching the price of an existing ask order
//      * @param _collection: contract address of the NFT
//      * @param _tokenId: tokenId of the NFT purchased
//      * @param _price: price (must match the askPrice from the seller)
//      */
//     function _buyToken(
//         address _collection,
//         address _referrer,
//         address _user,
//         string memory _tokenId,
//         uint256 _userTokenId,
//         uint256 _price,
//         uint[] memory _options
//     ) internal {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_collection);
//         Collection memory _itemCollection = IMarketPlace(marketCollections).getCollection(_collectionId);
//         require(_itemCollection.status == Status.Open, "Collection: Not for trading");
//         Ask memory ask = IMarketPlace(marketOrders).getAskDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
//         address _token = ask.tokenInfo.usetFIAT ? ask.tokenInfo.tFIAT : ve(ask.tokenInfo.ve).token();
//         if (ask.tokenInfo.direction == DIRECTION.senderToReceiver && ask.bidDuration == 0) {
//             IERC20(_token).safeTransferFrom(msg.sender, address(this), _price);
//         }
//         if (ask.bidDuration != 0) { // Auction
//             erc20(_token).approve(marketHelpers, ask.price);
//             IMarketPlace(marketHelpers).checkAuction(_price, _collection, msg.sender, _tokenId);
//         } else {
//             IMarketPlace(marketHelpers).processTrade(
//                 _collection,
//                 _referrer,
//                 _user,
//                 _tokenId,
//                 _userTokenId,
//                 _price,
//                 _options
//             );
//         }
//     }

//     function updateRecurringBountyRevenue(address _token, uint _collectionId, uint _amount) external {
//         if (marketHelpers != msg.sender) {
//             IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
//         }
//         recurringBountyBalance[_collectionId][_token] += _amount;
//     }

//     function withdrawRecurringBounty(address _referrer, address _token) external returns(uint _amount) {
//         require(trustBounty == msg.sender);
//         uint _referrerCollectionId = IMarketPlace(marketCollections).addressToCollectionId(_referrer);
//         _amount = recurringBountyBalance[_referrerCollectionId][_token];
//         recurringBountyBalance[_referrerCollectionId][_token] = 0;
//         IERC20(_token).safeTransfer(msg.sender, _amount);
//     }
// }
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

// contract SubscriptionMarketPlaceTrades is ERC721Pausable {
//     using SafeERC20 for IERC20;

//     mapping(address => uint) public treasuryRevenue;
//     mapping(address => uint) public lotteryRevenue;
//     mapping(address => mapping(uint => uint)) public cashbackFund;
//     address private marketHelpers;
//     address private marketOrders;
//     address private marketCollections;
//     address private marketPlaceEvents;
    
//     // mapping(address => bool) public isBlacklisted;
//     mapping(string => mapping(address => uint)) private discountLimits;
//     mapping(string => mapping(address => uint)) private cashbackLimits;
//     mapping(string => mapping(bytes32 => uint)) private identityLimits;
//     mapping(string => address[]) private paywallSignups;
    

//     // // Recover NFT tokens sent by accident
//     // event NonFungibleTokenRecovery(address indexed token, uint256 indexed tokenId);

//     // // Pending revenue is claimed
//     // event RevenueClaim(address indexed claimer, uint256 amount);

//     // // Recover ERC20 tokens sent by accident
//     // event TokenRecovery(address indexed token, uint256 amount);

//     // // Ask order is matched by a trade
//     // event Trade(
//     //     address indexed collection,
//     //     bytes32 tokenId,
//     //     address indexed seller,
//     //     address buyer,
//     //     uint256 askPrice,
//     //     uint256 netPrice
//     // );

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
//         address _marketHelpers
//     ) ERC721("CanCanSubNote", "nCanCanSub") {
//         marketCollections = _marketCollections;
//         marketPlaceEvents = _marketPlaceEvents;
//         marketOrders = _marketOrders;
//         marketHelpers = _marketHelpers;
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

//     function updateTreasuryRevenue(address _token, uint _amount) external {
//         require(msg.sender == marketHelpers);
//         // IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
//         treasuryRevenue[_token] += _amount;
//     }

//     function updateLotteryRevenue(address _token, uint _amount) external {
//         require(msg.sender == marketHelpers);
//         // IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
//         lotteryRevenue[_token] += _amount;
//     }

//     function updateCashbackFund(address _token, uint _collectionId, uint _amount) external {
//         require(msg.sender == marketHelpers);
//         // IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
//         cashbackFund[_token][_collectionId] += _amount;
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
//         uint _userTokenId
//     ) external lock {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_collection);
//         Ask memory ask = IMarketPlace(marketOrders)._askDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
//         uint _reducedPrice = ask.price;
//         if (ask.tokenInfo.direction == DIRECTION.senderToReceiver) {
//             require(ask.dropinTimer < block.timestamp, "Not yet available");
//             require(ask.maxSupply > 0, "Not enough supply");
//             string memory contract_tokenId = string(abi.encodePacked(_collectionId, _tokenId));
//             bytes32 _identityCode = IMarketPlace(marketOrders).checkIdentityProof2(
//                 _collectionId,
//                 _tokenId,
//                 _user, 
//                 false
//             );
//             IMarketPlace(marketOrders).updatePaymentCredits(_user, _collectionId, _tokenId);
//             (uint _price, bool _applied) = IPaywall(marketHelpers).getRealPrice(_collection, _tokenId, ask.price, _identityCode);
//             if (_price >= IMarketPlace(marketOrders).paymentCredits(_user, contract_tokenId)) {
//                 _price -= IMarketPlace(marketOrders).paymentCredits(_user, contract_tokenId);
//                 uint _credits = IMarketPlace(marketOrders).paymentCredits(_user, contract_tokenId);
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
//                     identityLimits[contract_tokenId][_identityCode] += 1;
//                 }
//                 if (discountLimits[contract_tokenId][_user] == 0) {
//                     paywallSignups[contract_tokenId].push(_user);
//                 }
//                 discountLimits[contract_tokenId][_user] += 1;
//             }
//             _reducedPrice = _price;
//         }
//         _buyToken(_collection, _referrer, _user, _tokenId, _userTokenId, _reducedPrice);
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
//         Ask memory ask = IMarketPlace(marketOrders)._askDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
//         string memory cid = string(abi.encodePacked(_collectionId, _tokenId));
//         {
//         if (ask.priceReductor.cashbackStatus == Status.Open &&
//             ask.priceReductor.cashbackStart < block.timestamp
//         ) {
//             require(
//                 cashbackLimits[cid][msg.sender] < Math.max(ask.priceReductor.cashbackCost.limit, ask.priceReductor.cashbackNumbers.limit),
//                 "processCashBack: limit reached"
//             );

//             (uint256[] memory values1,) = INFTicket(nft_).getMerchantTicketsPagination(
//                 _collection, 
//                 ask.priceReductor.cashbackNumbers.cursor,
//                 ask.priceReductor.cashbackNumbers.size
//             );
//             (,uint256 totalPrice2) = INFTicket(nft_).getMerchantTicketsPagination(
//                 _collection, 
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

//             if (!ask.priceReductor.cashNotCredit) {
//                 _creditNotCash = true;
//             }

//         }
//         (, uint256 totalPrice11) = INFTicket(nft_).getUserTicketsPagination(
//             msg.sender, 
//             _collection, 
//             ask.priceReductor.cashbackNumbers.cursor,
//             ask.priceReductor.cashbackNumbers.size
//         );
//         (, uint256 totalPrice22) = INFTicket(nft_).getUserTicketsPagination(
//             msg.sender, 
//             _collection, 
//             ask.priceReductor.cashbackCost.cursor,
//             ask.priceReductor.cashbackCost.size
//         );
//         uint256 totalCashback = cashback1 * totalPrice11 / 10000;
//         totalCashback += cashback2 * totalPrice22 / 10000;  
//         if (cashbackLimits[cid][msg.sender] == 0) {
//             paywallSignups[cid].push(msg.sender);
//         }  
//         if (totalCashback > 0) cashbackLimits[cid][msg.sender] += 1;
//         address _token = ask.tokenInfo.usetFIAT ? ask.tokenInfo.tFIAT : ve(ask.tokenInfo.ve).token();

//         if (!_creditNotCash) {
//             IERC20(_token).safeTransfer(address(msg.sender), totalCashback);            
//         } else {
//             IMarketPlace(marketOrders).incrementPaymentCredits(msg.sender,_collectionId,_applyToTokenId,totalCashback);
//             address _arp = IMarketPlace(marketOrders).arps(_collectionId);
//             erc20(_token).approve(_arp, totalCashback);
//             IPaywall(_arp).notifyRevenue(_token, totalCashback);
//         }
//         cashbackFund[_token][_collectionId] -= totalCashback; 
//         }
//     }

//     function reinitializeIdentityLimits(string memory _tokenId) external {
//         string memory contract_tokenId = string(abi.encodePacked(msg.sender, _tokenId));
//         for (uint i = 0; i < paywallSignups[contract_tokenId].length; i++) {
//             delete identityLimits[contract_tokenId][
//                 IMarketPlace(marketCollections).userToIdentityCode(paywallSignups[contract_tokenId][i])
//             ];
//         }
//         delete paywallSignups[contract_tokenId];
//     }

//     function reinitializeDiscountLimits(string memory _tokenId) external {
//         string memory contract_tokenId = string(abi.encodePacked(msg.sender, _tokenId));
//         for (uint i = 0; i < paywallSignups[contract_tokenId].length; i++) {
//             delete discountLimits[contract_tokenId][paywallSignups[contract_tokenId][i]];
//         }
//         delete paywallSignups[contract_tokenId];
//     }

//     function reinitializeCashbackLimits(string memory _tokenId) external {
//         string memory contract_tokenId = string(abi.encodePacked(msg.sender, _tokenId));
//         for (uint i = 0; i < paywallSignups[contract_tokenId].length; i++) {
//             delete cashbackLimits[contract_tokenId][paywallSignups[contract_tokenId][i]];
//         }
//         delete paywallSignups[contract_tokenId];
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
//         uint256 _price
//     ) internal {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_collection);
//         (Status status,,,,,,,) = IMarketPlace(marketCollections)._collections(_collectionId);
//         require(status == Status.Open, "Collection: Not for trading");
//         // require(IMarketPlace(marketOrders)._askTokenIds(_collectionId).contains(uint(keccak256(abi.encodePacked(_tokenId)))), "Buy: Not for sale");
//         Ask memory ask = IMarketPlace(marketOrders)._askDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
//         if (ask.bidDuration != 0 && ask.tokenInfo.direction == DIRECTION.senderToReceiver) { // Auction
//             address _token = ask.tokenInfo.usetFIAT ? ask.tokenInfo.tFIAT : ve(ask.tokenInfo.ve).token();
//             IERC20(_token).safeTransferFrom(msg.sender, address(this), _price);
//             IMarketPlace(marketHelpers).checkAuction(_price, _collection, msg.sender, _tokenId);
//         } else {
//             IPaywall(marketHelpers).processTrade(
//                 _collection,
//                 _referrer,
//                 _user,
//                 _tokenId,
//                 _userTokenId,
//                 _price
//             );
//         }
//     }
    
//     function processAuction(
//         address _collection,
//         address _referrer,
//         address _user,
//         string memory _tokenId
//     ) external {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_collection);
//         Ask memory ask = IMarketPlace(marketOrders)._askDetails(_collectionId, keccak256(abi.encodePacked(_tokenId)));
//         require(ask.firstBidTime + ask.bidDuration <= block.timestamp, 
//                 "Auction: Still ongoing"
//         );
//         require(ask.lastBidder == msg.sender, "Auction: Not auction winner");
//         IMarketPlace(marketCollections).checkIdentityProof(_collection, false);
//         address _arp = IMarketPlace(marketOrders).arps(_collectionId);
//         (uint period,) = IMarketPlace(marketOrders).subscriptionInfo(_collectionId);
//         uint _referrerCollectionId = IMarketPlace(marketCollections).addressToCollectionId(_referrer);
//         IPaywall(_arp).updateProtocol(_user, 0, ask.price, 0, period, _referrerCollectionId, "paywall");
//         address[] memory _users = new address[](1);
//         _users[0] = _user;
//         IPaywall(_arp).autoCharge(_users, ask.price, 1);
//     }
// }
// /**
//  *Submitted for verification at BscScan.com on 2021-09-30
// */

// // File: @openzeppelin/contracts/utils/Context.sol

// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;
// pragma abicoder v2;

// import "./NFTicket.sol";
// import "./PermissionaryNote.sol";
// // File: contracts/ERC721NFTMarketV1.sol

// contract SubscriptionMarketPlace is Auth, PermissionaryNote, ERC721Holder, ReentrancyGuard {
//     using EnumerableSet for EnumerableSet.AddressSet;
//     using EnumerableSet for EnumerableSet.UintSet;

//     using SafeERC20 for IERC20;

//     enum Status {
//         Pending,
//         Open,
//         Close
//     }

//     enum DIRECTION {
//         senderToReceiver,
//         receiverToSender
//     }
//     address public immutable WBNB;
//     uint256 public constant TOTAL_MAX_FEE = 1000; // 10% of a sale

//     address public adminAddress;
//     address public treasuryAddress;
//     address public lotteryAddress;

//     uint256 public minimumAskPrice; // in wei
//     uint256 public maximumAskPrice; // in wei
//     uint256 public minimumLotteryPrice; // in wei
//     uint public cashbackBuffer;
//     uint public maxWeight;
//     address public businessVoter;
//     address public referralVoter;
//     mapping(address => uint256) public pendingRevenue; // For creator/treasury to claim
//     mapping(uint256 => uint256) public pendingRevenueFromNote;
//     bool public blockContracts = true;
//     EnumerableSet.AddressSet private _collectionAddressSet;
//     EnumerableSet.AddressSet private _dtokenSet;
    
//     struct Referral {
//         address seller;
//         uint referrerFee;
//     }
//     // merchant can switch from wall1 to wall2 to force all users into a new subscription
//     enum Paywall {
//         UndefinedWall,
//         PartnerWall1,
//         PartnerWall2,
//         UserWall1,
//         UserWall2,
//         NFTicketWall1,
//         NFTicketWall2
//     }

//     // referee => videoId => Referral
//     mapping(address => mapping(Paywall => Referral)) public _referrals; // Ask details (price + seller address) for a given collection and a tokenId
//     mapping(address => mapping(Paywall => Ask)) public _askDetails; // Ask details (price + seller address) for a given collection and a tokenId
//     mapping(address => EnumerableSet.UintSet) private _askTokenIds; // Set of tokenIds for a collection
//     mapping(address => Collection) public _collections; // Details about the collections
//     mapping(address => EnumerableSet.UintSet) private _tokenIdsOfSellerForCollection;
//     mapping(address => mapping(string => address)) public credited;
//     mapping(string => mapping(uint => uint)) public subscriptionTiers;
//     mapping(string => uint[]) public AllTiers;
//     mapping(address => EnumerableSet.AddressSet) private collectionTrustWorthyAuditors;
//     mapping(address => uint) public cashNotCredit;

//     // The minimum amount of time left in an auction after a new bid is created
//     uint256 public tradingFee;
//     uint256 public lotteryFee;
//     uint public maximumArrayLength = 50;
//     mapping(address => bool) public unAuthorizedContracts;
//     mapping(address => mapping(string => uint)) public paymentCredits;
//     address public nft_;
//     address[] public nfts_;
//     mapping(address => mapping(address => uint)) public burnTokenForCredit;
//     mapping(address => mapping(Paywall => EnumerableSet.AddressSet)) private sponsoredMessages;
//     mapping(address => mapping(Paywall => uint)) public merchantCredits;
//     uint public minSponsorship = 5; //5$
//     uint public sponsorMessageShare = 5000; // 50%
//     mapping(address => bool) public isBlacklisted;
//     mapping(string => mapping(address => uint)) public discountLimits;
//     mapping(string => mapping(address => uint)) public cashbackLimits;
//     mapping(string => mapping(bytes32 => uint)) public identityLimits;
//     mapping(string => address[]) public paywallSignups;
//     struct Discount {
//         uint256 cursor;
//         uint256 size;
//         uint256 perct;
//         uint256 lowerThreshold;
//         uint256 upperThreshold;
//         uint256 limit;
//     }

//     struct PriceReductor {
//         Status discountStatus;   
//         uint discountStart;   
//         Status cashbackStatus;   
//         uint cashbackStart;   
//         bool cashNotCredit;
//         bool checkIdentityCode;
//         Discount discountNumbers;
//         Discount discountCost;    
//         Discount cashbackNumbers;
//         Discount cashbackCost;
//     }

//     struct Ask {
//         address seller;
//         uint256 price; // price of the token
//         uint256 rsrcTokenId;
//         bool transferrable;
//         PriceReductor priceReductor;
//         string note;
//         uint maxSupply;
//         uint period;
//         uint freeTrial;
//         bytes32 requiredIndentity;
//         COLOR minIDBadgeColor;
//         string valueName;
//         uint timeRemaining;
//     }

//     struct Collection {
//         Status status; // status of the collection
//         address tokenMinter;
//         uint256 referrerFee; // creator fee (100 = 1%, 500 = 5%, 5 = 0.05%)
//         address dtoken;
//     }

//     struct Note {
//         uint start;
//         uint end;
//         uint lender;
//     }
//     mapping(address => Note) public notes;
//     uint permissionaryNoteTokenId = 1;
//     struct SubscriptionInfo {
//         address referrer;
//         bool autoCharge;
//         uint freeTrial;
//         uint amountPayable;
//         uint paidPayable;
//         uint tradingFee;
//         uint periodPayable;
//         uint startPayable;
//         bytes32 identityCode;
//     }
//     mapping(string => mapping(address => SubscriptionInfo)) public subscriptionInfo;
//     mapping(string => address[]) public AllSubscriptions;
//     mapping(string => address[]) public AllAutoCharges;
//     mapping(uint => address) public transferList;

//     // Ask order is cancelled
//     event AskCancel(address indexed seller, Paywall indexed paywall);

//     // Ask order is created
//     event AskNew(address indexed seller, Paywall indexed paywall, uint256 askPrice);

//     // Ask order is updated
//     event AskUpdate(address indexed seller, Paywall indexed paywall, uint256 askPrice);

//     // Collection is closed for trading and new listings
//     event CollectionClose(address indexed collection);

//     // New collection is added
//     event CollectionNew(
//         address indexed collection,
//         address indexed tokenMinter,
//         uint256 referrerFee
//     );

//     // Existing collection is updated
//     event CollectionUpdate(
//         address indexed collection,
//         address indexed tokenMinter,
//         uint256 referrerFee
//     );

//     // Admin and Treasury Addresses are updated
//     event NewAdminAndTreasuryAddresses(address indexed admin, address indexed treasury);

//     // Minimum/maximum ask prices are updated
//     event NewMinimumAndMaximumAskPrices(uint256 minimumAskPrice, uint256 maximumAskPrice);

//     // Recover NFT tokens sent by accident
//     event NonFungibleTokenRecovery(address indexed token, uint256 indexed tokenId);

//     // Pending revenue is claimed
//     event RevenueClaim(address indexed claimer, uint256 amount);

//     // Recover ERC20 tokens sent by accident
//     event TokenRecovery(address indexed token, uint256 amount);

//     event UpdateBurnTokenForCredit(address indexed Collection, address token, uint256 discountNumber);

//     // Ask order is matched by a trade
//     event Trade(
//         address indexed collection,
//         Paywall indexed _paywall,
//         address indexed seller,
//         address buyer,
//         uint256 askPrice,
//         uint256 netPrice
//     );

//     event DeleteSubscription(address indexed from, uint time);
//     event UpdateAutoCharge(address indexed from, uint time);

//     /**
//      * @notice Constructor
//      * @param _adminAddress: address of the admin
//      * @param _treasuryAddress: address of the treasury
//      * @param _WBNBAddress: WBNB address
//      * @param _minimumAskPrice: minimum ask price
//      * @param _maximumAskPrice: maximum ask price
//      */
//     constructor(
//         address _adminAddress,
//         address _treasuryAddress,
//         address _WBNBAddress,
//         uint256 _minimumAskPrice,
//         uint256 _maximumAskPrice,
//         address _superLikeGaugeFactory
//     ) 
//     PermissionaryNote("MarketPlace") 
//     Auth(_adminAddress, _superLikeGaugeFactory)
//     {
//         require(_adminAddress != address(0), "Operations: Admin address cannot be zero");
//         require(_treasuryAddress != address(0), "Operations: Treasury address cannot be zero");
//         require(_WBNBAddress != address(0), "Operations: WBNB address cannot be zero");
//         require(_minimumAskPrice > 0, "Operations: _minimumAskPrice must be > 0");
//         require(_minimumAskPrice < _maximumAskPrice, "Operations: _minimumAskPrice < _maximumAskPrice");

//         adminAddress = _adminAddress;
//         treasuryAddress = _treasuryAddress;
        
//         WBNB = _WBNBAddress;
//         minimumAskPrice = _minimumAskPrice;
//         maximumAskPrice = _maximumAskPrice;
//     }

   
//     /**
//      * @notice Buy token with WBNB by matching the price of an existing ask order
//      * @param _collection: contract address of the NFT
//      * @param _paywall: tokenId of the NFT purchased
//      * @param _tier: price (must be equal to the askPrice set by the seller)
//      */
//     function buyWithContract(
//         address _contract,
//         address _collection,
//         address _referrer,
//         Paywall _paywall,
//         uint _direction,
//         uint256 _tier,
//         uint256 _startPayable,
//         uint256[3] memory _stakes,
//         string memory _note
//     ) external nonReentrant {
//         require(_askDetails[_collection][_paywall].timeRemaining >= block.timestamp, "No more available");
//         require(_askDetails[_collection][_paywall].maxSupply > 0, "Not enough supply");
//         string memory contract_tokenId = string(abi.encodePacked(_collection, _paywall));
//         uint _price = subscriptionTiers[contract_tokenId][_tier];
//         bytes32 _identityCode = checkIdentityProof2(
//             _collection,
//             _paywall,
//             msg.sender, 
//             false
//         );
//         if (paymentCredits[msg.sender][string(abi.encodePacked(_collection, ""))] > 0) {
//             paymentCredits[msg.sender][contract_tokenId] += 
//             paymentCredits[msg.sender][string(abi.encodePacked(_collection, ""))];
//             paymentCredits[msg.sender][string(abi.encodePacked(_collection, ""))] = 0;
//         }
//         _price = _beforePaymentApplyDiscount(_collection, _paywall, _price, _identityCode); 
//         if (paymentCredits[msg.sender][contract_tokenId] >= _price && _direction == 0) {
//             // creative way to check for discount to avoid stack too deep error
//             if (_price < subscriptionTiers[contract_tokenId][_tier]) {
//                 if (_askDetails[_collection][_paywall].priceReductor.checkIdentityCode) {
//                     identityLimits[contract_tokenId][_identityCode] += 1;
//                 }
//                 if (discountLimits[contract_tokenId][msg.sender] == 0) {
//                     paywallSignups[contract_tokenId].push(msg.sender);
//                 }
//                 discountLimits[contract_tokenId][msg.sender] += 1;
//             }
//             paymentCredits[msg.sender][contract_tokenId] -= _price;
//             _buyToken(
//                 _collection, 
//                 _referrer,
//                 _paywall, 
//                 _startPayable,
//                 _price,
//                 _tier,
//                 _identityCode,
//                 _note
//             );
//         } else {
//             require(!unAuthorizedContracts[_contract], "Unauthorized call to buyWithContract");
//             _price -= paymentCredits[msg.sender][contract_tokenId];
//             _price = getPriceInFreeToken(_collection, _price);
//             IPaymentContract(_contract).createStake(
//                 _collection,
//                 WBNB,
//                 string(abi.encodePacked(_paywall)),
//                 msg.sender,
//                 _direction,
//                 _stakes[0], 
//                 _stakes[1],
//                 _price,
//                 _stakes[2],
//                 _note
//             );
//         }
//     }

//     function sponsorVideo(
//         address _collection, 
//         Paywall _paywall, 
//         address _gauge,
//         uint _credit
//     ) external nonReentrant {
//         require(_credit >= minSponsorship, "Invalid credit");
//         if (merchantCredits[_collection][_paywall] > 0) { 
//             //previous sponsor credit not yet used
//             require(sponsoredMessages[_collection][_paywall].contains(_gauge));
//         }
//         IERC20(WBNB).safeTransferFrom(
//             address(msg.sender), 
//             address(this), 
//             getPriceInFreeToken(_collection, _credit)
//         );
//         merchantCredits[_collection][_paywall] += _credit;
//         sponsoredMessages[_collection][_paywall].add(_gauge);
//     }

//     function updateBlacklist(address[] memory _users, bool[] memory _blacklists) external onlyAdmin {
//         require(_users.length == _blacklists.length, "Blackist: Uneven lists");
//         for (uint i = 0; i < _users.length; i++) {
//             isBlacklisted[_users[i]] = _blacklists[i];
//         }
//     }

//     function updateSponsorMessageVariables(
//         uint _minSponsorship,
//         uint _sponsorMessageShare
//     ) external onlyAdmin {
//         minSponsorship = _minSponsorship; 
//         sponsorMessageShare = _sponsorMessageShare;
//     }
    
//     function beforePaymentApplyMerchantCredit(
//         address _collection, 
//         Paywall _paywall
//     ) external {
//         require(sponsoredMessages[_collection][_paywall].length() > 0, "No merchant credit available");
//         string memory contract_tokenId = string(abi.encodePacked(_collection, _paywall));
//         require(credited[msg.sender][contract_tokenId] == address(0), "Credit already applied");
//         address _gauge = sponsoredMessages[_collection][_paywall].at(0);
//         uint _price = _askDetails[_collection][_paywall].price * sponsorMessageShare / 10000;
//         if (_price >= merchantCredits[_collection][_paywall]) {
//             paymentCredits[msg.sender][contract_tokenId] += merchantCredits[_collection][_paywall];
//             merchantCredits[_collection][_paywall] = 0;
//             sponsoredMessages[_collection][_paywall].remove(_gauge);
//         } else {
//             merchantCredits[_collection][_paywall] -= _price;
//             paymentCredits[msg.sender][contract_tokenId] += _price;
//         }
//         credited[msg.sender][contract_tokenId] = _gauge;
//     }

//     function getTransferrable(
//         address _collection, 
//         Paywall _paywall
//     ) external view returns(bool) {
//         return _askDetails[_collection][_paywall].transferrable;
//     }

//     function _beforePaymentApplyDiscount(
//         address _collection,
//         Paywall _paywall,
//         uint _price,
//         bytes32 _identityCode
//     ) public view returns(uint) {
//         uint256 discount;
//         Discount memory discountCost = _askDetails[_collection][_paywall].priceReductor.discountCost;
//         Discount memory discountNumbers = _askDetails[_collection][_paywall].priceReductor.discountNumbers;
//         string memory cid = string(abi.encodePacked(_collection, _paywall));

//         if (_askDetails[_collection][_paywall].priceReductor.discountStatus == Status.Open &&
//             _askDetails[_collection][_paywall].priceReductor.discountStart < block.timestamp
    
//         ) {
//             if (_askDetails[_collection][_paywall].priceReductor.checkIdentityCode) {
//                 require(
//                     identityLimits[cid][_identityCode] < Math.max(discountCost.limit, discountNumbers.limit),
//                     "_beforePaymentApplyDiscount: limit reached"
//                 );
//             } else {
//                 require(
//                     discountLimits[cid][msg.sender] < Math.max(discountCost.limit, discountNumbers.limit),
//                     "_beforePaymentApplyDiscount: limit reached"
//                 );
//             }

//             (uint256[] memory values1,) = INFTicket(nft_).getUserTicketsPagination(
//                 msg.sender, 
//                 _collection, 
//                 discountNumbers.cursor,
//                 discountNumbers.size
//             );
//             (,uint256 totalPrice2) = INFTicket(nft_).getUserTicketsPagination(
//                 msg.sender, 
//                 _collection, 
//                 discountCost.cursor,
//                 discountCost.size
//             );

//             if (values1.length >= discountNumbers.lowerThreshold && 
//                 values1.length <= discountNumbers.upperThreshold
//             ) {
//                 discount = discount + discountNumbers.perct;
//                 if (totalPrice2 >= discountCost.lowerThreshold && 
//                     totalPrice2 <= discountCost.upperThreshold
//                 )
//                  {
//                     discount = discount + discountCost.perct;
//                 }
//             }
//         }
//         uint256 costWithDiscount = discount == 0 ? _price : _price-_price*discount/10000;
//         return costWithDiscount;
//     }

//     function updateBurnTokenForCredit(
//         address _token,
//         uint256 _discountNumber
//     ) external     
//     {
//         burnTokenForCredit[msg.sender][_token] = _discountNumber;

//         emit UpdateBurnTokenForCredit(msg.sender, _token, _discountNumber);
//     }

//     function burnForCredit(
//         address _collection, 
//         address _token, 
//         uint256 _number,  // tokenId in case of NFTs and amount otherwise 
//         Paywall _paywall
//     ) external {
//         uint discount = burnTokenForCredit[_collection][_token];
//         require(discount > 0, "BurnForCredit: No credit available");
//         bool _isNFT;
//         try IERC721(_token).supportsInterface(0x80ac58cd) {
//             _isNFT = true;
//         } catch {
//             _isNFT = false;
//         }
//         IERC20(_token).safeTransferFrom(
//             msg.sender, 
//             address(this),
//             _number
//         );
//         uint credit = _isNFT ? discount * 1 / 10000 : discount * _number / 10000;
//         string memory contract_tokenId = string(
//             abi.encodePacked(_collection, _paywall
//         ));
//         paymentCredits[msg.sender][contract_tokenId] += credit;
//     }

//     function processCashBack(
//         address _collection, 
//         Paywall _paywall,
//         bool _creditNotCash
//     ) external {
//         uint256 cashback1;
//         uint256 cashback2;
//         Discount memory cashbackCost = _askDetails[_collection][_paywall].priceReductor.cashbackCost;
//         Discount memory cashbackNumbers = _askDetails[_collection][_paywall].priceReductor.cashbackNumbers;
//         string memory cid = string(abi.encodePacked(_collection, _paywall));
        
//         if (_askDetails[_collection][_paywall].priceReductor.cashbackStatus == Status.Open &&
//             _askDetails[_collection][_paywall].priceReductor.cashbackStart < block.timestamp
//         ) {
//             require(
//                 cashbackLimits[cid][msg.sender] < Math.max(cashbackCost.limit, cashbackNumbers.limit),
//                 "processCashBack: limit reached"
//             );

//             (uint256[] memory values1,) = INFTicket(nft_).getMerchantTicketsPagination(
//                 _collection, 
//                 cashbackNumbers.cursor,
//                 cashbackNumbers.size
//             );
//             (,uint256 totalPrice2) = INFTicket(nft_).getMerchantTicketsPagination(
//                 _collection, 
//                 cashbackCost.cursor,
//                 cashbackCost.size
//             );

//             if (values1.length >= cashbackNumbers.lowerThreshold && 
//                 values1.length <= cashbackNumbers.upperThreshold
//             ) {
//                 cashback1 += cashbackNumbers.perct;
//                 if (totalPrice2 >= cashbackCost.lowerThreshold && 
//                     totalPrice2 <= cashbackCost.upperThreshold
//                 ) {
//                     cashback2 = cashback2 + cashbackCost.perct;
//                 }
//             }

//             if (!_askDetails[_collection][_paywall].priceReductor.cashNotCredit) {
//                 _creditNotCash = true;
//             }

//         }
//         (, uint256 totalPrice11) = INFTicket(nft_).getUserTicketsPagination(
//             msg.sender, 
//             _collection, 
//             cashbackNumbers.cursor,
//             cashbackNumbers.size
//         );
//         (, uint256 totalPrice22) = INFTicket(nft_).getUserTicketsPagination(
//             msg.sender, 
//             _collection, 
//             cashbackCost.cursor,
//             cashbackCost.size
//         );
//         uint256 totalCashback = cashback1 * totalPrice11 / 10000;
//         if (cashback1 > 0) INFTicket(nft_).batchUpdateActive(
//             msg.sender, _collection, cashbackNumbers.cursor, cashbackNumbers.size, false);
//         if (cashback2 > 0) INFTicket(nft_).batchUpdateActive(
//             msg.sender, _collection, cashbackCost.cursor, cashbackCost.size, false);
//         totalCashback = totalCashback + cashback2 * totalPrice22 / 10000;  
//         if (cashbackLimits[cid][msg.sender] == 0) {
//             paywallSignups[cid].push(msg.sender);
//         }  
//         if (totalCashback > 0) cashbackLimits[cid][msg.sender] += 1;

//         if (!_creditNotCash) {
//             require(totalCashback > 0 && pendingRevenue[_collection] >= totalCashback, 
//                     "Not eligible for cashback"
//             );
//             pendingRevenue[_collection] -= 
//             getPriceInFreeToken(_collection, totalCashback); 
//             IERC20(WBNB).safeTransferFrom(
//                 address(this), 
//                 address(msg.sender), 
//                 getPriceInFreeToken(_collection, totalCashback)
//             );            
//         } else {
//             string memory contract_tokenId = string(abi.encodePacked(_collection, _paywall));
//             paymentCredits[msg.sender][contract_tokenId] += totalCashback;
//         }
//     }

//     function getPaymentCredits(
//         address _collection, 
//         Paywall _paywall
//     ) external view returns(uint) {
//         return paymentCredits[msg.sender][string(abi.encodePacked(_collection, _paywall))];
//     }

//     function updateContracts(address[] memory _contracts, bool[] memory _isAuth) external onlyAdmin {
//         require(_contracts.length == _isAuth.length, "Invalid list");
//         for (uint i = 0; i < _contracts.length; i++) {
//             unAuthorizedContracts[_contracts[i]] = _isAuth[i];
//         }
//     }
    
//     function processPayment(
//         address _collection, 
//         string memory _tokenId, 
//         address _buyer, 
//         uint256 _price,
//         DIRECTION _direction
//     ) external nonReentrant {
//         Paywall _paywall = Paywall(st2num(_tokenId));
//         require(!unAuthorizedContracts[msg.sender], "Unauthorized call to processPayment");
//         if (_direction == DIRECTION.senderToReceiver) {
//             IERC20(WBNB).safeTransferFrom(
//                 address(msg.sender), 
//                 address(this), 
//                 getPriceInFreeToken(_collection, _price)
//             );
//             string memory contract_tokenId = string(abi.encodePacked(_collection, _paywall));
//             paymentCredits[_buyer][contract_tokenId] += _price;
//         } else if (_direction == DIRECTION.receiverToSender) {
//             if (_askDetails[_collection][_paywall].priceReductor.cashNotCredit) {
//                 require(pendingRevenue[_collection] >= _price, 
//                         "Not eligible for cash refund"
//                 );
//                 pendingRevenue[_collection] -= _price;
//                 cashNotCredit[_collection] -= _price;
//                 IERC20(WBNB).safeTransferFrom(
//                     address(this), 
//                     address(msg.sender), 
//                     _price
//                 );            
//             } else {
//                 string memory contract_tokenId = string(abi.encodePacked(_collection, ""));
//                 paymentCredits[msg.sender][contract_tokenId] += _price;
//             }
//         }
//     }

//     /**
//      * @notice Buy token with WBNB by matching the price of an existing ask order
//      * @param _collection: contract address of the NFT
//      * @param _paywall: tokenId of the NFT purchased
//      */
//     function buyTokenUsingWBNB(
//         address _collection,
//         address _referrer,
//         Paywall _paywall,
//         uint256 _startPayable,
//         uint256 _tier,
//         string memory _note
//     ) external nonReentrant {
//         _collection = _askDetails[_collection][_paywall].seller;
//         require(_askDetails[_collection][_paywall].timeRemaining >= block.timestamp, "No more available");
//         require(_askDetails[_collection][_paywall].maxSupply > 0, "Not enough supply");
//         string memory contract_tokenId = string(abi.encodePacked(_collection, _paywall));
//         uint _price = subscriptionTiers[contract_tokenId][_tier];
//         bytes32 _identityCode = checkIdentityProof2(
//             _collection,
//             _paywall,
//             msg.sender, 
//             false
//         );
//         _price = _beforePaymentApplyDiscount(_collection, _paywall, _price, _identityCode); 
//         if (paymentCredits[msg.sender][string(abi.encodePacked(_collection, ""))] > 0) {
//             paymentCredits[msg.sender][contract_tokenId] += 
//             paymentCredits[msg.sender][string(abi.encodePacked(_collection, ""))];
//             paymentCredits[msg.sender][string(abi.encodePacked(_collection, ""))] = 0;
//         }
//         if (_price < subscriptionTiers[contract_tokenId][_tier]) {
//             if (_askDetails[_collection][_paywall].priceReductor.checkIdentityCode) {
//                 identityLimits[contract_tokenId][_identityCode] += 1;
//             } 
//             if (discountLimits[contract_tokenId][msg.sender] == 0) {
//                 paywallSignups[contract_tokenId].push(msg.sender);
//             }
//             discountLimits[contract_tokenId][msg.sender] += 1;
//         }
//         if (paymentCredits[msg.sender][contract_tokenId] >= _price) {
//             paymentCredits[msg.sender][contract_tokenId] -= _price;
//         } else {
//             IERC20(WBNB).safeTransferFrom(
//                 address(msg.sender), 
//                 address(this), 
//                 getPriceInFreeToken(
//                 _collection,
//                 _price - paymentCredits[msg.sender][contract_tokenId])
//             );   
//         }
//         _buyToken(
//             _collection, 
//             _referrer,
//             _paywall, 
//             _startPayable,
//             _price,
//             _tier,
//             _identityCode,
//             _note
//         );
//     }
    
//     // function batchCancelAskOrder(
//     //     address _collection, 
//     //     string memory[] memory _tokenIds
//     // ) external nonReentrant {
//     //     for (uint i = 0; i < _tokenIds.length; i++) {
//     //          cancelAskOrder(_collection,  _tokenIds[i]);
//     //     }
//     // }

//     /**
//      * @notice Cancel existing ask order
//      * @param _paywall: tokenId of the NFT
//      */
//     function cancelAskOrder(Paywall _paywall) public nonReentrant {
//         // Verify the sender has listed it
//         require(_tokenIdsOfSellerForCollection[msg.sender].contains(uint256(_paywall)), "Order: Token not listed");
        
//         // Adjust the information
//         _tokenIdsOfSellerForCollection[msg.sender].remove(uint(_paywall));
//         delete _askDetails[msg.sender][_paywall];
//         _askTokenIds[msg.sender].remove(uint(_paywall));
        
//         // Emit event
//         emit AskCancel(msg.sender, _paywall);
//     }

//     /**
//      * @notice Claim pending revenue (treasury or creators)
//      */
//     function claimPendingRevenue() external nonReentrant returns(uint) {
//         uint256 revenueToClaim;
//         if (cashNotCredit[msg.sender] > 0) {
//             revenueToClaim = pendingRevenue[msg.sender] - cashNotCredit[msg.sender];
//         } else {
//             revenueToClaim = pendingRevenue[msg.sender];
//         }
//         require(revenueToClaim != 0, "Claim: Nothing to claim");
//         pendingRevenue[msg.sender] = cashNotCredit[msg.sender];
//         if (msg.sender != adminAddress && msg.sender != lotteryAddress) {
//             checkIdentityProof(msg.sender, false);
//         }
//         IERC20(WBNB).safeTransfer(
//             address(msg.sender), 
//             revenueToClaim
//         );

//         emit RevenueClaim(msg.sender, revenueToClaim);

//         return revenueToClaim;
//     }

//     function fundPendingRevenue(address _collection, uint _amount) external nonReentrant returns(uint) {
//         IERC20(WBNB).safeTransferFrom(
//             address(msg.sender), 
//             address(this), 
//             _amount
//         );
//         pendingRevenue[_collection] += _amount;
//         return pendingRevenue[_collection];
//     }

//     function fundPendingRevenueFromNote(uint _tokenId, uint _amount) external nonReentrant returns(uint) {
//         IERC20(WBNB).safeTransferFrom(
//             address(msg.sender), 
//             address(this), 
//             _amount
//         );
//         pendingRevenueFromNote[_tokenId] += _amount;
//         return pendingRevenueFromNote[_tokenId];
//     }

//     function claimPendingRevenueFromNote(uint _tokenId) external nonReentrant {
//         require(balanceOf(msg.sender, _tokenId) > 0, "Only owner!");
//         uint256 revenueToClaim = pendingRevenueFromNote[_tokenId];
//         require(revenueToClaim != 0, "Claim: Nothing to claim");
//         pendingRevenueFromNote[_tokenId] = 0;
//         _burn(msg.sender, _tokenId, 1);
//         if (msg.sender != adminAddress && msg.sender != lotteryAddress) {
//             checkIdentityProof(msg.sender, false);
//         }
//         IERC20(WBNB).safeTransfer(
//             address(msg.sender), 
//             revenueToClaim
//         );

//         emit RevenueClaim(msg.sender, revenueToClaim);
//     }
    
//     function transferDueToNote(uint _start, uint _end) external {
//         require(notes[msg.sender].end < block.timestamp, "Current note not yet expired");
//         require(_start > _end && _start >= block.timestamp);
//         notes[msg.sender] = Note({
//             start: _start,
//             end: _end,
//             lender: permissionaryNoteTokenId
//         });
//         safeMint(msg.sender, _start, _end, permissionaryNoteTokenId++);
//     }

//     function updatePendingRevenue(address _merchant, uint _revenue) internal {
//         if (notes[_merchant].start < block.timestamp && 
//             notes[_merchant].end >= block.timestamp) {
//             pendingRevenueFromNote[notes[_merchant].lender] += _revenue;
//         } else {
//             pendingRevenue[_merchant] += _revenue;
//         }
//     }

//     // function batchCreateAskOrder(
//     //     address _collection,
//     //     string[] memory _tokenIds,
//     //     uint256 _askPrice,
//     //     uint256 _loanDuration,
//     //     uint256 _bidDuration,
//     //     uint256 _loanInterestRate,
//     //     int256 _minBidIncrementPercentage
//     // ) external nonReentrant {
//     //     for (uint i = 0; i < _tokenIds.length; i++) {
//     //         createAskOrder(
//     //             _collection,
//     //             _tokenIds[i],
//     //             _askPrice,
//     //             _loanDuration,
//     //             _bidDuration,
//     //             _loanInterestRate,
//     //             _minBidIncrementPercentage
//     //         );
//     //     }
//     // }

//     /**
//      * @notice Create ask order
//      * @param _paywall: tokenId of the NFT
//      * @param _askPrice: price for listing (in wei)
//      */
//     function createAskOrder(
//         Paywall _paywall,
//         uint256 _askPrice,
//         bool _transferrable,
//         uint256 _rsrcTokenId,
//         uint _period,
//         uint _freeTrial,
//         string memory _requiredIndentity,
//         COLOR _minIDBadgeColor,
//         string memory _valueName,
//         int256 _maxSupply,
//         uint _timeRemaining
//     ) public nonReentrant {
        
//         // Verify collection is accepted
//         require(
//             _collections[msg.sender].status == Status.Open, 
//             "Collection: Not for listing"
//         );
//         require(_maxSupply > 0 || _maxSupply < 0, "Too few supplies");

//         if (_rsrcTokenId != 0) {
//             ISuperLikeGaugeFactory(superLikeGaugeFactory)
//             .safeTransferFrom(msg.sender, address(this), _rsrcTokenId);
//         }

//         // Adjust the information
//         _tokenIdsOfSellerForCollection[msg.sender].add(uint(_paywall));
//         _askDetails[msg.sender][_paywall] = Ask({
//             seller: msg.sender,
//             price: _askPrice,
//             transferrable: _transferrable,
//             rsrcTokenId: _rsrcTokenId,
//             note: "",
//             period: _period,
//             freeTrial: _freeTrial,
//             requiredIndentity: keccak256(abi.encodePacked(_requiredIndentity)),
//             minIDBadgeColor: _minIDBadgeColor,
//             valueName: _valueName,
//             maxSupply: _maxSupply > 0 ? uint(_maxSupply) : type(uint).max,
//             timeRemaining: block.timestamp + _timeRemaining,
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
//             })
//         });

//         // Add tokenId to the askTokenIds set
//         _askTokenIds[msg.sender].add(uint(_paywall));

//         // Emit event
//         emit AskNew(msg.sender, _paywall, _askPrice);
//     }

//     function reinitializeIdentityLimits(Paywall _paywall) external {
//         string memory contract_tokenId = string(abi.encodePacked(msg.sender, _paywall));
//         for (uint i = 0; i < paywallSignups[contract_tokenId].length; i++) {
//             delete identityLimits[contract_tokenId][
//                 userToIdentityCode[paywallSignups[contract_tokenId][i]]
//             ];
//         }
//         delete paywallSignups[contract_tokenId];
//     }

//     function reinitializeDiscountLimits(Paywall _paywall) external {
//         string memory contract_tokenId = string(abi.encodePacked(msg.sender, _paywall));
//         for (uint i = 0; i < paywallSignups[contract_tokenId].length; i++) {
//             delete discountLimits[contract_tokenId][paywallSignups[contract_tokenId][i]];
//         }
//         delete paywallSignups[contract_tokenId];
//     }

//     function reinitializeCashbackLimits(Paywall _paywall) external {
//         string memory contract_tokenId = string(abi.encodePacked(msg.sender, _paywall));
//         for (uint i = 0; i < paywallSignups[contract_tokenId].length; i++) {
//             delete cashbackLimits[contract_tokenId][paywallSignups[contract_tokenId][i]];
//         }
//         delete paywallSignups[contract_tokenId];
//     }

//     /**
//      * @notice Modify existing ask order
//      * @param _paywall: paywall
//      */
//     function modifyAskOrderDiscount(
//         Paywall _paywall,
//         Status _discountStatus,   
//         uint _discountStart,   
//         bool _checkIdentityCode,
//         uint[] memory __discountNumbers,
//         uint[] memory __discountCost
//     ) external nonReentrant {
//         // Verify collection is accepted
//         require(
//             _collections[msg.sender].status == Status.Open, 
//             "Collection: Not for listing"
//         );                                     
//         if (_discountStatus == Status.Open) {
//             require(__discountNumbers.length == 6 || __discountCost.length == 6, "Invalid discounts");
            
//             _askDetails[msg.sender][_paywall].priceReductor.discountNumbers = Discount({
//                 cursor: __discountNumbers[0],
//                 size: __discountNumbers[1],
//                 perct: __discountNumbers[2],
//                 lowerThreshold: __discountNumbers[3],
//                 upperThreshold: __discountNumbers[4],
//                 limit: __discountNumbers[5]
//             });
//             _askDetails[msg.sender][_paywall].priceReductor.discountCost = Discount({
//                 cursor: __discountCost[0],
//                 size: __discountCost[1],
//                 perct: __discountCost[2],
//                 lowerThreshold: __discountCost[3],
//                 upperThreshold: __discountCost[4],
//                 limit: __discountCost[5]
//             });
//         }

//         // Emit event
//         emit AskUpdate(msg.sender, _paywall, _askDetails[msg.sender][_paywall].price);
//     }

//     function modifyAskOrderCashback(
//         Paywall _paywall,
//         Status _cashbackStatus,
//         uint _cashbackStart,
//         bool _cashNotCredit,
//         bool _checkIdentityCode,
//         uint[] memory __cashbackNumbers,
//         uint[] memory __cashbackCost
//     ) external nonReentrant {
//         // Verify collection is accepted
//         require(
//             _collections[msg.sender].status == Status.Open, 
//             "Collection: Not for listing"
//         );     
//         if (_cashbackStatus == Status.Open && _askDetails[msg.sender][_paywall].priceReductor.cashbackStart > 0) {
//             require(_askDetails[msg.sender][_paywall].priceReductor.cashbackStart + cashbackBuffer < block.timestamp,
//                 "Cashback is already active on this product"
//             );
//             require(__cashbackNumbers.length == 6 || __cashbackCost.length == 6, "Invalid cashbacks");
            
//             _askDetails[msg.sender][_paywall].priceReductor.cashNotCredit = _cashNotCredit;
//             _askDetails[msg.sender][_paywall].priceReductor.cashbackNumbers = Discount({
//                 cursor: __cashbackNumbers[0],
//                 size: __cashbackNumbers[1],
//                 perct: __cashbackNumbers[2],
//                 lowerThreshold: __cashbackNumbers[3],
//                 upperThreshold: __cashbackNumbers[4],
//                 limit: __cashbackNumbers[5]
//             });
//             _askDetails[msg.sender][_paywall].priceReductor.cashbackCost = Discount({
//                 cursor: __cashbackCost[0],
//                 size: __cashbackCost[1],
//                 perct: __cashbackCost[2],
//                 lowerThreshold: __cashbackCost[3],
//                 upperThreshold: __cashbackCost[4],
//                 limit: __cashbackCost[5]
//             });
//         }

//         // Emit event
//         emit AskUpdate(msg.sender, _paywall, _askDetails[msg.sender][_paywall].price);
//     }

//     // function batchModifyAskOrder(
//     //     address _collection,
//     //     string[] memory _tokenIds,
//     //     uint256 _newPrice,
//     //     uint256 _loanDuration,
//     //     uint256 _bidDuration,
//     //     uint256 _loanInterestRate,
//     //     int256 _minBidIncrementPercentage
//     // ) external nonReentrant {
//     //     for (uint i = 0; i < _tokenIds.length; i++) {
//     //         modifyAskOrder(
//     //             _collection,
//     //             _tokenIds[i],
//     //             _newPrice,
//     //             _loanDuration,
//     //             _bidDuration,
//     //             _loanInterestRate,
//     //             _minBidIncrementPercentage
//     //         );
//     //     }
//     // }

//     function addReferral(
//         address _referrer,
//         address _collection, 
//         Paywall _paywall
//     ) external onlyAdmin {
//         _referrals[_referrer][_paywall] = Referral({
//             seller: _askDetails[_collection][_paywall].seller,
//             referrerFee: _collections[_collection].referrerFee
//         });
//     }

//     function closeReferral(
//         address _referrer,
//         Paywall _paywall
//     ) external onlyAdmin {
//         delete _referrals[_referrer][_paywall];
//     }

//     function modifyAskOrderIdentity(
//         Paywall _paywall,
//         string memory _requiredIndentity,
//         COLOR _minIDBadgeColor,
//         string memory _valueName
//     ) public nonReentrant {
//         _askDetails[msg.sender][_paywall].requiredIndentity = keccak256(abi.encodePacked(_requiredIndentity));
//         _askDetails[msg.sender][_paywall].minIDBadgeColor = _minIDBadgeColor;
//         _askDetails[msg.sender][_paywall].valueName = _valueName;
     
//     }

//     /**
//      * @notice Modify existing ask order
//      * @param _paywall: tokenId of the NFT
//      * @param _newPrice: new price for listing (in wei)
//      */
//     function modifyAskOrder(
//         Paywall _paywall,
//         uint256 _newPrice,
//         bool _transferrable,
//         uint256 _rsrcTokenId,
//         uint _period,
//         uint _freeTrial,
//         int256 _maxSupply,
//         uint _timeRemaining
//     ) public nonReentrant {
        
//         // Verify collection is accepted
//         require(
//             _collections[msg.sender].status == Status.Open, 
//             "Collection: Not for listing"
//         );

//         if (_rsrcTokenId != 0) {
//             // Transfer resource NFT from contract to buyer
//             ISuperLikeGaugeFactory(superLikeGaugeFactory).safeTransferFrom(
//                 address(this), 
//                 msg.sender, 
//                 _askDetails[msg.sender][_paywall].rsrcTokenId
//             );
//             // Transfer resource NFT from buyer to contract
//             ISuperLikeGaugeFactory(superLikeGaugeFactory).safeTransferFrom(
//                 msg.sender, 
//                 address(this), 
//                 _rsrcTokenId
//             );
//             _askDetails[msg.sender][_paywall].rsrcTokenId = _rsrcTokenId;
//         } 

//         // Adjust the information
//         // _askDetails[msg.sender][_paywall].price = _newPrice;
//         _askDetails[msg.sender][_paywall].transferrable = _transferrable;
//         _askDetails[msg.sender][_paywall].maxSupply = _maxSupply > 0 ? uint(_maxSupply) : type(uint).max;
//         _askDetails[msg.sender][_paywall].period = _period;
//         _askDetails[msg.sender][_paywall].freeTrial = _freeTrial;
//         _askDetails[msg.sender][_paywall].timeRemaining = block.timestamp + _timeRemaining;

//         // Emit event
//         emit AskUpdate(msg.sender, _paywall, _newPrice);
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

//     /**
//      * @notice Add a new collection
//      * @param _tokenMinter: address of custom NFTicket (must be 0x00 if none)
//      * @param _referrerFee: referrer fee
//      */
//     function addCollection(
//         address _tokenMinter,
//         uint256 _referrerFee,
//         address _dtoken
//     ) external {
//         require(!isBlacklisted[msg.sender], "Blacklisted!");
//         require(!_collectionAddressSet.contains(msg.sender), "Operations: Collection already listed");
//         require(_dtokenSet.contains(_dtoken), "Operations: Invalid dtoken");
//         require(_referrerFee + lotteryFee + tradingFee <= 10000, "Invalid referrerFee");
//         // Needed to be able to mine from here
//         if (_tokenMinter != address(0)) {
//             require(
//                 INFTicket(_tokenMinter).devaddr_() == address(this), 
//                 "Transfer ownership to contract first"
//             );
//         }
        
//         _collectionAddressSet.add(msg.sender);
//         _collections[msg.sender] = Collection({
//             status: Status.Open,
//             tokenMinter: _tokenMinter,
//             referrerFee: _referrerFee,
//             dtoken: _dtoken
//         });

//         emit CollectionNew(msg.sender, _tokenMinter, _referrerFee);
//     }

//     /**
//      * @notice Allows the admin to close collection for trading and new listing
//      * @param _collection: collection address
//      * @dev Callable by admin
//      */
//     function closeCollectionForTradingAndListing(address _collection) external onlyAdmin {
//         require(_collectionAddressSet.contains(_collection), "Operations: Collection not listed");

//         _collections[_collection].status = Status.Close;
//         _collectionAddressSet.remove(_collection);

//         emit CollectionClose(_collection);
//     }

//     function closeListing(Paywall _paywall) external {
//         require(_askDetails[msg.sender][_paywall].priceReductor.cashbackStart + cashbackBuffer < block.timestamp,
//             "Cannot close listing when cashback is still valid"
//         );
//         // Update storage information
//         _tokenIdsOfSellerForCollection[msg.sender].remove(uint(_paywall));
//         delete _askDetails[msg.sender][_paywall];
//         _askTokenIds[msg.sender].remove(uint(_paywall));
//     }

//     /**
//      * @notice Modify collection characteristics
//      * @param _referrerFee: referrer fee
//      */
//     function modifyCollection(
//         address _tokenMinter,
//         uint256 _referrerFee,
//         address _dtoken
//     ) external {
//         require(_collectionAddressSet.contains(msg.sender), "Operations: Collection not listed");
//         require(_referrerFee + lotteryFee + tradingFee <= 10000, "Invalid referrerFee");
        
//         // Needed to be able to mine from here
//         if (_tokenMinter != address(0)) {
//             require(
//                 INFTicket(_tokenMinter).devaddr_() == address(this), 
//                 "Transfer ownership to contract first"
//             );
//         }
//         if (_dtoken != address(0)) {
//             require(_dtokenSet.contains(_dtoken), "Operations: Invalid dtoken");
//             _collections[msg.sender].dtoken = _dtoken;
//         }

//         _collections[msg.sender].status = Status.Open;
//         _collections[msg.sender].tokenMinter = _tokenMinter;
//         _collections[msg.sender].referrerFee = _referrerFee;

//         emit CollectionUpdate(msg.sender, _tokenMinter, _referrerFee);
//     }

//     /**
//      * @notice Allows the admin to update minimum and maximum prices for a token (in wei)
//      * @param _minimumAskPrice: minimum ask price
//      * @param _maximumAskPrice: maximum ask price
//      * @dev Callable by admin
//      */
//     function updateMinimumAndMaximumPrices(
//         uint256 _maximumArrayLength,
//         uint256 _minimumAskPrice, 
//         uint256 _minimumLotteryPrice,
//         uint256 _maximumAskPrice
//     ) external onlyAdmin {
//         require(_minimumAskPrice < _maximumAskPrice, "Operations: _minimumAskPrice < _maximumAskPrice");

//         minimumAskPrice = _minimumAskPrice;
//         maximumAskPrice = _maximumAskPrice;
//         maximumArrayLength = _maximumArrayLength;
//         minimumLotteryPrice = _minimumLotteryPrice;

//         emit NewMinimumAndMaximumAskPrices(_minimumAskPrice, _maximumAskPrice);
//     }

//     function updateCashBackBuffer(uint _cashbackBuffer) external onlyAdmin {
//         cashbackBuffer = _cashbackBuffer;
//     }

//     function updateTradingNLotteryFee(
//         uint256 _tradingFee,
//         uint256 _lotteryFee
//     ) external onlyAdmin {
//         tradingFee = _tradingFee;
//         lotteryFee = _lotteryFee;
//     }

//     function createNFTicket(
//         string memory _uri, 
//         bool _confirm,
//         address _randGen
//     ) external onlyAdmin {
//         require(nft_ == address(0) || _confirm, "MarketPlace: NFT already minted");
//         nft_ = address(new NFTicket(address(this), _uri, WBNB, _randGen));
//         nfts_.push(nft_);
//     }

//     function updateNFTDev(address _newDev) external onlyAdmin{
//         INFTicket(nft_).updateDev(_newDev);
//     }

//     /**
//      * @notice Allows the owner to recover tokens sent to the contract by mistake
//      * @param _token: token address
//      * @dev Callable by owner
//      */
//     function recoverFungibleTokens(address _token) external onlyAdmin {
//         require(_token != WBNB, "Operations: Cannot recover WBNB");
//         uint256 amountToRecover = IERC20(_token).balanceOf(address(this));
//         require(amountToRecover != 0, "Operations: No token to recover");

//         IERC20(_token).safeTransfer(address(msg.sender), amountToRecover);

//         emit TokenRecovery(_token, amountToRecover);
//     }

//     // /**
//     //  * @notice Allows the owner to recover NFTs sent to the contract by mistake
//     //  * @param _token: NFT token address
//     //  * @param _tokenId: tokenId
//     //  * @dev Callable by owner
//     //  */
//     // function recoverNonFungibleToken(address _token, string memory _tokenId) external onlyAdmin nonReentrant {
//     //     require(!_askTokenIds[_token].contains(_tokenId), "Operations: NFT not recoverable");
//     //     IERC721(_token).safeTransferFrom(address(this), address(msg.sender), _tokenId);

//     //     emit NonFungibleTokenRecovery(_token, _tokenId);
//     // }

//     /**
//      * @notice Set admin address
//      * @dev Only callable by owner
//      * @param _adminAddress: address of the admin
//      * @param _treasuryAddress: address of the treasury
//      */
//     function setAdminAndTreasuryAddresses(
//         address _adminAddress, 
//         address _treasuryAddress,
//         address _lotteryAddress
//         ) external onlyAdmin {
//         require(_adminAddress != address(0), "Operations: Admin address cannot be zero");
//         require(_treasuryAddress != address(0), "Operations: Treasury address cannot be zero");
//         require(_lotteryAddress != address(0), "Operations: Lottery address cannot be zero");
//         adminAddress = _adminAddress;
//         treasuryAddress = _treasuryAddress;
//         lotteryAddress = _lotteryAddress;

//         emit NewAdminAndTreasuryAddresses(_adminAddress, _treasuryAddress);
//     }

//     // /**
//     //  * @notice Check asks for an array of tokenIds in a collection
//     //  * @param collection: address of the collection
//     //  * @param tokenIds: array of tokenId
//     //  */
//     // function viewAsksByCollectionAndTokenIds(address collection, uint256[] calldata tokenIds)
//     //     external
//     //     view
//     //     returns (bool[] memory statuses, Ask[] memory askInfo)
//     // {
//     //     uint256 length = tokenIds.length;

//     //     statuses = new bool[](length);
//     //     askInfo = new Ask[](length);

//     //     for (uint256 i = 0; i < length; i++) {
//     //         if (_askTokenIds[collection].contains(tokenIds[i])) {
//     //             statuses[i] = true;
//     //         } else {
//     //             statuses[i] = false;
//     //         }

//     //         askInfo[i] = _askDetails[collection][tokenIds[i]];
//     //     }

//     //     return (statuses, askInfo);
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

//     //     if (length > _askTokenIds[collection].length() - cursor) {
//     //         length = _askTokenIds[collection].length() - cursor;
//     //     }

//     //     tokenIds = new uint256[](length);
//     //     askInfo = new Ask[](length);

//     //     for (uint256 i = 0; i < length; i++) {
//     //         tokenIds[i] = _askTokenIds[collection].at(cursor + i);
//     //         askInfo[i] = _askDetails[collection][tokenIds[i]];
//     //     }

//     //     return (tokenIds, askInfo, cursor + length);
//     // }

//     // /**
//     //  * @notice View ask orders for a given collection and a seller
//     //  * @param collection: address of the collection
//     //  * @param seller: address of the seller
//     //  * @param cursor: cursor
//     //  * @param size: size of the response
//     //  */
//     // function viewAsksByCollectionAndSeller(
//     //     address collection,
//     //     address seller,
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

//     //     if (length > _tokenIdsOfSellerForCollection[seller][collection].length() - cursor) {
//     //         length = _tokenIdsOfSellerForCollection[seller][collection].length() - cursor;
//     //     }

//     //     tokenIds = new uint256[](length);
//     //     askInfo = new Ask[](length);

//     //     for (uint256 i = 0; i < length; i++) {
//     //         tokenIds[i] = _tokenIdsOfSellerForCollection[seller][collection].at(cursor + i);
//     //         askInfo[i] = _askDetails[collection][tokenIds[i]];
//     //     }

//     //     return (tokenIds, askInfo, cursor + length);
//     // }

//     /*
//      * @notice View addresses and details for all the collections available for trading
//      * @param cursor: cursor
//      * @param size: size of the response
//      */
//     function viewCollections(uint256 cursor, uint256 size)
//         external
//         view
//         returns (
//             address[] memory collectionAddresses,
//             Collection[] memory collectionDetails,
//             uint256
//         )
//     {
//         uint256 length = size;

//         if (length > _collectionAddressSet.length() - cursor) {
//             length = _collectionAddressSet.length() - cursor;
//         }

//         collectionAddresses = new address[](length);
//         collectionDetails = new Collection[](length);

//         for (uint256 i = 0; i < length; i++) {
//             collectionAddresses[i] = _collectionAddressSet.at(cursor + i);
//             collectionDetails[i] = _collections[collectionAddresses[i]];
//         }

//         return (collectionAddresses, collectionDetails, cursor + length);
//     }

//     /**
//      * @notice Calculate price and associated fees for a collection
//      * @param collection: address of the collection
//      * @param price: listed price
//      */
//     function calculatePriceAndFeesForCollection(
//         address collection, 
//         address subscription, 
//         address referrer,
//         Paywall paywall, 
//         uint256 price
//     )
//         external
//         view
//         returns (
//             uint256 netPrice,
//             uint256 _tradingFee,
//             uint256 _lotteryFee,
//             uint256 referrerFee
//     ) {
//         if (_collections[collection].status != Status.Open) {
//             return (0, 0, 0, 0);
//         }
//         return (_calculatePriceAndFeesForCollection(collection, subscription, referrer, paywall, price));
//     }

//     function updateCollectionTrustWorthyAuditors(address[] memory _gauges, bool _add) external {
//         for (uint i = 0; i < _gauges.length; i++) {
//             if (_add) {
//                 collectionTrustWorthyAuditors[msg.sender].add(_gauges[i]);
//             } else {
//                 collectionTrustWorthyAuditors[msg.sender].remove(_gauges[i]);
//             }
//         }
//     }

//     function getAllCollectionTrustWorthyAuditors(address _collection) external view returns(address[] memory _auditors) {
//         _auditors = new address[](collectionTrustWorthyAuditors[_collection].length());
//         for (uint i = 0; i < collectionTrustWorthyAuditors[_collection].length(); i++) {
//             _auditors[i] = collectionTrustWorthyAuditors[_collection].at(i);
//         }
//     }

//     function checkIdentityProof2(
//         address _collection,
//         Paywall _paywall, 
//         address _owner, 
//         bool _check
//     ) public returns(bytes32 identityCode) {
//         string memory _valueName = _askDetails[_collection][_paywall].valueName;
//         if (keccak256(abi.encodePacked(_valueName)) != keccak256(abi.encodePacked("")) || _check) {
//             (
//                 string memory ssid,
//                 string memory value, 
//                 address _gauge 
//             ) = ISuperLikeGaugeFactory(superLikeGaugeFactory).getIdentityValue(_owner, _valueName);
//             require(ISuperLikeGauge(_gauge).badgeColor() >= uint(_askDetails[_collection][_paywall].minIDBadgeColor), "ID Gauge inelligible");
//             require(keccak256(abi.encodePacked(value)) == _askDetails[_collection][_paywall].requiredIndentity || 
//             _askDetails[_collection][_paywall].requiredIndentity == 0, "Invalid comparator");
//             require(collectionTrustWorthyAuditors[_collection].length() == 0 || collectionTrustWorthyAuditors[_collection].contains(_gauge),
//                     "Only identity proofs from trustworthy auditors"
//             );
//             identityCode = keccak256(abi.encodePacked(ssid));
//             require(!blackListedIdentities[identityCode], "You identiyCode is blacklisted");
//             if (identityProofs[identityCode] == address(0)) {
//                 // only register the first time
//                 identityProofs[identityCode] = _owner;
//             }
//             userToIdentityCode[_owner] = identityCode;
//         }
//     }

//     function updateBlockContracts(bool _block) external onlyAdmin {
//         blockContracts = _block;
//     }

//     /**
//      * @notice Buy token by matching the price of an existing ask order
//      * @param _collection: contract address of the NFT
//      * @param _paywall: tokenId of the NFT purchased
//      * @param _price: price (must match the askPrice from the seller)
//      */
//     function _buyToken(
//         address _collection,
//         address _referrer,
//         Paywall _paywall,
//         uint256 _startPayable,
//         uint256 _price,
//         uint256 _tier,
//         bytes32 _identityCode,
//         string memory _note
//     ) internal {
//         if (blockContracts) require(!isContract(msg.sender), "No contracts!");
//         require(_collections[_collection].status == Status.Open, "Collection: Not for trading");
//         require(_askTokenIds[_collection].contains(uint(_paywall)), "Paywall not available");

//         string memory contract_tokenId = string(abi.encodePacked(_collection, _paywall));
//         require(subscriptionInfo[contract_tokenId][msg.sender].startPayable == 0, 
//         "Only new users, delete previous subscription first!");
//         uint _freeTrial;
//         uint _freePeriod;
//         if (_askDetails[_collection][_paywall].priceReductor.checkIdentityCode) {
//             _freeTrial = identityLimits[contract_tokenId][_identityCode] > 1 ? 0 : block.timestamp + _startPayable;
//             _freePeriod = identityLimits[contract_tokenId][_identityCode] > 1 ? 0 : 
//             _askDetails[_collection][_paywall].freeTrial * _askDetails[_collection][_paywall].period;
//         }
//         subscriptionInfo[contract_tokenId][msg.sender] = SubscriptionInfo({
//             referrer: _referrer, 
//             paidPayable: subscriptionTiers[contract_tokenId][_tier],
//             amountPayable: subscriptionTiers[contract_tokenId][_tier],
//             periodPayable: _askDetails[_collection][_paywall].period * _tier,
//             tradingFee: tradingFee, 
//             freeTrial: _freeTrial,
//             autoCharge: false,
//             identityCode: _identityCode,
//             startPayable: block.timestamp + _startPayable + _freePeriod
//         });
//         AllSubscriptions[contract_tokenId].push(msg.sender);
//         _processTrade(
//             _collection,
//             _referrer,
//             _paywall,
//             msg.sender,
//             _price,
//             _note
//         );
//     }

//     function _processTrade(
//         address _collection,
//         address _referrer,
//         Paywall _paywall,
//         address _owner,
//         uint _price,
//         string memory _note
//     ) internal {
//         require(msg.sender != _askDetails[_collection][_paywall].seller, "Buy: Buyer cannot be seller");
//         // Calculate the net price (collected by seller), trading fee (collected by treasury), creator fee (collected by creator)
//         (uint256 netPrice, uint256 _tradingFee, uint256 _lotteryFee, uint256 referrerFee) = _calculatePriceAndFeesForCollection(
//             _collection,
//             _owner,
//             _referrer,
//             _paywall,
//             _price
//         );
        
//         // Transfer WBNB
//         if (requiredIndentity == keccak256(abi.encodePacked("")) && 
//             (!_askDetails[_collection][_paywall].priceReductor.cashNotCredit) &&
//             (notes[_askDetails[_collection][_paywall].seller].start >= block.timestamp ||
//             notes[_askDetails[_collection][_paywall].seller].end < block.timestamp)) {
//             IERC20(WBNB).safeTransfer(
//                 _askDetails[_collection][_paywall].seller, 
//                 getPriceInFreeToken(_collection, netPrice)
//             );
//         } else {
//             updatePendingRevenue(
//                 _askDetails[_collection][_paywall].seller, 
//                 getPriceInFreeToken(_collection, netPrice)
//             );
//             if (_askDetails[_collection][_paywall].priceReductor.cashNotCredit) {
//                 cashNotCredit[_collection] += getPriceInFreeToken(_collection, netPrice);
//             }
//         }
//         // Update pending revenues for treasury/creator (if any!)
//         if (referrerFee != 0 && _referrer != address(0)) {
//             updatePendingRevenue(
//                 _referrer, 
//                 getPriceInFreeToken(_collection, referrerFee)
//             );
//         }

//         // Update trading fee if not equal to 0
//         if (_tradingFee != 0) {
//             pendingRevenue[treasuryAddress] += 
//             getPriceInFreeToken(_collection, _tradingFee);
//         }

//         if (_lotteryFee != 0) {
//             pendingRevenue[lotteryAddress] += 
//             getPriceInFreeToken(_collection, _lotteryFee);
//         }

//         // Mint NFTicket to buyer
//         address _tokenMinter;
//         if (_collections[_collection].tokenMinter != address(0)) {
//             _tokenMinter = _collections[_collection].tokenMinter;
//         } else {
//             _tokenMinter = nft_;
//         }
//         // uint[] memory _emptyArray;
//         uint[] memory _ids = INFTicket(_tokenMinter).batchMint(
//             msg.sender,
//             _collection,
//             1,
//             _price,
//             string(abi.encodePacked(_paywall)),
//             _note,
//             new uint[](1)
//         );
//         _askDetails[_collection][_paywall].maxSupply -= 1;

//         // sponsoring
//         address _gauge = credited[msg.sender][string(abi.encodePacked(_collection, _paywall))];
//         if (_gauge != address(0)) {
//             string memory message = ISuperLikeGauge(_gauge).cancan_email();
//             INFTicket(_tokenMinter).addSponsoredMessagesAdmin(_ids[0], message);
//         }
//         // voting
//         if (superLikeGaugeFactory != address(0)) {
//             _price = getPriceInFreeToken(_collection, _price);
//             address _userGauge = ISuperLikeGaugeFactory(superLikeGaugeFactory).userGauge(msg.sender);
//             address[] memory _poolVote = new address[](1);
//             int256[] memory _poolWeight = new int256[](1);
//             _poolVote[0] = _collection;
//             _poolWeight[0] = int256(Math.min(_price, maxWeight));
//             if (_userGauge != address(0) && ISuperLikeGauge(_userGauge).tokenId() > 0) {
//                 IBusinessVoter(businessVoter).vote(
//                     ISuperLikeGauge(_userGauge).tokenId(),
//                     _poolVote,
//                     _poolWeight
//                 );
//                 ISuperLikeGauge(_userGauge).updateLotteryCredits(
//                     _price >= minimumLotteryPrice ? 1 : 0,
//                     uint(_poolWeight[0])
//                 );
//                 // if user has been referred
//                 if (ISuperLikeGaugeFactory(superLikeGaugeFactory).referrers(msg.sender) > 0) {
//                     IReferralVoter(referralVoter).vote(
//                         ISuperLikeGauge(_userGauge).tokenId(),
//                         _poolVote,
//                         _poolWeight
//                     );
//                 }
//             }
//         }

//         // Emit event
//         emit Trade(
//             _collection, 
//             _paywall, 
//             _askDetails[_collection][_paywall].seller, 
//             msg.sender, 
//             _price, 
//             netPrice
//         );
//     }

//     function getPriceInFreeToken(address _collection, uint _priceInDtoken) public returns(uint) {
//         // get collection's dtoken address and get multiplier from liquidity pool
//         uint _multiplier = 1;
//         // return price conversion from dtoken to free token
//         return _priceInDtoken * _multiplier;
//     }

//     function updateVoterNGaugeFactory(
//         uint _maxWeight,
//         address _businessVoter,
//         address _referralVoter,
//         address _superLikeGaugeFactory
//     ) external onlyAdmin {
//         maxWeight = _maxWeight;
//         businessVoter = _businessVoter;
//         referralVoter = _referralVoter;
//         superLikeGaugeFactory = _superLikeGaugeFactory;
//     }

//     /**
//      * @notice Calculate price and associated fees for a collection
//      * @param _collection: address of the collection
//      * @param _askPrice: listed price
//      */
//     function _calculatePriceAndFeesForCollection(
//         address _collection, 
//         address _subscription, 
//         address _referrer, 
//         Paywall _paywall,
//         uint256 _askPrice
//     )
//         internal
//         view
//         returns (
//             uint256 netPrice,
//             uint256 _tradingFee,
//             uint256 _lotteryFee,
//             uint256 referrerFee
//         )
//     {
//         string memory contract_tokenId = string(abi.encodePacked(_collection, _paywall));
//         _tradingFee = (_askPrice * subscriptionInfo[contract_tokenId][_subscription].tradingFee) / 10000;
//         _lotteryFee = (_askPrice * lotteryFee) / 10000;
//         if (_referrer != address(0)) {
//             referrerFee = (_askPrice * _referrals[_referrer][_paywall].referrerFee) / 10000;
//         }

//         netPrice = _askPrice - _tradingFee - _lotteryFee - referrerFee;

//         return (netPrice, _tradingFee, _lotteryFee, referrerFee);
//     }

//      function updateSubscriptionTiers(
//         Paywall _paywall,
//         uint[] memory _times, 
//         uint[] memory _prices
//     ) external onlyAdmin {
//         require(_times.length == _prices.length, "Uneven lists");
//         string memory contract_tokenId = string(abi.encodePacked(msg.sender, _paywall));
//         AllTiers[contract_tokenId] = _times;
//         for (uint i = 0; i < _times.length; i++) {
//             subscriptionTiers[contract_tokenId][_times[i]] = _prices[i];
//         }
//     }

//     function autoChargeAll(Paywall _paywall) external {
//         string memory contract_tokenId = string(abi.encodePacked(msg.sender, _paywall));
//         autoCharge(msg.sender, _paywall, AllAutoCharges[contract_tokenId], 0, 0);
//     }

//     function autoCharge(
//         address _collection,
//         Paywall _paywall, 
//         address[] memory _subscriptions,
//         uint _amount,
//         uint _numPeriods
//     ) public {
//         require(msg.sender == _collection ||
//             (_subscriptions.length == 1 && _subscriptions[0] == msg.sender),
//             "Either merchant or subscription owner only!"
//         );
//         string memory contract_tokenId = string(abi.encodePacked(_collection, _paywall));
//         for (uint i = 0; i < _subscriptions.length; i++) {
//             if (subscriptionInfo[contract_tokenId][_subscriptions[i]].autoCharge ||
//                 _subscriptions[0] == msg.sender
//             ) {
//                 checkIdentityProof2(
//                     _collection,
//                     _paywall,
//                     _subscriptions[i], 
//                     false
//                 );
//                 (uint _price,) = getDuePayable(_collection, _paywall, _subscriptions[i], _numPeriods);
//                 if (_amount != 0) _price = Math.min(_amount, _price);
//                 if (paymentCredits[_subscriptions[i]][contract_tokenId] >= _price) {
//                     paymentCredits[_subscriptions[i]][contract_tokenId] -= _price;
//                 } else {
//                     IERC20(WBNB).safeTransferFrom(
//                         address(_subscriptions[i]), 
//                         address(this), 
//                         getPriceInFreeToken(
//                         _collection,
//                         _price - paymentCredits[_subscriptions[i]][contract_tokenId])
//                     );   
//                 }
//                 _processTrade(
//                     _collection,
//                     subscriptionInfo[contract_tokenId][_subscriptions[i]].referrer,
//                     _paywall,
//                     _subscriptions[i],
//                     _price,
//                     "Auto Charge"
//                 );
//             }
//         }
//     }

//     function updateAutoCharge(address _collection, Paywall _paywall, bool _autoCharge) external {
//         string memory contract_tokenId = string(abi.encodePacked(_collection, _paywall));
//         if (_autoCharge) {
//             AllAutoCharges[contract_tokenId].push(msg.sender);
//         } else {
//             address[] memory _addresses = new address[](AllAutoCharges[contract_tokenId].length - 1);
//             for (uint i = 0; i < AllAutoCharges[contract_tokenId].length; i++) {
//                 if(AllAutoCharges[contract_tokenId][i] != msg.sender) {
//                     _addresses[i] = AllAutoCharges[contract_tokenId][i];
//                 }
//             }
//             AllAutoCharges[contract_tokenId]= _addresses;
//         }
//         subscriptionInfo[contract_tokenId][msg.sender].autoCharge = _autoCharge;

//         emit UpdateAutoCharge(msg.sender, block.timestamp);
//     }

//     function getNumPeriods(uint tm1, uint tm2, uint period) public pure returns(uint) {
//         if (tm1 == 0 || tm2 == 0 || tm2 <= tm1) return 0;
//         return period > 0 ? (tm2 - tm1) / period : 1;
//     }

//     function getDuePayable(
//         address _collection,
//         Paywall _paywall,
//         address _subscription,
//         uint _numPeriods
//     ) public view returns(uint, uint) {
//         string memory contract_tokenId = string(abi.encodePacked(_collection, _paywall));
//         SubscriptionInfo storage invoice = subscriptionInfo[contract_tokenId][_subscription];   
//         uint numPeriods = getNumPeriods(
//             invoice.startPayable, 
//             block.timestamp, 
//             invoice.periodPayable
//         );
//         numPeriods += _numPeriods;
//         if (invoice.amountPayable * numPeriods > subscriptionInfo[contract_tokenId][_subscription].paidPayable) {
//             return (
//                 invoice.amountPayable * numPeriods - subscriptionInfo[contract_tokenId][_subscription].paidPayable,
//                 invoice.periodPayable * numPeriods + invoice.startPayable
//             );
//         }
//         return (0, numPeriods * invoice.periodPayable + invoice.startPayable);
//     }
    
//     function ongoingSubscription(
//         address _collection,
//         Paywall _paywall,
//         address _subscription
//     ) external view returns(bool) {
//         string memory contract_tokenId = string(abi.encodePacked(_collection, _paywall));
//         SubscriptionInfo storage invoice = subscriptionInfo[contract_tokenId][_subscription];   
//         if (invoice.freeTrial > block.timestamp) {
//             return false;
//         } else if (
//             invoice.freeTrial <= block.timestamp && 
//             invoice.startPayable > block.timestamp
//         ) {
//             return true;
//         }
//         (uint _due,) = getDuePayable(_collection, _paywall, _subscription, 0);
//         return _due == 0;
//     }

//     function deleteSubscription(address _collection, Paywall _paywall) public {
//         string memory contract_tokenId = string(abi.encodePacked(_collection, _paywall));
//         delete subscriptionInfo[contract_tokenId][msg.sender];

//         emit DeleteSubscription(msg.sender, block.timestamp);
//     }

//     function putOnTransferList(uint[] memory _tokenIds) external {
//         for (uint i = 0; i < _tokenIds.length; i++) {
//             require(INFTicket(nft_).getTicketOwner(_tokenIds[i]) == msg.sender, "Only owner!");
//             transferList[_tokenIds[i]] = msg.sender;
//         }
//     }
    
//     function transferSubscription(uint _tokenId, address _collection, Paywall _paywall) external {
//         require(INFTicket(nft_).getReceiver(_tokenId) == msg.sender, "Only receiver!");

//         string memory contract_tokenId = string(abi.encodePacked(_collection, _paywall));
//         address _prevOwner = transferList[_tokenId];
//         subscriptionInfo[contract_tokenId][msg.sender] = subscriptionInfo[contract_tokenId][_prevOwner];
//         delete transferList[_tokenId];
//         deleteSubscription(_collection, _paywall);
//     }

//     function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
//         return this.onERC1155Received.selector;
//     }

//     function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
//         return this.onERC1155BatchReceived.selector;
//     }

//     function isContract(address account) internal view returns (bool) {
//         // This method relies on extcodesize, which returns 0 for contracts in
//         // construction, since the code is only stored at the end of the
//         // constructor execution.

//         uint256 size;
//         // solhint-disable-next-line no-inline-assembly
//         assembly {
//             size := extcodesize(account)
//         }
//         return size > 0;
//     }

//     function st2num(string memory numString) public pure returns(uint) {
//         uint  val=0;
//         bytes   memory stringBytes = bytes(numString);
//         for (uint  i =  0; i<stringBytes.length; i++) {
//             uint exp = stringBytes.length - i;
//             bytes1 ival = stringBytes[i];
//             uint8 uval = uint8(ival);
//            uint jval = uval - uint(0x30);
   
//            val +=  (uint(jval) * (10**(exp-1))); 
//         }
//       return val;
//     }
// }
// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;
// pragma experimental ABIEncoderV2;

// import './Library.sol';

// // File: contracts/ERC721NFTMarketV1.sol

// contract NFTMarketPlace is ERC721Pausable {
//     using SafeERC20 for IERC20;

//     mapping(address => uint) public treasuryRevenue;
//     mapping(address => uint) public lotteryRevenue;

//     address public businessVoter;
//     address public referralVoter;
//     mapping(address => mapping(uint => address)) public taxContracts;
//     mapping(address => mapping(uint => uint256)) public pendingRevenue; // For creator/treasury to claim
//     mapping(address => mapping(uint256 => uint256)) public pendingRevenueFromNote;
//     mapping(address => mapping(uint => uint)) public cashbackFund;
//     address private marketHelpers;
//     address private marketOrders;
//     address private marketCollections;
    
//     mapping(string => mapping(address => uint)) private discountLimits;
//     mapping(string => mapping(address => uint)) private cashbackLimits;
//     mapping(string => mapping(bytes32 => uint)) private identityLimits;
//     mapping(string => address[]) private paywallSignups;

//     struct Note {
//         uint start;
//         uint end;
//         uint lender;
//     }
//     mapping(address => Note) public notes;
//     uint public permissionaryNoteTokenId = 1;


//     // Recover NFT tokens sent by accident
//     event NonFungibleTokenRecovery(address indexed token, uint256 indexed tokenId);

//     // Pending revenue is claimed
//     event RevenueClaim(address indexed claimer, uint256 amount);

//     // Recover ERC20 tokens sent by accident
//     event TokenRecovery(address indexed token, uint256 amount);

//     // modifier onlyBorrower(address _collection, uint256 _tokenId) {
//     //     require(_loanTokenIds[_collection][_tokenId] > 0, "Loans: Non existant loan");
//     //     require(_loans[_collection][_tokenId].seller == msg.sender , 'Loans: Not borrower');
//     //     _;
//     // }

//     // modifier onlyLender(address _collection, uint256 _tokenId) {
//     //    require(_loanTokenIds[_collection][_tokenId] > 0, "Loans: Non existant loan");
//     //    require(ownerOf(_loanTokenIds[_collection][_tokenId]) == msg.sender , 'Loans: Not lender');
//     //     _;
//     // }

//     /**
//      * @notice Constructor
//      * @param _marketCollections: address of the admin
//      * @param _marketOrders: address of the treasury
//      * @param _marketHelpers: address of the treasury
//      */
//     constructor(
//         address _marketCollections,
//         address _marketOrders,
//         address _marketHelpers
//     ) ERC721("NFTNote", "nNFT") {
//         marketCollections = _marketCollections;
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

//     /**
//      * @notice Buy token with WBNB by matching the price of an existing ask order
//      * @param _collection: contract address of the NFT
//      * @param _tokenId: tokenId of the NFT purchased
//      */
//     function buyWithContract(
//         address _collection,
//         address _user,
//         address _referrer,
//         uint256 _tokenId,
//         uint256 _userTokenId,
//         address _rsrcCollection, 
//         uint256 _rsrcTokenId
//     ) external lock {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_user);
//         (Status status,,,,,,,,,,,,) = IMarketPlace(marketCollections)._collections(_collectionId);
//         NFTAsk memory ask = INFTMarketPlace(marketOrders)._askDetails(_collectionId, _tokenId);
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
//             (uint _price, bool _applied) = INFTMarketPlace(marketHelpers).getRealPrice(_user, _collection, _tokenId, ask.price, _identityCode);
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

//     function updateTaxContract(address _taxContract, address _token) external {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         taxContracts[_token][_collectionId] = _taxContract;
//     }

//     function processCashBack(
//         address _collection, 
//         bytes32 _tokenId,
//         bool _creditNotCash,
//         bytes32 _applyToTokenId
//     ) external lock {
//         uint256 cashback1;
//         uint256 cashback2;
//         address nft_ = IMarketPlace(marketCollections).nft_();
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_collection);
//         Ask memory ask = IMarketPlace(marketOrders)._askDetails(_collectionId, _tokenId);
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
//             pendingRevenue[_token][_collectionId] += Math.min(totalCashback, cashbackFund[_token][_collectionId]);
//         }
//         cashbackFund[_token][_collectionId] -= totalCashback; 
//         }
//     }

//     /**
//      * @notice Claim pending revenue (treasury or creators)
//      */
//     function claimPendingRevenue(address _token) external lock returns(uint) {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(msg.sender);
//         uint revenueToClaim = pendingRevenue[_token][_collectionId];
//         require(revenueToClaim > 0, "Claim: Nothing to claim");
//         pendingRevenue[_token][_collectionId] = 0;
//         IMarketPlace(marketCollections).checkIdentityProof(msg.sender, false);
//         IERC20(_token).safeTransfer(address(msg.sender), revenueToClaim);
        
//         emit RevenueClaim(msg.sender, revenueToClaim);

//         return revenueToClaim;
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

//     // Used by non creators to back tokens while buying them
//     function backToken(
//         bool _back,
//         address _collection, 
//         uint256 _tokenId,
//         address _rsrcCollection, 
//         uint256 _rsrcTokenId
//     ) public {
//         // // rsrc tokens do not need to be backed
//         // if (!_rsrcCollectionAddressSet.contains(_collection)) { 
//         //     require(_collectionAddressSet.contains(_collection), "Operations: Collection not listed");
//         //     require(_rsrcCollection == address(0) ||
//         //     _rsrcCollectionAddressSet.contains(_rsrcCollection), "Operations: Not a resource Collection");
//         //     if (!_back) { // use seller's resource
//         //         _rsrcCollection = _collections[_collection].rsrcCollection;
//         //         uint _lastIdx = _collections[_collection].rsrcTokenIds.length - 1;
//         //         _rsrcTokenId = _collections[_collection].rsrcTokenIds[_lastIdx];
//         //         INaturalResourceNFT(_rsrcCollection).detach(_rsrcTokenId);
//         //         INaturalResourceNFT(_rsrcCollection).attach(_rsrcTokenId, 0, msg.sender);
//         //         delete _collections[_collection].rsrcTokenIds[_lastIdx];
//         //     } else { // use buyer's resource
//         //         INaturalResourceNFT(_rsrcCollection).safeTransferNAttach(
//         //             msg.sender,
//         //             0,
//         //             msg.sender,
//         //             address(this), 
//         //             _rsrcTokenId,
//         //             1,
//         //             msg.data
//         //         );
//         //     }
//         //     require(_rsrcTokenId > 0, "Operations: Invalid rsrc token Id");
//         //     string memory contract_tokenId = string(
//         //         abi.encodePacked(_collection, _tokenId));

//         //     backings[contract_tokenId][_rsrcCollection] = _rsrcTokenId;
//         // }
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
//         bytes32 _tokenId,
//         uint256 _userTokenId,
//         uint256 _price,
//         uint[] memory _options
//     ) internal {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_collection);
//         (Status status,,,,,,,) = IMarketPlace(marketCollections)._collections(_collectionId);
//         require(status == Status.Open, "Collection: Not for trading");
//         // require(IMarketPlace(marketOrders)._askTokenIds(_collectionId).contains(uint(keccak256(abi.encodePacked(_tokenId)))), "Buy: Not for sale");
//         Ask memory ask = IMarketPlace(marketOrders)._askDetails(_collectionId, _tokenId);
//         address _token = ask.tokenInfo.usetFIAT ? ask.tokenInfo.tFIAT : ve(ask.tokenInfo.ve).token();
//         if (ask.tokenInfo.direction == DIRECTION.senderToReceiver) {
//             IERC20(_token).safeTransferFrom(msg.sender, address(this), _price);
//         } 
//         if (ask.bidDuration != 0 && ask.tokenInfo.direction == DIRECTION.senderToReceiver) { // Auction
//             IMarketPlace(marketHelpers).checkAuction(_price, _collection, msg.sender, _tokenId);
//         } else {
//             _processTrade(
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

//     function checkIdentityProof2(
//         address _collection,
//         uint _tokenId, 
//         address _owner, 
//         bool _check
//     ) public returns(bytes32 identityCode) {
//         // string memory _valueName = _askDetails[_collection][_tokenId].identityProof.valueName;
//         // address _seller = _askDetails[_collection][_tokenId].seller;
//         // if (keccak256(abi.encodePacked(_valueName)) != keccak256(abi.encodePacked("")) || _check) {
//         //     (
//         //         string memory ssid,
//         //         string memory value, 
//         //         address _gauge 
//         //     ) = ISuperLikeGaugeFactory(superLikeGaugeFactory).getIdentityValue(_owner, _valueName);
//         //     require(ISuperLikeGauge(_gauge).badgeColor() >= uint(_askDetails[_collection][_tokenId].identityProof.minIDBadgeColor), "ID Gauge inelligible");
//         //     require(keccak256(abi.encodePacked(value)) == _askDetails[_collection][_tokenId].identityProof.requiredIndentity || 
//         //     _askDetails[_collection][_tokenId].identityProof.requiredIndentity == 0, "Invalid comparator");
//         //     require(collectionTrustWorthyAuditors[_seller].length() == 0 || collectionTrustWorthyAuditors[_seller].contains(_gauge),
//         //             "Only identity proofs from trustworthy auditors"
//         //     );
//         //     identityCode = keccak256(abi.encodePacked(ssid));
//         //     require(!blackListedIdentities[identityCode], "You identiyCode is blacklisted");
//         //     if (identityProofs[identityCode] == address(0)) {
//         //         // only register the first time
//         //         identityProofs[identityCode] = _owner;
//         //     }
//         //     userToIdentityCode[_owner] = identityCode;
//         // }
//     }

//     function processTrade(
//         address _collection,
//         address _referrer,
//         address _user,
//         bytes32 _tokenId,
//         uint _userTokenId,
//         uint _price,
//         uint[] memory _options
//     ) external {
//         require(marketHelpers == msg.sender);
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
//         bytes32 _tokenId,
//         uint _userTokenId,
//         uint _price,
//         uint[] memory _options
//     ) internal {
//         uint _collectionId = IMarketPlace(marketCollections).addressToCollectionId(_collection);
//         Ask memory ask = IMarketPlace(marketOrders)._askDetails(_collectionId, _tokenId);
//         address _token = ask.tokenInfo.usetFIAT ? ask.tokenInfo.tFIAT : ve(ask.tokenInfo.ve).token();
//         require(ask.seller != msg.sender && ask.seller != _user, "Buy: Buyer cannot be seller");
//         // Calculate the net price (collected by seller), trading fee (collected by treasury), creator fee (collected by creator)
//         (uint256 netPrice, uint256 _tradingFee, uint256 _lotteryFee, uint256 _referrerFee, uint256 _cashbackFee, uint _recurringFee) = 
//         _calculatePriceAndFeesForCollection(
//             _collection,
//             _referrer,
//             _tokenId,
//             _price
//         );
//         // Transfer _token
//         if (ask.tokenInfo.direction == DIRECTION.senderToReceiver) {
//             updatePendingRevenue(_token, ask.seller, netPrice);
//             cashbackFund[_token][_collectionId] += _cashbackFee;
//         } else {
//             require(pendingRevenue[_token][_collectionId] >= _price);
//             pendingRevenue[_token][_collectionId] -= _price;
//             IERC20(_token).safeTransfer(msg.sender, netPrice);
//         }
//         // Update pending revenues for treasury/creator (if any!)
//         if (_referrerFee != 0 && _referrer != address(0x0)) {
//             updatePendingRevenue(_token, _referrer, _referrerFee);
//         }
//         // Update trading fee if not equal to 0
//         if (_tradingFee != 0) {
//             treasuryRevenue[_token] += _tradingFee;
//         }
//         if (_lotteryFee != 0) {
//             lotteryRevenue[_token] += _lotteryFee;
//         }
//         if (_recurringFee != 0) {
//             erc20(_token).approve(marketOrders, _recurringFee);
//             IMarketPlace(marketOrders).updateRecurringBountyRevenue(_token, _collectionId, _recurringFee);
//         }
//         IMarketPlace(marketHelpers).mintNFTicket(msg.sender, _collectionId, _tokenId, _options);
//         IMarketPlace(marketOrders).decrementMaxSupply(_collectionId, _tokenId);
//         IMarketPlace(marketHelpers).vote(ask.tokenInfo.ve, msg.sender, _tokenId, _userTokenId, _collectionId, _lotteryFee);

//         // Emit event
//         emit Trade(
//             _collection, 
//             _tokenId, 
//             ask.seller, 
//             msg.sender, 
//             _price, 
//             netPrice
//         );
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

//     /**
//      * @notice Calculate price and associated fees for a collection
//      * @param _collection: address of the collection
//      * @param _askPrice: listed price
//      */
//     function _calculatePriceAndFeesForCollection(
//         address _collection, 
//         address _referrer, 
//         bytes32 _tokenId,
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
//         return IMarketPlace(marketHelpers).calculatePriceAndFeesForCollection(
//             _collection,
//             _referrer,
//             _tokenId,
//             _askPrice
//         );
//     }
// }
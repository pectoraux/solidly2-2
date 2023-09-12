// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;

// import "./Library.sol";

// // Gauges are used to incentivize pools, they emit reward tokens over 7 days for staked LP tokens
// contract Paywall {
//     using SafeERC20 for IERC20;
    
//     uint public collectionId;
//     mapping(address => uint) private addressToProtocolId;
//     struct ProtocolInfo {
//         uint ticketId;
//         uint startReceivable;
//         uint amountReceivable;
//         uint periodReceivable;
//         uint paidReceivable;
//         uint freeTrialPeriod;
//         uint userTokenId;
//         uint optionId;
//         uint profileId;
//         uint referrerCollectionId;
//         bool autoCharge;
//         string item;
//     }
//     mapping(uint => ProtocolInfo) public protocolInfo;
//     uint public lastProtocolId = 1;
//     mapping(address => uint) public pendingRevenue;
//     uint public bufferTime;
//     mapping(uint => uint) public freeTrialPeriod;
//     address public devaddr_;
//     address private helper;
//     bool public profileIdRequired;
//     address public contractAddress;
//     uint public pricePerSecond;
//     struct Divisor {
//         uint factor;
//         uint period;
//         uint cap;
//     }
//     mapping(uint => Divisor) public  penaltyDivisor;
//     mapping(uint => Divisor) public discountDivisor;
//     struct PartnerShip {
//         uint partnerCollectionId;
//         string tokenId;
//         uint endTime;
//     }
//     mapping(uint => mapping(string => PartnerShip)) public partners;

//     constructor(address _contractAddress, address _devaddr, uint _collectionId) {
//         devaddr_ = _devaddr;
//         collectionId = _collectionId;
//         contractAddress = _contractAddress;
//     }

//     modifier onlyAdmin() {
//         uint _collectionId = IMarketPlace(_marketCollections()).addressToCollectionId(msg.sender);
//         require(collectionId == _collectionId);
//         _;
//     }

//     // simple re-entrancy check 
//     uint internal _unlocked = 1;
//     modifier lock() {
//         require(_unlocked == 1);
//         _unlocked = 2;
//         _;
//         _unlocked = 1;
//     }

//     function updateDevaddr() external onlyAdmin {
//         devaddr_ = msg.sender;
//     }

//     function isAdmin(address _user) external view returns(bool) {
//         return devaddr_ == _user;
//     }

//     function getProfileId(uint _protocolId) external view returns(uint) {
//         return protocolInfo[_protocolId].profileId;
//     }

//     function getToken(uint _protocolId) external view returns(address) {
//         TicketInfo memory _ticketInfo = INFTicket(_nfticket()).getTicketInfo(protocolInfo[_protocolId].ticketId);
//         return _ticketInfo.token;
//     }

//     function setContractAddress(address _contractAddress) external {
//         require(contractAddress == address(0x0) || helper == msg.sender);
//         contractAddress = _contractAddress;
//         helper = IContract(_contractAddress).paywallARPHelper();
//     }

//     function updateSubscriptionInfo(uint _optionId, uint _freeTrialPeriod) external onlyAdmin {
//         freeTrialPeriod[_optionId] = _freeTrialPeriod;
//         IMarketPlace(IContract(contractAddress).marketPlaceEvents()).emitUpdateSubscriptionInfo(
//             collectionId, 
//             _optionId, 
//             _freeTrialPeriod
//         );
//     }
    
//     function updateDiscountDivisor(uint _optionId, uint _factor, uint _period, uint _cap) external onlyAdmin {
//         discountDivisor[_optionId] = Divisor({
//             factor: _factor,
//             period: _period,
//             cap: _cap == 0 ? 10000 : _cap
//         });
//     }

//     function updatePenaltyDivisor(uint _optionId, uint _factor, uint _period, uint _cap) external onlyAdmin {
//         penaltyDivisor[_optionId] = Divisor({
//             factor: _factor,
//             period: _period,
//             cap: _cap == 0 ? 10000 : _cap
//         });
//     }


//     function updateProfileId() external {
//         address profile = IContract(contractAddress).profile();
//         uint _profileId = IProfile(profile).addressToProfileId(msg.sender);
//         require(IProfile(profile).isUnique(_profileId), "Profile is not unique");
//         protocolInfo[addressToProtocolId[msg.sender]].profileId = _profileId;
//     }

//     function updateParams(
//         uint _bufferTime, 
//         uint _pricePerSecond,
//         bool _profileIdRequired
//     ) external onlyAdmin {
//         bufferTime = _bufferTime;
//         pricePerSecond = _pricePerSecond;
//         profileIdRequired = _profileIdRequired;
//     }

//     function updateAutoCharge(uint _protocolId, bool _autoCharge) external {
//         require(ve(_nfticketHelper2()).ownerOf(protocolInfo[_protocolId].ticketId) == msg.sender);
//         protocolInfo[_protocolId].autoCharge = _autoCharge;
//         IMarketPlace(_marketPlaceEvents()).emitUpdateAutoCharge(collectionId, _protocolId, _autoCharge);
//     }

//     function _nfticket() internal view returns(address) {
//         return IContract(contractAddress).nfticket();
//     }
//     function _nfticketHelper2() internal view returns(address) {
//         return IContract(contractAddress).nfticketHelper2();
//     }

//     function _marketCollections() internal view returns(address) {
//         return IContract(contractAddress).marketCollections();
//     }

//     function _marketOrders() internal view returns(address) {
//         return IContract(contractAddress).paywallMarketOrders();
//     }

//     function _marketTrades() internal view returns(address) {
//         return IContract(contractAddress).paywallMarketTrades();
//     }
    
//     function _marketHelpers() internal view returns(address) {
//         return IContract(contractAddress).paywallMarketHelpers();
//     }

//     function _marketPlaceEvents() internal view returns(address) {
//         return IContract(contractAddress).marketPlaceEvents();
//     }

//     function _helper() internal view returns(address) {
//         return IContract(contractAddress).paywallARPHelper();
//     }

//     function updateProtocol(
//         uint _nfticketId, 
//         uint _pickedOption, // optionId + 1 
//         address[] memory _users
//     ) external {
//         address nfticket = _nfticket();
//         address nfticketHelper2 = _nfticketHelper2();
//         require(ve(nfticketHelper2).ownerOf(_nfticketId) == msg.sender);
//         address _referrer = IMarketPlace(nfticket).referrer(_nfticketId);
//         uint _referrerCollectionId;
//         if (_referrer != address(0x0)) {
//            _referrerCollectionId = IMarketPlace(_marketCollections()).addressToCollectionId(_referrer);
//         }
//         TicketInfo memory _ticketInfo = INFTicket(nfticket).getTicketInfo(_nfticketId);
//         uint _userTokenId = INFTicket(nfticket).userTokenId(_nfticketId);
//         PaywallOption[] memory _options = INFTicket(nfticketHelper2).getTicketPaywallOptions(_nfticketId);
//         for (uint i = 0; i < _options.length; i++) {
//             if (
//                 _pickedOption > 0 && _options[i].id == _pickedOption - 1 || _pickedOption == 0
//             ) {
//                 if (_users.length == _options.length) {
//                     addressToProtocolId[_users[i]] = lastProtocolId;
//                 } else {
//                     addressToProtocolId[msg.sender] = lastProtocolId;
//                 }
//                 uint _startReceivable = block.timestamp + freeTrialPeriod[_options[i].id];
//                 protocolInfo[lastProtocolId].amountReceivable = _ticketInfo.price + _options[i].unitPrice;
//                 protocolInfo[lastProtocolId].periodReceivable = _options[i].value;
//                 protocolInfo[lastProtocolId].startReceivable = _startReceivable;
//                 protocolInfo[lastProtocolId].userTokenId = _userTokenId;
//                 protocolInfo[lastProtocolId].optionId = _options[i].id;
//                 protocolInfo[lastProtocolId].ticketId = _nfticketId;
//                 protocolInfo[lastProtocolId].item = _ticketInfo.item;
//                 protocolInfo[lastProtocolId].freeTrialPeriod = freeTrialPeriod[_options[i].id];
//                 protocolInfo[lastProtocolId].referrerCollectionId = _referrerCollectionId;
//                 IMarketPlace(_marketPlaceEvents()).emitUpdateProtocol(
//                     collectionId, 
//                     _nfticketId,
//                     _referrerCollectionId, 
//                     lastProtocolId++, 
//                     _options[i].id,
//                     _options[i].unitPrice,
//                     _options[i].value,
//                     _startReceivable,
//                     _ticketInfo.item
//                 );
//             }
//         }
//     }

//     function deleteProtocol (uint protocolId) public onlyAdmin {
//         delete protocolInfo[protocolId];
//         IMarketPlace(_marketPlaceEvents()).emitDeleteProtocol(collectionId, protocolId);
//     }
    
//     function owner(uint _protocolId) public view returns(address) {
//         return ve(_nfticketHelper2()).ownerOf(protocolInfo[_protocolId].ticketId);
//     }

//     function autoCharge(uint _protocolId, uint _identityTokenId) external lock {
//         bool isAdmin = collectionId == IMarketPlace(_marketCollections()).addressToCollectionId(msg.sender); 
//         address _owner = owner(_protocolId);
//         require(
//             isAdmin && protocolInfo[_protocolId].autoCharge || _owner == msg.sender,
//             "Either merchant or protocol owner only!"
//         );
//         Collection memory _referrerCollection = 
//         IMarketPlace(_marketCollections()).getCollection(protocolInfo[_protocolId].referrerCollectionId);
//         uint[] memory _option = new uint[](1);
//         _option[0] = protocolInfo[_protocolId].optionId;
//         protocolInfo[_protocolId].paidReceivable += protocolInfo[_protocolId].amountReceivable;
//         IMarketPlace(_marketTrades()).buyWithContract(
//             devaddr_,
//             _owner,
//             protocolInfo[_protocolId].referrerCollectionId > 0 
//             ? _referrerCollection.owner : address(0x0),
//             protocolInfo[_protocolId].item,
//             protocolInfo[_protocolId].userTokenId,
//             _identityTokenId,
//             _option
//         );
//     }

//     function partner(uint _partnerCollectionId, string memory _paywallId, string memory _tokenId, uint _numOfSeconds) external {
//         if(devaddr_ != msg.sender && pricePerSecond > 0) {
//             require(IMarketPlace(IContract(contractAddress).marketHelpers2()).partnerShip(collectionId, _partnerCollectionId));
//             address marketTrades = _marketTrades();
//             address _token = IContract(contractAddress).token();
//             Collection memory _collection = IMarketPlace(_marketCollections()).getCollection(collectionId);
//             uint _askPrice = _numOfSeconds * pricePerSecond;
//             uint _tradingFee = (_askPrice * _collection.tradingFee) / 10000;
//             IERC20(_token).safeTransferFrom(
//                 address(msg.sender), 
//                 marketTrades, 
//                 _askPrice
//             );
//             IMarketPlace(marketTrades).updatePendingRevenue(_token, devaddr_, _askPrice - _tradingFee, false);
//             IMarketPlace(marketTrades).updateTreasuryRevenue(_token, _tradingFee);
//         }
//         uint _endTime = block.timestamp + _numOfSeconds;   
//         partners[_partnerCollectionId][_tokenId] = PartnerShip({
//             partnerCollectionId: _partnerCollectionId,
//             tokenId: _tokenId,
//             endTime: _endTime
//         });
//         IMarketPlace(_marketPlaceEvents()).emitUpdateMiscellaneous(
//             0,
//             collectionId, 
//             _paywallId, 
//             _tokenId, 
//             _partnerCollectionId, 
//             _endTime,
//             address(0x0),
//             new string[](0)
//         );
//     }
    
//     function getState(address _user, string memory _tokenId, uint _price) external view returns(uint) {
//         uint _protocolId = addressToProtocolId[_user];
//         if (owner(_protocolId) == _user && 
//             keccak256(abi.encodePacked(protocolInfo[_protocolId].item)) == keccak256(abi.encodePacked(_tokenId))
//         ) {
//             uint _optionId = protocolInfo[_protocolId].optionId;
//             (uint dueReceivable,,int secondsReceivable) = 
//             IMarketPlace(_helper()).getDueReceivable(address(this), addressToProtocolId[_user]);
//             if (secondsReceivable > 0) {
//                 uint _factor = Math.min(penaltyDivisor[_optionId].cap, (uint(secondsReceivable) / Math.max(1,penaltyDivisor[_optionId].period)) * penaltyDivisor[_optionId].factor);
//                 uint _penalty = _price * _factor / 10000; 
//                 return _price + _penalty;
//             } else {
//                 uint _factor = Math.min(discountDivisor[_optionId].cap, (uint(-secondsReceivable) / Math.max(1,discountDivisor[_optionId].period)) * discountDivisor[_optionId].factor);
//                 uint _discount = _price * _factor / 10000; 
//                 return _price > _discount ? _price - _discount : 0;
//             }
//         }
//         return _price;
//     }

//     function ongoingSubscription(address _user, uint _nfticketId, string memory _tokenId) external view returns(bool) {
//         uint _protocolId = addressToProtocolId[_user];
//         if (owner(_protocolId) == _user && 
//             keccak256(abi.encodePacked(protocolInfo[_protocolId].item)) == keccak256(abi.encodePacked(_tokenId))
//         ) {
//             if (profileIdRequired && protocolInfo[_protocolId].profileId == 0) return false;
//             (uint dueReceivable,,int secondsReceivable) = 
//             IMarketPlace(_helper()).getDueReceivable(address(this), addressToProtocolId[_user]);
//             return dueReceivable == 0 || secondsReceivable < 0 || uint(secondsReceivable) < bufferTime;
//         } else if (_nfticketId > 0) {
//             require(ve(_nfticketHelper2()).ownerOf(_nfticketId) == _user);
    
//             TicketInfo memory _ticketInfo = INFTicket(_nfticket()).getTicketInfo(_nfticketId);
//             require(partners[_ticketInfo.merchant][_tokenId].endTime > block.timestamp);
//             address _partnerPaywall = IMarketPlace(IContract(contractAddress).paywallARPHelper()).collectionIdToPaywallARP(_ticketInfo.merchant);
//             return IMarketPlace(_partnerPaywall).ongoingSubscription(_user, _nfticketId, _tokenId);
//         }
//         return false;
//     }

//     function withdraw(address _token) external onlyAdmin {
//         IERC20(_token).safeTransfer(msg.sender, erc20(_token).balanceOf(address(this)));
//     }
// }

// contract PaywallARPHelper {
//     using EnumerableSet for EnumerableSet.AddressSet;

//     EnumerableSet.AddressSet private gauges;
//     mapping(uint => address) public collectionIdToPaywallARP;
//     address public contractAddress;
//     address private factory;
    
//     function setContractAddress(address _contractAddress) external {
//         require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender, "NT2");
//         contractAddress = _contractAddress;
//     }

//     function setContractAddressAt(address _paywallARP) external {
//         IMarketPlace(_paywallARP).setContractAddress(contractAddress);
//     }

//     function getAllARPs(uint _start) external view returns(address[] memory arps) {
//         arps = new address[](gauges.length() - _start);
//         for (uint i = _start; i < gauges.length(); i++) {
//             arps[i] = gauges.at(i);
//         }    
//     }

//     function updateGauge(address _last_gauge, uint _collectionId) external {
//         require(IContract(contractAddress).paywallARPFactory() == msg.sender);
//         gauges.add(_last_gauge);
//         collectionIdToPaywallARP[_collectionId] = _last_gauge;
//         IMarketPlace(IContract(contractAddress).marketPlaceEvents()).emitCreatePaywallARP(_last_gauge, _collectionId);
//     }

//     function isGauge(address _gauge) external view returns(bool) {
//         return gauges.contains(_gauge);
//     }

//     function deleteARP(address _arp) external {
//         require(msg.sender == IAuth(contractAddress).devaddr_() || IAuth(_arp).devaddr_() == msg.sender);
//         gauges.remove(_arp);
//         IMarketPlace(IContract(contractAddress).marketPlaceEvents()).emitDeletePaywallARP(IMarketPlace(_arp).collectionId());
//     }

//     function getNumPeriods(uint tm1, uint tm2, uint _period) public pure returns(uint) {
//         if (tm1 == 0 || tm2 == 0 || tm2 <= tm1) return 0;
//         return _period > 0 ? (tm2 - tm1) / _period : 1;
//     }
    
//     function getDueReceivable(address _arp, uint _protocolId) public view returns(uint, uint, int) {   
//         (,uint startReceivable,uint amountReceivable,uint periodReceivable,uint paidReceivable,,,,,,) 
//         = IMarketPlace(_arp).protocolInfo(_protocolId);
//         uint numPeriods = getNumPeriods(
//             startReceivable, 
//             block.timestamp, 
//             periodReceivable
//         );
//         uint nextDue = startReceivable + periodReceivable * Math.max(1,numPeriods);
//         uint due = nextDue < block.timestamp ? amountReceivable * numPeriods - paidReceivable : 0;
//         return (
//             due, // due
//             nextDue, // next
//             int(block.timestamp) - int(nextDue) //late or seconds in advance
//         );
//     }

// }

// contract PaywallARPFactory {
//     address public contractAddress;
//     function setContractAddress(address _contractAddress) external {
//         require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender, "NT2");
//         contractAddress = _contractAddress;
//     }

//     function createGauge() external {
//         uint _collectionId = IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(msg.sender);
//         address last_gauge = address(new Paywall(
//             contractAddress,
//             msg.sender,
//             _collectionId
//         ));
//         IMarketPlace(IContract(contractAddress).paywallARPHelper()).updateGauge(last_gauge, _collectionId);
//     }
// }

// // {
// //         "id": "4",
// //         "category": "Subscription",
// //         "element": "Monthly",
// //         "traitType": "Subscription",
// //         "value": "86400*30",
// //         "min": 0,
// //         "max": 100,
// //         "unitPrice": 1,
// //         "currency": '$'
// // },
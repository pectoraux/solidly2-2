// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.16;

// import "./InvoiceNFT.sol";

// // Gauges are used to incentivize pools, they emit reward tokens over 7 days for staked LP tokens
// contract CBC is Auth
//  {
//     using EnumerableSet for EnumerableSet.UintSet;
//     using EnumerableSet for EnumerableSet.AddressSet;
    
//     address public  gaugeContract;
//     address private invoiceFactory;
//     address public  nft_;
//     address public token;

//     uint public period = 86400 * 7 * 30; // 1 month
//     bool public adminBountyRequired;
//     uint public adminBountyId;
//     uint public active_period;
//     uint public limitFactor;
//     uint public gaugeBalanceFactor;
//     mapping(uint => uint) public balanceOf;
//     bool public bountyRequired;
//     bool public profileRequired;
//     uint public bufferTime;

//     struct ProtocolInfo {
//         address owner;
//         address valuepool;
//         uint bountyId;
//         uint profileId;
//         uint amountPayable;
//         uint amountReceivable;
//         uint paidPayable;
//         uint paidReceivable;
//         uint periodPayable;
//         uint periodReceivable;
//         uint startPayable;
//         uint startReceivable;
//     }

//     mapping(uint => uint) public collateralInfo;
//     mapping(uint => uint) public lenderFees;
//     mapping(uint => uint) public protocolShares;
//     mapping(uint => ProtocolInfo) public protocolInfo;
//     uint lastProtocolId = 1;
//     mapping(address => uint) public addressToProtocolId;
//     EnumerableSet.UintSet private AllProtocols;
//     EnumerableSet.AddressSet private AllValuePools;
//     uint public pendingRevenue;

//     event UpdateProtocol(address indexed from, uint time, address owner);
//     event AutoCharge(address indexed protocol, uint price, uint time);
//     event DeleteProtocol(address indexed from, uint time, address protocol);
//     event Withdraw(address indexed from, uint amount);
//     event PayInvoicePayable(address indexed from, uint time, uint paid);

//     constructor(
//         address _token,
//         address _arpHelper,
//         address _invoiceFactory,
//         address _devaddr,
//         address _superLikeGaugeFactory,
//         address _ve
//     ) Auth(helper, _devaddr, _superLikeGaugeFactory)
//     {
//         token = _token; 
//         gaugeContract = _ve;
//         invoiceFactory = _invoiceFactory;
//     }

//     // simple re-entrancy check
//     uint internal _unlocked = 0;
//     modifier lock() {
//         require(_unlocked == 1);
//         _unlocked = 2;
//         _;
//         _unlocked = 1;
//     }

//     function initialize(
//         address _nft,
//         bool _adminBountyRequired
//     ) external {
//         require(msg.sender == invoiceFactory);
//         if(_unlocked == 0){
//             adminBountyRequired = _adminBountyRequired;
//             nft_ = _nft;
//             _unlocked = 1;
//         }
//     }

//     function updateParameters(
//         bool _profileRequired,
//         bool _bountyRequired,
//         uint _bufferTime,
//         uint _period,
//         uint _limitFactor,
//         uint _gaugeBalanceFactor
//     ) external onlyAdmin
//     {
//         profileRequired = _profileRequired;
//         bountyRequired = _bountyRequired;
//         bufferTime = _bufferTime;
//         period = _period;
//         limitFactor = _limitFactor;
//         gaugeBalanceFactor = _gaugeBalanceFactor;
//     }

//     // function updateLateDays(address _protocolOwner) external onlyAdmin {
//     //     (uint dueReceivable, uint nextDue, uint latePeriods) = (0,0,0);//getDueReceivable(_protocolOwner, 0);   
//     //     IProfile(profile).updateLateDays(
//     //         protocolInfo[addressToProtocolId[_protocolOwner]].profileId, 
//     //         latePeriods * protocolInfo[addressToProtocolId[_protocolOwner]].periodReceivable / 86400, //late days
//     //         dueReceivable
//     //     );
//     // }

//      function updateBounty(uint _bountyId) external {
//         (address owner,address _token,address claimableBy,,,,,) = ITrustBounty(IARPHelper(helper).trustBounty()).bountyInfo(_bountyId);
//         require(owner == msg.sender && _token == token && claimableBy == address(this));
//         if (msg.sender == devaddr_) {
//             require(adminBountyId == 0);
//             adminBountyId = _bountyId;
//         } else {
//             require(collateralInfo[addressToProtocolId[msg.sender]] == _bountyId);
//             require(protocolInfo[addressToProtocolId[msg.sender]].bountyId == 0);
//             protocolInfo[addressToProtocolId[msg.sender]].bountyId = _bountyId;
//         }
//     }
        
//     function updateProfile(uint _profileId) external {
//         (address owner,,,,,) = IProfile(IARPHelper(helper).profile()).profileInfo(_profileId);
//         require(owner == msg.sender);
//         protocolInfo[addressToProtocolId[msg.sender]].profileId = _profileId;
//     }

//     function updateProtocolShares(uint _protocolId, uint _num) external {
//         require(msg.sender == helper);
//         protocolShares[_protocolId] -= _num;
//     }

//     function getAllValuePools() external view returns(address[] memory valuepools) {
//         valuepools = new address[](AllValuePools.length());
//         for (uint i = 0; i < AllValuePools.length(); i++){
//             valuepools[i] = AllValuePools.at(i);
//         }
//     }

//     function addValuePool(address _valuepool) external {
//         require(vaVoter(vaVoter).getBalance(_valuepool, address(this)) > 0);
//         AllValuePools.add(_valuepool);
//     }

//     function removeValuePool(address _valuepool) external {
//         require(vaVoter(vaVoter).getBalance(_valuepool, address(this)) == 0);
//         AllValuePools.remove(_valuepool);
//     }
    
//     function autoCharge(
//         address[] memory _protocols, 
//         uint _amount, 
//         uint _numPeriods
//     ) public lock
//      {
//         require(
//             msg.sender == devaddr_ || msg.sender == nft_ ||
//             (_protocols.length == 1 && _protocols[0] == msg.sender),
//             "Either merchant or protocol owner only!"
//         );
//         for (uint i = 0; i < _protocols.length; i++) {
//             if ( _protocols[0] == msg.sender || msg.sender == nft_) {
//                 (uint _price,,) = IARPHelper(helper).getDueReceivable(address(this), _protocols[i], _numPeriods);
//                 if (_amount != 0) _price = Math.min(_amount, _price);
//                 uint payswapFees = _price * IARPHelper(helper).tradingFee() / 10000;
//                 IARPHelper(helper)._safeTransferFrom(token, _protocols[i], address(this), _price);
//                 IARPHelper(helper)._safeTransfer(token, helper, payswapFees);
//                 address _valuepool = protocolInfo[addressToProtocolId[_protocols[i]]].valuepool;
//                 protocolInfo[addressToProtocolId[_protocols[i]]].paidReceivable += _price;
//                 if (IARPHelper(helper).adminNotes(address(this),_protocols[i]) > 0) {
//                     uint _tokenId = IARPHelper(helper).adminNotes(address(this),_protocols[i]);
//                     (uint due,,,) = IARPHelper(helper).notes(address(this),_tokenId);
//                     uint _paid = _price >= due ? due : _price;
//                     IARPHelper(helper).updateDue(_tokenId, _paid);
//                     _price -= _paid;
//                     IARPHelper(helper).updatePendingRevenueFromNote(_tokenId, _paid);
//                 } 
//                 if (_price > payswapFees) {
//                     uint lenderFees = _price * lenderFees[addressToProtocolId[_protocols[i]]] / 10000;
//                     erc20(token).approve(_valuepool, _price - lenderFees - payswapFees);
//                     IValuePool(_valuepool).notifyReimbursement(token, _protocols[i], _price - lenderFees - payswapFees);
//                     pendingRevenue += lenderFees;
//                 }

//                 emit AutoCharge(_protocols[i], _price, block.timestamp);
//             }
//         }
//     }

//     function updateProtocol(
//         address _owner,
//         address _valuepool,
//         uint _bountyId,
//         uint _amountPayable,
//         uint _amountReceivable,
//         uint _periodPayable,
//         uint _periodReceivable,
//         uint _startReceivable,
//         uint _startPayable,
//         uint _collateralAddress,
//         uint _lenderFees
//     ) external onlyAdmin
//      {
//         checkIdentityProof(_owner, false);
//         if(addressToProtocolId[_owner] == 0) {
//             addressToProtocolId[_owner] = lastProtocolId;
//             protocolShares[lastProtocolId] = 10000;
//             AllProtocols.add(lastProtocolId);
//             protocolInfo[addressToProtocolId[_owner]].startReceivable = block.timestamp + _startReceivable;
//             protocolInfo[addressToProtocolId[_owner]].startPayable = block.timestamp + _startPayable;
//             protocolInfo[addressToProtocolId[_owner]].amountReceivable = _amountReceivable;
//             protocolInfo[addressToProtocolId[_owner]].amountPayable = _amountPayable;
//             protocolInfo[addressToProtocolId[_owner]].periodReceivable = _periodReceivable;
//             protocolInfo[addressToProtocolId[_owner]].periodPayable = _periodPayable;
//             protocolInfo[addressToProtocolId[_owner]].valuepool = _valuepool;
//             protocolInfo[addressToProtocolId[_owner]].owner = _owner;
//             lenderFees[addressToProtocolId[_owner]] = _lenderFees;
//             collateralInfo[addressToProtocolId[_owner]] = _bountyId; 
//             lastProtocolId++;
//         }
//         emit UpdateProtocol(msg.sender, block.timestamp, _owner);
//     }

//     function deleteProtocol (address _protocol) public onlyAdmin {
//         (uint due,,) = IARPHelper(helper).getDuePayable(address(this), _protocol, 0);
//         require(due == 0, "Pay protocol invoice first");
//         delete protocolInfo[addressToProtocolId[_protocol]];
//         AllProtocols.remove(addressToProtocolId[_protocol]);

//         emit DeleteProtocol(msg.sender, block.timestamp, _protocol);
//     }

//     function batchPayInvoices(uint _startIdx, uint _endIdx) external {
//         for (uint i = _startIdx; i < _endIdx; i++) {
//             if (protocolInfo[AllProtocols.at(i)].startPayable != 0){
//                 payInvoicePayable(
//                     protocolInfo[AllProtocols.at(i)].owner,
//                     protocolShares[AllProtocols.at(i)]
//                 );
//             }
//         }
//     }
    
//     function payInvoicePayable(
//         address _protocol, 
//         uint _share
//     ) public lock
//     {
//         require(
//             _protocol == msg.sender || devaddr_ == msg.sender || nft_ == msg.sender,
//             "Only invoice owner or admin!"
//         );
//         (uint duePayable,,) = IARPHelper(helper).getDuePayable(address(this), _protocol, 0);
//         if (nft_ == msg.sender) {
//             duePayable = duePayable * _share / 10000;
//         } else {
//             duePayable = duePayable * protocolShares[addressToProtocolId[_protocol]] / 10000;
//         }
//         protocolInfo[addressToProtocolId[_protocol]].paidPayable += duePayable;
//         require(duePayable > 0, "Nothing to pay yet");
//         uint payswapFees = duePayable * IARPHelper(helper).tradingFee() / 10000;
//         duePayable -= payswapFees;
//         IARPHelper(helper)._safeTransfer(token, helper, payswapFees);
//         IValuePool(protocolInfo[addressToProtocolId[_protocol]].valuepool).notifyLoan(token, _protocol, duePayable);

//         emit PayInvoicePayable(_protocol, block.timestamp, duePayable);
//     }

//     function withdraw(address _token, uint amount) external onlyChangeMinCosigners(msg.sender, amount) {
//         if (_token == token) {
//             require(pendingRevenue >= amount);
//             pendingRevenue -= amount;
//         }
//         IARPHelper(helper)._safeTransfer(_token, msg.sender, amount);
        
//         emit Withdraw(msg.sender, amount);
//     }

//     function noteWithdraw(address _to, uint amount) external {
//         require(msg.sender == helper);
//         IARPHelper(helper)._safeTransfer(token, _to, amount);
//     }

//     function updateBalances() public {
//         if (block.timestamp >= active_period) {
//             for (uint i = 0; i < AllProtocols.length(); i++) {
//                 balanceOf[AllProtocols.at(i)] = 0;
//             }
//             active_period = block.timestamp / period * period;
//         }
//     }

//     function updateBalanceOf(address _to, uint amount) external {
//         require(msg.sender === helper);
//         balanceOf[addressToProtocolId[_to]] += amount;
//     }

//     function _isContract(address account) internal view returns (bool) {
//         // This method relies on extcodesize, which returns 0 for contracts in
//         // construction, since the code is only stored at the end of the
//         // constructor execution.
//         uint _size;
//         assembly {
//             _size := extcodesize(account)
//         }
//         return _size > 0;
//     }
// }

// contract ARPNote is ERC721Pausable {
//     using EnumerableSet for EnumerableSet.AddressSet;

//     EnumerableSet.AddressSet private gauges;
//     address public devaddr_;
//     address public trustBounty;
//     address public profile;
//     struct Note {
//         uint due;
//         uint timer;
//         uint tokenId;
//         address protocol;
//     }
//     mapping(address => mapping(uint => Note)) public notes;
//     mapping(address => mapping(address => uint)) public adminNotes;
//     mapping(address => mapping(uint => uint)) public pendingRevenueFromNote;
//     mapping(address => mapping(uint => uint)) private protocolNotes;
//     uint public tokenId = 1;
//     uint public tradingFee;
//     address private factory = 0x0bDabC785a5e1C71078d6242FB52e70181C1F316;
//     mapping(address => address) public fts_;

//     constructor() ERC721("MicroLenderNote", "MLender")  {
//         devaddr_ = msg.sender;
//     }

//     // simple re-entrancy check
//     uint internal _unlocked = 1;
//     modifier lock() {
//         require(_unlocked == 1);
//         _unlocked = 2;
//         _;
//         _unlocked = 1;
//     }

//     function createFT(address _arp, string memory _name, string memory _symbol) external {
//         require(IARP(_arp).devaddr_() == msg.sender && fts_[_arp] == address(0x0));
//         fts_[_arp] = address(new ERC20(_name, _symbol));
//     }

//     function updateDev(address _devaddr) external {
//         require(msg.sender == devaddr_);
//         devaddr_ = _devaddr;
//     }

//     function updateDue(uint _tokenId, uint _paid) external {
//         notes[msg.sender][_tokenId].due -= _paid;
//     }

//     function getAllARPs() external view returns(address[] memory arps) {
//         arps = new address[](gauges.length());
//         for (uint i = 0; i < gauges.length(); i++) {
//             arps[i] = gauges.at(i);
//         }    
//     }

//     function updateGauge(address _last_gauge) external {
//         require(msg.sender == factory);
//         gauges.add(_last_gauge);
//     }

//     function deleteARP(address _arp) external {
//         require(msg.sender == devaddr_ || IARP(_arp).devaddr_() == msg.sender);
//         gauges.remove(_arp);
//     }

//     function updatePendingRevenueFromNote(uint _tokenId, uint _paid) external {
//         pendingRevenueFromNote[msg.sender][_tokenId] += _paid;
//     }

//     function getNumPeriods(uint tm1, uint tm2, uint _period) public pure returns(uint) {
//         if (tm1 == 0 || tm2 == 0 || tm2 <= tm1) return 0;
//         return _period > 0 ? (tm2 - tm1) / _period : 1;
//     }

//     function getDuePayable(address _arp, address _protocol, uint _numPeriods) public view returns(uint, uint, uint) {
//         uint _protocolId = IARP(_arp).addressToProtocolId(_protocol);
//         (,,,uint _tokenId,uint amountPayable,,uint paidPayable,,uint periodPayable,,uint startPayable,) = 
//         IARP(_arp).protocolInfo(_protocolId);
//         uint numPeriods = getNumPeriods(
//             startPayable, 
//             block.timestamp, 
//             periodPayable
//         );
//         numPeriods += _numPeriods;
//         uint latePeriods = paidPayable / amountPayable;
//         if (amountPayable * numPeriods > paidPayable) {
//             return (
//                 amountPayable * numPeriods - paidPayable,
//                 periodPayable * numPeriods + startPayable,
//                 latePeriods
//             );
//         }
//         return (0, numPeriods * periodPayable + startPayable, latePeriods);
//     }
    
//     function getDueReceivable(address _arp, address _protocol, uint _numPeriods) public view returns(uint, uint, uint) {   
//         uint _protocolId = IARP(_arp).addressToProtocolId(_protocol);
//         (,,,,,uint amountReceivable,,uint paidReceivable,,uint periodReceivable,,uint startReceivable) = 
//         IARP(_arp).protocolInfo(_protocolId);
//         uint numPeriods = getNumPeriods(
//             startReceivable, 
//             block.timestamp, 
//             periodReceivable
//         );
//         numPeriods += _numPeriods;
//         uint latePeriods = paidReceivable / amountReceivable;
//         if (amountReceivable * numPeriods > paidReceivable) {
//             return (
//                 amountReceivable * numPeriods - paidReceivable,
//                 periodReceivable * numPeriods + startReceivable,
//                 latePeriods
//             );
//         }
//         return (0, numPeriods * periodReceivable + startReceivable, latePeriods);
//     }
    
//     function transferDueToNoteReceivable(
//         address _arp,
//         address _to, 
//         address _protocol, 
//         uint _numPeriods
//     ) external lock
//     {
//         (uint dueReceivable, uint nextDue,) = getDueReceivable(_arp, _protocol, _numPeriods);
//         require(dueReceivable > 0, "You can't transfer a nul balance");
//         IARP(_arp).changeDouble(msg.sender, dueReceivable);
//         adminNotes[_arp][_protocol] = tokenId;
//         notes[_arp][tokenId] = Note({
//             due: dueReceivable,
//             timer: nextDue,
//             tokenId: tokenId,
//             protocol: _protocol
//         });
//         _safeMint(_to, tokenId++, msg.data);
//     }

//     function sendInvoice(
//         address _arp, 
//         address _protocol, 
//         address[] memory _recipients, 
//         uint[] memory _shares
//     ) external {
//         uint _protocolId = IARP(_arp).addressToProtocolId(msg.sender);
//         (,,,,,,,,,,uint startPayable,) = IARP(_arp).protocolInfo(_protocolId);
//         require(msg.sender == IARP(_arp).devaddr_() || msg.sender == _protocol, "Only admin or protocol!");
//         require(startPayable > 0, "Cannot send invoice from pending protocol");
//         IARP(_arp).updateProtocolShares(_protocolId, _sumArr(_shares));
//         IInvoiceNFT(IARP(_arp).nft_()).mintToBatch(
//             _protocol,
//             _recipients,
//             _shares
//         );
//         // emit SendInvoice(msg.sender, _protocol, block.timestamp);
//     }

//     function claimPendingRevenueFromNote(address _arp, bool _adminNote, uint _tokenId) external 
//     lock
//      {
//         require(ownerOf(_tokenId) == msg.sender, "Only owner!");
//         uint256 revenueToClaim;
//         if (_adminNote) {
//             require(adminNotes[_arp][notes[_arp][_tokenId].protocol] == _tokenId, "Invalid admin note");
//             require(notes[_arp][_tokenId].due >= pendingRevenueFromNote[_arp][_tokenId], "Error with pending note revenue");
//             revenueToClaim = pendingRevenueFromNote[_arp][_tokenId] ;
//         } else {
//             require(notes[_arp][_tokenId].timer <= block.timestamp, "Not yet due");
//             uint _supply = erc20(IARP(_arp).token()).balanceOf(_arp);
//             revenueToClaim = notes[_arp][_tokenId].due > _supply ? _supply : notes[_arp][_tokenId].due;
//         }
//         require(revenueToClaim != 0, "Claim: Nothing to claim");
//         notes[_arp][_tokenId].due -= revenueToClaim;
//         if (notes[_arp][_tokenId].due == 0) {
//             _burn(_tokenId); 
//             delete notes[_arp][_tokenId];
//             if (_adminNote) delete adminNotes[_arp][notes[_arp][_tokenId].protocol];
//         }
//         uint payswapFees = revenueToClaim * tradingFee / 10000;
//         IARP(_arp).noteWithdraw(address(msg.sender), revenueToClaim - payswapFees);
//         IARP(_arp).noteWithdraw(address(this), payswapFees);

//         // emit RevenueClaim(msg.sender, revenueToClaim);
//     }

//     function tokenURI(uint _tokenId) public override view returns (string memory output) {
//         output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
//         output = string(abi.encodePacked(output, "Contract address: ", address(this), '</text><text x="10" y="40" class="base">'));
//         output = string(abi.encodePacked(output, "Amount due: ", 
//         // toString(notes[_tokenId].due), 
//         '</text><text x="10" y="60" class="base">'));
//         output = string(abi.encodePacked(output, "Time due ", 
//         // toString(notes[_tokenId].timer), 
//         '</text><text x="10" y="80" class="base">'));
//         output = string(abi.encodePacked(output, "Owner ", 
//         // notes[_tokenId].protocol, 
//         '</text></svg>'));

//         string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "SponsorCard note #', toString(_tokenId), '", "description": "This card gives you access to amount due by the owner at date mentioned below.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
//         output = string(abi.encodePacked('data:application/json;base64,', json));
//     }

//     function updateTradingFee(uint _tradingFee) external {
//         require(msg.sender == devaddr_);
//         tradingFee = _tradingFee;
//     }
    
//     function _safeTransfer(address _token, address to, uint256 value) internal {
//         (,uint _bountyId, uint profileId,,,,,,,,,) = IARP(msg.sender).protocolInfo(IARP(msg.sender).addressToProtocolId(to));
//         if (IMicroLender(msg.sender).profileRequired() && to == IARP(msg.sender).devaddr_()) require(profileId != 0);
//         if (to != address(this) && ((to == IARP(msg.sender).devaddr_() && IARP(msg.sender).adminBountyRequired()) || 
//         (to != IARP(msg.sender).devaddr_() && IARP(msg.sender).bountyRequired()))) {
//             IARP(msg.sender).updateBalances();
//             uint bountyId = to == IARP(msg.sender).devaddr_() ? IARP(msg.sender).adminBountyId() : _bountyId;
//             uint _limit = ITrustBounty(trustBounty).getBalance(bountyId);
//             (,,,,,uint endTime,,) = ITrustBounty(trustBounty).bountyInfo(bountyId);
//             require(endTime > block.timestamp + IARP(msg.sender).bufferTime());
//             uint amount = value * IARP(msg.sender).limitFactor() / 10000;
//             value = Math.min(amount, _limit - IARP(msg.sender).balanceOf(IARP(msg.sender).addressToProtocolId(to)));
//             IARP(msg.sender).updateBalanceOf(to, value);
//         }
//         require(_token.code.length > 0);
//         (bool success, bytes memory data) =
//         _token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
//         require(success && (data.length == 0 || abi.decode(data, (bool))));
//     }

//     function _safeTransferFrom(address _token, address from, address to, uint256 value) internal {
//         require(_token.code.length > 0);
//         (bool success, bytes memory data) =
//         _token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
//         require(success && (data.length == 0 || abi.decode(data, (bool))));
//     }

//     function toString(uint value) internal pure returns (string memory) {
//         // Inspired by OraclizeAPI's implementation - MIT license
//         // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

//         if (value == 0) {
//             return "0";
//         }
//         uint temp = value;
//         uint digits;
//         while (temp != 0) {
//             digits++;
//             temp /= 10;
//         }
//         bytes memory buffer = new bytes(digits);
//         while (value != 0) {
//             digits -= 1;
//             buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
//             value /= 10;
//         }
//         return string(buffer);
//     }

//     function _sumArr(uint[] memory _arr) internal pure returns(uint total) {
//         for (uint i = 0; i < _arr.length; i++) {
//             total += _arr[i];
//         }
//     }

// }

// contract CBCFactory {
//     address private superLikeGaugeFactory;
//     address private helper;
//     address private invoiceFactory;

//     constructor(
//         address _arpHelper, 
//         address _invoiceFactory,
//         address _superLikeGaugeFactory
//         ) {
//         helper = _arpHelper;
//         invoiceFactory = _invoiceFactory;
//         superLikeGaugeFactory = _superLikeGaugeFactory;
//     }

//     function createGauge(
//         address _token,
//         address _devaddr,
//         address _ve
//     ) external {
//         address last_gauge = address(new CBC(
//             _token,
//             helper,
//             invoiceFactory,
//             _devaddr,
//             superLikeGaugeFactory,
//             _ve
//         ));
//         IARPHelper(helper).updateGauge(last_gauge);
//     }
// }
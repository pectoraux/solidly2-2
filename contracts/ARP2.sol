// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;

// import "./InvoiceNFT.sol";

// // Gauges are used to incentivize pools, they emit reward tokens over 7 days for staked LP tokens
// contract ARP is Auth
//  {
//     using EnumerableSet for EnumerableSet.UintSet;
    
//     address public  gaugeContract;
//     address private invoiceFactory;
//     address public  nft_;
//     address public token;
    // enum ARPType {
    //     Manual, // owner manually puts in amount details
    //     SemiAutomatic, // owner manually puts in percentage of total balance user can withdraw
    //     Automatic // user uses va to determine percentage of total balance withdrawable
    // }

//     uint public period = 86400 * 7 * 30; // 1 month
//     bool public automatic;
//     bool public immutableContract;
//     bool public adminBountyRequired;
//     uint public adminBountyId;
//     uint public active_period;
//     uint public limitFactor;
//     uint public gaugeBalanceFactor;
//     mapping(uint => uint) public balanceOf;
//     bool public bountyRequired;
//     bool public profileRequired;
//     bool public initialized;
//     uint public bufferTime;
//     mapping(uint => bool) public isAutoChargeable;

//     struct ProtocolInfo {
//         address owner;
//         uint bountyId;
//         uint profileId;
//         uint tokenId;
//         uint amountPayable;
//         uint amountReceivable;
//         uint paidPayable;
//         uint paidReceivable;
//         uint periodPayable;
//         uint periodReceivable;
//         uint startPayable;
//         uint startReceivable;
//     }
//     mapping(uint => uint) public protocolShares;
//     mapping(uint => ProtocolInfo) public protocolInfo;
//     uint lastProtocolId = 1;
//     mapping(address => uint) public addressToProtocolId;
//     EnumerableSet.UintSet private AllProtocols;
//     uint public pendingRevenue;
//     uint public maxNotesPerProtocol = 1;
//     address private taxContract;
//     bool private notifyCredits;
//     bool private notifyDebits;
//     mapping(uint => uint) public autoPaidPayable;

//     event UpdateProtocol(address indexed from, uint time, address owner, string description);
//     event AutoCharge(address indexed protocol, uint price, uint time);
//     event DeleteProtocol(address indexed from, uint time, address protocol);
//     event Withdraw(address indexed from, uint amount);
//     event PayInvoicePayable(address indexed from, uint time, uint paid);

//     constructor(
//         address _token,
//         address _devaddr,
//         address _helper,
//         address _invoiceFactory,
//         address _superLikeGaugeFactory
//     ) Auth(_helper, _devaddr, _superLikeGaugeFactory)
//     {
//         token = _token; 
//         invoiceFactory = _invoiceFactory;
//     }

//     // simple re-entrancy check
//     uint internal _unlocked = 1;
//     modifier lock() {
//         require(_unlocked == 1);
//         _unlocked = 2;
//         _;
//         _unlocked = 1;
//     }

//     function initialize(
//         address _nft,
//         address _ve,
//         bool _automatic,
//         bool _immutableContract,
//         bool _adminBountyRequired
//     ) external {
//         require(msg.sender == invoiceFactory);
//         if(!initialized){
//             adminBountyRequired = _adminBountyRequired;
//             automatic = _automatic;
//             immutableContract = _automatic ? false : _immutableContract;
//             nft_ = _nft;
//             gaugeContract = _ve;
//             initialized = true;
//         }
//     }

//     function getPaidPayable(uint _protocolId) external view returns(uint) {
//         if (automatic) {
//             return autoPaidPayable[protocolInfo[_protocolId].tokenId];
//         }
//         return protocolInfo[_protocolId].paidPayable;
//     }

//     function getAllAccounts() external view returns(uint[] memory accounts) {
//         accounts = new uint[](AllProtocols.length());
//         for (uint i = 0; i < AllProtocols.length(); i++) {
//             accounts[i] = AllProtocols.at(i);
//         }    
//     }

//     function updateParameters(
//         address _taxContract,
//         uint _maxNotesPerProtocol,
//         bool _bountyRequired,
//         bool _profileRequired,
//         bool _notifyCredits,
//         bool _notifyDebits,
//         uint _bufferTime,
//         uint _period,
//         uint _limitFactor,
//         uint _gaugeBalanceFactor
//     ) external onlyAdmin
//     {
//         taxContract = _taxContract;
//         notifyCredits = _notifyCredits;
//         notifyDebits = _notifyDebits;
//         maxNotesPerProtocol = _maxNotesPerProtocol;
//         bountyRequired = _bountyRequired;
//         profileRequired = _profileRequired;
//         bufferTime = _bufferTime;
//         period = _period;
//         limitFactor = _limitFactor;
//         gaugeBalanceFactor = _gaugeBalanceFactor;
//     }

//     function updateBounty(uint _bountyId) external {
//         (address owner,address _token,address claimableBy,,,,,) = ITrustBounty(IARPHelper(helper).trustBounty()).bountyInfo(_bountyId);
//         require(owner == msg.sender && _token == token && claimableBy == devaddr_);
//         if (isAdmin(msg.sender)) {
//             require(adminBountyId == 0);
//             adminBountyId = _bountyId;
//         } else {
//             require(protocolInfo[addressToProtocolId[msg.sender]].bountyId == 0);
//             protocolInfo[addressToProtocolId[msg.sender]].bountyId = _bountyId;
//         }
//     }
        
//     function updateProfile(uint _profileId) external {
//         (address owner,,,,,) = IProfile(IARPHelper(helper).profile()).profileInfo(_profileId);
//         require(owner == msg.sender);
//         protocolInfo[addressToProtocolId[msg.sender]].profileId = _profileId;
//     }

//     function updateTokenId(uint _tokenId) external {
//         require(ve(IGaugeBalance(gaugeContract)._ve()).ownerOf(_tokenId) == msg.sender);
//         protocolInfo[addressToProtocolId[msg.sender]].tokenId = _tokenId;
//         protocolInfo[addressToProtocolId[msg.sender]].paidPayable += autoPaidPayable[_tokenId];
//     }

//     function updateOwner(address _prevOwner, uint _tokenId) external {
//         require(ve(IGaugeBalance(gaugeContract)._ve()).ownerOf(_tokenId) == msg.sender);
//         require(protocolInfo[addressToProtocolId[_prevOwner]].tokenId == _tokenId);
//         addressToProtocolId[msg.sender] = addressToProtocolId[_prevOwner];
//         delete addressToProtocolId[_prevOwner];
//     }

//     function updatePaidPayable(address _owner, uint _num) external {
//         if(msg.sender == helper) {
//             protocolInfo[addressToProtocolId[_owner]].paidPayable += _num;
//             IBILL(taxContract).notifyCredit(_owner, _num);
//         } else if (isAdmin[msg.sender] && !immutableContract){
//             protocolInfo[addressToProtocolId[_owner]].paidPayable += protocolInfo[addressToProtocolId[_owner]].amountPayable * _num;
//         }
//     }

//     function updateProtocolShares(uint _protocolId, uint _num) external {
//         require(msg.sender == helper);
//         protocolShares[_protocolId] -= _num;
//     }

//     function updateAutoCharge() external {
//         isAutoChargeable[addressToProtocolId[msg.sender]] = !isAutoChargeable[addressToProtocolId[msg.sender]];
//     }

//     function autoCharge(
//         address[] memory _protocols, 
//         uint _amount, 
//         uint _numPeriods
//     ) public lock
//      {
//         require(
//             isAdmin[msg.sender] || 
//             msg.sender == nft_ ||
//             (_protocols.length == 1 && _protocols[0] == msg.sender),
//             "Either merchant or protocol owner only!"
//         );
        
//         for (uint i = 0; i < _protocols.length; i++) {
//             if (isAdmin[msg.sender]) {
//                 require(isAutoChargeable[addressToProtocolId[_protocols[i]]]);
//             }
//             (uint _price,,) = IARPHelper(helper).getDueReceivable(address(this), _protocols[i], _numPeriods);
//             if (_amount != 0) _price = Math.min(_amount, _price);
//             uint payswapFees = _price * IARPHelper(helper).tradingFee() / 10000;
//             IARPHelper(helper)._safeTransferFrom(token, _protocols[i], address(this), _price);
//             IARPHelper(helper)._safeTransfer(token, helper, payswapFees);
//             protocolInfo[addressToProtocolId[_protocols[i]]].paidReceivable += _price;
//             if(notifyDebits) IBILL(taxContract).notifyDebit(_protocols[i], _price);
//             if (IARPHelper(helper).adminNotes(address(this),_protocols[i]) > 0) {
//                 uint _tokenId = IARPHelper(helper).adminNotes(address(this),_protocols[i]);
//                 (uint due,,,) = IARPHelper(helper).notes(address(this),_tokenId);
//                 uint _paid = _price >= due ? due : _price;
//                 IARPHelper(helper).updateDue(_tokenId, _paid);
//                 _price -= _paid;
//                 IARPHelper(helper).updatePendingRevenueFromNote(_tokenId, _paid);
//             }
//             pendingRevenue += _price - payswapFees;
//             emit AutoCharge(_protocols[i], _price, block.timestamp);
//         }
//     }

//     function updateProtocol(
//         address _owner,
//         uint _amountPayable,
//         uint _amountReceivable,
//         uint _periodPayable,
//         uint _periodReceivable,
//         uint _startReceivable,
//         uint _startPayable,
//         string memory _description
//     ) external onlyChangeMinCosigners(msg.sender, _amountPayable)
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
//             protocolInfo[addressToProtocolId[_owner]].owner = _owner;
//             lastProtocolId++;
//         }
//         emit UpdateProtocol(msg.sender, block.timestamp, _owner, _description);
//     }

//     function deleteProtocol (address _protocol) public onlyAdmin {
//         // (uint due,,) = IARPHelper(helper).getDuePayable(address(this), _protocol, 1);
//         // require(due == 0, "Pay protocol invoice first");
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
//             _protocol == msg.sender || isAdmin[msg.sender] || nft_ == msg.sender,
//             "Only invoice owner or admin!"
//         );
//         (uint duePayable,,) = IARPHelper(helper).getDuePayable(address(this), _protocol, 1);
//         if (nft_ == msg.sender) {
//             duePayable = duePayable * _share / 10000;
//         } else {
//             duePayable = duePayable * protocolShares[addressToProtocolId[_protocol]] / 10000;
//         }
//         uint _balanceOf = erc20(token).balanceOf(address(this));
//         uint _toPay = _balanceOf < duePayable ? _balanceOf : duePayable;
//         if (automatic) {
//             autoPaidPayable[protocolInfo[addressToProtocolId[_protocol]].tokenId] += _toPay;
//         }
//         protocolInfo[addressToProtocolId[_protocol]].paidPayable += _toPay;
//         if(notifyCredits) IBILL(taxContract).notifyCredit(_protocol, _toPay);
//         require(_toPay > 0, "Nothing to pay yet");
//         uint payswapFees = _toPay * IARPHelper(helper).tradingFee() / 10000;
//         _toPay -= payswapFees;
//         IARPHelper(helper)._safeTransfer(token, helper, payswapFees);
//         IARPHelper(helper)._safeTransfer(token, _protocol, _toPay);

//         emit PayInvoicePayable(_protocol, block.timestamp, _toPay);
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

//     function updateAutoPaidPayable(uint _tokenId, uint amount) external {
//         require(msg.sender == helper);
//         autoPaidPayable[_tokenId] += amount;
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
//         require(msg.sender == helper);
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
//     mapping(address => mapping(bytes32 => uint)) public bonuses;
//     mapping(address => mapping(address => uint)) public adminNotes;
//     mapping(address => mapping(uint => uint)) public pendingRevenueFromNote;
//     mapping(address => mapping(uint => uint)) private protocolNotes;
//     uint public tokenId = 1;
//     uint public tradingFee;
//     address private factory;
//     address private badgeNFT;
//     mapping(address => address) fts_;
//     mapping(uint => uint) private badgePaidPayable;

//     constructor(address _badgeNFT) ERC721("ARPNote", "nARP")  {
//         devaddr_ = msg.sender;
//         badgeNFT = _badgeNFT;
//     }

//     // simple re-entrancy check
//     uint internal _unlocked = 1;
//     modifier lock() {
//         require(_unlocked == 1);
//         _unlocked = 2;
//         _;
//         _unlocked = 1;
//     }

//     function setFactory(address _factory) external {
//          require(msg.sender == devaddr_);
//          factory = _factory;
//     }

//     function createFT(address _arp, string memory _name, string memory _symbol) external {
//         require(IARP(_arp).devaddr_() == msg.sender && fts_[_arp] == address(0x0));
//         fts_[_arp] = address(new ERC20(_name, _symbol));
//     }

//     function updateDev(address _devaddr) external {
//         require(msg.sender == devaddr_);
//         devaddr_ = _devaddr;
//     }

//     function updateBonuses(address _arp, bytes32 _bonusName, uint _bonus) external {
//         require(IAuth(_arp).isAdmin(msg.sender));
//         bonuses[_arp][_bonusName] = _bonus;
//     }

//     function withdrawBonus(address _arp, uint _badgeId) external lock {
//         require(IERC1155(badgeNft).balanceOf(msg.sender, _badgeId) > 0);
//         (,address _auditor) = IBadgeNFT(badgeNFT).getTicketAuditor(_badgeId);
//         IARP(_arp).checkIdentityProof(_auditor, false);
//         (
//             bytes32 _bonusName, 
//             bytes32 _resource, 
//             int _numberOfTickets
//         ) = IBadgeNFT(badgeNFT).getTicketRating(_tokenId);
//         if (_numberOfTickets > 0) {
//             IARP(_arp).noteWithdraw(msg.sender, uint(_numberOfTickets) - badgePaidPayable[_badgeId]);
//             badgePaidPayable[_badgeId] += uint(_numberOfTickets);
//         } else {
//             badgePaidPayable[_badgeId] -= uint(_numberOfTickets);
//         }
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

//     function isGauge(address _arp) external returns(bool) {
//         return gauges.contains(_arp);
//     }

//     function updateGauge(address _last_gauge) external {
//         require(msg.sender == factory);
//         gauges.add(_last_gauge);
//     }

//     function deleteARP(address _arp) external {
//         require(msg.sender == devaddr_ || IARP(_arp).isAdmin(msg.sender));
//         gauges.remove(_arp);
//     }

//     function updatePendingRevenueFromNote(uint _tokenId, uint _paid) external {
//         pendingRevenueFromNote[msg.sender][_tokenId] += _paid;
//     }

//     function getNumPeriods(uint tm1, uint tm2, uint _period) public pure returns(uint) {
//         if (tm1 == 0 || tm2 == 0 || tm2 <= tm1) return 0;
//         return _period > 0 ? (tm2 - tm1) / _period : 1;
//     }

//     function getAmountPayable(address _arp, uint _tokenId, uint _amountPayable) public view returns(uint) {
//         if (IARP(_arp).automatic()) {
//             return IGaugeBalance(IARP(_arp).gaugeContract()).balanceOf(_tokenId) * IARP(_arp).gaugeBalanceFactor();
//         }
//         return _amountPayable;
//     }

//     function getDuePayable(address _arp, address _protocol, uint _numPeriods) public view returns(uint, uint, uint) {
//         uint _protocolId = IARP(_arp).addressToProtocolId(_protocol);
//         (,,,uint _tokenId,uint _amountPayable,,uint paidPayable,,uint periodPayable,,uint startPayable,) = 
//         IARP(_arp).protocolInfo(_protocolId);
//         uint numPeriods = getNumPeriods(
//             startPayable, 
//             block.timestamp, 
//             periodPayable
//         );
//         numPeriods += _numPeriods;
//         uint amountPayable = getAmountPayable(_arp, _tokenId, _amountPayable);
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

//     function transferDueToNote(address _arp, address _to, uint _numPeriods) external 
//     lock
//     {
//         uint _protocolId = IARP(_arp).addressToProtocolId(msg.sender);
//         (uint duePayable, uint nextDue,) = getDuePayable(_arp, msg.sender, _numPeriods);
//         duePayable = duePayable * IARP(_arp).protocolShares(_protocolId) / 10000;
//         require(protocolNotes[_arp][_protocolId] < IARP(_arp).maxNotesPerProtocol(), "Maximum notes reached");
//         require(duePayable > 0, "You can't transfer a nul balance");
//         notes[_arp][tokenId] = Note({
//             due: duePayable,
//             timer: nextDue,
//             tokenId: tokenId,
//             protocol: msg.sender
//         });
//         protocolNotes[_arp][_protocolId] += 1;
//         if (IARP(_arp).automatic()) {
//             (,,,uint _tokenId,,,,,,,,) = IARP(_arp).protocolInfo(_protocolId);
//             IARP(_arp).updateAutoPaidPayable(_tokenId, duePayable);
//         }
//         IARP(_arp).updatePaidPayable(msg.sender, duePayable);
//         _safeMint(_to, tokenId++, msg.data);
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
//         require(IARP(_arp).isAdmin(msg.sender) || msg.sender == _protocol, "Only admin or protocol!");
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
//         (,uint _bountyId,uint profileId,,,,,,,,,) = IARP(msg.sender).protocolInfo(IARP(msg.sender).addressToProtocolId(to));
//         if (IMicroLender(msg.sender).profileRequired() && IARP(msg.sender).isAdmin(to)) require(profileId != 0);
//         if (to != address(this) && ((IARP(msg.sender).isAdmin(to) && IARP(msg.sender).adminBountyRequired()) || 
//         (!IARP(msg.sender).isAdmin(to) && IARP(msg.sender).bountyRequired()))) {
//             IARP(msg.sender).updateBalances();
//             uint bountyId = IARP(msg.sender).isAdmin(to) ? IARP(msg.sender).adminBountyId() : _bountyId;
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

// contract ARPFactory {
//     address private superLikeGaugeFactory;
//     address private helper;
//     address private invoiceFactory;

//     constructor(
//         address _helper, 
//         address _invoiceFactory, 
//         address _superLikeGaugeFactory
//     ) {
//         helper = _helper;
//         invoiceFactory = _invoiceFactory;
//         superLikeGaugeFactory = _superLikeGaugeFactory;
//     }

//     function createGauge(
//         address _token,
//         address _devaddr
//     ) external {
//         address last_gauge = address(new ARP(
//             _token,
//             _devaddr,
//             helper,
//             invoiceFactory,
//             superLikeGaugeFactory
//         ));
//         IARPHelper(helper).updateGauge(last_gauge);
//     }
// }
// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;

// import "./InvoiceNFT.sol";

// // Gauges are used to incentivize pools, they emit reward tokens over 7 days for staked LP tokens
// contract ARP is Auth, ReentrancyGuard, ERC721Pausable {
//     using EnumerableSet for EnumerableSet.UintSet;
//     using EnumerableSet for EnumerableSet.AddressSet;
    
//     address public immutable factory;
//     address public immutable trustBounty;
//     bool public immutable adminBountyRequired;
//     bool public immutable automatic;
//     address public immutable gaugeContract;
//     address public immutable profile;

//     uint public period = 86400 * 7 * 30; // 1 month
    
//     uint public adminBountyId;
//     uint public active_period;
//     uint public limitFactor;
//     uint public gaugeBalanceFactor;
//     mapping(uint => uint) public balanceOf;
//     address public token;
//     uint public maxActiveProtocols;
//     uint public tokenId = 1;
//     bool public bountyRequired;
//     uint public bufferTime;

//     struct ProtocolInfo {
//         address owner;
//         uint bountyId;
//         uint profileId;
//         uint tokenId;
//         uint amountPayable;
//         uint amountReceivable;
//         // uint paidPayable;
//         // uint paidReceivable;
//         uint periodPayable;
//         uint periodReceivable;
//         uint startPayable;
//         uint startReceivable;
//         // address fromContract;
//     }
//     mapping(uint => uint) public protocolShares;
//     mapping(address => bool) public isBlackListed;
//     mapping(uint => ProtocolInfo) public protocolInfo;
//     uint lastProtocolId = 1;
//     mapping(address => uint) public addressToProtocolId;
//     EnumerableSet.UintSet private AllProtocols;
//     mapping(uint => uint) public protocolNotes;
//     struct Note {
//         uint due;
//         uint timer;
//         uint tokenId;
//         address protocol;
//     }
//     mapping(uint => Note) public notes;
//     mapping(address => uint) public adminNotes;
//     mapping(uint => uint) public pendingRevenueFromNote;
//     uint public pendingRevenue;
//     address[] public AllAutoCharges;
//     uint public maxNotesPerProtocol = 1;
//     uint public tradingFee = 100;
//     address public nft_;
//     address public ft_;
//     mapping(address => bool) internal referrals;
//     bool public immutable immutableContract;
//     mapping(uint => uint) public autoPaidPayable;

//     event AddProtocol(address indexed from, uint time, address owner, uint lastProtocolId, string description);
//     event UpdateProtocol(address indexed from, uint time, address owner, string description);
//     event DeleteProtocol(address indexed from, uint time, address protocol);
//     event Deposit(address indexed from, uint amount);
//     event Withdraw(address indexed from, uint amount);
//     event PayInvoicePayable(address indexed from, uint time, uint paid);
//     event UpdateAutoCharge(address indexed from, uint time);
//     event RevenueClaim(address indexed from, uint revenueToClaim);
//     event SendInvoice(address indexed from, address indexed owner, uint time);
    
//     constructor(
//         string memory _name,
//         string memory _symbol,
//         address _token,
//         address _devaddr,
//         address _trustBounty,
//         uint _minCosigners,
//         bool _immutableContract,
//         bool _adminBountyRequired,
//         address _superLikeGaugeFactory,
//         bool _automatic,
//         address _profile,
//         address _ve
//     ) ERC721(_name, _symbol) 
//       Auth(_devaddr, _superLikeGaugeFactory)
//     {
//         token = _token; 
//         factory = msg.sender;
//         profile = _profile;
//         trustBounty = _trustBounty;
//         minCosigners = _minCosigners;
//         automatic = _automatic;
//         gaugeContract = _ve;
//         adminBountyRequired = _adminBountyRequired;
//         immutableContract = _automatic ? false : _immutableContract;
//         if (_minCosigners > 0) cosignEnabled = true;
//     }

//     modifier isNotBlackListed() {
//         require(!isBlackListed[msg.sender], "You have been blacklisted");
//         _;
//     }

//     modifier isOpened() {
//         require(maxActiveProtocols == 0 || maxActiveProtocols >= AllProtocols.length());
//         _;
//     }

//     modifier isAuthCleared () {
//         checkIdentityProof(msg.sender, false);
//         _;
//     } 

//     function getPaidPayable(uint _protocolId) external view returns(uint) {
//         if (automatic) {
//             return autoPaidPayable[protocolInfo[_protocolId].tokenId];
//         }
//         // return protocolInfo[_protocolId].paidPayable;
//     }

//     function updateParameters(
//         uint _maxActiveProtocols, 
//         uint _maxNotesPerProtocol,
//         address[] memory _protocolOwners,
//         bool _blacklist,
//         bool _bountyRequired,
//         uint _bufferTime,
//         uint _period,
//         uint _limitFactor,
//         uint _gaugeBalanceFactor
//     ) external onlyAdmin {
//         maxActiveProtocols = _maxActiveProtocols;
//         maxNotesPerProtocol = _maxNotesPerProtocol;
//         bountyRequired = _bountyRequired;
//         bufferTime = _bufferTime;
//         period = _period;
//         limitFactor = _limitFactor;
//         gaugeBalanceFactor = _gaugeBalanceFactor;
//         for (uint i = 0; i < _protocolOwners.length; i++) {
//             isBlackListed[_protocolOwners[i]] = _blacklist;
//         }
//     }

//     function updateLateDays(address _protocolOwner) external onlyAdmin {
//         (uint dueReceivable, uint nextDue, uint latePeriods) = getDueReceivable(_protocolOwner, 0);   
//         IProfile(profile).updateLateDays(
//             protocolInfo[addressToProtocolId[_protocolOwner]].profileId, 
//             latePeriods * protocolInfo[addressToProtocolId[_protocolOwner]].periodReceivable / 86400, //late days
//             dueReceivable
//         );
//     }

//     function _updateBounty(uint _bountyId) internal {
//         (address owner,address _token,,,,) = ITrustBounty(trustBounty).bountyInfo(_bountyId);
//         require(owner == msg.sender);
//         require(_token == token);
//         if (msg.sender == devaddr_) {
//             require(adminBountyId == 0);
//             adminBountyId = _bountyId;
//         } else {
//             require(protocolInfo[addressToProtocolId[msg.sender]].bountyId == 0);
//             protocolInfo[addressToProtocolId[msg.sender]].bountyId = _bountyId;
//         }
//     }
        
//     function _updateProfile(uint _profileId) internal {
//         (address owner,,,,,) = IProfile(profile).profileInfo(_profileId);
//         require(owner == msg.sender);
//         protocolInfo[addressToProtocolId[msg.sender]].profileId = _profileId;
//     }

//     function _updateTokenId(uint _tokenId) internal {
//         require(ve(IGaugeBalance(gaugeContract)._ve()).ownerOf(_tokenId) == msg.sender);
//         protocolInfo[addressToProtocolId[msg.sender]].tokenId = _tokenId;
//         // protocolInfo[addressToProtocolId[msg.sender]].paidPayable += autoPaidPayable[_tokenId];
//     }

//     function updateTradingFee(uint _tradingFee) external {
//         require(msg.sender == factory);
//         tradingFee = _tradingFee;
//     }

//     function createInvoiceNFT(
//         string memory _uri
//     ) external onlyAdmin {
//         require(nft_ == address(0x0), "ARP: InvoiceNFT collection already created");
//         nft_ = address(new InvoiceNFT(address(this), token, _uri));
//     }

//     function createInvoiceFT(string memory _name, string memory _symbol) external onlyAdmin {
//         require(ft_ == address(0x0), "ARP: InvoiceFT collection already created");
//         ft_ = address(new ERC20(_name, _symbol));
//     }

//     function updateDevs(address _newNFTDev) external onlyAdmin {
//         INFTicket(nft_).updateDev(_newNFTDev);
//     }

//     function tokenURI(uint _tokenId) public override view returns (string memory output) {
//         output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
//         output = string(abi.encodePacked(output, "Contract address: ", address(this), '</text><text x="10" y="40" class="base">'));
//         output = string(abi.encodePacked(output, "Amount due: ", toString(notes[_tokenId].due), '</text><text x="10" y="60" class="base">'));
//         output = string(abi.encodePacked(output, "Time due ", toString(notes[_tokenId].timer), '</text><text x="10" y="80" class="base">'));
//         output = string(abi.encodePacked(output, "Owner ", notes[_tokenId].protocol, '</text></svg>'));

//         string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "SponsorCard note #', toString(_tokenId), '", "description": "This card gives you access to amount due by the owner at date mentioned below.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
//         output = string(abi.encodePacked('data:application/json;base64,', json));
//     }

//     function transferDueToNote(address _to, uint _numPeriods) external nonReentrant {
//         (uint duePayable, uint nextDue,) = getDuePayable(msg.sender, _numPeriods);
//         duePayable = duePayable * protocolShares[addressToProtocolId[msg.sender]] / 10000;
//         require(protocolNotes[addressToProtocolId[msg.sender]] < maxNotesPerProtocol, "Maximum notes reached");
//         require(duePayable > 0, "You can't transfer a nul balance");
//         notes[tokenId] = Note({
//             due: duePayable,
//             timer: nextDue,
//             tokenId: tokenId,
//             protocol: msg.sender
//         });
//         protocolNotes[addressToProtocolId[msg.sender]] += 1;
//         if (automatic) {
//             autoPaidPayable[protocolInfo[addressToProtocolId[msg.sender]].tokenId] += duePayable;
//         }
//         // protocolInfo[addressToProtocolId[msg.sender]].paidPayable += duePayable;
//         _safeMint(_to, tokenId++, msg.data);
//     }
    
//     function transferDueToNoteReceivable(
//         address _to, 
//         address _protocol, 
//         uint _numPeriods
//     ) external onlyChangeDouble(msg.sender) nonReentrant {
//         (uint dueReceivable, uint nextDue,) = getDueReceivable(_protocol, _numPeriods);
//         require(dueReceivable > 0, "You can't transfer a nul balance");
//         adminNotes[_protocol] = tokenId;
//         notes[tokenId] = Note({
//             due: dueReceivable,
//             timer: nextDue,
//             tokenId: tokenId,
//             protocol: _protocol
//         });
//         _safeMint(_to, tokenId++, msg.data);
//     }

//     function autoChargeFromContract(
//         address _contract, 
//         address[] memory _owners, 
//         address[] memory _protocols,
//         uint _amount, 
//         uint _numPeriods
//     ) external {
//         require(
//             msg.sender == devaddr_ || 
//             msg.sender == nft_ ||
//             (_protocols.length == 1 && _protocols[0] == msg.sender) || true,
//             // (_protocols.length == 1 && protocolInfo[addressToProtocolId[_protocols[0]]].fromContract == msg.sender),
//             "Either merchant or protocol owner only!"
//         );
//         for (uint i = 0; i < _protocols.length; i++) {
//             (uint _price1,,) = IARP(_contract).getDueReceivable(_protocols[i], _numPeriods);
//             (uint _price2,,) = getDueReceivable(_protocols[i], _numPeriods);
//             uint _price = _price2;
//             if (_amount != 0) _price = Math.min(_amount, _price2);
//             _safeTransferFrom(token, _owners[i], address(this), _price);
//             _owners[i] = address(this);
//             // protocolInfo[addressToProtocolId[_protocols[i]]].paidReceivable += _price;
//             erc20(token).approve(_contract, Math.min(_amount, _price1));
//         }
//         IARP(_contract).autoCharge(_owners, _protocols, _amount, _numPeriods);
//     }

//     function autoCharge(
//         address[] memory _owners, 
//         address[] memory _protocols, 
//         uint _amount, 
//         uint _numPeriods
//     ) public nonReentrant {
//         require(_owners.length == _protocols.length, "Uneven lengths");
//         require(
//             msg.sender == devaddr_ || 
//             msg.sender == nft_ ||
//             (_protocols.length == 1 && _protocols[0] == msg.sender) ||
//             (_protocols.length == 1 && protocolInfo[addressToProtocolId[_protocols[0]]].fromContract == msg.sender),
//             "Either merchant or protocol owner only!"
//         );
//         for (uint i = 0; i < _protocols.length; i++) {
//             if ( _protocols[0] == msg.sender || msg.sender == nft_ || true
//                 // protocolInfo[addressToProtocolId[_protocols[0]]].fromContract == msg.sender
//             ) {
//                 (uint _price,,) = getDueReceivable(_protocols[i], _numPeriods);
//                 if (_amount != 0) _price = Math.min(_amount, _price);
//                 uint payswapFees = _price * tradingFee / 10000;
//                 _safeTransferFrom(token, _owners[i], address(this), _price);
//                 _safeTransfer(token, factory, payswapFees);
//                 // protocolInfo[addressToProtocolId[_protocols[i]]].paidReceivable += _price;
//                 if (adminNotes[_protocols[i]] > 0) {
//                     uint _tokenId = adminNotes[_protocols[i]];
//                     uint _paid = _price >= notes[_tokenId].due ? notes[_tokenId].due : _price;
//                     notes[_tokenId].due -= _paid;
//                     _price -= _paid;
//                     pendingRevenueFromNote[_tokenId] += _paid;
//                 }
//                 pendingRevenue += _price - payswapFees;
//             }
//         }
//     }

//     /**
//      * @notice Claim pending revenue (treasury or creators)
//      */
//     function claimPendingRevenue(uint revenueToClaim) external onlyChangeDouble(msg.sender) nonReentrant returns(uint) {
//         require(revenueToClaim != 0, "Claim: Nothing to claim");
//         if (revenueToClaim == 0) revenueToClaim = pendingRevenue;
//         pendingRevenue -= revenueToClaim;
//         _safeTransfer(token, address(msg.sender), revenueToClaim);

//         emit RevenueClaim(msg.sender, revenueToClaim);

//         return revenueToClaim;
//     }

//     function claimPendingRevenueFromNote(bool _adminNote, uint _tokenId) external nonReentrant {
//         require(ownerOf(tokenId) == msg.sender, "Only owner!");
//         uint256 revenueToClaim;
//         if (_adminNote) {
//             require(adminNotes[notes[_tokenId].protocol] == _tokenId, "Invalid admin note");
//             require(notes[_tokenId].due >= pendingRevenueFromNote[_tokenId], "Error with pending note revenue");
//             revenueToClaim = pendingRevenueFromNote[_tokenId] ;
//         } else {
//             require(notes[_tokenId].timer <= block.timestamp, "Not yet due");
//             uint _supply = erc20(token).balanceOf(address(this));
//             revenueToClaim = notes[_tokenId].due > _supply ? _supply : notes[_tokenId].due;
//         }
//         require(revenueToClaim != 0, "Claim: Nothing to claim");
//         notes[_tokenId].due -= revenueToClaim;
//         if (notes[_tokenId].due == 0) {
//             _burn(_tokenId); 
//             delete notes[_tokenId];
//             if (_adminNote) delete adminNotes[notes[_tokenId].protocol];
//         }
//         uint payswapFees = revenueToClaim * tradingFee / 10000;
//         _safeTransfer(token, address(msg.sender), revenueToClaim - payswapFees);
//         _safeTransfer(token, factory, payswapFees);

//         emit RevenueClaim(msg.sender, revenueToClaim);
//     }

//     function addProtocolFromContract(
//         address _owner,
//         address _contract,
//         address _fromContract,
//         uint _amountPayable,
//         uint _amountReceivable,
//         uint _periodPayable,
//         uint _periodReceivable,
//         uint _startReceivable,
//         uint _startPayable,
//         uint _bountyId,
//         uint _profileId,
//         uint _tokenId,
//         string memory _description
//     ) external onlyAdmin {
//         IARP(_contract).addProtocol(
//             _owner,
//             _fromContract,
//             _amountPayable,
//             _amountReceivable,
//             _periodPayable,
//             _periodReceivable,
//             _startReceivable,
//             _startPayable,
//             _bountyId,
//             _profileId,
//             _tokenId,
//             _description
//         );
//     }
    
//     function addProtocol(
//         address _owner,
//         address _fromContract,
//         uint _amountPayable,
//         uint _amountReceivable,
//         uint _periodPayable,
//         uint _periodReceivable,
//         uint _startReceivable,
//         uint _startPayable,
//         uint _bountyId,
//         uint _profileId,
//         uint _tokenId,
//         string memory _description
//     ) public isNotBlackListed isOpened isAuthCleared {
//         checkIdentityProof(_owner, false);
//         require(addressToProtocolId[_owner] == 0);
//         addressToProtocolId[_owner] = lastProtocolId;
//         protocolInfo[lastProtocolId] = ProtocolInfo({
//             // paidReceivable: 0,
//             // paidPayable: 0,
//             // fromContract: _fromContract,
//             amountReceivable: _amountReceivable,
//             amountPayable: msg.sender == devaddr_ ? _amountPayable : 0,
//             periodReceivable: _periodReceivable,
//             periodPayable: msg.sender == devaddr_ ? _periodPayable : 0,
//             startReceivable: block.timestamp + _startReceivable,
//             startPayable: msg.sender == devaddr_ ? block.timestamp + _startPayable : 0,
//             bountyId: 0,
//             profileId: 0,
//             owner: _owner,
//             tokenId: 0
//         });
//         protocolShares[lastProtocolId] = 10000;
//         _updateBounty(_bountyId);
//         _updateProfile(_profileId);
//         _updateTokenId(_tokenId);
//         AllProtocols.add(lastProtocolId);
//         if (devaddr_ == msg.sender && _fromContract != address(0)) {
//             IARP(_fromContract).addProtocol(
//                 _owner,
//                 address(0),
//                 _amountPayable,
//                 _amountReceivable,
//                 _periodPayable,
//                 _periodReceivable,
//                 _startReceivable,
//                 _startPayable,
//                 _bountyId,
//                 _profileId,
//                 _tokenId,
//                 _description
//             );
//         }

//         emit AddProtocol(msg.sender, block.timestamp, _owner, lastProtocolId++, _description);
//     }

//     function sendInvoice(
//         address _protocol, 
//         address[] memory _recipients, 
//         uint[] memory _shares
//     ) external {
//         require(msg.sender == devaddr_ || msg.sender == _protocol, "Only admin or protocol!");
//         require(protocolInfo[addressToProtocolId[_protocol]].startPayable > 0, "Cannot send invoice from pending protocol");
//         protocolShares[addressToProtocolId[_protocol]] -= _sumArr(_shares);
//         IInvoiceNFT(nft_).mintToBatch(
//             _protocol,
//             _recipients,
//             _shares
//         );
//         emit SendInvoice(msg.sender, _protocol, block.timestamp);
//     }

//     // used to remove paid days from contract
//     function updatePaidPayable(address _owner, uint _num) external onlyAdmin {
//         require(!immutableContract, "Only non immutable contract");
//         // protocolInfo[addressToProtocolId[_owner]].paidPayable += protocolInfo[addressToProtocolId[_owner]].amountPayable * _num;
//         // if (protocolInfo[protocolId].fromContract != address(0)) {
//         //     IARP(protocolInfo[protocolId].fromContract).updatePaidPayable(
//         //         _owner, 
//         //         protocolInfo[protocolId].amountPayable * _num
//         //     );
//         // }
//     }

//     // function updateProtocol(
//     //     address _owner,
//     //     uint _amountPayable,
//     //     uint _amountReceivable,
//     //     uint _periodPayable,
//     //     uint _periodReceivable,
//     //     uint _startReceivable,
//     //     uint _startPayable,
//     //     uint _bountyId,
//     //     uint _profileId,
//     //     uint _tokenId,
//     //     string memory _description
//     // ) external onlyAdmin {
//     //     if (protocolInfo[addressToProtocolId[_owner]].startPayable  == 0) {
//     //     //  only update start once
//     //         protocolInfo[addressToProtocolId[_owner]].startReceivable = block.timestamp + _startReceivable;
//     //         protocolInfo[addressToProtocolId[_owner]].startPayable = block.timestamp + _startPayable;
//     //         protocolInfo[addressToProtocolId[_owner]].amountReceivable = _amountReceivable;
//     //         protocolInfo[addressToProtocolId[_owner]].amountPayable = _amountPayable;
//     //         protocolInfo[addressToProtocolId[_owner]].periodReceivable = _periodReceivable;
//     //         protocolInfo[addressToProtocolId[_owner]].periodPayable = _periodPayable;
//     //         protocolInfo[addressToProtocolId[_owner]].owner = _owner;
//     //         protocolInfo[addressToProtocolId[_owner]].owner = _owner;
//     //         _updateBounty(_bountyId);
//     //         _updateProfile(_profileId);
//     //         _updateTokenId(_tokenId);
//     //         // if (protocolInfo[addressToProtocolId[_owner]].fromContract != address(0)) {
//     //         //     IARP(protocolInfo[addressToProtocolId[_owner]].fromContract).addProtocol(
//     //         //         _owner,
//     //         //         address(0),
//     //         //         _amountPayable,
//     //         //         _amountReceivable,
//     //         //         _periodPayable,
//     //         //         _periodReceivable,
//     //         //         _startReceivable,
//     //         //         _startPayable,
//     //         //         _bountyId,
//     //         //         _profileId,
//     //         //         _tokenId,
//     //         //         _description
//     //         //     );
//     //         // }
//     //     }

//     //     emit UpdateProtocol(msg.sender, block.timestamp, _owner, _description);
//     // }

//     // function deleteProtocol (address _protocol) public onlyAdmin {
//     //     (uint due,,) = getDuePayable(_protocol, 0);
//     //     require(due == 0, "Pay protocol invoice first");
//     //     delete protocolInfo[addressToProtocolId[_protocol]];
//     //     AllProtocols.remove(addressToProtocolId[_protocol]);

//     //     emit DeleteProtocol(msg.sender, block.timestamp, _protocol);
//     // }

//     function getNumPeriods(uint tm1, uint tm2, uint period) public pure returns(uint) {
//         if (tm1 == 0 || tm2 == 0 || tm2 <= tm1) return 0;
//         return period > 0 ? (tm2 - tm1) / period : 1;
//     }
    
//     function getAmountPayable(address _protocol) public view returns(uint) {
//         if (automatic) {
//             return IGaugeBalance(gaugeContract).balanceOf(protocolInfo[addressToProtocolId[_protocol]].tokenId) * gaugeBalanceFactor;
//         }
//         return protocolInfo[addressToProtocolId[_protocol]].amountPayable;
//     }

//     function getDuePayable(address _protocol, uint _numPeriods) public view returns(uint, uint, uint) {
//         uint numPeriods = getNumPeriods(
//             protocolInfo[addressToProtocolId[_protocol]].startPayable, 
//             block.timestamp, 
//             protocolInfo[addressToProtocolId[_protocol]].periodPayable
//         );
//         numPeriods += _numPeriods;
//         uint amountPayable = getAmountPayable(_protocol);
//         uint latePeriods = 0;//protocolInfo[addressToProtocolId[_protocol]].paidPayable / amountPayable;
//         // if (amountPayable * numPeriods > protocolInfo[addressToProtocolId[_protocol]].paidPayable) {
//         //     return (
//         //         amountPayable * numPeriods - protocolInfo[addressToProtocolId[_protocol]].paidPayable,
//         //         protocolInfo[addressToProtocolId[_protocol]].periodPayable * numPeriods + protocolInfo[addressToProtocolId[_protocol]].startPayable,
//         //         latePeriods
//         //     );
//         // }
//         return (0, numPeriods * protocolInfo[addressToProtocolId[_protocol]].periodPayable + protocolInfo[addressToProtocolId[_protocol]].startPayable, latePeriods);
//     }

//     function getDueReceivable(address _protocol, uint _numPeriods) public view returns(uint, uint, uint) {   
//         uint numPeriods = getNumPeriods(
//             protocolInfo[addressToProtocolId[_protocol]].startReceivable, 
//             block.timestamp, 
//             protocolInfo[addressToProtocolId[_protocol]].periodReceivable
//         );
//         numPeriods += _numPeriods;
//         uint latePeriods = 0;//protocolInfo[addressToProtocolId[_protocol]].paidReceivable / protocolInfo[addressToProtocolId[_protocol]].amountReceivable;
//         // if (protocolInfo[addressToProtocolId[_protocol]].amountReceivable * numPeriods > protocolInfo[addressToProtocolId[_protocol]].paidReceivable) {
//         //     return (
//         //         protocolInfo[addressToProtocolId[_protocol]].amountReceivable * numPeriods - protocolInfo[addressToProtocolId[_protocol]].paidReceivable,
//         //         protocolInfo[addressToProtocolId[_protocol]].periodReceivable * numPeriods + protocolInfo[addressToProtocolId[_protocol]].startReceivable,
//         //         latePeriods
//         //     );
//         // }
//         return (0, numPeriods * protocolInfo[addressToProtocolId[_protocol]].periodReceivable + protocolInfo[addressToProtocolId[_protocol]].startReceivable, latePeriods);
//     }

//     // function getAllDuePayables() public view returns(uint) {
//     //     uint[] memory protocols = new uint[](AllProtocols.length());
//     //     for (uint i = 0; i < AllProtocols.length(); i++) {
//     //         protocols[i] = AllProtocols.at(i);
//     //     }
//     //     return batchGetDuePayable(protocols);    
//     // }

//     // function getAllDueReceivables() public view returns(uint) {
//     //     uint[] memory protocols = new uint[](AllProtocols.length());
//     //     for (uint i = 0; i < AllProtocols.length(); i++) {
//     //         protocols[i] = AllProtocols.at(i);
//     //     }
//     //     return batchGetDueReceivable(protocols);    
//     // }

//     // function batchGetDuePayable(uint[] memory _protocolIds) public view returns(uint _total) {
//     //     for (uint i = 0; i < _protocolIds.length; i++) {
//     //         (uint due,,) = getDuePayable(protocolInfo[_protocolIds[i]].owner, 0);
//     //         _total += due;
//     //     }
//     // }

//     // function batchGetDueReceivable(uint[] memory _protocolIds) public view returns(uint _total) {
//     //     for (uint i = 0; i < _protocolIds.length; i++) {
//     //         (uint due,,) = getDueReceivable(protocolInfo[_protocolIds[i]].owner, 0);
//     //         _total += due;
//     //     }
//     // }

//     // function getNotesDue(uint[] memory _tokenIds) public view returns(uint _total) {
//     //     for (uint i = 0; i < _tokenIds.length; i++) {
//     //         _total += notes[_tokenIds[i]].due;
//     //     }
//     // }

//     // function getNotesDueIdx(uint _start, uint _end) public view returns(uint _total) {
//     //     for (uint i = _start; i <= _end; i++) {
//     //         _total += notes[i].due;
//     //     }
//     // }

//     // function payAllInvoices() external {
//     //     uint[] memory protocols = new uint[](AllProtocols.length());
//     //     for (uint i = 0; i < AllProtocols.length(); i++) {
//     //         protocols[i] = AllProtocols.at(i);
//     //     }
//     //     batchPayInvoices(protocols);    
//     // }

//     // function batchPayInvoices(uint[] memory _protocolIds) public {
//     //     for (uint i = 0; i < _protocolIds.length; i++) {
//     //         if (protocolInfo[_protocolIds[i]].startPayable != 0){
//     //             payInvoicePayable(
//     //                 protocolInfo[_protocolIds[i]].owner,
//     //                 protocolInfo[_protocolIds[i]].owner,
//     //                 protocolShares[_protocolIds[i]]
//     //             );
//     //         }
//     //     }
//     // }
    
//     // function payInvoicePayableFromContract(
//     //     address _contract, 
//     //     address _protocol, 
//     //     address _owner,
//     //     uint _share
//     // ) external onlyAdmin {
//     //     IARP(_contract).payInvoicePayable(
//     //         _protocol,
//     //         _owner, 
//     //         _share
//     //     );
//     // }

//     // function notifyRewardAmount(address _token, address _protocol, uint _payment) external {
//     //     _safeTransferFrom(_token, msg.sender, address(this), _payment);
//     //     (uint duePayable,,) = getDuePayable(_protocol, 0);
//     //     uint _toPay = Math.min(duePayable, _payment);
//     //     if (automatic) {
//     //         autoPaidPayable[protocolInfo[addressToProtocolId[_protocol]].tokenId] += _toPay;
//     //     }
//     //     // protocolInfo[addressToProtocolId[_protocol]].paidPayable += _toPay;
//     //     _safeTransfer(token, _protocol, _toPay);
//     // }

//     function payInvoicePayable(
//         address _protocol, 
//         address _owner, 
//         uint _share
//     ) public nonReentrant {
//         require(
//             _protocol == msg.sender || 
//             devaddr_ == msg.sender || 
//             nft_ == msg.sender,
//             // protocolInfo[addressToProtocolId[_protocol]].fromContract == msg.sender, 
//             "Only invoice owner or admin!"
//         );
//         (uint duePayable,,) = getDuePayable(_protocol, 0);
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
//         // protocolInfo[addressToProtocolId[_protocol]].paidPayable += _toPay;
//         require(_toPay > 0, "Nothing to pay yet");
//         uint payswapFees = _toPay * tradingFee / 10000;
//         _toPay -= payswapFees;
//         _safeTransfer(token, factory, payswapFees);

//         if (_isContract(msg.sender)) {
//             erc20(token).approve(msg.sender, _toPay);
//             IARP(_protocol).notifyRewardAmount(token, _protocol, _toPay);
//         } else {
//             _safeTransfer(token, _owner, _toPay);
//         }

//         emit PayInvoicePayable(_protocol, block.timestamp, _toPay);
//     }
    
//     // function depositAll() external {
//     //     deposit(getAllDuePayables());
//     // }

//     // function depositAllNotes(uint _start, uint _end) external {
//     //     deposit(getNotesDueIdx(_start, _end));
//     // }

//     // function depositAllNotes2(uint[] memory _tokenIds) external {
//     //     deposit(getNotesDue(_tokenIds));
//     // }

//     // function deposit(uint _amount) public nonReentrant {
//     //     require(_amount > 0, "Invalid amount");
//     //     _safeTransferFrom(token, msg.sender, address(this), _amount);
        
//     //     emit Deposit(msg.sender, _amount);
//     // }

//     // function withdrawAll() external onlyChangeDouble(msg.sender) {
//     //     withdraw(erc20(token).balanceOf(address(this)));
//     // }

//     // function withdraw(uint amount) public onlyChangeDouble(msg.sender) {
//     //     _safeTransfer(token, msg.sender, amount);
        
//     //     emit Withdraw(msg.sender, amount);
//     // }

//     // function createStake(
//     //     address _collection,
//     //     address _token,
//     //     string memory _videoId,
//     //     address _sender,
//     //     uint _direction,
//     //     uint _stakedSender, 
//     //     uint _stakedReceiver, 
//     //     uint _paymentSender,
//     //     uint _paymentReceiver,
//     //     string memory _note
//     // ) external onlyChangeDouble(_sender) {
//     //     require(_token == token, "Invalid token");
//     //     require(_sender == msg.sender, "Invalid sender");
//     //     pendingRevenue -= _paymentSender;
//     //     erc20(token).approve(msg.sender, _paymentSender);
//     //     IMarketPlace(msg.sender).processPayment(
//     //         _collection, 
//     //         _videoId, 
//     //         _sender, 
//     //         _paymentSender,
//     //         _direction
//     //     );
//     // }

//     // function createStakeInStakeMarket(
//     //     address _contract,
//     //     uint _direction,
//     //     string memory _tokenId,
//     //     uint256 _price,
//     //     uint256[3] memory _stakes,
//     //     string memory _note
//     // ) external onlyAdmin {
//     //     pendingRevenue -= _price;
//     //     IPaymentContract(_contract).createStake(
//     //         msg.sender,
//     //         token,
//     //         _tokenId,
//     //         msg.sender,
//     //         _direction,
//     //         _stakes[0], 
//     //         _stakes[1],
//     //         _price,
//     //         _stakes[2],
//     //         _note
//     //     );
//     // }
    
//     // function addReferrals(address[] memory _referrers, bool _add) external onlyAdmin {
//     //     for (uint i = 0; i < _referrers.length; i++) {
//     //         referrals[_referrers[i]] = _add;
//     //     }
//     // }

//     // function _referrals(address _receiver, string memory _tokenId) external view returns (address, uint) {
//     //     return (referrals[_receiver] ? _receiver : address(0), 0);
//     // }

//     // function processPayment(
//     //     address _collection, 
//     //     string memory _tokenId, 
//     //     address _buyer, 
//     //     uint256 _price,
//     //     uint _direction
//     // ) external nonReentrant {
//     //     _safeTransferFrom(token, msg.sender, address(this), _price);
//     //     pendingRevenue += _price;
//     // }

//     // function addInvoiceFromFactory(
//     //     address _sender,
//     //     address _valuepool,
//     //     int _periodReceivable,
//     //     string memory _cartItems
//     // ) external onlyChangeDouble(_sender) {
//     //     require(_sender == msg.sender, "Invalid sender");
//     //     IARPFactory(factory).addInvoiceFromFactory(
//     //         _valuepool,
//     //         _periodReceivable,
//     //         _cartItems
//     //     );
//     // }
    
//     // function updateCartItems(
//     //     address _sender,
//     //     address _valuepool,
//     //     string memory _cartItems
//     // ) external onlyChangeDouble(_sender) {
//     //     require(_sender == msg.sender, "Invalid sender");
//     //     IValuePool(_valuepool).updateCartItems(_cartItems);
//     // }

//     // function reimburseLoan(
//     //     address _sender,
//     //     address _valuepool,
//     //     uint _amount
//     // ) external onlyChangeDouble(_sender) {
//     //     require(_sender == msg.sender, "Invalid sender");
//     //     IValuePool(_valuepool).reimburseLoan(_amount);
//     // }

//     // function deposit(
//     //     address _sender,
//     //     address _valuepool,
//     //     uint _amount
//     // ) external onlyChangeDouble(_sender) {
//     //     require(_sender == msg.sender, "Invalid sender");
//     //     IValuePool(_valuepool).deposit(_amount);
//     // }

//     // function withdraw(
//     //     address _sender,
//     //     address _valuepool,
//     //     uint _amount
//     // ) external onlyChangeDouble(_sender) {
//     //     require(_sender == msg.sender, "Invalid sender");
//     //     IValuePool(_valuepool).withdraw(_amount);
//     // }

//     // function pickRank(
//     //     address _valuepool,
//     //     address _sender
//     // ) external onlyChangeDouble(_sender) {
//     //     require(_sender == msg.sender, "Invalid sender");
//     //     IValuePool(_valuepool).pickRank();
//     // }

//     // function claimRank(
//     //     address _valuepool,
//     //     address _sender
//     // ) external onlyChangeDouble(_sender) {
//     //     require(_sender == msg.sender, "Invalid sender");
//     //     IValuePool(_valuepool).claimRank();
//     // }

//     // function claimReward(
//     //     address _sender,
//     //     uint _paid,
//     //     string memory _videoId,
//     //     address _valuepool,
//     //     address _merchant,
//     //     address _merchantGauge
//     // ) external onlyChangeDouble(_sender) {
//     //     require(_sender == msg.sender, "Invalid sender");
//     //     IValuePool(_valuepool).claimReward(_paid, _videoId, _merchant, _merchantGauge);
//     // }
    
//     function updateBalances() public {
//         if (block.timestamp >= active_period) {
//             for (uint i = 0; i < AllProtocols.length(); i++) {
//                 balanceOf[AllProtocols.at(i)] = 0;
//             }
//             active_period = block.timestamp / period * period;
//         }
//     }
    
//     function _safeTransfer(address _token, address to, uint256 value) internal {
//         if (to != address(this) && ((to == IARP(msg.sender).devaddr_() && IARP(msg.sender).adminBountyRequired()) || 
//         (to != IARP(msg.sender).devaddr_() && IARP(msg.sender).bountyRequired()))) {
//             IARP(msg.sender).updateBalances();
//             uint bountyId = to == IARP(msg.sender).devaddr_() ? IARP(msg.sender).adminBountyId() : IARP(msg.sender).protocolInfo(IARP(msg.sender).addressToProtocolId(to)).bountyId;
//             uint _limit = ITrustBounty(trustBounty).getBalance(bountyId);
//             (,,,,uint endTime,) = ITrustBounty(trustBounty).bountyInfo(bountyId);
//             require(endTime > block.timestamp + IARP(msg.sender).bufferTime());
//             uint amount = value * IARP(msg.sender).limitFactor() / 10000;
//             amount = Math.min(amount, _limit - IARP(msg.sender).balanceOf(IARP(msg.sender).addressToProtocolId(to)));
//             IARP(msg.sender).updateBalanceOf(to, amount)
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

//     function _safeApprove(address _token, address spender, uint256 value) internal {
//         require(_token.code.length > 0);
//         (bool success, bytes memory data) =
//         _token.call(abi.encodeWithSelector(erc20.approve.selector, spender, value));
//         require(success && (data.length == 0 || abi.decode(data, (bool))));
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

//     function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
//         return this.onERC1155Received.selector;
//     }

//     function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
//         return this.onERC1155BatchReceived.selector;
//     }
// }

// contract ARPFactory {
//     using EnumerableSet for EnumerableSet.AddressSet;

//     EnumerableSet.AddressSet private gauges;
//     address public profile;
//     address public trustBounty;
//     address public superLikeGaugeFactory;
//     address public devaddr_;
//     uint public tradingFee;

//     constructor() {
//         devaddr_ = msg.sender;
//     }

//     function updateDev(address _devaddr) external {
//         require(msg.sender == devaddr_);
//         devaddr_ = _devaddr;
//     }

//     function getAllARPs() external returns(address[] memory arps) {
//         arps = new address[](gauges.length());
//         for (uint i = 0; i < gauges.length(); i++) {
//             arps[i] = gauges.at(i);
//         }    
//     }

//     function deleteARP(address _arp) external {
//         require(msg.sender == devaddr_ || IGauge(_arp).devaddr_() == msg.sender);
//         gauges.remove(_arp);
//     }

//     function createGauge(
//         string memory _name,
//         string memory _symbol,
//         address _token,
//         address _devaddr,
//         uint _minCosigners,
//         bool _immutableContract,
//         bool _adminBountyRequired,
//         bool _automatic,
//         address _ve
//     ) external returns (address) {
//         require(profile != address(0x0) && 
//                 trustBounty != address(0x0) && 
//                 superLikeGaugeFactory!= address(0x0));
//         string memory _uri = string(abi.encodePacked(_name, _symbol));
//         address nft_ = address(new InvoiceNFT(address(this), token, _uri));
//         address ft_ = address(new ERC20(_name, _symbol));
//         address last_gauge = address(new ARP(
//             nft_,
//             ft_,
//             _token,
//             _devaddr,
//             trustBounty,
//             _minCosigners,
//             superLikeGaugeFactory,
//             profile,
//             _ve
//         ));
//         gauges.add(last_gauge);
//     }

//     function updateContracts(
//         address _profile,
//         address _trustBounty,
//         address _superLikeGaugeFactory
//     ) external {
//         profile = _profile;
//         trustBounty = _trustBounty;
//         superLikeGaugeFactory = _superLikeGaugeFactory;
//     }

//     function updateTradingFee(uint _newFee) external {
//         require(msg.sender == devaddr_);
//         tradingFee = _tradingFee;
//     }

//     // function addInvoiceFromFactory(
//     //     address _valuepool,
//     //     int _periodReceivable,
//     //     string memory _cartItems
//     //  ) external {
//     //      require(isGauge[msg.sender], "Only gauge");
//     //      IValuePool(_valuepool).addInvoiceFromFactory(
//     //         msg.sender,
//     //         _periodReceivable,
//     //         _cartItems
//     //      );
//     // }
// }
// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;

// import "./BadgeNFT.sol";

// // Gauges are used to incentivize pools, they emit reward tokens over 7 days for staked LP tokens
// contract SuperLikeGauge is ReentrancyGuard {
//     using EnumerableSet for EnumerableSet.AddressSet;
//     using EnumerableSet for EnumerableSet.UintSet;

//     address[] public tokens;
//     address public _ve; // the ve token used for gauges
//     address public voter;
//     address public immutable factory;
//     mapping(address => uint) public tokenIds;
//     address public payswapAdmin = 0x0bDabC785a5e1C71078d6242FB52e70181C1F316;
//     // info about owner
//     uint public tokenId;
//     string public cancan_email; 
//     string public creative_cid; 
//     string public video_cid; 
//     string public website_link; 
//     string public description; 

//     enum COLOR {
//         UNDEFINED,
//         BLACK,
//         BROWN,
//         SILVER,
//         GOLD
//     }
//     COLOR internal _badgeColor = COLOR.BLACK;
//     COLOR internal _adminSetBadgeColor = COLOR.UNDEFINED;
//     mapping(address => EnumerableSet.UintSet) private _tokenIdsOfSellerForCollection;
//     EnumerableSet.AddressSet private _collectionAddressSet;

//     struct ProtocolInfo {
//         uint idx;
//         address token;
//         uint amountReceivable;
//         uint paidReceivable;
//         uint periodReceivable;
//         uint startReceivable;
//         uint dueReceivable;
//         int rating;
//         string ratingString;
//         string ratingDescription;
//     }
//     mapping(address => ProtocolInfo) public protocolInfo;
//     address[] public protocols;
//     uint public maxActiveProtocols;
//     uint public protocolCount;
//     mapping(address => bool) public blacklist;
//     mapping(address => bool) public isToken;
//     address public devaddr_;
//     mapping(address => uint) public lotteryCreditFromPrice;
//     mapping(address => uint) public lotteryCreditFromNumbers;

//     event Deposit(address indexed from, uint tokenId, uint amount);
//     event Withdraw(address indexed from, uint tokenId, uint amount);
//     event NotifyReward(address indexed from, address indexed reward, uint amount);

//     event CollectionNew(address indexed collection, address indexed seller);
//     event ListNew(address indexed collection, address indexed seller, uint256 indexed tokenId);
//     event ListCancel(address indexed collection, address indexed seller, uint256 indexed tokenId);
//     event AddProtocol(address indexed from, uint time, address owner);
//     event UpdateProtocol(address indexed from, uint time, address owner);
//     event DeleteProtocol(address indexed from, uint time, uint pid);
//     event PayInvoiceReceivable(address indexed from, uint pid, uint paid);

//     constructor(
//         address  __ve, 
//         uint _tokenId, 
//         address _voter,
//         address _devaddr
//     ) {
//         _ve = __ve;
//         voter = _voter;
//         tokenId = _tokenId;
//         devaddr_ = _devaddr;
//         factory = msg.sender;
//     }

//     modifier isNotBlackListed() {
//         require(!blacklist[msg.sender], "You have been blacklisted");
//         _;
//     }

//     modifier onlyAdmin() {
//         require(
//             msg.sender == devaddr_, "Gauge: Not owner");
//         _;
//     }

//     modifier isOpened() {
//         require(maxActiveProtocols == 0 || maxActiveProtocols >= protocolCount);
//         _;
//     }

//     function updateVoterNVe(address __ve, address _voter) external onlyAdmin {
//         _ve = __ve;
//         voter = _voter;
//     }

//     function updateMaxActiveProtocols(uint _newMax) external onlyAdmin {
//         maxActiveProtocols = _newMax;
//     }

//     function updateVideoCid(string calldata _video_cid) external onlyAdmin {
//         video_cid = _video_cid;
//     }

//     function updateCreativeCid(string calldata _creative_cid) external onlyAdmin {
//         creative_cid = _creative_cid;
//     }

//     function updateCancanEmail(string calldata _cancan_email) external onlyAdmin {
//         ISuperLikeGaugeFactory(factory).updateGaugeEmail(cancan_email, _cancan_email);
//         cancan_email = _cancan_email;
//     }

//     function updateWebsiteLink(string calldata _website_link) external onlyAdmin {
//         website_link = _website_link;
//     }

//     function updateDescription(string calldata _description) external onlyAdmin {
//         description = _description;
//     }
    
//     function updateLotteryCredits(uint _fromNumber, uint _fromPrice) external {
//         lotteryCreditFromNumbers[msg.sender] += _fromNumber;
//         lotteryCreditFromPrice[msg.sender] += _fromPrice;
//     }

//     function badgeColor() external view returns(COLOR) {
//         if (_adminSetBadgeColor == COLOR.UNDEFINED) {
//             return _badgeColor;
//         }
//         return _adminSetBadgeColor;
//     }

//     function updateAdminSetBadgeColor(COLOR _color) external {
//         require(msg.sender == payswapAdmin, "Only payswap admin!");
//         _adminSetBadgeColor = _color;
//     }

//     function useLotteryCredit(address _marketPlace, uint _amount) external {
//         require(lotteryCreditFromNumbers[_marketPlace] + lotteryCreditFromPrice[_marketPlace] >= _amount,
//         "Not enough credits");
//         uint _credit;
//         if (lotteryCreditFromNumbers[_marketPlace] >= _amount) {
//             lotteryCreditFromNumbers[_marketPlace] -= _amount;
//             _credit += _amount;
//         } else {
//             lotteryCreditFromNumbers[_marketPlace] = 0;
//             _credit += lotteryCreditFromNumbers[_marketPlace];

//             if (lotteryCreditFromPrice[_marketPlace] >= _amount - _credit) {
//                 lotteryCreditFromPrice[_marketPlace] -= _amount - _credit;
//                 _credit += _amount - _credit;
//             }
//         }
//         require(_credit == _amount, "Error computing credits");
//     }

//     function setBadgeColor(COLOR _color) external {
//         if (msg.sender == payswapAdmin) {
//             _badgeColor = _color;
//         } else {
//             _color = COLOR((Voter(voter).getColor(address(this))));
//             _badgeColor = _color;
//         }
//     }

//     function updatePayswapAdmin(address _newAdmin) external {
//         require(msg.sender == payswapAdmin, "Not payswapAdmin");
//         payswapAdmin = _newAdmin;
//     }

//     function updateDev(address _dev) external onlyAdmin {
//         devaddr_ = _dev;
//     }

//     function updateTokenId(uint _tokenId) external onlyAdmin {
//         require(ve(_ve).ownerOf(_tokenId) == msg.sender, "Not token owner");
//         tokenId = _tokenId;
//     }

//     function updateRating(
//         address _owner, 
//         int _rating,
//         string memory _ratingString, 
//         string memory _description
//     ) external onlyAdmin {
//         protocolInfo[_owner].rating = _rating;
//         protocolInfo[_owner].ratingString = _ratingString;
//         protocolInfo[_owner].ratingDescription = _description;
//     }

//     function addProtocol(
//         address _owner,
//         address _token,
//         uint _amountReceivable,
//         uint _periodReceivable,
//         uint _startReceivable,
//         string memory _description
//     ) external isNotBlackListed isOpened {
//         protocols.push(_owner);
//         uint _start = msg.sender == devaddr_ ? _startReceivable : 0;
//         protocolInfo[_owner] = ProtocolInfo({
//             idx: protocols.length,
//             amountReceivable: _amountReceivable,
//             paidReceivable: 0,
//             periodReceivable: _periodReceivable,
//             dueReceivable: 0,
//             token: _token,
//             startReceivable: block.timestamp + _start,
//             rating: 0,
//             ratingString: "",
//             ratingDescription: _description
//         });
//         protocolCount += 1;

//         emit AddProtocol(msg.sender, block.timestamp, _owner);
//     }

//     function updatePayment(
//         address _owner,
//         address _token,
//         uint _amountReceivable,
//         uint _periodReceivable,
//         uint _startReceivable
//     ) external onlyAdmin {
//         if (protocolInfo[_owner].startReceivable < block.timestamp) {
//             protocolInfo[_owner].token = _token;
//         }
//         protocolInfo[_owner].amountReceivable = _amountReceivable;
//         protocolInfo[_owner].periodReceivable = _periodReceivable;
//         protocolInfo[_owner].startReceivable = block.timestamp + _startReceivable;
        

//         emit UpdateProtocol(msg.sender, block.timestamp, _owner);
//     }

//     function deleteProtocol(address _owner) public onlyAdmin {
//         uint _pid = protocolInfo[_owner].idx;
//         delete protocols[_pid];
//         delete protocolInfo[_owner];
//         protocolCount -= 1;

//         emit DeleteProtocol(msg.sender, block.timestamp, _pid);
//     }

//     function _updateInvoiceDueReceivable() internal {
//         if (protocolInfo[msg.sender].periodReceivable > 0) { //it is periodic
//             uint deadline = protocolInfo[msg.sender].startReceivable + 
//             protocolInfo[msg.sender].periodReceivable;
//             if (block.timestamp > deadline) {
//                 protocolInfo[msg.sender].startReceivable = deadline;
//                 protocolInfo[msg.sender].dueReceivable = 
//                 protocolInfo[msg.sender].dueReceivable + 
//                 protocolInfo[msg.sender].amountReceivable;
//             }
//         } else {
//             protocolInfo[msg.sender].dueReceivable = 
//             protocolInfo[msg.sender].amountReceivable - 
//             protocolInfo[msg.sender].paidReceivable;
//         }
//     }
    
//     function payInvoiceReceivable(uint _paid) external nonReentrant {
//         _updateInvoiceDueReceivable();

//         uint paid = protocolInfo[msg.sender].dueReceivable > _paid ? 
//         _paid : protocolInfo[msg.sender].dueReceivable;
//         if (!isToken[protocolInfo[msg.sender].token]) {
//             isToken[protocolInfo[msg.sender].token] = true;
//             tokens.push(protocolInfo[msg.sender].token);
//         }
//         _safeTransferFrom(
//             protocolInfo[msg.sender].token, 
//             msg.sender, 
//             address(this), 
//             paid
//         );
//         protocolInfo[msg.sender].paidReceivable += paid;
//         protocolInfo[msg.sender].dueReceivable -= paid;

//         emit PayInvoiceReceivable(msg.sender, block.timestamp, paid);
//     }

//     function updateBlacklist(address[] memory _accounts, bool[] memory _blacklists) external onlyAdmin {
//         require(_accounts.length == _blacklists.length, "Blackist: Uneven lists");
//         for (uint i = 0; i < _accounts.length; i++) {
//             blacklist[_accounts[i]] = _blacklists[i];
//         }
//     }
    
//     function withdrawAll() external {
//         for (uint i = 0; i < tokens.length; i++) {
//             uint _balance = erc20(tokens[i]).balanceOf(address(this));
//             if (_balance > 0) withdraw(tokens[i], _balance);
//         }
//     }

//     function withdraw(address _token, uint amount) public onlyAdmin {
//         _safeTransfer(_token, msg.sender, amount);

//         emit Withdraw(msg.sender, tokenId, amount);
//     }
    
//     function notifyRewardAmount(address _token, uint _amount) external nonReentrant {
//         require(_amount > 0 && !blacklist[msg.sender], "Invalid amount or account");
//         require(tokenId > 0, "Invalid tokenId for gauge");
//         if (!isToken[_token]) {
//             isToken[_token] = true;
//             tokens.push(_token);
//         }
//         _safeTransferFrom(_token, msg.sender, address(this), _amount);

//         emit NotifyReward(msg.sender, _token, _amount);
//     }

//     function addCollection(address _collection) external onlyAdmin {
//         require(!_collectionAddressSet.contains(_collection), "Operations: Collection already listed");
//         require(IERC721(_collection).supportsInterface(0x80ac58cd), "Operations: Not ERC721");

//         _collectionAddressSet.add(_collection);
        
//         emit CollectionNew(_collection, msg.sender);
//     }

//     function createListing(
//         address _collection,
//         uint256 _tokenId
//     ) public onlyAdmin {
//         IERC721(_collection).safeTransferFrom(address(msg.sender), address(this), _tokenId);
//         // Adjust the information
//         _tokenIdsOfSellerForCollection[_collection].add(_tokenId);

//         // Emit event
//         emit ListNew(_collection, msg.sender, _tokenId);
//     }

//     /**
//      * @notice Cancel existing ask order
//      * @param _collection: contract address of the NFT
//      * @param _tokenId: tokenId of the NFT
//      */
//     function cancelListing(address _collection, uint256 _tokenId) public onlyAdmin {
//         // Verify the sender has listed it
//         require(_tokenIdsOfSellerForCollection[_collection].contains(_tokenId), "Order: Token not listed");
        
//         // Adjust the information
//         _tokenIdsOfSellerForCollection[_collection].remove(_tokenId);
        
//         // Transfer the NFT back to the user
//         IERC721(_collection).transferFrom(address(this), address(msg.sender), _tokenId);

//         // Emit event
//         emit ListCancel(_collection, msg.sender, _tokenId);
//     }

//     function updateApi(address _badgeNFT, uint _tokenId, string memory _api) external {
//         IBadgeNFT(_badgeNFT).updateApi(
//             _tokenId, 
//             _api
//         );
//     }

//     function updateInfo(
//         address _badgeNFT, 
//         uint _tokenId, 
//         address _owner
//     ) external {
//         IBadgeNFT(_badgeNFT).updateInfo(
//             _tokenId,
//             protocolInfo[_owner].rating,
//             protocolInfo[_owner].ratingString,
//             protocolInfo[_owner].ratingDescription
//         );
//     }

//     function mintBadge(
//         address _owner,
//         address _to, 
//         int256 _rating,
//         string memory _ratingString,
//         string memory _ratingDescription
//     ) external {
//         require(msg.sender == _owner || msg.sender == devaddr_, "Only owner or admin");
//         ISuperLikeGaugeFactory(factory).mintBadge(
//             _to, 
//             protocolInfo[_owner].rating,
//             protocolInfo[_owner].ratingString,
//             protocolInfo[_owner].ratingDescription
//         );
//     }
    
//     function safeTransferFrom(
//         address _from,
//         address _to,
//         uint _tokenId
//     ) external {
//         ISuperLikeGaugeFactory(factory).safeTransferFrom(
//             _from,
//             _to,
//             _tokenId
//         );
//     }

//     function _safeTransfer(address token, address to, uint256 value) internal {
//         require(token.code.length > 0);
//         (bool success, bytes memory data) =
//         token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
//         require(success && (data.length == 0 || abi.decode(data, (bool))));
//     }

//     function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
//         require(token.code.length > 0);
//         (bool success, bytes memory data) =
//         token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
//         require(success && (data.length == 0 || abi.decode(data, (bool))));
//     }

//     function _safeApprove(address token, address spender, uint256 value) internal {
//         require(token.code.length > 0);
//         (bool success, bytes memory data) =
//         token.call(abi.encodeWithSelector(erc20.approve.selector, spender, value));
//         require(success && (data.length == 0 || abi.decode(data, (bool))));
//     }
// }

// contract SuperLikeGaugeFactory is Ownable {
//     using EnumerableSet for EnumerableSet.AddressSet;
//     address public last_gauge;
//     address[] public gauges;
//     address public badgeNFT;
//     address[] public badgeNFTs;
//     mapping(address => bool) public isGauge;
//     mapping(address => address) public userGauge;
//     mapping(address => uint) public referrers;
//     mapping(string => address) public gaugeEmails;
//     mapping(string => address) public ssids;
//     mapping(bytes32 => EnumerableSet.AddressSet) private elligibleForLoan;
//     mapping(address => bool) public isLender;
//     struct SSID {
//         string value;
//         uint expirationDate;
//         address auditorGauge;
//     }
//     mapping(address => mapping(string => SSID)) public identityProofs;
//     address public devaddr_;
//     mapping(address => bool) public marketPlaces;

//     constructor() {devaddr_ = msg.sender;}

//     function createBadgeNFT(
//         string memory _uri, 
//         bool _confirm
//     ) external {
//         require(msg.sender == devaddr_, "Only dev");
//         require(badgeNFT == address(0) || _confirm, "SuperLikeGauge: NFT already minted");
//         badgeNFT = address(new BadgeNFT(_uri));
//         badgeNFTs.push(badgeNFT);
//     }

//     function addMarketPlace(address _marketPlace, bool _add) external {
//         require(msg.sender == devaddr_, "Only dev");
//         marketPlaces[_marketPlace] = _add;
//     }

//     function getIdentityValue(
//         address _owner, 
//         string memory _valueName
//     ) public view returns(string memory, string memory, address) {
//         require(identityProofs[_owner][_valueName].auditorGauge != address(0),
//         "Non existant proof");
//         uint _expirationDate0 = identityProofs[_owner]["ssid"].expirationDate;
//         uint _expirationDate = identityProofs[_owner][_valueName].expirationDate;
//         return (
//             _expirationDate0 < block.timestamp ? identityProofs[_owner]["ssid"].value: "",
//             _expirationDate < block.timestamp ? identityProofs[_owner][_valueName].value: "",
//             _expirationDate < block.timestamp ? identityProofs[_owner][_valueName].auditorGauge: address(0)
//         );
//     }

//     function setElligibleForLoan(bytes32[] memory _idCodes, address _lender, bool _add) external {
//         require(isLender[msg.sender], "Only lenders!");

//         for (uint i = 0; i < _idCodes.length; i++) {
//             if (_add) {
//                 elligibleForLoan[_idCodes[i]].add(_lender);
//             } else {
//                 elligibleForLoan[_idCodes[i]].remove(_lender);
//             }
//         }
//     }

//     function isElligibleForLoan(bytes32 _idCode) external returns(bool) {
//         return elligibleForLoan[_idCode].length() == 0;
//     }

//     function getAllDues(bytes32 _idCode) external view returns(address[] memory dues) {
//         dues = new address[](elligibleForLoan[_idCode].length());
//         for (uint i = 0; i < elligibleForLoan[_idCode].length(); i++) {
//             dues[i] = elligibleForLoan[_idCode].at(i);
//         }
//     }

//     function setLender(address[] memory _lenders, bool _add) external {
//         require(msg.sender == devaddr_, "Only dev!");
//         for (uint i = 0; i < _lenders.length; i++) {
//             isLender[_lenders[i]] = _add;
//         }
//     }

//     function addIdentityProof(
//         address _user,
//         string memory _valueName, //age, agebt, agelt...
//         string memory _value,
//         uint _expirationDate,
//         address _auditorGauge,
//         address _toDelete // in case of stolen wallet
//     ) external {
//         require(msg.sender == devaddr_, "Only dev");
//         require(isGauge[_auditorGauge], "Invalid auditor");

//         identityProofs[_user][_valueName] = SSID({
//             value: _value,
//             expirationDate: block.timestamp + _expirationDate,
//             auditorGauge: _auditorGauge
//         });
//         if (keccak256(abi.encodePacked(_valueName)) == keccak256(abi.encodePacked("ssid"))) {
//             if (ssids[_value] == _toDelete) delete ssids[_value];
//             require(ssids[_value] == address(0), "SSID already created");
//             ssids[_value] = _user;
//         }
//         if (_toDelete != address(0)) {
//             delete identityProofs[_toDelete][_valueName];
//         }
//     }

//     function updateDev(address _newDev) external {
//         require(msg.sender == devaddr_, "Only dev");
//         devaddr_ = _newDev;
//     }

//     function mintBadgeFromIdentityProofs(string memory _valueName) external {
//         require(badgeNFT != address(0), "Badge NFT not yet set");
//         require(identityProofs[msg.sender][_valueName].auditorGauge != address(0), "Invalid");
//         (,string memory _value, address _gauge) = getIdentityValue(msg.sender, _valueName);
//         string memory _ratingString = string(abi.encodePacked(_valueName, _value));
//         string memory _ratingDescription = string(abi.encodePacked(
//             "Identity Proof from ",
//             ISuperLikeGauge(_gauge).cancan_email(),
//             _gauge
//         ));
//         IBadgeNFT(badgeNFT).batchMint(
//             msg.sender,
//             _gauge, // used to figure badge's color
//             1,
//             0,
//             _ratingString,
//             _ratingDescription
//         );
//     }

//     function mintBadge(
//         address _to, 
//         int256 _rating,
//         string memory _ratingString,
//         string memory _ratingDescription
//     ) external {
//         require(isGauge[msg.sender], "SuperLikeGaugeFactory: Not a gauge");
//         require(badgeNFT != address(0), "Badge NFT not yet set");
//         IBadgeNFT(badgeNFT).batchMint(
//             _to, 
//             msg.sender,      // used to figure badge's color
//             1,
//             _rating,
//             _ratingString,
//             _ratingDescription
//         );
//     }

//     function safeTransferFrom(
//         address _from,
//         address _to,
//         uint _tokenId
//     ) external {
//         require(isGauge[msg.sender] || marketPlaces[msg.sender], "SuperLikeGaugeFactory: Not a gauge");
//         (,address _gauge) = IBadgeNFT(badgeNFT).getTicketAuditor(_tokenId); 
//         require(_gauge == msg.sender, "SL Gauge: Only auditor");
//         IERC1155(badgeNFT).safeTransferFrom(
//             _from,
//             _to,
//             _tokenId,
//             1,
//             msg.data
//         );
//     }

//     function updateGaugeEmail(string memory _oldEmail, string memory _newEmail) external {
//         require(isGauge[msg.sender], "Only SL gauge!");
//         delete gaugeEmails[_oldEmail];
//         gaugeEmails[_newEmail] = ISuperLikeGauge(msg.sender).devaddr_();
//     }

//     function createGauge(
//         address _user,
//         address _ve, 
//         uint _referrerTokenId, 
//         uint _tokenId
//     ) external returns (address) {
//         require(_tokenId != _referrerTokenId, "Invalid referrer tokenId");
//         last_gauge = address(new SuperLikeGauge(
//             _ve, 
//             _tokenId, 
//             msg.sender,
//             _user
//         ));
//         gauges.push(last_gauge);
//         isGauge[last_gauge] = true;
//         userGauge[_user] = last_gauge;
//         referrers[_user] = _referrerTokenId;
//         return last_gauge;
//     }
    
//     function createGaugeSingle(
//         address _ve, 
//         uint _tokenId,
//         uint _referrerTokenId, 
//         address _voter
//     ) external returns (address) {
//         require(_tokenId != _referrerTokenId || _referrerTokenId == 0, 
//         "Invalid referrer tokenId"
//         );
//         last_gauge = address(new SuperLikeGauge(
//             _ve, 
//             _tokenId, 
//             _voter,
//             msg.sender
//         ));
//         gauges.push(last_gauge);
//         isGauge[last_gauge] = true;
//         userGauge[msg.sender] = last_gauge;
//         referrers[msg.sender] = _referrerTokenId;
//         return last_gauge;
//     }

//     function removeGauge(address _gauge) external onlyOwner {
//         isGauge[_gauge] = false;
//     }
    
// }

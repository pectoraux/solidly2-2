// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.17;

// import "./InvoiceNFT.sol";

// // Gauges are used to incentivize pools, they emit reward tokens over 7 days for staked LP tokens
// contract Inheritance is Auth
//  {
//     using EnumerableSet for EnumerableSet.AddressSet;
//     using EnumerableSet for EnumerableSet.UintSet;

//     struct Inheritance {
//         address from;
//         bool erc721;
//         uint tokenId;
//         address token;
//         uint percent;
//     }
//     mapping(address => EnumerableSet.UintSet) private myFTHeirs;
//     mapping(address => EnumerableSet.UintSet) private myNFTHeirs;
//     mapping(string => Inheritance[]) public myHeirsFTInheritance;
//     mapping(string => Inheritance[]) public myHeirsNFTInheritance;
//     mapping(address => uint) public timeLock;
//     uint public minB4InheritanceWithdrawal = 86400 * 7;
//     mapping(address => uint) public withdrawals;

//     event WithdrawInheritance(address indexed from, string indexed ssid, uint time);
//     event AddHeirsFungibleTokens(address indexed from, address indexed token, uint time);
//     event AddHeirsNonFungibleTokens(address indexed from, address indexed token, uint time);
//     event RemoveHeirsFungibleTokens(address indexed from, address indexed token, uint time);
//     event RemoveHeirsNonFungibleTokens(address indexed from, address indexed token, uint time);

//     constructor(
//         address _devaddr,
//         address _helper,
//         address _superLikeGaugeFactory
//     ) Auth(_helper, _devaddr, _superLikeGaugeFactory)
//     {

//     }

//     // simple re-entrancy check
//     uint internal _unlocked = 1;
//     modifier lock() {
//         require(_unlocked == 1);
//         _unlocked = 2;
//         _;
//         _unlocked = 1;
//     }

//     function addHeirsFungibleTokens(
//         address _from,
//         address _token,
//         string[] memory _heirSSIDs, //["sdt", "adgh"]
//         uint[] memory _percents     //["1000", 9000]
//     ) external onlyMinCosigners(msg.sender, 0) {
//         require(_heirSSIDs.length == _percents.length, "Uneven lists");
//         require(IARPHelper(helper)._sumArr(_percents) == 10000, "Percents not adding up to 100");
//         require(IERC20(_token).allowance(_from, address(this)) == 
//                 IERC20(_token).balanceOf(_from), "Access not granted to Inheritance contract");
//         require(myFTHeirs[_token].length() == 0, "Token already added");

//         for (uint i = 0; i < _heirSSIDs.length; i++) {
//             myFTHeirs[_token].add(uint(keccak256(abi.encodePacked(_heirSSIDs[i]))));
//             myHeirsFTInheritance[_heirSSIDs[i]].push(Inheritance({
//                 from: _from,
//                 erc721: false,
//                 tokenId: 0,
//                 token: _token,
//                 percent: _percents[i]
//             }));
//         }
//         emit AddHeirsFungibleTokens(msg.sender, _token, block.timestamp);
//     } 

//     function addHeirsNonFungibleTokens(
//         bool _erc721,
//         uint _tokenId,
//         address _from,
//         address _token,
//         string[] memory _heirSSIDs, //["sdt", "adgh"]
//         uint[] memory _percents     //["1000", 9000]
//     ) external onlyMinCosigners(msg.sender, 0) {
//         require(_heirSSIDs.length == _percents.length, "Uneven lists");
//         require(IARPHelper(helper)._sumArr(_percents) == 10000, "Percents not adding up to 100");
//         require(IERC721(_token).isApprovedForAll(_from, address(this)),
//         "Access not granted to Inheritance contract");
//         require(myNFTHeirs[_token].length() == 0, "Token already added");

//         for (uint i = 0; i < _heirSSIDs.length; i++) {
//             myNFTHeirs[_token].add(uint(keccak256(abi.encodePacked(_heirSSIDs[i]))));
//             myHeirsNFTInheritance[_heirSSIDs[i]].push(Inheritance({
//                 from: _from,
//                 erc721: _erc721,
//                 tokenId: _tokenId,
//                 token: _token,
//                 percent: _percents[i]
//             }));
//         }
//         emit AddHeirsNonFungibleTokens(msg.sender, _token, block.timestamp);
//     }

//     function isEligibleForFTInheritanceAt(string memory _ssid, uint _idx) public view returns(bool) {
//         return (
//             myHeirsFTInheritance[_ssid][_idx].percent > 0 &&
//             myFTHeirs[myHeirsFTInheritance[_ssid][_idx].token]
//             .contains(uint(keccak256(abi.encodePacked(_ssid))))
//         );
//     }

//     function isEligibleForNFTInheritanceAt(string memory _ssid, uint _idx) public view returns(bool) {
//         return (
//             myHeirsNFTInheritance[_ssid][_idx].percent > 0 &&
//             myFTHeirs[myHeirsNFTInheritance[_ssid][_idx].token]
//             .contains(uint(keccak256(abi.encodePacked(_ssid))))
//         );
//     }

//     function removeHeirsFungibleTokens(address _token) external onlyMinCosigners(msg.sender, 0) {
//         delete myFTHeirs[_token];
//         emit RemoveHeirsFungibleTokens(msg.sender, _token, block.timestamp);
//     }

//     function removeHeirsNonFungibleTokens(address _token) external onlyMinCosigners(msg.sender, 0) {
//         delete myNFTHeirs[_token];
//         emit RemoveHeirsNonFungibleTokens(msg.sender, _token, block.timestamp);
//     }

//     function getAllFTInheritance(string memory _ssid) public view
//     returns(Inheritance[] memory inheritances) 
//     {
//         inheritances = new Inheritance[](myHeirsFTInheritance[_ssid].length);
//         uint j;
//         for (uint i = 0; i < myHeirsFTInheritance[_ssid].length; i++) {
//             if (isEligibleForFTInheritanceAt(_ssid, i)) {
//                 inheritances[j++] = myHeirsFTInheritance[_ssid][i];
//             }
//         }
//     }

//     function getAllNFTInheritance(string memory _ssid) public view
//     returns(Inheritance[] memory inheritances) 
//     {
//         inheritances = new Inheritance[](myHeirsNFTInheritance[_ssid].length);
//         uint j;
//         for (uint i = 0; i < myHeirsNFTInheritance[_ssid].length; i++) {
//             if(isEligibleForNFTInheritanceAt(_ssid, i)){
//                 inheritances[j++] = myHeirsNFTInheritance[_ssid][i];
//             }
//         }
//     }

//     function withdrawInheritance(string memory _ssid, uint _tokenId) external {
//         address _owner = msg.sender;
//         if (_tokenId > 0) {
//             _owner = notes[_tokenId].heir;
//             _ssid = notes[_tokenId].heirSSID;
//         }
//         checkIdentityProof(_owner, true);
//         userToIdentityCode[_owner] = keccak256(abi.encodePacked(_ssid));
//         if (timeLock[_owner] == 0) {
//             timeLock[_owner] = block.timestamp + minB4InheritanceWithdrawal;
//         } else if (timeLock[_owner] < block.timestamp) {
//             delete timeLock[_owner];
//             Inheritance[] memory _ftInheritances = getAllFTInheritance(_ssid);
//             Inheritance[] memory _nftInheritances = getAllNFTInheritance(_ssid);
//             for (uint i = 0; i < _ftInheritances.length; i++) {
//                 _withdrawFTInheritance(_ftInheritances[i]);
//             } 
//             for (uint i = 0; i < _nftInheritances.length; i++) {
//                 _withdrawNFTInheritance(_nftInheritances[i]);
//             }
//         }

//         emit WithdrawInheritance(_owner, _ssid, block.timestamp);
//     }

//     function _withdrawFTInheritance(Inheritance memory _inheritance) internal {
//         uint _balanceOf = IERC20(_inheritance.token).balanceOf(devaddr_) + withdrawals[_inheritance.token];
//         uint _amount = _balanceOf * _inheritance.percent / 10000;
//         uint _tradingFee = _amount * IARPHelper(helper).tradingFee() / 10000;
//         _safeTransferFrom(
//             _inheritance.token, 
//             _inheritance.from, 
//             msg.sender,
//             _amount - _tradingFee
//         );
//         _safeTransferFrom(
//             _inheritance.token, 
//             _inheritance.from, 
//             payswapAdmin,
//             _tradingFee
//         );
//         withdrawals[_inheritance.token] += _amount;
//     }

//     function getAllFTInheritanceValue(string memory _ssid) public view 
//     returns(address[] memory tokens, uint[] memory dues) {
//         Inheritance[] memory inheritances = getAllFTInheritance(_ssid);
//         tokens = new address[](inheritances.length);
//         dues = new uint[](inheritances.length);
//         for (uint i = 0; i < inheritances.length; i++) {
//             uint _balanceOf = IERC20(inheritances[i].token).balanceOf(devaddr_) + withdrawals[inheritances[i].token];
//             uint _amount = _balanceOf * inheritances[i].percent / 10000;
//             tokens[i] = inheritances[i].token;
//             dues[i] = _amount;
//         }
//     }

//     function getAllNFTInheritanceValue(string memory _ssid) public view 
//     returns(address[] memory tokens, uint[] memory tokenIds, uint[] memory dues) {
//         Inheritance[] memory inheritances = getAllNFTInheritance(_ssid);
//         tokens = new address[](inheritances.length);
//         tokenIds = new uint[](inheritances.length);
//         dues = new uint[](inheritances.length);
//         for (uint i = 0; i < inheritances.length; i++) {
//             if (inheritances[i].erc721) {
//                 tokens[i] = inheritances[i].token;
//                 tokenIds[i] = inheritances[i].tokenId;
//                 dues[i] = 1;
//             } else {
//                 uint _balanceOf = withdrawals[inheritances[i].token] + 
//                                 IERC1155(inheritances[i].token).balanceOf(devaddr_, inheritances[i].tokenId);
//                 uint _amount = _balanceOf * inheritances[i].percent / 10000;
//                 tokens[i] = inheritances[i].token;
//                 tokenIds[i] = inheritances[i].tokenId;
//                 dues[i] = _amount;
//             }
//         }
//     }

//     function _withdrawNFTInheritance(Inheritance memory _inheritance) internal {
//         if (_inheritance.erc721) {
//             IERC721(_inheritance.token).safeTransferFrom(
//                 _inheritance.from, 
//                 msg.sender,
//                 _inheritance.tokenId
//             );
//         } else {
//             uint _balanceOf = withdrawals[_inheritance.token] + 
//                               IERC1155(_inheritance.token).balanceOf(devaddr_, _inheritance.tokenId);
//             uint _amount = _balanceOf * _inheritance.percent / 10000;
//             IERC1155(_inheritance.token).safeTransferFrom(
//                 _inheritance.from, 
//                 msg.sender,
//                 _inheritance.tokenId,
//                 _amount,
//                 msg.data
//             );
//             withdrawals[_inheritance.token] += _amount;
//         }
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
// }

// contract InheritanceNote is ERC721Pausable {
//     using EnumerableSet for EnumerableSet.AddressSet;

//     EnumerableSet.AddressSet private gauges;
//     address public devaddr_;
//     address public trustBounty;
//     address public profile;
//     struct Note {
//         address heir;
//         string heirSSID;
//     }
//     mapping(address => mapping(uint => Note)) public notes;
//     mapping(address => mapping(address => uint)) public adminNotes;
//     mapping(address => mapping(uint => uint)) public pendingRevenueFromNote;
//     mapping(address => mapping(uint => uint)) private protocolNotes;
//     uint public tokenId = 1;
//     uint public tradingFee;
//     address private factory;
//     address private superLikeGaugeFactory;
//     mapping(address => address) fts_;

//     constructor(address _superLikeGaugeFactory) ERC721("ARPNote", "nARP")  {
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

//     function setFactory(address _factory) external {
//          require(msg.sender == devaddr_);
//          factory = _factory;
//     }

//     function updateDev(address _devaddr) external {
//         require(msg.sender == devaddr_);
//         devaddr_ = _devaddr;
//     }

//     function mintInheritanceNote(address _inheritance, address _to, string memory _ssid) external {
//         (
//             string memory ssid,, 
//         ) = ISuperLikeGaugeFactory(superLikeGaugeFactory).getIdentityValue(msg.sender, "ssid");
//         require(IInheritance(_inheritance).isEligibleForFTInheritanceAt(_ssid, 0));
//         notes[_inheritance][tokenId] = Note({
//             heir: msg.sender,
//             heirSSID: _ssid
//         });
//         _safeMint(_to, tokenId++, msg.data);
//     }

//     function getAllInheritances() external view returns(address[] memory inheritances) {
//         inheritances = new address[](gauges.length());
//         for (uint i = 0; i < gauges.length(); i++) {
//             inheritances[i] = gauges.at(i);
//         }    
//     }

//     function updateGauge(address _last_gauge) external {
//         require(msg.sender == factory);
//         gauges.add(_last_gauge);
//     }

//     function deleteInheritance(address _inheritance) external {
//         require(msg.sender == devaddr_ || IARP(_inheritance).devaddr_() == msg.sender);
//         gauges.remove(_inheritance);
//     }

//     function tokenURI(uint _tokenId) public override view returns (string memory output) {
//         output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
//         output = string(abi.encodePacked(output, "Contract address: ", address(this), '</text><text x="10" y="40" class="base">'));
//         output = string(abi.encodePacked(output, "Owner ", ownerOf(_tokenId), '</text></svg>'));
//         output = string(abi.encodePacked(output, "Heir ", notes[_tokenId].heir, '</text></svg>'));
//         output = string(abi.encodePacked(output, "Heir SSID", notes[_tokenId].heirSSID, '</text></svg>'));
//         (address[] memory tokens, uint[] memory dues) = getAllFTInheritanceValue(notes[_tokenId].heirSSID);
//         output = string(abi.encodePacked(output, "List of Fungibles: " '</text></svg>'));
//         for (uint i = 0; i < tokens.length; i++) {
//             output = string(abi.encodePacked(output, "Token: ", tokens[i], ", Due: ", dues[i], '</text></svg>'));
//         }
//         (address[] memory tokens2, uint[] memory tokenIds, uint[] memory dues2)
//         = getAllNFTInheritanceValue(notes[_tokenId].heirSSID);
//         output = string(abi.encodePacked(output, "List of Non Fungibles: " '</text></svg>'));
//         for (uint i = 0; i < tokens2.length; i++) {
//             output = string(abi.encodePacked(output, "Token: ", tokens2[i], ", TokenId: ", tokenIds[i],", Due: ", dues2[i], '</text></svg>'));
//         }
//         string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": " Inheritance: note #', toString(_tokenId), '", "description": "This is a note granting access to the following inheritances.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
//         output = string(abi.encodePacked('data:application/json;base64,', json));
//     }

//     function updateTradingFee(uint _tradingFee) external {
//         require(msg.sender == devaddr_);
//         tradingFee = _tradingFee;
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

//     function _sumArr(uint[] memory _arr) public pure returns(uint total) {
//         for (uint i = 0; i < _arr.length; i++) {
//             total += _arr[i];
//         }
//     }

// }

// contract InheritanceFactory {
//     address private superLikeGaugeFactory;
//     address private helper;

//     constructor(
//         address _helper, 
//         address _superLikeGaugeFactory
//     ) {
//         helper = _helper;
//         superLikeGaugeFactory = _superLikeGaugeFactory;
//     }

//     function createGauge(address _devaddr) external {
//         address last_gauge = address(new Inheritance(
//             _devaddr,
//             helper,
//             superLikeGaugeFactory
//         ));
//         IARPHelper(helper).updateGauge(last_gauge);
//     }
// }
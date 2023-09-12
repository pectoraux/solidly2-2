// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import './Library.sol';

contract SSI is Ownable, ERC721Pausable {
    using EnumerableSet for EnumerableSet.UintSet;
    struct Account {
        string publicKey;
        string encryptedPrivateKey;
    }
    uint constant SSID_CATEGORY = 1;
    COLOR public minBadgeColor = COLOR.SILVER;
    address public contractAddress;
    uint public tokenId = 1;
    string public idValueName = "ssid";
    mapping(uint => SSIData) public metadata;
    mapping(uint => Account) public profileToAccount;
    mapping(uint => uint) private ssid;
    mapping(uint => EnumerableSet.UintSet) private _authorizations;
    
    event DataCreated(
        uint indexed profileId, 
        uint auditorProfileId,
        address owner,
        address auditor, 
        uint startTime, 
        uint endTime,
        string question,
        string answer,
        string dataType,
        bool searchable
    );
    event CreateAccount(uint indexed profileId, address owner, string publicKey, string encyptedPrivateKey);
    event ActivateData(uint indexed profileId, uint auditorProfileId, string question, string answer);
    event ValidateData(uint indexed profileId, string question);
    event DataDeleted(uint indexed profileId, string question);
    event GenerateShareProof(
        address owner, 
        uint tokenId, 
        uint senderProfileId, 
        uint receiverProfileId, 
        uint auditorProfileId,
        uint deadline,
        string question,
        string encryptedAnswer
    );
    event GenerateIdentityProof(
        address owner, 
        uint tokenId, 
        uint senderProfileId, 
        uint auditorProfileId,
        uint deadline,
        string question,
        string encryptedAnswer
    );
    event UpdateMiscellaneous(
        uint idx, 
        uint collectionId, 
        string paramName, 
        string paramValue, 
        uint paramValue2, 
        uint paramValue3, 
        address sender,
        address paramValue4,
        string paramValue5
    );

    constructor() ERC721("NFT Proof", "NFTProof") {}

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender, "SSI1");
        contractAddress = _contractAddress;
    }

    function getSSIData(uint _tokenId) external view returns(SSIData memory) {
        return metadata[_tokenId];
    }
    
    function updateParams(COLOR _minBadgeColor) external {
        require(IAuth(contractAddress).devaddr_() == msg.sender, "SSI1");
        minBadgeColor = _minBadgeColor;
    }

    function emitUpdateMiscellaneous(
        uint _idx, 
        uint _collectionId, 
        string memory paramName, 
        string memory paramValue, 
        uint paramValue2, 
        uint paramValue3,
        address paramValue4,
        string memory paramValue5
    ) external {
        emit UpdateMiscellaneous(
            _idx, 
            _collectionId, 
            paramName, 
            paramValue, 
            paramValue2, 
            paramValue3, 
            msg.sender,
            paramValue4,
            paramValue5
        );
    }

    function updateId(string memory _idValueName) external {
        require(IAuth(contractAddress).devaddr_() == msg.sender);
        idValueName = _idValueName;
    }

    function verifyNFT(uint tokenId, uint merchantId, string memory item) external view returns(uint) {
        if(metadata[tokenId].proofType == ProofType.shareProof &&
           (metadata[tokenId].auditorProfileId == 1 ||
            _authorizations[merchantId].contains(metadata[tokenId].auditorProfileId)) &&
            keccak256(abi.encodePacked(item)) == keccak256(abi.encodePacked(metadata[tokenId].question))
        ) {
            return 1;
        }
        return 0;
    }
    
    function createAccount(
        uint profileId,
        string memory publicKey,
        string memory encryptedPrivateKey
    ) external {
        require(IProfile(_profile()).addressToProfileId(msg.sender) == profileId && profileId > 0, "SSI2");

        profileToAccount[profileId].publicKey = publicKey;
        profileToAccount[profileId].encryptedPrivateKey = encryptedPrivateKey;

        emit CreateAccount(
            profileId,
            msg.sender,
            publicKey,
            encryptedPrivateKey
        );
    }

    function createData(
        uint profileId,
        uint auditorProfileId,
        address owner,
        address auditor, 
        uint startTime, 
        uint endTime,
        bool searchable,
        string memory question,
        string memory answer,
        string memory dataType
    ) external {
        require(IProfile(_profile()).addressToProfileId(msg.sender) == auditorProfileId && auditorProfileId > 0, "SSI3");
        emit DataCreated(
            profileId, 
            auditorProfileId,
            owner,
            auditor, 
            startTime, 
            endTime,
            question,
            answer,
            dataType,
            searchable
        );
    }

    function activateData(uint profileId, uint _auditorProfileId, string memory question, string memory answer) external {
        require(msg.sender == IAuth(contractAddress).devaddr_() || 
            (IProfile(_profile()).addressToProfileId(msg.sender) == _auditorProfileId && _auditorProfileId > 0),
            "SSI4"
        );
        emit ActivateData(profileId, _auditorProfileId, question, answer);
    }
    
    function deleteData(uint profileId, string memory question) external {
        require(IProfile(_profile()).addressToProfileId(msg.sender) == profileId && profileId > 0, "SSI5");
        emit DataDeleted(profileId, question);
    }

    function updateAuthorization(uint profileId, uint _auditorProfileId, bool _add) external {
        require(IProfile(_profile()).addressToProfileId(msg.sender) == profileId  && profileId > 0, "SSI6");
        if (_add) {
            _authorizations[profileId].add(_auditorProfileId);
        } else {
            _authorizations[profileId].remove(_auditorProfileId);
        }
    }

    function getAllAuthorizations(uint _profileId) external view returns(uint[] memory _auditors) {
        _auditors = new uint[](_authorizations[_profileId].length());
        for (uint i = 0; i < _authorizations[_profileId].length(); i++) {
            _auditors[i] = _authorizations[_profileId].at(i);
        }    
    }

    function updateSSID(uint _profileId, uint _identityTokenId) external {
        require(ownerOf(_identityTokenId) == msg.sender, "SSI7");
        require(metadata[_identityTokenId].proofType == ProofType.identityProof, "SSI07");
        require(keccak256(abi.encodePacked(metadata[_identityTokenId].question)) == keccak256(abi.encodePacked(idValueName)), "SSI8");
        // (address _auditor,, COLOR _badgeColor) = IAuditor(IContract(contractAddress).auditorNote()).getGaugeNColor(metadata[_identityTokenId].auditorProfileId);
        // require(SSID_CATEGORY == IAuditor(IContract(contractAddress).auditorHelper()).categories(_auditor));
        // require(_badgeColor >= minBadgeColor);
        ssid[_profileId] = _identityTokenId;
    }

    function getSSID(uint _profileId) external view returns(SSIData memory) {
        require(ssid[_profileId] > 0, "SSI08");
        return metadata[ssid[_profileId]];
    }

    function validateData(uint profileId, string memory question) external {
        require(IProfile(_profile()).addressToProfileId(msg.sender) == profileId && profileId > 0, "SSI9");
        emit ValidateData(profileId, question);
    }
    
    function _profile() internal view returns(address) {
        return IContract(contractAddress).profile();
    }

    function generateShareProof(
        address _sender,
        uint _senderProfileId, 
        uint _receiverProfileId,
        uint _auditorProfileId,
        uint _deadline,
        string memory _question,
        string memory _encryptedAnswer
    ) external {
        address profile = _profile();
        require(_authorizations[_senderProfileId].contains(_auditorProfileId) || _auditorProfileId == 1, "SSI10");
        require(msg.sender == IAuth(contractAddress).devaddr_() || 
            (IProfile(profile).addressToProfileId(msg.sender) == _auditorProfileId  && _auditorProfileId > 0), 
            "SSI11"
        );
        require(IProfile(profile).addressToProfileId(_sender) == _senderProfileId  && _senderProfileId > 0, "SSI12");
        metadata[tokenId] = SSIData({
            senderProfileId: _senderProfileId,
            receiverProfileId: _receiverProfileId,
            auditorProfileId: _auditorProfileId,
            deadline: block.timestamp + _deadline,
            question: _question,
            answer: _encryptedAnswer,
            proofType: ProofType.shareProof
        });
        emit GenerateShareProof(
            _sender, 
            tokenId, 
            _senderProfileId, 
            _receiverProfileId, 
            _auditorProfileId,
            block.timestamp + _deadline,
            _question,
            _encryptedAnswer
        );
        _safeMint(_sender, tokenId++, msg.data);
    }
    
    function burn(uint _tokenId) external {
        _burn(_tokenId);
    }

    function generateIdentityProof(
        address _sender,
        uint _senderProfileId,
        uint _auditorProfileId,
        uint _deadline,
        string memory _question,
        string memory _answer
    ) external {
        require(_auditorProfileId == 1 || _authorizations[_senderProfileId].contains(_auditorProfileId), "SSI13");
        require(msg.sender == IAuth(contractAddress).devaddr_() || 
            (IProfile(_profile()).addressToProfileId(msg.sender) == _auditorProfileId  && _auditorProfileId > 0), 
            "SSI14"
        );
        require(IProfile(_profile()).addressToProfileId(_sender) == _senderProfileId  && _senderProfileId > 0, "SSI15");
        metadata[tokenId] = SSIData({
            senderProfileId: _senderProfileId,
            receiverProfileId: 0,
            auditorProfileId: _auditorProfileId,
            deadline: block.timestamp + _deadline,
            question: _question,
            answer: _answer,
            proofType: ProofType.identityProof
        });
        _safeMint(_sender, tokenId, msg.data);
        
        emit GenerateIdentityProof(
            _sender, 
            tokenId++, 
            _senderProfileId, 
            _auditorProfileId, 
            block.timestamp + _deadline,
            _question,
            _answer
        );
    }

    function tokenURI(uint _tokenId) public override view returns (string memory output) {
        output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
        output = string(abi.encodePacked(output, "Contract address: ", address(this), '</text><text x="10" y="40" class="base">'));
        output = string(abi.encodePacked(output, "Amount due: ", 
        // toString(notes[_tokenId].due), 
        '</text><text x="10" y="60" class="base">'));
        output = string(abi.encodePacked(output, "Time due ", 
        // toString(notes[_tokenId].timer), 
        '</text><text x="10" y="80" class="base">'));
        output = string(abi.encodePacked(output, "Owner ", 
        // notes[_tokenId].protocol, 
        '</text></svg>'));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "SponsorCard note #', toString(_tokenId), '", "description": "This card gives you access to amount due by the owner at date mentioned below.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
    }

    function toString(uint value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
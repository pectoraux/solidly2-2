// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Library.sol";

// Gauges are used to incentivize pools, they emit reward tokens over 7 days for staked LP tokens
contract Sponsor {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    
    address public _ve;
    bool public bountyRequired;
    uint public lastProtocolId = 1;
    address public devaddr_;
    address private helper;
    address public contractAddress;
    uint public collectionId;
    uint public maxNotesPerProtocol = 1;
    mapping(address => bool) public isAdmin;
    EnumerableSet.UintSet private contents;
    mapping(uint => uint) public pendingFromNote;
    mapping(uint => CardInfo) public protocolInfo;
    mapping(address => uint) public adminBountyIds;
    mapping(address => uint) public totalProcessed;
    mapping(address => uint) public addressToProtocolId;
    
    constructor(
        address _devaddr,
        address _helper,
        address _contractAddress
    ) {
        collectionId = IMarketPlace(IContract(_contractAddress).marketCollections())
        .addressToCollectionId(_devaddr);
        require(collectionId > 0, "S01");
        helper = _helper;
        devaddr_ = _devaddr;
        isAdmin[devaddr_] = true;
        contractAddress = _contractAddress;
    }

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

     modifier onlyAdmin() {
        require(isAdmin[msg.sender]);
        _;
    }

    modifier onlyDev() {
        require(devaddr_ == msg.sender || 
        collectionId == IMarketPlace(IContract(contractAddress).marketCollections())
        .addressToCollectionId(msg.sender));
        _;
    }

     function updateDev(address _devaddr) external onlyDev {
        devaddr_ = _devaddr;
    }

    function updateAdmin(address _admin, bool _add) external onlyDev {
        isAdmin[_admin] = _add;
    }

    function updateDevFromCollectionId(address _devaddr) external {
        require(collectionId == IMarketPlace(IContract(contractAddress).marketCollections())
        .addressToCollectionId(msg.sender));
        devaddr_ = _devaddr;
    }

    function updateParameters(
        bool _bountyRequired,
        address __ve,
        uint _maxNotesPerProtocol
    ) external onlyAdmin {
        _ve = __ve;
        bountyRequired = _bountyRequired;
        maxNotesPerProtocol = _maxNotesPerProtocol;
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || helper == msg.sender);
        contractAddress = _contractAddress;
        helper = IContract(_contractAddress).paywallARPHelper();
    }

    function protocolInfoCard(uint _protocolId) external view returns(CardInfo memory) {
        return protocolInfo[_protocolId];
    }

   function updateContents(string memory _contentName, bool _add) external {
       if (_add) {
           require(IContract(contractAddress).contains(_contentName), "S1");
           contents.add(uint(keccak256(abi.encodePacked(_contentName))));
       } else {
           contents.remove(uint(keccak256(abi.encodePacked(_contentName))));
       }
        ISponsor(helper).emitUpdateContents(_contentName, _add);
   }
    
   function getAllContents(uint _start) external view returns(string[] memory _content) {
        _content = new string[](contents.length() - _start);
        for (uint i = _start; i < contents.length(); i++) {
            _content[i] = IContent(contractAddress).indexToName(contents.at(i));
        }    
    }

   function contentContainsAny(string[] memory _excluded) external view returns(bool) {
       for(uint i = 0; i < _excluded.length; i++) {
           if (contents.contains(uint(keccak256(abi.encodePacked(_excluded[i]))))) {
               return true;
           }
       }
       return false;
   }

   function _trustBounty() internal view returns(address) {
    return IContract(contractAddress).trustBounty();
   }

    function updateBounty(uint _bountyId) external {
        address trustBounty = _trustBounty();
        (address owner,address _token,,address claimableBy,,,,,,) = 
        ITrustBounty(trustBounty).bountyInfo(_bountyId);
        if (isAdmin[msg.sender]) {
            require(owner == msg.sender && claimableBy == address(0x0), "S2");
            if (_bountyId > 0 && adminBountyIds[_token] == 0) {
                ISponsor(helper).attach(_bountyId);
            } else if (_bountyId == 0 && adminBountyIds[_token] > 0) {
                ISponsor(helper).detach(_bountyId);
            }
            adminBountyIds[_token] = _bountyId;
        } else {
            require(owner == msg.sender && 
                _token == protocolInfo[addressToProtocolId[msg.sender]].token && 
                claimableBy == devaddr_,
                "S3"
            );
            require(protocolInfo[addressToProtocolId[msg.sender]].bountyId == 0, "S4");
            protocolInfo[addressToProtocolId[msg.sender]].bountyId = _bountyId;
        }
    }

    function updateTokenId(uint _tokenId) external {
        require(ve(_ve).ownerOf(_tokenId) == msg.sender, "S5");
        protocolInfo[addressToProtocolId[msg.sender]].tokenId = _tokenId;
    }

    function updateOwner(address _prevOwner, uint _tokenId) external {
        require(ve(_ve).ownerOf(_tokenId) == msg.sender, "S6");
        require(protocolInfo[addressToProtocolId[_prevOwner]].tokenId == _tokenId, "S7");
        protocolInfo[addressToProtocolId[_prevOwner]].owner = msg.sender;
        addressToProtocolId[msg.sender] = addressToProtocolId[_prevOwner];
        delete addressToProtocolId[_prevOwner];
    }
    
    function updatePaidPayable(address _owner, uint _num) external {
        if(msg.sender == helper) {
            protocolInfo[addressToProtocolId[_owner]].paidPayable += _num;
            pendingFromNote[addressToProtocolId[_owner]] += _num;
        }
    }

    function depositDue(address _protocol) external lock {
        (uint duePayable,,) = ISponsor(helper).getDuePayable(address(this), _protocol, 0);
        duePayable += pendingFromNote[addressToProtocolId[_protocol]];
        IERC20(protocolInfo[addressToProtocolId[_protocol]].token)
        .safeTransferFrom(msg.sender, address(this), duePayable);
        pendingFromNote[addressToProtocolId[_protocol]] = 0;
    }

    function payInvoicePayable(address _protocol) external lock returns(uint) {
        require(
            _protocol == msg.sender || devaddr_ == msg.sender,
            "S8"
        );
        (uint duePayable,,) = ISponsor(helper).getDuePayable(address(this), _protocol, 0);
        address token = protocolInfo[addressToProtocolId[_protocol]].token;
        uint _bounty = ITrustBounty(_trustBounty()).getBalance(adminBountyIds[token]);
        require(_bounty >= ISponsor(helper).minBountyPercent() * totalProcessed[token] / 10000, "S9");
        uint _balanceOf = erc20(token).balanceOf(address(this));
        uint _toPay = _balanceOf < duePayable ? _balanceOf : duePayable;
        protocolInfo[addressToProtocolId[_protocol]].paidPayable += _toPay;
        require(_toPay > 0, "S10");
        uint payswapFees = _toPay * ISponsor(helper).tradingFee() / 10000;
        _toPay -= payswapFees;
        totalProcessed[token] += _toPay;
        IERC20(token).safeTransfer(helper, payswapFees);
        IERC20(token).safeTransfer(_protocol, _toPay);
        ISponsor(helper).emitPayInvoicePayable(
            addressToProtocolId[_protocol], 
            protocolInfo[addressToProtocolId[_protocol]].paidPayable
        );
        return _balanceOf < duePayable ? _balanceOf : duePayable;
    }

    function _checkIdentityProof(address _owner, uint _identityTokenId) internal {
        if (collectionId > 0) {
            IMarketPlace(IContract(contractAddress).marketHelpers2())
            .checkUserIdentityProof(collectionId, _identityTokenId, _owner);
        }
    }

    function updateProtocol(
        address _owner,
        address _token,
        uint _amountPayable,
        uint _periodPayable,
        uint _startPayable,
        uint _identityTokenId,
        uint _protocolId,
        string memory _media,
        string memory _description
    ) external onlyAdmin {
        require(addressToProtocolId[_owner] == 0);
        _checkIdentityProof(_owner, _identityTokenId);
        _protocolId = lastProtocolId++;
        addressToProtocolId[_owner] = _protocolId;
        protocolInfo[addressToProtocolId[_owner]].startPayable = block.timestamp + _startPayable;
        protocolInfo[addressToProtocolId[_owner]].amountPayable = _amountPayable;
        protocolInfo[addressToProtocolId[_owner]].periodPayable = _periodPayable;
        protocolInfo[addressToProtocolId[_owner]].owner = _owner;
        protocolInfo[addressToProtocolId[_owner]].token = _token;
        
        ISponsor(helper).emitUpdateProtocol(
            _protocolId,
            _owner, 
            _media,
            _description
        );
    }

    function deleteProtocol (address _protocol) public onlyAdmin {
        delete protocolInfo[addressToProtocolId[_protocol]];
        ISponsor(helper).emitDeleteProtocol(addressToProtocolId[_protocol]);
        delete addressToProtocolId[_protocol];
    }

    function withdraw(address _token, uint amount) external onlyAdmin {
        IERC20(_token).safeTransfer(msg.sender, amount);
        
        ISponsor(helper).emitWithdraw(msg.sender, amount);
    }

    function noteWithdraw(address _to, address _protocol, uint amount) external {
        require(msg.sender == helper, "S11");
        IERC20(protocolInfo[addressToProtocolId[_protocol]].token)
        .safeTransfer(_to, amount);
    }
}

contract SponsorNote is ERC721Pausable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct SponsorShipNote {
        uint due;
        uint timer;
        uint tokenId;
        uint protocolId;
        address token;
        address protocol;
    }
    EnumerableSet.AddressSet private gauges;
    mapping(address => uint) public treasuryFees;
    mapping(uint => SponsorShipNote) public notes;
    uint public tokenId = 1;
    uint public tradingFee = 100;
    uint public minBountyPercent = 100;
    uint private sum_of_diff_squared;
    EnumerableSet.UintSet private _allVoters;
    mapping(address => uint) public percentiles;
    struct Vote {
        uint likes;
        uint dislikes;
    }
    mapping(uint => address) public profiles;
    mapping(address => Vote) public  votes;
    mapping(uint => mapping(address => int)) public voted;
    mapping(address => mapping(uint => uint)) private protocolNotes;
    address public contractAddress;

    event Voted(address indexed sponsor, uint profileId, uint likes, uint dislikes, bool like);
    event UpdateProtocol(
        uint indexed protocolId,
        address sponsor,
        address owner,
        string media,
        string description
    );
    event PayInvoicePayable(uint indexed protocolId, address sponsor, uint paidPayable);
    event UpdateContents(address sponsor, string contentName, bool add);
    event DeleteProtocol(uint indexed protocolId, address sponsor);
    event DeleteSponsor(address indexed sponsor);
    event Withdraw(address indexed from, address sponsor, uint amount);
    event CreateSponsorship(address indexed sponsor, address user, uint profileId);
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
    
    constructor() ERC721("SponsorNote", "nSponsor")  {}

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function getAllSponsors(uint _start) external view returns(address[] memory sponsors) {
        sponsors = new address[](gauges.length() - _start);
        for (uint i = _start; i < gauges.length(); i++) {
            sponsors[i] = gauges.at(i);
        }    
    }

    function isGauge(address _sponsor) external view returns(bool) {
        return gauges.contains(_sponsor);
    }

    function _profile() internal view returns(address) {
        return IContract(contractAddress).profile();
    }

    function _ssi() internal view returns(address) {
        return IContract(contractAddress).ssi();
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

    function updateGauge(
        address _last_gauge,
        address _user, 
        uint _profileId
    ) external {
        require(msg.sender == IContract(contractAddress).sponsorFactory(), "SN1");
        require(IProfile(_profile()).addressToProfileId(_user) == _profileId, "SN2");
        gauges.add(_last_gauge);
        profiles[_profileId] = _last_gauge;
        emit CreateSponsorship(_last_gauge, _user, _profileId);
    }

    function attach(uint _bountyId) external {
        require(gauges.contains(msg.sender), "SN07");
        ITrustBounty(IContract(contractAddress).trustBountyHelper()).attach(_bountyId);
    }

    function detach(uint _bountyId) external {
        require(gauges.contains(msg.sender), "SN08");
        ITrustBounty(IContract(contractAddress).trustBountyHelper()).detach(_bountyId);
    }

    function updateMinBountyPercent(uint _minBountyPercent) external {
        require(msg.sender == IAuth(contractAddress).devaddr_(), "SN3");
        minBountyPercent = _minBountyPercent;
    }

    function deleteSponsor(address _sponsor) external {
        require(msg.sender == IAuth(contractAddress).devaddr_() || IAuth(_sponsor).isAdmin(msg.sender), "SN4");
        gauges.remove(_sponsor);
        emit DeleteSponsor(_sponsor);
    }

    function _resetVote(address _sponsor, uint profileId) internal {
        if (voted[profileId][_sponsor] > 0) {
            votes[_sponsor].likes -= 1;
        } else if (voted[profileId][_sponsor] < 0) {
            votes[_sponsor].dislikes -= 1;
        }
    }
    
    function vote(address _sponsor, uint profileId, bool like) external {
        require(IProfile(_profile()).addressToProfileId(msg.sender) == profileId, "SN5");
        SSIData memory metadata = ISSI(_ssi()).getSSID(profileId);
        require(keccak256(abi.encodePacked(metadata.answer)) != keccak256(abi.encodePacked("")), "SN6");
        _resetVote(_sponsor, profileId);        
        if (like) {
            votes[_sponsor].likes += 1;
            voted[profileId][_sponsor] = 1;
        } else {
            votes[_sponsor].dislikes += 1;
            voted[profileId][_sponsor] = -1;
        }
        uint _sponsorVotes;
        if (votes[_sponsor].likes > votes[_sponsor].dislikes) {
            _sponsorVotes = votes[_sponsor].likes - votes[_sponsor].dislikes;
        }
        _allVoters.add(profileId);
        (uint percentile, uint sods) = Percentile.computePercentileFromData(
            false,
            _sponsorVotes,
            _allVoters.length(),
            _allVoters.length(),
            sum_of_diff_squared
        );
        sum_of_diff_squared = sods;
        percentiles[_sponsor] = percentile;
        emit Voted(_sponsor, profileId, votes[_sponsor].likes, votes[_sponsor].dislikes, like);
    }
    
    function _getColor(uint _percentile) internal pure returns(COLOR) {
        if (_percentile > 75) {
            return COLOR.GOLD;
        } else if (_percentile > 50) {
            return COLOR.SILVER;
        } else if (_percentile > 25) {
            return COLOR.BROWN;
        } else {
            return COLOR.BLACK;
        }
    }

    function getGaugeNColor(uint _ssidAuditorProfileId) external view returns(address, COLOR) {
        return (
            profiles[_ssidAuditorProfileId],
            _getColor(percentiles[profiles[_ssidAuditorProfileId]])
        );
    }

    function emitWithdraw(address from, uint amount) external {
        require(gauges.contains(msg.sender), "SN7");
        emit Withdraw(from, msg.sender, amount);
    }
    
    function emitDeleteProtocol(uint protocolId) external {
        require(gauges.contains(msg.sender), "SN8");
        emit DeleteProtocol(protocolId, msg.sender);
    }

    function emitPayInvoicePayable(uint protocolId, uint paidPayable) external {
        require(gauges.contains(msg.sender), "SN9");
        emit PayInvoicePayable(protocolId, msg.sender, paidPayable);
    }

    function emitUpdateContents(string memory _contentName, bool _add) external {
        require(gauges.contains(msg.sender), "SN09");
        emit UpdateContents(msg.sender, _contentName, _add);
    }

    function emitUpdateProtocol(
        uint protocolId,
        address owner,
        string memory media,
        string memory description
    ) external {
        require(gauges.contains(msg.sender), "SN10");
        emit UpdateProtocol(
            protocolId, 
            msg.sender,
            owner,
            media,
            description
        );
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender, "NT2");
        contractAddress = _contractAddress;
    }

    function setContractAddressAt(address _sponsorCard) external {
        IMarketPlace(_sponsorCard).setContractAddress(contractAddress);
    }

    function getNumPeriods(uint tm1, uint tm2, uint _period) public pure returns(uint) {
        if (tm1 == 0 || tm2 == 0 || tm2 < tm1) return 0;
        return _period > 0 ? (tm2 - tm1) / _period : 1;
    }

    function getDuePayable(address _sponsor, address _protocol, uint _numPeriods) public view returns(uint, uint, int) {
        uint _protocolId = ISponsor(_sponsor).addressToProtocolId(_protocol);
        (,,,,uint amountPayable,uint paidPayable,uint periodPayable,uint startPayable) = 
        ISponsor(_sponsor).protocolInfo(_protocolId);
        uint numPeriods = getNumPeriods(
            startPayable, 
            block.timestamp, 
            periodPayable
        );
        numPeriods += _numPeriods;
        uint nextDue = startPayable + periodPayable * Math.max(1,numPeriods);
        uint due = nextDue < block.timestamp ? amountPayable * numPeriods - paidPayable : 0;
        return (
            due, // due
            periodPayable == 0 ? uint(0) : nextDue, // next
            periodPayable == 0 ? int(0) : int(block.timestamp) - int(nextDue) //late or seconds in advance
        );
    }

    function transferDueToNote(address _sponsor, address _to, uint _numPeriods) external lock {
        require(gauges.contains(_sponsor), "SN14");
        uint _protocolId = ISponsor(_sponsor).addressToProtocolId(msg.sender);
        (uint duePayable, uint nextDue,) = getDuePayable(_sponsor, msg.sender, _numPeriods);
        require(
            // duePayable > 0 && 
            protocolNotes[_sponsor][_protocolId] < ISponsor(_sponsor).maxNotesPerProtocol(), "SN15");
        (,address _token,,,,,,) = ISponsor(_sponsor).protocolInfo(_protocolId);
        notes[tokenId] = SponsorShipNote({
            due: duePayable,
            token: _token,
            timer: nextDue,
            tokenId: tokenId,
            protocolId: _protocolId,
            protocol: msg.sender
        });
        protocolNotes[_sponsor][_protocolId] += 1;
        ISponsor(_sponsor).updatePaidPayable(msg.sender, duePayable);
        _safeMint(_to, tokenId, msg.data);
        emit UpdateMiscellaneous(
            1, 
            _protocolId, 
            "", 
            "", 
            tokenId++, 
            0, 
            msg.sender,
            _sponsor,
            ""
        );
    }

    function claimRevenueFromNote(address _sponsor, uint _tokenId) external lock {
        require(gauges.contains(_sponsor) && ownerOf(_tokenId) == msg.sender, "SN16");
        require(notes[_tokenId].timer < block.timestamp, "SN17");
        _burn(_tokenId); 
        uint payswapFees = notes[_tokenId].due * tradingFee / 10000;
        ISponsor(_sponsor).noteWithdraw(msg.sender, notes[_tokenId].protocol, notes[_tokenId].due - payswapFees);
        ISponsor(_sponsor).noteWithdraw(address(this), notes[_tokenId].protocol, payswapFees);
        treasuryFees[notes[_tokenId].token] += payswapFees;
        delete notes[_tokenId];
    }

    function _constructTokenURI(uint _tokenId, address _token, string[] memory description, string[] memory optionNames, string[] memory optionValues) internal view returns(string memory) {
        return IMarketPlace(IContract(contractAddress).nftSvg()).constructTokenURI(
            _tokenId,
            "",
            _token,
            ownerOf(_tokenId),
            ownerOf(_tokenId),
            address(0x0),
            new string[](1),
            optionNames,
            optionValues,
            description
        );
    }

    function tokenURI(uint _tokenId) public override view returns (string memory output) {
        uint idx;
        string[] memory optionNames = new string[](5);
        string[] memory optionValues = new string[](5);
        uint decimals = uint(IMarketPlace(notes[_tokenId].token).decimals());
        optionValues[idx++] = toString(_tokenId);
        optionNames[idx] = "PID";
        optionValues[idx++] = toString(notes[_tokenId].protocolId);
        optionNames[idx] = "End";
        optionValues[idx++] = toString(notes[_tokenId].timer);
        optionNames[idx] = "Amount";
        optionValues[idx++] = string(abi.encodePacked(toString(notes[_tokenId].due/10**decimals), " " ,IMarketPlace(notes[_tokenId].token).symbol()));
        optionNames[idx] = "Expired";
        optionValues[idx++] = notes[_tokenId].timer < block.timestamp ? "Yes" : "No";
        string[] memory _description = new string[](1);
        _description[0] = "This note gives you access to revenues on the specified protocol";
        output = _constructTokenURI(
            _tokenId, 
            notes[_tokenId].token,
            _description,
            optionNames, 
            optionValues 
        );
    }

    function updateTradingFee(uint _tradingFee) external {
        require(msg.sender == IAuth(contractAddress).devaddr_());
        tradingFee = _tradingFee;
    }

    function withdrawFees(address _token) external returns(uint _amount) {
        require(msg.sender == IAuth(contractAddress).devaddr_(), "SN19");
        _amount = treasuryFees[_token];
        IERC20(_token).safeTransfer(msg.sender, _amount);
        treasuryFees[_token] = 0;
        return _amount;
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

    function _sumArr(uint[] memory _arr) internal pure returns(uint total) {
        for (uint i = 0; i < _arr.length; i++) {
            total += _arr[i];
        }
    }

}

contract SponsorFactory {
    address public contractAddress;

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }

    function createGauge(uint _profileId, address _devaddr) external {
        address sponsorNote = IContract(contractAddress).sponsorNote();
        address last_gauge = address(new Sponsor(
            _devaddr,
            sponsorNote,
            contractAddress
        ));
        ISponsor(sponsorNote).updateGauge(
            last_gauge, 
            _devaddr, 
            _profileId 
        );
    }
}
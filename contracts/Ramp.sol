// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Library.sol";

contract Ramp {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    
    uint badgeId;
    mapping(address => EnumerableSet.UintSet) private protocolPartners;
    mapping(address => RampInfo) public protocolInfo;
    EnumerableSet.AddressSet private AllProtocols;
    mapping(address => mapping(uint => uint)) public paidRevenue;
    mapping(address => uint) public totalRevenue;
    uint tokenId;
    uint mintFee;
    uint burnFee;
    address public _ve;
    uint salePrice;
    uint soldAccounts;
    bool automatic = true;
    uint public collectionId;
    address public contractAddress;
    mapping(address => bool) public isAdmin;
    address public devaddr_;
    address private helper;

    constructor(
        address _devaddr,
        address _helper,
        address __contractAddress
    ){
        collectionId = IMarketPlace(IContract(__contractAddress).marketCollections())
        .addressToCollectionId(_devaddr);
        require(collectionId > 0, "R01");
        helper = _helper;
        devaddr_ = _devaddr;
        isAdmin[_devaddr] = true;
        contractAddress = __contractAddress;
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

    function checkIdentityProof(address _owner, uint _identityTokenId) public {
        if (collectionId > 0) {
            IMarketPlace(IContract(contractAddress).marketHelpers2())
            .checkUserIdentityProof(collectionId, _identityTokenId, _owner);
        }
    }

    function updateParameters(
        uint _mintFee, 
        uint _burnFee,
        uint _badgeId,
        uint _salePrice,
        bool _automatic
    ) external onlyAdmin {
        mintFee = _mintFee;
        burnFee = _burnFee;
        badgeId = _badgeId;
        salePrice = _salePrice;
        automatic = _automatic;
    }

    function getAllTokens(uint _start) external view returns(address[] memory tokens) {
        tokens = new address[](AllProtocols.length() - _start);
        for (uint i = _start; i < AllProtocols.length(); i++) {
            tokens[i] = AllProtocols.at(i);
        }    
    }

    function getParams() external view returns(uint,uint,uint,uint,uint,uint,bool,address) {
        return (
            badgeId,
            tokenId,
            mintFee,
            burnFee,
            salePrice,
            soldAccounts,
            automatic,
            _ve
        );
    }
    
    function updateBounty(address _token, uint _bountyId) external {
        IRamp(helper).checkBounty(msg.sender, _bountyId);
        require(isAdmin[msg.sender]);
        require(protocolInfo[_token].bountyId == 0);
        protocolInfo[_token].bountyId = _bountyId;
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || helper == msg.sender);
        contractAddress = _contractAddress;
        helper = IContract(_contractAddress).rampHelper();
    }

    function _updateBounty(address _token, uint _bountyId) internal {
        IRamp(helper).checkBounty(msg.sender, _bountyId);
        if(protocolInfo[_token].bountyId > 0) {
            address _trustBounty = IContract(contractAddress).trustBounty();
            uint newBalance = ITrustBounty(_trustBounty).getBalance(_bountyId);
            uint oldBalance = ITrustBounty(_trustBounty).getBalance(protocolInfo[_token].bountyId);
            require(newBalance >= oldBalance);
            _unlockBounty(_token);
        } 
        protocolInfo[_token].bountyId = _bountyId;
    }

    function getAllPartnerBounties(address _token, uint _start) external view returns(uint[] memory _partners) {
        _partners = new uint[](protocolPartners[_token].length() - _start);
        for (uint i = _start; i < protocolPartners[_token].length(); i++) {
            _partners[i] = protocolPartners[_token].at(i);
        }    
    }

    function addPartner(address _token, uint _bountyId) external {
        address rampAds = IContract(contractAddress).rampAds();
        (,,CollateralStatus _status) = IRamp(rampAds).mintAvailable(address(this), _token);
        if (_status == CollateralStatus.UnderCollateralized ||
            protocolInfo[_token].maxParters > protocolPartners[_token].length()
        ) {
            IRamp(helper).checkBounty(msg.sender, _bountyId);
            require(!isAdmin[msg.sender]);
            require(protocolPartners[_token].length() < IContract(contractAddress).maximumSize());
            protocolPartners[_token].add(_bountyId);
            uint _share = ITrustBounty(IContract(contractAddress).trustBounty()).getBalance(_bountyId) * 10000 / IRamp(helper).getTotalBalance(address(this), _token);
            // do not account for past revenue for new partners
            paidRevenue[_token][_bountyId] += _share * totalRevenue[_token]/ 10000;
        }
    }
        
    function updateProfile(address _token, uint _profileId) external {
        require(IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender) == _profileId);
        require(isAdmin[msg.sender]);
        protocolInfo[_token].profileId = _profileId;
    }

    function updateTokenId(address _token, uint _tokenId) public {
        require(ve(_ve).ownerOf(_tokenId) == msg.sender);
        if (AllProtocols.contains(_token)) {
            protocolInfo[_token].tokenId = _tokenId;
        }
    }

    function updateDevTokenId(address __ve, uint _tokenId) public {
        require(ve(__ve).ownerOf(_tokenId) == msg.sender);
        require(isAdmin[msg.sender]);
        _ve = __ve;
        tokenId = _tokenId;
    }

    function updateBadgeId(address _token, uint _badgeId) external {
        require(ve(IRamp(helper).badgeNFT()).ownerOf(_badgeId) == msg.sender);
        require(isAdmin[msg.sender]);
        protocolInfo[_token].badgeId = _badgeId;
    }

    function updateDevFromToken(uint _tokenId) external {
        require(ve(_ve).ownerOf(_tokenId) == msg.sender);
        require(tokenId == _tokenId);
        isAdmin[devaddr_] = false;
        devaddr_ = msg.sender;
        isAdmin[msg.sender] = true;
    }

    function buyAccount(address _token, uint _tokenId, uint _bountyId) external {
        require(protocolInfo[_token].salePrice > 0);
        require(ve(_ve).ownerOf(_tokenId) == msg.sender);
        
        IERC20(ve(_ve).token()).safeTransferFrom(msg.sender, address(this), protocolInfo[_token].salePrice);
        protocolInfo[_token].salePrice = 0;
        soldAccounts += 1;
        _updateBounty(_token, _bountyId);
        updateTokenId(_token, _tokenId);
    }

    function buyRamp(address __ve, uint _tokenId, uint[] memory _bountyIds) external {
        require(salePrice > 0 && ve(_ve).ownerOf(_tokenId) == msg.sender);
        require(AllProtocols.length() - soldAccounts == _bountyIds.length);
        
        IERC20(ve(_ve).token()).safeTransferFrom(msg.sender, address(this), salePrice);
        for(uint i = 0; i < AllProtocols.length(); i++) {
            uint __tokenId = protocolInfo[AllProtocols.at(i)].tokenId;
            if (isAdmin[ve(_ve).ownerOf(__tokenId)]) {
                _updateBounty(AllProtocols.at(i), _bountyIds[i]);
            }
        }
        isAdmin[msg.sender] = true;
        isAdmin[devaddr_] = false;
        devaddr_ = msg.sender;
        updateDevTokenId(__ve, _tokenId);
    } 

    function createProtocol(address _token, uint _tokenId) external onlyAdmin {
        require(IRamp(helper).dTokenSetContains(_token));
        if(!AllProtocols.contains(_token)) {
            AllProtocols.add(_token);
            protocolInfo[_token].status = RampStatus.Open;
            if (_tokenId > 0) updateTokenId(_token, _tokenId);

            IRamp(helper).emitCreateProtocol(msg.sender, _token);
        }
    }

    // available only to admins
    function updateProtocol(
        address _token, 
        bool _close, 
        uint _cap,
        uint _salePrice,
        uint _maxParters
    ) external onlyAdmin {
        if(AllProtocols.contains(_token)) {
            uint _tokenId = protocolInfo[_token].tokenId;
            require(_tokenId == 0 || isAdmin[ve(_ve).ownerOf(_tokenId)]);
            _updateProtocol(_token, _close, _cap, _salePrice, _maxParters);
        }
    }

    // available to new owner of account
    function updateIndividualProtocol(
        address _token, 
        bool _close, 
        uint _cap,
        uint _salePrice,
        uint _maxParters
    ) external {
        if(AllProtocols.contains(_token)) {
            require(ve(_ve).ownerOf(protocolInfo[_token].tokenId) == msg.sender);
            require(!isAdmin[msg.sender]);
            _updateProtocol(_token, _close, _cap, _salePrice, _maxParters);
        }
    }

    function _updateProtocol(
        address _token, 
        bool _close, 
        uint _cap,
        uint _salePrice,
        uint _maxParters
    ) internal {
        if (_close) {
            protocolInfo[_token].status = RampStatus.Close;
        } else if (protocolInfo[_token].status == RampStatus.Close) {
            protocolInfo[_token].status = RampStatus.Open;
        }
        if (_cap >= IRamp(helper).minCap(_token)) {
            protocolInfo[_token].cap = _cap;    
        }
        protocolInfo[_token].salePrice = _salePrice;
        protocolInfo[_token].maxParters = _maxParters;
    }

    function mint(address _token, address to, uint _amount, uint _identityTokenId, string memory _sessionId) external {
        checkIdentityProof(to, _identityTokenId);
        require(IAuth(contractAddress).devaddr_() == msg.sender || isAdmin[msg.sender], "R1");
        require(protocolInfo[_token].status == RampStatus.Open, "R2");
        (uint _mintable,, CollateralStatus _status) = IRamp(IContract(contractAddress).rampAds()).mintAvailable(address(this), _token);
        if (_status == CollateralStatus.OverCollateralized) {
            uint _toMint = Math.min(_mintable, _amount);
            uint _fee;
            uint _payswapFee;
            if (protocolInfo[_token].cap > 0) {
                _fee = Math.min(_toMint * mintFee / 10000, protocolInfo[_token].cap);
                _payswapFee = Math.min(_toMint * IRamp(helper).tradingFee() / 10000, protocolInfo[_token].cap);
            } else {
                _fee = _toMint * mintFee / 10000;
                _payswapFee = _toMint * IRamp(helper).tradingFee() / 10000;
            }
            totalRevenue[_token] += _fee;
            _toMint = _toMint - _fee - _payswapFee;
            protocolInfo[_token].minted += _toMint;
            IRamp(helper).mint(_token, to, _toMint, _payswapFee, _identityTokenId, _sessionId);
        }
    }

    function burn(address _token, uint _amount, uint _identityTokenId) external {
        checkIdentityProof(msg.sender, _identityTokenId);
        // require(AllProtocols.contains(_token));
        uint _toBurn = Math.min(
            _amount, 
            protocolInfo[_token].minted - protocolInfo[_token].burnt
        );
        uint _fee;
        uint _payswapFee;
        if (protocolInfo[_token].cap > 0) {
            _fee = Math.min(_toBurn * burnFee / 10000, protocolInfo[_token].cap);
            _payswapFee = Math.min(IRamp(helper).tradingFee() * _toBurn / 10000, protocolInfo[_token].cap);
        } else {
            _fee = _toBurn * burnFee / 10000;
            _payswapFee = IRamp(helper).tradingFee() * _toBurn / 10000;
        }
        _toBurn = _toBurn - _fee - _payswapFee;
        totalRevenue[_token] += _fee;
        IRamp(helper).burn(_token, msg.sender, _toBurn, _fee, _payswapFee);
        protocolInfo[_token].burnt += _toBurn;
    }

    function claimPendingRevenue(address _token, uint _partnerBountyId) external {
        require(!isAdmin[msg.sender] && protocolPartners[_token].contains(_partnerBountyId));
        uint _toPay = IRamp(helper).claimPendingRevenue(_token, msg.sender, _partnerBountyId);
        protocolInfo[_token].minted += _toPay;
        paidRevenue[_token][_partnerBountyId] += _toPay;
        IERC20(_token).safeTransfer(msg.sender, _toPay);
    }

    function unlockBounty(address _token, uint _bountyId) external {
        require(protocolInfo[_token].minted == protocolInfo[_token].burnt);
        if(isAdmin[msg.sender]) {
            IRamp(helper).endBounty(protocolInfo[_token].bountyId);
            protocolInfo[_token].bountyId = 0;
        } else if (protocolPartners[_token].contains(_bountyId)) {
            IRamp(helper).endBounty(_bountyId);
            protocolPartners[_token].remove(_bountyId);
        }
    }
    
    function _unlockBounty(address _token) internal {
        IRamp(helper).endBounty(protocolInfo[_token].bountyId);
        protocolInfo[_token].bountyId = 0;
    }

    function deleteProtocol(address _token) public onlyAdmin {
        require(protocolInfo[_token].minted == protocolInfo[_token].burnt);
        require(protocolInfo[_token].bountyId == 0);
        delete protocolInfo[_token];
        AllProtocols.remove(_token);

        IRamp(helper).emitDeleteProtocol(msg.sender, _token);
    }

    function withdraw(address _token, uint amount) external onlyAdmin {
        IERC20(_token).safeTransfer(msg.sender, amount);
    }
}

contract RampHelper {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private gauges;
    address private nativeCoin;
    uint public tradingFee;
    uint private bufferTime;
    address private badgeNFT;
    mapping(address => uint) public minCap;
    mapping(address => uint) public pendingRevenue;
    EnumerableSet.AddressSet internal _dtokenSet;
    mapping(address => EnumerableSet.AddressSet) internal _extraSet;
    mapping(address => address) private tokenToOracle;
    mapping(address => uint) private nextOracleUpdateTime;
    mapping(address => uint) private tokenPriceInNative;
    mapping(bytes32 => bool) private activeSession;
    mapping(address => uint256) private oracleLatestRoundId;
    mapping(address => mapping(address => bool)) private isBlacklisted;
    uint256 private oracleUpdateAllowance = 86400;
    address private contractAddress;
    mapping(address => bool) public trustWorthyAuditors;
    uint collectionId;
    
    event AddToken(address dtoken);
    event RemoveToken(address dtoken);
    event Voted(address ramp, uint profileId, uint likes, uint dislikes, bool like);
    event CreateGauge(address ramp, address owner, uint collectionId);
    event PreMint(
        string sessionId,
        address ramp, 
        address user, 
        address tokenAddress, 
        uint amount, 
        uint identityTokenId
    );
    event PostMint(string sessionId, address user);
    event CreateProtocol(address ramp, address from, address token);
    event Mint(address ramp, address token, address to, uint amount, string sessionId);
    event Burn(address ramp, address token, address to, uint amount);
    event ClaimPendingRevenue(address ramp, address token, address user, uint partnerBountyId);
    event DeleteProtocol(address ramp, address from, address token);
    event LinkAccount(string accountId, string channel, string[] moreInfo, address owner);
    event Blacklist(address ramp, address user, bool blacklist);
    event UpdateRampInfo(
        address ramp,
        uint profileId,
        string applicationLink,
        string[5] publishableKeys, 
        string[5] secretKeys, 
        string[5] clientIds,
        string avatar,
        string description,
        string[5] channels
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

    constructor(address _nativeCoin, uint _collectionId) {
        nativeCoin = _nativeCoin;
        collectionId = _collectionId;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == IAuth(contractAddress).devaddr_());
        _;
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender, "NT2");
        contractAddress = _contractAddress;
    }

    function setContractAddressAt(address _ramp) external {
        IMarketPlace(_ramp).setContractAddress(contractAddress);
    }

    function linkAccount(string memory _channel, string memory _accountId, string[] memory moreInfo) external {
        emit LinkAccount(_accountId, _channel, moreInfo, msg.sender);
    }
    
    function checkAuditor(address _ramp) external view returns(bool) {
        address _profile = IContract(contractAddress).profile();
        uint _rampProfileId = IProfile(_profile).addressToProfileId(IAuth(_ramp).devaddr_());
        SSIData memory metadata = ISSI(IContract(contractAddress).ssi()).getSSID(_rampProfileId);
        (,bool dk,) = IAuditor(IContract(contractAddress).auditorNote()).getGaugeNColor(metadata.auditorProfileId);
        return IProfile(_profile).isUnique(_rampProfileId) && dk;
    }

    function updateBlacklist(address ramp, address _user, bool _blacklist) external {
        require(IAuth(ramp).isAdmin(msg.sender) && gauges.contains(ramp));
        isBlacklisted[ramp][_user] = _blacklist;

        emit Blacklist(ramp, _user, _blacklist);
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
    function preMint(
        address ramp, 
        address to, 
        address tokenAddress, 
        uint amount, 
        uint _identityTokenId,
        string memory sessionId
    ) external {
        require(gauges.contains(ramp));
        require(!isBlacklisted[ramp][to]);
        require(IAuth(ramp).isAdmin(msg.sender) || msg.sender == IAuth(contractAddress).devaddr_());
        IRamp(ramp).checkIdentityProof(to, _identityTokenId);
        activeSession[keccak256(abi.encodePacked(sessionId))] = true;

        emit PreMint(
            sessionId, 
            ramp, 
            to, 
            tokenAddress, 
            amount, 
            _identityTokenId
        );
    }

    function postMint(string memory sessionId) external {
        emit PostMint(sessionId, msg.sender);
    }
    
    function updateRampInfo(
        address _ramp,
        uint _profileId,
        string memory applicationLink, 
        string[5] memory publishableKeys, 
        string[5] memory secretKeys, 
        string[5] memory clientIds,
        string memory avatar,
        string memory description,
        string[5] memory channels
    ) external {
        require(IAuth(_ramp).isAdmin(msg.sender));
        require(IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender) == _profileId && _profileId > 0);
        SSIData memory metadata = ISSI(IContract(contractAddress).ssi()).getSSID(_profileId);
        require(keccak256(abi.encodePacked(metadata.answer)) != keccak256(abi.encodePacked("")), "NTH4");

        emit UpdateRampInfo(
            _ramp,
            _profileId,
            applicationLink,
            publishableKeys,
            secretKeys,
            clientIds,
            avatar,
            description,
            channels
        );
    }

    function emitCreateProtocol(address from, address token) external {
        require(gauges.contains(msg.sender));
        emit CreateProtocol(msg.sender, from, token);
    }

    function emitDeleteProtocol(address from, address token) external {
        require(gauges.contains(msg.sender));
        emit DeleteProtocol(msg.sender, from, token);
    }
    
    function dTokenSetContains(address _token) external view returns(bool) {
        return _dtokenSet.contains(_token) || _extraSet[msg.sender].contains(_token);
    }

    function updateMinCap(address _token, uint _minCap) external onlyAdmin {
        minCap[_token] = _minCap;
    }

    function updateOracleUpdateAllowance(uint _oracleUpdateAllowance) external onlyAdmin {
        oracleUpdateAllowance = _oracleUpdateAllowance;
    }
    
    function endBounty(uint _bountyId) external {
        require(gauges.contains(msg.sender));
        ITrustBounty(IContract(contractAddress).trustBounty()).updateBountyEndTime(_bountyId, 0);
    }

    function addDtoken(address _dtoken) external onlyAdmin {
        _dtokenSet.add(_dtoken);
        emit AddToken(_dtoken);
    }

    function addExtratoken(address _ramp, address _dtoken, uint _identityTokenId) external {
        require(gauges.contains(_ramp) && IAuth(_ramp).isAdmin(msg.sender));
        IMarketPlace(IContract(contractAddress).marketHelpers2())
        .checkUserIdentityProof(collectionId, _identityTokenId, msg.sender);
        _extraSet[_ramp].add(_dtoken);
        emit AddToken(_dtoken);
    }
    
    function removeDtoken(address _dtoken) external onlyAdmin {
        _dtokenSet.remove(_dtoken);
        emit RemoveToken(_dtoken);
    }

    function removeExtratoken(address _ramp, address _dtoken) external {
        require(IAuth(_ramp).isAdmin(msg.sender) || msg.sender == IAuth(contractAddress).devaddr_());
        _extraSet[_ramp].remove(_dtoken);
        emit RemoveToken(_dtoken);
    }

    function checkBounty(address _user, uint _bountyId) external {
        require(gauges.contains(msg.sender));
        (address owner,address token,,address claimableBy,,,uint endTime,,,) = 
        ITrustBounty(IContract(contractAddress).trustBounty()).bountyInfo(_bountyId);
        require(owner == _user && nativeCoin == token && claimableBy == address(this));
        require(endTime >= block.timestamp + bufferTime);
        ITrustBounty(IContract(contractAddress).trustBountyHelper()).attach(_bountyId);
    }
    
    function updateOracle(address _token, address _oracle, bool _add) external onlyAdmin {
        if (_add) {
            require(_oracle != address(0x0), "Cannot be zero address");
            oracleLatestRoundId[_oracle] = 0;
            tokenToOracle[_token] = _oracle;
            // Dummy check to make sure the interface implements this function properly
            AggregatorV3Interface(_oracle).latestRoundData();
        } else {
            delete tokenToOracle[_token];
        }
    }

    function updateTrustWorthyAuditors(address _auditor, bool _add) external onlyAdmin {
        trustWorthyAuditors[_auditor] = _add;
    }

    function getPartnerShare(uint _total, uint _partnerBountyId) public view returns(uint) {
        uint balance = ITrustBounty(IContract(contractAddress).trustBounty()).getBalance(_partnerBountyId);
        return balance * 10000 / _total;
    }

    function getTotalBalance(address _ramp, address _token) external view returns(uint balance) {
        RampInfo memory protocolInfo = IRamp(_ramp).protocolInfo(_token);
        address trustBounty = IContract(contractAddress).trustBounty();
        balance = ITrustBounty(trustBounty).getBalance(protocolInfo.bountyId);
        uint[] memory partnerBounties = IRamp(_ramp).getAllPartnerBounties(_token,0);
        for (uint i = 0; i < partnerBounties.length; i++) {
            balance += ITrustBounty(trustBounty).getBalance(partnerBounties[i]);
        }
    }

    function updateExtraOracle(address _token, address _oracle, bool _add) external {
        require(trustWorthyAuditors[msg.sender] && !_dtokenSet.contains(_token));
        if (_add) {
            require(_oracle != address(0x0), "Cannot be zero address");
            oracleLatestRoundId[_oracle] = 0;
            tokenToOracle[_token] = _oracle;
            // Dummy check to make sure the interface implements this function properly
            AggregatorV3Interface(_oracle).latestRoundData();
        } else {
            delete tokenToOracle[_token];
        }
    }

    function _getPriceFromOracle(address _token) internal view returns (uint80, int256) {
        require(tokenToOracle[_token] != address(0x0));
        uint256 leastAllowedTimestamp = block.timestamp + oracleUpdateAllowance;
        (uint80 roundId,int256 price,,uint256 timestamp,) = AggregatorV3Interface(tokenToOracle[_token]).latestRoundData();
        require(timestamp <= leastAllowedTimestamp);
        require(uint256(roundId) > oracleLatestRoundId[tokenToOracle[_token]]);
        return (roundId, price);
    }
    
    function updateTokenPrice(address _token) external {
        (uint80 currentRoundId, int256 currentPrice) = _getPriceFromOracle(_token);
        nextOracleUpdateTime[tokenToOracle[_token]] = 
        (block.timestamp + oracleUpdateAllowance) / oracleUpdateAllowance * oracleUpdateAllowance;
        oracleLatestRoundId[tokenToOracle[_token]] = uint256(currentRoundId);
        tokenPriceInNative[_token] = uint256(currentPrice);
    }

    function getChainID() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function convert(address tokenAddress, uint _balance) public view returns(uint amountOut) {
        if (getChainID() == 4002) return _balance;
        require(
            tokenPriceInNative[tokenAddress] > 0 && 
            nextOracleUpdateTime[tokenToOracle[tokenAddress]] > block.timestamp
        );
        amountOut = tokenPriceInNative[tokenAddress] * _balance;
    }

    function getAllRamps(uint _start) external view returns(address[] memory ramps) {
        ramps = new address[](gauges.length() - _start);
        for (uint i = _start; i < gauges.length(); i++) {
            ramps[i] = gauges.at(i);
        }    
    }

    function getAllDTokens(uint _start) external view returns(address[] memory dtokens) {
        dtokens = new address[](_dtokenSet.length() - _start);
        for (uint i = _start; i < _dtokenSet.length(); i++) {
            dtokens[i] = _dtokenSet.at(i);
        }    
    }
    
    function updateGauge(address _last_gauge, address _devaddr) external {
        require(msg.sender == IContract(contractAddress).rampFactory());
        gauges.add(_last_gauge);
        emit CreateGauge(_last_gauge, _devaddr, IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(_devaddr));
    }

    function deleteRamp(address _ramp) external {
        require(msg.sender == IAuth(contractAddress).devaddr_() || IAuth(_ramp).isAdmin(msg.sender));
        gauges.remove(_ramp);
    }

    function emitVoted(address _ramp, uint profileId, uint likes, uint dislikes, bool like) external {
        require(IContract(contractAddress).rampHelper2() == msg.sender);
        emit Voted(_ramp, profileId, likes, dislikes, like);
    }

    function claimPendingRevenue(address _token, address _user, uint _partnerBountyId) external returns(uint _toPay) {
        address _ramp = msg.sender;
        (address owner,,,,,,,,,) = ITrustBounty(IContract(contractAddress).trustBounty()).bountyInfo(_partnerBountyId);
        require(_user == owner);
        (uint _mintable, uint _totalBalance,) = IRamp(IContract(contractAddress).rampAds()).mintAvailable(_ramp, _token);
        uint _share = getPartnerShare(_totalBalance, _partnerBountyId);
        uint _totalRevenue = IRamp(_ramp).totalRevenue(_token);
        uint _paidRevenue = IRamp(_ramp).paidRevenue(_token, _partnerBountyId);
        _toPay = Math.min(_mintable, _totalRevenue * _share / 10000 - _paidRevenue);
        _toPay = Math.min(_toPay, erc20(_token).balanceOf(_ramp));
        emit ClaimPendingRevenue(_ramp, _token, _user, _partnerBountyId);
    }

    function updateParameters(
        uint _tradingFee, 
        uint _bufferTime,
        address _badgeNFT
    ) external onlyAdmin {
        tradingFee = _tradingFee;
        bufferTime = _bufferTime;
        badgeNFT = _badgeNFT;
    }

    function mint(
        address _token, 
        address _user, 
        uint _toMint, 
        uint _payswapFee,
        uint _identityTokenId,
        string memory _sessionId
    ) external {
        require(gauges.contains(msg.sender), "RH1");
        require(_dtokenSet.contains(_token) || _extraSet[msg.sender].contains(_token), "RH2");
        require(activeSession[keccak256(abi.encodePacked(_sessionId))], "RH3");
        require(!isBlacklisted[msg.sender][_user], "RH4");
        IMarketPlace(IContract(contractAddress).marketHelpers2())
        .checkUserIdentityProof(collectionId, _identityTokenId, IAuth(msg.sender).devaddr_());

        erc20(_token).mint(_user, _toMint);
        erc20(_token).mint(address(this), _payswapFee);
        pendingRevenue[_token] += _payswapFee;

        activeSession[keccak256(abi.encodePacked(_sessionId))] = false;
        emit Mint(msg.sender, _token, _user, _toMint, _sessionId);
    }

    function burn(address _token, address _user, uint _toBurn, uint _fee, uint _payswapFee) external {
        require(gauges.contains(msg.sender) && _dtokenSet.contains(_token));
        require(!isBlacklisted[msg.sender][_user]);
        erc20(_token).burn(_user, _toBurn);
        IERC20(_token).safeTransferFrom(_user, msg.sender, _fee);
        IERC20(_token).safeTransferFrom(_user, address(this), _payswapFee);
        pendingRevenue[_token] += _payswapFee;
        emit Burn(msg.sender, _token, _user, _toBurn);
    }

    function withdrawFees(address _token) external onlyAdmin returns(uint _amount) {
        _amount = pendingRevenue[_token];
        IERC20(_token).safeTransfer(msg.sender, _amount);
        pendingRevenue[_token] = 0;
        return _amount;
    }

    function createClaim(
        address _ramp, 
        address _token,
        uint amount,
        bool _lockBounty,
        string memory _title, 
        string memory _content,
        string memory _tags
    ) external payable {
        RampInfo memory protocolInfo = IRamp(_ramp).protocolInfo(_token);
        ITrustBounty(IContract(contractAddress).trustBounty()).createClaim(
            msg.sender, 
            protocolInfo.bountyId, 
            amount,
            _lockBounty,
            _title,
            _content,
            _tags
        );
    }
}

contract RampHelper2 {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using Percentile for *; 

    struct Vote {
        uint likes;
        uint dislikes;
    }
    EnumerableSet.UintSet private _allVoters;
    mapping(address => uint) public percentiles;
    uint private sum_of_diff_squared;
    mapping(address => Vote) public votes;
    mapping(uint => mapping(address => int)) public voted;
    address public contractAddress;
    
    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function _resetVote(address _ramp, uint profileId) internal {
        if (voted[profileId][_ramp] > 0) {
            votes[_ramp].likes -= 1;
        } else if (voted[profileId][_ramp] < 0) {
            votes[_ramp].dislikes -= 1;
        }
    }

    function vote(address _ramp, uint profileId, bool like) external {
        require(IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender) == profileId && profileId > 0);
        SSIData memory metadata = ISSI(IContract(contractAddress).ssi()).getSSID(profileId);
        require(keccak256(abi.encodePacked(metadata.answer)) != keccak256(abi.encodePacked("")));
        _resetVote(_ramp, profileId);        
        if (like) {
            votes[_ramp].likes += 1;
            voted[profileId][_ramp] = 1;
        } else {
            votes[_ramp].dislikes += 1;
            voted[profileId][_ramp] = -1;
        }
        uint _rampVotes;
        if (votes[_ramp].likes > votes[_ramp].dislikes) {
            _rampVotes = votes[_ramp].likes - votes[_ramp].dislikes;
        }
        _allVoters.add(profileId);
        (uint percentile, uint sods) = Percentile.computePercentileFromData(
            false,
            _rampVotes,
            _allVoters.length(),
            _allVoters.length(),
            sum_of_diff_squared
        );
        sum_of_diff_squared = sods;
        percentiles[_ramp] = percentile;
        IRamp(IContract(contractAddress).rampHelper()).
        emitVoted(_ramp, profileId, votes[_ramp].likes, votes[_ramp].dislikes, like);
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }

}

contract RampAds is ERC721Pausable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    uint private tokenId = 1;
    struct ScheduledMedia {
        uint amount;
        string message;
    }
    uint public pricePerAttachMinutes;
    mapping(uint => ScheduledMedia) public scheduledMedia;
    mapping(uint => uint) public pendingRevenue;
    mapping(address => EnumerableSet.UintSet) private _scheduledMedia;
    uint internal minute = 3600; // allows minting once per week (reset every Thursday 00:00 UTC)
    uint private currentMediaIdx = 1;
    struct Channel {
        string message;
        uint active_period;
    }
    struct RampNote {
        address token;
        uint profileId;
        uint mintedAt;
    }
    mapping(uint => RampNote) public notes;
    mapping(address => Channel) public channels;
    mapping(address => EnumerableSet.UintSet) private excludedContents;
    uint public adminFee = 100;
    uint public treasury;
    address contractAddress;
    uint public totalFromSponsors;
    mapping(address => uint) public paidPayable;
    uint public minToMint;
    mapping(uint => bool) public isMinted;
    address private uriGenerator;
    uint public lotteryShare;
    uint public lotteryRevenue;
    address private lotteryAddress;

    mapping(address => uint) public mintFactor;
    uint public defaultMintFactor = 8000;

    constructor() ERC721("RampAd", "RampAdNFT")  {}

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function updateExcludedContent(address _tag, string memory _contentName, bool _add) external {
        require(IAuth(contractAddress).devaddr_() == msg.sender);
        if (_add) {
            require(IContract(contractAddress).contains(_contentName));
            excludedContents[_tag].add(uint(keccak256(abi.encodePacked(_contentName))));
        } else {
            excludedContents[_tag].remove(uint(keccak256(abi.encodePacked(_contentName))));
        }
    }

    function updateParameters(uint _defaultMintFactor) external {
        require(IAuth(contractAddress).devaddr_() == msg.sender);
        defaultMintFactor = _defaultMintFactor;
    }

    function updateMintFactors(address _token, uint _mintFactor) external {
        require(IAuth(contractAddress).devaddr_() == msg.sender);
        mintFactor[_token] = _mintFactor;
    }

    function getExcludedContents(address _tag) public view returns(string[] memory _excluded) {
        _excluded = new string[](excludedContents[_tag].length());
        for (uint i = 0; i < _excluded.length; i++) {
            _excluded[i] = IContract(contractAddress).indexToName(excludedContents[_tag].at(i));
        }
    }

    function mintAvailable(address _ramp, address _token) external view 
        returns(uint mintable, uint balance, CollateralStatus status) {
        RampInfo memory protocolInfo = IRamp(_ramp).protocolInfo(_token);
        address rampHelper = IContract(contractAddress).rampHelper();
        balance = IRamp(rampHelper).getTotalBalance(_ramp, _token);
        uint _convertedBalance = IRamp(rampHelper).convert(_token, balance);
        uint _mintFactor = mintFactor[_token] > 0 ? mintFactor[_token] : defaultMintFactor;
        uint _totalMintable = _mintFactor * _convertedBalance / 10000;
        uint _circulatingSupply = protocolInfo.minted - protocolInfo.burnt;
        mintable = _totalMintable > _circulatingSupply ? _totalMintable - _circulatingSupply : 0;
        bool _isValid = IRamp(rampHelper).checkAuditor(_ramp);
        if (!_isValid) mintable = mintable / 2;
        if (mintable > 0) {
            status = CollateralStatus.OverCollateralized;
        } else {
            status = CollateralStatus.UnderCollateralized;
        }
    }
    
    function claimPendingRevenueFromSponsors(address _ramp) external lock {
        require(IAuth(_ramp).isAdmin(msg.sender) && IRamp(IContract(contractAddress).rampHelper()).isGauge(_ramp));
        uint _totalMinted;
        uint _totalSupply;
        address[] memory _allTokens = IRamp(_ramp).getAllTokens(0);
        for (uint i = 0; i < _allTokens.length; i++) {
             _totalMinted += (IRamp(_ramp).protocolInfo(_allTokens[i])).minted;
             _totalSupply += erc20(_allTokens[i]).totalSupply();
        }
        uint earnings = totalFromSponsors * _totalMinted / _totalSupply;
        if (earnings > paidPayable[_ramp]) {
            earnings -= paidPayable[_ramp];
        } else {
            earnings = 0;
        }
        paidPayable[_ramp] += earnings;
        IERC20(IContract(contractAddress).token()).safeTransfer(_ramp, earnings);
    }
    
    function updateParams(
        uint _pricePerAttachMinutes, 
        uint _minToMint, 
        uint _adminFee,
        uint _lotteryShare,
        address _uriGenerator,
        address _lotteryAddress
    ) external {
        require(IAuth(contractAddress).devaddr_() == msg.sender);
        adminFee = _adminFee;
        minToMint = _minToMint;
        uriGenerator = _uriGenerator;
        lotteryShare = _lotteryShare;
        lotteryAddress = _lotteryAddress;
        pricePerAttachMinutes = _pricePerAttachMinutes;
    }

    function sponsorTag(
        address _sponsor,
        address _tag, 
        uint _amount, 
        string memory _message
    ) external {
        require(IAuth(_sponsor).isAdmin(msg.sender));
        require(!ISponsor(_sponsor).contentContainsAny(getExcludedContents(_tag)));
        if (pricePerAttachMinutes > 0) {
            uint price = _amount * pricePerAttachMinutes;
            IERC20(IContract(contractAddress).token()).safeTransferFrom(msg.sender, address(this), price);
            uint _treasuryFee = price * adminFee / 10000;
            uint _lotteryFee = price * lotteryShare / 10000;
            treasury += _treasuryFee;
            lotteryRevenue += _lotteryFee;
            totalFromSponsors += price - _treasuryFee - _lotteryFee;
            scheduledMedia[currentMediaIdx] = ScheduledMedia({
                amount: _amount,
                message: _message
            });
            _scheduledMedia[_tag].add(currentMediaIdx++);
            updateSponsorMedia(_tag);
        }
    }

    function getMedia(uint _tokenId) public view returns(string[] memory _media) {
        _media = new string[](_scheduledMedia[notes[_tokenId].token].length());
        for (uint i = 0; i < _scheduledMedia[notes[_tokenId].token].length(); i++) {
            uint _currentMediaIdx = _scheduledMedia[notes[_tokenId].token].at(i);
            _media[i] = scheduledMedia[_currentMediaIdx].message;
        }
        if (_media.length == 0) _media = new string[](1);
    }

    function updateSponsorMedia(address _tag) public {
        require(channels[_tag].active_period < block.timestamp);
        uint idx = _scheduledMedia[_tag].at(0);
        channels[_tag].active_period = block.timestamp + scheduledMedia[idx].amount*minute / minute * minute;
        channels[_tag].message = scheduledMedia[idx].message;
        _scheduledMedia[_tag].remove(idx);
    }

    function claimLotteryRevenue(address _token) external {
        require(msg.sender == lotteryAddress);
        if (_token == IContract(contractAddress).token()) lotteryRevenue = 0;
        IERC20(_token).safeTransfer(msg.sender, lotteryRevenue);
    }

    function claimTreasuryRevenue(address _token, uint _amount) external {
        require(msg.sender == IAuth(contractAddress).devaddr_());
        if (_token == IContract(contractAddress).token()) treasury -= _amount;
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }
    
    function mint(address _token) external returns(uint) {
        require(erc20(_token).balanceOf(msg.sender) >= 
        IRamp(IContract(contractAddress).rampHelper()).convert(_token, minToMint));
        address profile = IContract(contractAddress).profile();
        uint _profileId = IProfile(profile).addressToProfileId(msg.sender);
        require(IProfile(profile).isUnique(_profileId) && !isMinted[_profileId]);
        isMinted[_profileId] = true;
        notes[tokenId] = RampNote({
            token: _token,
            profileId: _profileId,
            mintedAt: block.timestamp
        });
        _safeMint(msg.sender, tokenId, msg.data);
        IRamp(IContract(contractAddress).rampHelper()).emitUpdateMiscellaneous(
            1,
            _profileId,
            "",
            "",
            tokenId,
            0,
            _token,
            ""
        );
        return tokenId++;
    }

    function burn(uint _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender);
        _burn(_tokenId);
        delete isMinted[IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender)];
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }

    function _constructTokenURI(uint _tokenId, address _token, string[] memory description, string[] memory optionNames, string[] memory optionValues) internal view returns(string memory) {
        return IMarketPlace(IContract(contractAddress).nftSvg()).constructTokenURI(
            _tokenId,
            "",
            _token,
            ownerOf(_tokenId),
            ownerOf(_tokenId),
            address(0x0),
            getMedia(_tokenId),
            optionNames,
            optionValues,
            description
        );
    }

    function tokenURI(uint _tokenId) public override view returns (string memory output) {
        uint idx;
        string[] memory optionNames = new string[](4);
        string[] memory optionValues = new string[](4);
        uint decimals = uint(IMarketPlace(notes[_tokenId].token).decimals());
        uint balance = erc20(notes[_tokenId].token).balanceOf(ownerOf(_tokenId));
        optionValues[idx++] = toString(_tokenId);
        optionNames[idx] = "PID";
        optionValues[idx++] = toString(notes[_tokenId].profileId);
        optionNames[idx] = "Start";
        optionValues[idx++] = toString(notes[_tokenId].mintedAt);
        optionNames[idx] = "Amount";
        optionValues[idx++] = string(abi.encodePacked(toString(balance/10**decimals), " " ,IMarketPlace(notes[_tokenId].token).symbol()));
        string[] memory _description = new string[](1);
        _description[0] = "This note grants you rights only accessible to others that have minted this currency";
        output = _constructTokenURI(
            _tokenId, 
            notes[_tokenId].token,
            _description,
            optionNames, 
            optionValues 
        );
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

    function _sumArr(uint[] memory _arr) internal pure returns(uint _total) {
        for (uint i = 0; i < _arr.length; i++) {
            _total += _arr[i];
        }
    }

}

contract ExtraToken is AML {
    address public minter;

    constructor(
        string memory _name, 
        string memory _symbol,
        address _devaddr,
        address _contractAddress
    ) AML(_contractAddress, _devaddr, _name, _symbol) {}

    modifier onlyMinter() {
        require(msg.sender == minter);
        _;
    }

    function updateMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    /// @dev Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyMinter {
        super._mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public onlyMinter {
        super._burn(_from, _amount);
    }
}

contract ExtraTokenFactory {
    address contractAddress;

    constructor(address _contractAddress) {
        contractAddress = _contractAddress;
    }

    function mintExtraToken(string memory _name, string memory _symbol, address _devaddr) external returns(address) {
        require(IRamp(IContract(contractAddress).rampHelper()).trustWorthyAuditors(msg.sender));
        address _newToken = address(new ExtraToken(_name, _symbol, _devaddr, contractAddress));
        return _newToken;
    }
}

contract RampFactory {
    address public contractAddress;

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }

    function createGauge(address _devaddr) external {
        address rampHelper = IContract(contractAddress).rampHelper();
        address last_gauge = address(new Ramp(
            _devaddr,
            rampHelper,
            contractAddress
        ));
        IRamp(rampHelper).updateGauge(last_gauge, _devaddr);
    }
}
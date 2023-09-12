// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Library.sol";

contract StakeMarket {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    struct StakeNote {
        uint due;
        uint nextDue;
        uint stakeId;
        address token;
    }
    bool public check;
    mapping(uint => address) private taxContracts;
    mapping(uint => StakeStatus) public stakeStatus;
    mapping(uint => StakeNote) public notes;
    mapping(uint => EnumerableSet.UintSet) private _stakeTokens;
    uint private stakeId = 1;
    mapping(uint => Stake) private stakes;
    mapping(uint => bool) public isStake;
    mapping(uint => bool) public closedStake;
    mapping(uint => EnumerableSet.UintSet) private partners;
    mapping(address => uint) public treasuryFees;
    address contractAddress;
    mapping(uint => EnumerableSet.UintSet) internal _stakesApplication;
    mapping(uint => Application) public stakesApplication;
    mapping(uint => uint) public waitingPeriodDeadline;
    mapping(uint => uint) public stakesBalances;

    event StakeCreated(uint indexed stakeId, address owner, uint time, string stakeSource);
    event UpdateRequirements(
        uint indexed stakeId,
        string terms,
        string countries,
        string cities,
        string products
    );
    event UpdateOwner(uint indexed stakeId, address _newOwner);
    event CancelStake(uint indexed stakeId, address owner, uint time);
    event LockStake(uint indexed stakeId, uint partnerStakeId, uint time, bool closedStake);
    event ApplyToStake(uint indexed stakeId, address user, uint partnerStakeId, uint time);
    event DeleteApplication(uint indexed stakeId, address user, uint applicationId);
    event SwitchStake(address indexed user, uint pool, bool closedStake);
    event AddToStake(uint indexed stakeId, address owner, uint amount, uint time);
    event UnlockStake(uint indexed stakeId, address owner, uint amount, uint time);
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

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }

    function _profile() internal view returns(address) {
        return IContract(contractAddress).profile();
    }

    function _noteContract() internal view returns(address) {
        return IContract(contractAddress).stakeMarketNote();
    }
    
    function _voter() internal view returns(address) {
        return IContract(contractAddress).stakeMarketVoter();
    }

    function getOwner(uint _stakeId) external view returns(address) {
        return stakes[_stakeId].owner;
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

    function _tradingFee() internal view returns(uint) {
        return IStakeMarket(IContract(contractAddress).stakeMarketNote()).tradingFee();
    }

    function _bufferTime() internal view returns(uint) {
        return IStakeMarket(IContract(contractAddress).stakeMarketNote()).bufferTime();
    }

    function getStake(uint _stakeId) external view returns(Stake memory) {
        return stakes[_stakeId];
    }

    function createStake(
        address[6] memory _addrs, //[_ve,_token,_source,_referrer,collection,user]
        string memory _tokenId,
        string memory _stakeSource,
        uint[] memory _options,
        uint _userTokenId, 
        uint _identityTokenId, 
        uint[7] memory _bankInfo, //[amountPayable,amountReceivable,periodPayable,periodReceivable,waitingPeriod,startPayable,startReceivable]
        bool _requireUpfrontPayment
    ) public returns (uint) {
        uint _fees;
        if (_requireUpfrontPayment) {
            IERC20(_addrs[1]).safeTransferFrom(msg.sender, address(this), _bankInfo[1]);
            _fees = _bankInfo[1] * _tradingFee() / 10000;
            treasuryFees[_addrs[1]] += _fees;
            stakesBalances[stakeId] = _bankInfo[1];
        }
        stakes[stakeId] = Stake({
            ve: _addrs[0],
            metadata: MetaData({
                source: _addrs[2],
                collection: _addrs[4],
                referrer: _addrs[3],
                userTokenId: _userTokenId,
                identityTokenId: _identityTokenId,
                options: _options
            }),
            token: _addrs[1],
            tokenId: _tokenId,
            owner: _addrs[5],
            parentStakeId: stakeId,
            bank: Bank({
                startPayable: block.timestamp + _bankInfo[5],
                startReceivable: block.timestamp + _bankInfo[6],
                amountPayable: _bankInfo[0],
                amountReceivable: _bankInfo[1],
                periodPayable: _bankInfo[2],
                periodReceivable: _bankInfo[3],
                paidPayable: 0,
                paidReceivable: _requireUpfrontPayment ? _bankInfo[1] - _fees : 0,
                gasPercent: 0,
                stakeRequired: 0,
                waitingPeriod: _bankInfo[4]
            }),
            profileId: 0,
            bountyId: 0,
            profileRequired: false,
            bountyRequired: false,
            ownerAgreement: AGREEMENT.undefined
        });
        isStake[stakeId] = true;
        emit StakeCreated(stakeId, msg.sender, block.timestamp, _stakeSource);
        return stakeId++;
    }

    function updateRequirements(
        uint _stakeId,
        uint _profileId,
        uint _bountyId,
        bool _profileRequired,
        bool _bountyRequired,
        uint _stakeRequired,
        uint _gasPercent,
        string memory _terms,
        string memory _countries,
        string memory _cities,
        string memory _products
    ) external {
        require(stakes[_stakeId].owner == msg.sender);
        address trustBountyHelper = IContract(contractAddress).trustBountyHelper();
        if (_profileId > 0) {
            require(IProfile(_profile()).addressToProfileId(msg.sender) == _profileId && _profileId > 0);
        }
        if (_bountyId > 0) {
            (address owner,,,address claimableBy,,,,,,) = ITrustBounty(IContract(contractAddress).trustBounty()).bountyInfo(_bountyId);
            require(owner == msg.sender && claimableBy == address(0x0));
        }
        stakes[_stakeId].profileRequired = _profileRequired;
        stakes[_stakeId].bountyRequired = _bountyRequired;
        stakes[_stakeId].bank.stakeRequired = _stakeRequired;
        stakes[_stakeId].bank.gasPercent = _gasPercent;
        stakes[_stakeId].profileId = _profileId;
        stakes[_stakeId].bountyId = _bountyId;
        if (stakes[_stakeId].bountyId == 0 && _bountyId > 0) {
            ITrustBounty(trustBountyHelper).attach(_bountyId);
        } else if (stakes[_stakeId].bountyId > 0 && _bountyId == 0) {
            ITrustBounty(trustBountyHelper).detach(_bountyId);
        }
        emit UpdateRequirements(_stakeId,_terms,_countries,_cities,_products);
    }

    function updateOwner(uint _stakeId, address _newOwner) external {
        uint _profileId = IProfile(_profile()).addressToProfileId(msg.sender);
        require(stakes[_stakeId].profileId == _profileId && _profileId > 0);
        stakes[_stakeId].owner = _newOwner;
        emit UpdateOwner(_stakeId, _newOwner);
    }

    function updateTaxContract(uint _stakeId, address _taxContract) external {
        require(stakes[_stakeId].owner == msg.sender);
        taxContracts[_stakeId] = _taxContract;
    }

    function createAndApply(
        address _user,
        uint[7] memory _bankInfo,
        uint _deadline,
        uint _identityTokenId,
        uint _partnerStakeId,
        string memory _stakeSource
    ) external {
        address[6] memory _addrs;
        _addrs[0] = stakes[_partnerStakeId].ve;
        _addrs[1] = stakes[_partnerStakeId].token;
        _addrs[2] = stakes[_partnerStakeId].metadata.source;
        _addrs[3] = stakes[_partnerStakeId].metadata.referrer;
        _addrs[4] = stakes[_partnerStakeId].metadata.collection;
        _addrs[5] = _user;
        uint _stakeId = createStake(
            _addrs, //[_ve,_token,_source,_referrer, collection]
            stakes[_partnerStakeId].tokenId,
            _stakeSource,
            stakes[_partnerStakeId].metadata.options,
            stakes[_partnerStakeId].metadata.userTokenId,
            stakes[_partnerStakeId].metadata.identityTokenId,
            _bankInfo,
            stakes[_partnerStakeId].bank.stakeRequired > 0
        );
        applyToStake(_stakeId, _deadline, _identityTokenId, _partnerStakeId);
    }

    function updateStaked(uint _stakeId, uint _amountPayable, uint _amountReceivable, address _source) external {
        require(stakes[_stakeId].owner == msg.sender && waitingPeriodDeadline[_stakeId] != 0);
        require(stakes[_stakeId].ownerAgreement != AGREEMENT.disagreement);
        
        stakes[_stakeId].metadata.source = _source;
        stakes[_stakeId].bank.amountPayable = _amountPayable;
        stakes[_stakeId].bank.amountReceivable = _amountReceivable;
    }

    function cancelStake(uint _stakeId) external lock {
        require(isStake[_stakeId] && stakes[_stakeId].owner == msg.sender);
        require(stakes[_stakeId].ownerAgreement == AGREEMENT.undefined);
        IERC20(stakes[_stakeId].token).safeTransfer(
            stakes[_stakeId].owner, 
            stakes[_stakeId].bank.paidReceivable - stakes[_stakeId].bank.paidPayable
        );
        isStake[_stakeId] = false;
        delete stakes[_stakeId];
        emit CancelStake(_stakeId, msg.sender, block.timestamp);
    }

    function switchStake(uint _stakeId) external {
        require(msg.sender == stakes[_stakeId].owner);
        closedStake[_stakeId] = !closedStake[_stakeId];

        emit SwitchStake(msg.sender, _stakeId, !closedStake[_stakeId]);
    }

    function getAllApplications(uint _stakeId, uint _start) external view returns(uint[] memory _stakeIds) {
        _stakeIds = new uint[](_stakesApplication[_stakeId].length() - _start);
        for (uint i = _start; i < _stakesApplication[_stakeId].length(); i++) {
            _stakeIds[i] = _stakesApplication[_stakeId].at(i);
        }  
    }

    function getAllPartners(uint _stakeId, uint _start) external view returns(uint[] memory p) {
        p = new uint[](partners[_stakeId].length() - _start);
        for (uint i = _start; i < partners[_stakeId].length(); i++) {
            p[i] = partners[_stakeId].at(i);
        }
    }

    function applyToStake(
        uint _stakeId,
        uint _deadline,
        uint _identityTokenId,
        uint _partnerStakeId
    ) internal {
        address noteContract = _noteContract();
        IStakeMarket(noteContract).checkIdentityProof(_partnerStakeId, _identityTokenId, msg.sender);
        require(isStake[_stakeId] && isStake[_partnerStakeId] && !closedStake[_partnerStakeId]);
        require(stakes[_partnerStakeId].bank.stakeRequired <= stakes[_stakeId].bank.amountReceivable);
        stakes[_partnerStakeId].ve = stakes[_stakeId].ve;
        stakes[_partnerStakeId].token = stakes[_stakeId].token;
        stakes[_partnerStakeId].bank.startPayable = stakes[_stakeId].bank.startReceivable;
        stakes[_partnerStakeId].bank.startReceivable = stakes[_stakeId].bank.startPayable;
        stakes[_partnerStakeId].bank.waitingPeriod = stakes[_stakeId].bank.waitingPeriod;
        if (IStakeMarket(noteContract).isMarketPlace(stakes[_partnerStakeId].metadata.source)) {
            stakes[_stakeId].metadata.source = stakes[_partnerStakeId].metadata.source;
        }
        _stakesApplication[_partnerStakeId].add(_stakeId);
        stakesApplication[_stakeId] = Application({
            status: ApplicationStatus.Pending,
            stakeId: _stakeId,
            deadline: block.timestamp + _deadline
        });

        emit ApplyToStake(_stakeId, msg.sender, _partnerStakeId, block.timestamp);
    }

    function lockStake(
        uint _applicationId,
        uint _stakeId,
        uint _startPayable,
        bool _closeStake
    ) external {
        require(msg.sender == stakes[_stakeId].owner);
        require(_stakesApplication[_stakeId].contains(_applicationId));
        require(stakesApplication[_applicationId].status == ApplicationStatus.Pending);
        if (stakesApplication[_applicationId].deadline < block.timestamp) {
            _stakesApplication[_stakeId].remove(_applicationId);
            delete stakesApplication[_applicationId];
            return;
        }
        require(stakes[_applicationId].ownerAgreement == AGREEMENT.undefined);
        partners[_stakeId].add(_applicationId);
        stakes[_stakeId].ownerAgreement = AGREEMENT.pending;
        if (_startPayable > 0) {
            stakes[_stakeId].bank.startPayable = _startPayable;
            stakes[_applicationId].bank.startReceivable = _startPayable;
        }
        stakes[_applicationId].parentStakeId = _stakeId;
        stakes[_applicationId].ownerAgreement = AGREEMENT.pending;
        stakesBalances[_stakeId] += stakesBalances[_applicationId];
        stakesApplication[_applicationId].status = ApplicationStatus.Accepted;
        _stakesApplication[_stakeId].remove(_applicationId);
        closedStake[_stakeId] = _closeStake;
        
        emit LockStake(_stakeId, _applicationId, block.timestamp, _closeStake);
    }

    function deleteApplication(uint _stakeId, uint _partnerStakeId) external {
        require(stakes[_stakeId].owner == msg.sender);

        _stakesApplication[_partnerStakeId].remove(_stakeId);
        delete stakesApplication[_stakeId];
        emit DeleteApplication(_stakeId, msg.sender, _partnerStakeId);
    }

    function updateStakeFromVoter(uint _winnerId, uint _loserId) external {
        require(_voter() == msg.sender);
        _updateStake(_winnerId, _loserId, AGREEMENT.good, true);
    }

    function _updateStake(uint _winnerId, uint _loserId, AGREEMENT _agreement, bool _fromVote) internal {
        require(isStake[_winnerId] && stakes[_winnerId].ownerAgreement != AGREEMENT.undefined);
        require(_agreement == AGREEMENT.good || _agreement == AGREEMENT.notgood);

        if (!_fromVote) {
            stakes[_winnerId].ownerAgreement = _agreement;
        } else {
            stakeStatus[stakes[_winnerId].parentStakeId].winnerId = _winnerId;
            stakeStatus[stakes[_winnerId].parentStakeId].loserId = _loserId;
        }
    }

    function updateStatusOrAppeal(
        uint _attackerId, 
        string memory _title, 
        string memory _content,
        string memory _tags
    ) external {
        if (stakeStatus[stakes[_attackerId].parentStakeId].endTime < block.timestamp) {
            stakeStatus[stakes[_attackerId].parentStakeId].status = StakeStatusEnum.AtPeace;
            uint _winnerId = stakeStatus[stakes[_attackerId].parentStakeId].winnerId;
            uint _loserId = stakeStatus[stakes[_attackerId].parentStakeId].loserId;
            stakes[_winnerId].ownerAgreement = AGREEMENT.good;
            stakes[_loserId].bank.amountPayable = stakes[_winnerId].bank.amountReceivable;
            stakes[_loserId].bank.amountReceivable = stakes[_winnerId].bank.amountPayable;
            stakes[_loserId].ownerAgreement = AGREEMENT.good;
        } else {
            require(msg.sender == stakes[_attackerId].owner);
            require(stakeStatus[stakes[_attackerId].parentStakeId].loserId == _attackerId);
            stakeStatus[stakes[_attackerId].parentStakeId].endTime = block.timestamp + _bufferTime();
            uint _defenderId = stakeStatus[stakes[_attackerId].parentStakeId].winnerId;
            uint _attackerGas = stakes[_attackerId].bank.paidReceivable * stakes[_attackerId].bank.gasPercent / 10000;
            uint _defenderGas = stakes[_defenderId].bank.paidReceivable * stakes[_defenderId].bank.gasPercent / 10000;
            IERC20(stakes[_attackerId].token).safeTransferFrom(
                address(msg.sender), 
                address(this), 
                _attackerGas + _defenderGas
            );
            address voter = _voter();
            erc20(stakes[_attackerId].token).approve(voter, _attackerGas + _defenderGas);
            IStakeMarketVoter(voter).createGauge(
                stakes[_attackerId].ve,
                stakes[_attackerId].token,
                _attackerId,
                _defenderId,
                _attackerGas + _defenderGas,
                _title,
                _content,
                _tags
            );
        }
    }

    function createGauge(
        uint _attackerId, 
        uint _defenderId, 
        string memory _title, 
        string memory _content,
        string memory _tags
    ) external {
        stakeStatus[stakes[_attackerId].parentStakeId].status = StakeStatusEnum.AtWar;
        require(msg.sender == stakes[_attackerId].owner && _defenderId != 0);
        address voter = _voter();
        require(!IStakeMarketVoter(voter).isGauge(stakes[_attackerId].ve, _attackerId) &&
                !IStakeMarketVoter(voter).isGauge(stakes[_attackerId].ve, _defenderId));
        if (waitingPeriodDeadline[_attackerId] == 0) {
            uint _period = stakes[_attackerId].bank.waitingPeriod;
            waitingPeriodDeadline[_attackerId] = block.timestamp + _period / Math.max(_period,1) * _period;
            waitingPeriodDeadline[_defenderId] = block.timestamp + _period / Math.max(_period,1) * _period;
        } else {
            require(waitingPeriodDeadline[_attackerId] < block.timestamp);
            stakes[_attackerId].ownerAgreement = AGREEMENT.disagreement;
            stakes[_defenderId].ownerAgreement = AGREEMENT.disagreement;
            uint _attackerGas = stakes[_attackerId].bank.paidReceivable * stakes[_attackerId].bank.gasPercent / 10000;
            uint _defenderGas = stakes[_defenderId].bank.paidReceivable * stakes[_defenderId].bank.gasPercent / 10000;
            stakes[_attackerId].bank.paidReceivable -= _attackerGas;
            stakes[_defenderId].bank.paidReceivable -= _defenderGas;
            stakesBalances[stakes[_attackerId].parentStakeId] -= (_attackerGas + _defenderGas);
            waitingPeriodDeadline[_attackerId] = 0;
            waitingPeriodDeadline[_defenderId] = 0;
            stakeStatus[stakes[_attackerId].parentStakeId].endTime = block.timestamp + _bufferTime();
            erc20(stakes[_attackerId].token).approve(voter, _attackerGas + _defenderGas);
            IStakeMarketVoter(voter).createGauge(
                stakes[_attackerId].ve,
                stakes[_attackerId].token,
                _attackerId,
                _defenderId,
                _attackerGas + _defenderGas,
                _title,
                _content,
                _tags
            );
        }
    }
    
    function addToStake(uint _stakeId, uint _amount) external {
        if (stakes[_stakeId].ownerAgreement == stakes[stakes[_stakeId].parentStakeId].ownerAgreement) {
            _amount = _amount > 0 ? _amount : stakes[_stakeId].bank.amountReceivable;
            (uint dueReceivable,,) = IStakeMarket(_noteContract()).getDueReceivable(_stakeId, 0);
            _amount = _amount == 0 ? dueReceivable : Math.max(_amount, dueReceivable);
            IERC20(stakes[_stakeId].token).safeTransferFrom(
                address(msg.sender), 
                address(this), 
                _amount
            );
            uint _fees = _amount * _tradingFee() / 10000;
            treasuryFees[stakes[_stakeId].token] += _fees;
            stakesBalances[stakes[_stakeId].parentStakeId] += _amount;
            stakes[_stakeId].bank.paidReceivable += _amount - _fees;
        }
        emit AddToStake(_stakeId, msg.sender, _amount, block.timestamp);
    }

    function withdrawFees(address _token) external {
        // require(msg.sender == );
        IERC20(_token).safeTransfer(IAuth(contractAddress).devaddr_(), treasuryFees[_token]);
        treasuryFees[_token] = 0;
    }

    function updateStake(uint _stakeId, AGREEMENT agreement) external {
        require(msg.sender == stakes[_stakeId].owner);
        _updateStake(_stakeId, 0, agreement, false);
    }
    
    function unlockStake(uint _stakeId, uint _amount, bool _removePartner) external lock {
        require(msg.sender == stakes[_stakeId].owner);
        address noteContract = _noteContract();
        (uint duePayable,,) = IStakeMarket(noteContract).getDuePayable(_stakeId, 0);
        if (stakes[_stakeId].ownerAgreement == AGREEMENT.good &&
            stakes[stakes[_stakeId].parentStakeId].ownerAgreement == AGREEMENT.good &&
            stakeStatus[stakes[_stakeId].parentStakeId].status == StakeStatusEnum.AtPeace &&
            duePayable > 0
        ) {
            duePayable = Math.min(duePayable, stakesBalances[stakes[_stakeId].parentStakeId]);
            _amount = _amount == 0 ? duePayable : Math.min(_amount, duePayable);
            stakesBalances[stakes[_stakeId].parentStakeId] -=  _amount;
            if (_removePartner) {
                (uint dueReceivable,,) = IStakeMarket(noteContract).getDueReceivable(_stakeId, 0);
                require(dueReceivable == 0);
                isStake[_stakeId] = false;
                partners[stakes[_stakeId].parentStakeId].remove(_stakeId);
            }
            stakes[_stakeId].bank.paidPayable += _amount;
            if (IStakeMarket(noteContract).isMarketPlace(stakes[_stakeId].metadata.source)) {
                erc20(stakes[_stakeId].token).approve(
                    stakes[_stakeId].metadata.source, 
                    _amount
                );
                IMarketPlace(stakes[_stakeId].metadata.source).buyWithContract(
                    stakes[stakes[_stakeId].parentStakeId].metadata.collection,
                    stakes[_stakeId].owner,
                    stakes[_stakeId].metadata.referrer,
                    stakes[_stakeId].tokenId,
                    stakes[_stakeId].metadata.userTokenId,
                    stakes[_stakeId].metadata.identityTokenId,
                    stakes[_stakeId].metadata.options
                );
            } else {
                if (taxContracts[_stakeId] != address(0x0)) {
                    IBILL(taxContracts[_stakeId]).notifyCredit(
                        address(this),
                        stakes[_stakeId].owner, 
                        _amount
                    );
                }
                IERC20(stakes[_stakeId].token).safeTransfer(
                    stakes[_stakeId].owner, 
                    _amount
                );
            }
        }
        emit UnlockStake(_stakeId, msg.sender, _amount, block.timestamp);
    }
    
    function mintNote(uint _stakeId, uint _numPeriods) external {
        require(msg.sender == stakes[_stakeId].owner);
        (uint duePayable, uint nextDue,) = IStakeMarket(_noteContract()).getDuePayable(_stakeId, _numPeriods);
        uint _tokenId = IStakeMarket(IContract(contractAddress).stakeMarketHelper()).safeMint(msg.sender, _stakeId);
        notes[_tokenId] = StakeNote({
            due: duePayable,
            nextDue: nextDue,
            token: stakes[_stakeId].token,
            stakeId: _stakeId
        });
        _stakeTokens[_stakeId].add(_tokenId);
    }

    function claimRevenueFromNote(address _owner, uint _tokenId) external lock {
        require(msg.sender == IContract(contractAddress).stakeMarketHelper());
        require(notes[_tokenId].nextDue < block.timestamp);
        require(notes[_tokenId].due <= stakesBalances[stakes[notes[_tokenId].stakeId].parentStakeId]);
        stakesBalances[stakes[notes[_tokenId].stakeId].parentStakeId] -= notes[_tokenId].due;
        uint payswapFees = notes[_tokenId].due * _tradingFee() / 10000;
        IERC20(notes[_tokenId].token).safeTransfer(_owner, notes[_tokenId].due - payswapFees);
        treasuryFees[notes[_tokenId].token] += payswapFees;
        _stakeTokens[notes[_tokenId].stakeId].remove(_tokenId);
        delete notes[_tokenId];
    }
}

contract StakeMarketNote {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    struct IOUNote {
        uint ownerStakeId;
        uint creatorStakeId;
        uint created;
        string tag;
    }
    mapping(uint => IOUNote) public IOU;
    uint public bufferTime = 14 days;
    uint public tradingFee = 100;
    address public contractAddress;
    mapping(uint => EnumerableSet.AddressSet) private gaugeTrustWorthyAuditors;
    mapping(uint => mapping(bytes32 => bool)) public blackListedIdentities;
    mapping(uint => mapping(bytes32 => uint)) public identityProofs;
    mapping(uint => IdentityProof) internal gaugeIdentityProof;

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }
    
    function _stakeMarket() internal view returns(address) {
        return IContract(contractAddress).stakeMarket();
    }

    function _ssi() internal view returns(address) {
        return IContract(contractAddress).ssi();
    }
    
    function _auditorNote() internal view returns(address) {
        return IContract(contractAddress).auditorNote();
    }

    function verifyNFT(uint _tokenId, uint _creatorStakeId, string memory _tag) external view returns(uint) {
        if (
            IOU[_tokenId].created > 0 &&
            IOU[_tokenId].creatorStakeId == _creatorStakeId &&
            (
                keccak256(abi.encodePacked(_tag)) == keccak256(abi.encodePacked("")) ||
                keccak256(abi.encodePacked(_tag)) == keccak256(abi.encodePacked(IOU[_tokenId].tag))
            ) 
        ) {
            return 1;
        }
        return 0;
    }

    function isMarketPlace(address _source) external view returns(bool) {
        return _source == IContract(contractAddress).paywallMarketTrades() ||
        _source == IContract(contractAddress).nftMarketTrades() ||
        _source == IContract(contractAddress).marketTrades();
    }

    function createIOU(uint _stakeId, uint _partnerStakeId, uint _start, string memory _tag) external {
        address stakeMarket = _stakeMarket();
        Stake memory stake = IStakeMarket(stakeMarket).getStake(_stakeId);
        require(stake.owner == msg.sender, "Only owner");
        uint[] memory _partners = IStakeMarket(stakeMarket).getAllPartners(_stakeId, _start);
        bool found;
        for (uint i = 0; i < _partners.length; i++) {
            if (_partners[i] == _partnerStakeId) {
                found = true;
                break;
            }
        }
        if (found) {
            Stake memory partnerStake = IStakeMarket(stakeMarket).getStake(_partnerStakeId);
            uint _tokenId = IStakeMarket(IContract(contractAddress).stakeMarketHelper()).safeMint(partnerStake.owner, _stakeId);
            IOU[_tokenId] = IOUNote({
                creatorStakeId: _stakeId,
                ownerStakeId: _partnerStakeId,
                tag: _tag,
                created: block.timestamp
            });
        }
    }

    function updateGaugeTrustWorthyAuditors(uint _stakeId, address[] memory _gauges, bool _add) external {
        Stake memory stake = IStakeMarket(_stakeMarket()).getStake(_stakeId);
        require(stake.owner == msg.sender);
        for (uint i = 0; i < _gauges.length; i++) {
            if (_add) {
                gaugeTrustWorthyAuditors[_stakeId].add(_gauges[i]);
            } else {
                gaugeTrustWorthyAuditors[_stakeId].remove(_gauges[i]);
            }
        }
    }

    function getAllGaugeTrustWorthyAuditors(uint _stakeId) external view returns(address[] memory _auditors) {
        _auditors = new address[](gaugeTrustWorthyAuditors[_stakeId].length());
        for (uint i = 0; i < gaugeTrustWorthyAuditors[_stakeId].length(); i++) {
            _auditors[i] = gaugeTrustWorthyAuditors[_stakeId].at(i);
        }
    }

    function checkIdentityProof(
        uint _stakeId,
        uint _identityTokenId,
        address _owner
    ) external {
        string memory _valueName = gaugeIdentityProof[_stakeId].valueName;
        bool _dataKeeperOnly = gaugeIdentityProof[_stakeId].dataKeeperOnly;
        COLOR _minIDBadgeColor = gaugeIdentityProof[_stakeId].minIDBadgeColor;
        string memory _requiredIndentity = gaugeIdentityProof[_stakeId].requiredIndentity;
        bool _onlyTrustWorthyAuditors = gaugeIdentityProof[_stakeId].onlyTrustWorthyAuditors;
        uint _maxUse = gaugeIdentityProof[_stakeId].maxUse;
        _checkIdentityProof(
            _owner, 
            _stakeId, 
            _identityTokenId,
            _valueName,
            _requiredIndentity,
            _onlyTrustWorthyAuditors,
            _dataKeeperOnly,
            _maxUse,
            _minIDBadgeColor
        );
    }

    function _checkIdentityProof(
        address _owner, 
        uint _stakeId, 
        uint _identityTokenId,
        string memory _valueName,
        string memory _requiredIndentity,
        bool _onlyTrustWorthyAuditors,
        bool _dataKeeperOnly,
        uint _maxUse,
        COLOR _minIDBadgeColor
    ) internal {
        if (keccak256(abi.encodePacked(_valueName)) != keccak256(abi.encodePacked(""))) {
            require(ve(_ssi()).ownerOf(_identityTokenId) == _owner);
            SSIData memory metadata = ISSI(_ssi()).getSSIData(_identityTokenId);
            require(metadata.deadline > block.timestamp);
            (string memory _ssid, address gauge,address gauge2) = _checkProfiles(metadata, _dataKeeperOnly, _minIDBadgeColor);
            require(keccak256(abi.encodePacked(metadata.question)) == keccak256(abi.encodePacked(_requiredIndentity))); 
            require(keccak256(abi.encodePacked(metadata.answer)) == keccak256(abi.encodePacked(_valueName)));
            _updateIdentityCode(
                _stakeId,
                keccak256(abi.encodePacked(_ssid)),
                _onlyTrustWorthyAuditors,
                _maxUse,
                gauge,
                gauge2
            );
        }
    }

    function _checkProfiles(SSIData memory metadata, bool _dataKeeperOnly, COLOR _minIDBadgeColor) internal view returns(string memory,address,address) {
        SSIData memory metadata2 = ISSI(_ssi()).getSSID(metadata.senderProfileId);
        (address gauge, bool dk, COLOR _badgeColor) = IAuditor(_auditorNote()).getGaugeNColor(metadata.auditorProfileId);
        (address gauge2, bool dk2, COLOR _badgeColor2) = IAuditor(_auditorNote()).getGaugeNColor(metadata2.auditorProfileId);
        require(_badgeColor >= _minIDBadgeColor && _badgeColor2 >= _minIDBadgeColor);
        if (_dataKeeperOnly) require(dk && dk2);
        return (metadata2.answer, gauge, gauge2);
    }

    function _updateIdentityCode(
        uint _stakeId, 
        bytes32 _identityCode,
        bool onlyTrustWorthyAuditors,
        uint _maxUse,
        address _gauge,
        address _gauge2
    ) internal {
        require(!onlyTrustWorthyAuditors || (
            gaugeTrustWorthyAuditors[_stakeId].contains(_gauge) && 
            gaugeTrustWorthyAuditors[_stakeId].contains(_gauge2)
        ));
        require(!blackListedIdentities[0][_identityCode] && !blackListedIdentities[_stakeId][_identityCode]);
        if (_maxUse > 0) {
            require(_identityCode != keccak256(abi.encodePacked("")));
            require(identityProofs[_stakeId][_identityCode] < _maxUse);
        }
        identityProofs[_stakeId][_identityCode] += 1;
    }

    function addIdentityProofToStake(
        uint _stakeId,
        uint _minIDBadgeColor,
        string memory _valueName,
        uint _maxUse,
        bool _dataKeeperOnly,
        bool _onlyTrustWorthyAuditors,
        string memory _requiredIndentity
    ) external {
        Stake memory stake = IStakeMarket(_stakeMarket()).getStake(_stakeId);
        require(stake.owner == msg.sender, "Only sender!");

        gaugeIdentityProof[_stakeId].valueName = _valueName;
        gaugeIdentityProof[_stakeId].minIDBadgeColor = COLOR(_minIDBadgeColor);
        gaugeIdentityProof[_stakeId].dataKeeperOnly = _dataKeeperOnly;
        gaugeIdentityProof[_stakeId].requiredIndentity = _requiredIndentity;
        gaugeIdentityProof[_stakeId].maxUse = _maxUse;
        gaugeIdentityProof[_stakeId].onlyTrustWorthyAuditors = _onlyTrustWorthyAuditors;
        
    }

    function updateBlacklistedIdentities(uint _stakeId, uint[] memory userProfileIds, bool blacklist) external {
        Stake memory stake = IStakeMarket(_stakeMarket()).getStake(_stakeId);
        if (_stakeId > 0) {
            require(stake.owner == msg.sender);
        } else {
            require(msg.sender == IAuth(contractAddress).devaddr_());
        }
        for (uint i = 0; i < userProfileIds.length; i++) {
            SSIData memory metadata = ISSI(_ssi()).getSSID(userProfileIds[i]);
            if (keccak256(abi.encodePacked(metadata.answer)) != keccak256(abi.encodePacked(""))) {
                blackListedIdentities[_stakeId][keccak256(abi.encodePacked(metadata.answer))] = blacklist;
            }
        }
    }

    function updateTradingFee(uint _tradingFee) external {
        require(msg.sender == IAuth(contractAddress).devaddr_());
        tradingFee = _tradingFee;
    }

    function setBufferTime(uint _bufferTime) external {
        require(msg.sender == IAuth(contractAddress).devaddr_());
        bufferTime = _bufferTime;
    }

    function getNumPeriods(uint tm1, uint tm2, uint _period) public pure returns(uint) {
        if (tm1 == 0 || tm2 == 0 || tm2 < tm1) return 0;
        return _period > 0 ? (tm2 - tm1) / _period : 1;
    }

    function getDuePayable(uint _stakeId, uint _numPeriods) external view returns(uint, uint, int) {
        Stake memory stake = IStakeMarket(_stakeMarket()).getStake(_stakeId);
        uint numPeriods = getNumPeriods(
            stake.bank.startPayable, 
            block.timestamp, 
            stake.bank.periodPayable
        );
        numPeriods += _numPeriods;
        uint nextDue = stake.bank.startPayable + stake.bank.periodPayable * Math.max(1,numPeriods);
        uint due = nextDue < block.timestamp ? stake.bank.amountPayable * numPeriods - stake.bank.paidPayable : 0;
        return (
            due, // due
            stake.bank.periodPayable == 0 ? uint(0) : nextDue, // next
            stake.bank.periodPayable == 0 ? int(0) : int(block.timestamp) - int(nextDue) //late or seconds in advance
        );
    }
    
    function getDueReceivable(uint _stakeId, uint _numPeriods) external view returns(uint, uint, int) {   
        Stake memory stake = IStakeMarket(_stakeMarket()).getStake(_stakeId);
        uint numPeriods = getNumPeriods(
            stake.bank.startReceivable, 
            block.timestamp, 
            stake.bank.periodReceivable
        );
        numPeriods += _numPeriods;
        uint nextDue = stake.bank.startReceivable + stake.bank.periodReceivable * Math.max(1,numPeriods);
        uint due = nextDue < block.timestamp ? stake.bank.amountReceivable * numPeriods - stake.bank.paidReceivable : 0;
        return (
            due, // due
            stake.bank.periodReceivable == 0 ? uint(0) : nextDue, // next
            stake.bank.periodReceivable == 0 ? int(0) : int(block.timestamp) - int(nextDue) //late or seconds in advance
        );
    }
}

contract StakeMarketHelper is ERC721Pausable {
    address public contractAddress;
    uint public tokenId = 1;
    constructor() ERC721("StakeMarketNote", "nSTM") {}

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }

    function _stakeMarket() internal view returns(address) {
        return IContract(contractAddress).stakeMarket();
    }

    function safeMint(address _owner, uint _stakeId) external returns(uint) {
        require(msg.sender == IContract(contractAddress).stakeMarketNote() || msg.sender == IContract(contractAddress).stakeMarket());
        _safeMint(_owner, tokenId, msg.data);
        IStakeMarket(IContract(contractAddress).stakeMarket()).emitUpdateMiscellaneous(
            1, 
            _stakeId,
            "",
            "",
            tokenId,
            0,
            address(0),
            ""
        );
        return tokenId++;
    }

    function claimRevenueFromNote(uint _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender);
        IStakeMarket(_stakeMarket()).claimRevenueFromNote(msg.sender, _tokenId);
        _burn(_tokenId); 
    }

    function _getBankInfo(uint[] memory _bankInfo) internal pure returns(uint[7] memory bankInfo) {
        bankInfo[0] = _bankInfo[0];
        bankInfo[1] = _bankInfo[1];
        bankInfo[2] = _bankInfo[2];
        bankInfo[3] = _bankInfo[3];
        bankInfo[4] = _bankInfo[4];
        bankInfo[5] = _bankInfo[5];
        bankInfo[6] = _bankInfo[6];
    }

    function _getOptions(uint[] memory _bankInfo) internal pure returns(uint[] memory _options) {
        _options = new uint[](_bankInfo.length > 10 ? _bankInfo.length - 10 : 0);
        uint idx;
        for (uint i = 10; i < _bankInfo.length; i++) {
            _options[idx++] = _bankInfo[i];
        }
    }

    function buyWithContract(
        address _collection,
        address _user,
        address _referrer,
        string memory _tokenId,
        uint _apply,
        uint[] memory _bankInfo   
    ) external {
        require(IValuePool(IContract(contractAddress).valuepoolHelper()).isGauge(msg.sender));
        address _ve = IValuePool(msg.sender)._ve();
        address token = IValuePool(msg.sender).token();
        uint[7] memory bankInfo = _getBankInfo(_bankInfo);
        address stakeMarket = _stakeMarket();
        erc20(token).approve(stakeMarket, bankInfo[1]);
        if (_apply == 0) {
            address[6] memory _addrs;
            _addrs[0] = _ve;
            _addrs[1] = token;
            _addrs[2] = _bankInfo[9] == 0 
            ? IContract(contractAddress).marketOrders()
            : _bankInfo[9] == 1
            ? IContract(contractAddress).paywallMarketOrders()
            : IContract(contractAddress).nftMarketOrders();
            _addrs[3] = _referrer;
            _addrs[4] = _collection;
            _addrs[5] = _user;
            IStakeMarket(stakeMarket).createStake(
                _addrs, 
                _tokenId,
                "valuepool", 
                _getOptions(_bankInfo),
                _bankInfo[7],
                _bankInfo[8],
                bankInfo,
                true
            );
        } else {
            IStakeMarket(stakeMarket).createAndApply(
                _user,
                bankInfo,
                _bankInfo[7],
                _bankInfo[8],
                _bankInfo[10],
                "valuepool"
            );
        }
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

    function _tokenURI(uint _tokenId) internal view returns (string memory output) {
        (uint due, uint nextDue, uint stakeId, address token) = IStakeMarket(_stakeMarket()).notes(_tokenId);
        uint idx;
        string[] memory optionNames = new string[](6);
        string[] memory optionValues = new string[](6);
        uint decimals = uint(IMarketPlace(token).decimals());
        optionValues[idx++] = toString(_tokenId);
        optionNames[idx] = "Type";
        optionValues[idx++] = "Stake Note";
        optionNames[idx] = "End";
        optionValues[idx++] = toString(nextDue);
        optionNames[idx] = "SID";
        optionValues[idx++] = toString(stakeId);
        optionNames[idx] = "Amount";
        optionValues[idx++] = string(abi.encodePacked(toString(due/10**decimals), " " ,IMarketPlace(token).symbol()));
        optionNames[idx] = "Expired";
        optionValues[idx++] = nextDue < block.timestamp ? "Yes" : "No";
        string[] memory _description = new string[](1);
        _description[0] = "This note gives you access to revenues of the stake owner on the specified stake";
        output = _constructTokenURI(
            _tokenId, 
            token,
            _description,
            optionNames, 
            optionValues 
        );
    }

    function _tokenURIiou(
        uint _tokenId, 
        uint _creatorStakeId,
        uint _ownerStakeId,
        uint _created,
        string memory _tag
    ) internal view returns (string memory output) {
        Stake memory stake = IStakeMarket(IContract(contractAddress).stakeMarket()).getStake(_creatorStakeId);
        uint idx;
        string[] memory optionNames = new string[](9);
        string[] memory optionValues = new string[](9);
        optionValues[idx++] = toString(_tokenId);
        optionNames[idx] = "Type";
        optionValues[idx++] = "IOU";
        optionNames[idx] = "Start";
        optionValues[idx++] = toString(_created);
        // optionValues[idx++] = addressToString(stake.metadata.collection);
        optionNames[idx] = "Product";
        optionValues[idx++] = stake.tokenId;
        optionNames[idx] = "Creator Stake";
        optionValues[idx++] = toString(_creatorStakeId);
        optionNames[idx] = "Creator Profile";
        optionValues[idx++] = toString(stake.profileId);
        optionNames[idx] = "Creator Bounty";
        optionValues[idx++] = toString(stake.bountyId);
        optionNames[idx] = "Owner Stake";
        optionValues[idx++] = toString(_ownerStakeId);
        optionNames[idx] = "Tag";
        optionValues[idx++] = _tag;
        string[] memory _description = new string[](1);
        _description[0] = "This note is a testimony by the creator of a service rendered by the owner";
        output = _constructTokenURI(
            _tokenId,
            stake.token,
            _description,
            optionNames, 
            optionValues 
        );
    }

    function tokenURI(uint _tokenId) public view virtual override returns (string memory output) {
        (uint creatorStakeId, uint ownerStakeId, uint created, string memory tag) = IStakeMarket(IContract(contractAddress).stakeMarketNote()).IOU(_tokenId);
        if (created > 0) {
            output = _tokenURIiou(_tokenId, creatorStakeId, ownerStakeId, created, tag);
        } else {
            output = _tokenURI(_tokenId);
        }
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

    function addressToString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}
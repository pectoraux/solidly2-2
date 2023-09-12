// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import './Library.sol';

contract TrustBounties {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Bounty {
        address owner;
        address token;
        address ve;
        address claimableBy;
        uint minToClaim;
        uint startTime;
        uint endTime;
        uint parentBountyId;
        NFTYPE isNFT;
        bool recurring;
    } 
    mapping(uint => uint) private profileId;
    mapping(uint => Bounty) public bountyInfo;
    EnumerableSet.UintSet private bounties;
    mapping(uint => EnumerableSet.UintSet) private approvals;
    struct Approval {
        uint amount;
        uint deadline;
    }
    mapping(uint => mapping(uint => Approval)) public isApprovedForAmount;
    uint private bountyId = 1;
    struct Claim {
        uint bountyId;
        address hunter;
        uint endTime;
        uint amountToClaim;
        bool friendly;
        address winner;
        StakeStatusEnum status;
    }
    mapping(uint => Claim[]) public claims;
    struct Balance {
        uint tokenId;
        uint amount;
    }
    mapping(uint => mapping(address => Balance)) private balances;
    mapping(uint => EnumerableSet.AddressSet) private balanceSources;
    address private contractAddress;
    mapping(uint => bool) public lockedBounties;

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function getOwner(uint _bountyId) external view returns(address) {
        return bountyInfo[_bountyId].owner;
    }

    function _trustBountyHelper() internal view returns(address) {
        return IContract(contractAddress).trustBountyHelper();
    }

    function _trustBountyVoter() internal view returns(address) {
        return IContract(contractAddress).trustBountyVoter();
    }

    function getBalance(uint _bountyId) public view returns(uint _balance) {
        if (
            !lockedBounties[_bountyId] &&
            (claims[_bountyId].length == 0 || claims[_bountyId][claims[_bountyId].length - 1].status != StakeStatusEnum.AtWar)
            ) {            
            for(uint i = 0; i < balanceSources[_bountyId].length(); i++) {
                _balance += balances[_bountyId][balanceSources[_bountyId].at(i)].amount;
            }
            for(uint i = 0; i < approvals[_bountyId].length(); i++) {
                if (isApprovedForAmount[_bountyId][approvals[_bountyId].at(i)].deadline > block.timestamp + 
                    ITrustBounty(_trustBountyHelper()).balanceBuffer()
                ) {
                    _balance = isApprovedForAmount[_bountyId][approvals[_bountyId].at(i)].amount;
                }
            }
            _balance = _balance / Math.max(ITrustBounty(_trustBountyHelper()).attachments(_bountyId),1);
        }
    }

    function createBounty(
        address _user,
        address _token,
        address _ve,
        address _claimableBy,
        uint _parentBountyId,
        uint _collectionId,
        uint _endTime,
        uint _isNFT,
        bool _recurring,
        string memory _avatar,
        string memory _bountySource
    ) external returns(uint) { 
        address trustBountyHelper = _trustBountyHelper();
        require(ITrustBounty(trustBountyHelper).isVe(_ve),"1");
        require(_endTime >= ITrustBounty(trustBountyHelper).minLockPeriod(),"2");
        if (_token == address(0x0)) {
            _token = ITrustBounty(trustBountyHelper).WETH();
        }
        require(_token == ITrustBounty(trustBountyHelper).WETH() || 
            ITrustBounty(trustBountyHelper).isWhiteListed(_token),"3");
        if (_parentBountyId > 0) {
            require(bountyInfo[_parentBountyId].owner != address(0x0));
            if (!_recurring) require(!bountyInfo[_parentBountyId].recurring);
        }
        bountyInfo[bountyId] = Bounty({
            ve: _ve,
            owner: _user,
            minToClaim: ITrustBounty(trustBountyHelper).minToClaim(),
            startTime: block.timestamp,
            endTime: block.timestamp + _endTime,
            parentBountyId: _parentBountyId,
            token: _token,
            claimableBy: _claimableBy,
            recurring: _recurring,
            isNFT: NFTYPE(_isNFT)
        });
        profileId[bountyId] = IProfile(IContract(contractAddress).profile()).addressToProfileId(_user);
        bounties.add(bountyId);

        ITrustBounty(trustBountyHelper).emitCreateBounty(
            bountyId, 
            _user, 
            _token, 
            _parentBountyId, 
            _collectionId,
            _bountySource, 
            _avatar
        );
        return bountyId++;
    }
    
    function updateOwner(uint _bountyId) external {
        require(profileId[_bountyId] == IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender));
        bountyInfo[_bountyId].owner = msg.sender;
    }
    
    function updateBountyEndTime(uint _bountyId, uint _buffer) external {
        require(ITrustBounty(_trustBountyHelper()).isAuthorizedSourceFactories(msg.sender));
        bountyInfo[_bountyId].endTime = block.timestamp + _buffer;
    }

    function addApproval(uint _bountyId, uint _partnerBounty, uint _amount, uint _deadline) external {
        require(bountyInfo[_bountyId].owner == msg.sender);
        require(_amount <= balances[_bountyId][address(this)].amount);
        require(isApprovedForAmount[_bountyId][_partnerBounty].deadline < block.timestamp + _deadline);
        balances[_bountyId][address(this)].amount -= _amount;
        approvals[_partnerBounty].add(_bountyId);
        isApprovedForAmount[_partnerBounty][_bountyId].amount += _amount;
        isApprovedForAmount[_partnerBounty][_bountyId].deadline = block.timestamp + _deadline;
    
        ITrustBounty(_trustBountyHelper()).emitAddApproval(
            _bountyId, 
            _partnerBounty, 
            _amount,
            block.timestamp + _deadline
        );
    }

    function removeApproval(uint _bountyId, uint _partnerBounty, uint _amount) external {
        require(bountyInfo[_bountyId].owner == msg.sender);
        require(_amount <= isApprovedForAmount[_partnerBounty][_bountyId].amount);
        require(isApprovedForAmount[_bountyId][_partnerBounty].deadline < block.timestamp);
        isApprovedForAmount[_partnerBounty][_bountyId].amount -= _amount;
        balances[_bountyId][address(this)].amount += _amount;
        if (isApprovedForAmount[_partnerBounty][_bountyId].amount == 0) {
            approvals[_partnerBounty].remove(_bountyId);
        }
        ITrustBounty(_trustBountyHelper()).emitRemoveApproval(
            _bountyId, 
            _partnerBounty, 
            _amount,
            isApprovedForAmount[_partnerBounty][_bountyId].amount == 0
        );
    }

    function updateBounty(
        uint _bountyId,
        uint _collectionId,
        address _newOwner,
        string memory avatar,
        string memory terms
    ) external {
        require(bountyInfo[_bountyId].owner == msg.sender);
        address trustBountyHelper = _trustBountyHelper();
        bountyInfo[_bountyId].owner = _newOwner;
        bountyInfo[_bountyId].minToClaim = ITrustBounty(trustBountyHelper).minToClaim();
        
        ITrustBounty(trustBountyHelper).emitUpdateBounty(
            _bountyId, 
            _collectionId,
            _newOwner, 
            avatar, 
            terms
        );
    }

    function addRecurringBalance(uint _bountyId, address _source) external lock {
        uint _amount = IMarketPlace(_source).withdrawRecurringBounty(msg.sender, bountyInfo[_bountyId].token);
        balances[_bountyId][_source].amount += _amount;
        _source = address(this);
        balanceSources[_bountyId].add(_source);

        ITrustBounty(_trustBountyHelper()).emitAddBalance(_bountyId, _source, _amount);
    }

    function addBalance(uint _bountyId, address _source, uint _tokenId, uint _amount) external lock {
        require(_amount > 0);
        require(_source != address(0x0));
        if (bountyInfo[_bountyId].isNFT != NFTYPE.not) { // is nft
            require(getBalance(_bountyId) == 0); // one nft per bounty
        }
        address trustBountyHelper = _trustBountyHelper();
        if (_source == address(this)) {
            uint _fees;
            if (bountyInfo[_bountyId].isNFT == NFTYPE.not) {
                _fees = _amount * ITrustBounty(trustBountyHelper).tradingFee() / 10000;
                _amount = _amount - _fees;
                ITrustBounty(trustBountyHelper).notifyFees(bountyInfo[_bountyId].token, _fees);
            } else {
                _fees = ITrustBounty(trustBountyHelper).tradingNFTFee();
                IERC20(IContract(contractAddress).token()).safeTransferFrom(
                    bountyInfo[_bountyId].owner,
                    address(this),
                    _fees
                );
                ITrustBounty(trustBountyHelper).notifyFees(
                    IContract(contractAddress).token(), 
                    _fees
                );
            }
            ITrustBounty(trustBountyHelper).safeTransferFrom(_bountyId, msg.sender, address(this), _amount);
        } else {
            require(ITrustBounty(trustBountyHelper).isAuthorizedSourceFactories(_source));
            require(ve(_source).token() == bountyInfo[_bountyId].token);
            IGaugeBalance(_source).updateMinimumBalance(
                msg.sender, 
                _tokenId,
                _amount + balances[_bountyId][_source].amount, 
                bountyInfo[_bountyId].endTime
            );
        }
        balances[_bountyId][_source].tokenId = _tokenId;
        balances[_bountyId][_source].amount += _amount;
        balanceSources[_bountyId].add(_source);
        
        ITrustBounty(trustBountyHelper).emitAddBalance(_bountyId, _source, _amount);
    }

    function _deleteBalance(uint _bountyId, address _source, address _user) internal lock {
        uint _balanceAmount = balances[_bountyId][_source].amount;
        uint _tokenId = balances[_bountyId][_source].tokenId;
        address trustBountyHelper = _trustBountyHelper();
        delete balances[_bountyId][_source];
        balanceSources[_bountyId].remove(_source);
        if (_source == address(this)) {
            try ITrustBounty(trustBountyHelper).safeTransfer(_bountyId, _user, _balanceAmount)
            {}catch{}
        } else {
            IGaugeBalance(_source).deleteMinimumBalance(
                _user, 
                _tokenId, 
                _balanceAmount
            );
        }
        ITrustBounty(trustBountyHelper).emitDeleteBalance(_bountyId, _source);
    }

    function deleteBounty(uint _bountyId) external {
        require(bountyInfo[_bountyId].owner == msg.sender);
        require(bountyInfo[_bountyId].endTime < block.timestamp);
        // delete all balances attached
        for (uint i = 0; i < balanceSources[_bountyId].length(); i++) {
            _deleteBalance(_bountyId, balanceSources[_bountyId].at(i), msg.sender);
        }
        delete bountyInfo[_bountyId];
        bounties.remove(_bountyId);
        ITrustBounty(_trustBountyHelper()).emitDeleteBounty(_bountyId);
    }

    function createClaim(
        address _attacker,
        uint _bountyId,
        uint _amountToClaim,
        bool _lockBounty,
        string memory _title, 
        string memory _content,
        string memory _tags
    ) public {
        require(bountyInfo[_bountyId].owner != address(0x0));
        require(bountyInfo[_bountyId].claimableBy == address(0x0) ||
        bountyInfo[_bountyId].claimableBy == msg.sender);
        if (claims[_bountyId].length > 0) {
            require(claims[_bountyId][claims[_bountyId].length - 1].winner != address(0x0));
        }
        address trustBountyHelper = _trustBountyHelper();
        address trustBountyVoter = _trustBountyVoter();
        require(!IStakeMarketVoter(trustBountyVoter).isGauge(bountyInfo[_bountyId].ve, _bountyId));    
        uint _minToClaim = _amountToClaim * ITrustBounty(trustBountyHelper).minToClaim() / 10000;
        ITrustBounty(trustBountyHelper).safeTransferFrom(_bountyId, _attacker, address(this), _minToClaim);
        claims[_bountyId].push(Claim({
            bountyId: _bountyId,
            hunter: _attacker,
            endTime: 0,
            amountToClaim: _amountToClaim,
            winner: address(0x0),
            friendly: false,
            status: StakeStatusEnum.AtWar
        }));
        lockedBounties[_bountyId] = _lockBounty;
        erc20(bountyInfo[_bountyId].token).approve(trustBountyVoter, _minToClaim);
        IStakeMarketVoter(trustBountyVoter).createGauge(
            bountyInfo[_bountyId].ve, 
            bountyInfo[_bountyId].token, 
            claims[_bountyId].length,
            _bountyId, 
            _minToClaim,
            _title,
            _content,
            _tags
        );
        ITrustBounty(trustBountyHelper).emitCreateClaim(
            claims[_bountyId].length,
            _bountyId, 
            _amountToClaim, 
            _attacker,
            false,
            false
        );
    }

    function updateStakeFromVoter(uint _winnerId, uint _looserId) external {
        require(_trustBountyVoter() == msg.sender);
        uint _bountyId; 
        if (claims[_winnerId].length >= _looserId) {
            _bountyId = claims[_winnerId][_looserId-1].bountyId == _winnerId ? _winnerId : _looserId;
        } else {
            _bountyId = _looserId;
        }
        if (claims[_bountyId].length > 0) {
            uint _lastClaim = claims[_bountyId].length - 1;
            require(claims[_bountyId][_lastClaim].winner == address(0x0));
            address __winner = _bountyId == _winnerId
            ? bountyInfo[_bountyId].owner
            : claims[_bountyId][_lastClaim].hunter;
            claims[_bountyId][_lastClaim].winner = __winner;
            uint appealWindow = ITrustBounty(_trustBountyHelper()).appealWindow();
            claims[_bountyId][_lastClaim].endTime = block.timestamp + appealWindow; // appeal window
            ITrustBounty(_trustBountyHelper())
            .emitUpdateClaim(_lastClaim, block.timestamp + appealWindow, false, __winner);
        }
    }

    function createFriendlyClaim(
        address _attacker,
        uint _bountyId,
        uint _amountToClaim
    ) external {
        require(bountyInfo[_bountyId].owner != address(0x0));
        require(bountyInfo[_bountyId].claimableBy == address(0x0) ||
        bountyInfo[_bountyId].claimableBy == msg.sender);
        if (claims[_bountyId].length > 0) {
            require(claims[_bountyId][claims[_bountyId].length - 1].winner != address(0x0));
        }
        claims[_bountyId].push(Claim({
            bountyId: _bountyId,
            hunter: _attacker,
            endTime: 0,
            amountToClaim: _amountToClaim,
            winner: address(0x0),
            friendly: true,
            status: StakeStatusEnum.AtWar
        }));

        ITrustBounty(_trustBountyHelper()).emitCreateClaim(
            claims[_bountyId].length,
            _bountyId, 
            _amountToClaim, 
            _attacker,
            true,
            false
        );
    }

    function concede(uint _bountyId) external {
        uint _lastClaim = claims[_bountyId].length-1;
        require(bountyInfo[_bountyId].owner == msg.sender || claims[_bountyId][_lastClaim].hunter == msg.sender);
        address _winner = bountyInfo[_bountyId].owner == msg.sender 
        ? claims[_bountyId][_lastClaim].hunter : bountyInfo[_bountyId].owner;
        claims[_bountyId][_lastClaim].winner = _winner;
        ITrustBounty(_trustBountyHelper()).emitUpdateClaim(
            _lastClaim, 
            block.timestamp, 
            false,
            _winner
        );
    }

    function applyClaimResults(
        uint _bountyId, 
        uint _claimId, 
        uint _amountToClaim,
        string memory _title, 
        string memory _content,
        string memory _tags
    ) external {
        _claimId = _claimId - 1;
        require(claims[_bountyId][_claimId].winner != address(0x0));
        address trustBountyHelper = _trustBountyHelper();
        if (_amountToClaim > 0) {
            require(claims[_bountyId][_claimId].winner != msg.sender);
            address _attacker = claims[_bountyId][_claimId].winner == bountyInfo[_bountyId].owner
            ?  msg.sender : claims[_bountyId][_claimId].hunter;
            createClaim(_attacker, _bountyId, _amountToClaim, lockedBounties[_bountyId], _title, _content, _tags);
        } else if (claims[_bountyId][_claimId].winner == claims[_bountyId][_claimId].hunter) {
            require(claims[_bountyId][_claimId].endTime < block.timestamp);
            uint _amount = _gatherFunds(_bountyId, claims[_bountyId][_claimId].amountToClaim);
            uint _fees = _amount * ITrustBounty(trustBountyHelper).tradingFee() / 10000;
            ITrustBounty(trustBountyHelper).notifyFees(bountyInfo[_bountyId].token, _fees);
            ITrustBounty(trustBountyHelper).safeTransfer(_bountyId, claims[_bountyId][_claimId].hunter, _amount - _fees);
        } else if (claims[_bountyId][_claimId].winner == bountyInfo[_bountyId].owner) {
            lockedBounties[_bountyId] = false;
        }
        claims[_bountyId][_claimId].status = StakeStatusEnum.AtPeace;
        ITrustBounty(trustBountyHelper).emitUpdateClaim(
            _claimId, 
            block.timestamp,
            true,
            claims[_bountyId][_claimId].hunter
        );
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }

    function _gatherFunds(uint _bountyId, uint _amount) internal returns(uint _fundsGathered) {
        for (uint i = 0; i < balanceSources[_bountyId].length(); i++) {
            if (_amount <= _fundsGathered) break;
            uint _delta1 = _amount - _fundsGathered;
            address _source = balanceSources[_bountyId].at(i);
            if (balances[_bountyId][_source].amount < _delta1) {
                _fundsGathered += balances[_bountyId][_source].amount;
                if (_source != address(this)) {
                    IGaugeBalance(_source).withdrawBounty(
                        bountyInfo[_bountyId].owner, 
                        balances[_bountyId][_source].tokenId, 
                        balances[_bountyId][_source].amount
                    );
                }
                delete balances[_bountyId][_source];
            } else {
                _fundsGathered += _delta1;
                balances[_bountyId][_source].amount -= _delta1;
                if (_source != address(this)) {
                    IGaugeBalance(_source).withdrawBounty(
                        bountyInfo[_bountyId].owner, 
                        balances[_bountyId][_source].tokenId,
                        _delta1
                    );
                }
            }
        }
        if (_fundsGathered < _amount) {
            for (uint i = 0; i < approvals[_bountyId].length(); i++) {
                if (_amount <= _fundsGathered) break;
                uint _delta = _amount - _fundsGathered;
                if (isApprovedForAmount[_bountyId][approvals[_bountyId].at(i)].amount < _delta) {
                    _fundsGathered += isApprovedForAmount[_bountyId][approvals[_bountyId].at(i)].amount;
                    isApprovedForAmount[_bountyId][approvals[_bountyId].at(i)].amount = 0;
                } else {
                    _fundsGathered += _delta;
                    isApprovedForAmount[_bountyId][approvals[_bountyId].at(i)].amount -= _delta;
                }
            }
            cleanUpApprovals(_bountyId);
            cleanUpBalances(_bountyId);
        }
    }

    function cleanUpApprovals(uint _bountyId) public {
        for (uint i = approvals[_bountyId].length() - 1; i <= 0; i--) {
            if (isApprovedForAmount[_bountyId][approvals[_bountyId].at(i)].amount == 0) {
                approvals[_bountyId].remove(approvals[_bountyId].at(i));
                delete isApprovedForAmount[_bountyId][approvals[_bountyId].at(i)];
            }
        }
    }

    function cleanUpBalances(uint _bountyId) public {
        for (uint i = balanceSources[_bountyId].length() - 1; i <= 0; i--) {
            address _source = balanceSources[_bountyId].at(i);
            if (balances[_bountyId][_source].amount == 0) {
                balanceSources[_bountyId].remove(_source);
                delete balances[_bountyId][_source];
            }
        }
    }

    function onERC721Received(address,address,uint256,bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector; 
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}

contract TrustBountiesHelper {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private whitelistedTokens;
    EnumerableSet.AddressSet private authorizedSourceFactories;

    address public contractAddress;
    mapping(address => uint) public treasuryFees;
    mapping(address => bool) public ves;
    address public WETH;
    uint public minLockPeriod = 7 days;
    uint public appealWindow = 7 days;
    uint public balanceBuffer = 14 days;
    uint public tradingFee = 100;
    uint public tradingNFTFee = 1;
    uint public minToClaim = 100;
    mapping(address => bool) public canAttach;
    mapping(uint => uint) public attachments;
    event CreateBounty(
        uint indexed bountyId, 
        address owner, 
        address token, 
        uint parentBountyId, 
        uint collectionId,
        string bountySource, 
        string avatar
    );
    event UpdateBounty(
        uint indexed bountyId, 
        uint collectionId,
        address newOwner, 
        string avatar, 
        string terms
    );
    event DeleteBounty(uint indexed bountyId);
    event UpdateWhitelistedTokens(address[] tokens, bool add);
    event UpdateAuthorizedSourceFactories(address[] factories, bool add);
    event AddBalance(uint indexed bountyId, address source, uint balanceAmount);
    event DeleteBalance(uint indexed bountyId, address source);
    event CreateClaim(
        uint indexed claimId, 
        uint bountyId, 
        uint amount, 
        address hunter,
        bool friendly,
        bool atPeace
    );
    event UpdateClaim(uint indexed claimId, address winner, uint endTime, bool atPeace);
    event AddApproval(
        uint indexed bountyId, 
        uint partnerBounty, 
        uint amount,
        uint endTime
    );
    event RemoveApproval(
        uint indexed bountyId, 
        uint partnerBounty, 
        uint amount,
        bool deactivate
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

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }
    
    function emitCreateBounty(
        uint bountyId, 
        address owner, 
        address token, 
        uint parentBountyId, 
        uint collectionId,
        string memory bountySource, 
        string memory avatar
    ) external {
        require(msg.sender == _trustBounty());
        emit CreateBounty(
            bountyId, 
            owner, 
            token, 
            parentBountyId, 
            collectionId,
            bountySource, 
            avatar
        );   
    }

    function emitUpdateBounty(
        uint bountyId, 
        uint collectionId,
        address newOwner, 
        string memory avatar, 
        string memory terms
    ) external {
        require(msg.sender == _trustBounty());
        emit UpdateBounty(
            bountyId, 
            collectionId,
            newOwner, 
            avatar, 
            terms
        );
    }

    function emitDeleteBounty(uint _bountyId) external {
        require(msg.sender == _trustBounty());
        emit DeleteBounty(_bountyId);
    }

    function emitAddBalance(uint _bountyId, address _source, uint _balanceAmount) external {
        require(msg.sender == _trustBounty());
        emit AddBalance(_bountyId, _source, _balanceAmount);
    }

    function emitDeleteBalance(uint _bountyId, address _source) external {
        require(msg.sender == _trustBounty());
        emit DeleteBalance(_bountyId, _source);
    }

    function emitCreateClaim(
        uint _claimId, 
        uint _bountyId, 
        uint _amount, 
        address _hunter,
        bool _friendly,
        bool _atPeace
    ) external {
        require(msg.sender == _trustBounty());
        emit CreateClaim(
            _claimId, 
            _bountyId, 
            _amount, 
            _hunter,
            _friendly,
            _atPeace
        );
    }

    function emitUpdateClaim(
        uint _claimId,
        uint _endTime,
        bool _atPeace,
        address _winner
    ) external {
        require(msg.sender == _trustBounty());
        emit UpdateClaim(
            _claimId, 
            _winner, 
            _endTime, 
            _atPeace
        );
    }

    function emitAddApproval(
        uint _bountyId, 
        uint _partnerBounty, 
        uint _amount, 
        uint _endTime
    ) external {
        require(msg.sender == _trustBounty());
        emit AddApproval(
            _bountyId, 
            _partnerBounty, 
            _amount, 
            _endTime
        );
    }

    function emitRemoveApproval(
        uint _bountyId, 
        uint _partnerBounty, 
        uint _amount, 
        bool _deactivate
    ) external {
        require(msg.sender == _trustBounty());
        emit RemoveApproval(
            _bountyId, 
            _partnerBounty, 
            _amount, 
            _deactivate
        );
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

    function addBalanceETH(uint _bountyId, address _source, uint _tokenId) external payable lock {
        ITrustBounty(_trustBounty()).addBalance(_bountyId, _source, _tokenId, msg.value);
    }

    function applyClaimResultsETH(
        uint _bountyId, 
        uint _claimId, 
        string memory _title, 
        string memory _content
    ) external payable {
        ITrustBounty(_trustBounty()).applyClaimResults(
            _bountyId, 
            _claimId, 
            msg.value,
            _title, 
            _content
        ); 
    }

    function _trustBounty() internal view returns(address) {
        return IContract(contractAddress).trustBounty();
    }

    function updateCanAttach(address _contract, bool _add) external {
        require(msg.sender == IAuth(contractAddress).devaddr_(), "TH1");
        canAttach[_contract] = _add;
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }

    function isVe(address _ve) external view returns(bool) {
        return ves[_ve];
    }

    function notifyFees(address _token, uint _fees) external {
        require(msg.sender == IContract(contractAddress).trustBounty());
        treasuryFees[_token] += _fees;
    }

    function buyWithContract(
        address _token,
        address _user,
        address _referrer,
        string memory _tokenId,
        uint _amount,
        uint[] memory _bountyNTokenId   
    ) external {
        require(IValuePool(IContract(contractAddress).valuepoolHelper()).isGauge(msg.sender));
        address trustBounty = IContract(contractAddress).trustBounty();
        erc20(_token).approve(trustBounty, _amount);
        ITrustBounty(trustBounty).addBalance(
            _bountyNTokenId[0], 
            trustBounty, 
            _bountyNTokenId[1], 
            _amount
        );
    }

    function setWETH(address _WETH) external {
        require(msg.sender == IAuth(contractAddress).devaddr_());
        WETH = _WETH;
    }

    function isWhiteListed(address _token) external view returns(bool) {
        return whitelistedTokens.contains(_token);
    }

    function isAuthorizedSourceFactories(address _token) external view returns(bool) {
        return authorizedSourceFactories.contains(_token);
    }

    function updateWhitelistedTokens(address[] memory _tokens, bool _add) external {
        require(msg.sender == IAuth(contractAddress).devaddr_(), "T4");
        for (uint i = 0; i < _tokens.length; i++) {
            if (_add) {
                whitelistedTokens.add(_tokens[i]);
            } else {
                whitelistedTokens.remove(_tokens[i]);
            }
        }
        emit UpdateWhitelistedTokens(_tokens, _add);
    }
    
    function updateAuthorizedSourceFactories(address[] memory _factories, bool _add) external {
        require(msg.sender == IAuth(contractAddress).devaddr_(), "T5");
        for (uint i = 0; i < _factories.length; i++) {
            if (_add) {
                authorizedSourceFactories.add(_factories[i]);
            } else {
                authorizedSourceFactories.remove(_factories[i]);
            }
        }
        emit UpdateAuthorizedSourceFactories(_factories, _add);
    }

    function getWhitelistedTokens(uint _start) external view returns(address[] memory _tokens) {
        _tokens = new address[](whitelistedTokens.length() - _start);
        for (uint i = _start; i < whitelistedTokens.length(); i++) {
            _tokens[i] = whitelistedTokens.at(i);
        }
    }

    function getAuthorizedSourceFactories(uint _start) external view returns(address[] memory _factories) {
        _factories = new address[](authorizedSourceFactories.length() - _start);
        for (uint i = _start; i < authorizedSourceFactories.length(); i++) {
            _factories[i] = authorizedSourceFactories.at(i);
        }
    }

    function updateVes(address _ve, bool _add) external {
        require(msg.sender == IAuth(contractAddress).devaddr_(), "TH2");
        ves[_ve] = _add;
    }

    function updateParameters(
        uint _minLockPeriod, 
        uint _balanceBuffer, 
        uint _appealWindow,
        uint _tradingFee,
        uint _tradingNFTFee,
        uint _minToClaim
    ) external {
        require(msg.sender == IAuth(contractAddress).devaddr_(), "T1");
        tradingFee = _tradingFee;
        minToClaim = _minToClaim;
        tradingNFTFee = _tradingNFTFee;
        minLockPeriod = _minLockPeriod;
        balanceBuffer = _balanceBuffer;
        appealWindow = _appealWindow;
    }
    function getLatestClaimId(uint _bountyId) external view returns(uint) {
        return (ITrustBounty(IContract(contractAddress).trustBounty()).claims(_bountyId)).length;
    }
    function attach(uint _bountyId) external {
        require(canAttach[msg.sender], "TH4");
        attachments[_bountyId] += 1;
    }
    
    function detach(uint _bountyId) external {
        require(canAttach[msg.sender], "TH6");
        attachments[_bountyId] -= 1;
    }

    function safeTransfer(uint _bountyId, address to, uint256 value) external {
        address trustBounty = IContract(contractAddress).trustBounty();
        require(msg.sender == trustBounty, "TH7");
        (,address token,,,,,,,NFTYPE isNFT,) = ITrustBounty(trustBounty).bountyInfo(_bountyId);
        if (isNFT == NFTYPE.erc721) {
            IERC721(token).safeTransferFrom(address(this), to, value);
        } else if (isNFT == NFTYPE.erc1155) { 
            IERC1155(token).safeTransferFrom(address(this), to, value, 1, msg.data);
        } else if (token == WETH) { 
            (bool success, ) = to.call{value: value}(new bytes(0));
            require(success, "T42");
        } else {
            (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))), "T43");
        }
    }

    function safeTransferFrom(uint _bountyId, address from, address to, uint256 value) external {
        address trustBounty = IContract(contractAddress).trustBounty();
        require(msg.sender == trustBounty, "TH9");
        (,address token,,,,,,,NFTYPE isNFT,) = ITrustBounty(trustBounty).bountyInfo(_bountyId);
        if (isNFT == NFTYPE.erc721) {
            require(// value == 1 && _bountyId == 
                to == trustBounty, "GG");
            IERC721(token).safeTransferFrom(from, to, value);
        } else if (isNFT == NFTYPE.erc1155) { 
            IERC1155(token).safeTransferFrom(from, to, value, 1, msg.data);
        } else if (token == WETH && from == trustBounty) { 
            (bool success, ) = to.call{value: value}(new bytes(0));
            require(success, "T44");
        } else if (token == WETH && to == trustBounty) { 
            IWETH(WETH).deposit{value: value}();
        } else {
            IERC20(token).safeTransferFrom(from, to, value);
        }
    }

    function withdrawFees(address _token) external returns(uint _amount) {
        require(msg.sender == IAuth(contractAddress).devaddr_(), "T41");
        address trustBounty = IContract(contractAddress).trustBounty();
        _amount = treasuryFees[_token];
        treasuryFees[_token] = 0;
        IERC20(_token).safeTransfer(msg.sender, _amount);
        return _amount;
    }

    function onERC721Received(address,address,uint256,bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector; 
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma abicoder v2;

import "./Library.sol";

contract StakeMarketVoter {
    using Percentile for *;

    uint public period = 7 days;
    
    mapping(address => uint) public totalWeight; // total voting weight
    struct Gauge {
        uint endTime;
        uint percentile;
    }
    mapping(address => uint[]) public pools; // all pools viable for incentives
    mapping(address => uint) public totalGas;
    mapping(address => uint) public totalVotes;
    mapping(address => uint) public sum_of_diff_squared;
    mapping(address => mapping(uint => Gauge)) public gauges;
    mapping(address => mapping(uint => int256)) public weights; // pool => weight
    mapping(string => mapping(uint => int256)) public votes; // nft => pool => votes
    mapping(address => mapping(uint => uint[])) public poolVote; // nft => pools
    mapping(address => mapping(uint => uint)) public usedWeights;  // nft => total voting weight of user
    mapping(address => mapping(uint => bool)) public isGauge;
    struct Litigation {
        uint attackerId;
        uint defenderId;
        address market;
    }
    mapping(uint => Litigation) public litigations;
    uint public litigationId = 1;
    address public contractAddress;

    event GaugeCreated(
        uint indexed litigationId,
        address ve, 
        address token, 
        address market,
        uint percentile, 
        uint attackerId, 
        uint defenderId,
        uint creationTime, 
        uint endTime,
        uint gas,
        string title,
        string content,
        string tags
    );
    event UpdateTags(
        uint indexed litigationId,
        string countries,
        string cities,
        string products
    );
    event GaugeClosed(uint indexed litigationId, bool vetoed);
    event Voted(uint indexed litigationId, address ve, address voter, uint tokenId, int256 weight);
    event Abstained(address ve, uint tokenId, int256 weight);
    event Deposit(address indexed lp, address indexed gauge, uint tokenId, uint amount);
    event Withdraw(address indexed lp, address indexed gauge, uint tokenId, uint amount);
    event NotifyReward(address indexed sender, address indexed reward, uint amount);
    event DistributeReward(address indexed sender, address indexed gauge, uint amount);
    event Attach(address indexed owner, address indexed gauge, uint tokenId);
    event Detach(address indexed owner, address indexed gauge, uint tokenId);
    event Whitelisted(address indexed whitelister, address indexed token);
    event UpdateAttackerContent(uint indexed litigationId, string content);
    event UpdateDefenderContent(uint indexed litigationId, string content);
    
    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    modifier onlyAdmin {
        require(msg.sender == IAuth(contractAddress).devaddr_());
        _;
    }

    function setContractAddress(address __contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender, "SV1");
        contractAddress = __contractAddress;
    }

    function updatePeriod(uint _period) external onlyAdmin {
        period = _period;
    }
    
    function _profile() internal view returns(address) {
        return IContract(contractAddress).profile();
    }

    function _bribe() internal view returns(address) {
        return IContract(contractAddress).stakeMarketBribe();
    }

    function updateAttackerContent(uint _litigationId, uint attackerId, string memory _content) external {
        require(IStakeMarket(litigations[_litigationId].market).getOwner(attackerId) == msg.sender, "SV2");
        emit UpdateAttackerContent(_litigationId, _content);
    }

    function updateDefenderContent(uint _litigationId, uint defenderId, string memory _content) external {
        require(IStakeMarket(litigations[_litigationId].market).getOwner(defenderId) == msg.sender, "SV3");
        emit UpdateDefenderContent(_litigationId, _content);
    }

    function reset(address _ve, uint _tokenId, uint _profileId) external {
        require(ve(_ve).isApprovedOrOwner(msg.sender, _tokenId), "SV4");
        _reset(_ve, _tokenId, _profileId);
        ve(_ve).abstain(_tokenId);
    }

    function _reset(address _ve, uint _tokenId, uint _profileId) internal {
        uint[] storage _poolVote = poolVote[_ve][_tokenId];
        uint _poolVoteCnt = _poolVote.length;
        int256 _totalWeight = 0;
        require(IProfile(_profile()).addressToProfileId(msg.sender) == _profileId && _profileId > 0, "SV5");
        for (uint i = 0; i < _poolVoteCnt; i ++) {
            uint _pool = _poolVote[i];
            string memory ve_tokenId = string(abi.encodePacked(_ve, _profileId, _tokenId));
            int256 _votes = votes[ve_tokenId][_pool];

            if (_votes != 0) {
                weights[_ve][_pool] -= _votes;
                votes[ve_tokenId][_pool] -= _votes;
                if (_votes > 0) {
                    IStakeMarketBribe(_bribe())._withdraw(_ve, uint256(_votes), _tokenId);
                    _totalWeight += _votes;
                } else {
                    _totalWeight -= _votes;
                }
                emit Abstained(_ve, _tokenId, _votes);
            }
        }
        totalWeight[_ve] -= uint256(_totalWeight);
        usedWeights[_ve][_tokenId] = 0;
        delete poolVote[_ve][_tokenId];
    }

    function poke(uint _litigationId, address _ve, uint _profileId, uint _tokenId) external {
        uint[] memory _poolVote = poolVote[_ve][_tokenId];
        uint _poolCnt = _poolVote.length;
        int256[] memory _weights = new int256[](_poolCnt);
        string memory ve_tokenId = string(abi.encodePacked(_ve, _profileId, _tokenId));

        for (uint i = 0; i < _poolCnt; i ++) {
            _weights[i] = votes[ve_tokenId][_poolVote[i]];
            _vote(_litigationId, _ve, _tokenId, _profileId, _poolVote[i], _weights[i]);
        }
    }

    function _vote(uint _litigationId, address _ve, uint _tokenId, uint _profileId, uint _pool, int256 _weightFactor) internal {
        _reset(_ve, _tokenId, _profileId);
        int256 _totalWeight = 0;
        int256 _usedWeight = 0;
        require(IProfile(_profile()).addressToProfileId(msg.sender) == _profileId && _profileId > 0, "SV6");
        SSIData memory metadata = ISSI(IContract(contractAddress).ssi()).getSSID(_profileId);
        require(keccak256(abi.encodePacked(metadata.answer)) != keccak256(abi.encodePacked("")), "SV7");
        int256 _weight = int256(gauges[_ve][_pool].percentile + ve(_ve).percentiles(_tokenId)) / 2;
        if (isGauge[_ve][_pool]) {
            int256 _poolWeight;
            if(_weightFactor > 0) {
                _poolWeight = _weight * _weightFactor / _weightFactor;
            } else {
                _poolWeight = -_weight * _weightFactor / _weightFactor;
            }
            string memory ve_tokenId = string(abi.encodePacked(_ve, _profileId, _tokenId));
                
            require(votes[ve_tokenId][_pool] == 0, "SV8");
            require(_poolWeight != 0, "SV9");

            poolVote[_ve][_tokenId].push(_pool);

            weights[_ve][_pool] += _poolWeight;
            votes[ve_tokenId][_pool] += _poolWeight;
            emit Voted(_litigationId, _ve, msg.sender, _tokenId, _poolWeight);
            if (_poolWeight > 0) {
                IStakeMarketBribe(_bribe())._deposit(_ve, uint256(_poolWeight), _tokenId);
            } else {
                _poolWeight = -_poolWeight;
            }
            _usedWeight += _poolWeight;
            _totalWeight += _poolWeight;
        }
        totalWeight[_ve] += uint256(_totalWeight);
        usedWeights[_ve][_tokenId] = uint256(_usedWeight);
    }

    function vote(uint _litigationId, address _ve, uint tokenId, uint _profileId, uint _pool, int256 _weight) external {
        require(ve(_ve).isApprovedOrOwner(msg.sender, tokenId), "SV10");
        _vote(_litigationId, _ve, tokenId, _profileId, _pool, _weight);
    }
    
    function createGauge(
        address _ve, 
        address _token, 
        uint _attackerId, 
        uint _defenderId, 
        uint _gas, 
        string memory _title, 
        string memory _content,
        string memory _tags
    ) external {
        require(IContract(contractAddress).stakeMarket() == msg.sender, "SV11");
        require(!isGauge[_ve][_attackerId] && !isGauge[_ve][_defenderId], "SV12");
        _safeTransferFrom(_token, msg.sender, _bribe(), _gas);
        uint percentile = _updateValues(_ve, _attackerId, _defenderId, _gas);
        emit GaugeCreated(
            litigationId++,
            _ve, 
            _token, 
            msg.sender,
            percentile, 
            _attackerId, 
            _defenderId,
            block.timestamp,
            block.timestamp + period / period * period,
            _gas,
            _title,
            _content,
            _tags
        );
    }

    function _updateValues(address _ve, uint _attackerId, uint _defenderId, uint _gas) internal returns(uint) {
        isGauge[_ve][_attackerId] = true;
        isGauge[_ve][_defenderId] = true;
        pools[_ve].push(_attackerId);
        litigations[litigationId].attackerId = _attackerId;
        litigations[litigationId].defenderId = _defenderId;
        litigations[litigationId].market = msg.sender;
        (uint percentile, uint sods) = Percentile.computePercentileFromData(
            false,
            _gas,
            totalGas[_ve] + _gas,
            totalVotes[_ve],
            sum_of_diff_squared[_ve]
        );
        totalVotes[_ve] += 1;
        totalGas[_ve] += _gas;
        sum_of_diff_squared[_ve] = sods;
        gauges[_ve][_attackerId].percentile = percentile;
        gauges[_ve][_attackerId].endTime = block.timestamp + period / period * period;
        return percentile;
    }

    function veto(address _ve, uint _litigationId, uint _attackerId, uint _winnerId, uint _loserId) external {
        require(IAuth(contractAddress).devaddr_() == msg.sender);
        IStakeMarket(litigations[_litigationId].market).updateStakeFromVoter(
            _winnerId, 
            _loserId
        );
        isGauge[_ve][_winnerId] = false;
        isGauge[_ve][_loserId] = false;
        delete gauges[_ve][_attackerId];
        delete litigations[_litigationId];
        delete weights[_ve][_winnerId];
        delete weights[_ve][_loserId];

        emit GaugeClosed(_litigationId, true);
    }

    function updateStakeFromVoter(address _ve, uint _litigationId) external {
        require(gauges[_ve][litigations[_litigationId].attackerId].endTime < block.timestamp, "SV13");
        IStakeMarket(litigations[_litigationId].market).updateStakeFromVoter(
            weights[_ve][litigations[_litigationId].attackerId] > 0 ? litigations[_litigationId].attackerId : litigations[_litigationId].defenderId, 
            weights[_ve][litigations[_litigationId].attackerId] > 0 ? litigations[_litigationId].defenderId : litigations[_litigationId].attackerId
        );
        isGauge[_ve][litigations[_litigationId].attackerId] = false;
        isGauge[_ve][litigations[_litigationId].defenderId] = false;
        delete gauges[_ve][litigations[_litigationId].attackerId];
        delete litigations[_litigationId];
        delete weights[_ve][litigations[_litigationId].attackerId];
        delete weights[_ve][litigations[_litigationId].defenderId];

        emit GaugeClosed(_litigationId, false);
    }

    function length(address _ve) external view returns (uint) {
        return pools[_ve].length;
    }

    function claimBribes(address _ve, address[] memory _tokens, uint _tokenId) external {
        require(ve(_ve).isApprovedOrOwner(msg.sender, _tokenId));
        IStakeMarketBribe(_bribe()).getRewardForOwner(_ve, _tokenId, _tokens);
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Library.sol";

contract ContributorVoter {
    uint internal constant DURATION = 7 days; // rewards are released over 7 days
    address public contractAddress;

    mapping(address => uint) public totalWeight; // total voting weight
    mapping(address => uint[]) public pools; // all pools viable for incentives
    mapping(uint => mapping(address => address)) public gauges; // pool => gauge
    mapping(address => uint) public poolForGauge; // gauge => pool
    mapping(address => address) public bribes; // gauge => bribe
    mapping(uint => mapping(address => int256)) public weights; // pool => weight
    mapping(uint => mapping(string => int256)) public votes; // nft => pool => votes
    mapping(uint => mapping(address => uint)) public usedWeights;  // nft => total voting weight of user
    mapping(address => bool) public isGauge;

    event GaugeCreated(uint indexed pool, address _ve, address gauge, address creator, address indexed bribe);
    event Voted(uint indexed collectionId, uint tokenId, int256 weight, address ve, bool positive);
    event Abstained(uint indexed collectionId, uint tokenId, address _ve, int256 weight);
    event NotifyReward(address indexed sender, address indexed ve, uint amount);
    event UpdateContent(uint indexed collectionId, uint profileId, string title, string content, string[5] images);
    event DistributeReward(address indexed sender, address indexed gauge, uint amount);
    event DeactivatePitch(uint indexed collectionId);

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

    function updateContent(string[5] memory _images, string memory title, string memory _content) external {
        uint _collectionId = IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(msg.sender);
        uint _profileId = IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender);
        emit UpdateContent(_collectionId, _profileId, title, _content, _images);
    }

    function deactivatePitch() external {
        emit DeactivatePitch(IMarketPlace(
            IContract(contractAddress).marketCollections()
        ).addressToCollectionId(msg.sender));
    }

    function _reset(uint _tokenId, uint _collectionId, address _ve) internal {
        string memory cid = string(abi.encodePacked(_collectionId, _ve));
        int256 _votes = votes[_tokenId][cid];
        int256 _totalWeight = 0;

        if (_votes != 0) {
            _updateFor(gauges[_collectionId][_ve], _ve);
            weights[_collectionId][_ve] -= _votes;
            votes[_tokenId][cid] -= _votes;
            if (_votes > 0) {
                uint _profileId = IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender);
                IBribe(bribes[gauges[_collectionId][_ve]])._withdraw(uint(_votes), _profileId);
                _totalWeight += _votes;
            } else {
                _totalWeight -= _votes;
            }
            emit Abstained(_tokenId, _collectionId, _ve, _votes);
        }
        totalWeight[_ve] -= uint256(_votes);
        usedWeights[_tokenId][_ve] = 0;
    }

    function _vote(
        uint _tokenId, 
        uint _collectionId, 
        address _gauge, 
        address _ve, 
        bool positive
    ) internal {
        _reset(_tokenId, _collectionId, _ve);
        string memory cid = string(abi.encodePacked(_collectionId, _ve));
        int256 _userWeight = int256(ve(_ve).balanceOfNFT(_tokenId));
        int256 _totalWeight = 0;
        int256 _usedWeight = 0;
        
        if (isGauge[_gauge]) {
            int256 _poolWeight = positive? _userWeight : -_userWeight;
            require(votes[_tokenId][cid] == 0);
            require(_poolWeight != 0);
            _updateFor(_gauge, _ve);

            weights[_collectionId][_ve] += _poolWeight;
            votes[_tokenId][cid] += _poolWeight;
            if (positive) {
                uint _profileId = IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender);
                require(_profileId > 0);
                IAcceleratorVoter(bribes[_gauge]).deposit(uint(_poolWeight), _profileId);
            } else {
                _poolWeight = -_poolWeight;
            }
            _usedWeight += _poolWeight;
            _totalWeight += _poolWeight;
            emit Voted(_collectionId, _tokenId, _poolWeight, _ve, positive);
        }
        if (_usedWeight > 0) ve(_ve).voting(_tokenId);
        totalWeight[_ve] += uint256(_totalWeight);
        usedWeights[_tokenId][_ve] = uint256(_usedWeight);
    }

    function vote(
        uint tokenId, 
        uint _collectionId, 
        address _gauge, 
        address _ve, 
        bool positive
    ) external {
        require(ve(_ve).isApprovedOrOwner(msg.sender, tokenId));
        _vote(tokenId, _collectionId, _gauge, _ve, positive);
    }

    function createGauge(address _ve) external returns (address) {
        uint _collectionId = IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(msg.sender);
        require(gauges[_collectionId][_ve] == address(0x0), "exists");
        address _bribe = IBribe(IContract(contractAddress).referralBribeFactory()).createBribe(_ve);
        address _gauge = IGauge(IContract(contractAddress).businessGaugeFactory()).createGauge(_collectionId, _ve);
        erc20(ve(_ve).token()).approve(_gauge, type(uint).max);
        bribes[_gauge] = _bribe;
        gauges[_collectionId][_ve] = _gauge;
        poolForGauge[_gauge] = _collectionId;
        isGauge[_gauge] = true;
        _updateFor(_gauge, _ve);
        pools[_ve].push(_collectionId);
        emit GaugeCreated(_collectionId, _ve, _gauge, msg.sender, _bribe);
        return _gauge;
    }

    function length(address _ve) external view returns (uint) {
        return pools[_ve].length;
    }

    uint internal index;
    mapping(address => uint) internal supplyIndex;
    mapping(address => uint) public claimable;

    function notifyRewardAmount(address _ve, uint amount) external {
        _safeTransferFrom(ve(_ve).token(), msg.sender, address(this), amount); // transfer the distro in
        uint256 _ratio = amount * 1e18 / Math.max(1,totalWeight[_ve]); // 1e18 adjustment is removed during claim
        if (_ratio > 0) {
            index += _ratio;
        }
        emit NotifyReward(msg.sender, _ve, amount);
    }

    function updateFor(address[] memory _gauges, address _ve) external {
        for (uint i = 0; i < _gauges.length; i++) {
            _updateFor(_gauges[i], _ve);
        }
    }

    function updateForRange(uint start, uint end, address _ve) public {
        for (uint i = start; i < end; i++) {
            _updateFor(gauges[pools[_ve][i]][_ve], _ve);
        }
    }

    function updateAll(address _ve) external {
        updateForRange(0, pools[_ve].length, _ve);
    }

    function updateGauge(address _gauge, address _ve) external {
        _updateFor(_gauge, _ve);
    }

    function _updateFor(address _gauge, address _ve) internal {
        uint _collectionId = poolForGauge[_gauge];
        int256 _supplied = weights[_collectionId][_ve];
        if (_supplied > 0) {
            uint _supplyIndex = supplyIndex[_gauge];
            uint _index = index; // get global index0 for accumulated distro
            supplyIndex[_gauge] = _index; // update _gauge current position to global position
            uint _delta = _index - _supplyIndex; // see if there is any difference that need to be accrued
            if (_delta > 0) {
                uint _share = uint(_supplied) * _delta / 1e18; // add accrued difference for each supplied token
                claimable[_gauge] += _share;
            }
        } else {
            supplyIndex[_gauge] = index; // new users are set to the default global state
        }
    }

    function claimRewards(address[] memory _gauges, address[][] memory _tokens) external {
        for (uint i = 0; i < _gauges.length; i++) {
            IBusinessVoter(_gauges[i]).getReward(_tokens[i]);
        }
    }

    function claimBribes(address[] memory _bribes, address[][] memory _tokens) external {
        uint profileId = IProfile(IContract(contractAddress).profile()).addressToProfileId(msg.sender);
        for (uint i = 0; i < _bribes.length; i++) {
            IBribe(_bribes[i]).getRewardForOwner(profileId, _tokens[i]);
        }
    }
    
    function distribute(address _gauge, address _ve) public lock {
        IMinter(IContract(contractAddress).businessMinter()).update_period();
        _updateFor(_gauge, _ve);
        uint _claimable = claimable[_gauge];
        if (_claimable > 0) {
            claimable[_gauge] = 0;
            IGauge(_gauge).notifyRewardAmount(ve(_ve).token(), _claimable);
        }
        emit DistributeReward(msg.sender, _gauge, _claimable);
    }

    // function distro(address _ve) external {
    //     distribute(0, pools[_ve].length, _ve);
    // }

    // function distribute(address _ve) external {
    //     distribute(0, pools[_ve].length, _ve);
    // }

    // function distribute(uint start, uint finish, address _ve) public {
    //     for (uint x = start; x < finish; x++) {
    //         distribute(gauges[pools[_ve][x]][_ve], _ve);
    //     }
    // }

    // function distribute(address[] memory _gauges, address _ve) external {
    //     for (uint x = 0; x < _gauges.length; x++) {
    //         distribute(_gauges[x], _ve);
    //     }
    // }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}
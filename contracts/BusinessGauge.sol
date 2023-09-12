// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Library.sol";

// Gauges are used to incentivize pools, they emit reward tokens over 7 days for staked LP tokens
contract BusinessGauge {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public factory;

    uint internal constant week = 86400 * 7; // allows minting once per week (reset every Thursday 00:00 UTC)
    uint public active_period;

    uint public collectionId;
    address public contractAddress;
    mapping(address => uint) public balanceOf;
    EnumerableSet.AddressSet private tokens;
    mapping(address => uint) public bountyIds;
    mapping(address => address) public tokenToVoter;

    event Deposit(address indexed from, address token, uint amount);
    event Withdraw(address indexed from, address token, uint amount);
    event NotifyReward(address indexed from, address indexed reward, uint amount);
    event ClaimFees(address indexed from, uint claimed0, uint claimed1);
    event ClaimRewards(address indexed from, address indexed reward, uint amount);
    constructor(
        uint _collectionId, 
        address _ve, 
        address _voter,
        address _contractAddress
    ) {
        collectionId = _collectionId;
        tokens.add(ve(_ve).token());
        tokenToVoter[ve(_ve).token()] = _voter;
        factory = msg.sender;
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

    function addToken(address _ve, address _voter) external {
        require(msg.sender == factory, "BG1");
        tokens.add(ve(_ve).token());
        tokenToVoter[ve(_ve).token()] = _voter;
    }

    function _trustBounty() internal view returns(address) {
        return IContract(contractAddress).trustBounty();
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || factory == msg.sender, "BG2");
        contractAddress = _contractAddress;
        factory = IContract(_contractAddress).businessGaugeFactory();
    }

    function updateBounty(uint _bountyId) external {
        address trustBounty = _trustBounty();
        uint _collectionId = IMarketPlace(IContract(contractAddress).marketCollections()).addressToCollectionId(msg.sender);
        (address owner,address _token,,address _claimableBy,,,,,,) = ITrustBounty(trustBounty).bountyInfo(_bountyId);
        require(owner == msg.sender && collectionId == _collectionId && _claimableBy == address(0x0), "BG3");
        require(tokens.contains(_token), "BG4");
        if (_bountyId > 0 && bountyIds[_token] == 0) {
            ITrustBounty(trustBounty).attach(_bountyId);
        } else if (_bountyId == 0 && bountyIds[_token] > 0) {
            ITrustBounty(trustBounty).detach(_bountyId);
        }
        bountyIds[_token] = _bountyId;
    }

    function depositAll(address _token) external {
        deposit(_token, erc20(_token).balanceOf(msg.sender));
    }

    function deposit(address _token, uint amount) public lock {
        require(amount > 0, "BG5");
        require(tokens.contains(_token), "BG6");
        
        _safeTransferFrom(_token, msg.sender, address(this), amount);
        
        emit Deposit(msg.sender, _token, amount);
    }

    function withdrawAll() external {
        address trustBounty = _trustBounty();
        for (uint i = 0; i < tokens.length(); i++) {
            uint _amount;
            if (bountyIds[tokens.at(i)] > 0) {
                uint _limit = ITrustBounty(trustBounty).getBalance(
                    bountyIds[tokens.at(i)]
                );
                (,,,,,,uint endTime,,,) = ITrustBounty(trustBounty).bountyInfo(bountyIds[tokens.at(i)]);
                require(endTime > block.timestamp, "BG7");
                _amount = _limit - balanceOf[tokens.at(i)];
            } else {
                uint _max = Math.min(erc20(tokens.at(i)).balanceOf(address(this)), IBusinessVoter(factory).maxWithdrawable());
                _amount = _max - balanceOf[tokens.at(i)];
            }
            withdraw(tokens.at(i), _amount);
        }
    }
    
    function totalSupply(address _token) external view returns(uint supply) {
        supply = erc20(_token).balanceOf(address(this));
    }

    function withdraw(address _token, uint amount) internal lock {
        require(amount > 0, "BG8");
        _updateBalances();
        balanceOf[_token] += amount;
        _safeTransfer(_token, msg.sender, amount);

        emit Withdraw(msg.sender, _token, amount);
    }

    function _updateBalances() internal {
        if (block.timestamp >= active_period) {
            for (uint i = 0; i < tokens.length(); i++) {
                // only reinitialize tokens with a bounty
                if (bountyIds[tokens.at(i)] > 0) balanceOf[tokens.at(i)] = 0;
            }
            active_period = block.timestamp / week * week;
        }
    }

    function getReward(address[] memory _tokens) external lock {
        _unlocked = 1;
        for(uint i = 0; i < _tokens.length; i++) {
            IBusinessVoter(msg.sender).distribute(address(this), _tokens[i]);
        }
        _unlocked = 2;
    }

    function notifyRewardAmount(address token, uint amount) external lock {
        // require(voters[msg.sender]);
        require(amount > 0, "BG9");

        _safeTransferFrom(token, msg.sender, address(this), amount);

        emit NotifyReward(msg.sender, token, amount);
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        require(token.code.length > 0, "BG10");
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BG11");
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0, "BG12");
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BG13");
    }

    function _safeApprove(address token, address spender, uint256 value) internal {
        require(token.code.length > 0, "BG14");
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(erc20.approve.selector, spender, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BG15");
    }
}

contract BusinessGaugeFactory {
    address public contractAddress;
    mapping(address => bool) public voters;
    mapping(uint => address) public hasGauge;
    uint public maxWithdrawable;
    
    constructor() { maxWithdrawable = type(uint).max; }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender, "NT2");
        contractAddress = _contractAddress;
    }

    function setContractAddressAt(address _businessGauge) external {
        IMarketPlace(_businessGauge).setContractAddress(contractAddress);
    }

    function updateVoter(address[] memory _voters, bool _add) external {
        require(msg.sender == IAuth(contractAddress).devaddr_(), "BGF1");
        for (uint i = 0; i < _voters.length; i++) {
            voters[_voters[i]] = _add;
        }
    }

    function createGauge(uint _collectionId, address _ve) external returns (address) {
        require(voters[msg.sender], "BGF2");
        if (hasGauge[_collectionId] != address(0x0)) {
            IGauge(hasGauge[_collectionId]).addToken(_ve, msg.sender);
            return hasGauge[_collectionId];
        } else {
            address last_gauge = address(new BusinessGauge(
                _collectionId, 
                _ve, 
                msg.sender,
                contractAddress
            ));
            hasGauge[_collectionId] = last_gauge;
            return last_gauge;
        }
    }

    function updateMaxWithdrawable(uint _maxWithdrawable) external {
        require(IAuth(contractAddress).devaddr_() == msg.sender, "BGF3");
        maxWithdrawable = _maxWithdrawable;
    }
}

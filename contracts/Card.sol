// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Library.sol";

// Gauges are used to incentivize pools, they emit reward tokens over 7 days for staked LP tokens
contract Card {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    address public _ve;
    address public contractAddress;
    mapping(uint => EnumerableSet.AddressSet) private _tokens;
    mapping(address => uint) public tokenIds;
    mapping(address => mapping(address => uint)) public balance;
    
    event TransferBalance(uint from, uint to, address token, uint amount);
    event AddBalance(address owner, address token, uint amount);
    event RemoveBalance(address owner, address token, uint amount);
    event ExecutePurchase(
        address _collection,
        address _referrer,
        address _token,
        string _productId,
        uint _isPaywall,
        uint _price,
        uint _tokenId,
        uint _userTokenId,
        uint _identityTokenId,
        uint[] _options
    );

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    modifier onlyAdmin() {
        require(IAuth(contractAddress).devaddr_() == msg.sender);
        _;
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }

    function getAllTokens(address _owner, uint _start) external view returns(address[] memory _allTokens) {
        _allTokens = new address[](_tokens[tokenIds[_owner]].length() - _start);
        for (uint i = _start; i < _tokens[tokenIds[_owner]].length(); i++) {
            _allTokens[i] = _tokens[tokenIds[_owner]].at(i);
        }
    }
    
    function addBalance(address _owner, address _token, uint _amount) external lock {
        require(tokenIds[_owner] > 0, "C6");
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        if (balance[msg.sender][_token] == 0) {
            _tokens[tokenIds[_owner]].add(_token);
        }
        balance[_owner][_token] += _amount;

        emit AddBalance(_owner, _token, _amount);
    }

    function removeBalance(address _token, uint _amount) external lock {
        require(tokenIds[msg.sender] > 0, "C6");
        if (balance[msg.sender][_token] == _amount) {
            _tokens[tokenIds[msg.sender]].remove(_token);
        }
        balance[msg.sender][_token] -= _amount;
        IERC20(_token).safeTransfer(msg.sender, _amount);

        emit RemoveBalance(msg.sender, _token, _amount);
    }

    function transferBalance(uint from, uint to, address _token, uint _amount) external onlyAdmin {
        balance[ve(_ve).ownerOf(from)][_token] -= _amount;
        balance[ve(_ve).ownerOf(to)][_token] += _amount;

        emit TransferBalance(from, to, _token, _amount);
    }

    function executePurchase(
        address _collection,
        address _referrer,
        address _token,
        string memory _productId,
        uint _isPaywall,
        uint _price,
        uint _tokenId,
        uint _userTokenId,
        uint _identityTokenId,
        uint[] memory _options
    ) external onlyAdmin {
        address _owner = ve(_ve).ownerOf(_tokenId);
        address marketPlace = _isPaywall == 2 
        ? IContract(contractAddress).paywallMarketTrades()
        : _isPaywall == 1
        ? IContract(contractAddress).nftMarketTrades()
        : IContract(contractAddress).marketTrades();
        if (balance[_owner][_token] >= _price) {
            balance[_owner][_token] -= _price;
        } else {
            IERC20(_token).safeTransferFrom(_owner, address(this), _price - balance[_owner][_token]);
            balance[_owner][_token] = 0;
        }
        erc20(_token).approve(marketPlace, _price);
        IMarketPlace(marketPlace).buyWithContract(
            _collection, 
            _owner,
            _referrer,
            _productId, 
            _userTokenId, 
            _identityTokenId, 
            _options
        );
        emit ExecutePurchase(
            _collection,
            _referrer,
            _token,
            _productId,
            _isPaywall,
            _price,
            _tokenId,
            _userTokenId,
            _identityTokenId,
            _options
        );
    }

    function updateVe(address __ve) external onlyAdmin {
        _ve = __ve;
    }

    function updateTokenId(uint _tokenId) external {
        require(ve(_ve).ownerOf(_tokenId) == msg.sender, "C1");
        tokenIds[msg.sender] = _tokenId;
    }

    function updateOwner(address _prevOwner, uint _tokenId) external {
        require(ve(_ve).ownerOf(_tokenId) == msg.sender, "C2");
        require(tokenIds[_prevOwner] == _tokenId, "C3");
        tokenIds[msg.sender] == _tokenId;
        for (uint i = 0; i < _tokens[_tokenId].length(); i++) {
            address _token = _tokens[_tokenId].at(i);
            balance[msg.sender][_token] += balance[_prevOwner][_token];
            balance[_prevOwner][_token] = 0;
        }
    }
}
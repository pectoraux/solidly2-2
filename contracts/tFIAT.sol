// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import './Library.sol';

contract tFIAT is AML {
    address public minter;
    constructor(
        string memory _name, 
        string memory _symbol,
        address _contractAddress, 
        address _devaddr,
        address _trustBounty
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
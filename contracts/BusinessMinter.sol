// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "./Library.sol";

// codifies the minting rules as per ve(3,3), abstracted from the token to support any token that allows minting

contract BusinessMinter {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint internal constant week = 86400 * 7; // allows minting once per week (reset every Thursday 00:00 UTC)
    mapping(address => uint) public currentDebt;
    address public contractAddress;
    uint public weekly = 1000e18;
    uint public active_period;
    EnumerableSet.AddressSet private _ves;
    EnumerableSet.AddressSet private _ve_dists;
    uint internal constant lock = 86400 * 7 * 52 * 4;
    EnumerableSet.AddressSet private _payswapContracts;
    mapping(address => uint) public currentVolume;
    mapping(address => uint) public previousVolume;
    mapping(address => uint) private referralsPercent;
    mapping(address => uint) private businessesPercent;
    mapping(address => uint) private acceleratorPercent;
    mapping(address => uint) private contributorsPercent;
    uint public teamPercent = 100;
    uint public burnPercent = 9000;
    mapping(address => uint) public burnFees;
    mapping(address => uint) public treasuryFees;
    address internal initializer;
    bool _initial = true;

    event Mint(address indexed sender, address _ve, uint weekly, uint circulating_supply, uint growth);

    constructor() {
        initializer = msg.sender;
        active_period = (block.timestamp + (2*week)) / week * week;
    }

    function initialize() external {
        require(initializer == msg.sender);
        for (uint i = 0; i < _ves.length(); i++) {
            address _ve = _ves.at(i);
            underlying _token = underlying(ve(_ve).token());
            _token.mint(address(this), weekly);
            _token.approve(address(_ve), weekly);
            ve(_ve).create_lock_for(weekly, lock, msg.sender);
            currentVolume[_ve] = weekly;
        }
        initializer = address(0);
        active_period = (block.timestamp + week) / week * week;
    }

    function updateParameters(uint _teamPercent, uint _burnPercent) external {
        require(IAuth(contractAddress).devaddr_() == msg.sender);
        burnPercent = _burnPercent;   
        teamPercent = _teamPercent;   
    }

    function getAllVes() external view returns(address[] memory __ves) {
        __ves = new address[](_ves.length());
        for (uint i = 0; i < _ves.length(); i++) {
            __ves[i] = _ves.at(i);
        }
    }

    function updateVes(address[] memory __ves, address[] memory __ve_dists, bool _add) external {
        require(msg.sender == IAuth(contractAddress).devaddr_());
        require(__ves.length == __ve_dists.length);
        for (uint i = 0; i < __ves.length; i++) {
            if (_add) {
                _ves.add(__ves[i]);
                _ve_dists.add(__ve_dists[i]);
            } else {
                _ves.remove(__ves[i]);
                _ve_dists.remove(__ve_dists[i]);
            }
        }
    }

    function _updatePercentages(address _ve) internal {
        uint totalWeightReferrals = IVoter(IContract(contractAddress).referralVoter()).totalWeight(_ve);
        uint totalWeightBusinesses = IVoter(IContract(contractAddress).businessVoter()).totalWeight(_ve);
        uint totalWeightAccelerator = IVoter(IContract(contractAddress).acceleratorVoter()).totalWeight(_ve);
        uint totalWeightContributors = IVoter(IContract(contractAddress).contributorVoter()).totalWeight(_ve);
        uint totalWeight = totalWeightReferrals + totalWeightBusinesses + totalWeightAccelerator + totalWeightContributors;
        referralsPercent[_ve] = totalWeightReferrals / totalWeight;
        businessesPercent[_ve] = totalWeightBusinesses / totalWeight;
        acceleratorPercent[_ve] = totalWeightAccelerator / totalWeight;
        contributorsPercent[_ve] = totalWeightContributors / totalWeight;
    }

    function setContractAddress(address _contractAddress) external {
        require(contractAddress == address(0x0) || IAuth(contractAddress).devaddr_() == msg.sender);
        contractAddress = _contractAddress;
    }
    
    // weekly emission takes the max of calculated (aka target) emission versus circulating tail end emission
    // calculate circulating supply as total token supply - locked supply
    function circulating_supply(address _ve) public view returns (uint) {
        return underlying(ve(_ve).token()).totalSupply() - ve(_ve).totalSupply();
    }

    function weekly_emission(address _ve) public view returns (uint _amount) {
        if (currentVolume[_ve] >= previousVolume[_ve] + currentDebt[_ve]) {
            _amount = currentVolume[_ve] - previousVolume[_ve] - currentDebt[_ve];
        }
    }

    // calculate inflation and adjust ve balances accordingly
    function calculate_growth(address _ve, uint _minted) public view returns (uint) {
        return ve(_ve).totalSupply() * _minted / underlying(ve(_ve).token()).totalSupply();
    }

    function updatePayswapContracts(address _contract, bool _add) external {
        require(msg.sender == IAuth(contractAddress).devaddr_());
        if (_add) {
            _payswapContracts.add(_contract);
        } else {
            _payswapContracts.remove(_contract);
        }
    }

    function _getAllWeeklyVolume(address _ve) internal {
        uint _totalVolume = INFTicket(IContract(contractAddress).nfticket()).transactionVolume(_ve);
        for (uint i = 0; i < _payswapContracts.length(); i++) {
            uint _fee = IAuditor(_payswapContracts.at(i)).withdrawFees(ve(_ve).token());
            treasuryFees[ve(_ve).token()] += _fee;
            uint _percent = IARPHelper(_payswapContracts.at(i)).tradingFee();
            _totalVolume += _fee * 10000 / _percent;
        }
        if (!_initial) {
            previousVolume[_ve] = currentVolume[_ve];
            currentVolume[_ve] = _totalVolume;
            if (_totalVolume < previousVolume[_ve] + currentDebt[_ve]) {
                currentDebt[_ve] += previousVolume[_ve] - _totalVolume;
            }
        }
        _initial = false;
    }

    function withdrawFees(address _token) external returns(uint _amount) {
        address team = IAuth(contractAddress).devaddr_();
        require(msg.sender == team);
        _amount = treasuryFees[_token];
        require(underlying(_token).transfer(address(team), _amount));
        treasuryFees[_token] = 0;
        return _amount;
    }

    // update period can only be called once per cycle (1 week)
    function update_period() external returns (uint) {
        uint _period = active_period;
        if (block.timestamp >= _period + week && initializer == address(0)) { // only trigger if new week
            _period = (block.timestamp + week) / week * week;
            active_period = _period;
            for (uint i = 0; i < _ves.length(); i++) {
                address _ve = _ves.at(i);
                _getAllWeeklyVolume(_ve);
                underlying _token = underlying(ve(_ve).token());
                ve_dist _ve_dist = ve_dist(_ve_dists.at(i));
                weekly = weekly_emission(_ve);
                uint _growth = calculate_growth(_ve, weekly);
                uint _required = _growth + weekly;
                uint _balanceOf = _token.balanceOf(address(this)) - treasuryFees[address(_token)] - burnFees[address(_token)];
                if (_balanceOf < _required) {
                    _token.mint(address(this), _required-_balanceOf);
                }

                require(_token.transfer(address(_ve_dist), _growth));
                _ve_dist.checkpoint_token(); // checkpoint token balance that was just minted in ve_dist
                _ve_dist.checkpoint_total_supply(); // checkpoint supply
                
                // send team's percentage
                uint _treasuryFee = weekly * teamPercent / 10000;
                uint _burnFee = weekly * burnPercent / 10000;
                treasuryFees[address(_token)] += _treasuryFee;
                burnFees[address(_token)] += _burnFee;
                uint _weeklyLessTeam = weekly - _treasuryFee - _burnFee;
                // send other percentages
                _updatePercentages(_ve);

                //businesses
                _token.approve(IContract(contractAddress).businessVoter(), _weeklyLessTeam * businessesPercent[_ve]);
                IBusinessVoter(IContract(contractAddress).businessVoter()).notifyRewardAmount(_ve, _weeklyLessTeam * businessesPercent[_ve]);
                
                //referrals
                _token.approve(IContract(contractAddress).referralVoter(), _weeklyLessTeam * referralsPercent[_ve]);
                IBusinessVoter(IContract(contractAddress).referralVoter()).notifyRewardAmount(_ve, _weeklyLessTeam * referralsPercent[_ve]);

                //contributors
                _token.approve(IContract(contractAddress).contributorVoter(), _weeklyLessTeam * contributorsPercent[_ve]);
                IBusinessVoter(IContract(contractAddress).contributorVoter()).notifyRewardAmount(_ve, _weeklyLessTeam * contributorsPercent[_ve]);
                
                //accelerator
                _token.approve(IContract(contractAddress).acceleratorVoter(), _weeklyLessTeam * acceleratorPercent[_ve]);
                IBusinessVoter(IContract(contractAddress).acceleratorVoter()).notifyRewardAmount(_ve, _weeklyLessTeam * acceleratorPercent[_ve]);
                
                emit Mint(msg.sender, _ve, weekly, circulating_supply(_ve), _growth);
            }   
        }
        return _period;
    }
}

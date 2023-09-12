// // SPDX-License-Identifier: GPL-3.0-or-later
// pragma solidity 0.8.17;

// import "./Percentile.sol";

// contract SponsorCardReceiver is Percentile, ReentrancyGuard {
//     struct SponsorCard {
//         uint totalPaid;
//         uint percentile;
//         uint ballerBoost; // needs to be divided by 10 before applying to totalPaid
//     }
//     address[] allSponsors;
//     address public sponsorDev;
//     mapping(address => bool) public isSponsor;
//     mapping(address => SponsorCard) public sponsorCards;
//     ISponsorCardFactory public sponsorFactory;
//     // booster contract => booster tokenId => sponsor
//     mapping(address => mapping(uint => address)) public attached;

//     constructor(address _factory, address _devaddr) { 
//         sponsorDev = _devaddr; 
//         sponsorFactory = ISponsorCardFactory(_factory);
//     }

//     function setDev(address _dev) external {
//         require(msg.sender == sponsorDev, "SponsorReceiver: Only admin");
//         sponsorDev = _dev;
//     }

//     function getAllSponsors() external view returns(address[] memory sponsors, uint[] memory percentiles) {
//         uint j = 0;
//         uint _length;
//         for (uint i = 0; i < allSponsors.length; i++) {
//             if(isSponsor[allSponsors[i]]) {
//                 _length++;
//             }
//         }
//         sponsors = new address[](_length);
//         percentiles = new uint[](_length);
//         for (uint i = 0; i < _length; i++) {
//             if(isSponsor[allSponsors[i]]) {
//                 sponsors[j] = allSponsors[i];
//                 percentiles[j] = sponsorCards[allSponsors[i]].percentile;
//                 j += 1;
//             }
//         }
//     }

//     function getAllPaidFromSponsor() public view returns(uint totalPaid) {
//         for (uint i = 0; i < allSponsors.length; i++) {
//             if(isSponsor[allSponsors[i]]) {
//                 totalPaid += ISponsorCard(allSponsors[i]).getPaidPayable(address(this));
//             }
//         }
//     }

//     function addSponsorCard() external {
//         isSponsor[msg.sender] = true;
//         sponsorCards[msg.sender] = SponsorCard({
//             totalPaid: 0,
//             percentile: 0,
//             ballerBoost: 0
//         });
//     }

//     function removeSponsorCard() external {
//         delete isSponsor[msg.sender];
//         delete sponsorCards[msg.sender];
//     }

//     function getReward(address _card) public nonReentrant {
//         if (isSponsor[_card]) {
//             update_sponsor(_card);
//             ISponsorCard(_card).payInvoicePayable(address(this));
//         }
//     }

//     function getRewards(address[] memory _cards) public {
//         for (uint i = 0; i < _cards.length; i++) {
//             getReward(_cards[i]);
//         }
//     }

//     function getAllRewards() public {
//         getRewards(allSponsors);
//     }

//     function attachSponsorCard(
//         address boostContract, 
//         uint boostTokenId, 
//         address sponsor
//     ) external {
//         require(ISponsorCardFactory(sponsorFactory).canBoost(boostContract), "Cannot boost");
//         require(erscr(boostContract).balanceOf(msg.sender, boostTokenId) > 0, "Not owner");
//         erscr(boostContract).safeTransferFrom(msg.sender, address(this), boostTokenId);
//         uint[] memory _ids = new uint[](1);
//         _ids[0] = boostTokenId;
//         erscr(boostContract).batchAttach(_ids, 0, msg.sender);
//         sponsorCards[msg.sender].ballerBoost = Math.min(
//             ISponsorCardFactory(sponsorFactory).MAX_BOOST(),
//             sponsorCards[msg.sender].ballerBoost 
//             + erscr(boostContract).boostingPower(boostTokenId)
//         );
//         attached[boostContract][boostTokenId] = sponsor;
//     }

//     function detachSponsorCard(
//         address boostContract, 
//         uint boostTokenId
//     ) external {
//         require(attached[boostContract][boostTokenId] != address(0), "Not attached");
//         require(erscr(boostContract).getLender(boostTokenId) == msg.sender, "Not owner");
//         delete attached[boostContract][boostTokenId];
//         sponsorCards[msg.sender].ballerBoost -= erscr(boostContract).boostingPower(boostTokenId);
//         uint[] memory _ids = new uint[](1);
//         _ids[0] = boostTokenId;
//         erscr(boostContract).batchDetach(_ids);
//         erscr(boostContract).safeTransfer(msg.sender, boostTokenId);
//     }

//     function _updateAccountsDeposits(address _card, uint _amount) internal virtual {
        
//     }

//     function update_sponsor(address _card) public {
//         uint amount = ISponsorCard(_card).getDuePayable(address(this));
//         if(isSponsor[_card] && amount > 0) {
//             sponsorCards[_card].totalPaid += Math.max(
//             amount, sponsorCards[_card].ballerBoost * amount / 10) ;
//             computePercentile(sponsorCards[_card].totalPaid);
//             sponsorCards[_card].percentile = getPercentile(zscore);
//             _updateAccountsDeposits(_card, amount);
//         }
//     }

//     function transferDueToNote(address _card) external {
//         require(msg.sender == sponsorDev, "SponsorReceiver: Only admin");
//         return ISponsorCard(_card).transferDueToNote(sponsorDev);
//     }

//     function notifyRewardAmount(address token, uint _amount) external virtual {
//         require(_amount > 0, "Invalid amount");
//         erc20(token).transferFrom(msg.sender, address(this), _amount);
//     }
// }

const { expect } = require("chai");
const { ethers } = require("hardhat");

function getCreate2Address(
  factoryAddress,
  [tokenA, tokenB],
  bytecode
) {
  const [token0, token1] = tokenA < tokenB ? [tokenA, tokenB] : [tokenB, tokenA]
  const create2Inputs = [
    '0xff',
    factoryAddress,
    keccak256(solidityPack(['address', 'address'], [token0, token1])),
    keccak256(bytecode)
  ]
  const sanitizedInputs = `0x${create2Inputs.map(i => i.slice(2)).join('')}`
  return getAddress(`0x${keccak256(sanitizedInputs).slice(-40)}`)
}

describe("core", function () {

  let token;
  let ust;
  let stakeMarket;
  let stakeMarketVoter;
  let stakeMarketBribe;
  let owner;
  let owner2;
  let owner3;
  let vavaHelper;
  let vaFactory;
  let valuepoolVoter;
  let Vava;
  let Va;
  let trustBounties;
  let poolGauge;

  it("1) deploy market place", async function () {
    [owner, owner2, owner3] = await ethers.getSigners(3);
    token = await ethers.getContractFactory("Token");
    ust = await token.deploy('ust', 'ust', 6, owner.address);
    await ust.mint(owner.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.mint(owner2.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.mint(owner3.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.deployed();

    ve_underlying = await token.deploy('FreeToken', 'FT', 18, owner.address);
    await ve_underlying.mint(owner.address, ethers.BigNumber.from("2000000000000000000000000000"));
    await ve_underlying.mint(owner2.address, ethers.BigNumber.from("1000000000000000000000000000"));
    await ve_underlying.mint(owner3.address, ethers.BigNumber.from("1000000000000000000000000000"));
    
    const ContractAddresses =  await ethers.getContractFactory("contracts/MarketPlace.sol:ContractAddresses")
    const NFTicket = await ethers.getContractFactory("contracts/MarketPlace.sol:NFTicket");
    const NFTicketHelper = await ethers.getContractFactory("contracts/MarketPlace.sol:NFTicketHelper");
    const NFTicketHelper2 = await ethers.getContractFactory("contracts/MarketPlace.sol:NFTicketHelper2");
    const MarketPlaceEvents = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceEvents");
    const MarketPlaceCollection = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceCollection");
    const MarketPlaceOrders = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceOrders");
    const NFTMarketPlaceOrders = await ethers.getContractFactory("contracts/NFTMarketPlace.sol:NFTMarketPlaceOrders");
    const PaywallMarketPlaceOrders = await ethers.getContractFactory("contracts/PaywallMarketPlace.sol:PaywallMarketPlaceOrders");
    const MarketPlaceTrades = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceTrades");
    const MarketPlaceHelper = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceHelper");
    const MarketPlaceHelper3 = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceHelper3");
    const ValuepoolVoter = await ethers.getContractFactory("ValuepoolVoter");
    const BusinessGaugeFactory = await ethers.getContractFactory("BusinessGaugeFactory");
    const BusinessBribeFactory = await ethers.getContractFactory("BusinessBribeFactory");
    const ReferralBribeFactory = await ethers.getContractFactory("ReferralBribeFactory");
    const VavaHelper = await ethers.getContractFactory("ValuepoolHelper");
    const VavaHelper2 = await ethers.getContractFactory("ValuepoolHelper2");
    const RandomNumberGenerator = await ethers.getContractFactory("contracts/Vava.sol:RandomNumberGenerator");
    const Auditor = await ethers.getContractFactory("Auditor");
    const AuditorHelper = await ethers.getContractFactory("AuditorHelper");
    const AuditorHelper2 = await ethers.getContractFactory("AuditorHelper2");
    const AuditorFactory = await ethers.getContractFactory("AuditorFactory");
    const StakeMarket = await ethers.getContractFactory("StakeMarket");
    const StakeMarketNote = await ethers.getContractFactory("StakeMarketNote");
    const SSI = await ethers.getContractFactory("SSI");
    const SponsorFactory = await ethers.getContractFactory("SponsorFactory");
    const TrustBounties = await ethers.getContractFactory("TrustBounties");
    const TrustBountiesHelper = await ethers.getContractFactory("TrustBountiesHelper");
    const BusinessVoter = await ethers.getContractFactory("BusinessVoter");
    const ReferralVoter = await ethers.getContractFactory("ReferralVoter");
    const Profile = await ethers.getContractFactory("Profile");
    ve_distContract = await ethers.getContractFactory("contracts/ve_dist.sol:ve_dist");
    const StakeMarketBribe =  await ethers.getContractFactory("Bribe")
    const BusinessMinter =  await ethers.getContractFactory("BusinessMinter")
    const AcceleratorVoter =  await ethers.getContractFactory("AcceleratorVoter")
    const ContributorVoter =  await ethers.getContractFactory("ContributorVoter")
    const NFTSVG = await ethers.getContractFactory("contracts/NFTMarketPlace.sol:NFTSVG")
    const Percentile = await ethers.getContractFactory("contracts/Library.sol:Percentile")
    let percentile = await Percentile.deploy()
    
    BusinessBribe = await ethers.getContractFactory("BusinessBribe");
    BusinessGauge = await ethers.getContractFactory("BusinessGauge");

    ReferralBribe = await ethers.getContractFactory("ReferralBribe");

    vecontract = await ethers.getContractFactory("contracts/ve.sol:mve",{
      libraries: {
        Percentile: percentile.address,
      },
    });
    
    const VeFactory = await ethers.getContractFactory("contracts/Vava.sol:veFactory",{
      libraries: {
        Percentile: percentile.address,
      },
    });

    const VavaFactory = await ethers.getContractFactory("ValuepoolFactory",{
      libraries: {
        Percentile: percentile.address,
      },
    });

    const AuditorNote = await ethers.getContractFactory("AuditorNote",{
      libraries: {
        Percentile: percentile.address,
      },
    });

    Va = await ethers.getContractFactory("contracts/Vava.sol:Ve",{
      libraries: {
        Percentile: percentile.address,
      },
    });

    Vava = await ethers.getContractFactory("contracts/Vava.sol:Valuepool",{
      libraries: {
        Percentile: percentile.address,
      },
    });

    const ProfileHelper = await ethers.getContractFactory("ProfileHelper",{
      libraries: {
        Percentile: percentile.address,
      },
    });

    const StakeMarketVoter = await ethers.getContractFactory("StakeMarketVoter", {
      libraries: {
        Percentile: percentile.address,
      },
    })

    const SponsorNote = await ethers.getContractFactory("SponsorNote",{
      libraries: {
        Percentile: percentile.address,
      },
    });

    const MarketPlaceHelper2 = await ethers.getContractFactory("contracts/MarketPlace.sol:MarketPlaceHelper2",{
      libraries: {
        Percentile: percentile.address,
      },
    });

  ve = await vecontract.deploy(ve_underlying.address);
  await ve.deployed()

  ve_dist = await ve_distContract.deploy(ve.address);
  await ve_dist.deployed()

  acceleratorVoter = await AcceleratorVoter.deploy();
  await acceleratorVoter.deployed()

  contributorVoter = await ContributorVoter.deploy();
  await contributorVoter.deployed()

  businessBribeFactory = await BusinessBribeFactory.deploy();
  await businessBribeFactory.deployed()

  businessMinter = await BusinessMinter.deploy();
  await businessMinter.deployed()

  businessGaugeFactory = await BusinessGaugeFactory.deploy();
  await businessGaugeFactory.deployed()

  referralBribeFactory = await ReferralBribeFactory.deploy();
  await referralBribeFactory.deployed()

  nftSvg = await NFTSVG.deploy()
  await nftSvg.deployed()

  auditorNote = await AuditorNote.deploy();
  await auditorNote.deployed()

  auditorHelper = await AuditorHelper.deploy();
  await auditorHelper.deployed()

  businessVoter = await BusinessVoter.deploy();
  await businessVoter.deployed()

  referralVoter = await ReferralVoter.deploy();
  await referralVoter.deployed()

  sponsorFactory = await SponsorFactory.deploy();
  await sponsorFactory.deployed()

  sponsorNote = await SponsorNote.deploy();
  await sponsorNote.deployed()

  ssi = await SSI.deploy()
  await ssi.deployed()

  profile = await Profile.deploy()
  await profile.deployed()

  profileHelper = await ProfileHelper.deploy()
  await profileHelper.deployed()

  stakeMarket = await StakeMarket.deploy()
  await stakeMarket.deployed()

  stakeMarketNote = await StakeMarketNote.deploy()
  await stakeMarketNote.deployed()

  stakeMarketBribe = await StakeMarketBribe.deploy()
  await stakeMarketBribe.deployed()

  stakeMarketVoter = await StakeMarketVoter.deploy()
  await stakeMarketVoter.deployed()

  contractAddresses = await ContractAddresses.deploy()
  await contractAddresses.deployed()

  nfticket = await NFTicket.deploy()
  await nfticket.deployed()

  nfticketHelper = await NFTicketHelper.deploy()
  await nfticketHelper.deployed()

  nfticketHelper2 = await NFTicketHelper2.deploy(contractAddresses.address)
  await nfticketHelper2.deployed()

  marketPlaceEvents = await MarketPlaceEvents.deploy()
  await marketPlaceEvents.deployed()

  marketPlaceCollection = await MarketPlaceCollection.deploy(
    owner.address,
    contractAddresses.address
  )

  marketPlaceOrders = await MarketPlaceOrders.deploy()
  await marketPlaceOrders.deployed()

  paywallMarketPlaceOrders = await PaywallMarketPlaceOrders.deploy()
  await paywallMarketPlaceOrders.deployed()

  nftMarketPlaceOrders = await NFTMarketPlaceOrders.deploy()
  await nftMarketPlaceOrders.deployed()

  marketPlaceTrades = await MarketPlaceTrades.deploy()
  await marketPlaceTrades.deployed()

  marketPlaceHelper = await MarketPlaceHelper.deploy()
  await marketPlaceHelper.deployed()

  marketPlaceHelper2 = await MarketPlaceHelper2.deploy()
  await marketPlaceHelper2.deployed()

  marketPlaceHelper3 = await MarketPlaceHelper3.deploy()
  await marketPlaceHelper3.deployed()

  vavaFactory = await VavaFactory.deploy(contractAddresses.address)
  await vavaFactory.deployed()

  vavaHelper = await VavaHelper.deploy()
  await vavaHelper.deployed()
  
  vavaHelper2 = await VavaHelper2.deploy()
  await vavaHelper2.deployed()

  veFactory = await VeFactory.deploy()
  await veFactory.deployed()

  valuepoolVoter = await ValuepoolVoter.deploy()
  await valuepoolVoter.deployed()

  trustBounties = await TrustBounties.deploy()
  await trustBounties.deployed()

  trustBountiesHelper = await TrustBountiesHelper.deploy()
  await trustBountiesHelper.deployed()

  // set ups
  await ve.setVoter(stakeMarketVoter.address)
  await ve.setVoter(acceleratorVoter.address)
  await ve.setVoter(businessVoter.address)
  await ve.setVoter(contributorVoter.address)
  await ve.setVoter(referralVoter.address)

  await nftSvg.setContractAddress(contractAddresses.address)
  console.log("nftSvg.setContractAddress===========> Done!")

  await acceleratorVoter.setContractAddress(contractAddresses.address)
  console.log("acceleratorVoter.setContractAddress===========> Done!")

  await contributorVoter.setContractAddress(contractAddresses.address)
  console.log("contributorVoter.setContractAddress===========> Done!")

  await businessGaugeFactory.setContractAddress(contractAddresses.address)
  console.log("businessGaugeFactory.setContractAddress===========> Done!")

  await businessMinter.setContractAddress(contractAddresses.address)
  console.log("businessMinter.setContractAddress===========> Done!")

  await businessBribeFactory.setContractAddress(contractAddresses.address)
  console.log("businessBribeFactory.setContractAddress===========> Done!")
  
  await referralBribeFactory.setContractAddress(contractAddresses.address)
  console.log("referralBribeFactory.setContractAddress===========> Done!")

  await businessVoter.setContractAddress(contractAddresses.address)
  console.log("businessVoter.setContractAddress===========> Done!")
  
  await referralVoter.setContractAddress(contractAddresses.address)
  console.log("referralVoter.setContractAddress===========> Done!")
  
  await trustBounties.setContractAddress(contractAddresses.address)
  console.log("trustBounties.setContractAddress===========> Done!")

  await trustBountiesHelper.setContractAddress(contractAddresses.address)
  console.log("trustBountiesHelper.setContractAddress===========> Done!")

  await auditorNote.setContractAddress(contractAddresses.address)
  console.log("auditorNote.setContractAddress===========> Done!")

  await auditorHelper.setContractAddress(contractAddresses.address)
  console.log("auditorHelper.setContractAddress===========> Done!")

  await sponsorFactory.setContractAddress(contractAddresses.address)
  console.log("sponsorFactory.setContractAddress===========> Done!")

  await sponsorNote.setContractAddress(contractAddresses.address)
  console.log("sponsorNote.setContractAddress===========> Done!")

  await valuepoolVoter.setContractAddress(contractAddresses.address)
  console.log("valuepoolVoter.setContractAddress===========> Done!")
  
  await vavaHelper2.setContractAddress(contractAddresses.address)
  console.log("vavaHelper2.setContractAddress===========> Done!")
  
  await vavaHelper.setContractAddress(contractAddresses.address)
  console.log("vavaHelper.setContractAddress===========> Done!")

  await ssi.setContractAddress(contractAddresses.address)
  console.log("ssi.setContractAddress===========> Done!")

  await stakeMarket.setContractAddress(contractAddresses.address)
  console.log("stakeMarket.setContractAddress===========> Done!")

  await stakeMarketNote.setContractAddress(contractAddresses.address)
  console.log("stakeMarketNote.setContractAddress===========> Done!")
  
  await stakeMarketBribe.setContractAddress(contractAddresses.address)
  console.log("stakeMarketBribe.setContractAddress===========> Done!")

  await stakeMarketVoter.setContractAddress(contractAddresses.address)
  console.log("stakeMarketVoter.setContractAddress===========> Done!")

  await profile.setContractAddress(contractAddresses.address)
  console.log("profile.setContractAddress===========> Done!")

  await profileHelper.setContractAddress(contractAddresses.address)
  console.log("profileHelper.setContractAddress===========> Done!")

  await nfticket.setContractAddress(contractAddresses.address)
  console.log("nfticket.setContractAddress===========> Done!")
  
  await nfticketHelper.setContractAddress(contractAddresses.address)
  console.log("nfticketHelper.setContractAddress===========> Done!")
  
  await marketPlaceOrders.setContractAddress(contractAddresses.address)
  console.log("marketPlaceOrders.setContractAddress===========> Done!")
  
  await marketPlaceTrades.setContractAddress(contractAddresses.address)
  console.log("marketPlaceTrades.setContractAddress===========> Done!")
  
  await marketPlaceHelper.setContractAddress(contractAddresses.address)
  console.log("marketPlaceHelper.setContractAddress===========> Done!")
  
  await marketPlaceHelper2.setContractAddress(contractAddresses.address)
  console.log("marketPlaceHelper2.setContractAddress===========> Done!")
  
  await marketPlaceHelper3.setContractAddress(contractAddresses.address)
  console.log("marketPlaceHelper3.setContractAddress===========> Done!")

  await marketPlaceEvents.setContractAddress(contractAddresses.address)
  console.log("marketPlaceEvents.setContractAddress===========> Done!")
  
  // ####################### setDev
  await contractAddresses.setDevaddr(owner.address)
  console.log("contractAddresses.setDevaddr===========> Done!")  

  await contractAddresses.addContent('nsfw')
  
  await businessGaugeFactory.updateVoter([
    acceleratorVoter.address, 
    businessVoter.address, 
    contributorVoter.address, 
    referralVoter.address
  ], true)

  await contractAddresses.setAcceleratorVoter(acceleratorVoter.address)
  console.log("contractAddresses.setAcceleratorVoter===========> Done!")
  
  await contractAddresses.setContributorVoter(contributorVoter.address)
  console.log("contractAddresses.setContributorVoter===========> Done!")

  await contractAddresses.setBusinessGaugeFactory(businessGaugeFactory.address)
  console.log("contractAddresses.setBusinessGaugeFactory===========> Done!")

  await contractAddresses.setBusinessMinter(businessMinter.address)
  console.log("contractAddresses.setBusinessMinter===========> Done!")

  await contractAddresses.setBusinessBribeFactory(businessBribeFactory.address)
  console.log("contractAddresses.setBusinessBribeFactory===========> Done!")

  await contractAddresses.setReferralBribeFactory(referralBribeFactory.address)
  console.log("contractAddresses.setReferralBribeFactory===========> Done!")

  await contractAddresses.setBusinessVoter(businessVoter.address)
  console.log("contractAddresses.setBusinessVoter===========> Done!")
  
  await contractAddresses.setReferralVoter(referralVoter.address)
  console.log("contractAddresses.setReferralVoter===========> Done!")

  await contractAddresses.setAuditorHelper(auditorHelper.address)
  console.log("contractAddresses.setAuditorHelper===========> Done!")

  await contractAddresses.setAuditorNote(auditorNote.address)
  console.log("contractAddresses.setAuditorNote===========> Done!")

  await contractAddresses.setTrustBounty(trustBounties.address)
  console.log("contractAddresses.setTrustBounty===========> Done!")

  await contractAddresses.setTrustBountyHelper(trustBountiesHelper.address)
  console.log("contractAddresses.setTrustBountyHelper===========> Done!")

  await trustBountiesHelper.updateVes(ve.address, true)
  await trustBountiesHelper.updateWhitelistedTokens([ust.address], true)
  await trustBountiesHelper.updateCanAttach(marketPlaceEvents.address, true)

  await contractAddresses.setSponsorFactory(sponsorFactory.address)
  console.log("contractAddresses.setSponsorFactory===========> Done!")

  await contractAddresses.setSponsorNote(sponsorNote.address)
  console.log("contractAddresses.setSponsorNote===========> Done!")

  await contractAddresses.setValuepoolFactory(vavaFactory.address)
  console.log("contractAddresses.setValuepoolFactory===========> Done!")

  await contractAddresses.setValuepoolFactory(vavaFactory.address)
  console.log("contractAddresses.setValuepoolFactory===========> Done!")

  await contractAddresses.setValuepoolHelper(vavaHelper.address)
  console.log("contractAddresses.setValuepoolHelper===========> Done!")

  await contractAddresses.setValuepoolHelper2(vavaHelper2.address)
  console.log("contractAddresses.setValuepoolHelper2===========> Done!")

  await contractAddresses.setVeFactory(veFactory.address)
  console.log("contractAddresses.setVeFactory===========> Done!")

  await contractAddresses.setValuepoolVoter(valuepoolVoter.address)
  console.log("contractAddresses.setValuepoolVoter===========> Done!")

  await contractAddresses.setSSI(ssi.address)
  console.log("contractAddresses.setSSI===========> Done!")

  await contractAddresses.setStakeMarket(stakeMarket.address)
  console.log("contractAddresses.setStakeMarket===========> Done!")

  await contractAddresses.setStakeMarketNote(stakeMarketNote.address)
  console.log("contractAddresses.setStakeMarketNote===========> Done!")

  await contractAddresses.setStakeMarketBribe(stakeMarketBribe.address)
  console.log("contractAddresses.setStakeMarketBribe===========> Done!")

  await contractAddresses.setStakeMarketVoter(stakeMarketVoter.address)
  console.log("contractAddresses.setStakeMarketVoter===========> Done!")

  await contractAddresses.setProfile(profile.address)
  console.log("contractAddresses.setProfile===========> Done!")

  await contractAddresses.setProfileHelper(profileHelper.address)
  console.log("contractAddresses.setProfileHelper===========> Done!")

  await contractAddresses.setNfticket(nfticket.address)
  console.log("contractAddresses.setNfticket===========> Done!")
  
  await contractAddresses.setNfticketHelper(nfticketHelper.address)
  console.log("contractAddresses.setNfticketHelper===========> Done!")
  
  await contractAddresses.setNfticketHelper2(nfticketHelper2.address)
  console.log("contractAddresses.setNfticketHelper2===========> Done!")
  
  await contractAddresses.setToken(ust.address)
  console.log("contractAddresses.setToken===========> Done!")
  
  await contractAddresses.setMarketHelpers3(marketPlaceHelper3.address)
  console.log("contractAddresses.setMarketHelpers3===========> Done!")
  
  await contractAddresses.setMarketHelpers2(marketPlaceHelper2.address)
  console.log("contractAddresses.setMarketHelpers2===========> Done!")
  
  await contractAddresses.setMarketHelpers(marketPlaceHelper.address)
  console.log("contractAddresses.setMarketHelpers===========> Done!")
  
  await contractAddresses.setMarketTrades(marketPlaceTrades.address)
  console.log("contractAddresses.setMarketTrades===========> Done!")

  await contractAddresses.setMarketCollections(marketPlaceCollection.address)
  console.log("contractAddresses.setMarketCollections===========> Done!")

  await contractAddresses.setMarketPlaceEvents(marketPlaceEvents.address)
  console.log("contractAddresses.setMarketPlaceEvents===========> Done!")

  await contractAddresses.setMarketOrders(marketPlaceOrders.address)
  console.log("contractAddresses.setMarketOrders===========> Done!")

  await contractAddresses.setPaywallMarketOrders(paywallMarketPlaceOrders.address)
  console.log("contractAddresses.setPaywallMarketOrders===========> Done!")

  await contractAddresses.setNFTMarketOrders(nftMarketPlaceOrders.address)
  console.log("contractAddresses.setNFTMarketOrders===========> Done!")

  await contractAddresses.setNftSvg(nftSvg.address)
  console.log("contractAddresses.setNftSvg===========> Done!")
    
  await marketPlaceHelper3.addDtoken(ust.address)
  await marketPlaceHelper3.addVetoken(ve.address)
  await businessMinter.updateVes([ve.address], [ve_dist.address], true)
  await businessMinter.initialize()
  await ve_dist.setDepositor(businessMinter.address)

}).timeout(10000000);

  it("create lock", async function () {
      let ve_underlying_amount = ethers.BigNumber.from("1000000000000000000000");
      await ve_underlying.approve(ve.address, ve_underlying_amount);
      await ve_underlying.connect(owner2).approve(ve.address, ve_underlying_amount);
      const lockDuration = 7 * 24 * 3600; // 1 week
  
      // Balance should be zero before and 1 after creating the lock
      expect(await ve.balanceOf(owner.address)).to.equal(0);
      await ve.create_lock(ve_underlying_amount, lockDuration);
      await ve.connect(owner2).create_lock(ve_underlying_amount, lockDuration);
      expect(await ve.ownerOf(1)).to.equal(owner.address);
      expect(await ve.ownerOf(2)).to.equal(owner2.address);
      expect(await ve.balanceOf(owner.address)).to.equal(1);
      expect(await ve.balanceOf(owner2.address)).to.equal(1);
    });
  
  it("Deposit tokens", async function () {
    expect(await poolGauge.totalSupply(ust.address)).to.equal(0);
    expect(await poolGauge.derivedSupply(ust.address)).to.equal(0);
  
    await ust.approve(poolGauge.address, 100000000)
    await poolGauge.deposit(ust.address, ve.address, 1, 100000000)

    await ust.connect(owner2).approve(poolGauge.address, 50000000)
    await poolGauge.connect(owner2).deposit(ust.address, ve.address, 2, 50000000)

    expect(await poolGauge.totalSupply(ust.address)).to.equal(150000000);
    expect(await poolGauge.derivedSupply(ust.address)).to.equal(120000000);

    mint_amount = 100000000
    await ust.approve(poolGauge.address, mint_amount)
    await poolGauge.notifyRewardAmount(ust.address, mint_amount)
    
    console.log("rewardRate===============>", await poolGauge.rewardRate(ust.address))
    expect(await poolGauge.rewardRate(ust.address)).to.equal(165);
    expect(await poolGauge.rewardPerTokenStored(ust.address)).to.equal(0);

    // increase time
    await network.provider.send("evm_increaseTime", [86700])
    await network.provider.send("evm_mine")

    earned1 = await poolGauge.earned(ust.address, ve.address, 1)
    earned2 = await poolGauge.earned(ust.address, ve.address, 2)
    left = await poolGauge.left(ust.address)
    console.log("periodFinish===============>", await poolGauge.periodFinish(ust.address))
    console.log("earned1===============>", earned1)
    console.log("earned2===============>", earned2)
    console.log("total===============>", earned1.add(earned2))
    console.log("left===============>", left)
    console.log("calcualted left===============>", mint_amount - earned1.add(earned2))
    
  });

});

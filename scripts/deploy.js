async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const ContentTypes = await ethers.getContractFactory("ContentTypes");
  const NFTicketHelper = await ethers.getContractFactory("NFTicketHelper");
  const NFTicket = await ethers.getContractFactory("NFTicket");
  const SSI = await ethers.getContractFactory("SSI");
  const BusinessMinter = await ethers.getContractFactory("BusinessMinter");
  const StakeMarketBribe = await ethers.getContractFactory("Bribe");
  const TrustBounties = await ethers.getContractFactory("TrustBounties");
  const AuditorHelper = await ethers.getContractFactory("AuditorHelper");
  const AuditorFactory = await ethers.getContractFactory("AuditorFactory");
  const MarketPlaceEvents = await ethers.getContractFactory("MarketPlaceEvents");
  const MarketPlaceCollection = await ethers.getContractFactory("MarketPlaceCollection");
  const MarketPlaceOrders = await ethers.getContractFactory("MarketPlaceOrders");
  const MarketPlaceHelper = await ethers.getContractFactory("MarketPlaceHelper");
  const BusinessBribeFactory = await ethers.getContractFactory("BusinessBribeFactory");
  const ReferralBribeFactory = await ethers.getContractFactory("ReferralBribeFactory");
  const BusinessGaugeFactory = await ethers.getContractFactory("BusinessGaugeFactory");
  const BusinessVoter = await ethers.getContractFactory("BusinessVoter");
  const ReferralVoter = await ethers.getContractFactory("ReferralVoter");
  const MarketPlaceTrades = await ethers.getContractFactory("MarketPlaceTrades");
  const StakeMarketNote = await ethers.getContractFactory("StakeMarketNote");
  const StakeMarket = await ethers.getContractFactory("StakeMarket");
  const VavaHelper = await ethers.getContractFactory("VavaHelper");
  const ValuepoolVoter =  await ethers.getContractFactory("ValuepoolVoter")
  const SponsorFactory =  await ethers.getContractFactory("SponsorFactory")
  const vecontract = await ethers.getContractFactory("contracts/ve.sol:ve");
  const Percentile = await ethers.getContractFactory("contracts/Library.sol:Percentile")
  const percentile = await Percentile.deploy()
  const SponsorNote = await ethers.getContractFactory("SponsorNote",{
    libraries: {
      Percentile: percentile.address,
    },
  });
  const MarketPlaceHelper2 = await ethers.getContractFactory("MarketPlaceHelper2",{
    libraries: {
      Percentile: percentile.address,
    },
  });
  const Profile = await ethers.getContractFactory("Profile",{
    libraries: {
      Percentile: percentile.address,
    },
  });
  const AuditorNote = await ethers.getContractFactory("AuditorNote",{
    libraries: {
      Percentile: percentile.address,
    },
  });
  const StakeMarketVoter = await ethers.getContractFactory("StakeMarketVoter", {
    libraries: {
      Percentile: percentile.address,
    },
  })
  const VaFactory =  await ethers.getContractFactory("vaFactory", {
    libraries: {
      Percentile: percentile.address,
    },
  })
  const VavaFactory =  await ethers.getContractFactory("VavaFactory", {
    libraries: {
      Percentile: percentile.address,
    },
  })

  // const contentTypes = await ContentTypes.deploy()
  // const nfticketHelper = await NFTicketHelper.deploy(
  //   "0x53B34d4d703C42C167fAD1013C9a74C17a91AcAf",
  //   contentTypes.address
  // );
  // const nfticket = await NFTicket.deploy(
  //   "0x53B34d4d703C42C167fAD1013C9a74C17a91AcAf",
  //   nfticketHelper.address
  // );
  // const ssi = await SSI.deploy();
  // const businessMinter = await BusinessMinter.deploy(
  //   nfticket.address,
  //   "0x0000000000000000000000000000000000000000"
  // );
  // const stakeMarketBribe = await StakeMarketBribe.deploy()
  // const stakeMarketVoter = await StakeMarketVoter.deploy(
  //   stakeMarketBribe.address,
  //   ssi.address
  // )
  // const trustBounties = await TrustBounties.deploy(
  //   stakeMarketVoter.address,
  //   businessMinter.address
  // );
  // const profile = await Profile.deploy(
  //   "0x0bDabC785a5e1C71078d6242FB52e70181C1F316",
  //   trustBounties.address,
  //   ssi.address
  // );
  // auditorNote = await AuditorNote.deploy(
  //   businessMinter.address,
  //   profile.address,
  //   trustBounties.address, 
  //   ssi.address
  // );
  marketPlaceEvents = await MarketPlaceEvents.deploy();
  marketPlaceCollection = await MarketPlaceCollection.deploy(
    "0xe52E5E61C39b71c0667D3C006D8a0b308A896b9c",//nfticket.address, 
    "0x0bDabC785a5e1C71078d6242FB52e70181C1F316",
    "0x0612627fE6948cA6186B6b0Bb4257b6B5ccb4dAD",//auditorNote.address,
    marketPlaceEvents.address, 
    "0xc779EA80F7Ff02650C87D5C8ad656344779Dd766",//ssi.address 
  );
  // events 0xc4C93E219AE011EBaBb869f618756eFCb7834DE7
  // collections: 0xdDb95C5e6f214349DE1d3801BedD29c3a29Fe4d7
  // orders: 0xcEaF702e7333bBc9c9642D201226961ff74Fd59A
  // helpers:0x0b5D4cbBf043cbc683b7196EE26CE22832b5B306
  // helpers2:0x3248350F0E3C6f2BAad91e92087deaA2c8D3ACA3
  // trades: 0xCaA8B60400e38e1e8d1986701A216ea63a48289b
  // contentypes: 0x2B3DBfa8DD196CcF43359819B9563D6302c4400D
  // nftickethelper: 0xDD8C2e4990c54f5bcCAa18c8c18f0E85F84D078a
  // auditorHelper = await AuditorHelper.deploy(
  //   "0x53B34d4d703C42C167fAD1013C9a74C17a91AcAf",
  //   auditorNote.address,
  //   contentTypes.address,
  //   marketPlaceCollection.address
  // );
  marketPlaceOrders = await MarketPlaceOrders.deploy(
    marketPlaceCollection.address, 
    marketPlaceEvents.address, 
    "0xfc8FA78e10AEcE6EB24339303fbEE4bFbAc07017",//trustBounties.address, 
    "0x0151d6ED787d0d5080EFb1990067a266D16b0F39"//auditorHelper.address
  );
  marketPlaceHelper = await MarketPlaceHelper.deploy(
    marketPlaceCollection.address, 
    marketPlaceEvents.address, 
    marketPlaceOrders.address,
    "0xC10fBb98120f77B85e36B5Cd5d89A611fDc60418"//profile.address 
  );
  // auditorFactory = await AuditorFactory.deploy(
  //   auditorNote.address,
  //   auditorHelper.address,
  //   ssi.address 
  // )
  // businessBribeFactory = await BusinessBribeFactory.deploy(profile.address);
  // referralBribeFactory = await ReferralBribeFactory.deploy();
  // businessGaugeFactory = await BusinessGaugeFactory.deploy(
  //   trustBounties.address,
  //   marketPlaceCollection.address
  // );
  // businessVoter = await BusinessVoter.deploy(
  //   businessGaugeFactory.address, 
  //   businessBribeFactory.address,
  //   businessMinter.address,
  //   profile.address,
  //   marketPlaceCollection.address,
  //   marketPlaceHelper.address
  // );
  // referralVoter = await ReferralVoter.deploy(
  //   businessGaugeFactory.address, 
  //   referralBribeFactory.address,
  //   businessMinter.address,
  //   profile.address,
  //   marketPlaceCollection.address,
  //   marketPlaceHelper.address
  // );
  marketPlaceHelper2 = await MarketPlaceHelper2.deploy(
    "0xC10fBb98120f77B85e36B5Cd5d89A611fDc60418",//profile.address, 
    "0x0151d6ED787d0d5080EFb1990067a266D16b0F39",//auditorHelper.address,
    "0x0612627fE6948cA6186B6b0Bb4257b6B5ccb4dAD",//auditorNote.address,
    marketPlaceOrders.address, 
    marketPlaceHelper.address,
    marketPlaceCollection.address
  );
  marketPlaceTrades = await MarketPlaceTrades.deploy(
    marketPlaceCollection.address, 
    marketPlaceEvents.address, 
    marketPlaceOrders.address, 
    marketPlaceHelper.address,
    marketPlaceHelper2.address,
    "0xfc8FA78e10AEcE6EB24339303fbEE4bFbAc07017"//trustBounties.address
  );
  // stakeMarketNote = await StakeMarketNote.deploy(
  //   auditorNote.address,
  //   ssi.address
  // );
  // stakeMarket = await StakeMarket.deploy(
  //   businessMinter.address,
  //   marketPlaceTrades.address,
  //   stakeMarketNote.address
  // );
  // vavaHelper = await VavaHelper.deploy(
  //   "0x0000000000000000000000000000000000000000"
  // )
  // vaFactory = await VaFactory.deploy()
  // vavaFactory = await VavaFactory.deploy(
  //   vavaHelper.address,
  //   vaFactory.address,
  //   marketPlaceCollection.address, 
  //   ssi.address
  // )
  // valuepoolVoter = await ValuepoolVoter.deploy(
  //   "0x0000000000000000000000000000000000000000"
  // )
  // sponsorNote = await SponsorNote.deploy(
  //   businessMinter.address,
  //   profile.address,
  //   trustBounties.address,
  //   auditorHelper.address,
  //   ssi.address
  // );
  // sponsorFactory = await SponsorFactory.deploy(
  //   sponsorNote.address,
  //   contentTypes.address,
  //   ssi.address
  // );

  // console.log("contentTypes==============>", contentTypes.address)
  // console.log("nfticketHelper==============>", nfticketHelper.address)
  // console.log("nfticket==============>", nfticket.address)
  // console.log("ssi==============>", ssi.address)
  // console.log("businessMinter==============>", businessMinter.address)
  // console.log("stakeMarketBribe==============>", stakeMarketBribe.address)
  // console.log("stakeMarketVoter==============>", stakeMarketVoter.address)
  // console.log("trustBounties==============>", trustBounties.address)
  // console.log("profile==============>", profile.address)
  // console.log("auditorNote==============>", auditorNote.address)
  console.log("marketPlaceEvents==============>", marketPlaceEvents.address)
  console.log("marketPlaceCollection==============>", marketPlaceCollection.address)
  // console.log("auditorHelper==============>", auditorHelper.address)
  console.log("marketPlaceOrders==============>", marketPlaceOrders.address)
  // console.log("auditorFactory==============>", auditorFactory.address)
  // console.log("businessBribeFactory==============>", businessBribeFactory.address)
  // console.log("referralBribeFactory==============>", referralBribeFactory.address)
  // console.log("businessGaugeFactory==============>", businessGaugeFactory.address)
  // console.log("businessVoter==============>", businessVoter.address)
  // console.log("referralVoter==============>", referralVoter.address)
  console.log("marketPlaceHelper==============>", marketPlaceHelper.address)
  console.log("marketPlaceHelper2==============>", marketPlaceHelper2.address)
  console.log("marketPlaceTrades==============>", marketPlaceTrades.address)
  // console.log("stakeMarketNote==============>", stakeMarketNote.address)
  // console.log("stakeMarket==============>", stakeMarket.address)
  // console.log("vavaHelper==============>", vavaHelper.address)
  // console.log("vaFactory==============>", vaFactory.address)
  // console.log("vavaFactory==============>", vavaFactory.address)
  // console.log("valuepoolVoter==============>", valuepoolVoter.address)
  // console.log("sponsorNote==============>", sponsorNote.address)
  // console.log("sponsorFactory==============>", sponsorFactory.address)
  // const ve = await vecontract.deploy(ve_underlying.address);
  // const ve_dist = await Ve_dist.deploy(ve.address);

  // await profile.setBadgeNFT(auditorHelper.address);
  await marketPlaceCollection.setBadgeNFT(
    "0x0151d6ED787d0d5080EFb1990067a266D16b0F39",//auditorHelper.address
  );

  // await contentTypes.addContent("nsfw")
    // await businessMinter.updateVes(
    //   [ve.address],
    //   [ve_dist.address],
    //   true
    // );
    // await businessMinter.updateContracts(
    //   ve.address,
    //   businessVoter.address,
    //   "0x0000000000000000000000000000000000000000",
    //   "0x0000000000000000000000000000000000000000",
    //   referralVoter.address
    // );
    // await ve_dist.setDepositor(businessMinter.address)
    await marketPlaceHelper.updateVoterNGaugeFactory(
      "0x54703548B8Fd536287Ed7540ee553C99a626F5FE",//businessVoter.address,
      "0xAb47E7fC6b6eE648Ab3D421f8a2D861906caB242",//referralVoter.address,
      86400
    )
    // await businessGaugeFactory.updateVoter([businessVoter.address, referralVoter.address], true)
    // await businessMinter.initialize(ethers.BigNumber.from("1000000000000000000000000000"))
    // await ssi.setProfile(profile.address);
    // await stakeMarketBribe.setVoter(stakeMarketVoter.address);
    // await stakeMarket.setVoter(stakeMarketVoter.address);
    // await stakeMarketVoter.setMarket(trustBounties.address, true);
    // await stakeMarketVoter.setMarket(stakeMarket.address, true);
    // await stakeMarketNote.setStakeMarket(stakeMarket.address);
    // await trustBounties.updateVes(ve.address, true);
    // await trustBounties.updateWhitelistedTokens([ust.address], true);
    // await ve.setVoter(stakeMarketVoter.address);
    // await ve.setVoter(businessVoter.address);
    // await ve.setVoter(referralVoter.address);
    // await vavaHelper.setFactory(
    //   nfticket.address,
    //   valuepoolVoter.address,
    //   vavaFactory.address,
    //   marketPlaceTrades.address
    // );
    // await vaFactory.setContracts(
    //   trustBounties.address,
    //   valuepoolVoter.address,
    //   owner.address,
    //   vavaHelper.address
    // );
    
    await marketPlaceOrders.setMarkets(
      marketPlaceTrades.address, 
      marketPlaceHelper.address,
      marketPlaceHelper2.address
    );
    await marketPlaceHelper.setMarketTrades(marketPlaceTrades.address);
    await marketPlaceHelper2.setMarketTrades(marketPlaceTrades.address);
    // await nfticket.setMarkets(
    //   marketPlaceCollection.address, 
    //   marketPlaceOrders.address, 
    //   marketPlaceTrades.address,
    //   marketPlaceHelper.address
    // );
    // await nfticketHelper.setMarkets(
    //   marketPlaceEvents.address, 
    //   marketPlaceCollection.address
    // );
    await marketPlaceCollection.setMarketOrders(marketPlaceOrders.address)
    await marketPlaceEvents.setContracts(
      "0x636E5E298340c3C415605CA53A6346edBD5546F9",//nfticketHelper.address,
      marketPlaceCollection.address,
      marketPlaceOrders.address,
      marketPlaceTrades.address,
      marketPlaceHelper.address,
      marketPlaceHelper2.address,
      marketPlaceHelper.address,
    "0xfc8FA78e10AEcE6EB24339303fbEE4bFbAc07017",//trustBounties.address,
      marketPlaceHelper.address,
      marketPlaceHelper.address,
    );
    await marketPlaceHelper.addDtoken(
      "0x53B34d4d703C42C167fAD1013C9a74C17a91AcAf"//ust.address
    )
    await marketPlaceHelper.addVetoken(
      "0xAE33660c8b3772f968bEA82c21dA3D8Fd93D6481"//ve.address
    )
    // await nfticketHelper.setMarkets(
    //   marketPlaceEvents.address, 
    //   marketPlaceCollection.address
    // )
  // await ve.setVoter(voter.address);
  // await ve_dist.setDepositor(minter.address);
  // await voter.initialize(["0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83","0x04068da6c83afcfa0e13ba15a6696662335d5b75","0x321162Cd933E2Be498Cd2267a90534A804051b11","0x8d11ec38a3eb5e956b052f67da8bdc9bef8abf3e","0x82f0b8b456c1a451378467398982d4834b6829c1","0xdc301622e621166bd8e82f2ca0a26c13ad0be355","0x1E4F97b9f9F913c46F1632781732927B9019C68b", "0x29b0Da86e484E1C0029B56e817912d778aC0EC69", "0xae75A438b2E0cB8Bb01Ec1E1e376De11D44477CC", "0x7d016eec9c25232b01f23ef992d98ca97fc2af5a", "0x468003b688943977e6130f4f68f23aad939a1040","0xe55e19fb4f2d85af758950957714292dac1e25b2","0x4cdf39285d7ca8eb3f090fda0c069ba5f4145b37","0x6c021ae822bea943b2e66552bde1d2696a53fbb7","0x2a5062d22adcfaafbd5c541d4da82e4b450d4212","0x841fad6eae12c286d1fd18d1d525dffa75c7effe","0x5C4FDfc5233f935f20D2aDbA572F770c2E377Ab0","0xad996a45fd2373ed0b10efa4a8ecb9de445a4302", "0xd8321aa83fb0a4ecd6348d4577431310a6e0814d", "0x5cc61a78f164885776aa610fb0fe1257df78e59b", "0x10b620b2dbac4faa7d7ffd71da486f5d44cd86f9","0xe0654C8e6fd4D733349ac7E09f6f23DA256bF475","0x85dec8c4b2680793661bca91a8f129607571863d","0x74b23882a30290451A17c44f4F05243b6b58C76d","0xf16e81dce15b08f326220742020379b855b87df9", "0x9879abdea01a879644185341f7af7d8343556b7a","0x00a35FD824c717879BF370E70AC6868b95870Dfb","0xc5e2b037d30a390e62180970b3aa4e91868764cd", "0x10010078a54396F62c96dF8532dc2B4847d47ED3"], minter.address);
  // await minter.initialize(["0x5bDacBaE440A2F30af96147DE964CC97FE283305","0xa96D2F0978E317e7a97aDFf7b5A76F4600916021","0x95478C4F7D22D1048F46100001c2C69D2BA57380","0xC0E2830724C946a6748dDFE09753613cd38f6767","0x3293cB515Dbc8E0A8Ab83f1E5F5f3CC2F6bbc7ba","0xffFfBBB50c131E664Ef375421094995C59808c97","0x02517411F32ac2481753aD3045cA19D58e448A01","0xf332789fae0d1d6f058bfb040b3c060d76d06574","0xdFf234670038dEfB2115Cf103F86dA5fB7CfD2D2","0x0f2A144d711E7390d72BD474653170B201D504C8","0x224002428cF0BA45590e0022DF4b06653058F22F","0x26D70e4871EF565ef8C428e8782F1890B9255367","0xA5fC0BbfcD05827ed582869b7254b6f141BA84Eb","0x4D5362dd18Ea4Ba880c829B0152B7Ba371741E59","0x1e26D95599797f1cD24577ea91D99a9c97cf9C09","0xb4ad8B57Bd6963912c80FCbb6Baea99988543c1c","0xF9E7d4c6d36ca311566f46c81E572102A2DC9F52","0xE838c61635dd1D41952c68E47159329443283d90","0x111731A388743a75CF60CCA7b140C58e41D83635","0x0edfcc1b8d082cd46d13db694b849d7d8151c6d5","0xD0Bb8e4E4Dd5FDCD5D54f78263F5Ec8f33da4C95","0x9685c79e7572faF11220d0F3a1C1ffF8B74fDc65","0xa70b1d5956DAb595E47a1Be7dE8FaA504851D3c5","0x06917EFCE692CAD37A77a50B9BEEF6f4Cdd36422","0x5b0390bccCa1F040d8993eB6e4ce8DeD93721765"], [ethers.BigNumber.from("800000000000000000000000"),ethers.BigNumber.from("2376588000000000000000000"),ethers.BigNumber.from("1331994000000000000000000"),ethers.BigNumber.from("1118072000000000000000000"),ethers.BigNumber.from("1070472000000000000000000"),ethers.BigNumber.from("1023840000000000000000000"),ethers.BigNumber.from("864361000000000000000000"),ethers.BigNumber.from("812928000000000000000000"),ethers.BigNumber.from("795726000000000000000000"),ethers.BigNumber.from("763362000000000000000000"),ethers.BigNumber.from("727329000000000000000000"),ethers.BigNumber.from("688233000000000000000000"),ethers.BigNumber.from("681101000000000000000000"),ethers.BigNumber.from("677507000000000000000000"),ethers.BigNumber.from("676304000000000000000000"),ethers.BigNumber.from("642992000000000000000000"),ethers.BigNumber.from("609195000000000000000000"),ethers.BigNumber.from("598412000000000000000000"),ethers.BigNumber.from("591573000000000000000000"),ethers.BigNumber.from("587431000000000000000000"),ethers.BigNumber.from("542785000000000000000000"),ethers.BigNumber.from("536754000000000000000000"),ethers.BigNumber.from("518240000000000000000000"),ethers.BigNumber.from("511920000000000000000000"),ethers.BigNumber.from("452870000000000000000000")], ethers.BigNumber.from("100000000000000000000000000"));

  // await tFiat.updateWhitelist(trustBounties.address, true)

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });


// https://cryptotools.net/rsagen
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
  let ve_underlying;
  let ve;
  let owner;
  let gauge_factory;
  let gauge;
  let owner2;
  let owner3;
  let owner4;

  let ust_1;
  let ust_2;
  let ust_3;
  let ust_4;
  let rank_0;
  let rank_1;

  it("deploy factory", async function () {
    [owner, owner2, owner3, owner4] = await ethers.getSigners(4);
    token = await ethers.getContractFactory("Token");
    ust = await token.deploy('ust', 'ust', 6, owner.address);
    await ust.mint(owner.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.mint(owner2.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.mint(owner3.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.mint(owner4.address, ethers.BigNumber.from("1000000000000000000"));
    await ust.deployed();

    ve_underlying = await token.deploy('VE', 'VE', 18, owner.address);
    await ve_underlying.mint(owner.address, ethers.BigNumber.from("20000000000000000000000000"));
    await ve_underlying.mint(owner2.address, ethers.BigNumber.from("10000000000000000000000000"));
    await ve_underlying.mint(owner3.address, ethers.BigNumber.from("10000000000000000000000000"));
    await ve_underlying.mint(owner4.address, ethers.BigNumber.from("10000000000000000000000000"));
    
    vecontract = await ethers.getContractFactory("contracts/ve.sol:ve");
    ve = await vecontract.deploy(ve_underlying.address);

    const BaseV1GaugeFactory = await ethers.getContractFactory("BaseV1ValuePoolFactory");
    gauges_factory = await BaseV1GaugeFactory.deploy();
    await gauges_factory.deployed();

    const BaseV1Voter = await ethers.getContractFactory("WagmiAcceleratorVoter");
    gauge_factory = await BaseV1Voter.deploy(ve.address, gauges_factory.address, gauges_factory.address, gauges_factory.address);
    await gauge_factory.deployed();

    await ve.setVoter(gauge_factory.address);

    const SuperLikeGaugeFactory = await ethers.getContractFactory("SuperLikeGaugeFactory");
    superLikeGaugeFactory = await SuperLikeGaugeFactory.deploy();
    await superLikeGaugeFactory.deployed()

    expect(await gauge_factory.length()).to.equal(0);
  });
  
  it("deploy valuepool", async function () {
    await gauges_factory.createValuePool(
      "Valuepool",
      "vlp",
      ve_underlying.address, 
      owner.address,
      "0x0000000000000000000000000000000000000000",
      superLikeGaugeFactory.address,
      0,
      "0x0000000000000000000000000000000000000000"
    );

    const gauge_address = await gauges_factory.last_valuepool();
    
    BallerNFT = await ethers.getContractFactory("BallerNFT");
    ballerNFT = await BallerNFT.deploy(
      owner.address,
      1,
      ust.address,
      "",
      gauge_factory.address,
      "0x0000000000000000000000000000000000000000"
    );
    const BaseV1Market = await ethers.getContractFactory("MarketPlaceV1");
    nftMarket = await BaseV1Market.deploy(
      owner.address, 
      owner.address, 
      ve_underlying.address, 
      1,
      100
    );
    await nftMarket.deployed();
    expect(await nftMarket.nft_()).to.equal("0x0000000000000000000000000000000000000000");
    await nftMarket.createNFTicket("nfticket", true);
    nft_address = await nftMarket.nft_();
    expect(nft_address).to.not.equal("0x0000000000000000000000000000000000000000");

    const Gauge = await ethers.getContractFactory("ValuePool");
    gauge = await Gauge.attach(gauge_address);
    await gauge.initialize(
      ballerNFT.address, 
      nftMarket.address, 
      ust.address, 
      false, 
      true
    );

  });

  it("add invoice", async function () {
    await gauge.addInvoice(owner.address, 86700, "clothes, PC");

    expect((await gauge.invoiceInfo(owner.address)).cartItems).to.equal("clothes, PC");
    expect((await gauge.invoiceInfo(owner.address)).periodReceivable).to.equal(86700);

    await gauge.updateCartItems("PC, clothes");
  });

  it("deposit in invoice", async function () {
    expect(await ust.balanceOf(gauge.address)).to.equal(0);
    ust_1 = ethers.BigNumber.from("100");
    await ust.approve(gauge.address, ust_1);
    await gauge.deposit(ust_1);
    console.log(await ust.balanceOf(gauge.address));
    expect(await ust.balanceOf(gauge.address)).to.equal(ust_1);
    console.log(await gauge.invoiceInfo(owner.address));
    expect((await gauge.invoiceInfo(owner.address)).totalInvoices).to.equal(1);
    expect((await gauge.invoiceInfo(owner.address)).totalpaidInvoices).to.equal(100);
    expect((await gauge.invoiceInfo(owner.address)).user_sum_of_diff_squared).to.equal(0);
    expect((await gauge.invoiceInfo(owner.address)).sum_of_diff_squared_invoices).to.equal(0);
  });

  it("add invoice 2", async function () {
    await gauge.connect(owner2).addInvoice(owner2.address, 86700, "clothes, PC");

    expect((await gauge.invoiceInfo(owner2.address)).periodReceivable).to.equal(86700);
    expect((await gauge.invoiceInfo(owner2.address)).cartItems).to.equal("clothes, PC");

    await gauge.connect(owner2).updateCartItems("PC, clothes");
    expect((await gauge.invoiceInfo(owner2.address)).cartItems).to.equal("PC, clothes");
  });

  it("deposit in invoice 2", async function () {
    ust_2 = ethers.BigNumber.from("300");
    expect(await ust.balanceOf(gauge.address)).to.equal(ust_1);
    await ust.connect(owner2).approve(gauge.address, ust_2);
    await gauge.connect(owner2).deposit(ust_2);
    console.log(await ust.balanceOf(gauge.address));
    expect(await ust.balanceOf(gauge.address)).to.equal(ust_2.add(ust_1));
    console.log(await gauge.invoiceInfo(owner2.address));
    expect((await gauge.invoiceInfo(owner2.address)).totalInvoices).to.equal(2);
    expect((await gauge.invoiceInfo(owner2.address)).totalpaidInvoices).to.equal(400);
    expect((await gauge.invoiceInfo(owner2.address)).user_sum_of_diff_squared).to.equal(10000);
    expect((await gauge.invoiceInfo(owner2.address)).sum_of_diff_squared_invoices).to.equal(10000);
  });

  it("add invoice 3", async function () {
    await gauge.connect(owner3).addInvoice(owner3.address, 86700, "clothes, PC");

    expect((await gauge.invoiceInfo(owner3.address)).periodReceivable).to.equal(86700);
    expect((await gauge.invoiceInfo(owner3.address)).cartItems).to.equal("clothes, PC");

    await gauge.connect(owner3).updateCartItems("PC, clothes");
    expect((await gauge.invoiceInfo(owner3.address)).cartItems).to.equal("PC, clothes");
  });

  it("deposit in invoice 3", async function () {
    ust_3 = ethers.BigNumber.from("1300");
    expect(await ust.balanceOf(gauge.address)).to.equal(ust_2.add(ust_1));
    await ust.connect(owner3).approve(gauge.address, ust_3);
    await gauge.connect(owner3).deposit(ust_3);
    console.log(await ust.balanceOf(gauge.address));
    expect(await ust.balanceOf(gauge.address)).to.equal(ust_3.add(ust_2).add(ust_1));
    console.log(await gauge.invoiceInfo(owner3.address));
    expect((await gauge.invoiceInfo(owner3.address)).totalInvoices).to.equal(3);
    expect((await gauge.invoiceInfo(owner3.address)).totalpaidInvoices).to.equal(1700);
    expect((await gauge.invoiceInfo(owner3.address)).user_sum_of_diff_squared).to.equal(548756);
    expect((await gauge.invoiceInfo(owner3.address)).sum_of_diff_squared_invoices).to.equal(548756);
  });

  it("add invoice 4", async function () {
    await gauge.connect(owner4).addInvoice(owner4.address, 86700, "clothes, PC");

    expect((await gauge.invoiceInfo(owner4.address)).periodReceivable).to.equal(86700);
    expect((await gauge.invoiceInfo(owner4.address)).cartItems).to.equal("clothes, PC");

    await gauge.connect(owner4).updateCartItems("PC, clothes");
    expect((await gauge.invoiceInfo(owner4.address)).cartItems).to.equal("PC, clothes");
  });

  it("deposit in invoice 4", async function () {
    ust_4 = ethers.BigNumber.from("1");
    expect(await ust.balanceOf(gauge.address)).to.equal(ust_3.add(ust_2).add(ust_1));
    await ust.connect(owner4).approve(gauge.address, ust_4);
    await gauge.connect(owner4).deposit(ust_4);
    console.log(await ust.balanceOf(gauge.address));
    expect(await ust.balanceOf(gauge.address)).to.equal(ust_4.add(ust_3).add(ust_2).add(ust_1));
    console.log(await gauge.invoiceInfo(owner4.address));
    expect((await gauge.invoiceInfo(owner4.address)).totalInvoices).to.equal(0);
    expect((await gauge.invoiceInfo(owner4.address)).totalpaidInvoices).to.equal(0);
    expect((await gauge.invoiceInfo(owner4.address)).user_sum_of_diff_squared).to.equal(0);
    expect((await gauge.invoiceInfo(owner4.address)).sum_of_diff_squared_invoices).to.equal(0);
  });

  it("pick & claim Rank", async function () {
    expect((await gauge.invoiceInfo(owner.address)).rank).to.equal(0);
    await gauge.pickRank();
    await gauge.claimRank();
    console.log("owner user percentile", await gauge.getUserPercentile());
    rank_0 = (await gauge.invoiceInfo(owner.address)).rank;
    expect(rank_0).to.be.above(0);
    expect(rank_0).to.equal(rank_0);
    expect(await gauge.getPeopleBefore(rank_0)).to.equal(0);

    expect((await gauge.invoiceInfo(owner2.address)).rank).to.equal(0);
    await gauge.connect(owner2).pickRank();
    await gauge.connect(owner2).claimRank();
    console.log("owner2 user percentile", await gauge.connect(owner2).getUserPercentile());
    rank_1 = (await gauge.invoiceInfo(owner2.address)).rank;
    expect(rank_1).to.be.above(0);
    console.log("owner invoice rank", rank_0);
    console.log("owner2 invoice rank", rank_1);

    if (rank_0 > rank_1) {
      console.log("first");
      console.log("old rank", rank_0);
      console.log("new rank", await gauge.rank());
      expect(await gauge.rank()).to.equal(rank_1);
      expect(await gauge.rank()).to.below(rank_0);
      expect(await gauge.getPeopleBefore(rank_1)).to.equal(0);
      expect(await gauge.getPeopleBefore(rank_0)).to.equal(1);
    } else if (rank_0 < rank_1){
      console.log("second");
      console.log("old rank", rank_0);
      console.log("new rank", await gauge.rank());
      expect(await gauge.rank()).to.equal(rank_0);
      expect(await gauge.rank()).to.below(rank_1);
      expect(await gauge.getPeopleBefore(rank_1)).to.equal(1);
      expect(await gauge.getPeopleBefore(rank_0)).to.equal(0);
    } else {
      console.log("third");
      console.log("old rank", rank_0);
      console.log("new rank", await gauge.rank());
      expect(await gauge.rank()).to.equal(rank_0);
      expect(await gauge.rank()).to.equal(rank_1);
      expect(await gauge.getPeopleBefore(rank_0)).to.equal(0);
      expect(await gauge.getPeopleBefore(rank_1)).to.equal(0);
    }
  });

  it("claim Reward", async function () {
    let token_1 = ethers.BigNumber.from("1000");
    // create user gauges
    await superLikeGaugeFactory.createGaugeSingle(
      ve.address, 
      0,
      1, 
      gauge_factory.address
    );
    const owner_gauge_address = await superLikeGaugeFactory.last_gauge() 

    await superLikeGaugeFactory.connect(owner2).createGaugeSingle(
      ve.address, 
      0,
      1, 
      gauge_factory.address
    );
    const owner2_gauge_address = await superLikeGaugeFactory.last_gauge() 
    
    await ve_underlying.mint(gauge.address, ethers.BigNumber.from("20000000000000000000000000"));
    console.log("rank_0", rank_0);
    console.log("rank_1", rank_1);
    console.log("rank", (await gauge.rank()));
    
    if (rank_1 > (await gauge.rank())) { 
        console.log("first");
        await expect(
          gauge.connect(owner2).claimReward(
          token_1,
          "footMercato",
          owner.address,
          owner_gauge_address
        )).to.be.reverted;

        await gauge.claimReward(
          token_1,
         "footMercato",
          owner2.address,
          owner2_gauge_address
        );

        expect(await gauge.rank()).to.equal(rank_1);
    } 
    else if (rank_0 > (await gauge.rank())) {
      console.log("second");
      await expect(
        gauge.claimReward(
        token_1,
        "footMercato",
        owner2.address,
        owner2_gauge_address
      )).to.be.reverted;

        
      await gauge.connect(owner2).claimReward(
        token_1,
        "footMercato",
        owner.address,
        owner_gauge_address
      );
      expect(await gauge.rank()).to.equal(rank_0);
    } else {
      console.log("third");
      await gauge.claimReward(
        token_1 / 2,
        "footMercato",
        owner2.address,
        owner2_gauge_address
      );
      await gauge.connect(owner2).claimReward(
        token_1 / 2,
        "footMercato",
        owner.address,
        owner_gauge_address
      );
    }
    // console.log("ve_underlying balance", await ve_underlying.balanceOf(gauge.address));
    // expect(await ve_underlying.balanceOf(gauge.address))
    // .to.equal(ethers.BigNumber.from("19999999999999999999999000"));

  })

  it("withdraw & removefootprint", async function () {
    console.log("totalInvoices", await gauge.totalInvoices());
    console.log("totalpaidInvoices", await gauge.totalpaidInvoices());
    console.log("sum_of_diff_squared_invoices", await gauge.sum_of_diff_squared_invoices());
    console.log("user paidReceivable", await gauge.invoiceInfo(owner2.address));
    console.log("user percentile before", await gauge.connect(owner2).getUserPercentile());
    const percentile_before = await gauge.getUserPercentile();
    await gauge.connect(owner2).withdraw((await gauge.invoiceInfo(owner2.address)).paidReceivable);
    console.log("totalInvoices", await gauge.totalInvoices());
    console.log("totalpaidInvoices", await gauge.totalpaidInvoices());
    console.log("sum_of_diff_squared_invoices", await gauge.sum_of_diff_squared_invoices());
    console.log("user paidReceivable", await gauge.invoiceInfo(owner2.address));
    console.log("user percentile after", await gauge.getUserPercentile());
    expect(await gauge.getUserPercentile()).to.be.above(percentile_before);
    expect(await gauge.connect(owner2).getUserPercentile()).to.equal(1);
    expect((await gauge.invoiceInfo(owner2.address)).paidReceivable).to.equal(0);

    console.log("user percentile before", await gauge.connect(owner3).getUserPercentile());
    const percentile_before2 = await gauge.connect(owner3).getUserPercentile();
    const paid_before2 = (await gauge.invoiceInfo(owner3.address)).paidReceivable;
    await gauge.connect(owner3).withdraw(1);
    console.log("user percentile after", await gauge.connect(owner3).getUserPercentile());
    expect(await gauge.connect(owner3).getUserPercentile()).to.be.below(percentile_before2);
    expect((await gauge.invoiceInfo(owner3.address)).paidReceivable.add(1)).to.equal(paid_before2);
  });

  
});

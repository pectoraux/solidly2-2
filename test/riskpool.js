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

    expect(await gauge_factory.length()).to.equal(0);
  });
  
  it("deploy valuepool", async function () {
    await gauges_factory.createValuePool(
      ve_underlying.address, 
      owner.address,
      gauge_factory.address,
      0
    );
    const gauge_address = await gauges_factory.last_valuepool();
    console.log(gauge_address);
    
    const Gauge = await ethers.getContractFactory("ValuePool");
    gauge = await Gauge.attach(gauge_address);
    await gauge.initialize(owner.address, ve_underlying.address, true, false);
  });

  it("add invoice", async function () {
    await gauge.addInvoice(owner.address, 86700, "clothes, PC");

    expect((await gauge.invoiceInfo(0)).owner).to.equal(owner.address);
    expect((await gauge.invoiceInfo(0)).periodReceivable).to.equal(86700);
    expect((await gauge.invoiceInfo(0)).cartItems).to.equal("clothes, PC");

    await gauge.updateCartItems(0, "PC, clothes");
    expect((await gauge.invoiceInfo(0)).cartItems).to.equal("PC, clothes");
  });

  it("deposit in invoice", async function () {
    expect(await ve_underlying.balanceOf(gauge.address)).to.equal(0);
    ve_underlying_1 = ethers.BigNumber.from("100");
    await ve_underlying.approve(gauge.address, ve_underlying_1);
    await gauge.deposit(0, ve_underlying_1);
    console.log(await ve_underlying.balanceOf(gauge.address));
    expect(await ve_underlying.balanceOf(gauge.address)).to.equal(ve_underlying_1);
    console.log(await gauge.invoiceInfo(0));
    expect((await gauge.invoiceInfo(0)).totalInvoices).to.equal(1);
    expect((await gauge.invoiceInfo(0)).totalpaidInvoices).to.equal(100);
    expect((await gauge.invoiceInfo(0)).user_sum_of_diff_squared).to.equal(0);
    expect((await gauge.invoiceInfo(0)).sum_of_diff_squared_invoices).to.equal(0);
  });

  it("add invoice 2", async function () {
    await gauge.connect(owner2).addInvoice(owner2.address, 86700, "clothes, PC");

    expect((await gauge.invoiceInfo(1)).owner).to.equal(owner2.address);
    expect((await gauge.invoiceInfo(1)).periodReceivable).to.equal(86700);
    expect((await gauge.invoiceInfo(1)).cartItems).to.equal("clothes, PC");

    await gauge.connect(owner2).updateCartItems(1, "PC, clothes");
    expect((await gauge.invoiceInfo(1)).cartItems).to.equal("PC, clothes");
  });

  it("deposit in invoice 2", async function () {
    ve_underlying_2 = ethers.BigNumber.from("300");
    expect(await ve_underlying.balanceOf(gauge.address)).to.equal(ve_underlying_1);
    await ve_underlying.connect(owner2).approve(gauge.address, ve_underlying_2);
    await gauge.connect(owner2).deposit(1, ve_underlying_2);
    console.log(await ve_underlying.balanceOf(gauge.address));
    expect(await ve_underlying.balanceOf(gauge.address)).to.equal(ve_underlying_2.add(ve_underlying_1));
    console.log(await gauge.invoiceInfo(1));
    expect((await gauge.invoiceInfo(1)).totalInvoices).to.equal(2);
    expect((await gauge.invoiceInfo(1)).totalpaidInvoices).to.equal(400);
    expect((await gauge.invoiceInfo(1)).user_sum_of_diff_squared).to.equal(10000);
    expect((await gauge.invoiceInfo(1)).sum_of_diff_squared_invoices).to.equal(10000);
  });

  it("add invoice 3", async function () {
    await gauge.connect(owner3).addInvoice(owner3.address, 86700, "clothes, PC");

    expect((await gauge.invoiceInfo(2)).owner).to.equal(owner3.address);
    expect((await gauge.invoiceInfo(2)).periodReceivable).to.equal(86700);
    expect((await gauge.invoiceInfo(2)).cartItems).to.equal("clothes, PC");

    await gauge.connect(owner3).updateCartItems(2, "PC, clothes");
    expect((await gauge.invoiceInfo(2)).cartItems).to.equal("PC, clothes");
  });

  it("deposit in invoice 3", async function () {
    ve_underlying_3 = ethers.BigNumber.from("1300");
    expect(await ve_underlying.balanceOf(gauge.address)).to.equal(ve_underlying_2.add(ve_underlying_1));
    await ve_underlying.connect(owner3).approve(gauge.address, ve_underlying_3);
    await gauge.connect(owner3).deposit(2, ve_underlying_3);
    console.log(await ve_underlying.balanceOf(gauge.address));
    expect(await ve_underlying.balanceOf(gauge.address)).to.equal(ve_underlying_3.add(ve_underlying_2).add(ve_underlying_1));
    console.log(await gauge.invoiceInfo(2));
    expect((await gauge.invoiceInfo(2)).totalInvoices).to.equal(3);
    expect((await gauge.invoiceInfo(2)).totalpaidInvoices).to.equal(1700);
    expect((await gauge.invoiceInfo(2)).user_sum_of_diff_squared).to.equal(548756);
    expect((await gauge.invoiceInfo(2)).sum_of_diff_squared_invoices).to.equal(548756);
  });

  it("add invoice 4", async function () {
    await gauge.connect(owner4).addInvoice(owner4.address, 86700, "clothes, PC");

    expect((await gauge.invoiceInfo(3)).owner).to.equal(owner4.address);
    expect((await gauge.invoiceInfo(3)).periodReceivable).to.equal(86700);
    expect((await gauge.invoiceInfo(3)).cartItems).to.equal("clothes, PC");

    await gauge.connect(owner4).updateCartItems(3, "PC, clothes");
    expect((await gauge.invoiceInfo(3)).cartItems).to.equal("PC, clothes");
  });

  it("deposit in invoice 4", async function () {
    ve_underlying_4 = ethers.BigNumber.from("1");
    expect(await ve_underlying.balanceOf(gauge.address)).to.equal(ve_underlying_3.add(ve_underlying_2).add(ve_underlying_1));
    await ve_underlying.connect(owner4).approve(gauge.address, ve_underlying_4);
    await gauge.connect(owner4).deposit(3, ve_underlying_4);
    console.log(await ve_underlying.balanceOf(gauge.address));
    expect(await ve_underlying.balanceOf(gauge.address)).to.equal(ve_underlying_4.add(ve_underlying_3).add(ve_underlying_2).add(ve_underlying_1));
    console.log(await gauge.invoiceInfo(3));
    expect((await gauge.invoiceInfo(3)).totalInvoices).to.equal(0);
    expect((await gauge.invoiceInfo(3)).totalpaidInvoices).to.equal(0);
    expect((await gauge.invoiceInfo(3)).user_sum_of_diff_squared).to.equal(0);
    expect((await gauge.invoiceInfo(3)).sum_of_diff_squared_invoices).to.equal(0);
  });

  it("pick & claim Rank", async function () {
    expect((await gauge.invoiceInfo(0)).rank).to.equal(0);
    await gauge.pickRank(0, owner.address);
    await gauge.claimRank(0, owner.address);
    console.log("invoice 0 user percentile", await gauge.getUserPercentile(1));
    rank_0 = (await gauge.invoiceInfo(0)).rank;
    expect(rank_0).to.be.above(0);
    expect(rank_0).to.equal(rank_0);
    expect(await gauge.getPeopleBefore(rank_0)).to.equal(0);

    expect((await gauge.invoiceInfo(1)).rank).to.equal(0);
    await gauge.pickRank(1, owner2.address);
    await gauge.claimRank(1, owner2.address);
    console.log("invoice 1 user percentile", await gauge.getUserPercentile(1));
    rank_1 = (await gauge.invoiceInfo(1)).rank;
    expect(rank_1).to.be.above(0);
    console.log("invoice 0 rank", rank_0);
    console.log("invoice 1 rank", rank_1);

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

  it("claim Reward without adding merchants", async function () {
    let token_1 = ethers.BigNumber.from("1000");
    console.log("rank_0", rank_0);
    console.log("rank_1", rank_1);
    console.log("rank", (await gauge.rank()));
    if (rank_1 > (await gauge.rank())) { 
        console.log("first");
        await expect(
          gauge.claimReward(
          1,
          token_1,
          owner2.address,
          owner.address
        )).to.be.reverted;

        await expect(
          gauge.claimReward(
          0,
          token_1,
          owner.address,
          owner2.address
        )).to.be.reverted;

        expect(await gauge.rank()).to.equal(rank_0);
    } else if (rank_0 > (await gauge.rank())) {
      console.log("second");
      await expect(
        gauge.claimReward(
        0,
        token_1,
        owner.address,
        owner2.address
      )).to.be.reverted;

      await expect(
        gauge.claimReward(
        1,
        token_1,
        owner2.address,
        owner.address
      )).to.be.reverted;

      expect(await gauge.rank()).to.equal(rank_1);
    } else {
      console.log("third");
      await expect(
        gauge.claimReward(
        0,
        token_1 / 2,
        owner.address,
        owner2.address
      )).to.be.reverted;
      
      await expect(
        gauge.claimReward(
        1,
        token_1 / 2,
        owner2.address,
        owner.address
      )).to.be.reverted;
    }
    console.log("ve_underlying balance", await ve_underlying.balanceOf(gauge.address));
    expect(await ve_underlying.balanceOf(gauge.address))
    .to.equal(ethers.BigNumber.from("1701"));

  })

  it("add merchant", async function () {
    await gauge.updateMerchant(0, true, owner2.address);
    await gauge.updateMerchant(1, true, owner.address);
  });

  it("claim Reward", async function () {
    let token_1 = ethers.BigNumber.from("1000");
    console.log("ve_underlying balance before", await ve_underlying.balanceOf(gauge.address));
    console.log("rank_0", rank_0);
    console.log("rank_1", rank_1);
    console.log("rank", (await gauge.rank()));
    if (rank_1 > (await gauge.rank())) { 
        console.log("first");
        await expect(
          gauge.claimReward(
          1,
          token_1,
          owner2.address,
          owner.address
        )).to.be.reverted;

        await gauge.claimReward(
          0,
          token_1,
          owner.address,
          owner2.address
        );

        expect(await gauge.rank()).to.equal(rank_1);
    } else if (rank_0 > (await gauge.rank())) {
      console.log("second");
      await expect(
        gauge.claimReward(
        0,
        token_1,
        owner.address,
        owner2.address
      )).to.be.reverted;
        
      await gauge.claimReward(
        1,
        token_1,
        owner2.address,
        owner.address
      );
      expect(await gauge.rank()).to.equal(rank_0);
    } else {
      console.log("third");
      await gauge.claimReward(
        0,
        token_1 / 2,
        owner.address,
        owner2.address
      );
      await gauge.claimReward(
        1,
        token_1 / 2,
        owner2.address,
        owner.address
      );
    }
    console.log("ve_underlying balance after", await ve_underlying.balanceOf(gauge.address));
    // expect(await ve_underlying.balanceOf(gauge.address))
    // .to.equal(ethers.BigNumber.from("1685"));

  })

  it("vote for auth", async function () {
    await expect(gauge.connect(owner2)
    .updateMerchant(1, true, owner2.address)).to.be.reverted;

    const devAuthBefore = await gauge.isAuth(owner.address);
    console.log(await gauge.isAuth(owner2.address));
    console.log(devAuthBefore);

    await gauge.voteForAuth(owner2.address, 2, true);
    console.log(await gauge.isAuth(owner2.address));
    console.log(devAuthBefore);
    expect(await gauge.isAuth(owner2.address)).to.equal(2);
    expect(await gauge.isAuth(owner.address)).to.equal(devAuthBefore.sub(2));
    
    await gauge.voteForAuth(owner2.address, 1, false);
    expect(await gauge.isAuth(owner2.address)).to.equal(1);
    expect(await gauge.isAuth(owner.address)).to.equal(devAuthBefore.sub(3));
    
    await gauge.voteForAuth(owner2.address, 10, true);
    await gauge.voteForAuth(owner2.address, 10, true);
    await gauge.voteForAuth(owner2.address, 10, true);
    expect(await gauge.isAuth(owner.address)).to.equal(devAuthBefore.sub(33));

    await gauge.connect(owner2).updateMerchant(0, true, owner2.address);
  });

  it("should not be able to withdraw", async function () {
    await expect(
      gauge.withdraw(0, 10)
    ).to.be.reverted;
  });
});

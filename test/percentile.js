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
  let mim;
  let dai;
  let ve_underlying;
  let late_reward;
  let ve;
  let factory;
  let router;
  let pair;
  let pair2;
  let pair3;
  let owner;
  let gauge_factory;
  let gauge;
  let gauge2;
  let gauge3;
  let bribe;
  let bribe2;
  let bribe3;
  let minter;
  let ve_dist;
  let library;
  let staking;
  let owner2;
  let owner3;

  let codes;
  let prev_threshold;
  let zscore;
  let percentile;

  it("test computePercentile", async function () {
    [owner, owner2, owner3] = await ethers.getSigners(3);
    const Percentile = await ethers.getContractFactory("Percentile");
    percentile = await Percentile.deploy();
    await percentile.deployed();

    await percentile.computePercentile(100);
    expect(await percentile.totalpaid()).to.equal(100);
    expect(await percentile.totalSponsors()).to.equal(1);
    expect(await percentile.mean()).to.equal(100);
    expect(await percentile.sum_of_diff_squared()).to.equal(0);
    expect(await percentile.std()).to.equal(1);
    zscore = await percentile.zscore();
    expect(zscore).to.equal(0);
    expect(await percentile.getPercentile(zscore)).to.equal(50);

    await percentile.computePercentile(200);
    expect(await percentile.totalpaid()).to.equal(300);
    expect(await percentile.totalSponsors()).to.equal(2);
    expect(await percentile.mean()).to.equal(150);
    expect(await percentile.sum_of_diff_squared()).to.equal(2500);
    expect(await percentile.std()).to.equal(50);
    zscore = await percentile.zscore();
    expect(zscore).to.equal(100);
    expect(await percentile.getPercentile(zscore)).to.equal(84);

    await percentile.computePercentile(1000);
    expect(await percentile.totalpaid()).to.equal(1300);
    expect(await percentile.totalSponsors()).to.equal(3);
    expect(await percentile.mean()).to.equal(433);
    expect(await percentile.sum_of_diff_squared()).to.equal(323989);
    expect(await percentile.std()).to.equal(402);
    zscore = await percentile.zscore();
    expect(zscore).to.equal(141);
    expect(await percentile.getPercentile(zscore)).to.equal(92);

    await percentile.computePercentile(1);
    expect(await percentile.totalpaid()).to.equal(1301);
    expect(await percentile.totalSponsors()).to.equal(4);
    expect(await percentile.mean()).to.equal(325);
    expect(await percentile.sum_of_diff_squared()).to.equal(428965);
    expect(await percentile.std()).to.equal(378);
    zscore = await percentile.zscore();
    expect(zscore).to.equal(-85);
    expect(await percentile.getPercentile(zscore)).to.equal(20);
  });

  it("test computePercentileFromData", async function () {
    let _totalpaid = 0;
    let _totalSponsors = 0;
    let _sum_of_diff_squared = 0;
    let percentile_sds; 
    percentile_sds = await percentile.computePercentileFromData(
      true, 
      100, 
      _totalpaid, 
      _totalSponsors,
      _sum_of_diff_squared
    );
    _totalpaid += 100;
    _totalSponsors += 1;
    _sum_of_diff_squared = percentile_sds[1];
    expect(_totalpaid).to.equal(100);
    expect(_totalSponsors).to.equal(1);
    expect(_totalpaid / _totalSponsors).to.equal(100);
    expect(_sum_of_diff_squared).to.equal(0);
    expect(percentile_sds[0]).to.equal(50);

    percentile_sds = await percentile.computePercentileFromData(
      true, 
      200, 
      _totalpaid, 
      _totalSponsors,
      _sum_of_diff_squared
    );
    _totalpaid += 200;
    _totalSponsors += 1;
    _sum_of_diff_squared.add(percentile_sds[1]);
    expect(_totalpaid).to.equal(300);
    expect(_totalSponsors).to.equal(2);
    expect(_totalpaid / _totalSponsors).to.equal(150);
    expect(_sum_of_diff_squared).to.equal(ethers.BigNumber.from(2500));
    expect(percentile_sds[0]).to.equal(50);

    percentile_sds = await percentile.computePercentileFromData(
      true, 
      1000, 
      _totalpaid, 
      _totalSponsors,
      _sum_of_diff_squared
    );
    _totalpaid += 1000;
    _totalSponsors += 1;
    _sum_of_diff_squared = percentile_sds[1];
    expect(_totalpaid).to.equal(1300);
    expect(_totalSponsors).to.equal(3);
    expect(_totalpaid / _totalSponsors).to.equal(433);
    expect(_sum_of_diff_squared).to.equal(323989);
    expect(percentile_sds[0]).to.equal(84);

    percentile_sds = await percentile.computePercentileFromData(
      true, 
      1, 
      _totalpaid, 
      _totalSponsors,
      _sum_of_diff_squared
    );
    _totalpaid += 1;
    _totalSponsors += 1;
    _sum_of_diff_squared = percentile_sds[1];
    expect(_totalpaid).to.equal(1301);
    expect(_totalSponsors).to.equal(4);
    expect(_totalpaid / _totalSponsors).to.equal(325);
    expect(_sum_of_diff_squared).to.equal(428965);
    expect(percentile_sds[0]).to.equal(20);
  });

});

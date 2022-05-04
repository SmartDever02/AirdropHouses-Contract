const { expect } = require('chai');
const { ethers, getNamedAccounts } = require('hardhat');

let _siner;

describe('AirdropHouses NFT', function () {
  let airdropHouses;

  this.beforeEach(async function () {
    const AirdropHouses = await ethers.getContractFactory('AirdropHouses');
    airdropHouses = await AirdropHouses.deploy();

    await airdropHouses.deployed();

    console.log(typeof getNamedAccounts);

    //    const { deployer, minter, ..._others } = await getNamedAccounts();
    //    _signer = await ethers.getSigner(deployer);
  });

  it('admin confirm', async function () {
    // let tx = await airdropHouses.connect(_siner).setSaleMode(1);
    // await tx.wait();
    // expect(await airdropHouses.saleMode()).to.equals(1);
    // tx = await airdropHouses.connect(_siner).setSaleMode(2);
    // await tx.wait();
    // expect(await airdropHouses.saleMode()).to.equal(2);
  });

  // before this test, set _saleMode = 2 (presale);

  // it('publc sale', async function () {
  //   const recipient = '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266';
  //   expect(await airdropHouses.saleMode()).to.equal(2);

  //   let tx = await airdropHouses.payToMint(recipient, 3, {
  //     value: ethers.utils.parseEther('9'),
  //   });
  //   await tx.wait();

  //   expect(await airdropHouses.count()).to.equal(3);

  //   tx = await airdropHouses.payToMint(recipient, 2, {
  //     value: ethers.utils.parseEther('6'),
  //   });
  //   await tx.wait();

  //   expect(await airdropHouses.count()).to.equal(5);
  //   expect(await airdropHouses.balanceOf(recipient)).to.equal(5);
  // });

  // before this test, set _saleMode = 1 (presale);

  it('initial state:', async function () {
    const recipient = '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266';
    let balance = await airdropHouses.balanceOf(recipient);
    console.log(balance);

    console.log('saleMode: ', await airdropHouses.saleMode());
    expect(await airdropHouses.saleMode()).to.equal(1);

    let currentTimestamp = await airdropHouses.getCurrentTimestamp();
    console.log('now : ', currentTimestamp);

    const price = await airdropHouses.price();
    console.log(await airdropHouses.getTimePast());
    //expect(price.toString()).to.equal('1500000000000000');
    expect(await airdropHouses.count()).to.equal('0');

    expect(await airdropHouses.count()).to.equal(0);
    console.log('left sale', await airdropHouses.getLeftPresale());
    expect(await airdropHouses.getLeftPresale()).to.equal(1200);
    // expect(await airdropHouses.getLeftPresale()).to.equal(1);
  });

  /*
  it('buy 300 nfts then 300 lefts', async function () {
    const recipient = '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266';
    let tx = await airdropHouses.payToWhiteMint(recipient, 3, {
      value: ethers.utils.parseEther('4.5'),
    });
    await tx.wait();

    expect(await airdropHouses.balanceOf(recipient)).to.equal(3);

    expect(await airdropHouses.count()).to.equal(3);

    expect((await airdropHouses.price()).toString()).to.equal(
      '1500000000000000'
    );

    tx = await airdropHouses.payToWhiteMint(recipient, 3, {
      value: ethers.utils.parseEther('4.5'),
    });
    await tx.wait();

    expect(await airdropHouses.balanceOf(recipient)).to.equal(6);

    expect(await airdropHouses.count()).to.equal(6);

    expect((await airdropHouses.price()).toString()).to.equal(
      '2000000000000000'
    );
  });

  it('prices after 2,4,6 hours', async function () {
    await network.provider.send('evm_increaseTime', [7200]);
    await network.provider.send('evm_mine'); // after 2 hours
    expect((await airdropHouses.price()).toString()).to.equal(
      '2000000000000000000'
    );
    await network.provider.send('evm_increaseTime', [7200]);
    await network.provider.send('evm_mine'); //after 4 hours
    expect((await airdropHouses.price()).toString()).to.equal(
      '2500000000000000000'
    );
  });

  // before this test, set _saleMode = 1 (presale);
  // it('Price & Left NFT', async function () {
  //   const recipient = '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266';

  //   let tx = await airdropHouses.payToWhiteMint(recipient, 6, {
  //     value: ethers.utils.parseEther('0.009'),
  //   });

  //   await tx.wait();

  //   expect(await airdropHouses.balanceOf(recipient)).to.equal(6);

  //   expect(await airdropHouses.count()).to.equal(6);

  //   //expect((await airdropHouses.getLeftPresale()).toString()).to.equal('6');

  //   expect((await airdropHouses.price()).toString()).to.equal(
  //     '2000000000000000'
  //   );

  //   tx = await airdropHouses.payToWhiteMint(recipient, 6, {
  //     value: ethers.utils.parseEther('0.012'),
  //   });

  //   await tx.wait();

  //   expect(await airdropHouses.balanceOf(recipient)).to.equal(12);
  //   console.log(
  //     'Now, after 12, price: ' + (await airdropHouses.price()).toString()
  //   );
  // });

  /*
  it('NFT is minted successfully', async function () {
    const recipient = '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266';

    let currentTimestamp = await airdropHouses.getCurrentTimestamp();
    console.log('now : ', currentTimestamp);

    let balance = await airdropHouses.balanceOf(recipient);

    const count = await airdropHouses.price();

    console.log(count);
    console.log(ethers.utils.parseEther('3'));
    console.log(airdropHouses);
    const tx = await airdropHouses.payToMint(recipient, 1, {
      value: ethers.utils.parseEther('3'),
    });

    await tx.wait();

    expect(await airdropHouses.balanceOf(recipient)).to.equal(1);

    // console.log(await kanessa.tokenURI(0));
  });
  */
});

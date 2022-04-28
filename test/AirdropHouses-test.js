const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('AirdropHouses NFT', function () {
  let airdropHouses;

  this.beforeEach(async function () {
    const AirdropHouses = await ethers.getContractFactory('AirdropHouses');
    airdropHouses = await AirdropHouses.deploy();

    await airdropHouses.deployed();
  });

  it('NFT is minted successfully', async function () {
    const recipient = '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266';

    console.log('hey');
    let balance = await airdropHouses.balanceOf(recipient);

    const count = await airdropHouses.price();
    console.log(count);

    console.log(ethers.utils.parseEther('0.05'));
    console.log(airdropHouses);
    const tx = await airdropHouses.payToMint(recipient, 1, {
      value: ethers.utils.parseEther('0.05'),
    });

    await tx.wait();

    expect(await airdropHouses.balanceOf(recipient)).to.equal(1);

    // console.log(await kanessa.tokenURI(0));
  });
});

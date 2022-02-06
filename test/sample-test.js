const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTMarketplace", function () {
  it("Testing the whole functionality of the marketplace.", async function () {
    const Marketplace = await ethers.getContractFactory("NFTMarket");
    const Market = await Marketplace.deploy();
    await Market.deployed();
    const MarketAddress = Market.address;

    const NFT = await ethers.getContractFactory("NFT");
    const NftDep = await NFT.deploy(MarketAddress);
    await NftDep.deployed();
    const NftAddress = NftDep.address;
    
    let ListingPrice = await Market.getListingPrice();
    ListingPrice = ListingPrice.toString();

    const AuctionPrice = ethers.utils.parseUnits('1', 'ether');

    await NftDep.createToken("https://www.test.com");
    await NftDep.createToken("https://www.test2.com");

    await Market.createMarketItem(NftAddress, 1, AuctionPrice, { value: ListingPrice });
    await Market.createMarketItem(NftAddress, 2, AuctionPrice, { value: ListingPrice });

    const [_, BuyerAddress] = await ethers.getSigners();

    await Market.connect(BuyerAddress).createMarketSale(NftAddress, 1, { value: AuctionPrice });

    let MarketNFTS = await Market.fetchMarketItems();
    let MyOwnedNFTS = await Market.fetchMyOwnedNFTs();
    let MyCreatedNFTS = await Market.fetchMyCreatedNFTs();

    MarketNFTS = await Promise.all(MarketNFTS.map(async i => {
      const tokenUri = await NftDep.tokenURI(i.tokenId);
      let item = {
        price: i.price.toString(),
        tokenId: i.tokenId.toString(),
        seller: i.seller,
        owner: i.owner,
        tokenUri
      }
      return item;
    }))

    MyOwnedNFTS = await Promise.all(MyOwnedNFTS.map(async i => {
      const tokenUri = await NftDep.tokenURI(i.tokenId);
      let item = {
        price: i.price.toString(),
        tokenId: i.tokenId.toString(),
        seller: i.seller,
        owner: i.owner,
        tokenUri
      }
      return item;
    }));

    MyCreatedNFTS = await Promise.all(MyCreatedNFTS.map(async i => {
      const tokenUri = await NftDep.tokenURI(i.tokenId);
      let item = {
        price: i.price.toString(),
        tokenId: i.tokenId.toString(),
        seller: i.seller,
        owner: i.owner,
        tokenUri
      }
      return item;
    }));

    console.log("Marketplace NFTS", MarketNFTS);
    console.log("My owned NFTS", MyOwnedNFTS);
    console.log("My created NFTS", MyCreatedNFTS);
  });
});

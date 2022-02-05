pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    address payable owner;
    uint256 listingPrice = 0.025 ether;

    constructor() {
        owner = payable(msg.sender);
    }

    struct MarketItem {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;

    event MarketItemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    function getListingPrice() public view returns(uint) {
        return listingPrice;
    }

    function createMarketItem(address nftContract, uint256 tokenID, uint256 price) public payable nonReentrant {
        require(price > 0, "Please give a specific price");
        require(msg.value == listingPrice, "Please pay the listing price!");

        _itemIds.increment();
        uint256 itemID = _itemIds.current();

        idToMarketItem[itemID] = MarketItem(
            itemID,
            nftContract,
            tokenID,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenID);

        emit MarketItemCreated(
            itemID, 
            nftContract, 
            tokenID, 
            msg.sender, 
            address(0), 
            price, 
            false
        );
    }

    function createMarketSale(address nftContract, uint256 itemID) public payable nonReentrant {
        uint256 price = idToMarketItem[itemID].price;
        uint256 tokenID = idToMarketItem[itemID].tokenId;

        require(msg.value == price, "Please pay the asking price to buy this asset");

        idToMarketItem[itemID].seller.transfer(msg.value);
        IERC721(nftContract).transferFrom(address(0), msg.sender, tokenID);
        idToMarketItem[itemID].owner = payable(msg.sender);
        idToMarketItem[itemID].sold = true;
        _itemsSold.increment();
        payable(owner).transfer(listingPrice);
    }

    function fetchMarketItems() public view returns(MarketItem[] memory) {
        uint256 itemCount = _itemIds.current();
        uint256 unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for(uint i=0; i<itemCount; i++) {
            if(idToMarketItem[i+1].owner == address(0)) {
                uint256 currentItemID = idToMarketItem[i+1].itemId;
                MarketItem storage item = idToMarketItem[currentItemID];
                items[currentIndex] = item;
                currentIndex += 1;
            }
        }

        return items;
    }

    function fetchMyOwnedNFTs() public view returns(MarketItem[] memory) {
        uint256 itemCount = _itemIds.current();
        uint256 count = 0;
        uint256 currentIndex = 0;

        for(uint i=0; i<itemCount; i++) {
            if(idToMarketItem[i+1].owner == msg.sender) {
                count += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](count);
        for(uint i=0; i<itemCount; i++) {
            if(idToMarketItem[i+1].owner == msg.sender) {
                uint256 currentItemID = idToMarketItem[i+1].itemId;
                MarketItem storage item = idToMarketItem[currentItemID];
                items[currentIndex] = item;
                currentIndex += 1;
            }
        }

        return items;
    }

   function fetchMyCreatedNFTs() public view returns(MarketItem[] memory) {
        uint256 itemCount = _itemIds.current();
        uint256 count = 0;
        uint256 currentIndex = 0;

        for(uint i=0; i<itemCount; i++) {
            if(idToMarketItem[i+1].seller == msg.sender) {
                count += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](count);
        for(uint i=0; i<itemCount; i++) {
            if(idToMarketItem[i+1].seller == msg.sender) {
                uint256 currentItemID = idToMarketItem[i+1].itemId;
                MarketItem storage item = idToMarketItem[currentItemID];
                items[currentIndex] = item;
                currentIndex += 1;
            }
        }

        return items;
    }
}
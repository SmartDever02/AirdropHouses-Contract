//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AirdropHouses is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    uint private _saleMode = 0;             // 0 - nothing, 1 - presale 2-public sale
    mapping (uint256 => mapping(uint256 => bytes32)) private _merkleRoots;

    // uint256 private _presalePrice = 15 * 10 ** 17;        // 1.5 eth
    // uint256 private _publicSalePrice  = 3 * 10 ** 18;    // 3 eth
    // uint256 private _risingPrice = 5 * 10 ** 17;         // 0.5 eth

    // For just testing.
    uint256 private _presalePrice = 15;        // 15 wei
    uint256 private _publicSalePrice  = 30;    // 30 wei
    uint256 private _risingPrice = 5;         // 5 wei
    uint256 private _priceLastChangeTime;           // price last change time

    uint256 private _sheetsPerPrice = 10;       // 10 should be 500
    uint256 private _batchDuration = 1 hours;       

    uint256 private _publicMintLimit = 5;       

    uint _startDate;

    string private _strBaseTokenURI;

    event MerkelRootChanged(uint256 _groupNum, bytes32 _merkleRoot);
    event SaleModeChanged(uint _saleMode);
    event RisingPriceChanged(uint _risingPrice);
    event SheetsPerPriceChanged(uint _sheetsPerPrice);
    event BatchDurationChanged(uint _batchDuration);
    event publicMintLimitChanged(uint _publicMintLimit);
    event StartDateChanged(uint startDate);
    event MintNFT(address indexed _to, uint256 _number);
    event BaseURIChanged(string newURI);

    constructor() ERC721("AirDropHouses", "ADH") {
        _merkleRoots[1][10] = 0x96acecf251fdbb6eef35fde352b9afa11bdb198444de51d20aa190be3da3498f;
        _merkleRoots[1][7] = 0xf45563d140b2f28102755980ec9e98d1fa35a83720a38bbd0616d4e3016030a4;
        _merkleRoots[1][1] = 0x86b477c107683bf6bcb4fc7da646b68bbeb71ac92d3e509fac621e0f8179561c;
        _merkleRoots[2][5] = 0x76871e49c2fb1d6cbcc657139c829cb7e7187b370ddddeaeb90ef60450f151e1;
        _merkleRoots[2][6] = 0x7fe1f522b96df4e466cbe9dba168ef6be4722a57ecbb7afb85e4f251a671dc90;
        _merkleRoots[3][7] = 0xf7e14cb1df408269baef2f9dac5873cf0df451bd989680601f5b99b97fa5de4b;
    }   

    function getCurrentTimestamp() external view returns (uint) {
        return block.timestamp;
    }

    function _baseURI() internal view override returns (string memory) {
        return _strBaseTokenURI;
    }

    function totalCount() public pure returns (uint256) {
        return 2000;
    }

    function getTimePast() public view returns (uint) {
        return block.timestamp - _startDate;
    }

    // get count of sheets by past time and count of sheets that are sold out
    function getLeftPresale() public view returns (uint256) {
        if(_tokenIdCounter.current() >= _sheetsPerPrice * 3) return 0;
        uint batchNum = getBatchNum();
        return _sheetsPerPrice * batchNum - (_tokenIdCounter.current() % _sheetsPerPrice);
    }

    function getBatchNum() public view returns (uint256) {
        uint batch  = getTimePast() / _batchDuration + 1;

        return batch >= 3 ? 3 : batch;
    }

    function price() public view returns (uint256) {
        if (_saleMode == 0) {
            return _presalePrice;
        }
        if (_saleMode == 2) {
            return _publicSalePrice;
        }

        uint countLevel = _tokenIdCounter.current() / _sheetsPerPrice;
        uint timeLevel = getTimePast() / _batchDuration / 3;
        uint max = countLevel > timeLevel ? countLevel : timeLevel;

        return _presalePrice + ( max >= 2 ? 2: max ) * _risingPrice;
    }

    function safeMint(address to, uint256 number) public onlyOwner {
        for (uint256 i = 0; i < number; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
        }

        emit MintNFT(to, number);
        // _setTokenURI(tokenId, tokenURI(tokenId));
    }

    function _burn(uint256 _tokenId) internal override {
        super._burn(_tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for non-existent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, (tokenId + 1).toString(), ".json"))
                : "";
    }

    function payToMint(address recipiant, uint256 number) public payable {
        require((_saleMode == 2), "Public mint is not started yet!");

        require(msg.value >= price() * number, "Money is not enough!");

        require((number <= totalCount() - count()), "There are less sheets left than you want!");

        require((balanceOf(recipiant) + number <= _publicMintLimit), "You can NOT buy more than _publicMintLimit sheets!");
        
        for (uint256 i = 0; i < number; i++) {
            uint256 newItemid = _tokenIdCounter.current();
            _tokenIdCounter.increment();

            _mint(recipiant, newItemid);
        }

        emit MintNFT(recipiant, number);
    }

    function payToWhiteMint(
        address recipiant,
        uint256 limit,
        bytes32[] memory proof,
        uint256 number
    ) public payable {

        require(_saleMode == 1, "Presale is not suppoted!");

        require(_tokenIdCounter.current() < _sheetsPerPrice * 3, "Too late, all presale NFTs are sold out");

        require(getTimePast() < 10 * _batchDuration , "You are too late, presale is finished");    // check if preSale is finished

        require(msg.value >= price() * number, "Money is not enough!");

        require(balanceOf(recipiant) + number <= limit, "Mint amount limitation!");

        require((getLeftPresale() >= number), "There aren't enough nfts for you in this batch!");

        bool isWhitelisted = verifyWhitelist(getBatchNum(), _leaf(recipiant), limit, proof);

        require(isWhitelisted, "Sorry, You are not a whitelist member.");
        
        if(getLeftPresale() == number) {
            setLastPriceChangeTime(block.timestamp);
        }

        for (uint256 i = 0; i < number; i++) {
            uint256 newItemid = _tokenIdCounter.current();
            _tokenIdCounter.increment();

            _mint(recipiant, newItemid);
        }

        emit MintNFT(recipiant, number);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function count() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function saleMode() external view returns (uint) {
        return _saleMode;
    }

    function sheetsPerPrice() external view returns (uint) {
        return _sheetsPerPrice;
    }

    function batchDuration() external view returns (uint) {
        return _batchDuration;
    }

    function fromLastPriceTimeToNow() external view returns (uint) {
        return block.timestamp - _priceLastChangeTime;
    }

    function verifyWhitelist(uint256 batchNum, bytes32 leaf, uint limit, bytes32[] memory proof)
        public
        view
        returns (bool)
    {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash < proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        for(uint i = 1; i <= batchNum; i++) {
            if(_merkleRoots[i][limit] == computedHash) {
                return true;
            }
        }
        return false;
        // return computedHash == _merkleRoots[batchNum][limit] ;
    }

    function setMerkleRoot(uint256 batchNum, uint256 groupNum, bytes32 merkleRoot) external onlyOwner {
        _merkleRoots[batchNum][groupNum] = merkleRoot;

        emit MerkelRootChanged(groupNum, merkleRoot);
    }

    function setStartDate(uint256 lunchTime) private {
        _startDate = lunchTime;

        emit StartDateChanged(lunchTime);
    }

    function setLastPriceChangeTime(uint lastTime) private {
        _priceLastChangeTime = lastTime;
    }

    function setSaleMode(uint mode) external onlyOwner {
        _saleMode = mode;
        if (mode == 1) {
            setStartDate(block.timestamp);
            setLastPriceChangeTime(block.timestamp);
        }
        emit SaleModeChanged(mode);
    }

    function setRisingPrice(uint risingPrice) external onlyOwner {
        _risingPrice = risingPrice;

        emit RisingPriceChanged(risingPrice);
    }

    function setSheetsPerPrice(uint sheets) external onlyOwner {
        _sheetsPerPrice = sheets;

        emit SheetsPerPriceChanged(sheets);
    }

    function setTimePerBatch(uint duration) external onlyOwner {
        _batchDuration = duration;

        emit BatchDurationChanged(duration);
    }

    function setPublicMintLimit(uint publicMintLimit) external onlyOwner {
        _publicMintLimit = publicMintLimit;

        emit publicMintLimitChanged(publicMintLimit);
    }

    function setBaseURI(string memory newURI) external onlyOwner {
        _strBaseTokenURI = newURI;

        emit BaseURIChanged(newURI);
    }

}

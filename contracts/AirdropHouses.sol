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
    uint private _saleMode = 1;             // 0 - nothing, 1 - presale 2-public sale
    mapping (uint256 => bytes32) private _merkleRoots;

    uint256 private presalePrice = 15 * 10 ** 14;        // 0.0015 eth
    uint256 private publicSalePrice  = 3 * 10 ** 15;    // 0.003 eth

    uint _startDate = 1651327724;                // 2012-12-01 10:00:00

    string private _strBaseTokenURI;

    event SaleModeChanged(uint _saleMode);
    event MintNFT(address indexed _to, uint256 _number);

    constructor() ERC721("AirDropHouses", "PSL") {
        _merkleRoots[10] = 0x30959cbaa933e9367ddcc27eeaa02cad38815d0a1ad3285d9e05cd8cf1218d62;
        _merkleRoots[8] = 0x4e393124e51b15d221d3496d8235cb7ea5ccd33fdaf2086e5a111d30fc32bfcb;
        _merkleRoots[6] = 0x2c533542fc960de5bf7ce191a58ce06e48c030ddb43697e4bceac1e686f9d3d2;
        _merkleRoots[4] = 0x08d336b85ad41c2d076a0b38d8b7758f61a8ee7c6980f8b4928b038bf98aa2d1;
        _merkleRoots[2] = 0xfadbd3c7f79fa2bdc4f24857709cd4a4e870623dc9e9abcdfd6e448033e35212;
        _merkleRoots[1] = 0x135ef9624875b00601c3d17487323d5831d2caacf19de1ed33f2e675597f46f0;
        _strBaseTokenURI = "https://";
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

    // in production change 6 -> 600
    function getLeftPresale(uint timestamp) public view returns (uint256) {
        uint limitCount;
        // if ((block.timestamp - _startDate) / 60 / 60 <= 2) {
        if (timestamp <= _startDate + 2 hours) {
            limitCount = 6;
        }
        else if (timestamp <= _startDate + 4 hours) {
            limitCount = 12;
        }
        else if (timestamp <= _startDate + 6 hours) {
            limitCount = 18;
        }
        return limitCount >= (_tokenIdCounter.current() / 6 + 1) * 6 ? limitCount - _tokenIdCounter.current() : (_tokenIdCounter.current() / 6 + 1) - _tokenIdCounter.current();
        // return limitCount - _tokenIdCounter.current();
    }


    // in production change 10 ** 14 => 10 ** 16
    function price() public view returns (uint256) {
        if (_saleMode == 2) {
            return publicSalePrice;
        }
        if (getTimePast() / 60 / 60 < 2) {
            console.log('before 2: ',presalePrice + 5 * 10 ** 14 * (_tokenIdCounter.current() / 6));
            return presalePrice + 5 * 10 ** 14 * (_tokenIdCounter.current() / 6);
        }
        else if (getTimePast() / 60 / 60 < 4) {
            return presalePrice + 5 * 10 ** 14 + 5 * 10 ** 14 * (_tokenIdCounter.current() / 12);
        }
        return presalePrice + 10 * 10 ** 14;                    // 0.0025 eth
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
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function payToMint(address recipiant, uint256 number) public payable {
        require((_saleMode == 2), "Public mint is not started yet!");
        require(msg.value >= price() * number, "Money is not enough!");
        require((number <= totalCount() - count()), "There are less sheets left than you want!");
        require((balanceOf(recipiant) + number <= 5), "You can NOT buy more than 5 sheets!");
        
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

        require((block.timestamp - _startDate <= 6 * 60 * 60), "You are too late, presale is finished");

        require(msg.value >= price() * number, "Money is not enough!");

        require(balanceOf(recipiant) + number <= limit, "Mint amount limitation!");

        require((getLeftPresale(block.timestamp) >= number), "There aren't enough nfts for you!");

        bool isWhitelisted = verifyWhitelist(_leaf(recipiant), limit, proof);

        require(isWhitelisted, "Not whitelisted");

        for (uint256 i = 0; i < number; i++) {
            uint256 newItemid = _tokenIdCounter.current();
            _tokenIdCounter.increment();

            _mint(recipiant, newItemid);
        }

        emit MintNFT(recipiant, number);
    }

    function count() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function verifyWhitelist(bytes32 leaf, uint limit, bytes32[] memory proof)
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
        return computedHash == _merkleRoots[limit];
    }

    function setMerkleRoot(uint256 groupNum, bytes32 merkleRoot) external onlyOwner {
        _merkleRoots[groupNum] = merkleRoot;
    }

    function saleMode() external view returns (uint) {
        return _saleMode;
    }

    function setStartDate(uint256 launchTime) private {
        _startDate = launchTime;
    }

    function setSaleMode(uint mode) external onlyOwner {
        _saleMode = mode;
        setStartDate(block.timestamp);
        emit SaleModeChanged(mode);
    }

}

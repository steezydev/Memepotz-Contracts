// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ERC721A } from "erc721a/contracts/ERC721A.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Genesis is ERC721A, Ownable {
    string public uriSuffix;
    string public baseUri;
    uint256 public maxSupply;
    uint256 public mintPrice;
    uint256 public maxPerWallet;
    bytes32 public merkleRoot;

    mapping(address owner => uint256 tokenId) public mintedTokens;

    modifier whitelistCompliance(bytes32[] calldata _merkleProof) {
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, node), "Invalid Merkle proof");
        _;
    }

    modifier mintCompliance(uint256 quantity) {
        require(_totalMinted() + quantity <= maxSupply, "Max supply reached");
        require(msg.value >= mintPrice, "Insufficient mint price");
        require(_numberMinted(msg.sender) + quantity <= maxPerWallet, "Mint limit reached for wallet");
        _;
    }

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _baseUri,
        string memory _uriSuffix,
        uint256 _maxSupply,
        uint256 _mintPrice,
        uint256 _maxPerWallet
    ) ERC721A(_tokenName, _tokenSymbol) {
        baseUri = _baseUri;
        uriSuffix = _uriSuffix;
        maxSupply = _maxSupply;
        mintPrice = _mintPrice;
        maxPerWallet = _maxPerWallet;
    }

    function whitelistMint(
        uint256 quantity,
        bytes32[] calldata _merkleProof
    ) external payable mintCompliance(quantity) whitelistCompliance(_merkleProof) {
        _mint(msg.sender, quantity);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(_tokenId), uriSuffix)) : "";
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }
}

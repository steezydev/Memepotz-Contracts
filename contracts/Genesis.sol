// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 

contract Memepotz is Ownable, ERC721Burnable, Pausable {
    using Strings for uint256;

    uint256 private _tokenIds;
    uint256 public maxPerWallet = 10;
    uint256 public mintPrice = 1 ether;
    bytes32 public merkleRoot;

    // Base URL for metadata
    string private _baseTokenURI;

    // Mapping wallet address to counter
    mapping(address => uint256) private _mintedTokens;

    constructor(string memory baseTokenURI, bytes32 merkleRoot_) ERC721("Memepotz #0", "MEG0") {
        _baseTokenURI = baseTokenURI;
        merkleRoot = merkleRoot_;
    }

    function safeMint(address recipient, bytes32[] calldata merkleProof) public payable whenNotPaused {
        require(msg.value >= mintPrice, "Not enough Ether sent");
        require(_mintedTokens[recipient] < maxPerWallet, "Mint limit exceeded");

        // Verify the merkle proof
        bytes32 node = keccak256(abi.encodePacked(recipient));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "Invalid proof");

        _tokenIds++;
        uint256 newItemId = _tokenIds;
        _safeMint(recipient, newItemId);
        _mintedTokens[recipient] += 1;
    }

    function burn(uint256 tokenId) public virtual override(ERC721Burnable) whenNotPaused {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _burn(tokenId);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function airdropNFT(address recipient) public onlyOwner {
        _tokenIds++;
        uint256 newItemId = _tokenIds;
        _mint(recipient, newItemId);
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

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : ".json";
    }
    

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}

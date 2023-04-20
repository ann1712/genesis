// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GenesisNFT is ERC721, Ownable{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    uint256[3] public mintPrice = [0.001 ether, 0.002 ether, 0.003 ether];
    uint256[3] public mintTime = [1681984800, 1681986000, 1681987200];
    uint public mintInterval = 20 minutes;
    uint256[3] public mintRound = [5, 10, 15];
    uint256 public TOTAL_SUPPLY = 30;
    uint256[3] public soldRound;
    
    struct WhiteList {
        address wallet;
        uint level;
    }

    //White list with level
    mapping (address => uint256) public whiteListLevel;

    mapping (address => uint256) public waitList;

    mapping (address => uint256[3]) public ownerToGenesis;

    constructor() ERC721("Genesis NFT", "GNS") {

    }

    function mint() public payable {
        uint256 round = _getCurrentRound();
        require(round > 0,"It's not time for mint!");
        if(round == 1) {
            // Whitelist round;
            require(whiteListLevel[msg.sender]>0, "You'r not in whitelist");
            require(ownerToGenesis[msg.sender][round-1] < whiteListLevel[msg.sender], "Limit NFT for your level!");
        }
        else if (round == 2){
            require(waitList[msg.sender] > 0, "You'r not in wait list");
            require(ownerToGenesis[msg.sender][round-1] < waitList[msg.sender], "You only mint 1 NFT in wait round");
        } else {
            require(ownerToGenesis[msg.sender][round-1] < 1, "You only mint 1 NFT in public round");
        }
        require(soldRound[round-1] < mintRound[round-1], "NFT sold out!");
        require(msg.value == mintPrice[round-1], "Not enough balance");
        _mint();
        soldRound[round-1]++;
        ownerToGenesis[msg.sender][round-1]++;
        
    }

    function _mint() internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }


    // Populate WhiteList
    function setWhiteList(WhiteList[] memory wls) external onlyOwner {
        for (uint256 i=0; i < wls.length; i++) {
            require(wls[i].level > 0 && wls[i].level < 4, "Level from 1-3!");
            whiteListLevel[wls[i].wallet] = wls[i].level;
            waitList[wls[i].wallet] = 1;
        }
    }

    // Populate WhiteList
    function addWaitList(address[] memory addresses) external onlyOwner {
        for (uint256 i=0; i < addresses.length; i++) {
            waitList[addresses[i]] = 1;
        }
    }

     // Get current Round
    function _getCurrentRound() public view returns (uint256){
        for(uint256 i = 0; i < 3; i++){
            if(block.timestamp >= mintTime[i] && block.timestamp < mintTime[i] + mintInterval) return i+1;
        }
        return 0; 
    }

     //Withdraw
    function withdraw(address _addr) external onlyOwner(){
        // Get balance of contract
        uint256 balance = address(this).balance;
        payable(_addr).transfer(balance);
    }

}
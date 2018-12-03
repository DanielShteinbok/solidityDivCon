// a simple dividend-paying contract. Minting only happens in the constructor,
// meaning that nobody's "shares" get diluted. 

// NOTE: this was written for use with Remix IDE. If a different IDE is used, the import
// will probably not work as is.

// feel free to use any part or all of this code for whatever you are doing.
pragma solidity ^0.4.24;

import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/master/contracts/token/ERC20/ERC20.sol";

contract TestCoin is ERC20 {
    // keep track of all token-holding addresses by linking each one to another.
    mapping (address => address) private tokenHolders;
    
    // keeps track of the last token-holding address
    address private lastHolder;
    
    // creator of the contract
    address public creator;
    
    // this contract should be able to receive ether
    function() public payable {
        
    }
    function payDividends() public {
        require(msg.sender == creator);
        address current = lastHolder;
        while (current != 0) {
            current.transfer(address(this).balance*this.balanceOf(current)/totalSupply());
            current = tokenHolders[current];
        }
    }
    
    // get the address that points to address person.
    // This function is private because it can cause problems:
    // the lastHolder will return itself. This is useful because only non-holders
    // return zeroes, but it can cause problems if used wrong (eternal gas-eating while loops, etc).
    function getBehind(address person) private view returns (address) {
        if (person == lastHolder){
            return person;
        }
        address current = lastHolder;
        while (tokenHolders[current] != 0) {
            if (tokenHolders[current] == person) {
                return current;
            }
            current = tokenHolders[current];
        }
        
        return 0;
    }
    function addHolder(address person) internal {
        tokenHolders[person] = lastHolder;
        lastHolder = person;
    }
    function removeHolder(address person) internal {
        if (lastHolder != person) {
            tokenHolders[getBehind(person)] = tokenHolders[person];
        }
        delete tokenHolders[person];
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        if (this.balanceOf(msg.sender) == 0) {
            removeHolder(msg.sender);
        }
        if (getBehind(to) == 0) {
            addHolder(to);
        }
        return true;
    }
    constructor(uint startAmount) public {
        creator = msg.sender;
        _mint(creator, startAmount);
        addHolder(creator);
    }
}

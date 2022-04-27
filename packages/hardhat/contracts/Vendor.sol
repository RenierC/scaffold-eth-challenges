pragma solidity 0.8.4;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
    uint256 public constant tokensPerEth = 100;

    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event Withdrawal(address owner, uint256 amount);
    event SellTokens(
        address buyer,
        uint256 amountOfETH,
        uint256 amountOfTokens
    );

    YourToken public yourToken;

    constructor(address tokenAddress) {
        yourToken = YourToken(tokenAddress);
    }

    function buyTokens() public payable {
        require(msg.value > 0, "You must send a non zero amount of ETH");

        uint256 amountToSend = msg.value * tokensPerEth;

        require(
            yourToken.balanceOf(address(this)) >= amountToSend,
            "The contract doesn't have enough tokens to cover the amount requested"
        );

        yourToken.transfer(msg.sender, msg.value * tokensPerEth);

        emit BuyTokens(msg.sender, msg.value, amountToSend);
    }

    // FIXME: it's part of the challenge but the owner shouldn't be able to withdraw the contract's funds
    function withdraw() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "You don't have any tokens to withdraw");

        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "The call failed");

        emit Withdrawal(msg.sender, contractBalance);
    }

    function sellTokens(uint256 amountToSell) public payable {
        require(amountToSell > 0, "You must send a non zero amount of tokens");
        require(
            yourToken.balanceOf(msg.sender) >= amountToSell,
            "You don't have enough tokens to sell"
        );

        uint256 amountToSend = amountToSell / tokensPerEth;

        require(
            address(this).balance >= amountToSend,
            "The contract doesn't have enough ETH to cover the amount requested"
        );

        bool charge = yourToken.transferFrom(
            msg.sender,
            address(this),
            amountToSell
        );
        require(charge, "Failed to get user's tokens");

        (bool success, ) = msg.sender.call{value: amountToSend}("");
        require(success, "Failed to send ETH to the user");

        emit SellTokens(msg.sender, amountToSell, amountToSend);
    }
}

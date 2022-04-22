// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  mapping ( address => uint256 ) public balances;

  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 30 seconds;
  bool public openForWithdraw = false;

  event Stake(address indexed _from, uint256 amount);
  event Withdraw(address indexed _from, uint256 amount);
  event Received(address, uint);

  modifier notCompleted() {
   require(!exampleExternalContract.completed(), "Staking process completed");
    _;
  }

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable {
    require(msg.value > 0 , "Stake amount must be greater than 0");
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() public notCompleted {
    require(!openForWithdraw, "The function was already executed");
    if(address(this).balance >= threshold && timeLeft() == 0) {
      exampleExternalContract.complete{value: address(this).balance}();
    } else {
      // if the `threshold` was not met, allow everyone to call a `withdraw()` function
      openForWithdraw = true;
    }
  }

  // Add a `withdraw()` function to let users withdraw their balance
  function withdraw() public notCompleted {
    uint256 userStake = balances[msg.sender];
    require(timeLeft() == 0, "The deadline has passed");
    require(openForWithdraw, "The function was not executed()");

    balances[msg.sender] = 0; 

    (bool withdrawal, ) = payable(msg.sender).call{value: userStake}("");
    require(withdrawal, "Error sending funds");

    emit Withdraw(msg.sender, userStake);
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
 function timeLeft() public view returns (uint256) {
    if(block.timestamp >= deadline) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
 }

  // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        stake();
        emit Received(msg.sender, msg.value);
    }
}

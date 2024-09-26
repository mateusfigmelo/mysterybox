// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console2} from "forge-std/Test.sol";
import "forge-std/Test.sol";
import "../src/MysteryBox.sol";

contract MysteryBoxTest is Test {
    MysteryBox public mysteryBox;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = makeAddr("owner");
        vm.deal(owner, 1 ether);
        user1 = address(0x1);
        user2 = address(0x2);
        vm.prank(owner);
        mysteryBox = new MysteryBox{value: 0.1 ether}();
        //console.log("Reward Pool Length:", mysteryBox.getRewardPool().length);
    }

    function testOwnerIsSetCorrectly() public view {
        assertEq(mysteryBox.owner(), owner);
    }

    function testSetBoxPrice() public {
        vm.prank(owner);
        uint256 newPrice = 0.2 ether;
        mysteryBox.setBoxPrice(newPrice);
        assertEq(mysteryBox.boxPrice(), newPrice);
    }

    function testSetBoxPrice_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert("Only owner can set price");
        mysteryBox.setBoxPrice(0.2 ether);
    }

    function testAddReward() public {
        vm.prank(owner);
        mysteryBox.addReward("Diamond Coin", 2 ether);
        MysteryBox.Reward[] memory rewards = mysteryBox.getRewardPool();
        assertEq(rewards.length, 5);
        assertEq(rewards[4].name, "Diamond Coin");
        assertEq(rewards[4].value, 2 ether);
    }

    function testAddReward_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert("Only owner can add rewards");
        mysteryBox.addReward("Diamond Coin", 2 ether);
    }

    function testBuyBox() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        mysteryBox.buyBox{value: 0.1 ether}();
        console.log("Before Open:", mysteryBox.boxesOwned(user1));
        assertEq(mysteryBox.boxesOwned(user1), 2);
    }

    function testBuyBox_IncorrectETH() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        vm.expectRevert("Incorrect ETH sent");
        mysteryBox.buyBox{value: 0.05 ether}();
    }

    function testOpenBox() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        mysteryBox.buyBox{value: 0.1 ether}();
        console.log("Before Open:", mysteryBox.boxesOwned(user1));
        vm.prank(user1);
        mysteryBox.openBox();
        console.log("After Open:", mysteryBox.boxesOwned(user1));
        assertEq(mysteryBox.boxesOwned(user1), 0);

        vm.prank(user1);
        MysteryBox.Reward[] memory rewards = mysteryBox.getRewards();
        console2.log(rewards[0].name);
        assertEq(rewards.length, 1);
    }

    function testOpenBox_NoBoxes() public {
        vm.prank(user1);
        vm.expectRevert("No boxes to open");
        mysteryBox.openBox();
    }

    function testTransferReward_InvalidIndex() public {
        vm.prank(user1);
        vm.expectRevert("Invalid index");
        mysteryBox.transferReward(user2, 0);
    }

    function testWithdrawFunds() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        mysteryBox.buyBox{value: 0.1 ether}();
        vm.prank(user1);
        mysteryBox.buyBox{value: 0.1 ether}();

        uint256 ownerBalanceBefore = owner.balance;
        console.log("Owner Balance Before:", ownerBalanceBefore);
        
        vm.prank(owner);
        mysteryBox.withdrawFunds();
        uint256 ownerBalanceAfter = owner.balance;
        console.log("Owner Balance After:", ownerBalanceAfter);

        assertEq(ownerBalanceAfter - ownerBalanceBefore, 0.3 ether);
    }

    function testWithdrawFunds_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert("Only owner can withdraw");
        mysteryBox.withdrawFunds();
    }

    function testChangeOwner() public {
        mysteryBox.changeOwner(user1);
        assertEq(mysteryBox.owner(), user1);
    }

    function testChangeOwner_AccessControl() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        mysteryBox.buyBox{value: 0.1 ether}();
        vm.prank(user1);
        mysteryBox.buyBox{value: 0.1 ether}();
        uint256 user2BalanceBefore = user2.balance;
        console.log("user2 Balance Before:", user2BalanceBefore);
        vm.prank(user2);
        mysteryBox.changeOwner(user2);
        assertEq(mysteryBox.owner(), user2);
        
        vm.prank(user2);
        mysteryBox.withdrawFunds();
        uint256 user2BalanceAfter = user2.balance;
        console.log("user2 Balance After:", user2BalanceAfter);

        assertEq(user2BalanceAfter - user2BalanceBefore, 0.3 ether);
    }
    function testClaimSingleReward() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        mysteryBox.buyBox{value: 0.1 ether}();
        vm.prank(user1);
        mysteryBox.openBox();
        vm.prank(user1);
        MysteryBox.Reward[] memory rewards = mysteryBox.getRewards();
        console2.log(rewards[0].name);
        assertEq(rewards.length, 1);

        vm.prank(user1);
        mysteryBox.claimSingleReward(1);
        rewards = mysteryBox.getRewards();
        assertEq(rewards.length, 0);
    }
}

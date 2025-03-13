//SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {InheritanceManager} from "../src/InheritanceManager.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract InheritanceManagerTest is Test {
    InheritanceManager im;
    ERC20Mock usdc;
    ERC20Mock weth;

    address owner = makeAddr("owner");
    address user1 = makeAddr("user1");

    function setUp() public {
        vm.prank(owner);
        im = new InheritanceManager();
        usdc = new ERC20Mock();
        weth = new ERC20Mock();
    }
    /*//////////////////////////////////////////////////////////////
                                 AUDIT
    //////////////////////////////////////////////////////////////*/


    function test_withdrawInheritedFundsEtherDuplicateBeneficiary() public {
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");
        vm.startPrank(owner);
        im.addBeneficiery(user1);
        im.addBeneficiery(user1);
        im.addBeneficiery(user2);
        im.addBeneficiery(user3);
        vm.stopPrank();
        vm.warp(1);
        vm.deal(address(im), 9e18);
        vm.warp(1 + 90 days);
        vm.startPrank(user1);
        im.inherit();
        im.withdrawInheritedFunds(address(0));
        vm.stopPrank();
        uint256 proportion = 9e18 / 4;
        assertEq(proportion * 2, user1.balance);
        assertEq(proportion, user2.balance);
        assertEq(proportion, user3.balance);
    }

    function test_removeBeneficiaryII() public {
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");
        address inexistentUser = makeAddr("inexistentUser");

        vm.startPrank(owner);
        im.addBeneficiery(user1);
        im.addBeneficiery(user2);
        im.addBeneficiery(user3);
        vm.stopPrank();
        assertEq(0, im._getBeneficiaryIndex(user1));
        assertEq(1, im._getBeneficiaryIndex(user2));
        assertEq(2, im._getBeneficiaryIndex(user3));
        vm.startPrank(owner);
        im.removeBeneficiary(user2);
        im.removeBeneficiary(inexistentUser);

        vm.stopPrank();
        console.log(" index0", im.getBeneficiary(0));
        console.log(" index1", im.getBeneficiary(1));
        console.log(" index2", im.getBeneficiary(2));
        assert(1 != im._getBeneficiaryIndex(user2));
    }

    function test_removeFirstBeneficiaryByPassingInexistentIndex() public {
        address user2 = makeAddr("user2");
        address inexistentUser = makeAddr("inexistentUser");
        vm.startPrank(owner);
        im.addBeneficiery(user1);
        im.addBeneficiery(user2);
        assertEq(user1, im.getBeneficiary(0));
        assertEq(user2, im.getBeneficiary(1));

        im.removeBeneficiary(inexistentUser);
        vm.stopPrank();

        assert(user1 != im.getBeneficiary(0));
    }

    /**
     * If the owner only call the functions that do not update the deadline like `InheritanceManager::contractInteractions` or `InheritanceManager::createEstateNFT` it can lead to allowing inheritance despite owner interactions which breaks the core purpose of the contract.
     */
    function test_inheritanceManagerInteractions() public {
        address user2 = makeAddr("user2");

        // First add beneficiary and roll to 90 days and check the deadline
        vm.startPrank(owner);
        im.addBeneficiery(user1);
        im.addBeneficiery(user2);
        vm.stopPrank();

        vm.warp(90 days);
        assertEq(1 + 90 days, im.getDeadline());
        vm.prank(user1);
        vm.expectRevert(InheritanceManager.InactivityPeriodNotLongEnough.selector);
        im.inherit();

        // Now call the functions that do not update the deadline
        vm.startPrank(owner);
        vm.warp(1 + 100 days);
        im.contractInteractions(address(0), abi.encode(address(0)), 0, false);
        vm.warp(1 + 120 days);
        im.createEstateNFT("our beach-house", 2000000, address(usdc));
        vm.stopPrank();

        // The deadline has not being updated
        assertEq(1 + 90 days, im.getDeadline());
        assertEq(vm.getBlockTimestamp(), 1 + 120 days);

        vm.prank(user1);
        im.inherit();

        assertEq(true, im.getIsInherited());
    }

    function test_zeroAddressBeneficiaryFundLoss() public {
        address user2 = makeAddr("user2");

        vm.startPrank(owner);
        // Add a valid beneficiary
        im.addBeneficiery(user1);
        // Add the zero address as a beneficiary
        im.addBeneficiery(address(0));
        // Add another valid beneficiary
        im.addBeneficiery(user2);

        // Fund the contract
        vm.deal(address(im), 3 ether);
        vm.stopPrank();

        // Wait for inheritance timelock to expire
        vm.warp(block.timestamp + 91 days);

        // Trigger inheritance
        vm.prank(user1);
        im.inherit();

        // Try to withdraw funds - this will attempt to send 1 ETH to address(0)
        vm.prank(user1);
        // This may revert or burn 1 ETH depending on the environment
        try im.withdrawInheritedFunds(address(0)) {
            // If it succeeds, check that 1 ETH was sent to address(0) (effectively burned)
            assertEq(address(0).balance, 1 ether);
            assertEq(user1.balance, 1 ether);
            assertEq(user2.balance, 1 ether);
        } catch {
            // If it reverts, no one gets their funds
            assertEq(address(im).balance, 3 ether);
            assertEq(user1.balance, 0);
            assertEq(user2.balance, 0);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                ORIGINAL
    //////////////////////////////////////////////////////////////*/

    function test_sendERC20FromOwner() public {
        usdc.mint(address(im), 10e18);
        weth.mint(address(im), 10e18);
        vm.startPrank(owner);
        im.sendERC20(address(weth), 1e18, user1);
        assertEq(weth.balanceOf(address(im)), 9e18);
        assertEq(weth.balanceOf(user1), 1e18);
        vm.stopPrank();
    }

    function test_sendERC20FromUserFail() public {
        usdc.mint(address(im), 10e18);
        weth.mint(address(im), 10e18);
        vm.startPrank(user1);
        vm.expectRevert();
        im.sendERC20(address(weth), 1e18, user1);
        assertEq(weth.balanceOf(address(im)), 10e18);
        vm.stopPrank();
    }

    function test_sendERC20FromOwnerDeadlineUpdate() public {
        uint256 deadline = im.getDeadline();
        uint256 expectedDeadline = 1 + 90 days;
        usdc.mint(address(im), 10e18);
        weth.mint(address(im), 10e18);
        vm.warp(10);
        vm.startPrank(owner);
        im.sendERC20(address(weth), 1e18, user1);
        assertEq(weth.balanceOf(address(im)), 9e18);
        assertEq(weth.balanceOf(user1), 1e18);
        deadline = im.getDeadline();
        expectedDeadline = 10 + 90 days;
        assertEq(deadline, expectedDeadline);
        vm.stopPrank();
    }

    function test_sendEtherFromOwner() public {
        vm.deal(address(im), 10e18);
        vm.startPrank(owner);
        im.sendETH(1e18, user1);
        assertEq(address(im).balance, 9e18);
        assertEq(user1.balance, 1e18);
        vm.stopPrank();
    }

    function test_sendEtherFromUserFail() public {
        vm.deal(address(im), 10e18);
        vm.startPrank(user1);
        vm.expectRevert();
        im.sendETH(1e18, owner);
        assertEq(address(im).balance, 10e18);
        vm.stopPrank();
    }

    function test_sendEtherFromOwnerDeadlineUpdate() public {
        uint256 deadline = im.getDeadline();
        uint256 expectedDeadline = 1 + 90 days;
        vm.deal(address(im), 10e18);
        vm.warp(10);
        vm.startPrank(owner);
        im.sendETH(1e18, user1);
        assertEq(address(im).balance, 9e18);
        assertEq(user1.balance, 1e18);
        deadline = im.getDeadline();
        expectedDeadline = 10 + 90 days;
        assertEq(deadline, expectedDeadline);
        vm.stopPrank();
    }

    function test_addBeneficiarySuccess() public {
        vm.startPrank(owner);
        im.addBeneficiery(user1);
        vm.stopPrank();
        assertEq(0, im._getBeneficiaryIndex(user1));
    }

    function test_addBeneficiaryFail() public {
        vm.startPrank(user1);
        vm.expectRevert();
        im.addBeneficiery(user1);
        vm.stopPrank();
    }

    function test_removeBeneficiary() public {
        address user2 = makeAddr("user2");
        vm.startPrank(owner);
        im.addBeneficiery(user1);
        im.addBeneficiery(user2);
        vm.stopPrank();
        assertEq(0, im._getBeneficiaryIndex(user1));
        assertEq(1, im._getBeneficiaryIndex(user2));
        vm.startPrank(owner);
        im.removeBeneficiary(user2);
        vm.stopPrank();
        assert(1 != im._getBeneficiaryIndex(user2));
    }

    function test_inheritBeforeDeadline() public {
        vm.startPrank(owner);
        im.addBeneficiery(user1);
        vm.stopPrank();
        vm.warp(1);
        vm.deal(address(im), 10e10);
        vm.warp(1 + 80 days);
        vm.startPrank(user1);
        vm.expectRevert();
        im.inherit();
        vm.stopPrank();
        assertEq(owner, im.getOwner());
    }

    function test_inheritOnlyOneBeneficiary() public {
        vm.startPrank(owner);
        im.addBeneficiery(user1);
        vm.stopPrank();
        vm.warp(1);
        vm.deal(address(im), 10e10);
        vm.warp(1 + 90 days);
        vm.startPrank(user1);
        im.inherit();
        vm.stopPrank();
        assertEq(user1, im.getOwner());
    }

    function test_inheritMultipleBeneficiaries() public {
        address user2 = makeAddr("user2");
        vm.startPrank(owner);
        im.addBeneficiery(user1);
        im.addBeneficiery(user2);
        vm.stopPrank();
        vm.warp(1);
        vm.deal(address(im), 10e10);
        vm.warp(1 + 90 days);
        vm.startPrank(user1);
        im.inherit();
        vm.stopPrank();
        assertEq(owner, im.getOwner());
        assertEq(true, im.getIsInherited());
    }

    function test_withdrawInheritedFundsFail() public {
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");
        vm.startPrank(owner);
        im.addBeneficiery(user1);
        im.addBeneficiery(user2);
        im.addBeneficiery(user3);
        vm.stopPrank();
        vm.warp(1);
        vm.deal(address(im), 10e10);
        vm.warp(1 + 90 days);
        vm.startPrank(user1);
        vm.expectRevert();
        im.withdrawInheritedFunds(address(0));
        vm.stopPrank();
    }

    function test_withdrawInheritedFundsEtherSuccess() public {
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");
        vm.startPrank(owner);
        im.addBeneficiery(user1);
        im.addBeneficiery(user2);
        im.addBeneficiery(user3);
        vm.stopPrank();
        vm.warp(1);
        vm.deal(address(im), 9e18);
        vm.warp(1 + 90 days);
        vm.startPrank(user1);
        im.inherit();
        im.withdrawInheritedFunds(address(0));
        vm.stopPrank();
        assertEq(3e18, user1.balance);
        assertEq(3e18, user2.balance);
        assertEq(3e18, user3.balance);
    }

    function test_withdrawInheritedFundsERC20Success() public {
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");
        vm.startPrank(owner);
        im.addBeneficiery(user1);
        im.addBeneficiery(user2);
        im.addBeneficiery(user3);
        vm.stopPrank();
        vm.warp(1);
        usdc.mint(address(im), 9e18);
        vm.warp(1 + 90 days);
        vm.startPrank(user1);
        im.inherit();
        im.withdrawInheritedFunds(address(usdc));
        vm.stopPrank();
        assertEq(3e18, usdc.balanceOf(user1));
        assertEq(3e18, usdc.balanceOf(user2));
        assertEq(3e18, usdc.balanceOf(user3));
    }

    function test_buyOutEstateNFTFailNotInherited() public {
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");
        vm.startPrank(owner);
        im.addBeneficiery(user1);
        im.addBeneficiery(user2);
        im.addBeneficiery(user3);
        im.createEstateNFT("our beach-house", 2000000, address(usdc));
        vm.stopPrank();
        vm.startPrank(user1);
        vm.expectRevert();
        im.buyOutEstateNFT(1);
        vm.stopPrank();
    }

    function test_buyOutEstateNFTFailNotBeneficiary() public {
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");
        address user4 = makeAddr("user4");
        vm.warp(1);
        vm.startPrank(owner);
        im.addBeneficiery(user1);
        im.addBeneficiery(user2);
        im.addBeneficiery(user3);
        im.createEstateNFT("our beach-house", 2000000, address(usdc));
        vm.stopPrank();
        vm.warp(1 + 90 days);
        vm.startPrank(user4);
        im.inherit();
        vm.expectRevert();
        im.buyOutEstateNFT(1);
        vm.stopPrank();
    }

    function test_buyOutEstateNFTSuccess() public {
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");
        vm.warp(1);
        vm.startPrank(owner);
        im.addBeneficiery(user1);
        im.addBeneficiery(user2);
        im.addBeneficiery(user3);
        im.createEstateNFT("our beach-house", 3e6, address(usdc));
        vm.stopPrank();
        usdc.mint(user3, 4e6);
        vm.warp(1 + 90 days);
        vm.startPrank(user3);
        usdc.approve(address(im), 4e6);
        im.inherit();
        im.buyOutEstateNFT(1);
        vm.stopPrank();
    }

    function test_appointTrusteeSuccess() public {
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");
        vm.startPrank(owner);
        im.addBeneficiery(user1);
        im.addBeneficiery(user2);
        vm.stopPrank();
        vm.warp(1);
        vm.deal(address(im), 9e18);
        vm.warp(1 + 90 days);
        vm.startPrank(user1);
        im.inherit();
        im.appointTrustee(user3);
        vm.stopPrank();
        assertEq(user3, im.getTrustee());
    }
}

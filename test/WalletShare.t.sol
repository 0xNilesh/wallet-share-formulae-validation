// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { WalletShare } from "../src/WalletShare.sol";
import { DataTypes } from "../src/libs/Datatypes.sol";
import { console2 } from "forge-std/src/console2.sol";

contract WalletShareTest is PRBTest, StdCheats {
    address payable public bobWallet;
    address payable public aliceWallet;
    address payable public rabbyWallet;
    address payable public foundationWallet;
    address payable public adminWallet;
    mapping(address actor => uint256 keys) public privateKeys;
    WalletShare internal walletShare;

    function createActor(string memory name) internal returns (address payable) {
        address actor;
        uint256 privateKey;
        (actor, privateKey) = makeAddrAndKey(name);
        address payable _actor = payable(actor);
        privateKeys[actor] = privateKey;
        return _actor;
    }

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        bobWallet = createActor("bobWallet");
        aliceWallet = createActor("aliceWallet");
        rabbyWallet = createActor("rabbyWallet");
        foundationWallet = createActor("foundationWallet");
        adminWallet = createActor("adminWallet");
        // Instantiate the contract-under-test.
        walletShare = new WalletShare(foundationWallet, adminWallet);
    }

    function test_FoundationGetsInitialShares() public {
        uint256 initialSharesAmount = 100_000;
        uint256 foundationWalletShares = walletShare.shares(foundationWallet);
        uint256 actualTotalShares = walletShare.walletTotalShares();
        assertEq(initialSharesAmount, foundationWalletShares);
        assertEq(foundationWalletShares, actualTotalShares);
    }

    function test_WalletGets_20PercentAllocation() public {
        uint256 bobWalletSharesBefore = walletShare.shares(bobWallet);
        DataTypes.Percentage memory percentAllocation = DataTypes.Percentage({ percentageNumber: 20, decimalPlaces: 0 });

        vm.prank(adminWallet);
        walletShare.addWalletShare(bobWallet, percentAllocation);
        uint256 expectedAllocationShares = 25_000;
        uint256 bobWalletSharesAfter = walletShare.shares(bobWallet);
        uint256 actualTotalShares = walletShare.walletTotalShares();

        assertEq(bobWalletSharesBefore, 0);
        assertEq(bobWalletSharesAfter, expectedAllocationShares);
        assertEq(actualTotalShares, 125_000);
    }

    function test_WalletGets_50PercentAllocation() public {
        // bob wallet gets allocated 20% shares i.e. 25k
        test_WalletGets_20PercentAllocation();

        uint256 aliceWalletSharesBefore = walletShare.shares(aliceWallet);
        DataTypes.Percentage memory percentAllocation = DataTypes.Percentage({ percentageNumber: 50, decimalPlaces: 0 });

        vm.prank(adminWallet);
        walletShare.addWalletShare(aliceWallet, percentAllocation);
        uint256 expectedAllocationShares = 125_000;
        uint256 bobWalletSharesAfter = walletShare.shares(bobWallet);
        uint256 aliceWalletSharesAfter = walletShare.shares(aliceWallet);
        uint256 foundationWalletSharesAfter = walletShare.shares(foundationWallet);
        uint256 actualTotalShares = walletShare.walletTotalShares();

        assertEq(aliceWalletSharesBefore, 0);
        assertEq(bobWalletSharesAfter, 25_000);
        assertEq(aliceWalletSharesAfter, expectedAllocationShares);
        assertEq(foundationWalletSharesAfter, 100_000);
        assertEq(actualTotalShares, 250_000);
    }

    // removes wallet allocation and removes shares from circulation
    function test_RemovalWalletM1() public {
        // bobWallet has 20% allocation (25k shares), aliceWallet has 50% (125k) & foundation (100k)
        test_WalletGets_50PercentAllocation();

        uint256 totalSharesBefore = walletShare.walletTotalShares();
        uint256 bobWalletSharesBefore = walletShare.shares(bobWallet);
        uint256 aliceWalletSharesBefore = walletShare.shares(aliceWallet);
        uint256 foundationWalletSharesBefore = walletShare.shares(foundationWallet);

        vm.prank(adminWallet);
        walletShare.removeWalletShareM1(bobWallet);

        uint256 totalSharesAfter = walletShare.walletTotalShares();
        uint256 bobWalletSharesAfter = walletShare.shares(bobWallet);
        uint256 aliceWalletSharesAfter = walletShare.shares(aliceWallet);
        uint256 foundationWalletSharesAfter = walletShare.shares(foundationWallet);

        assertEq(bobWalletSharesAfter, 0);
        assertEq(aliceWalletSharesAfter, aliceWalletSharesBefore);
        assertEq(foundationWalletSharesAfter, foundationWalletSharesBefore);
        assertEq(totalSharesAfter, totalSharesBefore - bobWalletSharesBefore);
    }

    // removes wallet allocation and assign shares to the foundation
    function test_RemovalWalletM2() public {
        // bobWallet has 20% allocation (25k shares), aliceWallet has 50% (125k) & foundation (100k)
        test_WalletGets_50PercentAllocation();

        uint256 totalSharesBefore = walletShare.walletTotalShares();
        uint256 bobWalletSharesBefore = walletShare.shares(bobWallet);
        uint256 aliceWalletSharesBefore = walletShare.shares(aliceWallet);
        uint256 foundationWalletSharesBefore = walletShare.shares(foundationWallet);

        vm.prank(adminWallet);
        walletShare.removeWalletShareM2(bobWallet);

        uint256 totalSharesAfter = walletShare.walletTotalShares();
        uint256 bobWalletSharesAfter = walletShare.shares(bobWallet);
        uint256 aliceWalletSharesAfter = walletShare.shares(aliceWallet);
        uint256 foundationWalletSharesAfter = walletShare.shares(foundationWallet);

        assertEq(bobWalletSharesAfter, 0);
        assertEq(aliceWalletSharesAfter, aliceWalletSharesBefore);
        assertEq(foundationWalletSharesAfter, foundationWalletSharesBefore + bobWalletSharesBefore);
        assertEq(totalSharesAfter, totalSharesBefore);
    }

    // testing add wallet after removal with method m1 (remove allocation from circulation)
    function test_AddWallet_AfterRemoval_M1() public {
        test_RemovalWalletM1();
        uint256 rabbyWalletSharesBefore = walletShare.shares(rabbyWallet);

        DataTypes.Percentage memory percentAllocation = DataTypes.Percentage({ percentageNumber: 50, decimalPlaces: 0 });

        vm.prank(adminWallet);
        walletShare.addWalletShare(rabbyWallet, percentAllocation);
        uint256 expectedAllocationShares = 225_000;
        uint256 rabbyWalletSharesAfter = walletShare.shares(rabbyWallet);
        uint256 totalSharesAfter = walletShare.walletTotalShares();

        assertEq(rabbyWalletSharesBefore, 0);
        assertEq(rabbyWalletSharesAfter, expectedAllocationShares);
        assertEq(totalSharesAfter, 450_000);
    }

    // testing add wallet after removal with method m2 (assign shares to foundation)
    function test_AddWallet_AfterRemoval_M2() public {
        test_RemovalWalletM2();
        uint256 rabbyWalletSharesBefore = walletShare.shares(rabbyWallet);

        DataTypes.Percentage memory percentAllocation = DataTypes.Percentage({ percentageNumber: 50, decimalPlaces: 0 });

        vm.prank(adminWallet);
        walletShare.addWalletShare(rabbyWallet, percentAllocation);
        uint256 expectedAllocationShares = 250_000;
        uint256 rabbyWalletSharesAfter = walletShare.shares(rabbyWallet);
        uint256 totalSharesAfter = walletShare.walletTotalShares();

        assertEq(rabbyWalletSharesBefore, 0);
        assertEq(rabbyWalletSharesAfter, expectedAllocationShares);
        assertEq(totalSharesAfter, 500_000);
    }

    // assign wallet 0.001% shares
    function test_WalletGets_NegligiblePercentAllocation() public {
        uint256 bobWalletSharesBefore = walletShare.shares(bobWallet);
        DataTypes.Percentage memory percentAllocation = DataTypes.Percentage({ percentageNumber: 1, decimalPlaces: 3 });

        vm.prank(adminWallet);
        walletShare.addWalletShare(bobWallet, percentAllocation);
        uint256 expectedAllocationShares = 1;
        uint256 bobWalletSharesAfter = walletShare.shares(bobWallet);
        uint256 actualTotalShares = walletShare.walletTotalShares();

        assertEq(bobWalletSharesBefore, 0);
        assertEq(bobWalletSharesAfter, expectedAllocationShares);
        assertEq(actualTotalShares, 100_001);
    }

    // assign wallet 0.0001% shares
    function test_WalletGets_NegligiblePercentAllocation2() public {
        uint256 bobWalletSharesBefore = walletShare.shares(bobWallet);
        DataTypes.Percentage memory percentAllocation = DataTypes.Percentage({ percentageNumber: 1, decimalPlaces: 4 });

        vm.prank(adminWallet);
        walletShare.addWalletShare(bobWallet, percentAllocation);
        uint256 expectedAllocationShares = 0;
        uint256 bobWalletSharesAfter = walletShare.shares(bobWallet);
        uint256 actualTotalShares = walletShare.walletTotalShares();

        assertEq(bobWalletSharesBefore, 0);
        assertEq(bobWalletSharesAfter, expectedAllocationShares);
        assertEq(actualTotalShares, 100_000);
    }

    function test_IncreaseWalletShare() public {
        // assigns bobWallet 20% allocation
        test_WalletGets_20PercentAllocation();

        // let's increase bobWallet allocation to 50%
        uint256 totalSharesBefore = walletShare.walletTotalShares();
        uint256 bobWalletSharesBefore = walletShare.shares(bobWallet);
        uint256 foundationWalletSharesBefore = walletShare.shares(foundationWallet);

        DataTypes.Percentage memory percentAllocation = DataTypes.Percentage({ percentageNumber: 50, decimalPlaces: 0 });

        vm.prank(adminWallet);
        walletShare.increaseWalletShares(bobWallet, percentAllocation);
        uint256 expectedAllocationShares = 100_000;
        uint256 totalSharesAfter = walletShare.walletTotalShares();
        uint256 bobWalletSharesAfter = walletShare.shares(bobWallet);
        uint256 foundationWalletSharesAfter = walletShare.shares(foundationWallet);

        assertEq(bobWalletSharesBefore, 25_000);
        assertEq(totalSharesBefore, 125_000);
        assertEq(foundationWalletSharesBefore, 100_000);
        assertEq(bobWalletSharesAfter, expectedAllocationShares);
        assertEq(totalSharesAfter, 200_000);
        assertEq(foundationWalletSharesAfter, 100_000);
    }

    function test_DecreaseWalletShare() public {
        // assigns bobWallet 20% allocation
        test_WalletGets_20PercentAllocation();

        // let's decrease bobWallet allocation to 10%
        uint256 totalSharesBefore = walletShare.walletTotalShares();
        uint256 bobWalletSharesBefore = walletShare.shares(bobWallet);
        uint256 foundationWalletSharesBefore = walletShare.shares(foundationWallet);

        DataTypes.Percentage memory percentAllocation = DataTypes.Percentage({ percentageNumber: 10, decimalPlaces: 0 });

        vm.prank(adminWallet);
        walletShare.decreaseWalletSharesM2(bobWallet, percentAllocation);
        uint256 expectedAllocationShares = 13_888;
        uint256 totalSharesAfter = walletShare.walletTotalShares();
        uint256 bobWalletSharesAfter = walletShare.shares(bobWallet);
        uint256 foundationWalletSharesAfter = walletShare.shares(foundationWallet);

        assertEq(bobWalletSharesBefore, 25_000);
        assertEq(totalSharesBefore, 125_000);
        assertEq(foundationWalletSharesBefore, 100_000);
        assertEq(bobWalletSharesAfter, expectedAllocationShares);
        assertEq(totalSharesAfter, 138_888);
        assertEq(foundationWalletSharesAfter, 125_000);
    }
}

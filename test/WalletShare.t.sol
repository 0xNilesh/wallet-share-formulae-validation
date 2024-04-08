// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { WalletShare } from "../src/WalletShare.sol";

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
}

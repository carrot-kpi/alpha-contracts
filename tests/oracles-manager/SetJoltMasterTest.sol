pragma solidity 0.8.13;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";

/**
 * @title SetJoltMasterTest
 * @dev SetJoltMasterTest contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract SetJoltMasterTest is BaseTestSetup {
    function testNonOwner() external {
        CHEAT_CODES.prank(address(1));
        CHEAT_CODES.expectRevert("Ownable: caller is not the owner");
        oraclesManager.setJoltMaster(address(0));
    }

    function testZeroAddress() external {
        // just in case the jobs registry is initially set to 0, set it to another value
        oraclesManager.setJoltMaster(address(1));
        assertEq(oraclesManager.joltMaster(), address(1));
        oraclesManager.setJoltMaster(address(0));
        assertEq(oraclesManager.joltMaster(), address(0));
    }

    function testNonZeroAddress() external {
        // just in case the jobs registry is initially set to non-0, set it to 0
        oraclesManager.setJoltMaster(address(0));
        assertEq(oraclesManager.joltMaster(), address(0));
        oraclesManager.setJoltMaster(address(1));
        assertEq(oraclesManager.joltMaster(), address(1));
    }
}

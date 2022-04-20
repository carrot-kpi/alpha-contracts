pragma solidity 0.8.13;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";

/**
 * @title OraclesManagerInstantiationTest
 * @dev OraclesManagerInstantiationTest contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract OraclesManagerInstantiationTest is BaseTestSetup {
    function testZeroAddressFactory() external {
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("ZeroAddressFactory()")
        );
        new OraclesManager(address(0), address(0));
    }

    function testZeroAddressJobsRegistry() external {
        new OraclesManager(address(factory), address(0));
    }
}
pragma solidity 0.8.13;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";

/**
 * @title FactorySetOraclesManagerTest
 * @dev FactorySetOraclesManagerTest contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract FactorySetOraclesManagerTest is BaseTestSetup {
    function testNonOwner() external {
        CHEAT_CODES.prank(address(1));
        CHEAT_CODES.expectRevert(abi.encodeWithSignature("Forbidden()"));
        factory.setOraclesManager(address(2));
    }

    function testZeroAddressManager() external {
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("ZeroAddressOraclesManager()")
        );
        factory.setOraclesManager(address(0));
    }

    function testSuccess() external {
        assertEq(factory.oraclesManager(), address(oraclesManager));
        address _newOraclesManager = address(2);
        factory.setOraclesManager(_newOraclesManager);
        assertEq(factory.oraclesManager(), _newOraclesManager);
    }
}

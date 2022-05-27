pragma solidity 0.8.14;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";

/**
 * @title FactorySetKpiTokensManagerTest
 * @dev FactorySetKpiTokensManagerTest contract
 * @author Federico Luzzi - <federico.luzzi@protonmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract FactorySetKpiTokensManagerTest is BaseTestSetup {
    function testNonOwner() external {
        CHEAT_CODES.prank(address(1));
        CHEAT_CODES.expectRevert(abi.encodeWithSignature("Forbidden()"));
        factory.setKpiTokensManager(address(2));
    }

    function testZeroAddressManager() external {
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("ZeroAddressKpiTokensManager()")
        );
        factory.setKpiTokensManager(address(0));
    }

    function testSuccess() external {
        assertEq(factory.kpiTokensManager(), address(kpiTokensManager));
        address _newKpiTokensManager = address(2);
        factory.setKpiTokensManager(_newKpiTokensManager);
        assertEq(factory.kpiTokensManager(), _newKpiTokensManager);
    }
}

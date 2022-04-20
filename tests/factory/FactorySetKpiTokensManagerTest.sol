pragma solidity 0.8.13;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {IKPITokensManager} from "../../contracts/interfaces/IKPITokensManager.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title FactorySetKpiTokensManagerTest
 * @dev FactorySetKpiTokensManagerTest contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
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

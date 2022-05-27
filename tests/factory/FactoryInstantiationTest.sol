pragma solidity 0.8.14;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {KPITokensFactory} from "../../contracts/KPITokensFactory.sol";

/**
 * @title FactoryInstantiationTest
 * @dev FactoryInstantiationTest contract
 * @author Federico Luzzi - <federico.luzzi@protonmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract FactoryInstantiationTest is BaseTestSetup {
    function testZeroAddressKpiTokensManager() external {
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("ZeroAddressKpiTokensManager()")
        );
        new KPITokensFactory(address(0), address(1), address(2));
    }

    function testZeroAddressOraclesManager() external {
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("ZeroAddressOraclesManager()")
        );
        new KPITokensFactory(address(1), address(0), address(2));
    }

    function testZeroAddressFeeReceiver() external {
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("ZeroAddressFeeReceiver()")
        );
        new KPITokensFactory(address(1), address(2), address(0));
    }

    function testSuccess() external {
        new KPITokensFactory(address(1), address(2), address(3));
    }
}

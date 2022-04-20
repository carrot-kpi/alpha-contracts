pragma solidity 0.8.13;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {KPITokensManager} from "../../contracts/KPITokensManager.sol";

/**
 * @title KpiTokensManagerInstantiationTest
 * @dev KpiTokensManagerInstantiationTest contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract KpiTokensManagerInstantiationTest is BaseTestSetup {
    function testZeroAddressFactory() external {
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("ZeroAddressFactory()")
        );
        new KPITokensManager(address(0));
    }
}

pragma solidity 0.8.14;

import {BaseTestSetup} from "../../../commons/BaseTestSetup.sol";
import {ERC20KPIToken} from "../../../../contracts/kpi-tokens/ERC20KPIToken.sol";
import {Clones} from "oz/proxy/Clones.sol";

/**
 * @title ERC20KPITokenBaseRecoverTest
 * @dev ERC20KPITokenBaseRecoverTest contract
 * @author Federico Luzzi - <federico.luzzi@protonmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract ERC20KPITokenBaseRecoverTest is BaseTestSetup {
    function testNotOwner() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );
        CHEAT_CODES.expectRevert(abi.encodeWithSignature("Forbidden()"));
        CHEAT_CODES.prank(address(123));
        kpiTokenInstance.recoverERC20(address(33333), address(this));
    }
}

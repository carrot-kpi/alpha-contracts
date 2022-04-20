pragma solidity 0.8.13;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {KPITokensManager} from "../../contracts/KPITokensManager.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title KpiTokensManagerTemplatesAmountTest
 * @dev KpiTokensManagerTemplatesAmountTest contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract KpiTokensManagerTemplatesAmountTest is BaseTestSetup {
    function testNoTemplates() external {
        kpiTokensManager = new KPITokensManager(address(factory));
        assertEq(kpiTokensManager.templatesAmount(), 0);
    }

    function testOneTemplate() external {
        kpiTokensManager = new KPITokensManager(address(factory));
        kpiTokensManager.addTemplate(address(2), "a");
        assertEq(kpiTokensManager.templatesAmount(), 1);
    }

    function testMultipleTemplates() external {
        kpiTokensManager.addTemplate(address(10), "a");
        kpiTokensManager.addTemplate(address(11), "b");
        assertEq(kpiTokensManager.templatesAmount(), 4);
    }
}

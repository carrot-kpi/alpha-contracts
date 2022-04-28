pragma solidity 0.8.13;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {KPITokensManager} from "../../contracts/KPITokensManager.sol";
import {IKPITokensManager} from "../../contracts/interfaces/IKPITokensManager.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title KpiTokensManagerEnumerateTest
 * @dev KpiTokensManagerEnumerateTest contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract KpiTokensManagerEnumerateTest is BaseTestSetup {
    function testNoTemplates() external {
        kpiTokensManager = new KPITokensManager(address(factory));
        CHEAT_CODES.expectRevert(abi.encodeWithSignature("InvalidIndices()"));
        kpiTokensManager.enumerate(0, 1);
    }

    function testOneTemplateSuccess() external {
        assertEq(kpiTokensManager.enumerate(0, 1).length, 1);
    }

    function testMultipleTemplatesSuccess() external {
        kpiTokensManager.addTemplate(address(10), "a");
        kpiTokensManager.addTemplate(address(11), "b");
        kpiTokensManager.addTemplate(address(12), "c");
        kpiTokensManager.addTemplate(address(12), "d");
        kpiTokensManager.addTemplate(address(12), "e");
        kpiTokensManager.addTemplate(address(12), "f");
        kpiTokensManager.addTemplate(address(12), "g");
        kpiTokensManager.addTemplate(address(12), "h");
        kpiTokensManager.addTemplate(address(12), "i");
        assertEq(kpiTokensManager.enumerate(0, 10).length, 10);
    }

    function testInconsistentIndices() external {
        CHEAT_CODES.expectRevert(abi.encodeWithSignature("InvalidIndices()"));
        kpiTokensManager.enumerate(10, 5);
    }

    function testOneTemplateFail() external {
        CHEAT_CODES.expectRevert(abi.encodeWithSignature("InvalidIndices()"));
        kpiTokensManager.enumerate(0, 10);
    }
}

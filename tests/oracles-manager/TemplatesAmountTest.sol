pragma solidity 0.8.13;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {IOraclesManager} from "../../contracts/interfaces/IOraclesManager.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title TemplatesAmountTest
 * @dev TemplatesAmountTest contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract TemplatesAmountTest is BaseTestSetup {
    function testNoTemplates() external {
        oraclesManager = new OraclesManager(address(factory), address(0));
        assertEq(oraclesManager.templatesAmount(), 0);
    }

    function testOneTemplate() external {
        assertEq(oraclesManager.templatesAmount(), 1);
    }

    function testMultipleTemplates() external {
        oraclesManager.addTemplate(address(10), false, "a");
        oraclesManager.addTemplate(address(11), false, "b");
        oraclesManager.addTemplate(address(12), false, "c");
        assertEq(oraclesManager.templatesAmount(), 4);
    }
}

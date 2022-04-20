pragma solidity 0.8.13;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {IOraclesManager} from "../../contracts/interfaces/IOraclesManager.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title OraclesManagerRemoveTemplateTest
 * @dev OraclesManagerRemoveTemplateTest contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract OraclesManagerRemoveTemplateTest is BaseTestSetup {
    function testNonOwner() external {
        CHEAT_CODES.prank(address(1));
        CHEAT_CODES.expectRevert(abi.encodeWithSignature("Forbidden()"));
        oraclesManager.removeTemplate(0);
    }

    function testNonExistentTemplate() external {
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("NonExistentTemplate()")
        );
        oraclesManager.removeTemplate(10);
    }

    function testSuccess() external {
        IOraclesManager.Template memory _template = oraclesManager.template(0);
        assertTrue(_template.exists);
        oraclesManager.removeTemplate(0);
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("NonExistentTemplate()")
        );
        oraclesManager.template(0);
    }
}

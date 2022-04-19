pragma solidity 0.8.13;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {IOraclesManager} from "../../contracts/interfaces/IOraclesManager.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title UpdateTemplateSpecificationTest
 * @dev UpdateTemplateSpecificationTest contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract UpdateTemplateSpecificationTest is BaseTestSetup {
    function testNonOwner() external {
        CHEAT_CODES.prank(address(1));
        CHEAT_CODES.expectRevert(abi.encodeWithSignature("Forbidden()"));
        oraclesManager.updateTemplateSpecification(0, "");
    }

    function testNonExistentTemplate() external {
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("NonExistentTemplate()")
        );
        oraclesManager.updateTemplateSpecification(1, "a");
    }

    function testEmptySpecification() external {
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("InvalidSpecification()")
        );
        oraclesManager.updateTemplateSpecification(0, "");
    }

    function testSuccess() external {
        string memory _oldSpecification = "a";
        oraclesManager.addTemplate(address(2), false, _oldSpecification);
        uint256 _templateId = oraclesManager.templatesAmount() - 1;
        IOraclesManager.Template memory _template = oraclesManager.template(
            _templateId
        );
        assertTrue(_template.exists);
        assertEq(_template.specification, _oldSpecification);
        string memory _newSpecification = "b";
        oraclesManager.updateTemplateSpecification(
            _templateId,
            _newSpecification
        );
        _template = oraclesManager.template(_templateId);
        assertTrue(_template.exists);
        assertEq(_template.specification, _newSpecification);
    }
}

pragma solidity 0.8.13;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {KPITokensManager} from "../../contracts/KPITokensManager.sol";
import {IKPITokensManager} from "../../contracts/interfaces/IKPITokensManager.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title KpiTokensManagerUpdateTemplateSpecificationTest
 * @dev KpiTokensManagerUpdateTemplateSpecificationTest contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract KpiTokensManagerUpdateTemplateSpecificationTest is BaseTestSetup {
    function testNonOwner() external {
        CHEAT_CODES.prank(address(1));
        CHEAT_CODES.expectRevert(abi.encodeWithSignature("Forbidden()"));
        kpiTokensManager.updateTemplateSpecification(0, "");
    }

    function testNonExistentTemplate() external {
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("NonExistentTemplate()")
        );
        kpiTokensManager.updateTemplateSpecification(3, "a");
    }

    function testEmptySpecification() external {
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("InvalidSpecification()")
        );
        kpiTokensManager.updateTemplateSpecification(0, "");
    }

    function testSuccess() external {
        string memory _oldSpecification = "a";
        kpiTokensManager.addTemplate(address(2), _oldSpecification);
        uint256 _templateId = kpiTokensManager.templatesAmount() - 1;
        IKPITokensManager.Template memory _template = kpiTokensManager.template(
            _templateId
        );
        assertTrue(_template.exists);
        assertEq(_template.specification, _oldSpecification);
        string memory _newSpecification = "b";
        kpiTokensManager.updateTemplateSpecification(
            _templateId,
            _newSpecification
        );
        _template = kpiTokensManager.template(_templateId);
        assertTrue(_template.exists);
        assertEq(_template.specification, _newSpecification);
    }
}

pragma solidity 0.8.13;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {KPITokensManager} from "../../contracts/KPITokensManager.sol";
import {IKPITokensManager} from "../../contracts/interfaces/IKPITokensManager.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title KpiTokensManagerUpgradeTemplateTest
 * @dev KpiTokensManagerUpgradeTemplateTest contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract KpiTokensManagerUpgradeTemplateTest is BaseTestSetup {
    function testNonOwner() external {
        CHEAT_CODES.prank(address(1));
        CHEAT_CODES.expectRevert(abi.encodeWithSignature("Forbidden()"));
        kpiTokensManager.upgradeTemplate(0, address(1), uint8(0), "");
    }

    function testNonExistentTemplate() external {
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("NonExistentTemplate()")
        );
        kpiTokensManager.upgradeTemplate(2, address(1), uint8(0), "a");
    }

    function testEmptySpecification() external {
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("InvalidSpecification()")
        );
        kpiTokensManager.upgradeTemplate(0, address(1), uint8(0), "");
    }

    function testSameSpecification() external {
        uint256 _templateId = 0;
        IKPITokensManager.Template memory _template = kpiTokensManager.template(
            _templateId
        );
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("InvalidSpecification()")
        );
        kpiTokensManager.upgradeTemplate(
            _templateId,
            address(1),
            uint8(0),
            _template.specification
        );
    }

    function testInvalidVersionBump() external {
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("InvalidVersionBump()")
        );
        kpiTokensManager.upgradeTemplate(0, address(1), uint8(8), "a");
    }

    function testSuccessPatchBump() external {
        uint256 _templateId = 0;
        IKPITokensManager.Template memory _template = kpiTokensManager.template(
            _templateId
        );
        assertTrue(_template.exists);
        assertEq(_template.version.major, 1);
        assertEq(_template.version.minor, 0);
        assertEq(_template.version.patch, 0);
        string memory _newSpecification = "b";
        address _newAddress = address(123);
        kpiTokensManager.upgradeTemplate(
            _templateId,
            _newAddress,
            uint8(1),
            _newSpecification
        );
        _template = kpiTokensManager.template(_templateId);
        assertTrue(_template.exists);
        assertEq(_template.addrezz, _newAddress);
        assertEq(_template.specification, _newSpecification);
        assertEq(_template.version.major, 1);
        assertEq(_template.version.minor, 0);
        assertEq(_template.version.patch, 1);
    }

    function testSuccessMinorBump() external {
        uint256 _templateId = 0;
        IKPITokensManager.Template memory _template = kpiTokensManager.template(
            _templateId
        );
        assertTrue(_template.exists);
        assertEq(_template.version.major, 1);
        assertEq(_template.version.minor, 0);
        assertEq(_template.version.patch, 0);
        string memory _newSpecification = "b";
        address _newAddress = address(123);
        kpiTokensManager.upgradeTemplate(
            _templateId,
            _newAddress,
            uint8(2),
            _newSpecification
        );
        _template = kpiTokensManager.template(_templateId);
        assertTrue(_template.exists);
        assertEq(_template.addrezz, _newAddress);
        assertEq(_template.specification, _newSpecification);
        assertEq(_template.version.major, 1);
        assertEq(_template.version.minor, 1);
        assertEq(_template.version.patch, 0);
    }

    function testSuccessMajorBump() external {
        uint256 _templateId = 0;
        IKPITokensManager.Template memory _template = kpiTokensManager.template(
            _templateId
        );
        assertTrue(_template.exists);
        assertEq(_template.version.major, 1);
        assertEq(_template.version.minor, 0);
        assertEq(_template.version.patch, 0);
        string memory _newSpecification = "b";
        address _newAddress = address(123);
        kpiTokensManager.upgradeTemplate(
            _templateId,
            _newAddress,
            uint8(4),
            _newSpecification
        );
        _template = kpiTokensManager.template(_templateId);
        assertTrue(_template.exists);
        assertEq(_template.addrezz, _newAddress);
        assertEq(_template.specification, _newSpecification);
        assertEq(_template.version.major, 2);
        assertEq(_template.version.minor, 0);
        assertEq(_template.version.patch, 0);
    }
}

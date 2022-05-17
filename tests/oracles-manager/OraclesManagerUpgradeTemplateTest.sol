pragma solidity 0.8.13;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {IOraclesManager} from "../../contracts/interfaces/IOraclesManager.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title OraclesManagerUpgradeTemplateTest
 * @dev OraclesManagerUpgradeTemplateTest contract
 * @author Federico Luzzi - <federico.luzzi@protonmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract OraclesManagerUpgradeTemplateTest is BaseTestSetup {
    function testNonOwner() external {
        CHEAT_CODES.prank(address(1));
        CHEAT_CODES.expectRevert(abi.encodeWithSignature("Forbidden()"));
        oraclesManager.upgradeTemplate(0, address(1), uint8(0), "");
    }

    function testNonExistentTemplate() external {
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("NonExistentTemplate()")
        );
        oraclesManager.upgradeTemplate(1, address(1), uint8(0), "a");
    }

    function testEmptySpecification() external {
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("InvalidSpecification()")
        );
        oraclesManager.upgradeTemplate(0, address(1), uint8(0), "");
    }

    function testSameSpecification() external {
        uint256 _templateId = 0;
        IOraclesManager.Template memory _template = oraclesManager.template(
            _templateId
        );
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("InvalidSpecification()")
        );
        oraclesManager.upgradeTemplate(
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
        oraclesManager.upgradeTemplate(0, address(1), uint8(8), "a");
    }

    function testSuccessPatchBump() external {
        uint256 _templateId = 0;
        IOraclesManager.Template memory _template = oraclesManager.template(
            _templateId
        );
        assertTrue(_template.exists);
        assertEq(_template.version.major, 1);
        assertEq(_template.version.minor, 0);
        assertEq(_template.version.patch, 0);
        string memory _newSpecification = "b";
        address _newAddress = address(123);
        oraclesManager.upgradeTemplate(
            _templateId,
            _newAddress,
            uint8(1),
            _newSpecification
        );
        _template = oraclesManager.template(_templateId);
        assertTrue(_template.exists);
        assertEq(_template.addrezz, _newAddress);
        assertEq(_template.specification, _newSpecification);
        assertEq(_template.version.major, 1);
        assertEq(_template.version.minor, 0);
        assertEq(_template.version.patch, 1);
    }

    function testSuccessMinorBump() external {
        uint256 _templateId = 0;
        IOraclesManager.Template memory _template = oraclesManager.template(
            _templateId
        );
        assertTrue(_template.exists);
        assertEq(_template.version.major, 1);
        assertEq(_template.version.minor, 0);
        assertEq(_template.version.patch, 0);
        string memory _newSpecification = "b";
        address _newAddress = address(123);
        oraclesManager.upgradeTemplate(
            _templateId,
            _newAddress,
            uint8(2),
            _newSpecification
        );
        _template = oraclesManager.template(_templateId);
        assertTrue(_template.exists);
        assertEq(_template.addrezz, _newAddress);
        assertEq(_template.specification, _newSpecification);
        assertEq(_template.version.major, 1);
        assertEq(_template.version.minor, 1);
        assertEq(_template.version.patch, 0);
    }

    function testSuccessMajorBump() external {
        uint256 _templateId = 0;
        IOraclesManager.Template memory _template = oraclesManager.template(
            _templateId
        );
        assertTrue(_template.exists);
        assertEq(_template.version.major, 1);
        assertEq(_template.version.minor, 0);
        assertEq(_template.version.patch, 0);
        string memory _newSpecification = "b";
        address _newAddress = address(123);
        oraclesManager.upgradeTemplate(
            _templateId,
            _newAddress,
            uint8(4),
            _newSpecification
        );
        _template = oraclesManager.template(_templateId);
        assertTrue(_template.exists);
        assertEq(_template.addrezz, _newAddress);
        assertEq(_template.specification, _newSpecification);
        assertEq(_template.version.major, 2);
        assertEq(_template.version.minor, 0);
        assertEq(_template.version.patch, 0);
    }
}

pragma solidity 0.8.13;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {IOraclesManager} from "../../contracts/interfaces/IOraclesManager.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title AddTemplateTest
 * @dev AddTemplateTest contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract AddTemplateTest is BaseTestSetup {
    function testNonOwner() external {
        CHEAT_CODES.prank(address(1));
        CHEAT_CODES.expectRevert(abi.encodeWithSignature("Forbidden()"));
        oraclesManager.addTemplate(address(2), false, "");
    }

    function testZeroAddressTemplate() external {
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("ZeroAddressTemplate()")
        );
        oraclesManager.addTemplate(address(0), false, "");
    }

    function testEmptySpecification() external {
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("InvalidSpecification()")
        );
        oraclesManager.addTemplate(address(1), false, "");
    }

    function testSuccess() external {
        string memory _specification = "test";
        address _templateAddress = address(1);
        oraclesManager.addTemplate(_templateAddress, false, _specification);
        uint256 _addedTemplateId = oraclesManager.templatesAmount() - 1;
        IOraclesManager.Template memory _template = oraclesManager.template(
            _addedTemplateId
        );
        assertEq(_template.addrezz, _templateAddress);
        assertEq(_template.version.major, 1);
        assertEq(_template.version.minor, 0);
        assertEq(_template.version.patch, 0);
        assertEq(_template.specification, _specification);
        assertTrue(!_template.automatable);
        assertTrue(_template.exists);
    }
}

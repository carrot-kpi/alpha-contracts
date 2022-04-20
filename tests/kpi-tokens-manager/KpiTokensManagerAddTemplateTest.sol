pragma solidity 0.8.13;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {IKPITokensManager} from "../../contracts/interfaces/IKPITokensManager.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title KpiTokensManagerAddTemplateTest
 * @dev KpiTokensManagerAddTemplateTest contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract KpiTokensManagerAddTemplateTest is BaseTestSetup {
    function testNonOwner() external {
        CHEAT_CODES.prank(address(1));
        CHEAT_CODES.expectRevert(abi.encodeWithSignature("Forbidden()"));
        kpiTokensManager.addTemplate(address(2), "");
    }

    function testZeroAddressTemplate() external {
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("ZeroAddressTemplate()")
        );
        kpiTokensManager.addTemplate(address(0), "");
    }

    function testEmptySpecification() external {
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("InvalidSpecification()")
        );
        kpiTokensManager.addTemplate(address(1), "");
    }

    function testSuccess() external {
        string memory _specification = "test";
        address _templateAddress = address(1);
        kpiTokensManager.addTemplate(_templateAddress, _specification);
        uint256 _addedTemplateId = kpiTokensManager.templatesAmount() - 1;
        IKPITokensManager.Template memory _template = kpiTokensManager.template(
            _addedTemplateId
        );
        assertEq(_template.addrezz, _templateAddress);
        assertEq(_template.version.major, 1);
        assertEq(_template.version.minor, 0);
        assertEq(_template.version.patch, 0);
        assertEq(_template.specification, _specification);
        assertTrue(_template.exists);
    }
}

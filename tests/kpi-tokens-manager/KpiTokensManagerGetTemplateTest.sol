pragma solidity 0.8.14;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {IKPITokensManager} from "../../contracts/interfaces/IKPITokensManager.sol";
import {Clones} from "oz/proxy/Clones.sol";

/**
 * @title KpiTokensManagerGetTemplateTest
 * @dev KpiTokensManagerGetTemplateTest contract
 * @author Federico Luzzi - <federico.luzzi@protonmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract KpiTokensManagerGetTemplateTest is BaseTestSetup {
    function testNonExistentTemplate() external {
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("NonExistentTemplate()")
        );
        kpiTokensManager.template(2);
    }

    function testSuccess() external {
        uint256 _templateId = 0;
        IKPITokensManager.Template memory _template = kpiTokensManager.template(
            _templateId
        );
        assertEq(_template.id, _templateId);
        assertEq(_template.addrezz, address(erc20KpiTokenTemplate));
        assertEq(_template.version.major, 1);
        assertEq(_template.version.minor, 0);
        assertEq(_template.version.patch, 0);
        assertEq(_template.specification, ERC20_KPI_TOKEN_SPECIFICATION);
        assertTrue(_template.exists);
    }
}

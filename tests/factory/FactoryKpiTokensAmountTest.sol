pragma solidity 0.8.13;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {KPITokensFactory} from "../../contracts/KPITokensFactory.sol";
import {ERC20KPIToken} from "../../contracts/kpi-tokens/ERC20KPIToken.sol";
import {AaveERC20KPIToken} from "../../contracts/kpi-tokens/AaveERC20KPIToken.sol";
import {KPITokensManager} from "../../contracts/KPITokensManager.sol";
import {ManualRealityOracle} from "../../contracts/oracles/ManualRealityOracle.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";

/**
 * @title FactoryKpiTokensAmountTest
 * @dev FactoryKpiTokensAmountTest contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract FactoryKpiTokensAmountTest is BaseTestSetup {
    function testNoTemplates() external {
        factory = new KPITokensFactory(address(1), address(2), address(3));
        assertEq(factory.kpiTokensAmount(), 0);
    }

    function testOneTemplate() external {
        factory = new KPITokensFactory(address(1), address(1), address(this));
        kpiTokensManager = new KPITokensManager(address(factory));
        kpiTokensManager.addTemplate(
            address(erc20KpiTokenTemplate),
            ERC20_KPI_TOKEN_SPECIFICATION
        );
        kpiTokensManager.addTemplate(
            address(aaveErc20KpiTokenTemplate),
            AAVE_ERC20_KPI_TOKEN_SPECIFICATION
        );

        manualRealityOracleTemplate = new ManualRealityOracle();
        oraclesManager = new OraclesManager(
            address(factory),
            address(0) // jolt jobs registry
        );
        oraclesManager.addTemplate(
            address(manualRealityOracleTemplate),
            false,
            MANUAL_REALITY_ETH_SPECIFICATION
        );

        factory.setKpiTokensManager(address(kpiTokensManager));
        factory.setOraclesManager(address(oraclesManager));
        createKpiToken("asd", "dsa");
        assertEq(factory.kpiTokensAmount(), 1);
    }

    function testMultipleTemplates() external {
        createKpiToken("a", "b");
        createKpiToken("c", "d");
        assertEq(factory.kpiTokensAmount(), 2);
    }
}

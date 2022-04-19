pragma solidity 0.8.13;

import {DSTest} from "ds-test/test.sol";
import {ERC20KPIToken} from "../../contracts/kpi-tokens/ERC20KPIToken.sol";
import {AaveERC20KPIToken} from "../../contracts/kpi-tokens/AaveERC20KPIToken.sol";
import {KPITokensManager} from "../../contracts/KPITokensManager.sol";
import {ManualRealityOracle} from "../../contracts/oracles/ManualRealityOracle.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {KPITokensFactory} from "../../contracts/KPITokensFactory.sol";
import {CheatCodes} from "./CheatCodes.sol";

/**
 * @title BaseTestSetup
 * @dev BaseTestSetup contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
abstract contract BaseTestSetup is DSTest {
    CheatCodes internal immutable CHEAT_CODES =
        CheatCodes(address(HEVM_ADDRESS));

    string internal constant MANUAL_REALITY_ETH_SPECIFICATION =
        "QmRvoExBSESXedwqfC1cs4DGaRymnRR1wA9YGoZbqsE8Mf";

    KPITokensFactory internal factory;
    ERC20KPIToken internal erc20KpiTokenTemplate;
    AaveERC20KPIToken internal aaveErc20KpiTokenTemplate;
    KPITokensManager internal kpiTokensManager;
    ManualRealityOracle internal manualRealityOracleTemplate;
    OraclesManager internal oraclesManager;

    function setUp() external {
        factory = new KPITokensFactory(address(1), address(1), address(this));

        erc20KpiTokenTemplate = new ERC20KPIToken();
        aaveErc20KpiTokenTemplate = new AaveERC20KPIToken();
        kpiTokensManager = new KPITokensManager(address(factory));
        kpiTokensManager.addTemplate(
            address(erc20KpiTokenTemplate),
            "QmXU4G418hZLL8yxXdjkTFSoH2FdSe6ELgUuSm5fHHJMMN"
        );
        kpiTokensManager.addTemplate(
            address(aaveErc20KpiTokenTemplate),
            "QmPRwBVEPteH9qLKHdPGPPkNYuLzTv6fNACcLSHDUW3j8p"
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
    }
}

pragma solidity 0.8.13;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {KPITokensFactory} from "../../contracts/KPITokensFactory.sol";
import {IERC20KPIToken} from "../../contracts/interfaces/kpi-tokens/IERC20KPIToken.sol";
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

    function createKpiToken(string memory _description, string memory _question)
        internal
    {
        IERC20KPIToken.Collateral[]
            memory _collaterals = new IERC20KPIToken.Collateral[](1);
        _collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 2,
            minimumPayout: 1
        });
        bytes memory _erc20KpiTokenInitializationData = abi.encode(
            _collaterals,
            bytes32("Test"),
            bytes32("TST"),
            100 ether
        );

        address _reality = address(42);
        CHEAT_CODES.mockCall(
            _reality,
            abi.encodeWithSignature(
                "askQuestion(uint256,string,address,uint32,uint32,uint256)"
            ),
            abi.encode(bytes32("question id"))
        );
        bytes memory _manualRealityOracleInitializationData = abi.encode(
            _reality,
            address(this),
            1,
            _question,
            60,
            block.timestamp + 60
        );
        IERC20KPIToken.OracleData[]
            memory _oracleDatas = new IERC20KPIToken.OracleData[](1);
        _oracleDatas[0] = IERC20KPIToken.OracleData({
            id: 0,
            lowerBound: 0,
            higherBound: 1,
            weight: 1,
            data: _manualRealityOracleInitializationData
        });
        bytes memory _oraclesInitializationData = abi.encode(
            _oracleDatas,
            false
        );

        firstErc20.mint(address(this), 2);
        address _predictedKpiTokenAddress = kpiTokensManager
            .predictInstanceAddress(
                0,
                _description,
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 2);

        factory.createToken(
            0,
            _description,
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );
    }
}

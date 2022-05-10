pragma solidity 0.8.13;

import {DSTest} from "ds-test/test.sol";
import {ERC20KPIToken} from "../../contracts/kpi-tokens/ERC20KPIToken.sol";
import {AaveERC20KPIToken} from "../../contracts/kpi-tokens/AaveERC20KPIToken.sol";
import {KPITokensManager} from "../../contracts/KPITokensManager.sol";
import {ManualRealityOracle} from "../../contracts/oracles/ManualRealityOracle.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {KPITokensFactory} from "../../contracts/KPITokensFactory.sol";
import {CheatCodes} from "./CheatCodes.sol";
import {ERC20PresetMinterPauser} from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import {IERC20KPIToken} from "../../contracts/interfaces/kpi-tokens/IERC20KPIToken.sol";

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
    string internal constant ERC20_KPI_TOKEN_SPECIFICATION =
        "QmXU4G418hZLL8yxXdjkTFSoH2FdSe6ELgUuSm5fHHJMMN";
    string internal constant AAVE_ERC20_KPI_TOKEN_SPECIFICATION =
        "QmPRwBVEPteH9qLKHdPGPPkNYuLzTv6fNACcLSHDUW3j8p";

    ERC20PresetMinterPauser internal firstErc20;
    ERC20PresetMinterPauser internal secondErc20;
    address internal feeReceiver;
    KPITokensFactory internal factory;
    ERC20KPIToken internal erc20KpiTokenTemplate;
    AaveERC20KPIToken internal aaveErc20KpiTokenTemplate;
    KPITokensManager internal kpiTokensManager;
    ManualRealityOracle internal manualRealityOracleTemplate;
    OraclesManager internal oraclesManager;

    function setUp() external {
        firstErc20 = new ERC20PresetMinterPauser("Token 1", "TKN1");
        secondErc20 = new ERC20PresetMinterPauser("Token 2", "TKN2");

        feeReceiver = address(400);
        factory = new KPITokensFactory(address(1), address(1), feeReceiver);

        erc20KpiTokenTemplate = new ERC20KPIToken();
        aaveErc20KpiTokenTemplate = new AaveERC20KPIToken();
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
    }

    function createKpiToken(string memory _description, string memory _question)
        internal
        returns (ERC20KPIToken)
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
            "Test",
            "TST",
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
            templateId: 0,
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

        uint256 kpiTokensAmount = factory.kpiTokensAmount();
        return
            ERC20KPIToken(
                factory.enumerate(
                    kpiTokensAmount > 0 ? kpiTokensAmount - 1 : kpiTokensAmount,
                    kpiTokensAmount > 0 ? kpiTokensAmount : 1
                )[0]
            );
    }
}

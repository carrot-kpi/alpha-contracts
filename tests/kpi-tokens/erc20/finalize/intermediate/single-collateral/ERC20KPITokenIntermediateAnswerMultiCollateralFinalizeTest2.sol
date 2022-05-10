pragma solidity 0.8.13;

import {BaseTestSetup} from "../../../../../commons/BaseTestSetup.sol";
import {ERC20KPIToken} from "../../../../../../contracts/kpi-tokens/ERC20KPIToken.sol";
import {IERC20KPIToken} from "../../../../../../contracts/interfaces/kpi-tokens/IERC20KPIToken.sol";

/**
 * @title ERC20KPITokenIntermediateAnswerMultiCollateralFinalizeTest2
 * @dev ERC20KPITokenIntermediateAnswerMultiCollateralFinalizeTest2 contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract ERC20KPITokenIntermediateAnswerMultiCollateralFinalizeTest2 is
    BaseTestSetup
{
    function testIntermediateBoundAndRelationshipMultipleOraclesZeroMinimumPayoutMultiCollateral()
        external
    {
        IERC20KPIToken.Collateral[]
            memory _collaterals = new IERC20KPIToken.Collateral[](2);
        _collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 2 ether,
            minimumPayout: 0
        });
        _collaterals[1] = IERC20KPIToken.Collateral({
            token: address(secondErc20),
            amount: 4 ether,
            minimumPayout: 0
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
        bytes memory _firstManualRealityOracleInitializationData = abi.encode(
            _reality,
            address(this),
            1,
            "a",
            60,
            block.timestamp + 60
        );
        bytes memory _secondManualRealityOracleInitializationData = abi.encode(
            _reality,
            address(this),
            1,
            "b",
            60,
            block.timestamp + 60
        );
        IERC20KPIToken.OracleData[]
            memory _oracleDatas = new IERC20KPIToken.OracleData[](2);
        _oracleDatas[0] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 10 ether,
            higherBound: 14 ether,
            weight: 1,
            data: _firstManualRealityOracleInitializationData
        });
        _oracleDatas[1] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 20 ether,
            higherBound: 26 ether,
            weight: 1,
            data: _secondManualRealityOracleInitializationData
        });
        bytes memory _oraclesInitializationData = abi.encode(
            _oracleDatas,
            true
        );

        firstErc20.mint(address(this), 2 ether);
        secondErc20.mint(address(this), 4 ether);
        address _predictedKpiTokenAddress = kpiTokensManager
            .predictInstanceAddress(
                0,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 2 ether);
        secondErc20.approve(_predictedKpiTokenAddress, 4 ether);

        factory.createToken(
            0,
            "a",
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        uint256 kpiTokensAmount = factory.kpiTokensAmount();
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            factory.enumerate(
                kpiTokensAmount > 0 ? kpiTokensAmount - 1 : kpiTokensAmount,
                kpiTokensAmount > 0 ? kpiTokensAmount : 1
            )[0]
        );

        address oracle = kpiTokenInstance.oracles()[0];
        CHEAT_CODES.prank(oracle);
        kpiTokenInstance.finalize(13 ether);

        (
            IERC20KPIToken.Collateral[] memory onChainCollaterals,
            IERC20KPIToken.FinalizableOracle[] memory onChainFinalizableOracles,
            ,
            ,
            ,

        ) = abi.decode(
                kpiTokenInstance.data(),
                (
                    IERC20KPIToken.Collateral[],
                    IERC20KPIToken.FinalizableOracle[],
                    bool,
                    uint256,
                    string,
                    string
                )
            );

        assertEq(onChainCollaterals.length, 2);
        assertEq(onChainCollaterals[0].token, _collaterals[0].token);
        assertEq(onChainCollaterals[0].amount, 1.74475 ether);
        assertEq(onChainCollaterals[0].minimumPayout, 0);
        assertEq(onChainCollaterals[1].token, _collaterals[1].token);
        assertEq(onChainCollaterals[1].amount, 3.4895 ether);
        assertEq(onChainCollaterals[1].minimumPayout, 0);

        assertEq(onChainFinalizableOracles.length, 2);
        assertTrue(onChainFinalizableOracles[0].finalized);
        assertTrue(!onChainFinalizableOracles[1].finalized);

        assertTrue(!kpiTokenInstance.finalized());
        assertEq(firstErc20.balanceOf(address(this)), 0.24925 ether);
        assertEq(secondErc20.balanceOf(address(this)), 0.4985 ether);
    }

    function testIntermediateBoundAndRelationshipMultipleOraclesNonZeroMinimumPayoutMultiCollateral()
        external
    {
        IERC20KPIToken.Collateral[]
            memory _collaterals = new IERC20KPIToken.Collateral[](2);
        _collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 2 ether,
            minimumPayout: 1 ether
        });
        _collaterals[1] = IERC20KPIToken.Collateral({
            token: address(secondErc20),
            amount: 26 ether,
            minimumPayout: 10 ether
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
        bytes memory _firstManualRealityOracleInitializationData = abi.encode(
            _reality,
            address(this),
            1,
            "a",
            60,
            block.timestamp + 60
        );
        bytes memory _secondManualRealityOracleInitializationData = abi.encode(
            _reality,
            address(this),
            1,
            "b",
            60,
            block.timestamp + 60
        );
        IERC20KPIToken.OracleData[]
            memory _oracleDatas = new IERC20KPIToken.OracleData[](2);
        _oracleDatas[0] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 10 ether,
            higherBound: 43 ether,
            weight: 1,
            data: _firstManualRealityOracleInitializationData
        });
        _oracleDatas[1] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 200 ether,
            higherBound: 2607 ether,
            weight: 2,
            data: _secondManualRealityOracleInitializationData
        });
        bytes memory _oraclesInitializationData = abi.encode(
            _oracleDatas,
            true
        );

        firstErc20.mint(address(this), 2 ether);
        secondErc20.mint(address(this), 26 ether);
        address _predictedKpiTokenAddress = kpiTokensManager
            .predictInstanceAddress(
                0,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 2 ether);
        secondErc20.approve(_predictedKpiTokenAddress, 26 ether);

        factory.createToken(
            0,
            "a",
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        uint256 kpiTokensAmount = factory.kpiTokensAmount();
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            factory.enumerate(
                kpiTokensAmount > 0 ? kpiTokensAmount - 1 : kpiTokensAmount,
                kpiTokensAmount > 0 ? kpiTokensAmount : 1
            )[0]
        );

        address oracle = kpiTokenInstance.oracles()[0];
        CHEAT_CODES.prank(oracle);
        kpiTokenInstance.finalize(33 ether);

        (
            IERC20KPIToken.Collateral[] memory onChainCollaterals,
            IERC20KPIToken.FinalizableOracle[] memory onChainFinalizableOracles,
            ,
            ,
            ,

        ) = abi.decode(
                kpiTokenInstance.data(),
                (
                    IERC20KPIToken.Collateral[],
                    IERC20KPIToken.FinalizableOracle[],
                    bool,
                    uint256,
                    string,
                    string
                )
            );

        assertEq(onChainCollaterals.length, 2);
        assertEq(onChainCollaterals[0].token, _collaterals[0].token);
        assertEq(onChainCollaterals[0].amount, 1.893595959595959596 ether);
        assertEq(onChainCollaterals[0].minimumPayout, 1 ether);
        assertEq(onChainCollaterals[1].token, _collaterals[1].token);
        assertEq(onChainCollaterals[1].amount, 24.313717171717171718 ether);
        assertEq(onChainCollaterals[1].minimumPayout, 10 ether);

        assertEq(onChainFinalizableOracles.length, 2);
        assertTrue(onChainFinalizableOracles[0].finalized);
        assertTrue(!onChainFinalizableOracles[1].finalized);

        assertTrue(!kpiTokenInstance.finalized());
        assertEq(
            firstErc20.balanceOf(address(this)),
            0.100404040404040404 ether
        );
        assertEq(
            secondErc20.balanceOf(address(this)),
            1.608282828282828282 ether
        );
    }
}

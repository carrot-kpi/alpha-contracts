pragma solidity 0.8.13;

import {BaseTestSetup} from "../../../../../commons/BaseTestSetup.sol";
import {ERC20KPIToken} from "../../../../../../contracts/kpi-tokens/ERC20KPIToken.sol";
import {IERC20KPIToken} from "../../../../../../contracts/interfaces/kpi-tokens/IERC20KPIToken.sol";

/**
 * @title ERC20KPITokenIntermediateAnswerSingleCollateralFinalizeTest
 * @dev ERC20KPITokenIntermediateAnswerSingleCollateralFinalizeTest contract
 * @author Federico Luzzi - <federico.luzzi@protonmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract ERC20KPITokenIntermediateAnswerSingleCollateralFinalizeTest is
    BaseTestSetup
{
    function testIntermediateBoundAndRelationshipSingleOracleZeroMinimumPayout()
        external
    {
        IERC20KPIToken.Collateral[]
            memory _collaterals = new IERC20KPIToken.Collateral[](1);
        _collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 2,
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
        bytes memory _manualRealityOracleInitializationData = abi.encode(
            _reality,
            address(this),
            1,
            "b",
            60,
            block.timestamp + 60
        );
        IERC20KPIToken.OracleData[]
            memory _oracleDatas = new IERC20KPIToken.OracleData[](1);
        _oracleDatas[0] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 10,
            higherBound: 12,
            weight: 1,
            data: _manualRealityOracleInitializationData
        });
        bytes memory _oraclesInitializationData = abi.encode(
            _oracleDatas,
            true
        );

        firstErc20.mint(address(this), 2);
        address _predictedKpiTokenAddress = kpiTokensManager
            .predictInstanceAddress(
                0,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 2);

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
        kpiTokenInstance.finalize(11);

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

        assertEq(onChainCollaterals.length, 1);
        assertEq(onChainCollaterals[0].token, _collaterals[0].token);
        assertEq(onChainCollaterals[0].amount, 1);
        assertEq(onChainCollaterals[0].minimumPayout, 0);

        assertEq(onChainFinalizableOracles.length, 1);
        assertTrue(onChainFinalizableOracles[0].finalized);

        assertTrue(kpiTokenInstance.finalized());
        assertEq(firstErc20.balanceOf(address(this)), 1);
    }

    function testIntermediateBoundAndRelationshipSingleOracleNonZeroMinimumPayout()
        external
    {
        IERC20KPIToken.Collateral[]
            memory _collaterals = new IERC20KPIToken.Collateral[](1);
        _collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 10 ether,
            minimumPayout: 1 ether
        });
        bytes memory _erc20KpiTokenInitializationData = abi.encode(
            _collaterals,
            "Test",
            "TST",
            10 ether
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
            "b",
            60,
            block.timestamp + 60
        );
        IERC20KPIToken.OracleData[]
            memory _oracleDatas = new IERC20KPIToken.OracleData[](1);
        _oracleDatas[0] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 10 ether,
            higherBound: 20 ether,
            weight: 1,
            data: _manualRealityOracleInitializationData
        });
        bytes memory _oraclesInitializationData = abi.encode(
            _oracleDatas,
            true
        );

        firstErc20.mint(address(this), 10 ether);
        address _predictedKpiTokenAddress = kpiTokensManager
            .predictInstanceAddress(
                0,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 10 ether);

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
        kpiTokenInstance.finalize(12 ether);

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

        assertEq(onChainCollaterals.length, 1);
        assertEq(onChainCollaterals[0].token, _collaterals[0].token);
        assertEq(onChainCollaterals[0].amount, 2.794 ether); // take into account the minimum payout
        assertEq(onChainCollaterals[0].minimumPayout, 1 ether);

        assertEq(onChainFinalizableOracles.length, 1);
        assertTrue(onChainFinalizableOracles[0].finalized);

        assertTrue(kpiTokenInstance.finalized());
        assertEq(firstErc20.balanceOf(address(this)), 7.176 ether);
    }

    function testIntermediateBoundOrRelationshipSingleOracleZeroMinimumPayout()
        external
    {
        IERC20KPIToken.Collateral[]
            memory _collaterals = new IERC20KPIToken.Collateral[](1);
        _collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 2 ether,
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
        bytes memory _manualRealityOracleInitializationData = abi.encode(
            _reality,
            address(this),
            1,
            "b",
            60,
            block.timestamp + 60
        );
        IERC20KPIToken.OracleData[]
            memory _oracleDatas = new IERC20KPIToken.OracleData[](1);
        _oracleDatas[0] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 40 ether,
            higherBound: 50 ether,
            weight: 1,
            data: _manualRealityOracleInitializationData
        });
        bytes memory _oraclesInitializationData = abi.encode(
            _oracleDatas,
            false
        );

        firstErc20.mint(address(this), 2 ether);
        address _predictedKpiTokenAddress = kpiTokensManager
            .predictInstanceAddress(
                0,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 2 ether);

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
        kpiTokenInstance.finalize(45 ether);

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

        assertEq(firstErc20.balanceOf(address(this)), 0.997 ether);
        assertTrue(kpiTokenInstance.finalized());

        assertEq(onChainCollaterals.length, 1);
        assertEq(onChainCollaterals[0].token, _collaterals[0].token);
        assertEq(onChainCollaterals[0].amount, 0.997 ether);
        assertEq(onChainCollaterals[0].minimumPayout, 0);

        assertEq(onChainFinalizableOracles.length, 1);
        assertTrue(onChainFinalizableOracles[0].finalized);
    }

    function testIntermediateBoundOrRelationshipSingleOracleNonZeroMinimumPayout()
        external
    {
        IERC20KPIToken.Collateral[]
            memory _collaterals = new IERC20KPIToken.Collateral[](1);
        _collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 45 ether,
            minimumPayout: 22 ether
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
            "b",
            60,
            block.timestamp + 60
        );
        IERC20KPIToken.OracleData[]
            memory _oracleDatas = new IERC20KPIToken.OracleData[](1);
        _oracleDatas[0] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 102 ether,
            higherBound: 286 ether,
            weight: 1,
            data: _manualRealityOracleInitializationData
        });
        bytes memory _oraclesInitializationData = abi.encode(
            _oracleDatas,
            false
        );

        firstErc20.mint(address(this), 45 ether);
        address _predictedKpiTokenAddress = kpiTokensManager
            .predictInstanceAddress(
                0,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 45 ether);

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
        kpiTokenInstance.finalize(153 ether);

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

        assertEq(onChainCollaterals.length, 1);
        assertEq(onChainCollaterals[0].token, _collaterals[0].token);
        assertEq(onChainCollaterals[0].amount, 28.337581521739130435 ether);
        assertEq(onChainCollaterals[0].minimumPayout, 22 ether);

        assertEq(onChainFinalizableOracles.length, 1);
        assertTrue(onChainFinalizableOracles[0].finalized);

        assertTrue(kpiTokenInstance.finalized());
        assertEq(
            firstErc20.balanceOf(address(this)),
            16.527418478260869565 ether
        );
    }

    function testIntermediateBoundAndRelationshipMultipleOraclesZeroMinimumPayout()
        external
    {
        IERC20KPIToken.Collateral[]
            memory _collaterals = new IERC20KPIToken.Collateral[](1);
        _collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 2 ether,
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
        address _predictedKpiTokenAddress = kpiTokensManager
            .predictInstanceAddress(
                0,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 2 ether);

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

        assertEq(onChainCollaterals.length, 1);
        assertEq(onChainCollaterals[0].token, _collaterals[0].token);
        assertEq(onChainCollaterals[0].amount, 1.74475 ether);
        assertEq(onChainCollaterals[0].minimumPayout, 0);

        assertEq(onChainFinalizableOracles.length, 2);
        assertTrue(onChainFinalizableOracles[0].finalized);
        assertTrue(!onChainFinalizableOracles[1].finalized);

        assertTrue(!kpiTokenInstance.finalized());
        assertEq(firstErc20.balanceOf(address(this)), 0.24925 ether);
    }

    function testIntermediateBoundAndRelationshipMultipleOraclesNonZeroMinimumPayout()
        external
    {
        IERC20KPIToken.Collateral[]
            memory _collaterals = new IERC20KPIToken.Collateral[](1);
        _collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 2 ether,
            minimumPayout: 1 ether
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
        address _predictedKpiTokenAddress = kpiTokensManager
            .predictInstanceAddress(
                0,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 2 ether);

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

        assertEq(onChainCollaterals.length, 1);
        assertEq(onChainCollaterals[0].token, _collaterals[0].token);
        assertEq(onChainCollaterals[0].amount, 1.893595959595959596 ether);
        assertEq(onChainCollaterals[0].minimumPayout, 1 ether);

        assertEq(onChainFinalizableOracles.length, 2);
        assertTrue(onChainFinalizableOracles[0].finalized);
        assertTrue(!onChainFinalizableOracles[1].finalized);

        assertTrue(!kpiTokenInstance.finalized());
        assertEq(
            firstErc20.balanceOf(address(this)),
            0.100404040404040404 ether
        );
    }
}

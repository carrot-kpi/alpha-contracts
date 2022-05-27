pragma solidity 0.8.14;

import {BaseTestSetup} from "../../../commons/BaseTestSetup.sol";
import {ERC20KPIToken} from "../../../../contracts/kpi-tokens/ERC20KPIToken.sol";
import {IERC20KPIToken} from "../../../../contracts/interfaces/kpi-tokens/IERC20KPIToken.sol";

/**
 * @title ERC20KPITokenAboveHigherBoundRecoverTest
 * @dev ERC20KPITokenAboveHigherBoundRecoverTest contract
 * @author Federico Luzzi - <federico.luzzi@protonmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract ERC20KPITokenAboveHigherBoundRecoverTest is BaseTestSetup {
    function testOverHigherBoundAndRelationshipSingleOracle() external {
        IERC20KPIToken.Collateral[]
            memory _collaterals = new IERC20KPIToken.Collateral[](1);
        _collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 20 ether,
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
        bytes memory _manualRealityOracleInitializationData = abi.encode(
            _reality,
            address(this),
            1,
            "a",
            60,
            block.timestamp + 60
        );
        IERC20KPIToken.OracleData[]
            memory _oracleDatas = new IERC20KPIToken.OracleData[](1);
        _oracleDatas[0] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 10 ether,
            higherBound: 43 ether,
            weight: 1,
            data: _manualRealityOracleInitializationData
        });
        bytes memory _oraclesInitializationData = abi.encode(
            _oracleDatas,
            true
        );

        firstErc20.mint(address(this), 20 ether);
        address _predictedKpiTokenAddress = kpiTokensManager
            .predictInstanceAddress(
                0,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 20 ether);

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
        kpiTokenInstance.finalize(10023 ether);

        kpiTokenInstance.recoverERC20(address(firstErc20), address(this));

        assertEq(firstErc20.balanceOf(address(this)), 0 ether);
    }

    function testOverHigherBoundAndRelationshipMultipleOracle() external {
        IERC20KPIToken.Collateral[]
            memory _collaterals = new IERC20KPIToken.Collateral[](1);
        _collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 20 ether,
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
            lowerBound: 12 ether,
            higherBound: 72 ether,
            weight: 1,
            data: _firstManualRealityOracleInitializationData
        });
        _oracleDatas[1] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 102 ether,
            higherBound: 430 ether,
            weight: 1,
            data: _secondManualRealityOracleInitializationData
        });
        bytes memory _oraclesInitializationData = abi.encode(
            _oracleDatas,
            true
        );

        firstErc20.mint(address(this), 20 ether);
        address _predictedKpiTokenAddress = kpiTokensManager
            .predictInstanceAddress(
                0,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 20 ether);

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
        kpiTokenInstance.finalize(97 ether);

        kpiTokenInstance.recoverERC20(address(firstErc20), address(this));

        assertEq(firstErc20.balanceOf(address(this)), 0 ether);
    }

    function testOverHigherBoundOrRelationshipSingleOracle() external {
        IERC20KPIToken.Collateral[]
            memory _collaterals = new IERC20KPIToken.Collateral[](1);
        _collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 20 ether,
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
        bytes memory _manualRealityOracleInitializationData = abi.encode(
            _reality,
            address(this),
            1,
            "a",
            60,
            block.timestamp + 60
        );
        IERC20KPIToken.OracleData[]
            memory _oracleDatas = new IERC20KPIToken.OracleData[](1);
        _oracleDatas[0] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 10 ether,
            higherBound: 43 ether,
            weight: 1,
            data: _manualRealityOracleInitializationData
        });
        bytes memory _oraclesInitializationData = abi.encode(
            _oracleDatas,
            false
        );

        firstErc20.mint(address(this), 20 ether);
        address _predictedKpiTokenAddress = kpiTokensManager
            .predictInstanceAddress(
                0,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 20 ether);

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
        kpiTokenInstance.finalize(10023 ether);

        kpiTokenInstance.recoverERC20(address(firstErc20), address(this));

        assertEq(firstErc20.balanceOf(address(this)), 0 ether);
    }

    function testOverHigherBoundOrRelationshipMultipleOracle() external {
        IERC20KPIToken.Collateral[]
            memory _collaterals = new IERC20KPIToken.Collateral[](1);
        _collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 20 ether,
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
            lowerBound: 12 ether,
            higherBound: 72 ether,
            weight: 1,
            data: _firstManualRealityOracleInitializationData
        });
        _oracleDatas[1] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 102 ether,
            higherBound: 430 ether,
            weight: 1,
            data: _secondManualRealityOracleInitializationData
        });
        bytes memory _oraclesInitializationData = abi.encode(
            _oracleDatas,
            false
        );

        firstErc20.mint(address(this), 20 ether);
        address _predictedKpiTokenAddress = kpiTokensManager
            .predictInstanceAddress(
                0,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 20 ether);

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
        kpiTokenInstance.finalize(97 ether);

        kpiTokenInstance.recoverERC20(address(firstErc20), address(this));

        assertEq(firstErc20.balanceOf(address(this)), 0 ether);
    }

    function testOverHigherBoundAndRelationshipSingleOracleMultiCollateral()
        external
    {
        IERC20KPIToken.Collateral[]
            memory _collaterals = new IERC20KPIToken.Collateral[](2);
        _collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 20 ether,
            minimumPayout: 10 ether
        });
        _collaterals[1] = IERC20KPIToken.Collateral({
            token: address(secondErc20),
            amount: 35 ether,
            minimumPayout: 12.2 ether
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
            "a",
            60,
            block.timestamp + 60
        );
        IERC20KPIToken.OracleData[]
            memory _oracleDatas = new IERC20KPIToken.OracleData[](1);
        _oracleDatas[0] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 10 ether,
            higherBound: 43 ether,
            weight: 1,
            data: _manualRealityOracleInitializationData
        });
        bytes memory _oraclesInitializationData = abi.encode(
            _oracleDatas,
            true
        );

        firstErc20.mint(address(this), 20 ether);
        secondErc20.mint(address(this), 35 ether);
        address _predictedKpiTokenAddress = kpiTokensManager
            .predictInstanceAddress(
                0,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 20 ether);
        secondErc20.approve(_predictedKpiTokenAddress, 35 ether);

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
        kpiTokenInstance.finalize(10023 ether);

        kpiTokenInstance.recoverERC20(address(firstErc20), address(this));
        kpiTokenInstance.recoverERC20(address(secondErc20), address(this));

        assertEq(firstErc20.balanceOf(address(this)), 0);
        assertEq(secondErc20.balanceOf(address(this)), 0);
    }

    function testOverHigherBoundAndRelationshipMultipleOracleMultiCollateral()
        external
    {
        IERC20KPIToken.Collateral[]
            memory _collaterals = new IERC20KPIToken.Collateral[](2);
        _collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 20 ether,
            minimumPayout: 10 ether
        });
        _collaterals[1] = IERC20KPIToken.Collateral({
            token: address(secondErc20),
            amount: 20.23 ether,
            minimumPayout: 18.9 ether
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
            lowerBound: 12 ether,
            higherBound: 72 ether,
            weight: 1,
            data: _firstManualRealityOracleInitializationData
        });
        _oracleDatas[1] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 102 ether,
            higherBound: 430 ether,
            weight: 1,
            data: _secondManualRealityOracleInitializationData
        });
        bytes memory _oraclesInitializationData = abi.encode(
            _oracleDatas,
            true
        );

        firstErc20.mint(address(this), 20 ether);
        secondErc20.mint(address(this), 20.23 ether);
        address _predictedKpiTokenAddress = kpiTokensManager
            .predictInstanceAddress(
                0,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 20 ether);
        secondErc20.approve(_predictedKpiTokenAddress, 20.23 ether);

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
        kpiTokenInstance.finalize(97 ether);

        kpiTokenInstance.recoverERC20(address(firstErc20), address(this));
        kpiTokenInstance.recoverERC20(address(secondErc20), address(this));

        assertEq(firstErc20.balanceOf(address(this)), 0);
        assertEq(secondErc20.balanceOf(address(this)), 0);
    }

    function testOverHigherBoundOrRelationshipSingleOracleMultiCollateral()
        external
    {
        IERC20KPIToken.Collateral[]
            memory _collaterals = new IERC20KPIToken.Collateral[](2);
        _collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 20 ether,
            minimumPayout: 10 ether
        });
        _collaterals[1] = IERC20KPIToken.Collateral({
            token: address(secondErc20),
            amount: 29 ether,
            minimumPayout: 28 ether
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
            "a",
            60,
            block.timestamp + 60
        );
        IERC20KPIToken.OracleData[]
            memory _oracleDatas = new IERC20KPIToken.OracleData[](1);
        _oracleDatas[0] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 10 ether,
            higherBound: 43 ether,
            weight: 1,
            data: _manualRealityOracleInitializationData
        });
        bytes memory _oraclesInitializationData = abi.encode(
            _oracleDatas,
            false
        );

        firstErc20.mint(address(this), 20 ether);
        secondErc20.mint(address(this), 29 ether);
        address _predictedKpiTokenAddress = kpiTokensManager
            .predictInstanceAddress(
                0,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 20 ether);
        secondErc20.approve(_predictedKpiTokenAddress, 29 ether);

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
        kpiTokenInstance.finalize(10023 ether);

        kpiTokenInstance.recoverERC20(address(firstErc20), address(this));
        kpiTokenInstance.recoverERC20(address(secondErc20), address(this));

        assertEq(firstErc20.balanceOf(address(this)), 0);
        assertEq(secondErc20.balanceOf(address(this)), 0);
    }

    function testOverHigherBoundOrRelationshipMultipleOracleMultiCollateral()
        external
    {
        IERC20KPIToken.Collateral[]
            memory _collaterals = new IERC20KPIToken.Collateral[](2);
        _collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 20 ether,
            minimumPayout: 10 ether
        });
        _collaterals[1] = IERC20KPIToken.Collateral({
            token: address(secondErc20),
            amount: 12.65 ether,
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
            lowerBound: 12 ether,
            higherBound: 72 ether,
            weight: 1,
            data: _firstManualRealityOracleInitializationData
        });
        _oracleDatas[1] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 102 ether,
            higherBound: 430 ether,
            weight: 1,
            data: _secondManualRealityOracleInitializationData
        });
        bytes memory _oraclesInitializationData = abi.encode(
            _oracleDatas,
            false
        );

        firstErc20.mint(address(this), 20 ether);
        secondErc20.mint(address(this), 12.65 ether);
        address _predictedKpiTokenAddress = kpiTokensManager
            .predictInstanceAddress(
                0,
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 20 ether);
        secondErc20.approve(_predictedKpiTokenAddress, 12.65 ether);

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
        kpiTokenInstance.finalize(97 ether);

        kpiTokenInstance.recoverERC20(address(firstErc20), address(this));
        kpiTokenInstance.recoverERC20(address(secondErc20), address(this));

        assertEq(firstErc20.balanceOf(address(this)), 0);
        assertEq(secondErc20.balanceOf(address(this)), 0);
    }
}

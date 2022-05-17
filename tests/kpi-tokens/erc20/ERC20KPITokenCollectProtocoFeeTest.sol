pragma solidity 0.8.13;

import {BaseTestSetup} from "../../commons/BaseTestSetup.sol";
import {ERC20KPIToken} from "../../../contracts/kpi-tokens/ERC20KPIToken.sol";
import {IOraclesManager} from "../../../contracts/interfaces/IOraclesManager.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IERC20KPIToken} from "../../../contracts/interfaces/kpi-tokens/IERC20KPIToken.sol";

/**
 * @title ERC20KPITokenCollectProtocoFeeTest
 * @dev ERC20KPITokenCollectProtocoFeeTest contract
 * @author Federico Luzzi - <federico.luzzi@protonmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract ERC20KPITokenCollectProtocoFeeTest is BaseTestSetup {
    function initializeKpiToken() internal returns (ERC20KPIToken) {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        firstErc20.mint(address(this), 10 ether);
        firstErc20.approve(address(kpiTokenInstance), 10 ether);

        IERC20KPIToken.Collateral[]
            memory collaterals = new IERC20KPIToken.Collateral[](1);
        collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 10 ether,
            minimumPayout: 1 ether
        });

        kpiTokenInstance.initialize(
            address(this),
            address(kpiTokensManager),
            10,
            "a",
            abi.encode(collaterals, "Token", "TKN", 100 ether)
        );

        IERC20KPIToken.OracleData[]
            memory oracleData = new IERC20KPIToken.OracleData[](2);
        bytes memory firstManualRealityEthInitializationData = abi.encode(
            address(2), // fake reality.eth address
            address(this), // arbitrator
            0, // template id
            "a", // question
            200, // question timeout
            block.timestamp + 200 // expiry
        );
        bytes memory secondManualRealityEthInitializationData = abi.encode(
            address(2), // fake reality.eth address
            address(this), // arbitrator
            0, // template id
            "b", // question
            300, // question timeout
            block.timestamp + 300 // expiry
        );
        oracleData[0] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 0,
            higherBound: 1,
            weight: 1,
            data: firstManualRealityEthInitializationData
        });
        oracleData[1] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 5 ether,
            higherBound: 10 ether,
            weight: 3,
            data: secondManualRealityEthInitializationData
        });
        address oraclesManager = address(2);
        CHEAT_CODES.mockCall(
            oraclesManager,
            abi.encodeWithSignature("instantiate(address,uint256,bytes)"),
            abi.encode(address(2))
        );
        kpiTokenInstance.initializeOracles(
            oraclesManager,
            abi.encode(oracleData, false)
        );

        return kpiTokenInstance;
    }

    function testNotInitialized() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );
        CHEAT_CODES.expectRevert(abi.encodeWithSignature("NotInitialized()"));
        kpiTokenInstance.collectProtocolFees(address(0));
    }

    function testMultipleCollection() external {
        ERC20KPIToken kpiTokenInstance = initializeKpiToken();

        address feeReceiver = address(42);
        kpiTokenInstance.collectProtocolFees(feeReceiver);

        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("AlreadyInitialized()")
        );
        kpiTokenInstance.collectProtocolFees(feeReceiver);
    }

    function testExcessiveCollection() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        firstErc20.mint(address(this), 10 ether);
        firstErc20.approve(address(kpiTokenInstance), 10 ether);

        IERC20KPIToken.Collateral[]
            memory collaterals = new IERC20KPIToken.Collateral[](1);
        collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 10 ether,
            minimumPayout: 9.9999999999 ether
        });

        kpiTokenInstance.initialize(
            address(this),
            address(kpiTokensManager),
            10,
            "a",
            abi.encode(collaterals, "Token", "TKN", 100 ether)
        );

        IERC20KPIToken.OracleData[]
            memory oracleData = new IERC20KPIToken.OracleData[](2);
        bytes memory firstManualRealityEthInitializationData = abi.encode(
            address(2), // fake reality.eth address
            address(this), // arbitrator
            0, // template id
            "a", // question
            200, // question timeout
            block.timestamp + 200 // expiry
        );
        bytes memory secondManualRealityEthInitializationData = abi.encode(
            address(2), // fake reality.eth address
            address(this), // arbitrator
            0, // template id
            "b", // question
            300, // question timeout
            block.timestamp + 300 // expiry
        );
        oracleData[0] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 0,
            higherBound: 1,
            weight: 1,
            data: firstManualRealityEthInitializationData
        });
        oracleData[1] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 5 ether,
            higherBound: 10 ether,
            weight: 3,
            data: secondManualRealityEthInitializationData
        });
        address oraclesManager = address(2);
        CHEAT_CODES.mockCall(
            oraclesManager,
            abi.encodeWithSignature("instantiate(address,uint256,bytes)"),
            abi.encode(address(2))
        );
        kpiTokenInstance.initializeOracles(
            oraclesManager,
            abi.encode(oracleData, false)
        );

        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("InvalidMinimumPayoutAfterFee()")
        );
        kpiTokenInstance.collectProtocolFees(address(42));
    }

    function testSuccessSingleCollateral() external {
        ERC20KPIToken kpiTokenInstance = initializeKpiToken();

        address feeReceiver = address(42);
        kpiTokenInstance.collectProtocolFees(feeReceiver);

        (IERC20KPIToken.Collateral[] memory onChainCollaterals, , , , , ) = abi
            .decode(
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

        IERC20KPIToken.Collateral memory onChainCollateral = onChainCollaterals[
            0
        ];

        assertEq(onChainCollateral.token, address(firstErc20));
        assertEq(onChainCollateral.amount, 9.97 ether);
        assertEq(onChainCollateral.minimumPayout, 1 ether);

        CHEAT_CODES.clearMockedCalls();
    }

    function testSuccessMultipleCollateral() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        firstErc20.mint(address(this), 10 ether);
        firstErc20.approve(address(kpiTokenInstance), 10 ether);

        secondErc20.mint(address(this), 3 ether);
        secondErc20.approve(address(kpiTokenInstance), 3 ether);

        IERC20KPIToken.Collateral[]
            memory collaterals = new IERC20KPIToken.Collateral[](2);
        collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 10 ether,
            minimumPayout: 1 ether
        });
        collaterals[1] = IERC20KPIToken.Collateral({
            token: address(secondErc20),
            amount: 3 ether,
            minimumPayout: 2 ether
        });

        kpiTokenInstance.initialize(
            address(this),
            address(kpiTokensManager),
            10,
            "a",
            abi.encode(collaterals, "Token", "TKN", 100 ether)
        );

        IERC20KPIToken.OracleData[]
            memory oracleData = new IERC20KPIToken.OracleData[](2);
        bytes memory firstManualRealityEthInitializationData = abi.encode(
            address(2), // fake reality.eth address
            address(this), // arbitrator
            0, // template id
            "a", // question
            200, // question timeout
            block.timestamp + 200 // expiry
        );
        bytes memory secondManualRealityEthInitializationData = abi.encode(
            address(2), // fake reality.eth address
            address(this), // arbitrator
            0, // template id
            "b", // question
            300, // question timeout
            block.timestamp + 300 // expiry
        );
        oracleData[0] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 0,
            higherBound: 1,
            weight: 1,
            data: firstManualRealityEthInitializationData
        });
        oracleData[1] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 5 ether,
            higherBound: 10 ether,
            weight: 3,
            data: secondManualRealityEthInitializationData
        });
        address oraclesManager = address(2);
        CHEAT_CODES.mockCall(
            oraclesManager,
            abi.encodeWithSignature("instantiate(address,uint256,bytes)"),
            abi.encode(address(2))
        );
        kpiTokenInstance.initializeOracles(
            oraclesManager,
            abi.encode(oracleData, false)
        );

        address feeReceiver = address(42);
        kpiTokenInstance.collectProtocolFees(feeReceiver);

        (IERC20KPIToken.Collateral[] memory onChainCollaterals, , , , , ) = abi
            .decode(
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

        assertEq(onChainCollaterals[0].token, address(firstErc20));
        assertEq(onChainCollaterals[0].amount, 9.97 ether);
        assertEq(onChainCollaterals[0].minimumPayout, 1 ether);

        assertEq(onChainCollaterals[1].token, address(secondErc20));
        assertEq(onChainCollaterals[1].amount, 2.991 ether);
        assertEq(onChainCollaterals[1].minimumPayout, 2 ether);

        CHEAT_CODES.clearMockedCalls();
    }
}

pragma solidity 0.8.13;

import {BaseTestSetup} from "../../commons/BaseTestSetup.sol";
import {ERC20KPIToken} from "../../../contracts/kpi-tokens/ERC20KPIToken.sol";
import {IOraclesManager} from "../../../contracts/interfaces/IOraclesManager.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IERC20KPIToken} from "../../../contracts/interfaces/kpi-tokens/IERC20KPIToken.sol";

/**
 * @title ERC20KPITokenInitializeOraclesTest
 * @dev ERC20KPITokenInitializeOraclesTest contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract ERC20KPITokenInitializeOraclesTest is BaseTestSetup {
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

        return kpiTokenInstance;
    }

    function testNotInitialized() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );
        CHEAT_CODES.expectRevert(abi.encodeWithSignature("NotInitialized()"));
        kpiTokenInstance.initializeOracles(address(0), abi.encode());
    }

    function testZeroAddressOraclesManager() external {
        ERC20KPIToken kpiTokenInstance = initializeKpiToken();
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("ZeroAddressOraclesManager()")
        );
        kpiTokenInstance.initializeOracles(address(0), abi.encode());
    }

    function testAlreadyInitialized() external {
        ERC20KPIToken kpiTokenInstance = createKpiToken(
            "description",
            "question"
        );
        IERC20KPIToken.OracleData[]
            memory oracleData = new IERC20KPIToken.OracleData[](1);
        oracleData[0] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 0,
            higherBound: 1,
            weight: 1,
            data: abi.encode(
                address(2), // fake reality.eth address
                address(this), // arbitrator
                0, // template id
                "a", // question
                200, // question timeout
                block.timestamp + 200 // expiry
            )
        });
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("AlreadyInitialized()")
        );
        kpiTokenInstance.initializeOracles(
            address(oraclesManager),
            abi.encode(oracleData, true)
        );
    }

    function testSameOracleBounds() external {
        ERC20KPIToken kpiTokenInstance = initializeKpiToken();
        IERC20KPIToken.OracleData[]
            memory oracleData = new IERC20KPIToken.OracleData[](1);
        oracleData[0] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 0,
            higherBound: 0,
            weight: 1,
            data: abi.encode(
                address(2), // fake reality.eth address
                address(this), // arbitrator
                0, // template id
                "a", // question
                200, // question timeout
                block.timestamp + 200 // expiry
            )
        });
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("InvalidOracleBounds()")
        );
        kpiTokenInstance.initializeOracles(
            address(oraclesManager),
            abi.encode(oracleData, true)
        );
    }

    function testInvalidOracleBounds() external {
        ERC20KPIToken kpiTokenInstance = initializeKpiToken();
        IERC20KPIToken.OracleData[]
            memory oracleData = new IERC20KPIToken.OracleData[](1);
        oracleData[0] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 1,
            higherBound: 0,
            weight: 1,
            data: abi.encode(
                address(2), // fake reality.eth address
                address(this), // arbitrator
                0, // template id
                "a", // question
                200, // question timeout
                block.timestamp + 200 // expiry
            )
        });
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("InvalidOracleBounds()")
        );
        kpiTokenInstance.initializeOracles(
            address(oraclesManager),
            abi.encode(oracleData, true)
        );
    }

    function testZeroWeight() external {
        ERC20KPIToken kpiTokenInstance = initializeKpiToken();
        IERC20KPIToken.OracleData[]
            memory oracleData = new IERC20KPIToken.OracleData[](1);
        oracleData[0] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 0,
            higherBound: 1,
            weight: 0,
            data: abi.encode(
                address(2), // fake reality.eth address
                address(this), // arbitrator
                0, // template id
                "a", // question
                200, // question timeout
                block.timestamp + 200 // expiry
            )
        });
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("InvalidOracleWeights()")
        );
        kpiTokenInstance.initializeOracles(
            address(oraclesManager),
            abi.encode(oracleData, true)
        );
    }

    function testSuccessAndSingleOracle() external {
        ERC20KPIToken kpiTokenInstance = initializeKpiToken();
        IERC20KPIToken.OracleData[]
            memory oracleData = new IERC20KPIToken.OracleData[](1);
        bytes memory manualRealityEthInitializationData = abi.encode(
            address(2), // fake reality.eth address
            address(this), // arbitrator
            0, // template id
            "a", // question
            200, // question timeout
            block.timestamp + 200 // expiry
        );
        oracleData[0] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 0,
            higherBound: 1,
            weight: 1,
            data: manualRealityEthInitializationData
        });
        address oraclesManager = address(2);
        CHEAT_CODES.mockCall(
            oraclesManager,
            abi.encodeWithSignature("instantiate(address,uint256,bytes)"),
            abi.encode(address(2))
        );
        kpiTokenInstance.initializeOracles(
            oraclesManager,
            abi.encode(oracleData, true)
        );

        (
            ,
            IERC20KPIToken.FinalizableOracle[] memory onChainFinalizableOracles,
            bool andRelationship,
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

        assertEq(onChainFinalizableOracles.length, 1);
        IERC20KPIToken.FinalizableOracle
            memory finalizableOracle = onChainFinalizableOracles[0];
        assertEq(finalizableOracle.addrezz, address(2));
        assertEq(finalizableOracle.lowerBound, 0);
        assertEq(finalizableOracle.higherBound, 1);
        assertEq(finalizableOracle.finalProgress, 0);
        assertEq(finalizableOracle.weight, 1);
        assertTrue(!finalizableOracle.finalized);
        assertTrue(andRelationship);

        CHEAT_CODES.clearMockedCalls();
    }
    
    function testSuccessNoAndSingleOracle() external {
        ERC20KPIToken kpiTokenInstance = initializeKpiToken();
        IERC20KPIToken.OracleData[]
            memory oracleData = new IERC20KPIToken.OracleData[](1);
        bytes memory manualRealityEthInitializationData = abi.encode(
            address(2), // fake reality.eth address
            address(this), // arbitrator
            0, // template id
            "a", // question
            200, // question timeout
            block.timestamp + 200 // expiry
        );
        oracleData[0] = IERC20KPIToken.OracleData({
            templateId: 0,
            lowerBound: 0,
            higherBound: 1,
            weight: 1,
            data: manualRealityEthInitializationData
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

        (
            ,
            IERC20KPIToken.FinalizableOracle[] memory onChainFinalizableOracles,
            bool andRelationship,
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

        assertEq(onChainFinalizableOracles.length, 1);
        IERC20KPIToken.FinalizableOracle
            memory finalizableOracle = onChainFinalizableOracles[0];
        assertEq(finalizableOracle.addrezz, address(2));
        assertEq(finalizableOracle.lowerBound, 0);
        assertEq(finalizableOracle.higherBound, 1);
        assertEq(finalizableOracle.finalProgress, 0);
        assertEq(finalizableOracle.weight, 1);
        assertTrue(!finalizableOracle.finalized);
        assertTrue(!andRelationship);

        CHEAT_CODES.clearMockedCalls();
    }

    function testSuccessAndMultipleOracles() external {
        ERC20KPIToken kpiTokenInstance = initializeKpiToken();
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
            abi.encode(oracleData, true)
        );

        (
            ,
            IERC20KPIToken.FinalizableOracle[] memory onChainFinalizableOracles,
            bool andRelationship,
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

        assertEq(onChainFinalizableOracles.length, 2);

        assertEq(onChainFinalizableOracles[0].addrezz, address(2));
        assertEq(onChainFinalizableOracles[0].lowerBound, 0);
        assertEq(onChainFinalizableOracles[0].higherBound, 1);
        assertEq(onChainFinalizableOracles[0].finalProgress, 0);
        assertEq(onChainFinalizableOracles[0].weight, 1);
        assertTrue(!onChainFinalizableOracles[0].finalized);

        assertEq(onChainFinalizableOracles[1].addrezz, address(2));
        assertEq(onChainFinalizableOracles[1].lowerBound, 5 ether);
        assertEq(onChainFinalizableOracles[1].higherBound, 10 ether);
        assertEq(onChainFinalizableOracles[1].finalProgress, 0);
        assertEq(onChainFinalizableOracles[1].weight, 3);
        assertTrue(!onChainFinalizableOracles[1].finalized);

        assertTrue(andRelationship);

        CHEAT_CODES.clearMockedCalls();
    }
    
    function testSuccessNoAndMultipleOracles() external {
        ERC20KPIToken kpiTokenInstance = initializeKpiToken();
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

        (
            ,
            IERC20KPIToken.FinalizableOracle[] memory onChainFinalizableOracles,
            bool andRelationship,
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

        assertEq(onChainFinalizableOracles.length, 2);

        assertEq(onChainFinalizableOracles[0].addrezz, address(2));
        assertEq(onChainFinalizableOracles[0].lowerBound, 0);
        assertEq(onChainFinalizableOracles[0].higherBound, 1);
        assertEq(onChainFinalizableOracles[0].finalProgress, 0);
        assertEq(onChainFinalizableOracles[0].weight, 1);
        assertTrue(!onChainFinalizableOracles[0].finalized);

        assertEq(onChainFinalizableOracles[1].addrezz, address(2));
        assertEq(onChainFinalizableOracles[1].lowerBound, 5 ether);
        assertEq(onChainFinalizableOracles[1].higherBound, 10 ether);
        assertEq(onChainFinalizableOracles[1].finalProgress, 0);
        assertEq(onChainFinalizableOracles[1].weight, 3);
        assertTrue(!onChainFinalizableOracles[1].finalized);

        assertTrue(!andRelationship);

        CHEAT_CODES.clearMockedCalls();
    }
}

pragma solidity 0.8.13;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {IERC20KPIToken} from "../../contracts/interfaces/kpi-tokens/IERC20KPIToken.sol";
import {TokenAmount} from "../../contracts/commons/Types.sol";

/**
 * @title FactoryCreateTokenTest
 * @dev FactoryCreateTokenTest contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract FactoryCreateTokenTest is BaseTestSetup {
    function testInvalidTemplateId() external {
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("NonExistentTemplate()")
        );
        factory.createToken(10, "a", abi.encode(1), abi.encode(2));
    }

    function testInvalidKpiTokenTemplateInitializationData() external {
        CHEAT_CODES.expectRevert(bytes(""));
        factory.createToken(1, "a", abi.encode(1), abi.encode(2));
    }

    function testInvalidOracleTemplateInitializationData() external {
        IERC20KPIToken.Collateral[]
            memory _collaterals = new IERC20KPIToken.Collateral[](1);
        _collaterals[0] = IERC20KPIToken.Collateral({
            token: address(1),
            amount: 2,
            minimumPayout: 1
        });
        bytes memory _erc20KpiTokenInitializationData = abi.encode(
            _collaterals,
            bytes32("Test"),
            bytes32("TST"),
            100 ether
        );
        CHEAT_CODES.expectRevert(bytes(""));
        factory.createToken(
            1,
            "a",
            _erc20KpiTokenInitializationData,
            abi.encode(2)
        );
    }

    function testSuccess() external {
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
            "question",
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
                "a",
                _erc20KpiTokenInitializationData,
                _oraclesInitializationData
            );
        firstErc20.approve(_predictedKpiTokenAddress, 2);

        assertEq(factory.size(), 0);
        factory.createToken(
            0,
            "a",
            _erc20KpiTokenInitializationData,
            _oraclesInitializationData
        );

        assertEq(factory.size(), 1);
        assertEq(factory.enumerate(0, 1)[0], _predictedKpiTokenAddress);
    }
}

pragma solidity 0.8.13;

import {BaseTestSetup} from "../../commons/BaseTestSetup.sol";
import {ManualRealityOracle} from "../../../contracts/oracles/ManualRealityOracle.sol";
import {IOraclesManager} from "../../../contracts/interfaces/IOraclesManager.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title ManualRealityOracleFinalizeTest
 * @dev ManualRealityOracleFinalizeTest contract
 * @author Federico Luzzi - <federico.luzzi@protonmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract ManualRealityOracleFinalizeTest is BaseTestSetup {
    function testRealityQuestionNotFinalized() external {
        ManualRealityOracle oracleInstance = ManualRealityOracle(
            Clones.clone(address(manualRealityOracleTemplate))
        );
        IOraclesManager.Template memory _template = oraclesManager.template(0);
        address _realityAddress = address(1234);
        bytes32 _questionId = bytes32("questionId");
        CHEAT_CODES.mockCall(
            _realityAddress,
            abi.encodeWithSignature(
                "askQuestion(uint256,string,address,uint32,uint32,uint256)"
            ),
            abi.encode(_questionId)
        );
        oracleInstance.initialize(
            address(1),
            _template,
            abi.encode(
                _realityAddress,
                address(1),
                0,
                "a",
                60,
                block.timestamp + 60
            )
        );

        CHEAT_CODES.mockCall(
            _realityAddress,
            abi.encodeWithSignature("isFinalized(bytes32)"),
            abi.encode(false)
        );
        CHEAT_CODES.expectRevert(abi.encodeWithSignature("Forbidden()"));
        oracleInstance.finalize();

        CHEAT_CODES.clearMockedCalls();
    }

    // FIXME: this is supposed to work, why is mocking finalize() on the kpi token not working?
    /* function testSuccess() external {
        ManualRealityOracle oracleInstance = ManualRealityOracle(
            Clones.clone(address(manualRealityOracleTemplate))
        );
        IOraclesManager.Template memory _template = oraclesManager.template(0);
        address _realityAddress = address(1234);
        bytes32 _questionId = bytes32("questionId");
        CHEAT_CODES.mockCall(
            _realityAddress,
            abi.encodeWithSignature(
                "askQuestion(uint256,string,address,uint32,uint32,uint256)"
            ),
            abi.encode(_questionId)
        );
        address _kpiToken = address(1234567);
        oracleInstance.initialize(
            _kpiToken,
            _template,
            abi.encode(
                _realityAddress,
                address(1),
                0,
                "a",
                60,
                block.timestamp + 60
            )
        );

        CHEAT_CODES.mockCall(
            _realityAddress,
            abi.encodeWithSignature("isFinalized(bytes32)", _questionId),
            abi.encode(true)
        );
        CHEAT_CODES.mockCall(
            _realityAddress,
            abi.encodeWithSignature("resultFor(bytes32)", _questionId),
            abi.encode(bytes32("1234"))
        );
        CHEAT_CODES.mockCall(
            _kpiToken,
            abi.encodeWithSignature(
                "finalize(uint256)",
                uint256(bytes32("1234"))
            ),
            abi.encode()
        );
        oracleInstance.finalize();

        assertTrue(oracleInstance.finalized());

        CHEAT_CODES.clearMockedCalls();
    } */
}

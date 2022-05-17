pragma solidity 0.8.13;

import {BaseTestSetup} from "../../commons/BaseTestSetup.sol";
import {ManualRealityOracle} from "../../../contracts/oracles/ManualRealityOracle.sol";
import {IOraclesManager} from "../../../contracts/interfaces/IOraclesManager.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title ManualRealityOracleGetTemplateTest
 * @dev ManualRealityOracleGetTemplateTest contract
 * @author Federico Luzzi - <federico.luzzi@protonmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract ManualRealityOracleGetTemplateTest is BaseTestSetup {
    function testSuccess() external {
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

        assertEq(oracleInstance.template().id, _template.id);

        CHEAT_CODES.clearMockedCalls();
    }
}

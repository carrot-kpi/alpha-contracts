pragma solidity 0.8.13;

import {BaseTestSetup} from "../../commons/BaseTestSetup.sol";
import {ManualRealityOracle} from "../../../contracts/oracles/ManualRealityOracle.sol";
import {IOraclesManager} from "../../../contracts/interfaces/IOraclesManager.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title ManualRealityOracleInitializeTest
 * @dev ManualRealityOracleInitializeTest contract
 * @author Federico Luzzi - <federico.luzzi@protonmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract ManualRealityOracleInitializeTest is BaseTestSetup {
    function testZeroAddressKpiToken() external {
        ManualRealityOracle oracleInstance = ManualRealityOracle(
            Clones.clone(address(manualRealityOracleTemplate))
        );
        IOraclesManager.Template memory _template = oraclesManager.template(0);
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("ZeroAddressKpiToken()")
        );
        oracleInstance.initialize(
            address(0),
            _template,
            abi.encode(uint256(1))
        );
    }

    function testInvalidTemplate() external {
        ManualRealityOracle oracleInstance = ManualRealityOracle(
            Clones.clone(address(manualRealityOracleTemplate))
        );
        IOraclesManager.Template memory _template = IOraclesManager.Template({
            id: 0,
            addrezz: address(2),
            version: IOraclesManager.Version({major: 1, minor: 0, patch: 0}),
            specification: "a",
            automatable: false,
            exists: false
        });
        CHEAT_CODES.expectRevert(abi.encodeWithSignature("InvalidTemplate()"));
        oracleInstance.initialize(
            address(1),
            _template,
            abi.encode(uint256(1))
        );
    }

    function testZeroAddressReality() external {
        ManualRealityOracle oracleInstance = ManualRealityOracle(
            Clones.clone(address(manualRealityOracleTemplate))
        );
        IOraclesManager.Template memory _template = oraclesManager.template(0);
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("ZeroAddressReality()")
        );
        oracleInstance.initialize(
            address(1),
            _template,
            abi.encode(address(0), address(1), 0, "a", 60, block.timestamp + 60)
        );
    }

    function testZeroAddressArbitrator() external {
        ManualRealityOracle oracleInstance = ManualRealityOracle(
            Clones.clone(address(manualRealityOracleTemplate))
        );
        IOraclesManager.Template memory _template = oraclesManager.template(0);
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("ZeroAddressArbitrator()")
        );
        oracleInstance.initialize(
            address(1),
            _template,
            abi.encode(address(1), address(0), 0, "a", 60, block.timestamp + 60)
        );
    }

    function testEmptyQuestion() external {
        ManualRealityOracle oracleInstance = ManualRealityOracle(
            Clones.clone(address(manualRealityOracleTemplate))
        );
        IOraclesManager.Template memory _template = oraclesManager.template(0);
        CHEAT_CODES.expectRevert(abi.encodeWithSignature("InvalidQuestion()"));
        oracleInstance.initialize(
            address(1),
            _template,
            abi.encode(address(1), address(1), 0, "", 60, block.timestamp + 60)
        );
    }

    function testInvalidTimeout() external {
        ManualRealityOracle oracleInstance = ManualRealityOracle(
            Clones.clone(address(manualRealityOracleTemplate))
        );
        IOraclesManager.Template memory _template = oraclesManager.template(0);
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("InvalidQuestionTimeout()")
        );
        oracleInstance.initialize(
            address(1),
            _template,
            abi.encode(address(1), address(1), 0, "a", 0, block.timestamp + 60)
        );
    }

    function testInvalidExpiry() external {
        ManualRealityOracle oracleInstance = ManualRealityOracle(
            Clones.clone(address(manualRealityOracleTemplate))
        );
        IOraclesManager.Template memory _template = oraclesManager.template(0);
        CHEAT_CODES.expectRevert(abi.encodeWithSignature("InvalidExpiry()"));
        oracleInstance.initialize(
            address(1),
            _template,
            abi.encode(address(1), address(1), 0, "a", 60, block.timestamp)
        );
    }

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
        uint256 _openingTs = block.timestamp + 60;
        oracleInstance.initialize(
            address(1),
            _template,
            abi.encode(_realityAddress, address(1), 0, "a", 60, _openingTs)
        );

        assertEq(oracleInstance.template().id, _template.id);

        CHEAT_CODES.mockCall(
            _realityAddress,
            abi.encodeWithSignature("getArbitrator(bytes32)"),
            abi.encode(address(1))
        );
        CHEAT_CODES.mockCall(
            _realityAddress,
            abi.encodeWithSignature("getTimeout(bytes32)"),
            abi.encode(uint32(60))
        );
        CHEAT_CODES.mockCall(
            _realityAddress,
            abi.encodeWithSignature("getOpeningTS(bytes32)"),
            abi.encode(_openingTs)
        );
        bytes memory _data = oracleInstance.data();
        (
            address _onChainReality,
            bytes32 _onChainQuestionId,
            address _onChainArbitrator,
            uint256 _onChainRealityTemplateId,
            string memory _onChainQuestion,
            uint32 _onChainTimeout,
            uint32 _onChainOpeningTs
        ) = abi.decode(
                _data,
                (address, bytes32, address, uint256, string, uint32, uint32)
            );
        assertEq(_onChainReality, _realityAddress);
        assertEq(_onChainQuestionId, _questionId);
        assertEq(_onChainArbitrator, address(1));
        assertEq(_onChainRealityTemplateId, 0);
        assertEq(_onChainQuestion, "a");
        assertEq(_onChainTimeout, 60);
        assertEq(_onChainOpeningTs, _openingTs);

        CHEAT_CODES.clearMockedCalls();
    }
}

pragma solidity 0.8.13;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title InstantiateTest
 * @dev InstantiateTest contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract InstantiateTest is BaseTestSetup {
    function testFailNotFromCreatedKpiToken() external {
        // FIXME: why does this fail if I uncomment stuff?
        CHEAT_CODES.expectRevert(); /* abi.encodeWithSignature("Forbidden()") */
        oraclesManager.instantiate(address(this), 0, bytes(""));
    }

    function testSuccessManualRealityOracle() external {
        bytes memory _initializationData = abi.encode(
            address(2), // fake reality.eth address
            address(this), // arbitrator
            0, // template id
            "a", // question
            200, // question timeout
            block.timestamp + 200 // expiry
        );
        address _predictedInstanceAddress = Clones.predictDeterministicAddress(
            address(manualRealityOracleTemplate),
            keccak256(abi.encodePacked(address(this), _initializationData)),
            address(oraclesManager)
        );
        CHEAT_CODES.mockCall(
            address(factory),
            abi.encodeWithSignature("created(address)", address(this)),
            abi.encode(true)
        );
        address _instance = oraclesManager.instantiate(
            address(this),
            0,
            _initializationData
        );
        assertEq(_instance, _predictedInstanceAddress);
        CHEAT_CODES.clearMockedCalls();
    }
}

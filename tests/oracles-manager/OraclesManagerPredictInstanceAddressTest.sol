pragma solidity 0.8.13;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {OraclesManager} from "../../contracts/OraclesManager.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title OraclesManagerPredictInstanceAddressTest
 * @dev OraclesManagerPredictInstanceAddressTest contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract OraclesManagerPredictInstanceAddressTest is BaseTestSetup {
    function testSuccess() external {
        bytes memory _initializationData = abi.encodePacked(
            uint256(1),
            uint256(2),
            uint256(3)
        );
        address _predicatedAddress = Clones.predictDeterministicAddress(
            address(manualRealityOracleTemplate),
            keccak256(abi.encodePacked(address(this), _initializationData)),
            address(oraclesManager)
        );
        assertEq(
            _predicatedAddress,
            oraclesManager.predictInstanceAddress(
                address(this),
                0,
                _initializationData
            )
        );
    }
}

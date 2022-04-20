pragma solidity 0.8.13;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";
import {KPITokensManager} from "../../contracts/KPITokensManager.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title KpiTokensManagerPredictInstanceAddressTest
 * @dev KpiTokensManagerPredictInstanceAddressTest contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract KpiTokensManagerPredictInstanceAddressTest is BaseTestSetup {
    function testSuccess() external {
        bytes memory _initializationData = abi.encodePacked(
            uint256(1),
            uint256(2),
            uint256(3)
        );
        bytes memory _oraclesInitializationData = abi.encodePacked(
            uint256(4),
            uint256(5),
            uint256(6)
        );
        string memory _description = "a";
        address _predictedAddress = Clones.predictDeterministicAddress(
            address(erc20KpiTokenTemplate),
            keccak256(
                abi.encodePacked(
                    _description,
                    _initializationData,
                    _oraclesInitializationData
                )
            ),
            address(kpiTokensManager)
        );
        assertEq(
            _predictedAddress,
            kpiTokensManager.predictInstanceAddress(
                0,
                _description,
                _initializationData,
                _oraclesInitializationData
            )
        );
    }
}

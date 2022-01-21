pragma solidity ^0.8.11;

/**
 * @title IOracle
 * @dev IOracle contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
interface IOracle {
    function initialize(address _kpiToken, bytes memory _initializationData)
        external;

    function kpiToken() external returns (address);

    function finalized() external returns (bool);
}

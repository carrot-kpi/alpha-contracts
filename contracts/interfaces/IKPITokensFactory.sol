pragma solidity ^0.8.11;

import "../commons/Types.sol";

/**
 * @title IKPITokensFactory
 * @dev IKPITokensFactory contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
interface IKPITokensFactory {
    function createToken(
        address _template,
        bytes memory _initializationData,
        bytes memory _oraclesInitializationData
    ) external;

    function created(address _address) external returns (bool);

    function setKpiTokensManager(address _kpiTokensManager) external;

    function setFeeReceiver(address _feeReceiver) external;
}

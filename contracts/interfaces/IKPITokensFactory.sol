pragma solidity >=0.8.0;

/**
 * @title IKPITokensFactory
 * @dev IKPITokensFactory contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
interface IKPITokensFactory {
    function createToken(
        uint256 _id,
        string memory _description,
        bytes memory _initializationData,
        bytes memory _oraclesInitializationData
    ) external;

    function allowOraclesCreation(address _address) external returns (bool);

    function setKpiTokensManager(address _kpiTokensManager) external;

    function setFeeReceiver(address _feeReceiver) external;

    function kpiTokensAmount() external view returns (uint256);

    function enumerate(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        returns (address[] memory);
}

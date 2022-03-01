pragma solidity ^0.8.11;

import "../IKPITokensManager.sol";

/**
 * @title IKPIToken
 * @dev IKPIToken contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
interface IKPIToken {
    struct InitializeArguments {
        address creator;
        address kpiTokensManager;
        uint256 kpiTokenTemplateId;
        string description;
        bytes data;
    }

    function initialize(
        address _creator,
        address _kpiTokensManager,
        uint256 _kpiTokenTemplateId,
        string memory _description,
        bytes memory _data
    ) external;

    function initializeOracles(address _oraclesManager, bytes memory _data)
        external;

    function collectProtocolFees(address _feeReceiver) external;

    function finalize(uint256 _result) external;

    function redeem() external;

    function creator() external view returns (address);

    function template()
        external
        view
        returns (IKPITokensManager.Template memory);

    function oracles() external view returns (address[] memory);

    function description() external view returns (string memory);

    function finalized() external view returns (bool);

    function protocolFee(bytes memory _data)
        external
        view
        returns (bytes memory);

    function data() external view returns (bytes memory);
}

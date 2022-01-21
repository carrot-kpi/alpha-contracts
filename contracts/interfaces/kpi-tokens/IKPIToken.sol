pragma solidity ^0.8.11;

import "../../commons/Types.sol";

/**
 * @title IKPIToken
 * @dev IKPIToken contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
interface IKPIToken {
    function initialize(address _creator, bytes memory _data) external;

    function initializeOracles(address _oraclesManager, bytes memory _data)
        external;

    function collectProtocolFees(address _feeReceiver) external;

    function finalize(uint256 _result) external;

    function redeem() external;

    function finalized() external view returns (bool);

    function protocolFee(bytes memory _data)
        external
        view
        returns (bytes memory);
}

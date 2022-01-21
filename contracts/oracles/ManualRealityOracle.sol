pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/oracles/IOracle.sol";
import "../interfaces/kpi-tokens/IKPIToken.sol";
import "../interfaces/external/IReality.sol";

/**
 * @title ManualRealityOracle
 * @dev ManualRealityOracle contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
contract ManualRealityOracle is IOracle, Initializable {
    bool public finalized;
    address public kpiToken;
    address public reality;
    bytes32 public kpiId;

    error Forbidden();
    error ZeroAddressKpiToken();
    error ZeroAddressReality();
    error ZeroAddressArbitrator();
    error InvalidQuestion();
    error InvalidQuestionTimeout();
    error InvalidExpiry();

    event Log(bytes _log);

    function initialize(address _kpiToken, bytes memory _data)
        external
        override
        initializer
    {
        if (_kpiToken == address(0)) revert ZeroAddressKpiToken();

        (
            address _reality,
            address _arbitrator,
            string memory _question,
            uint32 _questionTimeout,
            uint32 _expiry,
            bool _binary
        ) = abi.decode(_data, (address, address, string, uint32, uint32, bool));

        if (_reality == address(0)) revert ZeroAddressReality();
        if (_arbitrator == address(0)) revert ZeroAddressArbitrator();
        if (bytes(_question).length == 0) revert InvalidQuestion();
        if (_questionTimeout == 0) revert InvalidQuestionTimeout();
        if (_expiry <= block.timestamp) revert InvalidExpiry();

        emit Log(_data);

        kpiToken = _kpiToken;
        reality = _reality;
        kpiId = IReality(_reality).askQuestion(
            _binary ? 0 : 1,
            _question,
            _arbitrator,
            _questionTimeout,
            _expiry,
            0
        );
    }

    function finalize() external {
        if (finalized || !IReality(reality).isFinalized(kpiId))
            revert Forbidden();
        IKPIToken(kpiToken).finalize(
            uint256(IReality(reality).resultFor(kpiId))
        );
        finalized = true;
    }
}

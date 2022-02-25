pragma solidity ^0.8.11;

import "@jolt-network/contracts/JobUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../interfaces/oracles/IOracle.sol";
import "../interfaces/IOraclesManager.sol";
import "../interfaces/kpi-tokens/IKPIToken.sol";
import "../interfaces/external/IReality.sol";

error ZeroAddressKpiToken();
error ZeroAddressReality();
error ZeroAddressArbitrator();
error InvalidQuestion();
error InvalidBounds();
error InvalidQuestionTimeout();
error InvalidExpiry();
error NoWorkRequired();

/**
 * @title AutomatedRealityOracle
 * @dev AutomatedRealityOracle contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
contract AutomatedRealityOracle is JobUpgradeable, IOracle {
    bool public finalized;
    address public kpiToken;
    address public reality;
    bytes32 internal questionId;
    string internal question;
    IOraclesManager.Template public __template;

    function initialize(
        address _kpiToken,
        IOraclesManager.Template memory _template,
        bytes memory _data
    ) external initializer {
        if (_kpiToken == address(0)) revert ZeroAddressKpiToken();

        (
            address _joltJobsRegistry,
            address _reality,
            address _arbitrator,
            string memory _question,
            uint32 _questionTimeout,
            uint32 _expiry,
            bool _binary
        ) = abi.decode(
                _data,
                (address, address, address, string, uint32, uint32, bool)
            );

        if (_reality == address(0)) revert ZeroAddressReality();
        if (_arbitrator == address(0)) revert ZeroAddressArbitrator();
        if (bytes(_question).length == 0) revert InvalidQuestion();
        if (_questionTimeout == 0) revert InvalidQuestionTimeout();
        if (_expiry <= block.timestamp) revert InvalidExpiry();
        __Job_init(_joltJobsRegistry);

        __template = _template;
        kpiToken = _kpiToken;
        reality = _reality;
        question = _question;
        questionId = IReality(_reality).askQuestion(
            _binary ? 0 : 1,
            _question,
            _arbitrator,
            _questionTimeout,
            _expiry,
            0
        );
    }

    function _workable() internal view returns (bool) {
        return !finalized && IReality(reality).isFinalized(questionId);
    }

    function workable(bytes memory)
        external
        view
        override
        returns (bool, bytes memory)
    {
        return (_workable(), bytes(""));
    }

    function work(bytes memory) external override needsExecution {
        if (!_workable()) revert NoWorkRequired();
        IKPIToken(kpiToken).finalize(
            uint256(IReality(reality).resultFor(questionId))
        );
        finalized = true;
    }

    function data() external view override returns (bytes memory) {
        address _reality = reality; // gas optimization
        bytes32 _questionId = questionId; // gas optimization
        return
            abi.encode(
                _reality,
                IReality(_reality).getArbitrator(_questionId),
                question,
                IReality(_reality).getTimeout(_questionId),
                IReality(_reality).getOpeningTS(_questionId)
            );
    }

    function template()
        external
        view
        override
        returns (IOraclesManager.Template memory)
    {
        return __template;
    }
}

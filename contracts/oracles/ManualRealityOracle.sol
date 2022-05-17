pragma solidity 0.8.13;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../interfaces/oracles/IOracle.sol";
import "../interfaces/kpi-tokens/IKPIToken.sol";
import "../interfaces/external/IReality.sol";

/**
 * @title ManualRealityOracle
 * @dev ManualRealityOracle contract
 * @author Federico Luzzi - <federico.luzzi@protonmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
contract ManualRealityOracle is IOracle, Initializable {
    bool public finalized;
    address public kpiToken;
    address internal reality;
    uint256 internal realityTemplateId;
    bytes32 internal questionId;
    string internal question;
    IOraclesManager.Template internal __template;

    error Forbidden();
    error ZeroAddressKpiToken();
    error InvalidTemplate();
    error ZeroAddressReality();
    error ZeroAddressArbitrator();
    error InvalidQuestion();
    error InvalidQuestionTimeout();
    error InvalidExpiry();

    function initialize(
        address _kpiToken,
        IOraclesManager.Template calldata _template,
        bytes calldata _data
    ) external override initializer {
        if (_kpiToken == address(0)) revert ZeroAddressKpiToken();
        if (!_template.exists) revert InvalidTemplate();

        (
            address _reality,
            address _arbitrator,
            uint256 _templateId,
            string memory _question,
            uint32 _questionTimeout,
            uint32 _expiry
        ) = abi.decode(
                _data,
                (address, address, uint256, string, uint32, uint32)
            );

        if (_reality == address(0)) revert ZeroAddressReality();
        if (_arbitrator == address(0)) revert ZeroAddressArbitrator();
        if (bytes(_question).length == 0) revert InvalidQuestion();
        if (_questionTimeout == 0) revert InvalidQuestionTimeout();
        if (_expiry <= block.timestamp) revert InvalidExpiry();

        __template = _template;
        kpiToken = _kpiToken;
        reality = _reality;
        realityTemplateId = _templateId;
        question = _question;
        questionId = IReality(_reality).askQuestion(
            _templateId,
            _question,
            _arbitrator,
            _questionTimeout,
            _expiry,
            0
        );
    }

    function finalize() external {
        bytes32 _questionId = questionId; // gas optimization
        address _reality = reality; // gas optimization
        if (
            finalized ||
            !IReality(_reality).isFinalized(_questionId) ||
            IKPIToken(kpiToken).finalized()
        ) revert Forbidden();
        IKPIToken(kpiToken).finalize(
            uint256(IReality(_reality).resultFor(_questionId))
        );
        finalized = true;
    }

    function data() external view override returns (bytes memory) {
        address _reality = reality; // gas optimization
        bytes32 _questionId = questionId; // gas optimization
        return
            abi.encode(
                _reality,
                _questionId,
                IReality(_reality).getArbitrator(_questionId),
                realityTemplateId,
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

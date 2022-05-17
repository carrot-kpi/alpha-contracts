pragma solidity 0.8.13;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {IOracle} from "../interfaces/oracles/IOracle.sol";
import {IOraclesManager} from "../interfaces/IOraclesManager.sol";
import {IKPIToken} from "../interfaces/kpi-tokens/IKPIToken.sol";
import {IReality} from "../interfaces/external/IReality.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Manual Reality oracle
/// @dev An oracle template imlementation leveraging Reality.eth
/// crowdsourced, manual oracle to get data about real-world events
/// on-chain. Since the oracle is crowdsourced, it's extremely flexible,
/// and any condition that can be put into text can leverage Reality.eth
/// as an oracle. The setup is of great importance to ensure the safety
/// of the solution (question timeout, expiry, arbitrator atc must be set
/// with care to avoid unwanted results).
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
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

    /// @dev Initializes the template through the passed in data. This function is
    /// generally invoked by the oracles manager contract, in turn invoked by a KPI
    /// token template at creation-time. For more info on some of this parameters check
    /// out the Reality.eth docs here: https://reality.eth.limo/app/docs/html/dapp.html#.
    /// @param _kpiToken The address of the KPI token to which the oracle must be linked to.
    /// This address is also used to know to which contract to report results back to.
    /// @param _template The template struct representing this oracle's template.
    /// @param _data An ABI-encoded structure forwarded by the created KPI token from the KPI token
    /// creator, containing the initialization parameters for the oracle template.
    /// In particular the structure is formed in the following way:
    /// - `address _reality`: The address of the Reality.eth contract of choice in a specific network.
    /// - `address _arbitrator`: The arbitrator for the Reality.eth question.
    /// - `uint256 _templateId`: The template id for the Reality.eth question.
    /// - `string memory _question`: The question that must be submitted to Reality.eth.
    /// - `uint32 _questionTimeout`: The question timeout as described in the Reality.eth docs (linked above).
    /// - `uint32 _expiry`: The question expiry as described in the Reality.eth docs (linked above).
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

    /// @dev Once the question is finalized on Reality.eth, this must be manually called to
    /// report back the result to the linked KPI token. This also marks the oracle as finalized.
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

    /// @dev View function returning all the most important data about the oracle, in
    /// an ABI-encoded structure. The structure pretty much includes all the initialization
    /// data and some.
    /// @return The ABI-encoded data.
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

    /// @dev View function returning info about the template used to instantiate this oracle.
    /// @return The template struct.
    function template()
        external
        view
        override
        returns (IOraclesManager.Template memory)
    {
        return __template;
    }
}

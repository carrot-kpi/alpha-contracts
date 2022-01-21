pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@xcute/contracts/interfaces/IJobsRegistry.sol";
import "./interfaces/kpi-tokens/IKPIToken.sol";
import "./interfaces/oracles/IOracle.sol";
import "./interfaces/IOraclesManager.sol";
import "./interfaces/IKPITokensFactory.sol";
import "./libraries/TemplateSetLibrary.sol";

/**
 * @title OraclesManager
 * @dev OraclesManager contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
contract OraclesManager is Ownable, IOraclesManager {
    using SafeERC20 for IERC20;
    using TemplateSetLibrary for EnumerableTemplateSet;

    address public factory;
    address public workersJobsRegistry;
    EnumerableTemplateSet private templates;

    error NonExistentTemplate();
    error ZeroAddressFactory();
    error Forbidden();
    error AlreadyAdded();
    error ZeroAddressTemplate();
    error NotAnUpgrade();
    error ZeroAddressWorkersJobsRegistry();
    error InvalidDescription();
    error InvalidAutomationParameters();

    constructor(address _factory, address _workersJobsRegistry) {
        if (_factory == address(0)) revert ZeroAddressFactory();
        factory = _factory;
        workersJobsRegistry = _workersJobsRegistry;
    }

    function salt(
        address _automationFundingToken,
        uint256 _automationFundingAmount,
        bytes memory _initializationData
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _automationFundingToken,
                    _automationFundingAmount,
                    _initializationData
                )
            );
    }

    function predictInstanceAddress(
        address _template,
        address _automationFundingToken,
        uint256 _automationFundingAmount,
        bytes memory _initializationData
    ) external view returns (address) {
        return
            Clones.predictDeterministicAddress(
                _template,
                salt(
                    _automationFundingToken,
                    _automationFundingAmount,
                    _initializationData
                ),
                address(this)
            );
    }

    function instantiate(
        address _template,
        address _automationFundingToken,
        uint256 _automationFundingAmount,
        bytes memory _initializationData
    ) external override returns (address) {
        if (!IKPITokensFactory(factory).created(msg.sender)) revert Forbidden();
        if (!templates.contains(_template)) revert NonExistentTemplate();
        address _instance = Clones.cloneDeterministic(
            _template,
            salt(
                _automationFundingToken,
                _automationFundingAmount,
                _initializationData
            )
        );
        if (
            _automationFundingAmount > 0 &&
            _automationFundingToken != address(0) &&
            workersJobsRegistry != address(0)
        ) {
            IJobsRegistry(workersJobsRegistry).addJob(_instance);
            _ensureJobsRegistryAllowance(
                _automationFundingToken,
                _automationFundingAmount
            );
            IJobsRegistry(workersJobsRegistry).addCredit(
                _instance,
                _automationFundingToken,
                _automationFundingAmount
            );
        }
        IOracle(_instance).initialize(msg.sender, _initializationData);
        return _instance;
    }

    function addTemplate(
        address _template,
        bool _automatable,
        string calldata _description
    ) external override {
        if (msg.sender != owner()) revert Forbidden();
        templates.add(_template, _automatable, _description);
    }

    function removeTemplate(address _template) external override {
        if (msg.sender != owner()) revert Forbidden();
        templates.remove(_template);
    }

    function updateTemplateDescription(
        address _template,
        string calldata _newDescription
    ) external override {
        if (msg.sender != owner()) revert Forbidden();
        Template storage _templateFromStorage = templates.get(_template);
        _templateFromStorage.description = _newDescription;
    }

    function updgradeTemplate(
        address _template,
        address _newTemplate,
        string calldata _newDescription
    ) external override {
        if (msg.sender != owner()) revert Forbidden();
        templates.upgrade(_template, _newTemplate, _newDescription);
    }

    function _ensureJobsRegistryAllowance(
        address _token,
        uint256 _minimumAmount
    ) internal {
        if (
            _token != address(0) &&
            workersJobsRegistry != address(0) &&
            _minimumAmount > 0
        )
            IERC20(_token).approve(
                workersJobsRegistry,
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
    }

    function template(address _template)
        external
        view
        override
        returns (Template memory)
    {
        return templates.get(_template);
    }

    function templatesAmount() external view override returns (uint256) {
        return templates.size();
    }

    function templatesSlice(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        override
        returns (Template[] memory)
    {
        return templates.enumerate(_fromIndex, _toIndex);
    }
}

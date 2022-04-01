pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/kpi-tokens/IKPIToken.sol";
import "./interfaces/oracles/IOracle.sol";
import "./interfaces/IOraclesManager.sol";
import "./interfaces/IKPITokensFactory.sol";
import "./libraries/OracleTemplateSetLibrary.sol";

/**
 * @title OraclesManager
 * @dev OraclesManager contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
contract OraclesManager is Ownable, IOraclesManager {
    using SafeERC20 for IERC20;
    using OracleTemplateSetLibrary for IOraclesManager.EnumerableTemplateSet;

    address public factory;
    address public jobsRegistry;
    IOraclesManager.EnumerableTemplateSet private templates;

    error NonExistentTemplate();
    error ZeroAddressFactory();
    error Forbidden();
    error AlreadyAdded();
    error ZeroAddressTemplate();
    error NotAnUpgrade();
    error ZeroAddressJobsRegistry();
    error InvalidSpecification();
    error InvalidAutomationParameters();

    constructor(address _factory, address _jobsRegistry) {
        if (_factory == address(0)) revert ZeroAddressFactory();
        factory = _factory;
        jobsRegistry = _jobsRegistry;
    }

    function setJobsRegistry(address _jobsRegistry)
        external
        override
        onlyOwner
    {
        jobsRegistry = _jobsRegistry;
    }

    function salt(bytes calldata _initializationData)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_initializationData));
    }

    function predictInstanceAddress(
        uint256 _id,
        bytes calldata _initializationData
    ) external view override returns (address) {
        return
            Clones.predictDeterministicAddress(
                templates.get(_id).addrezz,
                salt(_initializationData),
                address(this)
            );
    }

    function instantiate(
        address _creator,
        uint256 _id,
        bytes calldata _initializationData
    ) external override returns (address) {
        if (!IKPITokensFactory(factory).created(msg.sender)) revert Forbidden();
        address _instance = Clones.cloneDeterministic(
            templates.get(_id).addrezz,
            salt(_initializationData)
        );
        IOracle(_instance).initialize(
            msg.sender,
            templates.get(_id),
            _initializationData
        );
        return _instance;
    }

    function addTemplate(
        address _template,
        bool _automatable,
        string calldata _specification
    ) external override {
        if (msg.sender != owner()) revert Forbidden();
        templates.add(_template, _automatable, _specification);
    }

    function removeTemplate(uint256 _id) external override {
        if (msg.sender != owner()) revert Forbidden();
        templates.remove(_id);
    }

    function updateTemplateSpecification(
        uint256 _id,
        string calldata _newSpecification
    ) external override {
        if (msg.sender != owner()) revert Forbidden();
        templates.get(_id).specification = _newSpecification;
    }

    function updgradeTemplate(
        uint256 _id,
        address _newTemplate,
        uint8 _versionBump,
        string calldata _newSpecification
    ) external override {
        if (msg.sender != owner()) revert Forbidden();
        templates.upgrade(_id, _newTemplate, _versionBump, _newSpecification);
    }

    function template(uint256 _id)
        external
        view
        override
        returns (IOraclesManager.Template memory)
    {
        return templates.get(_id);
    }

    function templatesAmount() external view override returns (uint256) {
        return templates.size();
    }

    function templatesSlice(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        override
        returns (IOraclesManager.Template[] memory)
    {
        return templates.enumerate(_fromIndex, _toIndex);
    }
}

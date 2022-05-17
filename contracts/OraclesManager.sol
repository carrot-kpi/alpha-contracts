pragma solidity 0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IKPIToken} from "./interfaces/kpi-tokens/IKPIToken.sol";
import {IOracle} from "./interfaces/oracles/IOracle.sol";
import {IOraclesManager} from "./interfaces/IOraclesManager.sol";
import {IKPITokensFactory} from "./interfaces/IKPITokensFactory.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title Oracles manager
/// @notice The oracles manager contract acts as a template
/// registry for oracle implementations. Additionally, templates
/// can also only be instantiated by the manager itself,
/// exclusively by request of the factory. All templates-related functions are governance-gated
/// (addition, removal, upgrade of templates and more) and the governance contract must be the
/// owner of the oracles manager.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract OraclesManager is Ownable, IOraclesManager {
    using SafeERC20 for IERC20;

    address public factory;
    IOraclesManager.EnumerableTemplateSet private templates;

    error NonExistentTemplate();
    error ZeroAddressFactory();
    error Forbidden();
    error ZeroAddressTemplate();
    error InvalidSpecification();
    error NoKeyForTemplate();
    error InvalidVersionBump();
    error InvalidIndices();

    event AddTemplate(address template, bool automatable, string specification);
    event RemoveTemplate(uint256 id);
    event UpdateTemplateSpecification(uint256 id, string _specification);
    event UpgradeTemplate(
        uint256 id,
        address newTemplate,
        uint8 versionBump,
        string newSpecification
    );

    constructor(address _factory) {
        if (_factory == address(0)) revert ZeroAddressFactory();
        factory = _factory;
    }

    function salt(address _creator, bytes calldata _initializationData)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_creator, _initializationData));
    }

    function predictInstanceAddress(
        address _creator,
        uint256 _id,
        bytes calldata _initializationData
    ) external view override returns (address) {
        return
            Clones.predictDeterministicAddress(
                // FIXME: getting a memory template
                // suffices in this case, will it result in gas savings?
                storageTemplate(_id).addrezz,
                salt(_creator, _initializationData),
                address(this)
            );
    }

    function instantiate(
        address _creator,
        uint256 _id,
        bytes calldata _initializationData
    ) external override returns (address) {
        if (!IKPITokensFactory(factory).allowOraclesCreation(msg.sender))
            revert Forbidden();
        IOraclesManager.Template storage _template = storageTemplate(_id);
        address _instance = Clones.cloneDeterministic(
            _template.addrezz,
            salt(_creator, _initializationData)
        );
        IOracle(_instance).initialize(
            msg.sender,
            _template,
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
        if (_template == address(0)) revert ZeroAddressTemplate();
        if (bytes(_specification).length == 0) revert InvalidSpecification();
        uint256 _id = templates.ids++;
        templates.map[_id] = IOraclesManager.Template({
            id: _id,
            addrezz: _template,
            version: IOraclesManager.Version({major: 1, minor: 0, patch: 0}),
            specification: _specification,
            automatable: _automatable,
            exists: true
        });
        templates.keys.push(_id);
        emit AddTemplate(_template, _automatable, _specification);
    }

    function removeTemplate(uint256 _id) external override {
        if (msg.sender != owner()) revert Forbidden();
        IOraclesManager.Template storage _templateFromStorage = storageTemplate(
            _id
        );
        delete _templateFromStorage.exists;
        uint256 _keysLength = templates.keys.length;
        for (uint256 _i = 0; _i < _keysLength; _i++)
            if (templates.keys[_i] == _id) {
                if (_i != _keysLength - 1)
                    templates.keys[_i] = templates.keys[_keysLength - 1];
                templates.keys.pop();
                emit RemoveTemplate(_id);
                return;
            }
        revert NoKeyForTemplate();
    }

    function updateTemplateSpecification(
        uint256 _id,
        string calldata _newSpecification
    ) external override {
        if (msg.sender != owner()) revert Forbidden();
        if (bytes(_newSpecification).length == 0) revert InvalidSpecification();
        storageTemplate(_id).specification = _newSpecification;
        emit UpdateTemplateSpecification(_id, _newSpecification);
    }

    function upgradeTemplate(
        uint256 _id,
        address _newTemplate,
        uint8 _versionBump,
        string calldata _newSpecification
    ) external override {
        if (msg.sender != owner()) revert Forbidden();
        if (bytes(_newSpecification).length == 0) revert InvalidSpecification();
        IOraclesManager.Template storage _templateFromStorage = storageTemplate(
            _id
        );
        if (
            keccak256(bytes(_templateFromStorage.specification)) ==
            keccak256(bytes(_newSpecification))
        ) revert InvalidSpecification();
        _templateFromStorage.addrezz = _newTemplate;
        _templateFromStorage.specification = _newSpecification;
        if (_versionBump & 1 == 1) _templateFromStorage.version.patch++;
        else if (_versionBump & 2 == 2) {
            _templateFromStorage.version.minor++;
            _templateFromStorage.version.patch = 0;
        } else if (_versionBump & 4 == 4) {
            _templateFromStorage.version.major++;
            _templateFromStorage.version.minor = 0;
            _templateFromStorage.version.patch = 0;
        } else revert InvalidVersionBump();
        emit UpgradeTemplate(
            _id,
            _newTemplate,
            _versionBump,
            _newSpecification
        );
    }

    function storageTemplate(uint256 _id)
        internal
        view
        returns (IOraclesManager.Template storage)
    {
        IOraclesManager.Template storage _template = templates.map[_id];
        if (!_template.exists) revert NonExistentTemplate();
        return _template;
    }

    function template(uint256 _id)
        external
        view
        override
        returns (IOraclesManager.Template memory)
    {
        IOraclesManager.Template memory _template = templates.map[_id];
        if (!_template.exists) revert NonExistentTemplate();
        return _template;
    }

    function templatesAmount() external view override returns (uint256) {
        return templates.keys.length;
    }

    function enumerate(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        override
        returns (IOraclesManager.Template[] memory)
    {
        if (_toIndex > templates.keys.length || _fromIndex > _toIndex)
            revert InvalidIndices();
        uint256 _range = _toIndex - _fromIndex;
        IOraclesManager.Template[]
            memory _templates = new IOraclesManager.Template[](_range);
        for (uint256 _i = 0; _i < _range; _i++)
            _templates[_i] = templates.map[templates.keys[_fromIndex + _i]];
        return _templates;
    }
}

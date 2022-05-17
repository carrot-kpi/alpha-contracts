pragma solidity 0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IKPIToken} from "./interfaces/kpi-tokens/IKPIToken.sol";
import {IOracle} from "./interfaces/oracles/IOracle.sol";
import {IKPITokensManager} from "./interfaces/IKPITokensManager.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI tokens manager
/// @dev The KPI token manager contract acts as a template
/// registry for KPI token implementations. Additionally, templates
/// can also only be instantiated by the manager itself,
/// exclusively by request of the factory contract. All
/// templates-related functions are governance-gated
/// (addition, removal, upgrade of templates and more) and the
/// governance contract must be the owner of the KPI tokens manager.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract KPITokensManager is Ownable, IKPITokensManager {
    using SafeERC20 for IERC20;

    address public factory;
    IKPITokensManager.EnumerableTemplateSet private templates;

    error ZeroAddressFactory();
    error Forbidden();
    error InvalidTemplate();
    error ZeroAddressTemplate();
    error InvalidSpecification();
    error InvalidVersionBump();
    error NoKeyForTemplate();
    error NonExistentTemplate();
    error InvalidIndices();

    constructor(address _factory) {
        if (_factory == address(0)) revert ZeroAddressFactory();
        factory = _factory;
    }

    /// @dev Calculates the salt value used in CREATE2 when
    /// instantiating new templates. the salt is calculated as
    /// keccak256(abi.encodePacked(`_description`, `_initializationData`, `_oraclesInitializationData`)).
    /// @param _description An IPFS cid pointing to a structured JSON describing what the KPI token is about.
    /// @param _initializationData The template-specific ABI-encoded initialization data.
    /// @param _oraclesInitializationData The initialization data required by the template to initialize
    /// the linked oracles.
    /// @return The salt value.
    function salt(
        string calldata _description,
        bytes calldata _initializationData,
        bytes calldata _oraclesInitializationData
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _description,
                    _initializationData,
                    _oraclesInitializationData
                )
            );
    }

    /// @dev Predicts a KPI token template instance address based on the input data.
    /// @param _id The id of the template that is to be instantiated.
    /// @param _description An IPFS cid pointing to a structured JSON describing what the KPI token is about.
    /// @param _initializationData The template-specific ABI-encoded initialization data.
    /// @param _oraclesInitializationData The initialization data required by the template to initialize
    /// the linked oracles.
    /// @return The address at which the template with the given input
    /// parameters will be instantiated.
    function predictInstanceAddress(
        uint256 _id,
        string calldata _description,
        bytes calldata _initializationData,
        bytes calldata _oraclesInitializationData
    ) external view override returns (address) {
        return
            Clones.predictDeterministicAddress(
                storageTemplate(_id).addrezz,
                salt(
                    _description,
                    _initializationData,
                    _oraclesInitializationData
                )
            );
    }

    /// @dev Instantiates a given template using EIP 1167 minimal proxies.
    /// The input data will both be used to choose the instantiated template
    /// and to feed it initialization data.
    /// @param _id The id of the template that is to be instantiated.
    /// @param _description An IPFS cid pointing to a structured JSON describing what the KPI token is about.
    /// @param _initializationData The template-specific ABI-encoded initialization data.
    /// @param _oraclesInitializationData The initialization data required by the template to initialize
    /// the linked oracles.
    /// @return The address at which the template with the given input
    /// parameters has been instantiated.
    function instantiate(
        uint256 _id,
        string calldata _description,
        bytes calldata _initializationData,
        bytes calldata _oraclesInitializationData
    ) external override returns (address) {
        if (msg.sender != factory) revert Forbidden();
        return
            Clones.cloneDeterministic(
                storageTemplate(_id).addrezz,
                salt(
                    _description,
                    _initializationData,
                    _oraclesInitializationData
                )
            );
    }

    /// @dev Adds a template to the registry. This function can only be called
    /// by the contract owner (governance).
    /// @param _template The template's address.
    /// @param _specification An IPFS cid pointing to a structured JSON
    /// describing the template.
    function addTemplate(address _template, string calldata _specification)
        external
        override
    {
        if (msg.sender != owner()) revert Forbidden();
        if (_template == address(0)) revert ZeroAddressTemplate();
        if (bytes(_specification).length == 0) revert InvalidSpecification();
        uint256 _id = templates.ids++;
        templates.map[_id] = IKPITokensManager.Template({
            id: _id,
            addrezz: _template,
            version: IKPITokensManager.Version({major: 1, minor: 0, patch: 0}),
            specification: _specification,
            exists: true
        });
        templates.keys.push(_id);
    }

    /// @dev Removes a template from the registry. This function can only be called
    /// by the contract owner (governance).
    /// @param _id The id of the template that must be removed.
    function removeTemplate(uint256 _id) external override {
        if (msg.sender != owner()) revert Forbidden();
        IKPITokensManager.Template
            storage _templateFromStorage = storageTemplate(_id);
        delete _templateFromStorage.exists;
        uint256 _keysLength = templates.keys.length;
        for (uint256 _i = 0; _i < _keysLength; _i++)
            if (templates.keys[_i] == _id) {
                if (_i != _keysLength - 1)
                    templates.keys[_i] = templates.keys[_keysLength - 1];
                templates.keys.pop();
                return;
            }
        revert NoKeyForTemplate();
    }

    /// @dev Upgrades a template. This function can only be called by the contract owner (governance).
    /// @param _id The id of the template that needs to be upgraded.
    /// @param _newTemplate The new address of the template.
    /// @param _versionBump A bitmask describing the version bump to be applied (major, minor, patch).
    /// @param _newSpecification The updated specification for the upgraded template.
    function upgradeTemplate(
        uint256 _id,
        address _newTemplate,
        uint8 _versionBump,
        string calldata _newSpecification
    ) external override {
        if (msg.sender != owner()) revert Forbidden();
        if (_newTemplate == address(0)) revert ZeroAddressTemplate();
        if (bytes(_newSpecification).length == 0) revert InvalidSpecification();
        IKPITokensManager.Template
            storage _templateFromStorage = storageTemplate(_id);
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
    }

    /// @dev Updates a template specification. The specification is an IPFS cid
    /// pointing to a structured JSON file containing data about the template.
    /// This function can only be called by the contract owner (governance).
    /// @param _id The template's id.
    /// @param _newSpecification The updated specification for the template with id `_id`.
    function updateTemplateSpecification(
        uint256 _id,
        string calldata _newSpecification
    ) external override {
        if (msg.sender != owner()) revert Forbidden();
        if (bytes(_newSpecification).length == 0) revert InvalidSpecification();
        storageTemplate(_id).specification = _newSpecification;
    }

    /// @dev Gets a template from storage.
    /// @param _id The id of the template that needs to be fetched.
    /// @return The template from storage with id `_id`.
    function storageTemplate(uint256 _id)
        internal
        view
        returns (IKPITokensManager.Template storage)
    {
        IKPITokensManager.Template storage _template = templates.map[_id];
        if (!_template.exists) revert NonExistentTemplate();
        return _template;
    }

    /// @dev Gets a template by id.
    /// @param _id The id of the template that needs to be fetched.
    /// @return The template with id `_id`.
    function template(uint256 _id)
        external
        view
        override
        returns (IKPITokensManager.Template memory)
    {
        return storageTemplate(_id);
    }

    /// @dev Gets the amount of all registered templates.
    /// @return The templates amount.
    function templatesAmount() external view override returns (uint256) {
        return templates.keys.length;
    }

    /// @dev Gets a templates slice based on indexes.
    /// @param _fromIndex The index from which to get templates.
    /// @param _toIndex The maximum index to which to get templates.
    /// @return A templates array representing the slice taken through the given indexes.
    function enumerate(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        override
        returns (IKPITokensManager.Template[] memory)
    {
        if (_toIndex > templates.keys.length || _fromIndex > _toIndex)
            revert InvalidIndices();
        uint256 _range = _toIndex - _fromIndex;
        IKPITokensManager.Template[]
            memory _templates = new IKPITokensManager.Template[](_range);
        for (uint256 _i = 0; _i < _range; _i++)
            _templates[_i] = templates.map[templates.keys[_fromIndex + _i]];
        return _templates;
    }
}

pragma solidity 0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IKPIToken} from "./interfaces/kpi-tokens/IKPIToken.sol";
import {IOracle} from "./interfaces/oracles/IOracle.sol";
import {IKPITokensManager} from "./interfaces/IKPITokensManager.sol";

/**
 * @title KPITokensManager
 * @dev KPITokensManager contract
 * @author Federico Luzzi - <federico.luzzi@protonmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
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

    function updateTemplateSpecification(
        uint256 _id,
        string calldata _newSpecification
    ) external override {
        if (msg.sender != owner()) revert Forbidden();
        if (bytes(_newSpecification).length == 0) revert InvalidSpecification();
        storageTemplate(_id).specification = _newSpecification;
    }

    function storageTemplate(uint256 _id)
        internal
        view
        returns (IKPITokensManager.Template storage)
    {
        IKPITokensManager.Template storage _template = templates.map[_id];
        if (!_template.exists) revert NonExistentTemplate();
        return _template;
    }

    function template(uint256 _id)
        external
        view
        override
        returns (IKPITokensManager.Template memory)
    {
        return storageTemplate(_id);
    }

    function templatesAmount() external view override returns (uint256) {
        return templates.keys.length;
    }

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

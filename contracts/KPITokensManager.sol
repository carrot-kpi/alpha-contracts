pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@jolt-network/contracts/interfaces/IJobsRegistry.sol";
import "./interfaces/kpi-tokens/IKPIToken.sol";
import "./interfaces/oracles/IOracle.sol";
import "./interfaces/IKPITokensManager.sol";
import "./libraries/KpiTokenTemplateSetLibrary.sol";

/**
 * @title KPITokensManager
 * @dev KPITokensManager contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
contract KPITokensManager is Ownable, IKPITokensManager {
    using SafeERC20 for IERC20;
    using KpiTokenTemplateSetLibrary for IKPITokensManager.EnumerableTemplateSet;

    address public factory;
    IKPITokensManager.EnumerableTemplateSet private templates;

    error ZeroAddressFactory();
    error Forbidden();
    error InvalidTemplate();

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
                templates.get(_id).addrezz,
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
                templates.get(_id).addrezz,
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
        templates.add(_template, _specification);
    }

    function removeTemplate(uint256 _id) external override {
        if (msg.sender != owner()) revert Forbidden();
        templates.remove(_id);
    }

    function upgradeTemplate(
        uint256 _id,
        address _newTemplate,
        uint8 _versionBump,
        string calldata _newSpecification
    ) external override {
        if (msg.sender != owner()) revert Forbidden();
        templates.upgrade(_id, _newTemplate, _versionBump, _newSpecification);
    }

    function updateTemplateSpecification(
        uint256 _id,
        string calldata _newSpecification
    ) external override {
        if (msg.sender != owner()) revert Forbidden();
        templates.get(_id).specification = _newSpecification;
    }

    function template(uint256 _id)
        external
        view
        override
        returns (IKPITokensManager.Template memory)
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
        returns (IKPITokensManager.Template[] memory)
    {
        return templates.enumerate(_fromIndex, _toIndex);
    }
}

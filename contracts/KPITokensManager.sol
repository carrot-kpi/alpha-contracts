pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@xcute/contracts/interfaces/IJobsRegistry.sol";
import "./interfaces/kpi-tokens/IKPIToken.sol";
import "./interfaces/oracles/IOracle.sol";
import "./interfaces/IKPITokensManager.sol";
import "./libraries/TemplateSetLibrary.sol";
import "./commons/Types.sol";

/**
 * @title KPITokensManager
 * @dev KPITokensManager contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
contract KPITokensManager is Ownable, IKPITokensManager {
    using SafeERC20 for IERC20;
    using TemplateSetLibrary for EnumerableTemplateSet;

    address public factory;
    EnumerableTemplateSet private templates;

    error ZeroAddressFactory();
    error Forbidden();
    error InvalidTemplate();

    constructor(address _factory) {
        if (_factory == address(0)) revert ZeroAddressFactory();
        factory = _factory;
    }

    function salt(bytes memory _initializationData)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(_initializationData);
    }

    function predictInstanceAddress(
        address _template,
        bytes calldata _initializationData
    ) external view returns (address) {
        return
            Clones.predictDeterministicAddress(
                _template,
                salt(_initializationData),
                address(this)
            );
    }

    function instantiate(address _template, bytes calldata _initializationData)
        external
        returns (address)
    {
        if (msg.sender != factory) revert Forbidden();
        if (!templates.contains(_template)) revert InvalidTemplate();
        return Clones.cloneDeterministic(_template, salt(_initializationData));
    }

    function addTemplate(
        address _template,
        bool _automatable,
        string calldata _description
    ) external {
        templates.add(_template, _automatable, _description);
    }

    function removeTemplate(address _template) external {
        if (msg.sender != owner()) revert Forbidden();
        templates.remove(_template);
    }

    function upgradeTemplate(
        address _template,
        address _newTemplate,
        string memory _newDescription
    ) external {
        if (msg.sender != owner()) revert Forbidden();
        templates.upgrade(_template, _newTemplate, _newDescription);
    }

    function updateTemplateDescription(
        address _template,
        string calldata _newDescription
    ) external override {
        if (msg.sender != owner()) revert Forbidden();
        Template storage _templateFromStorage = templates.get(_template);
        _templateFromStorage.description = _newDescription;
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

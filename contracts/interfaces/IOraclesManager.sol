pragma solidity ^0.8.11;

import "../commons/Types.sol";

/**
 * @title IOraclesManager
 * @dev IOraclesManager contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
interface IOraclesManager {
    struct Template {
        string specification;
        bool automatable;
    }

    struct TemplateWithAddress {
        address addrezz;
        string specification;
        bool automatable;
    }

    struct EnumerableTemplateSet {
        mapping(address => Template) map;
        address[] keys;
    }

    function predictInstanceAddress(
        address _template,
        address _automationFundingToken,
        uint256 _automationFundingAmount,
        bytes memory _initializationData
    ) external view returns (address);

    function instantiate(
        address _template,
        address _automationFundingToken,
        uint256 _automationFundingAmount,
        bytes memory _initializationData
    ) external returns (address);

    function addTemplate(
        address _template,
        bool _automatable,
        string calldata _specification
    ) external;

    function removeTemplate(address _template) external;

    function updgradeTemplate(
        address _template,
        address _newTemplate,
        string calldata _newSpecification
    ) external;

    function updateTemplateSpecification(
        address _template,
        string calldata _newSpecification
    ) external;

    function template(address _template)
        external
        view
        returns (TemplateWithAddress memory);

    function templatesAmount() external view returns (uint256);

    function templatesSlice(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        returns (TemplateWithAddress[] memory);
}

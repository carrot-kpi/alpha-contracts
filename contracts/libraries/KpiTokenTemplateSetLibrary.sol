pragma solidity ^0.8.11;

import "../interfaces/IKPITokensManager.sol";

/**
 * @title KpiTokenTemplateSetLibrary
 * @dev A library to handle KPI token templates changes/updates.
 * @author Federico Luzzi <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
library KpiTokenTemplateSetLibrary {
    error ZeroAddressTemplate();
    error InvalidSpecification();
    error TemplateAlreadyAdded();
    error NonExistentTemplate();
    error NoKeyForTemplate();
    error NotAnUpgrade();
    error InvalidIndices();

    function contains(
        IKPITokensManager.EnumerableTemplateSet storage _self,
        address _template
    ) public view returns (bool) {
        return
            _template != address(0) &&
            bytes(_self.map[_template].specification).length != 0;
    }

    function get(
        IKPITokensManager.EnumerableTemplateSet storage _self,
        address _template
    ) public view returns (IKPITokensManager.Template storage) {
        if (!contains(_self, _template)) revert NonExistentTemplate();
        return _self.map[_template];
    }

    function add(
        IKPITokensManager.EnumerableTemplateSet storage _self,
        address _template,
        string calldata _specification
    ) public {
        if (bytes(_specification).length == 0) revert InvalidSpecification();
        IKPITokensManager.Template storage _templateFromStorage = get(
            _self,
            _template
        );
        _templateFromStorage.specification = _specification;
        _self.keys.push(_template);
    }

    function remove(
        IKPITokensManager.EnumerableTemplateSet storage _self,
        address _template
    ) public {
        IKPITokensManager.Template storage _templateFromStorage = get(
            _self,
            _template
        );
        delete _templateFromStorage.specification;
        uint256 _keysLength = _self.keys.length;
        for (uint256 _i = 0; _i < _keysLength; _i++)
            if (_self.keys[_i] == _template) {
                if (_i != _keysLength - 1)
                    _self.keys[_i] = _self.keys[_keysLength - 1];
                _self.keys.pop();
                return;
            }
        revert NoKeyForTemplate();
    }

    function upgrade(
        IKPITokensManager.EnumerableTemplateSet storage _self,
        address _template,
        address _newTemplate,
        string calldata _newSpecification
    ) external {
        if (bytes(_newSpecification).length == 0) revert InvalidSpecification();
        if (_template == _newTemplate) revert NotAnUpgrade();
        IKPITokensManager.Template storage _templateFromStorage = get(
            _self,
            _template
        );
        if (
            keccak256(bytes(_templateFromStorage.specification)) ==
            keccak256(bytes(_newSpecification))
        ) revert InvalidSpecification();
        remove(_self, _template);
        add(_self, _newTemplate, _newSpecification);
    }

    function size(IKPITokensManager.EnumerableTemplateSet storage _self)
        external
        view
        returns (uint256)
    {
        return _self.keys.length;
    }

    function enumerate(
        IKPITokensManager.EnumerableTemplateSet storage _self,
        uint256 _fromIndex,
        uint256 _toIndex
    ) external view returns (IKPITokensManager.TemplateWithAddress[] memory) {
        if (_toIndex > _self.keys.length || _fromIndex > _toIndex)
            revert InvalidIndices();
        uint256 _range = _toIndex - _fromIndex;
        IKPITokensManager.TemplateWithAddress[]
            memory _templates = new IKPITokensManager.TemplateWithAddress[](
                _range
            );
        for (uint256 _i = 0; _i < _range; _i++) {
            address _templateAddress = _self.keys[_fromIndex + _i];
            IKPITokensManager.Template storage _template = _self.map[
                _templateAddress
            ];
            _templates[_i] = IKPITokensManager.TemplateWithAddress({
                addrezz: _templateAddress,
                specification: _template.specification
            });
        }
        return _templates;
    }
}

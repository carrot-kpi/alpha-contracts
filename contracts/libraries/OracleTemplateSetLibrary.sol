pragma solidity ^0.8.11;

import "../interfaces/IOraclesManager.sol";

/**
 * @title TemplateSetLibrary
 * @dev A library to handle template changes/updates.
 * @author Federico Luzzi <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
library OracleTemplateSetLibrary {
    struct KpiTokenTemplateWithAddress {
        address addrezz;
        string specification;
        bool automatable;
    }

    error ZeroAddressTemplate();
    error InvalidSpecification();
    error TemplateAlreadyAdded();
    error NonExistentTemplate();
    error NoKeyForTemplate();
    error NotAnUpgrade();
    error InvalidIndices();

    function contains(
        IOraclesManager.EnumerableTemplateSet storage _self,
        address _template
    ) public view returns (bool) {
        return
            _template != address(0) &&
            bytes(_self.map[_template].specification).length != 0;
    }

    function get(
        IOraclesManager.EnumerableTemplateSet storage _self,
        address _template
    ) public view returns (IOraclesManager.Template storage) {
        if (!contains(_self, _template)) revert NonExistentTemplate();
        return _self.map[_template];
    }

    function add(
        IOraclesManager.EnumerableTemplateSet storage _self,
        address _template,
        bool _automatable,
        string calldata _specification
    ) public {
        if (bytes(_specification).length == 0) revert InvalidSpecification();
        IOraclesManager.Template storage _templateFromStorage = get(
            _self,
            _template
        );
        _templateFromStorage.specification = _specification;
        _templateFromStorage.automatable = _automatable;
        _self.keys.push(_template);
    }

    function remove(
        IOraclesManager.EnumerableTemplateSet storage _self,
        address _template
    ) public {
        IOraclesManager.Template storage _templateFromStorage = get(
            _self,
            _template
        );
        delete _templateFromStorage.specification;
        delete _templateFromStorage.automatable;
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
        IOraclesManager.EnumerableTemplateSet storage _self,
        address _template,
        address _newTemplate,
        string calldata _newSpecification
    ) external {
        if (bytes(_newSpecification).length == 0) revert InvalidSpecification();
        if (_template == _newTemplate) revert NotAnUpgrade();
        IOraclesManager.Template storage _templateFromStorage = get(
            _self,
            _template
        );
        if (
            keccak256(bytes(_templateFromStorage.specification)) ==
            keccak256(bytes(_newSpecification))
        ) revert InvalidSpecification();
        remove(_self, _template);
        add(
            _self,
            _newTemplate,
            _templateFromStorage.automatable,
            _newSpecification
        );
    }

    function size(IOraclesManager.EnumerableTemplateSet storage _self)
        external
        view
        returns (uint256)
    {
        return _self.keys.length;
    }

    function enumerate(
        IOraclesManager.EnumerableTemplateSet storage _self,
        uint256 _fromIndex,
        uint256 _toIndex
    ) external view returns (IOraclesManager.TemplateWithAddress[] memory) {
        if (_toIndex > _self.keys.length || _fromIndex > _toIndex)
            revert InvalidIndices();
        uint256 _range = _toIndex - _fromIndex;
        IOraclesManager.TemplateWithAddress[]
            memory _templates = new IOraclesManager.TemplateWithAddress[](
                _range
            );
        for (uint256 _i = 0; _i < _range; _i++) {
            address _templateAddress = _self.keys[_fromIndex + _i];
            IOraclesManager.Template storage _template = _self.map[
                _templateAddress
            ];
            _templates[_i] = IOraclesManager.TemplateWithAddress({
                addrezz: _templateAddress,
                specification: _template.specification,
                automatable: _template.automatable
            });
        }
        return _templates;
    }
}

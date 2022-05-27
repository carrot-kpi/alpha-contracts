pragma solidity 0.8.14;

import {Ownable} from "oz/access/Ownable.sol";
import {Clones} from "oz/proxy/Clones.sol";
import {IKPITokensFactory} from "./interfaces/IKPITokensFactory.sol";
import {IKPITokensManager} from "./interfaces/IKPITokensManager.sol";
import {IOraclesManager} from "./interfaces/IOraclesManager.sol";
import {IKPIToken} from "./interfaces/kpi-tokens/IKPIToken.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI tokens factory
/// @dev The factory contract acts as an entry point for users wanting to
/// create a KPI token., passing as input the id of the template that is
/// to be used, alongside the description's IPFS cid (pointing to a
/// structured JSON describing what the KPI token is about) and the oracles
/// initialization data (template-specific). Other utility view functions
/// are included to query the storage of the contract.
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract KPITokensFactory is Ownable, IKPITokensFactory {
    address public kpiTokensManager;
    address public oraclesManager;
    address public feeReceiver;
    mapping(address => bool) public allowOraclesCreation;
    address[] internal kpiTokens;

    error Forbidden();
    error ZeroAddressKpiTokensManager();
    error ZeroAddressOraclesManager();
    error ZeroAddressFeeReceiver();
    error InvalidIndices();

    constructor(
        address _kpiTokensManager,
        address _oraclesManager,
        address _feeReceiver
    ) {
        if (_kpiTokensManager == address(0))
            revert ZeroAddressKpiTokensManager();
        if (_oraclesManager == address(0)) revert ZeroAddressOraclesManager();
        if (_feeReceiver == address(0)) revert ZeroAddressFeeReceiver();

        kpiTokensManager = _kpiTokensManager;
        oraclesManager = _oraclesManager;
        feeReceiver = _feeReceiver;
    }

    /// @dev Creates a KPI token with the input data.
    /// @param _id The id of the KPI token template to be used.
    /// @param _description An IPFS cid pointing to a structured JSON describing what the KPI token is about.
    /// @param _initializationData The template-specific ABI-encoded initialization data.
    /// @param _oraclesInitializationData The initialization data required by the template to initialize
    /// the linked oracles.
    function createToken(
        uint256 _id,
        string calldata _description,
        bytes calldata _initializationData,
        bytes calldata _oraclesInitializationData
    ) external override {
        address _instance = IKPITokensManager(kpiTokensManager).instantiate(
            _id,
            _description,
            _initializationData,
            _oraclesInitializationData
        );
        IKPIToken(_instance).initialize(
            msg.sender,
            kpiTokensManager,
            _id,
            _description,
            _initializationData
        );
        allowOraclesCreation[_instance] = true;
        IKPIToken(_instance).initializeOracles(
            oraclesManager,
            _oraclesInitializationData
        );
        allowOraclesCreation[_instance] = false;
        IKPIToken(_instance).collectProtocolFees(feeReceiver);
        kpiTokens.push(_instance);
    }

    /// @dev KPI tokens manager address setter. Can only be called by the contract owner.
    /// @param _kpiTokensManager The new KPI tokens manager address.
    function setKpiTokensManager(address _kpiTokensManager) external {
        if (msg.sender != owner()) revert Forbidden();
        if (_kpiTokensManager == address(0))
            revert ZeroAddressKpiTokensManager();
        kpiTokensManager = _kpiTokensManager;
    }

    /// @dev Oracles manager address setter. Can only be called by the contract owner.
    /// @param _oraclesManager The new oracles manager address.
    function setOraclesManager(address _oraclesManager) external {
        if (msg.sender != owner()) revert Forbidden();
        if (_oraclesManager == address(0)) revert ZeroAddressOraclesManager();
        oraclesManager = _oraclesManager;
    }

    /// @dev Fee receiver address setter. Can only be called by the contract owner.
    /// @param _feeReceiver The new fee receiver address.
    function setFeeReceiver(address _feeReceiver) external {
        if (msg.sender != owner()) revert Forbidden();
        if (_feeReceiver == address(0)) revert ZeroAddressFeeReceiver();
        feeReceiver = _feeReceiver;
    }

    /// @dev Gets the amount of all created KPI tokens.
    /// @return The KPI tokens amount.
    function kpiTokensAmount() external view override returns (uint256) {
        return kpiTokens.length;
    }

    /// @dev Gets a KPI tokens slice based on indexes.
    /// @param _fromIndex The index from which to get KPI tokens.
    /// @param _toIndex The maximum index to which to get KPI tokens.
    /// @return An address array representing the slice taken between the given indexes.
    function enumerate(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        override
        returns (address[] memory)
    {
        if (_toIndex > kpiTokens.length || _fromIndex > _toIndex)
            revert InvalidIndices();
        uint256 _range = _toIndex - _fromIndex;
        address[] memory _kpiTokens = new address[](_range);
        for (uint256 _i = 0; _i < _range; _i++)
            _kpiTokens[_i] = kpiTokens[_fromIndex + _i];
        return _kpiTokens;
    }
}

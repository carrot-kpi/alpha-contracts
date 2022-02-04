pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/IKPITokensFactory.sol";
import "./interfaces/IKPITokensManager.sol";
import "./interfaces/IOraclesManager.sol";
import "./interfaces/kpi-tokens/IKPIToken.sol";

/**
 * @title KPITokensFactory
 * @dev KPITokensFactory contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
contract KPITokensFactory is Ownable, IKPITokensFactory {
    using SafeERC20 for IERC20;

    address public kpiTokensManager;
    address public oraclesManager;
    address public feeReceiver;
    mapping(address => bool) public created;
    address[] kpiTokens;

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

    function createToken(
        uint256 _id,
        string memory _description,
        bytes memory _initializationData,
        bytes memory _oraclesInitializationData
    ) external override {
        address _instance = IKPITokensManager(kpiTokensManager).instantiate(
            _id,
            _description,
            _initializationData,
            _oraclesInitializationData
        );
        IKPIToken(_instance).initialize(
            msg.sender,
            IKPITokensManager(kpiTokensManager).template(_id),
            _description,
            _initializationData
        );
        created[_instance] = true;
        IKPIToken(_instance).initializeOracles(
            oraclesManager,
            _oraclesInitializationData
        );
        IKPIToken(_instance).collectProtocolFees(feeReceiver);
        kpiTokens.push(_instance);
    }

    function setKpiTokensManager(address _kpiTokensManager) external {
        if (msg.sender != owner()) revert Forbidden();
        if (_kpiTokensManager == address(0))
            revert ZeroAddressKpiTokensManager();
        kpiTokensManager = _kpiTokensManager;
    }

    function setOraclesManager(address _oraclesManager) external {
        if (msg.sender != owner()) revert Forbidden();
        if (_oraclesManager == address(0)) revert ZeroAddressOraclesManager();
        oraclesManager = _oraclesManager;
    }

    function setFeeReceiver(address _feeReceiver) external {
        if (msg.sender != owner()) revert Forbidden();
        if (_feeReceiver == address(0)) revert ZeroAddressFeeReceiver();
        feeReceiver = _feeReceiver;
    }

    function size() external view override returns (uint256) {
        return kpiTokens.length;
    }

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
        for (uint256 _i = _fromIndex; _i < _fromIndex + _range; _i++)
            _kpiTokens[_i] = kpiTokens[_i];
        return _kpiTokens;
    }
}

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/IReality.sol";
import "./interfaces/IKPIToken.sol";

error ZeroAddressKpiTokenImplementation();
error ZeroAddressOracle();
error ZeroAddressFeeReceiver();
error InvalidRealityQuestion();
error InvalidRealityExpiry();
error ZeroAddressRealityArbitrator();
error ZeroAddressCollateralToken();
error InvalidCollateralAmount();
error InvalidTokenName();
error InvalidTokenSymbol();
error ZeroTotalSupply();
error InvalidScalarRange();

/**
 * @title KPITokensFactory
 * @dev KPITokensFactory contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract KPITokensFactory is Ownable {
    using SafeERC20 for IERC20;

    struct RealityConfig {
        string question;
        uint32 expiry;
        uint32 timeout;
        address arbitrator;
    }

    uint16 public fee;
    address public kpiTokenImplementation;
    address public feeReceiver;
    IReality public oracle;

    event KpiTokenCreated(
        address kpiToken,
        uint256 feeAmount,
        uint32 kpiExpiry
    );
    event KpiTokenImplementationUpgraded(address implementation);
    event FeeUpdated(uint fee);
    event FeeReceiverUpdated(address feeReceiver);

    constructor(
        address _kpiTokenImplementation,
        address _oracle,
        uint16 _fee,
        address _feeReceiver
    ) {
        if(_kpiTokenImplementation == address(0)) revert ZeroAddressKpiTokenImplementation();
        if(_oracle == address(0)) revert ZeroAddressOracle();
        if(_feeReceiver == address(0)) revert ZeroAddressFeeReceiver();
        kpiTokenImplementation = _kpiTokenImplementation;
        oracle = IReality(_oracle);
        fee = _fee;
        feeReceiver = _feeReceiver;
    }

    function upgradeKpiTokenImplementation(address _kpiTokenImplementation)
        external
        onlyOwner
    {
        if(_kpiTokenImplementation == address(0)) revert ZeroAddressKpiTokenImplementation();
        kpiTokenImplementation = _kpiTokenImplementation;
        emit KpiTokenImplementationUpgraded(_kpiTokenImplementation);
    }

    function setFee(uint16 _fee) external onlyOwner {
        fee = _fee;
        emit FeeUpdated(_fee);
    }

    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        if(_feeReceiver == address(0)) revert ZeroAddressFeeReceiver();
        feeReceiver = _feeReceiver;
        emit FeeReceiverUpdated(_feeReceiver);
    }

    function createKpiToken(
        RealityConfig calldata _realityConfig,
        IKPIToken.Collateral calldata _collateral,
        IKPIToken.TokenData calldata _tokenData,
        IKPIToken.ScalarData calldata _scalarData
    ) external {
        if(bytes(_realityConfig.question).length == 0)revert InvalidRealityQuestion();
        if(_realityConfig.expiry <= block.timestamp) revert InvalidRealityExpiry();
        if(_realityConfig.arbitrator == address(0)) revert ZeroAddressRealityArbitrator();
        if(_collateral.token == address(0)) revert ZeroAddressCollateralToken();
        if(_collateral.amount == 0) revert InvalidCollateralAmount();
        if(bytes(_tokenData.name).length == 0) revert InvalidTokenName();
        if(bytes(_tokenData.symbol).length == 0) revert InvalidTokenSymbol();
        if(_tokenData.totalSupply == 0) revert ZeroTotalSupply();
        if(_scalarData.lowerBound >= _scalarData.higherBound) revert InvalidScalarRange();

        address _kpiTokenProxy = Clones.clone(kpiTokenImplementation);
        uint256 _feeAmount = (_collateral.amount * fee) / 10000;
        IERC20(_collateral.token).safeTransferFrom(
            msg.sender,
            feeReceiver,
            _feeAmount
        );
        IERC20(_collateral.token).safeTransferFrom(
            msg.sender,
            _kpiTokenProxy,
            _collateral.amount
        );
        bytes32 _kpiId =
            oracle.askQuestion(
                _scalarData.lowerBound == 0 && _scalarData.higherBound == 1
                    ? 0
                    : 1,
                _realityConfig.question,
                _realityConfig.arbitrator,
                _realityConfig.timeout,
                _realityConfig.expiry,
                0
            );
        IKPIToken(_kpiTokenProxy).initialize(
            _kpiId,
            address(oracle),
            msg.sender,
            _collateral,
            _tokenData,
            _scalarData
        );
        emit KpiTokenCreated(_kpiTokenProxy, _feeAmount, _realityConfig.expiry);
    }
}

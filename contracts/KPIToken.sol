pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IReality.sol";
import "./interfaces/IKPIToken.sol";

error NotEnoughCollateralBalance();
error AlreadyFinalized();
error NonFinalizedOracle();
error NotFinalized();
error NoKpiTokenBalance();

/**
 * @title KPIToken
 * @dev KPIToken contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract KPIToken is Initializable, ERC20Upgradeable, IKPIToken {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public immutable INVALID_ANSWER = 2**256 - 1;

    bytes32 public kpiId;
    IReality public oracle;
    IERC20Upgradeable public collateralToken;
    address public creator;
    bool public finalized;
    uint256 public collateralAmount;
    uint256 public minPayoutAmount;
    uint256 public initialSupply;
    uint256 public finalKpiProgress;
    ScalarData public scalarData;

    event Initialized(
        bytes32 kpiId,
        address oracle,
        address creator,
        Collateral collateral,
        TokenData tokenData,
        ScalarData scalarData
    );
    event Finalized(uint256 finalKpiProgress);
    event Redeemed(uint256 burnedTokens, uint256 redeemedCollateral);

    function initialize(
        bytes32 _kpiId,
        address _oracle,
        address _creator,
        Collateral calldata _collateral,
        TokenData calldata _tokenData,
        ScalarData calldata _scalarData
    ) external override initializer {
        if (
            IERC20Upgradeable(_collateral.token).balanceOf(address(this)) <
            _collateral.amount || _collateral.minPayoutAmount >
            _collateral.amount
        ) revert NotEnoughCollateralBalance();

        __ERC20_init(_tokenData.name, _tokenData.symbol);
        _mint(_creator, _tokenData.totalSupply);
        initialSupply = _tokenData.totalSupply;
        kpiId = _kpiId;
        oracle = IReality(_oracle);
        collateralToken = IERC20Upgradeable(_collateral.token);
        creator = _creator;
        scalarData = _scalarData;
        collateralAmount = _collateral.amount;
        minPayoutAmount = _collateral.minPayoutAmount;

        emit Initialized(
            _kpiId,
            _oracle,
            _creator,
            _collateral,
            _tokenData,
            _scalarData
        );
    }

    function finalize() external override {
        if (finalized) revert AlreadyFinalized();
        if (!oracle.isFinalized(kpiId)) revert NonFinalizedOracle();
        uint256 _oracleResult = uint256(oracle.resultFor(kpiId));
        if (
            _oracleResult <= scalarData.lowerBound ||
            _oracleResult == INVALID_ANSWER
        ) {
            // kpi below the lower bound or invalid, transfer funds back to creator
            finalKpiProgress = 0;
            collateralToken.safeTransfer(creator, collateralAmount - minPayoutAmount);
        } else {
            uint256 _kpiFullRange = scalarData.higherBound -
                scalarData.lowerBound;
            finalKpiProgress = _oracleResult >= scalarData.higherBound
                ? _kpiFullRange
                : _oracleResult - scalarData.lowerBound;
            // transfer the unnecessary collateral back to the KPI creator
            if (finalKpiProgress < _kpiFullRange) {
                collateralToken.safeTransfer(
                    creator,
                    ((collateralAmount - minPayoutAmount) * (_kpiFullRange - finalKpiProgress)) /
                        _kpiFullRange
                );
            }
        }
        finalized = true;
        emit Finalized(finalKpiProgress);
    }

    function redeem() external override {
        if (!finalized) revert NotFinalized();
        uint256 _kpiTokenBalance = balanceOf(msg.sender);
        if (_kpiTokenBalance == 0) revert NoKpiTokenBalance();
        _burn(msg.sender, _kpiTokenBalance);
        uint256 _redeemableBaseAmount = (minPayoutAmount * _kpiTokenBalance ) / (initialSupply);
        if (finalKpiProgress == 0) {          
            if (_redeemableBaseAmount > 0){
                collateralToken.safeTransfer(msg.sender, _redeemableBaseAmount);
            }
            emit Redeemed(_kpiTokenBalance, _redeemableBaseAmount);
            return;
        }
        uint256 _scalarRange = scalarData.higherBound - scalarData.lowerBound;
        uint256 _redeemableScalableAmount = ((collateralAmount - minPayoutAmount) * _kpiTokenBalance * finalKpiProgress) / (initialSupply * _scalarRange);
        collateralToken.safeTransfer(msg.sender, _redeemableBaseAmount + _redeemableScalableAmount);
        emit Redeemed(_kpiTokenBalance, _redeemableBaseAmount + _redeemableScalableAmount);
    }
}

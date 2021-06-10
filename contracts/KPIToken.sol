pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IReality.sol";
import "./interfaces/IKPIToken.sol";

/**
 * @title KPIToken
 * @dev KPIToken contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract KPIToken is Initializable, ERC20Upgradeable, IKPIToken {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant INVALID_ANSWER = 2**256 - 1;

    bytes32 public kpiId;
    IReality public oracle;
    IERC20Upgradeable public collateralToken;
    address public creator;
    uint256 public finalKpiProgress;
    bool public finalized;
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
        require(
            IERC20Upgradeable(_collateral.token).balanceOf(address(this)) >=
                _collateral.amount,
            "KT01"
        );

        __ERC20_init(_tokenData.name, _tokenData.symbol);
        _mint(_creator, _tokenData.totalSupply);
        kpiId = _kpiId;
        oracle = IReality(_oracle);
        collateralToken = IERC20Upgradeable(_collateral.token);
        creator = _creator;
        scalarData = _scalarData;

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
        require(!finalized, "KT02");
        require(oracle.isFinalized(kpiId), "KT03");
        uint256 _oracleResult = uint256(oracle.resultFor(kpiId));
        if (
            _oracleResult <= scalarData.lowerBound ||
            _oracleResult == INVALID_ANSWER
        ) {
            // kpi below the lower bound or invalid, transfer funds back to creator
            finalKpiProgress = 0;
            collateralToken.safeTransfer(
                creator,
                collateralToken.balanceOf(address(this))
            );
        } else {
            uint256 _kpiFullRange =
                scalarData.higherBound - scalarData.lowerBound;
            finalKpiProgress = _oracleResult >= scalarData.higherBound
                ? _kpiFullRange
                : _oracleResult - scalarData.lowerBound;
            // transfer the unnecessary collateral back to the KPI creator
            if (finalKpiProgress < _kpiFullRange) {
                collateralToken.safeTransfer(
                    creator,
                    (collateralToken.balanceOf(address(this)) *
                        (_kpiFullRange - finalKpiProgress)) / _kpiFullRange
                );
            }
        }
        finalized = true;
        emit Finalized(finalKpiProgress);
    }

    function redeem() external override {
        require(finalized, "KT04");
        uint256 _kpiTokenBalance = balanceOf(msg.sender);
        require(_kpiTokenBalance > 0, "KT05");
        if (finalKpiProgress == 0) {
            _burn(msg.sender, _kpiTokenBalance);
            emit Redeemed(_kpiTokenBalance, 0);
            return;
        }
        uint256 _totalSupplyPreBurn = totalSupply();
        _burn(msg.sender, _kpiTokenBalance);
        uint256 _scalarRange = scalarData.higherBound - scalarData.lowerBound;
        uint256 _redeemableAmount =
            (collateralToken.balanceOf(address(this)) *
                _kpiTokenBalance *
                finalKpiProgress) / (_totalSupplyPreBurn * _scalarRange);
        collateralToken.safeTransfer(msg.sender, _redeemableAmount);
        emit Redeemed(_kpiTokenBalance, _redeemableAmount);
    }
}

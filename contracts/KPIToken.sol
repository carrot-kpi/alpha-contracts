pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IReality.sol";

/**
 * @title KPIToken
 * @dev KPIToken contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract KPIToken is Initializable, ERC20Upgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct Collateral {
        address token;
        uint256 initialAmount;
    }

    struct TokenData {
        string name;
        string symbol;
        uint256 totalSupply;
    }

    bytes32 public kpiId;
    IReality public oracle;
    IERC20Upgradeable public collateralToken;
    address public creator;
    bool public kpiReached;
    bool public finalized;

    event Initialized(
        bytes32 kpiId,
        string name,
        string symbol,
        uint256 totalSupply,
        address oracle,
        address collateralToken,
        address creator
    );
    event Finalized(bool response);
    event Redeemed(uint256 burnedTokens, uint256 redeemedCollateral);

    function initialize(
        bytes32 _kpiId,
        address _oracle,
        address _creator,
        Collateral calldata _collateral,
        TokenData calldata _tokenData
    ) external initializer {
        require(
            IERC20Upgradeable(_collateral.token).balanceOf(address(this)) >=
                _collateral.initialAmount,
            "KT06"
        );

        __ERC20_init(_tokenData.name, _tokenData.symbol);
        _mint(_creator, _tokenData.totalSupply);
        kpiId = _kpiId;
        oracle = IReality(_oracle);
        collateralToken = IERC20Upgradeable(_collateral.token);
        creator = _creator;

        emit Initialized(
            _kpiId,
            _tokenData.name,
            _tokenData.symbol,
            _tokenData.totalSupply,
            _oracle,
            _collateral.token,
            _creator
        );
    }

    function finalize() external {
        require(oracle.isFinalized(kpiId), "KT01");
        if (uint256(oracle.resultFor(kpiId)) != 1) {
            collateralToken.safeTransfer(
                creator,
                collateralToken.balanceOf(address(this))
            );
        } else {
            kpiReached = true;
        }
        finalized = true;
        emit Finalized(kpiReached);
    }

    function redeem() external {
        require(finalized, "KT02");
        uint256 _kpiTokenBalance = balanceOf(msg.sender);
        require(_kpiTokenBalance > 0, "KT03");
        if (!kpiReached) {
            _burn(msg.sender, _kpiTokenBalance);
            emit Redeemed(_kpiTokenBalance, 0);
            return;
        }
        uint256 _totalSupplyPreBurn = totalSupply();
        _burn(msg.sender, _kpiTokenBalance);
        uint256 _redeemableAmount =
            (collateralToken.balanceOf(address(this)) * _kpiTokenBalance) /
                _totalSupplyPreBurn;
        collateralToken.safeTransfer(msg.sender, _redeemableAmount);
        emit Redeemed(_kpiTokenBalance, _redeemableAmount);
    }
}

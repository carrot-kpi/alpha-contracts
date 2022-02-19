pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IKPIToken.sol";

/**
 * @title IERC20KPIToken
 * @dev IERC20KPIToken contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
interface IAaveERC20KPIToken is IKPIToken, IERC20Upgradeable {
    struct Collateral {
        address token;
        address aToken;
        uint256 amount;
        uint256 minimumPayout;
    }

    struct FinalizableOracle {
        address addrezz;
        bool finalized;
        uint256 lowerBound;
        uint256 higherBound;
        uint256 finalProgress;
        uint256 weight;
    }

    struct RedeemedCollateral {
        address token;
        uint256 amount;
    }
}

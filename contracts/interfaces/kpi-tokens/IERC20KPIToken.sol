pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IKPIToken.sol";

/**
 * @title IERC20KPIToken
 * @dev IERC20KPIToken contract
 * @author Federico Luzzi - <federico.luzzi@protonmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
interface IERC20KPIToken is IKPIToken, IERC20Upgradeable {
    struct OracleData {
        uint256 templateId;
        uint256 lowerBound;
        uint256 higherBound;
        uint256 weight;
        bytes data;
    }

    struct Collateral {
        address token;
        uint256 amount;
        uint256 minimumPayout;
    }

    struct FinalizableOracle {
        address addrezz;
        uint256 lowerBound;
        uint256 higherBound;
        uint256 finalProgress;
        uint256 weight;
        bool finalized;
    }

    struct RedeemedCollateral {
        address token;
        uint256 amount;
    }
}

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title IKPIToken
 * @dev IKPIToken contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
interface IKPIToken is IERC20Upgradeable {
    struct Collateral {
        address token;
        uint256 amount;
    }

    struct TokenData {
        string name;
        string symbol;
        uint256 totalSupply;
    }

    struct ScalarData {
        uint256 lowerBound;
        uint256 higherBound;
    }

    function initialize(
        bytes32 _kpiId,
        address _oracle,
        address _creator,
        Collateral calldata _collateral,
        TokenData calldata _tokenData,
        ScalarData calldata _scalarData
    ) external;

    function finalize() external;

    function redeem() external;
}

pragma solidity ^0.8.11;

/**
 * @title IERC20Decimals
 * @dev IERC20Decimals contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
interface IERC20Decimals {
    function decimals() external view returns (uint8);
}

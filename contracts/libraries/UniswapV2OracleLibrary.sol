pragma solidity ^0.8.11;

import "../interfaces/external/IUniswapV2Pair.sol";
import "./FixedPointLibrary.sol";

/**
 * @title UniswapV2OracleLibrary
 * @dev A library to facilitate the use of Uniswap-like pools as price oracles.
 * @author Various
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
library UniswapV2OracleLibrary {
    using FixedPointLibrary for *;

    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2**32);
    }

    function currentCumulativePrices(address pair)
        internal
        view
        returns (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        )
    {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        ) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            unchecked {
                // subtraction overflow is desired
                uint32 timeElapsed = blockTimestamp - blockTimestampLast;
                // addition overflow is desired
                // counterfactual
                price0Cumulative +=
                    uint256(FixedPointLibrary.fraction(reserve1, reserve0)._x) *
                    timeElapsed;
                // counterfactual
                price1Cumulative +=
                    uint256(FixedPointLibrary.fraction(reserve0, reserve1)._x) *
                    timeElapsed;
            }
        }
    }
}

pragma solidity ^0.8.11;

import "jolt-network/JobUpgradeable.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "../libraries/FixedPointLibrary.sol";
import "../libraries/UniswapV2OracleLibrary.sol";
import "../interfaces/external/IUniswapV2Pair.sol";
import "../interfaces/oracles/IOracle.sol";
import "../interfaces/IERC20Decimals.sol";
import "../interfaces/kpi-tokens/IKPIToken.sol";

/**
 * @title UniswapV2TWAPOracle
 * @dev UniswapV2TWAPOracle contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
contract UniswapV2TWAPOracle is JobUpgradeable, IOracle {
    using FixedPointLibrary for *;

    struct Observation {
        uint32 timestamp;
        FixedPointLibrary.uq112x112 price;
        uint256 lastCumulative;
    }

    bool public finalized;
    bool internal token0;
    uint8 internal tokenDecimals;
    uint32 internal refreshRate;
    uint64 internal startsAt;
    uint64 internal endsAt;
    address internal pair;
    address public kpiToken;
    Observation internal observation;
    IOraclesManager.Template internal __template;

    error ZeroAddressKpiToken();
    error ZeroAddressPair();
    error InvalidRefreshRate();
    error NoWorkRequired();
    error NoTokenInPair();
    error InvalidStartsAt();
    error InvalidEndsAt();
    error ZeroAddressToken();

    function initialize(
        address _kpiToken,
        IOraclesManager.Template calldata _template,
        bytes calldata _data
    ) external initializer {
        if (_kpiToken == address(0)) revert ZeroAddressKpiToken();

        (
            address _joltJobsRegistry,
            address _pair,
            address _token,
            uint64 _startsAt,
            uint64 _endsAt,
            uint32 _refreshRate
        ) = abi.decode(
                _data,
                (address, address, address, uint64, uint64, uint32)
            );

        if (_pair == address(0)) revert ZeroAddressPair();
        if (_token == address(0)) revert ZeroAddressToken();
        if (_startsAt <= block.timestamp) revert InvalidStartsAt();
        if (_refreshRate <= 30) revert InvalidRefreshRate();
        if (_endsAt <= _startsAt + _refreshRate) revert InvalidEndsAt();

        if (IUniswapV2Pair(_pair).token0() == _token) token0 = true;
        else if (IUniswapV2Pair(_pair).token1() == _token) token0 = false;
        else revert NoTokenInPair();

        (
            uint256 _price0Cumulative,
            uint256 _price1Cumulative,
            uint32 _timestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(_pair);

        __Job_init(_joltJobsRegistry);
        __template = _template;
        kpiToken = _kpiToken;
        refreshRate = _refreshRate;
        startsAt = _startsAt;
        endsAt = _endsAt;
        tokenDecimals = IERC20Decimals(_token).decimals();
        pair = _pair;
        observation = Observation({
            timestamp: _timestamp,
            price: FixedPointLibrary.uq112x112(0),
            lastCumulative: token0 ? _price1Cumulative : _price0Cumulative
        });
    }

    function _workable() internal view returns (bool) {
        if (block.timestamp < startsAt) return false;
        if (block.timestamp >= endsAt) return !finalized;
        (, , uint32 _timestamp) = UniswapV2OracleLibrary
            .currentCumulativePrices(pair);
        uint32 _timeElapsed;
        unchecked {
            _timeElapsed = _timestamp - observation.timestamp;
        }
        return _timeElapsed >= refreshRate;
    }

    function workable(bytes calldata)
        external
        view
        override
        returns (bool, bytes memory)
    {
        return (_workable(), bytes(""));
    }

    function work(bytes calldata) external override needsExecution {
        if (!_workable()) revert NoWorkRequired();

        if (block.timestamp >= endsAt && !finalized) {
            IKPIToken(kpiToken).finalize(
                observation.price.mul(10**tokenDecimals).decode144()
            );
            finalized = true;
            return;
        }

        (
            uint256 _price0Cumulative,
            uint256 _price1Cumulative,
            uint32 _timestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(pair);

        uint256 _priceCumulative = (
            token0 ? _price1Cumulative : _price0Cumulative
        );
        FixedPointLibrary.uq112x112 memory _averagePriceCumulative;
        // over/underflow is desired
        unchecked {
            uint32 _timeElapsed = _timestamp - observation.timestamp;
            _averagePriceCumulative = FixedPointLibrary.uq112x112(
                uint224(
                    (_priceCumulative - observation.lastCumulative) /
                        _timeElapsed
                )
            );
        }

        observation.price = _averagePriceCumulative;
        observation.lastCumulative = _priceCumulative;
        observation.timestamp = _timestamp;
    }

    function data() external view override returns (bytes memory) {
        return
            abi.encode(
                refreshRate,
                startsAt,
                endsAt,
                pair,
                token0,
                observation.price.mul(10**tokenDecimals).decode144(),
                observation.timestamp
            );
    }

    function template()
        external
        view
        override
        returns (IOraclesManager.Template memory)
    {
        return __template;
    }
}

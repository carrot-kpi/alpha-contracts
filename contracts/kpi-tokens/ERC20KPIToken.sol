pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../interfaces/oracles/IOracle.sol";
import "../interfaces/IOraclesManager.sol";
import "../interfaces/kpi-tokens/IERC20KPIToken.sol";
import "../commons/Types.sol";

/**
 * @title ERC20KPIToken
 * @dev ERC20KPIToken contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
contract ERC20KPIToken is
    ERC20Upgradeable,
    IERC20KPIToken,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 internal immutable INVALID_ANSWER =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    bool private oraclesInitialized;
    bool private protocolFeeCollected;
    bool public finalized;
    bool public andRelationship;
    uint16 internal toBeFinalized;
    address public creator;
    Collateral[] public collaterals;
    mapping(address => FinalizableOracle) public oracles;
    uint256 internal initialSupply;
    uint256 internal totalWeight;

    error Forbidden();
    error InconsistentWeights();
    error InconsistentCollaterals();
    error InvalidCollateral();
    error NoFunding();
    error InconsistentArrayLengths();
    error InvalidOracleBounds();
    error InvalidOracleWeights();
    error AlreadyInitialized();
    error NotInitialized();
    error OraclesNotInitialized();

    event Initialize(
        address creator,
        Collateral[] collaterals,
        bytes32 name,
        bytes32 symbol,
        uint256 supply
    );
    event Finalize(address oracle, uint256 result);
    event Redeem(uint256 burned, RedeemedCollateral[] redeemed);

    function initialize(address _creator, bytes memory _data)
        external
        override
        initializer
    {
        (
            address[] memory _collateralTokens,
            uint256[] memory _collateralAmounts,
            uint256[] memory _minimumPayouts,
            bytes32 _erc20Name,
            bytes32 _erc20Symbol,
            uint256 _erc20Supply
        ) = abi.decode(
                _data,
                (address[], uint256[], uint256[], bytes32, bytes32, uint256)
            );

        if (
            _collateralTokens.length == 0 ||
            _collateralTokens.length != _collateralAmounts.length ||
            _collateralAmounts.length != _minimumPayouts.length
        ) revert InconsistentCollaterals();

        for (uint256 _i = 0; _i < _collateralTokens.length; _i++) {
            address _token = _collateralTokens[_i];
            uint256 _amount = _collateralAmounts[_i];
            uint256 _minimumPayout = _minimumPayouts[_i];
            if (
                _token == address(0) ||
                _amount == 0 ||
                _minimumPayout >= _amount
            ) revert InvalidCollateral();
            IERC20Upgradeable(_token).safeTransferFrom(
                _creator,
                address(this),
                _amount
            );
            collaterals.push(
                Collateral({
                    token: _token,
                    amount: _amount,
                    minimumPayout: _minimumPayout
                })
            );
        }

        __ERC20_init(
            string(abi.encodePacked(_erc20Name)),
            string(abi.encodePacked(_erc20Symbol))
        );
        _mint(_creator, _erc20Supply);

        initialSupply = _erc20Supply;
        creator = _creator;

        emit Initialize(
            _creator,
            collaterals,
            _erc20Name,
            _erc20Symbol,
            _erc20Supply
        );
    }

    function initializeOracles(address _oraclesManager, bytes memory _data)
        external
        nonReentrant
    {
        if (creator == address(0)) revert NotInitialized();
        if (oraclesInitialized) revert AlreadyInitialized();

        (
            address[] memory _templates,
            uint256[] memory _lowerBounds,
            uint256[] memory _higherBounds,
            address[] memory _automationFundingTokens,
            uint256[] memory _automationFundingAmounts,
            uint256[] memory _weights,
            bytes[] memory _initializationData,
            bool _andRelationship
        ) = abi.decode(
                _data,
                (
                    address[],
                    uint256[],
                    uint256[],
                    address[],
                    uint256[],
                    uint256[],
                    bytes[],
                    bool
                )
            );

        if (
            _templates.length == 0 ||
            _templates.length != _lowerBounds.length ||
            _lowerBounds.length != _higherBounds.length ||
            _higherBounds.length != _automationFundingTokens.length ||
            _automationFundingTokens.length !=
            _automationFundingAmounts.length ||
            _automationFundingAmounts.length != _weights.length ||
            _weights.length != _initializationData.length
        ) revert InconsistentArrayLengths();

        for (uint256 _i = 0; _i < _templates.length; _i++) {
            uint256 _higherBound = _higherBounds[_i];
            uint256 _lowerBound = _lowerBounds[_i];
            uint256 _weight = _weights[_i];
            if (_higherBound <= _lowerBound) revert InvalidOracleBounds();
            if (_weight == 0) revert InvalidOracleWeights();
            totalWeight += _weight;
            toBeFinalized++;
            address _instance = IOraclesManager(_oraclesManager).instantiate(
                _templates[_i],
                _automationFundingTokens[_i],
                _automationFundingAmounts[_i],
                _initializationData[_i]
            );
            oracles[_instance] = FinalizableOracle({
                lowerBound: _lowerBound,
                higherBound: _higherBound,
                finalProgress: 0,
                weight: _weight,
                finalized: false
            });
        }

        andRelationship = _andRelationship;
        oraclesInitialized = true;
    }

    function collectProtocolFees(address _feeReceiver) external nonReentrant {
        if (!oraclesInitialized) revert OraclesNotInitialized();
        if (protocolFeeCollected) revert AlreadyInitialized();

        for (uint256 _i = 0; _i < collaterals.length; _i++) {
            Collateral storage _collateral = collaterals[_i];
            uint256 _fee = calculateProtocolFee(_collateral.amount);
            IERC20Upgradeable(_collateral.token).safeTransfer(
                _feeReceiver,
                _fee
            );
            _collateral.amount -= _fee;
        }

        protocolFeeCollected = true;
    }

    function finalize(uint256 _result) external override nonReentrant {
        if (finalized) revert Forbidden();

        FinalizableOracle storage _oracle = oracles[msg.sender];
        if (_oracle.higherBound == 0 || _oracle.finalized) revert Forbidden();

        if (_result < _oracle.lowerBound || _result == INVALID_ANSWER) {
            // if oracles are in an 'and' relationship and at least one gives a
            // negative result, give back all the collateral minus the minimum payout
            // to the creator
            if (andRelationship) {
                for (uint256 _i = 0; _i < collaterals.length; _i++) {
                    Collateral storage _collateral = collaterals[_i];
                    uint256 _reimboursement = _collateral.amount -
                        _collateral.minimumPayout;
                    if (_reimboursement > 0) {
                        IERC20Upgradeable(_collateral.token).safeTransfer(
                            creator,
                            _reimboursement
                        );
                        _collateral.amount -= _reimboursement;
                    }
                }
                finalized = true;
                return;
            } else {
                // if not in an 'and' relationship, only give back the amount of
                // collateral tied to the failed condition (minus the minimum payout)
                for (uint256 _i = 0; _i < collaterals.length; _i++) {
                    Collateral storage _collateral = collaterals[_i];
                    uint256 _reimboursement = ((_collateral.amount -
                        _collateral.minimumPayout) * _oracle.weight) /
                        totalWeight;
                    if (_reimboursement > 0) {
                        IERC20Upgradeable(_collateral.token).safeTransfer(
                            creator,
                            _reimboursement
                        );
                        _collateral.amount -= _reimboursement;
                    }
                }
            }
        } else {
            uint256 _oracleFullRange = _oracle.higherBound - _oracle.lowerBound;
            uint256 _finalOracleProgress = _result >= _oracle.higherBound
                ? _oracleFullRange
                : _result - _oracle.lowerBound;
            _oracle.finalProgress = _finalOracleProgress;
            // transfer the unnecessary collateral back to the KPI creator
            if (_finalOracleProgress < _oracleFullRange) {
                for (uint256 _i = 0; _i < collaterals.length; _i++) {
                    Collateral storage _collateral = collaterals[_i];
                    uint256 _reimboursement = ((_collateral.amount -
                        _collateral.minimumPayout) *
                        _oracle.weight *
                        (_oracleFullRange - _finalOracleProgress)) /
                        (_oracleFullRange * totalWeight);
                    if (_reimboursement > 0) {
                        IERC20Upgradeable(_collateral.token).safeTransfer(
                            creator,
                            _reimboursement
                        );
                        _collateral.amount -= _reimboursement;
                    }
                }
            }
        }

        if (--toBeFinalized == 0) finalized = true;

        emit Finalize(msg.sender, _result);
    }

    function calculateProtocolFee(uint256 _amount)
        internal
        pure
        returns (uint256)
    {
        return (_amount * 30) / 10_000;
    }

    function redeem() external override nonReentrant {
        if (!finalized) revert Forbidden();
        uint256 _kpiTokenBalance = balanceOf(msg.sender);
        if (_kpiTokenBalance == 0) revert Forbidden();
        _burn(msg.sender, _kpiTokenBalance);
        RedeemedCollateral[]
            memory _redeemedCollaterals = new RedeemedCollateral[](
                collaterals.length
            );
        for (uint256 _i = 0; _i < collaterals.length; _i++) {
            Collateral storage _collateral = collaterals[_i];
            // FIXME: can initial total supply be 0?
            uint256 _redeemableAmount = (_collateral.amount *
                _kpiTokenBalance) / initialSupply;
            IERC20Upgradeable(_collateral.token).safeTransfer(
                msg.sender,
                _redeemableAmount
            );
            _redeemedCollaterals[_i] = RedeemedCollateral({
                token: _collateral.token,
                amount: _redeemableAmount
            });
        }
        emit Redeem(_kpiTokenBalance, _redeemedCollaterals);
    }

    function protocolFee(bytes memory _data)
        external
        pure
        returns (bytes memory)
    {
        (
            address[] memory _collateralTokens,
            uint256[] memory _collateralAmounts
        ) = abi.decode(_data, (address[], uint256[]));

        if (_collateralTokens.length != _collateralAmounts.length)
            revert InconsistentArrayLengths();

        uint256[] memory _fees = new uint256[](_collateralTokens.length);
        for (uint256 _i = 0; _i < _collateralTokens.length; _i++)
            _fees[_i] = calculateProtocolFee(_collateralAmounts[_i]);

        return abi.encode(_collateralTokens, _fees);
    }
}

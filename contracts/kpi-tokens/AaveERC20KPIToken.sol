pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../interfaces/oracles/IOracle.sol";
import "../interfaces/IOraclesManager.sol";
import "../interfaces/IKPITokensManager.sol";
import "../interfaces/external/IAavePool.sol";
import "../interfaces/kpi-tokens/IAaveERC20KPIToken.sol";

/**
 * @title AaveERC20KPIToken
 * @dev AaveERC20KPIToken contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
contract AaveERC20KPIToken is
    ERC20Upgradeable,
    IAaveERC20KPIToken,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 internal immutable INVALID_ANSWER =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    bool internal oraclesInitialized;
    bool internal protocolFeeCollected;
    bool public finalized;
    bool internal andRelationship;
    uint16 internal toBeFinalized;
    address public creator;
    address public aavePool;
    Collateral[] internal collaterals;
    FinalizableOracle[] internal finalizableOracles;
    string public description;
    IKPITokensManager.Template private __template;
    uint256 internal initialSupply;
    uint256 internal totalWeight;

    error InvalidAavePoolAddress();
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
    error InvalidDescription();

    event Initialize(
        address creator,
        string _description,
        Collateral[] collaterals,
        bytes32 name,
        bytes32 symbol,
        uint256 supply
    );
    event Finalize(address oracle, uint256 result);
    event Redeem(uint256 burned, RedeemedCollateral[] redeemed);

    function initialize(
        address _creator,
        IKPITokensManager.Template calldata _template,
        string memory _description,
        bytes memory _data
    ) external override initializer {
        if (bytes(_description).length == 0) revert InvalidDescription();

        (
            address _aavePool,
            address[] memory _collateralTokens,
            uint256[] memory _collateralAmounts,
            uint256[] memory _minimumPayouts,
            bytes32 _erc20Name,
            bytes32 _erc20Symbol,
            uint256 _erc20Supply
        ) = abi.decode(
                _data,
                (
                    address,
                    address[],
                    uint256[],
                    uint256[],
                    bytes32,
                    bytes32,
                    uint256
                )
            );

        if (_aavePool == address(0)) revert InvalidAavePoolAddress();
        if (
            _collateralTokens.length == 0 ||
            _collateralTokens.length != _collateralAmounts.length ||
            _collateralAmounts.length != _minimumPayouts.length
        ) revert InconsistentCollaterals();

        for (uint256 _i = 0; _i < _collateralTokens.length; _i++) {
            Collateral memory _collateral = Collateral({
                token: _collateralTokens[_i],
                amount: _collateralAmounts[_i],
                aToken: address(0),
                minimumPayout: _minimumPayouts[_i]
            });
            IAavePool.ReserveData memory _reserveData = IAavePool(_aavePool)
                .getReserveData(_collateral.token);
            if (_reserveData.aTokenAddress == address(0))
                revert InvalidCollateral();
            _collateral.aToken = _reserveData.aTokenAddress;

            if (
                _collateral.token == address(0) ||
                _collateral.amount == 0 ||
                _collateral.minimumPayout >= _collateral.amount
            ) revert InvalidCollateral();
            IERC20Upgradeable(_collateral.token).safeTransferFrom(
                _creator,
                address(this),
                _collateral.amount
            );
            IERC20Upgradeable(_collateral.token).approve(
                _aavePool,
                _collateral.amount
            );
            IAavePool(_aavePool).supply(
                _collateral.token,
                _collateral.amount,
                address(this),
                0
            );
            collaterals.push(_collateral);
        }

        __ERC20_init(
            string(abi.encodePacked(_erc20Name)),
            string(abi.encodePacked(_erc20Symbol))
        );
        _mint(_creator, _erc20Supply);

        aavePool = _aavePool;
        initialSupply = _erc20Supply;
        creator = _creator;
        description = _description;
        __template = _template;

        emit Initialize(
            _creator,
            _description,
            collaterals,
            _erc20Name,
            _erc20Symbol,
            _erc20Supply
        );
    }

    function initializeOracles(address _oraclesManager, bytes calldata _data)
        external
        nonReentrant
    {
        if (creator == address(0)) revert NotInitialized();
        if (oraclesInitialized) revert AlreadyInitialized();

        (
            uint256[] memory _ids,
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
                    uint256[],
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
            _ids.length == 0 ||
            _ids.length != _lowerBounds.length ||
            _lowerBounds.length != _higherBounds.length ||
            _higherBounds.length != _automationFundingTokens.length ||
            _automationFundingTokens.length !=
            _automationFundingAmounts.length ||
            _automationFundingAmounts.length != _weights.length ||
            _weights.length != _initializationData.length
        ) revert InconsistentArrayLengths();

        for (uint256 _i = 0; _i < _ids.length; _i++) {
            uint256 _higherBound = _higherBounds[_i];
            uint256 _lowerBound = _lowerBounds[_i];
            uint256 _weight = _weights[_i];
            if (_higherBound <= _lowerBound) revert InvalidOracleBounds();
            if (_weight == 0) revert InvalidOracleWeights();
            totalWeight += _weight;
            toBeFinalized++;
            address _instance = IOraclesManager(_oraclesManager).instantiate(
                creator,
                _ids[_i],
                _automationFundingTokens[_i],
                _automationFundingAmounts[_i],
                _initializationData[_i]
            );
            finalizableOracles.push(
                FinalizableOracle({
                    addrezz: _instance,
                    lowerBound: _lowerBound,
                    higherBound: _higherBound,
                    finalProgress: 0,
                    weight: _weight,
                    finalized: false
                })
            );
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
            IERC20Upgradeable(_collateral.aToken).safeTransfer(
                _feeReceiver,
                _fee
            );
            _collateral.amount -= _fee;
        }

        protocolFeeCollected = true;
    }

    function finalizableOracle(address _address)
        internal
        view
        returns (FinalizableOracle storage)
    {
        for (uint256 _i = 0; _i < finalizableOracles.length; _i++) {
            FinalizableOracle storage _finalizableOracle = finalizableOracles[
                _i
            ];
            if (
                !_finalizableOracle.finalized &&
                _finalizableOracle.addrezz == _address
            ) return _finalizableOracle;
        }
        revert Forbidden();
    }

    function finalize(uint256 _result) external override nonReentrant {
        if (finalized) revert Forbidden();

        FinalizableOracle storage _oracle = finalizableOracle(msg.sender);
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

        if (--toBeFinalized == 0) {
            finalized = true;
            for (uint256 _i = 0; _i < collaterals.length; _i++) {
                Collateral storage _collateral = collaterals[_i];
                uint256 _withdrawnAmount = IAavePool(aavePool).withdraw(
                    _collateral.token,
                    type(uint256).max,
                    address(this)
                );
                _collateral.amount = _withdrawnAmount;
            }
        }

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
            Collateral memory _collateral = collaterals[_i];
            // FIXME: can initial total supply be 0?
            uint256 _redeemableAmount = (_collateral.amount *
                _kpiTokenBalance) / initialSupply;
            _redeemedCollaterals[_i] = RedeemedCollateral({
                token: _collateral.token,
                amount: _redeemableAmount
            });
        }
        emit Redeem(_kpiTokenBalance, _redeemedCollaterals);
    }

    function protocolFee(bytes calldata _data)
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

    function oracles() external view override returns (address[] memory) {
        address[] memory _oracleAddresses = new address[](
            finalizableOracles.length
        );
        for (uint256 _i = 0; _i < _oracleAddresses.length; _i++)
            _oracleAddresses[_i] = finalizableOracles[_i].addrezz;
        return _oracleAddresses;
    }

    function data() external view returns (bytes memory) {
        uint256 _collateralsLength = collaterals.length;
        address[] memory _collateralTokens = new address[](_collateralsLength);
        uint256[] memory _collateralAmounts = new uint256[](_collateralsLength);
        uint256[] memory _collateralMinimumPayouts = new uint256[](
            _collateralsLength
        );
        address[] memory _collateralATokens = new address[](_collateralsLength);
        for (uint256 _i = 0; _i < _collateralsLength; _i++) {
            Collateral storage _collateral = collaterals[_i];
            _collateralTokens[_i] = _collateral.token;
            _collateralAmounts[_i] = _collateral.amount;
            _collateralMinimumPayouts[_i] = _collateral.minimumPayout;
            _collateralATokens[_i] = _collateral.aToken;
        }

        uint256 _oraclesLength = finalizableOracles.length;
        uint256[] memory _lowerBounds = new uint256[](_oraclesLength);
        uint256[] memory _higherBounds = new uint256[](_oraclesLength);
        uint256[] memory _finalProgresses = new uint256[](_oraclesLength);
        uint256[] memory _weights = new uint256[](_oraclesLength);
        for (uint256 _i = 0; _i < _oraclesLength; _i++) {
            FinalizableOracle storage _oracle = finalizableOracles[_i];
            _lowerBounds[_i] = _oracle.lowerBound;
            _higherBounds[_i] = _oracle.higherBound;
            _finalProgresses[_i] = _oracle.finalProgress;
            _weights[_i] = _oracle.weight;
        }

        return
            abi.encode(
                _collateralTokens,
                _collateralAmounts,
                _collateralMinimumPayouts,
                _collateralATokens,
                _lowerBounds,
                _higherBounds,
                _finalProgresses,
                _weights,
                andRelationship,
                initialSupply,
                name(),
                symbol()
            );
    }

    function template()
        external
        view
        override
        returns (IKPITokensManager.Template memory)
    {
        return __template;
    }
}

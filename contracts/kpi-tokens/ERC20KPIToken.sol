pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../interfaces/oracles/IOracle.sol";
import "../interfaces/IOraclesManager.sol";
import "../interfaces/IKPITokensManager.sol";
import "../interfaces/kpi-tokens/IERC20KPIToken.sol";
import {TokenAmount} from "../commons/Types.sol";

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

    bool internal oraclesInitialized;
    bool internal protocolFeeCollected;
    bool public finalized;
    bool internal andRelationship;
    uint16 internal toBeFinalized;
    address public creator;
    Collateral[] internal collaterals;
    FinalizableOracle[] internal finalizableOracles;
    string public description;
    address internal kpiTokensManager;
    uint256 internal kpiTokenTemplateId;
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
    error InvalidDescription();
    error TooManyCollaterals();
    error InvalidName();
    error InvalidSymbol();
    error InvalidTotalSupply();
    error InvalidCreator();
    error InvalidKpiTokensManager();

    event Initialize(
        address creator,
        string description,
        Collateral[] collaterals,
        string name,
        string symbol,
        uint256 supply
    );
    event Finalize(address oracle, uint256 result);
    event Redeem(uint256 burned, RedeemedCollateral[] redeemed);

    function initialize(
        address _creator,
        address _kpiTokensManager,
        uint256 _kpiTokenTemplateId,
        string calldata _description,
        bytes calldata _data
    ) external override initializer {
        InitializeArguments memory _args = InitializeArguments({
            creator: _creator,
            kpiTokensManager: _kpiTokensManager,
            kpiTokenTemplateId: _kpiTokenTemplateId,
            description: _description,
            data: _data
        });

        if (_creator == address(0)) revert InvalidCreator();
        if (_kpiTokensManager == address(0)) revert InvalidKpiTokensManager();
        if (bytes(_args.description).length == 0) revert InvalidDescription();

        (
            Collateral[] memory _collaterals,
            string memory _erc20Name,
            string memory _erc20Symbol,
            uint256 _erc20Supply
        ) = abi.decode(_args.data, (Collateral[], string, string, uint256));

        uint256 _inputCollateralsLength = _collaterals.length;
        if (_inputCollateralsLength > 5) revert TooManyCollaterals();
        if (bytes(_erc20Name).length == 0) revert InvalidName();
        if (bytes(_erc20Symbol).length == 0) revert InvalidSymbol();
        if (_erc20Supply == 0) revert InvalidTotalSupply();

        for (uint8 _i = 0; _i < _inputCollateralsLength; _i++) {
            Collateral memory _collateral = _collaterals[_i];
            if (
                _collateral.token == address(0) ||
                _collateral.amount == 0 ||
                _collateral.minimumPayout >= _collateral.amount
            ) revert InvalidCollateral();
            IERC20Upgradeable(_collateral.token).safeTransferFrom(
                _args.creator,
                address(this),
                _collateral.amount
            );
            collaterals.push(_collateral);
        }

        __ERC20_init(_erc20Name, _erc20Symbol);
        _mint(_args.creator, _erc20Supply);

        initialSupply = _erc20Supply;
        creator = _args.creator;
        description = _args.description;
        kpiTokensManager = _args.kpiTokensManager;
        kpiTokenTemplateId = _args.kpiTokenTemplateId;

        emit Initialize(
            _args.creator,
            _args.description,
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
        address _creator = creator;
        if (_creator == address(0)) revert NotInitialized();
        if (oraclesInitialized) revert AlreadyInitialized();

        (OracleData[] memory _oracleDatas, bool _andRelationship) = abi.decode(
            _data,
            (OracleData[], bool)
        );

        for (uint256 _i = 0; _i < _oracleDatas.length; _i++) {
            OracleData memory _oracleData = _oracleDatas[_i];
            if (_oracleData.higherBound <= _oracleData.lowerBound)
                revert InvalidOracleBounds();
            if (_oracleData.weight == 0) revert InvalidOracleWeights();
            totalWeight += _oracleData.weight;
            toBeFinalized++;
            address _instance = IOraclesManager(_oraclesManager).instantiate(
                _creator,
                _oracleData.id,
                _oracleData.data
            );
            finalizableOracles.push(
                FinalizableOracle({
                    addrezz: _instance,
                    lowerBound: _oracleData.lowerBound,
                    higherBound: _oracleData.higherBound,
                    finalProgress: 0,
                    weight: _oracleData.weight,
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
            IERC20Upgradeable(_collateral.token).safeTransfer(
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
            // to the creator, otherwise calculate the exact amount to give back.
            bool _andRelationship = andRelationship;
            for (uint256 _i = 0; _i < collaterals.length; _i++) {
                Collateral storage _collateral = collaterals[_i];
                uint256 _reimboursement = _andRelationship
                    ? _collateral.amount - _collateral.minimumPayout
                    : ((_collateral.amount - _collateral.minimumPayout) *
                        _oracle.weight) / totalWeight;
                IERC20Upgradeable(_collateral.token).safeTransfer(
                    creator,
                    _reimboursement
                );
                _collateral.amount -= _reimboursement;
            }
            if (_andRelationship) {
                finalized = true;
                return;
            }
        } else {
            uint256 _oracleFullRange = _oracle.higherBound - _oracle.lowerBound;
            uint256 _finalOracleProgress = _result >= _oracle.higherBound
                ? _oracle.higherBound
                : _result - _oracle.lowerBound;
            _oracle.finalProgress = _finalOracleProgress;
            // transfer the unnecessary collateral back to the KPI creator
            // if the condition wasn't fully satisfied
            if (_finalOracleProgress < _oracleFullRange) {
                for (uint8 _i = 0; _i < collaterals.length; _i++) {
                    Collateral storage _collateral = collaterals[_i];
                    uint256 _reimboursement = ((_collateral.amount -
                        _collateral.minimumPayout) *
                        _oracle.weight *
                        (_oracleFullRange - _finalOracleProgress)) /
                        (_oracleFullRange * totalWeight);
                    IERC20Upgradeable(_collateral.token).safeTransfer(
                        creator,
                        _reimboursement
                    );
                    _collateral.amount -= _reimboursement;
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
            Collateral memory _collateral = collaterals[_i];
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

    function protocolFee(bytes calldata _data)
        external
        pure
        returns (bytes memory)
    {
        TokenAmount[] memory _collaterals = abi.decode(_data, (TokenAmount[]));

        if (_collaterals.length > 5) revert TooManyCollaterals();

        TokenAmount[] memory _fees = new TokenAmount[](_collaterals.length);
        for (uint8 _i = 0; _i < _collaterals.length; _i++) {
            TokenAmount memory _collateral = _collaterals[_i];
            _fees[_i] = TokenAmount({
                token: _collateral.token,
                amount: calculateProtocolFee(_collateral.amount)
            });
        }

        return abi.encode(_fees);
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
        return
            abi.encode(
                collaterals,
                finalizableOracles,
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
        return IKPITokensManager(kpiTokensManager).template(kpiTokenTemplateId);
    }
}

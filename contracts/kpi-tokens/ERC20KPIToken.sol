pragma solidity 0.8.14;

import {IERC20Upgradeable, ERC20Upgradeable} from "oz-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "oz-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ReentrancyGuard} from "oz/security/ReentrancyGuard.sol";
import {IOraclesManager} from "../interfaces/IOraclesManager.sol";
import {IKPITokensManager} from "../interfaces/IKPITokensManager.sol";
import {IERC20KPIToken} from "../interfaces/kpi-tokens/IERC20KPIToken.sol";
import {TokenAmount} from "../commons/Types.sol";

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title ERC20 KPI token template implementation
/// @dev A KPI token template imlementation. The template produces ERC20 tokens
/// that can be distributed arbitrarily to communities or specific entities in order
/// to incentivize them to reach certain KPIs. Backing these tokens there are potentially
/// a multitude of other ERC20 tokens (up to 5), the release of which is linked to
/// reaching the predetermined KPIs or not. In order to check if these KPIs are reached
/// on-chain, oracles oracles are employed, and based on the results conveyed back to
/// the KPI token template, the collaterals are either unlocked or sent back to the
/// original KPI token creator. Interesting logic is additionally tied to the conditions
/// and collaterals, such as the possibility to have a minimum payout (a per-collateral
/// sum that will always be paid out to KPI token holders regardless of the fact that
/// KPIs are reached or not), weighted KPIs and multiple detached resolution or all-in-one
/// reaching of KPIs (explained more in details later).
/// @author Federico Luzzi - <federico.luzzi@protonmail.com>
contract ERC20KPIToken is ERC20Upgradeable, IERC20KPIToken, ReentrancyGuard {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 internal immutable INVALID_ANSWER =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 internal immutable MULTIPLIER = 64;

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
    error InvalidDescription();
    error TooManyCollaterals();
    error TooManyOracles();
    error InvalidName();
    error InvalidSymbol();
    error InvalidTotalSupply();
    error InvalidCreator();
    error InvalidKpiTokensManager();
    error ZeroAddressOraclesManager();
    error InvalidMinimumPayoutAfterFee();
    error DuplicatedCollateral();

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

    /// @dev Initializes the template through the passed in data. This function is
    /// generally invoked by the factory,
    /// in turn invoked by a KPI token creator.
    /// @param _creator Since the factory is assumed to be the caller of this function,
    /// it must forward the original caller (msg.sender, the KPI token creator) here.
    /// @param _kpiTokensManager The factory-forwarded address of the KPI tokens manager.
    /// @param _kpiTokenTemplateId The id of the template.
    /// @param _description An IPFS cid pointing to a structured JSON describing what the
    /// @param _data An ABI-encoded structure forwarded by the factory from the KPI token
    /// creator, containing the initialization parameters for the ERC20 KPI token template.
    /// In particular the structure is formed in the following way:
    /// - `Collateral[] memory _collaterals`: an array of `Collateral` structs conveying
    ///   information about the collaterals to be used (a limit of maximum 5 different
    ///   collateral is enforced, and duplicates are not allowed).
    /// - `string memory _erc20Name`: The `name` of the created ERC20 token.
    /// - `string memory _erc20Symbol`: The `symbol` of the created ERC20 token.
    /// - `string memory _erc20Supply`: The initial supply of the created ERC20 token.
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
            for (uint8 _j = _i + 1; _j < _collaterals.length; _j++)
                if (_collateral.token == _collaterals[_j].token)
                    revert DuplicatedCollateral();
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

    /// @dev Initializes the oracles tied to this KPI token (both the actual oracle
    /// instantiation and configuration data needed to interpret the relayed result
    /// at the KPI-token level). This function is generally invoked by the factory,
    /// in turn invoked by a KPI token creator.
    /// @param _oraclesManager The factory-forwarded address of the oracles manager.
    /// @param _data An ABI-encoded structure forwarded by the factory from the KPI token
    /// creator, containing the initialization parameters for the chosen oracle templates.
    /// In particular the structure is formed in the following way:
    /// - `OracleData[] memory _oracleDatas`: data about the oracle, such as:
    ///     - `uint256 _templateId`: The id of the chosed oracle template.
    ///     - `uint256 _lowerBound`: The number at which the oracle's reported result is
    ///       interpreted in a failed KPI (not reached). If the oracle linked to this lower
    ///       bound reports a final number above this, we know the KPI is at least partially
    ///       reached.
    ///     - `uint256 _higherBound`: The number at which the oracle's reported result
    ///       is interpreted in a full verification of the KPI (fully reached). If the
    ///       oracle linked to this higher bound reports a final number equal or greater
    ///       than this, we know the KPI has fully been reached.
    ///     - `uint256 _weight`: The KPI weight determines the importance of it and how
    ///       much of the collateral a specific KPI "governs". If for example we have 2
    ///       KPIs A and B with respective weights 1 and 2, a third of the deposited
    ///       collaterals goes towards incentivizing A, while the remaining 2/3rds go
    ///       to B (i.e. B is valued as a more critical KPI to reach compared to A, and
    ///       collaterals reflect this).
    ///     - `uint256 _data`: ABI-encoded, oracle-specific data used to effectively
    ///       instantiate the oracle in charge of monitoring this KPI and reporting the
    ///       final result on-chain.
    /// - `bool _andRelationship`: Whether all KPIs should be at least partly reached in
    ///   order to unlock collaterals for KPI token holders to redeem (minus the minimum
    ///   payout amount, which is unlocked under any circumstance).
    function initializeOracles(address _oraclesManager, bytes calldata _data)
        external
    {
        address _creator = creator;
        if (_creator == address(0)) revert NotInitialized();
        if (_oraclesManager == address(0)) revert ZeroAddressOraclesManager();
        if (oraclesInitialized) revert AlreadyInitialized();

        (OracleData[] memory _oracleDatas, bool _andRelationship) = abi.decode(
            _data,
            (OracleData[], bool)
        );

        if (_oracleDatas.length > 5) revert TooManyOracles();

        for (uint16 _i = 0; _i < _oracleDatas.length; _i++) {
            OracleData memory _oracleData = _oracleDatas[_i];
            if (_oracleData.higherBound <= _oracleData.lowerBound)
                revert InvalidOracleBounds();
            if (_oracleData.weight == 0) revert InvalidOracleWeights();
            totalWeight += _oracleData.weight;
            address _instance = IOraclesManager(_oraclesManager).instantiate(
                _creator,
                _oracleData.templateId,
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

        toBeFinalized = uint16(_oracleDatas.length);
        andRelationship = _andRelationship;
        oraclesInitialized = true;
    }

    /// @dev Collects the protocol fee from the collaterals backing the KPI token.
    /// In the specific case, the fee is taken as a percentage of the ERC20
    /// collaterals backing the KPI token.
    /// @param _feeReceiver The address to which the collected fees must be sent.
    function collectProtocolFees(address _feeReceiver) external nonReentrant {
        if (!oraclesInitialized) revert NotInitialized();
        if (protocolFeeCollected) revert AlreadyInitialized();

        for (uint256 _i = 0; _i < collaterals.length; _i++) {
            Collateral storage _collateral = collaterals[_i];
            uint256 _fee = calculateProtocolFee(_collateral.amount);
            IERC20Upgradeable(_collateral.token).safeTransfer(
                _feeReceiver,
                _fee
            );
            if (_collateral.amount - _fee <= _collateral.minimumPayout)
                revert InvalidMinimumPayoutAfterFee();
            _collateral.amount -= _fee;
        }

        protocolFeeCollected = true;
    }

    /// @dev Given an input address, returns a storage pointer to the
    /// `FinalizableOracle` struct associated with it. It reverts if
    /// the association does not exists.
    /// @param _address The finalizable oracle address.
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

    /// @dev Finalizes a condition linked with the KPI token. Exclusively
    /// callable by oracles linked with the KPI token in order to report the
    /// final outcome for a KPI once everything has played out "in the real world".
    /// Based on the reported results and the template configuration, collateral is
    /// either reserved to be redeemed by KPI token holders when full finalization is
    /// reached (i.e. when all the oracles have reported their final result), or sent
    /// back to the original KPI token creator (for example when KPIs have not been
    /// met, minus any present minimum payout). The possible scenarios are the following:
    ///
    /// If a result is either invalid or below the lower bound set for the KPI:
    /// - If an "all or none" approach has been chosen at the KPI token initialization
    /// time, all the collateral is sent back to the KPI token creator and the KPI token
    /// expires worthless on the spot.
    /// - If no "all or none" condition has been set, the KPI contracts calculates how
    /// much of the collaterals the specific condition "governed" (through the weighting
    /// mechanism), subtracts any minimum payout for these and sends back the right amount
    /// of collateral to the KPI token creator.
    ///
    /// If a result is in the specified range (and NOT above the higher bound) set for
    /// the KPI, the same calculations happen and some of the collateral gets sent back
    /// to the KPI token creator depending on how far we were from reaching the full KPI
    /// progress.
    ///
    /// If a result is at or above the higher bound set for the KPI token, pretty much
    /// nothing happens to the collateral, which is fully assigned to the KPI token holders
    /// and which will become redeemable once the finalization process has ended for all
    /// the oracles assigned to the KPI token.
    ///
    /// Once all the oracles associated with the KPI token have reported their end result and
    /// finalize, the remaining collateral, if any, becomes redeemable by KPI token holders.
    /// @param _result The oracle end result.
    // FIXME: what happens here if one of the collateral tokens is paused or anyway if at least one
    // of the collaterals transfers reverts?
    // The oracle reporting is pretty much lost/undoable and collateral might remain locked forever.
    // A solution could be avoiding automatic transfer back of the collateral to the KPI token creator
    // by splitting the accounting and actual collaterals transfers in two distinct functions,
    // since it's of utmost importance to register the oracle result at this stage.
    function finalize(uint256 _result) external override nonReentrant {
        if (!oraclesInitialized) revert NotInitialized();

        FinalizableOracle storage _oracle = finalizableOracle(msg.sender);
        if (finalized || _oracle.finalized) revert Forbidden();

        if (_result <= _oracle.lowerBound || _result == INVALID_ANSWER) {
            // if oracles are in an 'and' relationship and at least one gives a
            // negative result, give back all the collateral minus the minimum payout
            // to the creator, otherwise calculate the exact amount to give back.
            bool _andRelationship = andRelationship;
            for (uint256 _i = 0; _i < collaterals.length; _i++) {
                // FIXME: will using a memory collateral here save gas? Below too
                Collateral storage _collateral = collaterals[_i];
                uint256 _reimboursement;
                if (_andRelationship)
                    _reimboursement =
                        _collateral.amount -
                        _collateral.minimumPayout;
                else {
                    uint256 _numerator = ((_collateral.amount -
                        _collateral.minimumPayout) * _oracle.weight) <<
                        MULTIPLIER;
                    _reimboursement = (_numerator / totalWeight) >> MULTIPLIER;
                }
                _collateral.amount -= _reimboursement;
            }
            if (_andRelationship) {
                finalized = true;
                for (uint256 _i = 0; _i < finalizableOracles.length; _i++)
                    finalizableOracles[_i].finalized = true;
                toBeFinalized = 0;
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
                    uint256 _numerator = ((_collateral.amount -
                        _collateral.minimumPayout) *
                        _oracle.weight *
                        (_oracleFullRange - _finalOracleProgress)) <<
                        MULTIPLIER;
                    uint256 _denominator = _oracleFullRange * totalWeight;
                    uint256 _reimboursement = (_numerator / _denominator) >>
                        MULTIPLIER;
                    _collateral.amount -= _reimboursement;
                }
            }
        }

        _oracle.finalized = true;
        if (--toBeFinalized == 0) finalized = true;

        emit Finalize(msg.sender, _result);
    }

    function recoverERC20(address _token, address _receiver) external {
        if (msg.sender != creator) revert Forbidden();
        for (uint8 _i = 0; _i < collaterals.length; _i++) {
            Collateral memory _collateral = collaterals[_i];
            if (_collateral.token == _token) {
                IERC20Upgradeable(_token).safeTransfer(
                    _receiver,
                    IERC20Upgradeable(_collateral.token).balanceOf(
                        address(this)
                    ) - _collateral.amount
                );
                return;
            }
        }
        IERC20Upgradeable(_token).safeTransfer(
            _receiver,
            IERC20Upgradeable(_token).balanceOf(address(this))
        );
    }

    /// @dev Given a collateral amount, calculates the protocol fee as a percentage of it.
    /// @param _amount The collateral amount end result.
    /// @return The protocol fee amount.
    function calculateProtocolFee(uint256 _amount)
        internal
        pure
        returns (uint256)
    {
        return (_amount * 30) / 10_000;
    }

    /// @dev Only callable by KPI token holders, lets them redeem any collateral
    /// left in the contract after finalization, proportional to their balance
    /// compared to the total supply and left collateral amount. If the KPI token
    /// has expired worthless, this simply burns the user's KPI tokens.
    function redeem() external override nonReentrant {
        if (!finalized) revert Forbidden();
        uint256 _kpiTokenBalance = balanceOf(msg.sender);
        if (_kpiTokenBalance == 0) revert Forbidden();
        RedeemedCollateral[]
            memory _redeemedCollaterals = new RedeemedCollateral[](
                collaterals.length
            );
        uint256 _totalSupply = totalSupply();
        for (uint8 _i = 0; _i < collaterals.length; _i++) {
            Collateral storage _collateral = collaterals[_i];
            uint256 _redeemableAmount = (_collateral.amount *
                _kpiTokenBalance) / _totalSupply;
            _collateral.amount -= _redeemableAmount;
            IERC20Upgradeable(_collateral.token).safeTransfer(
                msg.sender,
                _redeemableAmount
            );
            _redeemedCollaterals[_i] = RedeemedCollateral({
                token: _collateral.token,
                amount: _redeemableAmount
            });
        }
        _burn(msg.sender, _kpiTokenBalance);
        emit Redeem(_kpiTokenBalance, _redeemedCollaterals);
    }

    /// @dev Given ABI-encoded data about the collaterals a user intends to use
    /// to create a KPI token, gives back a fee breakdown detailing how much
    /// fees will be taken from the collaterals. The ABI-encoded params must be
    /// a `TokenAmount` array (with a maximum of 5 elements).
    /// @return An ABI-encoded fee breakdown represented by a `TokenAmount` array.
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
            if (_collateral.token == address(0) || _collateral.amount == 0)
                revert InvalidCollateral();
            for (uint8 _j = _i + 1; _j < _collaterals.length; _j++)
                if (_collateral.token == _collaterals[_j].token)
                    revert DuplicatedCollateral();
            _fees[_i] = TokenAmount({
                token: _collateral.token,
                amount: calculateProtocolFee(_collateral.amount)
            });
        }

        return abi.encode(_fees);
    }

    /// @dev View function to query all the oracles associated with the KPI token at once.
    /// @return The oracles array.
    function oracles() external view override returns (address[] memory) {
        if (!oraclesInitialized) revert NotInitialized();
        address[] memory _oracleAddresses = new address[](
            finalizableOracles.length
        );
        for (uint256 _i = 0; _i < _oracleAddresses.length; _i++)
            _oracleAddresses[_i] = finalizableOracles[_i].addrezz;
        return _oracleAddresses;
    }

    /// @dev View function returning all the most important data about the KPI token, in
    /// an ABI-encoded structure. The structure includes collaterals, finalizable oracles,
    /// "all-or-none" flag, initial supply of the ERC20 KPI token, along with name and symbol.
    /// @return The ABI-encoded data.
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

    /// @dev View function returning info about the template used to instantiate this KPI token.
    /// @return The template struct.
    function template()
        external
        view
        override
        returns (IKPITokensManager.Template memory)
    {
        return IKPITokensManager(kpiTokensManager).template(kpiTokenTemplateId);
    }
}

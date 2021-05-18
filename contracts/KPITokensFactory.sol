pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/IReality.sol";
import "./interfaces/IKPIToken.sol";

/**
 * @title KPITokensFactory
 * @dev KPITokensFactory contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract KPITokensFactory is Ownable {
    using SafeERC20 for IERC20;

    struct Collateral {
        address token;
        uint256 amount;
    }

    struct KpiTokenData {
        string name;
        string symbol;
        uint256 totalSupply;
    }

    struct OracleData {
        string question;
        uint32 kpiExpiry;
    }

    uint16 private constant _10000 = 10000;

    uint16 public fee;
    uint32 public voteTimeout;
    address public kpiTokenImplementation;
    address public arbitrator;
    address public feeReceiver;
    IReality public oracle;

    event KpiTokenCreated(address kpiToken, uint256 feeAmount);

    constructor(
        address _kpiTokenImplementation,
        address _oracle,
        address _arbitrator,
        uint16 _fee,
        uint32 _voteTimeout,
        address _feeReceiver
    ) {
        require(_kpiTokenImplementation != address(0), "KF01");
        require(_oracle != address(0), "KF02");
        require(_arbitrator != address(0), "KF03");
        require(_fee < _10000, "KF03");
        require(_voteTimeout > 0, "KF04");
        require(_feeReceiver != address(0), "KF17");
        kpiTokenImplementation = _kpiTokenImplementation;
        oracle = IReality(_oracle);
        arbitrator = _arbitrator;
        fee = _fee;
        voteTimeout = _voteTimeout;
        feeReceiver = _feeReceiver;
    }

    function upgradeKpiTokenImplementation(address _kpiTokenImplementation)
        external
        onlyOwner
    {
        require(_kpiTokenImplementation != address(0), "KF05");
        kpiTokenImplementation = _kpiTokenImplementation;
    }

    function setFee(uint16 _fee) external onlyOwner {
        require(_fee < _10000, "KF06");
        fee = _fee;
    }

    function setArbitrator(address _arbitrator) external onlyOwner {
        require(_arbitrator != address(0), "KF07");
        arbitrator = _arbitrator;
    }

    function setVoteTimeout(uint32 _voteTimeout) external onlyOwner {
        require(_voteTimeout > 0, "KF08");
        voteTimeout = _voteTimeout;
    }

    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        require(_feeReceiver != address(0), "KF16");
        feeReceiver = _feeReceiver;
    }

    function createKpiToken(
        Collateral calldata _collateral,
        KpiTokenData calldata _tokenData,
        OracleData calldata _oracleData
    ) external {
        require(_collateral.token != address(0), "KF09");
        require(_collateral.amount > 0, "KF10");
        require(bytes(_tokenData.name).length > 0, "KF11");
        require(bytes(_tokenData.symbol).length > 0, "KF12");
        require(_tokenData.totalSupply > 0, "KF13");
        require(bytes(_oracleData.question).length > 0, "KF14");
        require(_oracleData.kpiExpiry > block.timestamp, "KF15");
        address _kpiTokenProxy = Clones.clone(kpiTokenImplementation);
        IERC20(_collateral.token).safeTransferFrom(
            msg.sender,
            address(this),
            _collateral.amount
        );
        uint256 _feeAmount = (_collateral.amount * fee) / _10000;
        IERC20(_collateral.token).safeTransfer(feeReceiver, _feeAmount);
        uint256 _collateralAmountMinusFees = _collateral.amount - _feeAmount;
        IERC20(_collateral.token).safeTransfer(
            _kpiTokenProxy,
            _collateralAmountMinusFees
        );
        bytes32 _kpiId =
            oracle.askQuestion(
                0,
                _oracleData.question,
                arbitrator,
                voteTimeout,
                _oracleData.kpiExpiry,
                0
            );
        IKPIToken(_kpiTokenProxy).initialize(
            _kpiId,
            address(oracle),
            msg.sender,
            IKPIToken.Collateral({
                token: _collateral.token,
                initialAmount: _collateralAmountMinusFees
            }),
            IKPIToken.TokenData({
                name: _tokenData.name,
                symbol: _tokenData.symbol,
                totalSupply: _tokenData.totalSupply
            })
        );
        emit KpiTokenCreated(_kpiTokenProxy, _feeAmount);
    }
}

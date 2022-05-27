pragma solidity 0.8.14;

import {BaseTestSetup} from "../../commons/BaseTestSetup.sol";
import {ERC20KPIToken} from "../../../contracts/kpi-tokens/ERC20KPIToken.sol";
import {IOraclesManager} from "../../../contracts/interfaces/IOraclesManager.sol";
import {Clones} from "oz/proxy/Clones.sol";
import {IERC20KPIToken} from "../../../contracts/interfaces/kpi-tokens/IERC20KPIToken.sol";
import {TokenAmount} from "../../../contracts/commons/Types.sol";

/**
 * @title ERC20KPITokenGetProtocolFeesTest
 * @dev ERC20KPITokenGetProtocolFeesTest contract
 * @author Federico Luzzi - <federico.luzzi@protonmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract ERC20KPITokenGetProtocolFeesTest is BaseTestSetup {
    function testTooManyCollaterals() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        IERC20KPIToken.Collateral[]
            memory collaterals = new IERC20KPIToken.Collateral[](6);
        for (uint160 i = 1; i <= 6; i++)
            collaterals[i - 1] = IERC20KPIToken.Collateral({
                token: address(i),
                amount: i,
                minimumPayout: i - 1
            });

        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("TooManyCollaterals()")
        );
        kpiTokenInstance.protocolFee(abi.encode(collaterals));
    }

    function testZeroAmountCollateral() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        TokenAmount[] memory collaterals = new TokenAmount[](1);
        collaterals[0] = TokenAmount({token: address(firstErc20), amount: 0});

        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("InvalidCollateral()")
        );
        kpiTokenInstance.protocolFee(abi.encode(collaterals));
    }

    function testZeroAddressCollateral() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        TokenAmount[] memory collaterals = new TokenAmount[](1);
        collaterals[0] = TokenAmount({token: address(0), amount: 1});

        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("InvalidCollateral()")
        );
        kpiTokenInstance.protocolFee(abi.encode(collaterals));
    }

    function testDuplicateCollateral() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        TokenAmount[] memory collaterals = new TokenAmount[](2);
        collaterals[0] = TokenAmount({
            token: address(firstErc20),
            amount: 10 ether
        });
        collaterals[1] = TokenAmount({
            token: address(firstErc20),
            amount: 10 ether
        });

        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("DuplicatedCollateral()")
        );
        kpiTokenInstance.protocolFee(abi.encode(collaterals));
    }

    function testSuccess() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        TokenAmount[] memory collaterals = new TokenAmount[](2);
        collaterals[0] = TokenAmount({token: address(1), amount: 10 ether});
        collaterals[1] = TokenAmount({token: address(2), amount: 5 ether});

        TokenAmount[] memory fees = abi.decode(
            kpiTokenInstance.protocolFee(abi.encode(collaterals)),
            (TokenAmount[])
        );

        assertEq(fees.length, 2);
        assertEq(fees[0].token, collaterals[0].token);
        assertEq(fees[0].amount, 30000000000000000);
        assertEq(fees[1].token, collaterals[1].token);
        assertEq(fees[1].amount, 15000000000000000);
    }
}

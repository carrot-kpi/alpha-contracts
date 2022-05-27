pragma solidity 0.8.14;

import {BaseTestSetup} from "../commons/BaseTestSetup.sol";

/**
 * @title FactorySetFeeReceiverTest
 * @dev FactorySetFeeReceiverTest contract
 * @author Federico Luzzi - <federico.luzzi@protonmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract FactorySetFeeReceiverTest is BaseTestSetup {
    function testNonOwner() external {
        CHEAT_CODES.prank(address(1));
        CHEAT_CODES.expectRevert(abi.encodeWithSignature("Forbidden()"));
        factory.setFeeReceiver(address(2));
    }

    function testZeroAddressFeeReceiver() external {
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("ZeroAddressFeeReceiver()")
        );
        factory.setFeeReceiver(address(0));
    }

    function testSuccess() external {
        assertEq(factory.feeReceiver(), feeReceiver);
        address _newFeeReceiver = address(2);
        factory.setFeeReceiver(_newFeeReceiver);
        assertEq(factory.feeReceiver(), _newFeeReceiver);
    }
}

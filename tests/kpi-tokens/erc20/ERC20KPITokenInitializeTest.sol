pragma solidity 0.8.13;

import {BaseTestSetup} from "../../commons/BaseTestSetup.sol";
import {ERC20KPIToken} from "../../../contracts/kpi-tokens/ERC20KPIToken.sol";
import {IOraclesManager} from "../../../contracts/interfaces/IOraclesManager.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IERC20KPIToken} from "../../../contracts/interfaces/kpi-tokens/IERC20KPIToken.sol";

/**
 * @title ERC20KPITokenInitializeTest
 * @dev ERC20KPITokenInitializeTest contract
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
contract ERC20KPITokenInitializeTest is BaseTestSetup {
    function testZeroAddressCreator() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );
        CHEAT_CODES.expectRevert(abi.encodeWithSignature("InvalidCreator()"));
        kpiTokenInstance.initialize(
            address(0),
            address(0),
            0,
            "a",
            abi.encode(uint256(1))
        );
    }

    function testZeroAddressKpiTokensManager() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("InvalidKpiTokensManager()")
        );
        kpiTokenInstance.initialize(
            address(1),
            address(0),
            0,
            "a",
            abi.encode(uint256(1))
        );
    }

    function testEmptyDescription() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );
        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("InvalidDescription()")
        );
        kpiTokenInstance.initialize(
            address(1),
            address(1),
            0,
            "",
            abi.encode(uint256(1))
        );
    }

    function testInvalidData() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );
        CHEAT_CODES.expectRevert();
        kpiTokenInstance.initialize(
            address(1),
            address(1),
            0,
            "a",
            abi.encode(uint256(1))
        );
    }

    function testTooManyCollaterals() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        IERC20KPIToken.Collateral[]
            memory collaterals = new IERC20KPIToken.Collateral[](6);
        for (uint8 i = 0; i < 6; i++)
            collaterals[i] = IERC20KPIToken.Collateral({
                token: address(uint160(i)),
                amount: i,
                minimumPayout: 0
            });

        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("TooManyCollaterals()")
        );
        kpiTokenInstance.initialize(
            address(1),
            address(1),
            0,
            "a",
            abi.encode(collaterals, "Token", "TKN", 10 ether)
        );
    }

    function testInvalidName() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        IERC20KPIToken.Collateral[]
            memory collaterals = new IERC20KPIToken.Collateral[](5);
        for (uint8 i = 0; i < 5; i++)
            collaterals[i] = IERC20KPIToken.Collateral({
                token: address(uint160(i)),
                amount: i,
                minimumPayout: 0
            });

        CHEAT_CODES.expectRevert(abi.encodeWithSignature("InvalidName()"));
        kpiTokenInstance.initialize(
            address(1),
            address(1),
            0,
            "a",
            abi.encode(collaterals, "", "TKN", 10 ether)
        );
    }

    function testInvalidSymbol() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        IERC20KPIToken.Collateral[]
            memory collaterals = new IERC20KPIToken.Collateral[](5);
        for (uint8 i = 0; i < 5; i++)
            collaterals[i] = IERC20KPIToken.Collateral({
                token: address(uint160(i)),
                amount: i,
                minimumPayout: 0
            });

        CHEAT_CODES.expectRevert(abi.encodeWithSignature("InvalidSymbol()"));
        kpiTokenInstance.initialize(
            address(1),
            address(1),
            0,
            "a",
            abi.encode(collaterals, "Token", "", 10 ether)
        );
    }

    function testInvalidSupply() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        IERC20KPIToken.Collateral[]
            memory collaterals = new IERC20KPIToken.Collateral[](5);
        for (uint8 i = 0; i < 5; i++)
            collaterals[i] = IERC20KPIToken.Collateral({
                token: address(uint160(i)),
                amount: i,
                minimumPayout: 0
            });

        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("InvalidTotalSupply()")
        );
        kpiTokenInstance.initialize(
            address(1),
            address(1),
            0,
            "a",
            abi.encode(collaterals, "Token", "TKN", 0)
        );
    }

    function testZeroAddressCollateral() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        IERC20KPIToken.Collateral[]
            memory collaterals = new IERC20KPIToken.Collateral[](1);
        collaterals[0] = IERC20KPIToken.Collateral({
            token: address(0),
            amount: 0,
            minimumPayout: 0
        });

        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("InvalidCollateral()")
        );
        kpiTokenInstance.initialize(
            address(1),
            address(1),
            0,
            "a",
            abi.encode(collaterals, "Token", "TKN", 10 ether)
        );
    }

    function testZeroAmountCollateral() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        IERC20KPIToken.Collateral[]
            memory collaterals = new IERC20KPIToken.Collateral[](1);
        collaterals[0] = IERC20KPIToken.Collateral({
            token: address(1),
            amount: 0,
            minimumPayout: 0
        });

        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("InvalidCollateral()")
        );
        kpiTokenInstance.initialize(
            address(1),
            address(1),
            0,
            "a",
            abi.encode(collaterals, "Token", "TKN", 10 ether)
        );
    }

    function testSameMinimumPayoutCollateral() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        IERC20KPIToken.Collateral[]
            memory collaterals = new IERC20KPIToken.Collateral[](1);
        collaterals[0] = IERC20KPIToken.Collateral({
            token: address(1),
            amount: 1,
            minimumPayout: 1
        });

        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("InvalidCollateral()")
        );
        kpiTokenInstance.initialize(
            address(1),
            address(1),
            0,
            "a",
            abi.encode(collaterals, "Token", "TKN", 10 ether)
        );
    }

    function testGreaterMinimumPayoutCollateral() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        IERC20KPIToken.Collateral[]
            memory collaterals = new IERC20KPIToken.Collateral[](1);
        collaterals[0] = IERC20KPIToken.Collateral({
            token: address(1),
            amount: 1,
            minimumPayout: 10
        });

        CHEAT_CODES.expectRevert(
            abi.encodeWithSignature("InvalidCollateral()")
        );
        kpiTokenInstance.initialize(
            address(1),
            address(1),
            0,
            "a",
            abi.encode(collaterals, "Token", "TKN", 10 ether)
        );
    }

    function testSuccess() external {
        ERC20KPIToken kpiTokenInstance = ERC20KPIToken(
            Clones.clone(address(erc20KpiTokenTemplate))
        );

        firstErc20.mint(address(this), 10 ether);
        firstErc20.approve(address(kpiTokenInstance), 10 ether);

        IERC20KPIToken.Collateral[]
            memory collaterals = new IERC20KPIToken.Collateral[](1);
        collaterals[0] = IERC20KPIToken.Collateral({
            token: address(firstErc20),
            amount: 10 ether,
            minimumPayout: 1 ether
        });

        kpiTokenInstance.initialize(
            address(this),
            address(kpiTokensManager),
            10,
            "a",
            abi.encode(collaterals, "Token", "TKN", 100 ether)
        );

        (
            IERC20KPIToken.Collateral[] memory onChainCollaterals,
            IERC20KPIToken.FinalizableOracle[] memory onChainFinalizableOracles,
            bool onChainAndRelationship,
            uint256 onChainInitialSupply,
            string memory onChainName,
            string memory onChainSymbol
        ) = abi.decode(
                kpiTokenInstance.data(),
                (
                    IERC20KPIToken.Collateral[],
                    IERC20KPIToken.FinalizableOracle[],
                    bool,
                    uint256,
                    string,
                    string
                )
            );

        assertEq(onChainCollaterals.length, 1);
        assertEq(onChainCollaterals[0].token, address(firstErc20));
        assertEq(onChainCollaterals[0].amount, 10 ether);
        assertEq(onChainCollaterals[0].minimumPayout, 1 ether);
        assertEq(onChainFinalizableOracles.length, 0);
        assertEq(kpiTokenInstance.totalSupply(), 100 ether);
        assertEq(onChainInitialSupply, 100 ether);
        assertEq(kpiTokenInstance.creator(), address(this));
        assertEq(kpiTokenInstance.description(), "a");
        assertTrue(!onChainAndRelationship);
        assertEq(onChainName, "Token");
        assertEq(onChainSymbol, "TKN");
    }
}

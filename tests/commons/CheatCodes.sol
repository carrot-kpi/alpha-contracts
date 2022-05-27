pragma solidity 0.8.14;

/**
 * @title CheatCodes
 * @dev CheatCodes contract
 * @author Federico Luzzi - <federico.luzzi@protonmail.com>
 * SPDX-License-Identifier: GPL-3.0
 */
interface CheatCodes {
    function warp(uint256) external;

    function roll(uint256) external;

    function fee(uint256) external;

    function load(address account, bytes32 slot) external returns (bytes32);

    function store(
        address account,
        bytes32 slot,
        bytes32 value
    ) external;

    function sign(uint256 privateKey, bytes32 digest)
        external
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        );

    function addr(uint256 privateKey) external returns (address);

    function ffi(string[] calldata) external returns (bytes memory);

    function prank(address) external;

    function startPrank(address) external;

    function prank(address, address) external;

    function startPrank(address, address) external;

    function stopPrank() external;

    function deal(address who, uint256 newBalance) external;

    function etch(address who, bytes calldata code) external;

    function expectRevert() external;

    function expectRevert(bytes calldata) external;

    function expectRevert(bytes4) external;

    function record() external;

    function accesses(address)
        external
        returns (bytes32[] memory reads, bytes32[] memory writes);

    function expectEmit(
        bool,
        bool,
        bool,
        bool
    ) external;

    function mockCall(
        address,
        bytes calldata,
        bytes calldata
    ) external;

    function clearMockedCalls() external;

    function expectCall(address, bytes calldata) external;

    function getCode(string calldata) external returns (bytes memory);

    function label(address addr, string calldata label) external;

    function assume(bool) external;
}

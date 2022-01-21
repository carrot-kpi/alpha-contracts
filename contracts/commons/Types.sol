pragma solidity ^0.8.11;

/**
 * @title Common types
 * @dev Common types
 * @author Federico Luzzi - <fedeluzzi00@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */



struct RedeemedCollateral {
    address token;
    uint256 amount;
}

struct Oracle {
    address addrezz;
    uint256 lowerBound;
    uint256 higherBound;
    uint256 weight;
}

struct OracleCreationData {
    address template;
    bytes initializationData;
    uint256 jobFunding;
}

struct KpiTokenCreationOracle {
    address template;
    uint256 lowerBound;
    uint256 higherBound;
    uint256 jobFunding;
    uint256 weight;
    bytes initializationData;
}

struct FinalizableOracle {
    uint256 lowerBound;
    uint256 higherBound;
    uint256 finalProgress;
    uint256 weight;
    bool finalized;
}

struct Template {
    string description;
    bool exists;
    bool automatable;
}

struct EnumerableTemplateSet {
    mapping(address => Template) map;
    address[] keys;
}

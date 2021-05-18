import { constants, ContractReceipt } from "ethers";
import { solidityKeccak256, solidityPack } from "ethers/lib/utils";
import { ethers } from "hardhat";

const { provider } = ethers;

export const encodeRealityQuestion = (question: string): string => {
    question = JSON.stringify(question).replace(/^"|"$/g, "");
    return `${question}\u241fkpi\u241fen_US`;
};

export const getKpiTokenAddressFromReceipt = (receipt: ContractReceipt) => {
    if (!receipt.events) throw new Error("no events emitted");
    const creationEvent = receipt.events.find(
        (event) => event.event === "KpiTokenCreated"
    );
    if (!creationEvent) throw new Error("no creation event emitted");
    if (!creationEvent.args) throw new Error("no creation event args");
    const address = creationEvent.args.kpiToken;
    if (address === constants.AddressZero)
        throw new Error("zero address kpi token");
    return address;
};

export const getRealityQuestionId = (
    templateId: number,
    openingTimestamp: number,
    question: string,
    arbitratorAddress: string,
    timeout: number,
    creatorAddress: string,
    nonce: number
) => {
    const contentHash = solidityKeccak256(
        ["bytes"],
        [
            solidityPack(
                ["uint256", "uint32", "string"],
                [templateId, openingTimestamp, question]
            ),
        ]
    );
    return solidityKeccak256(
        ["bytes"],
        [
            solidityPack(
                ["bytes32", "address", "uint32", "address", "uint256"],
                [contentHash, arbitratorAddress, timeout, creatorAddress, nonce]
            ),
        ]
    );
};

export const fastForwardTo = async (timestamp: number) => {
    await provider.send("evm_mine", [timestamp]);
};

export const fastForward = async (seconds: number) => {
    const { timestamp: evmTimestamp } = await provider.getBlock("latest");
    await provider.send("evm_mine", [evmTimestamp + seconds]);
};

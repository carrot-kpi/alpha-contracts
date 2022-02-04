import { defaultAbiCoder } from "ethers/lib/utils";
import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";

interface TaskArguments {
    realityAddress: string;
    arbitratorAddress: string;
    question: string;
    questionTimeout: string;
    expiry: string;
}

task(
    "get-manual-reality-orace-calldata",
    "Gets manual Reality.eth's oracle calldata"
)
    .addParam("realityAddress", "Reality address")
    .addParam("arbitratorAddress", "Arbitrator address")
    .addParam("question", "Question")
    .addParam("questionTimeout", "Question timeout")
    .addParam("expiry", "Expiry")
    .setAction(
        async (
            {
                realityAddress,
                arbitratorAddress,
                question,
                questionTimeout,
                expiry,
            }: TaskArguments,
            hre: HardhatRuntimeEnvironment
        ) => {
            console.log(
                defaultAbiCoder.encode(
                    ["address", "address", "string", "uint32", "uint32"],
                    [
                        realityAddress,
                        arbitratorAddress,
                        question,
                        questionTimeout,
                        expiry,
                    ]
                )
            );
        }
    );

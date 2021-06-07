import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import {
    KPIToken__factory,
    KPIToken,
    KPITokensFactory__factory,
    KPITokensFactory,
} from "../typechain";

interface TaskArguments {
    verify: boolean;
    fee: string;
    realityAddress: string;
    arbitratorAddress: string;
    voteTimeout: string;
    feeReceiverAddress: string;
}

task(
    "deploy",
    "Deploys the whole contracts suite and verifies source code on Etherscan"
)
    .addParam("fee", "Fee to be applied when creating the KPI token (in bips)")
    .addParam("realityAddress", "Reality.eth contract address")
    .addParam("arbitratorAddress", "Arbitrator contract address")
    .addParam("feeReceiverAddress", "Fee receiver contract address")
    .addParam("voteTimeout", "Minimum vote timeout in seconds")
    .addFlag(
        "verify",
        "Additional (and optional) Etherscan contracts verification"
    )
    .setAction(
        async (
            {
                verify,
                fee,
                realityAddress,
                arbitratorAddress,
                voteTimeout,
                feeReceiverAddress,
            }: TaskArguments,
            hre: HardhatRuntimeEnvironment
        ) => {
            await hre.run("clean");
            await hre.run("compile");

            const kpiTokenImplementationFactory = (await hre.ethers.getContractFactory(
                "KPIToken"
            )) as KPIToken__factory;
            console.log("Deploying KPI token implementation template");
            const kpiTokenImplementation = (await kpiTokenImplementationFactory.deploy()) as KPIToken;

            const kpiTokensFactoryFactory = (await hre.ethers.getContractFactory(
                "KPITokensFactory"
            )) as KPITokensFactory__factory;
            console.log("Deploying KPI tokens factory");
            const kpiTokensFactory = (await kpiTokensFactoryFactory.deploy(
                kpiTokenImplementation.address,
                realityAddress,
                arbitratorAddress,
                fee,
                voteTimeout,
                feeReceiverAddress
            )) as KPITokensFactory;

            if (verify) {
                await new Promise((resolve) => {
                    console.log("Waiting before source code verification...");
                    setTimeout(resolve, 60000);
                });

                console.log(
                    "Verifying KPI token implementation template source code"
                );
                await hre.run("verify", {
                    address: kpiTokenImplementation.address,
                    constructorArgsParams: [],
                });

                console.log("Verifying KPI tokens factory source code");
                await hre.run("verify", {
                    address: kpiTokensFactory.address,
                    constructorArgsParams: [
                        kpiTokenImplementation.address,
                        realityAddress,
                        arbitratorAddress,
                        fee,
                        voteTimeout,
                        feeReceiverAddress,
                    ],
                });

                console.log(`Source code verified`);
            }

            console.log(
                `Factory deployed at address ${kpiTokensFactory.address}`
            );
        }
    );

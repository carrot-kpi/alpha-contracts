import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";

interface TaskArguments {
    factoryAddress: string;
    question: string;
    collateralAddress: string;
    collateralAmount: string;
    tokenName: string;
    tokenSymbol: string;
    lowerBound: string;
    higherBound: string;
    arbitratorAddress: string;
    voteTimeout: string;
    expiry: string;
    totalSupply: string;
}

task("get-create-kpi-token-calldata", "Gets create KPI token calldata")
    .addParam("question", "KPI question")
    .addParam("arbitratorAddress", "Arbitrator address")
    .addParam("voteTimeout", "Vote timeout")
    .addParam("collateralAddress", "Collateral address")
    .addParam("collateralAmount", "Collateral amount")
    .addParam("tokenName", "Token name")
    .addParam("tokenSymbol", "Token symbol")
    .addParam("totalSupply", "Token total supply")
    .addParam("lowerBound", "Scalar lower bound")
    .addParam("higherBound", "Scalar higher bound")
    .addParam("expiry", "The expiry timestamp (seconds since UNIX epoch)")
    .setAction(
        async (
            {
                question,
                collateralAddress,
                collateralAmount,
                tokenName,
                tokenSymbol,
                lowerBound,
                higherBound,
                arbitratorAddress,
                voteTimeout,
                expiry,
                totalSupply,
            }: TaskArguments,
            hre: HardhatRuntimeEnvironment
        ) => {
            await hre.run("clean");
            await hre.run("compile");

            const factory = await hre.ethers.getContractFactory(
                "KPITokensFactory"
            );
            console.log(
                factory.interface.encodeFunctionData("createKpiToken", [
                    {
                        question: `${JSON.stringify(question).replace(
                            /^"|"$/g,
                            ""
                        )}\u241fkpi\u241fen_US`,
                        arbitrator: arbitratorAddress,
                        expiry,
                        timeout: voteTimeout,
                    },
                    {
                        token: collateralAddress,
                        amount: collateralAmount,
                    },
                    {
                        name: tokenName,
                        symbol: tokenSymbol,
                        totalSupply,
                    },
                    { lowerBound, higherBound },
                ])
            );
        }
    );

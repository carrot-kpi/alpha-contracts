import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DateTime } from "luxon";
import { encodeRealityQuestion } from "../test/utils";
import { KPITokensFactory__factory } from "../typechain";

interface TaskArguments {
    factoryAddress: string;
    question: string;
    collateralAddress: string;
    collateralAmount: string;
    tokenName: string;
    tokenSymbol: string;
    lowerBound: string;
    higherBound: string;
}

task("create-kpi-token", "Creates a KPI token")
    .addParam("factoryAddress", "The KPI tokens factory address")
    .addParam("question", "KPI question")
    .addParam("collateralAddress", "Collateral address")
    .addParam("collateralAmount", "Collateral amount")
    .addParam("tokenName", "Token name")
    .addParam("tokenSymbol", "Token symbol")
    .addParam("lowerBound", "Scalar lower bound")
    .addParam("higherBound", "Scalar higher bound")
    .setAction(
        async (
            {
                factoryAddress,
                question,
                collateralAddress,
                collateralAmount,
                tokenName,
                tokenSymbol,
                lowerBound,
                higherBound,
            }: TaskArguments,
            hre: HardhatRuntimeEnvironment
        ) => {
            await hre.run("clean");
            await hre.run("compile");
            const [signer] = await hre.ethers.getSigners();

            const factory = await KPITokensFactory__factory.connect(
                factoryAddress,
                signer
            );
            const encodedRealityQuestion = `${JSON.stringify(question).replace(
                /^"|"$/g,
                ""
            )}\u241fkpi\u241fen_US`;
            console.log("creating");
            const transaction = await factory.createKpiToken(
                encodedRealityQuestion,
                Math.floor(DateTime.now().plus({ days: 3 }).toMillis() / 1000),
                {
                    token: collateralAddress,
                    amount: collateralAmount,
                },
                {
                    name: tokenName,
                    symbol: tokenSymbol,
                    totalSupply: "100000000000000000000000", //100k
                },
                { lowerBound, higherBound }
            );
            await transaction.wait();

            console.log("KPI token created");
        }
    );

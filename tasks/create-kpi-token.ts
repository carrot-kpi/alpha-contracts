import { parseEther } from "ethers/lib/utils";
import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DateTime } from "luxon";

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
}

const getCollateralAmountPlusFees = (baseAmount: string) => {
    const properBaseAmount = parseEther(baseAmount);
    const feeAmount = properBaseAmount.mul(30).div(10000);
    return {
        baseAmount: properBaseAmount,
        feeAmount,
        totalAmount: properBaseAmount.add(feeAmount),
    };
};

task("create-kpi-token", "Creates a KPI token")
    .addParam("factoryAddress", "The KPI tokens factory address")
    .addParam("question", "KPI question")
    .addParam("arbitratorAddress", "Arbitrator address")
    .addParam("voteTimeout", "Vote timeout")
    .addParam("collateralAddress", "Collateral address")
    .addParam("collateralAmount", "Collateral amount")
    .addParam("tokenName", "Token name")
    .addParam("tokenSymbol", "Token symbol")
    .addParam("lowerBound", "Scalar lower bound")
    .addParam("higherBound", "Scalar higher bound")
    .addOptionalParam("expiry", "The expiry timestamp (seconds since UNIX epoch)")
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
                arbitratorAddress,
                voteTimeout,
                expiry,
            }: TaskArguments,
            hre: HardhatRuntimeEnvironment
        ) => {
            await hre.run("clean");
            await hre.run("compile");
            const [signer] = await hre.ethers.getSigners();

            const collateralErc20 = (
                await hre.ethers.getContractFactory("ERC20")
            )
                .attach(collateralAddress)
                .connect(signer);
            const { totalAmount, baseAmount } = getCollateralAmountPlusFees(
                collateralAmount
            );
            if (
                await (
                    await collateralErc20.allowance(
                        signer.address,
                        factoryAddress
                    )
                ).lt(totalAmount)
            ) {
                console.log("approving collateral");
                const approveTx = await collateralErc20.approve(
                    factoryAddress,
                    totalAmount
                );
                await approveTx.wait();
                console.log("collateral approved");
            }

            const factory = await (
                await hre.ethers.getContractFactory("KPITokensFactory")
            )
                .attach(factoryAddress)
                .connect(signer);
            const encodedRealityQuestion = `${JSON.stringify(question).replace(
                /^"|"$/g,
                ""
            )}\u241fkpi\u241fen_US`;
            console.log("creating");
            const transaction = await factory.createKpiToken(
                {
                    question: encodedRealityQuestion,
                    arbitrator: arbitratorAddress,
                    expiry: expiry || Math.floor(
                        DateTime.now().plus({ minutes: 2 }).toSeconds()
                    ),
                    timeout: voteTimeout,
                },
                {
                    token: collateralAddress,
                    amount: baseAmount,
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

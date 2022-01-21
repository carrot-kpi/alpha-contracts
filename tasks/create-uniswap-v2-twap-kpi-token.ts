import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";

interface TaskArguments {
    workersTokenAddress: string;
    workersTokenFunding: string;
    factoryAddress: string;
    collateralAddress: string;
    collateralAmount: string;
    pairAddress: string;
    tokenAddress: string;
    workersMasterAddress: string;
    startsAt: string;
    endsAt: string;
    refreshRate: string;
}

task(
    "create-uniswap-v2-twap-kpi-token",
    "Creates a KPI token tracking the liquidity value of a Uniswap v2 fork pair"
)
    .addParam("workersTokenAddress")
    .addParam("workersTokenFunding")
    .addParam("factoryAddress")
    .addParam("collateralAddress")
    .addParam("collateralAmount")
    .addParam("pairAddress")
    .addParam("tokenAddress")
    .addParam("workersMasterAddress")
    .addParam("startsAt")
    .addParam("endsAt")
    .addParam("refreshRate")
    .setAction(
        async (
            {
                workersTokenAddress,
                workersTokenFunding,
                collateralAddress,
                collateralAmount,
                factoryAddress,
                pairAddress,
                tokenAddress,
                workersMasterAddress,
                startsAt,
                endsAt,
                refreshRate,
            }: TaskArguments,
            hre: HardhatRuntimeEnvironment
        ) => {
            await hre.run("clean");
            await hre.run("compile");
            const [signer] = await hre.ethers.getSigners();

            const jobFundingAmount =
                hre.ethers.utils.parseEther(workersTokenFunding);
            const workersToken = await (
                await hre.ethers.getContractFactory("ERC20")
            ).attach(workersTokenAddress);
            if (
                (
                    await workersToken.allowance(signer.address, factoryAddress)
                ).lt(jobFundingAmount)
            ) {
                const approveTx = await workersToken.approve(
                    factoryAddress,
                    jobFundingAmount
                );
                await approveTx.wait();
                console.log("Worker tokens approved");
            }

            const parsedCollateralAmount =
                hre.ethers.utils.parseEther(collateralAmount);
            const collateralToken = await (
                await hre.ethers.getContractFactory("ERC20")
            ).attach(collateralAddress);
            if (
                (
                    await collateralToken.allowance(
                        signer.address,
                        factoryAddress
                    )
                ).lt(parsedCollateralAmount)
            ) {
                const approveTx = await collateralToken.approve(
                    factoryAddress,
                    parsedCollateralAmount
                );
                await approveTx.wait();
                console.log("Collateral token approved");
            }

            const factory = await (
                await hre.ethers.getContractFactory("KPITokensFactory")
            )
                .attach(factoryAddress)
                .connect(signer);
            const creationTx = await factory.createToken(
                0,
                jobFundingAmount,
                hre.ethers.utils.defaultAbiCoder.encode(
                    [
                        "address",
                        "address",
                        "address",
                        "uint64",
                        "uint64",
                        "uint32",
                    ],
                    [
                        workersMasterAddress,
                        pairAddress,
                        tokenAddress,
                        startsAt,
                        endsAt,
                        refreshRate,
                    ]
                ),
                {
                    token: collateralAddress,
                    amount: parsedCollateralAmount,
                },
                {
                    name: "KPI",
                    symbol: "KPI",
                    totalSupply: hre.ethers.utils.parseEther("100000"),
                },
                { lowerBound: 0, higherBound: 1 }
            );
            await creationTx.wait();

            console.log("KPI token created");
        }
    );

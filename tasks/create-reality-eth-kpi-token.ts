import { formatBytes32String } from "ethers/lib/utils";
import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";

interface TaskArguments {
    kpiTemplateAddress: string;
    oracleTemplateAddress: string;
    factoryAddress: string;
    workersTokenFunding: string;
    workersTokenAddress: string;
    collateralAddress: string;
    collateralAmount: string;
    realityAddress: string;
    arbitratorAddress: string;
    questionText: string;
    questionTimeout: string;
    expiry: string;
    binary: string;
}

task(
    "create-reality-eth-kpi-token",
    "Creates a KPI token based on the outcome of a Reality.eth question"
)
    .addParam("kpiTemplateAddress")
    .addParam("oracleTemplateAddress")
    .addParam("factoryAddress")
    .addParam("workersTokenFunding")
    .addParam("workersTokenAddress")
    .addParam("collateralAddress")
    .addParam("collateralAmount")
    .addParam("realityAddress")
    .addParam("arbitratorAddress")
    .addParam("questionText")
    .addParam("questionTimeout")
    .addParam("expiry")
    .setAction(
        async (
            {
                kpiTemplateAddress,
                oracleTemplateAddress,
                factoryAddress,
                workersTokenFunding,
                workersTokenAddress,
                collateralAddress,
                collateralAmount,
                realityAddress,
                arbitratorAddress,
                questionText,
                questionTimeout,
                expiry,
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

            const factory = await (
                await hre.ethers.getContractFactory("KPITokensFactory")
            )
                .attach(factoryAddress)
                .connect(signer);
            const fee = await factory.fee();
            console.log("FEE", fee);
            const parsedRawCollateralAmount =
                hre.ethers.utils.parseEther(collateralAmount);
            const collateralAllowanceAmount = parsedRawCollateralAmount.add(
                parsedRawCollateralAmount.mul(fee).div(10000)
            );
            const collateralToken = await (
                await hre.ethers.getContractFactory("ERC20")
            ).attach(collateralAddress);
            if (
                (
                    await collateralToken.allowance(
                        signer.address,
                        factoryAddress
                    )
                ).lt(collateralAllowanceAmount)
            ) {
                const approveTx = await collateralToken.approve(
                    factoryAddress,
                    collateralAllowanceAmount
                );
                console.log("Collateral token approving");
                await approveTx.wait();
                console.log("Collateral token approved");
            }

            const creationTx = await factory.createToken(
                kpiTemplateAddress,
                [
                    {
                        token: collateralAddress,
                        amount: parsedRawCollateralAmount,
                    },
                ],
                [
                    {
                        template: oracleTemplateAddress,
                        lowerBound: 0,
                        higherBound: 1,
                        jobFunding: jobFundingAmount,
                        weight: 1,
                        initializationData:
                            hre.ethers.utils.defaultAbiCoder.encode(
                                [
                                    "address",
                                    "address",
                                    "address",
                                    "string",
                                    "uint32",
                                    "uint32",
                                    "bool",
                                ],
                                [
                                    realityAddress,
                                    arbitratorAddress,
                                    questionText,
                                    questionTimeout,
                                    expiry,
                                    true,
                                ]
                            ),
                    },
                ],
                true,
                hre.ethers.utils.defaultAbiCoder.encode(
                    ["bytes32", "bytes32", "uint256"],
                    [
                        formatBytes32String("Reality.eth KPI"),
                        formatBytes32String("KPI"),
                        hre.ethers.utils.parseEther("100000"),
                    ]
                )
            );
            await creationTx.wait();

            console.log("KPI token created");
        }
    );

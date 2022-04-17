import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";

interface TaskArguments {
    kpiTemplateId: string;
    oracleTemplateId: string;
    factoryAddress: string;
    kpiTokensManagerAddress: string;
    collateralAddress: string;
    collateralAmount: string;
    realityAddress: string;
    arbitratorAddress: string;
    questionText: string;
    questionTimeout: string;
    expiry: string;
    description: string;
}

task(
    "create-manual-reality-eth-erc20-kpi-token",
    "Creates a manual KPI token based on the outcome of a Reality.eth question"
)
    .addParam("kpiTemplateId")
    .addParam("oracleTemplateId")
    .addParam("factoryAddress")
    .addParam("kpiTokensManagerAddress")
    .addParam("collateralAddress")
    .addParam("collateralAmount")
    .addParam("realityAddress")
    .addParam("arbitratorAddress")
    .addParam("questionText")
    .addParam("questionTimeout")
    .addParam("expiry")
    .addParam("description")
    .setAction(
        async (
            {
                kpiTemplateId,
                oracleTemplateId,
                factoryAddress,
                kpiTokensManagerAddress,
                collateralAddress,
                collateralAmount,
                realityAddress,
                arbitratorAddress,
                questionText,
                questionTimeout,
                expiry,
                description,
            }: TaskArguments,
            hre: HardhatRuntimeEnvironment
        ) => {
            await hre.run("clean");
            await hre.run("compile");
            const [signer] = await hre.ethers.getSigners();

            const factory = await await hre.ethers.getContractAt(
                "KPITokensFactory",
                factoryAddress,
                signer
            );

            const collateralToken = await hre.ethers.getContractAt(
                "ERC20",
                collateralAddress
            );
            const collateralTokenDecimals = await collateralToken.decimals();
            const parsedRawCollateralAmount = hre.ethers.utils.parseUnits(
                collateralAmount,
                collateralTokenDecimals
            );

            const kpiTokenInitializationData =
                hre.ethers.utils.defaultAbiCoder.encode(
                    [
                        "address[]",
                        "uint256[]",
                        "uint256[]",
                        "bytes32",
                        "bytes32",
                        "uint256",
                    ],
                    [
                        [collateralAddress],
                        [parsedRawCollateralAmount],
                        [0],
                        hre.ethers.utils.formatBytes32String(
                            "Manual Reality.eth KPI"
                        ),
                        hre.ethers.utils.formatBytes32String("KPI"),
                        hre.ethers.utils.parseEther("100000"),
                    ]
                );

            const oraclesInitializationData =
                hre.ethers.utils.defaultAbiCoder.encode(
                    [
                        "uint256[]",
                        "uint256[]",
                        "uint256[]",
                        "uint256[]",
                        "bytes[]",
                        "bool",
                    ],
                    [
                        [oracleTemplateId],
                        [0],
                        [1],
                        [1],
                        [
                            hre.ethers.utils.defaultAbiCoder.encode(
                                [
                                    "address",
                                    "address",
                                    "uint256",
                                    "string",
                                    "uint32",
                                    "uint32",
                                ],
                                [
                                    realityAddress,
                                    arbitratorAddress,
                                    0,
                                    `${questionText}␟carrot␟en`,
                                    questionTimeout,
                                    expiry,
                                ]
                            ),
                        ],
                        false,
                    ]
                );

            const kpiTokensManagerFactory = await hre.ethers.getContractAt(
                "KPITokensManager",
                kpiTokensManagerAddress,
                signer
            );
            const predictedKpiTokenAddress =
                await kpiTokensManagerFactory.predictInstanceAddress(
                    kpiTemplateId,
                    description,
                    kpiTokenInitializationData,
                    oraclesInitializationData
                );

            console.log(
                "Predicted KPI token address",
                predictedKpiTokenAddress
            );
            if (
                (
                    await collateralToken.allowance(
                        signer.address,
                        predictedKpiTokenAddress
                    )
                ).lt(parsedRawCollateralAmount)
            ) {
                const approveTx = await collateralToken.approve(
                    predictedKpiTokenAddress,
                    parsedRawCollateralAmount
                );
                console.log("Collateral token approving");
                await approveTx.wait();
                console.log("Collateral token approved");
            }

            const creationTx = await factory.createToken(
                kpiTemplateId,
                description,
                kpiTokenInitializationData,
                oraclesInitializationData
            );
            await creationTx.wait();

            console.log("KPI token created");
        }
    );

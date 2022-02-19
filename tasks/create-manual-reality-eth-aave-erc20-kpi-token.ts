import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { IKPITokensManager__factory } from "../typechain-types";

interface TaskArguments {
    kpiTemplateId: string;
    oracleTemplateId: string;
    factoryAddress: string;
    kpiTokensManagerAddress: string;
    collateralAddress: string;
    collateralAmount: string;
    aavePoolAddress: string;
    realityAddress: string;
    arbitratorAddress: string;
    questionText: string;
    questionTimeout: string;
    expiry: string;
    description: string;
}

task(
    "create-manual-reality-eth-aave-erc20-kpi-token",
    "Creates a manual KPI token based on the outcome of a Reality.eth question"
)
    .addParam("kpiTemplateId")
    .addParam("oracleTemplateId")
    .addParam("factoryAddress")
    .addParam("kpiTokensManagerAddress")
    .addParam("collateralAddress")
    .addParam("collateralAmount")
    .addParam("aavePoolAddress")
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
                aavePoolAddress,
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

            const factory = await (
                await hre.ethers.getContractFactory("KPITokensFactory")
            )
                .attach(factoryAddress)
                .connect(signer);

            const collateralToken = await (
                await hre.ethers.getContractFactory("ERC20")
            ).attach(collateralAddress);
            const collateralTokenDecimals = await collateralToken.decimals();
            const parsedRawCollateralAmount = hre.ethers.utils.parseUnits(
                collateralAmount,
                collateralTokenDecimals
            );

            const kpiTokenInitializationData =
                hre.ethers.utils.defaultAbiCoder.encode(
                    [
                        "address",
                        "address[]",
                        "uint256[]",
                        "uint256[]",
                        "bytes32",
                        "bytes32",
                        "uint256",
                    ],
                    [
                        aavePoolAddress,
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
                        "address[]",
                        "uint256[]",
                        "uint256[]",
                        "bytes[]",
                        "bool",
                    ],
                    [
                        [oracleTemplateId],
                        [0],
                        [1],
                        [hre.ethers.constants.AddressZero],
                        [0],
                        [1],
                        [
                            hre.ethers.utils.defaultAbiCoder.encode(
                                [
                                    "address",
                                    "address",
                                    "string",
                                    "uint32",
                                    "uint32",
                                ],
                                [
                                    realityAddress,
                                    arbitratorAddress,
                                    questionText,
                                    questionTimeout,
                                    expiry,
                                ]
                            ),
                        ],
                        false,
                    ]
                );

            const predictedKpiTokenAddress =
                await IKPITokensManager__factory.connect(
                    kpiTokensManagerAddress,
                    signer
                ).predictInstanceAddress(
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

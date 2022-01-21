import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { IKPITokensManager__factory } from "../typechain-types";

interface TaskArguments {
    kpiTemplateAddress: string;
    oracleTemplateAddress: string;
    factoryAddress: string;
    kpiTokensManagerAddress: string;
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
    "create-manual-reality-eth-kpi-token",
    "Creates a manual KPI token based on the outcome of a Reality.eth question"
)
    .addParam("kpiTemplateAddress")
    .addParam("oracleTemplateAddress")
    .addParam("factoryAddress")
    .addParam("kpiTokensManagerAddress")
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
                kpiTokensManagerAddress,
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
            // const [signer] = await hre.ethers.getSigners();
            /* const yeah = IOracle__factory.connect(
                hre.ethers.constants.AddressZero,
                signer
            ).interface.decodeFunctionData(
                "initialize",
                "0xd1f578940000000000000000000000004e71340b77fed8b6458982b54d1681fb8dd6bb24000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000001000000000000000000000000003d00d77ee771405628a4ba4913175ecc095538da0000000000000000000000005b6df8e106ba70e65f92531dfb09fe196d32eaeb00000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000b40000000000000000000000000000000000000000000000000000000061e990ed000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000075465737420313f00000000000000000000000000000000000000000000000000"
            );
            console.log(
                hre.ethers.utils.defaultAbiCoder.decode(
                    [
                        "address",
                        "address",
                        "string",
                        "uint32",
                        "uint32",
                        "bool",
                    ],

                    yeah._initializationData
                )

                );
                hre.ethers.utils.defaultAbiCoder.decode(
                    ["address", "address", "uint256", "bytes"],
                )
            return; */

            await hre.run("clean");
            await hre.run("compile");
            const [signer] = await hre.ethers.getSigners();

            const factory = await (
                await hre.ethers.getContractFactory("KPITokensFactory")
            )
                .attach(factoryAddress)
                .connect(signer);

            const parsedRawCollateralAmount =
                hre.ethers.utils.parseEther(collateralAmount);

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
                        hre.ethers.utils.formatBytes32String("Manual Reality.eth KPI"),
                        hre.ethers.utils.formatBytes32String("KPI"),
                        hre.ethers.utils.parseEther("100000"),
                    ]
                );

            const oraclesInitializationData =
                hre.ethers.utils.defaultAbiCoder.encode(
                    [
                        "address[]",
                        "uint256[]",
                        "uint256[]",
                        "address[]",
                        "uint256[]",
                        "uint256[]",
                        "bytes[]",
                        "bool",
                    ],
                    [
                        [oracleTemplateAddress],
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
                        ],
                        false,
                    ]
                );

            const collateralToken = await (
                await hre.ethers.getContractFactory("ERC20")
            ).attach(collateralAddress);
            const predictedKpiTokenAddress =
                await IKPITokensManager__factory.connect(
                    kpiTokensManagerAddress,
                    signer
                ).predictInstanceAddress(
                    kpiTemplateAddress,
                    kpiTokenInitializationData
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
                kpiTemplateAddress,
                kpiTokenInitializationData,
                oraclesInitializationData
            );
            console.log(await creationTx.wait());

            console.log("KPI token created");
        }
    );

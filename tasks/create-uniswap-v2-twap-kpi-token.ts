import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";

interface TaskArguments {
    factoryAddress: string;
    kpiTokensManagerAddress: string;
    oraclesManagerAddress: string;
    collateralAddress: string;
    collateralAmount: string;
    pairAddress: string;
    tokenAddress: string;
    startsAt: string;
    endsAt: string;
    refreshRate: string;
    description: string;
    automationFundingTokenAddress: string;
    automationFundingTokenAmount: string;
    lowerBound: string;
    higherBound: string;
}

task(
    "create-uniswap-v2-twap-kpi-token",
    "Creates a manual KPI token based on the outcome of a Reality.eth question"
)
    .addParam("automationFundingTokenAddress")
    .addParam("automationFundingTokenAmount")
    .addParam("factoryAddress")
    .addParam("kpiTokensManagerAddress")
    .addParam("oraclesManagerAddress")
    .addParam("collateralAddress")
    .addParam("collateralAmount")
    .addParam("pairAddress")
    .addParam("tokenAddress")
    .addParam("startsAt")
    .addParam("endsAt")
    .addParam("refreshRate")
    .addParam("description")
    .addParam("lowerBound")
    .addParam("higherBound")
    .setAction(
        async (
            {
                automationFundingTokenAddress,
                automationFundingTokenAmount,
                factoryAddress,
                kpiTokensManagerAddress,
                oraclesManagerAddress,
                collateralAddress,
                collateralAmount,
                pairAddress,
                tokenAddress,
                startsAt,
                endsAt,
                refreshRate,
                description,
                lowerBound,
                higherBound,
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
                            "Automated Uniswap v2 TWAP KPI"
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
                        [2],
                        [lowerBound],
                        [higherBound],
                        [automationFundingTokenAddress],
                        [automationFundingTokenAmount],
                        [1],
                        [
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
                                    pairAddress,
                                    tokenAddress,
                                    startsAt,
                                    endsAt,
                                    refreshRate,
                                ]
                            ),
                        ],
                        false,
                    ]
                );

            const kpiTokensManagerFactory = await hre.ethers.getContractFactory(
                "KPITokensManager"
            );
            const predictedKpiTokenAddress = await kpiTokensManagerFactory
                .attach(kpiTokensManagerAddress)
                .connect(signer)
                .predictInstanceAddress(
                    0,
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

            const automationFundingToken = await (
                await hre.ethers.getContractFactory("ERC20")
            ).attach(automationFundingTokenAddress);
            const automationFundingTokenDecimals =
                await automationFundingToken.decimals();
            const parsedRawAutomationFundingAmount =
                hre.ethers.utils.parseUnits(
                    automationFundingTokenAmount,
                    automationFundingTokenDecimals
                );

            if (
                (
                    await automationFundingToken.allowance(
                        signer.address,
                        oraclesManagerAddress
                    )
                ).lt(parsedRawAutomationFundingAmount)
            ) {
                const approveTx = await automationFundingToken.approve(
                    oraclesManagerAddress,
                    parsedRawAutomationFundingAmount
                );
                console.log("Approving automation funding token");
                await approveTx.wait();
                console.log("Automation funding token approved");
            }

            const creationTx = await factory.createToken(
                0,
                description,
                kpiTokenInitializationData,
                oraclesInitializationData
            );
            await creationTx.wait();

            console.log("KPI token created");
        }
    );

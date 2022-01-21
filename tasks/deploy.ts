import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";

interface TaskArguments {
    verify: boolean;
    workersJobsRegistryAddress?: string;
    feeReceiverAddress: string;
}

task(
    "deploy",
    "Deploys the whole contracts suite and verifies source code on Etherscan"
)
    .addOptionalParam(
        "workersJobsRegistryAddress",
        "Workers platform jobs registry address"
    )
    .addParam("feeReceiverAddress", "Fee receiver address")
    .addFlag(
        "verify",
        "Additional (and optional) Etherscan contracts verification"
    )
    .setAction(
        async (
            {
                verify,
                workersJobsRegistryAddress,
                feeReceiverAddress,
            }: TaskArguments,
            hre: HardhatRuntimeEnvironment
        ) => {
            await hre.run("clean");
            await hre.run("compile");

            const erc20KpiTokenFactory = await hre.ethers.getContractFactory(
                "ERC20KPIToken"
            );
            const erc20KpiToken = await erc20KpiTokenFactory.deploy();
            await erc20KpiToken.deployed();
            console.log("Deployed ERC20 KPI token template");

            const templateSetLibraryFactory =
                await hre.ethers.getContractFactory("TemplateSetLibrary");
            const templateSetLibrary = await templateSetLibraryFactory.deploy();
            await templateSetLibrary.deployed();
            console.log("Deployed template set library");

            const signer = hre.ethers.provider.getSigner(0);
            const predictedFactoryAddress =
                await hre.ethers.utils.getContractAddress({
                    from: await signer.getAddress(),
                    nonce: (await signer.getTransactionCount()) + 3,
                });

            const kpiTokensManagerFactory = await hre.ethers.getContractFactory(
                "KPITokensManager",
                {
                    libraries: {
                        TemplateSetLibrary: templateSetLibrary.address,
                    },
                }
            );
            const kpiTokensManager = await kpiTokensManagerFactory.deploy(
                predictedFactoryAddress
            );
            await kpiTokensManager.deployed();
            console.log("Deployed KPI tokens manager");

            const erc20KpiTokenAdditionTx = await kpiTokensManager.addTemplate(
                erc20KpiToken.address,
                false,
                "ERC20 KPI token v1.0.0"
            );
            await erc20KpiTokenAdditionTx.wait();
            console.log("Added KPI token template");

            const oraclesManagerFactory = await hre.ethers.getContractFactory(
                "OraclesManager",
                {
                    libraries: {
                        TemplateSetLibrary: templateSetLibrary.address,
                    },
                }
            );
            const oraclesManager = await oraclesManagerFactory.deploy(
                predictedFactoryAddress,
                workersJobsRegistryAddress || hre.ethers.constants.AddressZero
            );
            await oraclesManager.deployed();
            console.log("Deployed oracles manager");

            const kpiTokensFactoryFactory = await hre.ethers.getContractFactory(
                "KPITokensFactory"
            );
            const kpiTokensFactory = await kpiTokensFactoryFactory.deploy(
                kpiTokensManager.address,
                oraclesManager.address,
                feeReceiverAddress
            );
            await kpiTokensFactory.deployed();
            console.log("Deployed KPI tokens factory");

            if (predictedFactoryAddress !== kpiTokensFactory.address)
                throw new Error();

            const automatedRealityOracleFactory =
                await hre.ethers.getContractFactory("AutomatedRealityOracle");
            const automatedRealityOracle =
                await automatedRealityOracleFactory.deploy();
            await automatedRealityOracle.deployed();
            console.log("Deployed automated Reality.eth oracle");

            const automatedRealityAdditionTx = await oraclesManager.addTemplate(
                automatedRealityOracle.address,
                true,
                "Automated Reality.eth oracle v1.0.0"
            );
            await automatedRealityAdditionTx.wait();
            console.log("Added automated Reality.eth oracle template");

            const manualRealityOracleFactory =
                await hre.ethers.getContractFactory("ManualRealityOracle");
            const manualRealityOracle =
                await manualRealityOracleFactory.deploy();
            await manualRealityOracle.deployed();
            console.log("Deployed manual Reality.eth oracle");

            const manualRealityAdditionTx = await oraclesManager.addTemplate(
                manualRealityOracle.address,
                false,
                "Manual Reality.eth oracle v1.0.0"
            );
            await manualRealityAdditionTx.wait();
            console.log("Added manual Reality.eth oracle template");

            const uniswapV2TwapOracleFactory =
                await hre.ethers.getContractFactory("UniswapV2TWAPOracle");
            const uniswapV2TwapOracle =
                await uniswapV2TwapOracleFactory.deploy();
            await uniswapV2TwapOracle.deployed();
            console.log("Deployed Uniswap v2 TWAP oracle");

            const twapAdditionTx = await oraclesManager.addTemplate(
                uniswapV2TwapOracle.address,
                true,
                "Uniswap v2 TWAP oracle v1.0.0"
            );
            await twapAdditionTx.wait();
            console.log("Added Uniswap v2 TWAP oracle template");

            console.log(predictedFactoryAddress);
            if (verify) {
                await wait(70_000);

                await verifyContractSourceCode(hre, erc20KpiToken.address, []);

                await verifyContractSourceCode(
                    hre,
                    templateSetLibrary.address,
                    []
                );

                await verifyContractSourceCode(hre, kpiTokensManager.address, [
                    predictedFactoryAddress,
                ]);

                await verifyContractSourceCode(hre, oraclesManager.address, [
                    predictedFactoryAddress,
                    workersJobsRegistryAddress ||
                        hre.ethers.constants.AddressZero,
                ]);

                await verifyContractSourceCode(hre, kpiTokensFactory.address, [
                    kpiTokensManager.address,
                    oraclesManager.address,
                    feeReceiverAddress,
                ]);

                await verifyContractSourceCode(
                    hre,
                    automatedRealityOracle.address,
                    []
                );

                await verifyContractSourceCode(
                    hre,
                    manualRealityOracle.address,
                    []
                );

                await verifyContractSourceCode(
                    hre,
                    uniswapV2TwapOracle.address,
                    []
                );

                console.log("Source code verified");
            }

            console.log("== Addresses ==");
            console.log(`KPI tokens manager: ${kpiTokensManager.address}`);
            console.log(`ERC20 KPI token template: ${erc20KpiToken.address}`);
            console.log(`Oracles manager: ${oraclesManager.address}`);
            console.log(`Factory: ${kpiTokensFactory.address}`);
            console.log(
                `Automated Reality.eth oracle template: ${automatedRealityOracle.address}`
            );
            console.log(
                `Manual Reality.eth oracle template: ${manualRealityOracle.address}`
            );
            console.log(
                `Automated Uniswap v2 TWAP oracle template: ${uniswapV2TwapOracle.address}`
            );
        }
    );

const wait = async (time: number): Promise<void> => {
    await new Promise((resolve) => {
        console.log("Waiting...");
        setTimeout(resolve, time);
    });
};

const verifyContractSourceCode = async (
    hre: HardhatRuntimeEnvironment,
    address: string,
    constructorArguments: string[]
): Promise<void> => {
    try {
        await hre.run("verify:verify", {
            address,
            constructorArguments,
        });
    } catch (error: any) {
        if (!/already verified/i.test(error.message)) throw error;
    }
};

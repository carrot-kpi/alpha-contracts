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

            const aaveErc20KpiTokenFactory =
                await hre.ethers.getContractFactory("AaveERC20KPIToken");
            const aaveErc20KpiToken = await aaveErc20KpiTokenFactory.deploy();
            await aaveErc20KpiToken.deployed();
            console.log("Deployed Aave ERC20 KPI token template");

            const signer = hre.ethers.provider.getSigner(0);
            const predictedFactoryAddress =
                await hre.ethers.utils.getContractAddress({
                    from: await signer.getAddress(),
                    nonce: (await signer.getTransactionCount()) + 4,
                });

            const kpiTokensManagerFactory = await hre.ethers.getContractFactory(
                "KPITokensManager"
            );
            const kpiTokensManager = await kpiTokensManagerFactory.deploy(
                predictedFactoryAddress
            );
            await kpiTokensManager.deployed();
            console.log("Deployed KPI tokens manager");

            const erc20KpiTokenAdditionTx = await kpiTokensManager.addTemplate(
                erc20KpiToken.address,
                "QmXU4G418hZLL8yxXdjkTFSoH2FdSe6ELgUuSm5fHHJMMN"
            );
            await erc20KpiTokenAdditionTx.wait();
            console.log("Added ERC20 KPI token template");

            const aaveErc20KpiTokenAdditionTx =
                await kpiTokensManager.addTemplate(
                    aaveErc20KpiToken.address,
                    "QmPRwBVEPteH9qLKHdPGPPkNYuLzTv6fNACcLSHDUW3j8p"
                );
            await aaveErc20KpiTokenAdditionTx.wait();
            console.log("Added Aave ERC20 KPI token template");

            const oraclesManagerFactory = await hre.ethers.getContractFactory(
                "OraclesManager"
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

            const manualRealityOracleFactory =
                await hre.ethers.getContractFactory("ManualRealityOracle");
            const manualRealityOracle =
                await manualRealityOracleFactory.deploy();
            await manualRealityOracle.deployed();
            console.log("Deployed manual Reality.eth oracle");

            const manualRealityAdditionTx = await oraclesManager.addTemplate(
                manualRealityOracle.address,
                false,
                "QmRvoExBSESXedwqfC1cs4DGaRymnRR1wA9YGoZbqsE8Mf"
            );
            await manualRealityAdditionTx.wait();
            console.log("Added manual Reality.eth oracle template");

            if (verify) {
                await wait(120_000);

                await verifyContractSourceCode(hre, erc20KpiToken.address, []);

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
                    manualRealityOracle.address,
                    []
                );

                console.log("Source code verified");
            }

            console.log(
                JSON.stringify(
                    {
                        kpiTokensManager: kpiTokensManager.address,
                        erc20KpiTokensTemplate: erc20KpiToken.address,
                        aaveErc20KpiTokensTemplate: aaveErc20KpiToken.address,
                        oraclesManager: oraclesManager.address,
                        factory: kpiTokensFactory.address,
                        manualRealityEthOracleTemplate:
                            manualRealityOracle.address,
                    },
                    undefined,
                    4
                )
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

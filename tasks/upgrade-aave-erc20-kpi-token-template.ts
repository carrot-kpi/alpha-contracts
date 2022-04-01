import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";

interface TaskArguments {
    kpiTokensManagerAddress: string;
    templateId: string;
    newTemplateSpecification: string;
    versionBump: string;
    verify: boolean;
}

task(
    "upgrade-aave-erc20-kpi-token-template",
    "Upgrades the currently published version of the Aave ERC20 KPI token template to the latest one available"
)
    .addParam("templateId")
    .addParam("newTemplateSpecification")
    .addParam("kpiTokensManagerAddress")
    .addParam("versionBump")
    .addFlag("verify")
    .setAction(
        async (
            {
                kpiTokensManagerAddress,
                templateId,
                newTemplateSpecification,
                versionBump,
                verify,
            }: TaskArguments,
            hre: HardhatRuntimeEnvironment
        ) => {
            await hre.run("clean");
            await hre.run("compile");
            const [signer] = await hre.ethers.getSigners();

            const templateFactory = await hre.ethers.getContractFactory(
                "AaveERC20KPIToken"
            );
            const newTemplate = await templateFactory.deploy();
            await newTemplate.deployed();
            console.log("Deployed new template");

            const kpiTokensManagerFactory = await hre.ethers.getContractFactory(
                "KPITokensManager"
            );
            const kpiTokensManager = kpiTokensManagerFactory
                .attach(kpiTokensManagerAddress)
                .connect(signer);
            const upgradeTx = await kpiTokensManager.upgradeTemplate(
                templateId,
                newTemplate.address,
                versionBump,
                newTemplateSpecification
            );
            await upgradeTx.wait();
            console.log("Upgraded to", newTemplate.address);

            if (verify) {
                await new Promise((resolve) => {
                    console.log("Waiting before source code verification...");
                    setTimeout(resolve, 20000);
                });

                await hre.run("verify", {
                    address: newTemplate.address,
                    constructorArgsParams: [],
                });

                console.log(`Source code verified`);
            }

            console.log(`Template upgraded to ${newTemplate.address}`);
        }
    );

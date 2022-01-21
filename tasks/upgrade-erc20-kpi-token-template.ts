import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { IKPITokensManager__factory } from "../typechain-types";

interface TaskArguments {
    kpiTokensManagerAddress: string;
    oldTemplateAddress: string;
    newTemplateDescription: string;
    verify: boolean;
}

task(
    "upgrade-erc20-kpi-token-template",
    "Upgrades the currently published version of the ERC20 KPI token template to the latest one available"
)
    .addParam("oldTemplateAddress")
    .addParam("newTemplateDescription")
    .addParam("kpiTokensManagerAddress")
    .addFlag("verify")
    .setAction(
        async (
            {
                kpiTokensManagerAddress,
                oldTemplateAddress,
                newTemplateDescription,
                verify,
            }: TaskArguments,
            hre: HardhatRuntimeEnvironment
        ) => {
            await hre.run("clean");
            await hre.run("compile");
            const [signer] = await hre.ethers.getSigners();

            const templateFactory = await hre.ethers.getContractFactory(
                "ERC20KPIToken"
            );
            const newTemplate = await templateFactory.deploy();
            await newTemplate.deployed();
            console.log("Deployed new template");

            const kpiTokensManager = IKPITokensManager__factory.connect(
                kpiTokensManagerAddress,
                signer
            );
            const upgradeTx = await kpiTokensManager.upgradeTemplate(
                oldTemplateAddress,
                newTemplate.address,
                newTemplateDescription
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

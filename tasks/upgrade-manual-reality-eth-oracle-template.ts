import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { IKPITokensManager__factory } from "../typechain-types";

interface TaskArguments {
    oraclesManagerAddress: string;
    oldTemplateAddress: string;
    newTemplateDescription: string;
    verify: boolean;
}

task(
    "upgrade-manual-reality-eth-oracle-template",
    "Upgrades the currently published version of the manual Reality oracle template to the latest one available"
)
    .addParam("oldTemplateAddress")
    .addParam("newTemplateDescription")
    .addParam("oraclesManagerAddress")
    .addFlag("verify")
    .setAction(
        async (
            {
                oraclesManagerAddress,
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
                "ManualRealityOracle"
            );
            const newTemplate = await templateFactory.deploy();
            await newTemplate.deployed();
            console.log("Deployed new template");

            const oraclesManager = IKPITokensManager__factory.connect(
                oraclesManagerAddress,
                signer
            );
            const upgradeTx = await oraclesManager.upgradeTemplate(
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
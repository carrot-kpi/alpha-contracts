import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";

interface TaskArguments {
    oraclesManagerAddress: string;
    oldTemplateAddress: string;
    newTemplateDescription: string;
    verify: boolean;
}

task(
    "upgrade-uniswap-v2-twap-template",
    "Upgrade the currently published version of the token price oracle to the latest one available"
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

            const twapOracleFactory = await hre.ethers.getContractFactory(
                "UniswapV2TWAPOracle"
            );
            const twapOracle = await twapOracleFactory.deploy();
            await twapOracle.deployed();
            console.log("Deployed TWAP oracle");

            const oraclesManager = (
                await hre.ethers.getContractFactory("OraclesManager")
            )
                .attach(oraclesManagerAddress)
                .connect(signer);
            const upgradeTx = await oraclesManager.updgradeTemplate(
                oldTemplateAddress,
                twapOracle.address,
                newTemplateDescription
            );
            await upgradeTx.wait();

            if (verify) {
                await new Promise((resolve) => {
                    console.log("Waiting before source code verification...");
                    setTimeout(resolve, 20000);
                });

                await hre.run("verify", {
                    address: twapOracle.address,
                    constructorArgsParams: [],
                });

                console.log(`Source code verified`);
            }

            console.log(`Template upgraded to ${twapOracle.address}`);
        }
    );

import { expect } from "chai";
import { preFactoryDeploymentFixture } from "../fixtures";
import { constants, Wallet } from "ethers";
import { waffle } from "hardhat";

const { loadFixture } = waffle;

describe("KPITokensFactory - Initialization", () => {
    it("should fail when initializing with a zero address implementation template", async () => {
        const { realitio, kpiTokensFactoryFactory } = await loadFixture(
            preFactoryDeploymentFixture
        );
        await expect(
            kpiTokensFactoryFactory.deploy(
                constants.AddressZero,
                realitio.address,
                30,
                Wallet.createRandom().address
            )
        ).to.be.revertedWith("ZeroAddressKpiTokenImplementation");
    });

    it("should fail when initializing with a zero address oracle", async () => {
        const { kpiToken, kpiTokensFactoryFactory } = await loadFixture(
            preFactoryDeploymentFixture
        );
        await expect(
            kpiTokensFactoryFactory.deploy(
                kpiToken.address,
                constants.AddressZero,
                30,
                Wallet.createRandom().address
            )
        ).to.be.revertedWith("ZeroAddressOracle");
    });

    it("should fail when initializing with a 0-address fee receiver", async () => {
        const {
            kpiToken,
            realitio,
            kpiTokensFactoryFactory,
        } = await loadFixture(preFactoryDeploymentFixture);
        await expect(
            kpiTokensFactoryFactory.deploy(
                kpiToken.address,
                realitio.address,
                30,
                constants.AddressZero
            )
        ).to.be.revertedWith("ZeroAddressFeeReceiver");
    });

    it("should succeed in the right conditions", async () => {
        const {
            kpiToken,
            realitio,
            kpiTokensFactoryFactory,
        } = await loadFixture(preFactoryDeploymentFixture);
        const feeReceiver = Wallet.createRandom();
        const kpiTokensFactory = await kpiTokensFactoryFactory.deploy(
            kpiToken.address,
            realitio.address,
            30,
            feeReceiver.address
        );
        expect(await kpiTokensFactory.kpiTokenImplementation()).to.be.equal(
            kpiToken.address
        );
        expect(await kpiTokensFactory.oracle()).to.be.equal(realitio.address);
        expect(await kpiTokensFactory.fee()).to.be.equal(30);
        expect(await kpiTokensFactory.feeReceiver()).to.be.equal(
            feeReceiver.address
        );
    });
});

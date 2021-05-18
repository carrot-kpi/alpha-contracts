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
                Wallet.createRandom().address,
                30,
                120,
                Wallet.createRandom().address
            )
        ).to.be.revertedWith("KF01");
    });

    it("should fail when initializing with a zero address oracle", async () => {
        const { kpiToken, kpiTokensFactoryFactory } = await loadFixture(
            preFactoryDeploymentFixture
        );
        await expect(
            kpiTokensFactoryFactory.deploy(
                kpiToken.address,
                constants.AddressZero,
                Wallet.createRandom().address,
                30,
                120,
                Wallet.createRandom().address
            )
        ).to.be.revertedWith("KF02");
    });

    it("should fail when initializing with a zero address arbitrator", async () => {
        const {
            kpiToken,
            realitio,
            kpiTokensFactoryFactory,
        } = await loadFixture(preFactoryDeploymentFixture);
        await expect(
            kpiTokensFactoryFactory.deploy(
                kpiToken.address,
                realitio.address,
                constants.AddressZero,
                30,
                120,
                Wallet.createRandom().address
            )
        ).to.be.revertedWith("KF03");
    });

    it("should fail when initializing with a 100% fee", async () => {
        const {
            kpiToken,
            realitio,
            kpiTokensFactoryFactory,
        } = await loadFixture(preFactoryDeploymentFixture);
        await expect(
            kpiTokensFactoryFactory.deploy(
                kpiToken.address,
                realitio.address,
                Wallet.createRandom().address,
                10000,
                120,
                Wallet.createRandom().address
            )
        ).to.be.revertedWith("KF03");
    });

    it("should fail when initializing with a more than 100% fee", async () => {
        const {
            kpiToken,
            realitio,
            kpiTokensFactoryFactory,
        } = await loadFixture(preFactoryDeploymentFixture);
        await expect(
            kpiTokensFactoryFactory.deploy(
                kpiToken.address,
                realitio.address,
                Wallet.createRandom().address,
                15000,
                120,
                Wallet.createRandom().address
            )
        ).to.be.revertedWith("KF03");
    });

    it("should fail when initializing with a 0 voting timeout", async () => {
        const {
            kpiToken,
            realitio,
            kpiTokensFactoryFactory,
        } = await loadFixture(preFactoryDeploymentFixture);
        await expect(
            kpiTokensFactoryFactory.deploy(
                kpiToken.address,
                realitio.address,
                Wallet.createRandom().address,
                30,
                0,
                Wallet.createRandom().address
            )
        ).to.be.revertedWith("KF04");
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
                Wallet.createRandom().address,
                30,
                100,
                constants.AddressZero
            )
        ).to.be.revertedWith("KF17");
    });

    it("should succeed in the right conditions", async () => {
        const {
            kpiToken,
            realitio,
            kpiTokensFactoryFactory,
        } = await loadFixture(preFactoryDeploymentFixture);
        const arbitrator = Wallet.createRandom();
        const feeReceiver = Wallet.createRandom();
        const kpiTokensFactory = await kpiTokensFactoryFactory.deploy(
            kpiToken.address,
            realitio.address,
            arbitrator.address,
            30,
            120,
            feeReceiver.address
        );
        expect(await kpiTokensFactory.kpiTokenImplementation()).to.be.equal(
            kpiToken.address
        );
        expect(await kpiTokensFactory.oracle()).to.be.equal(realitio.address);
        expect(await kpiTokensFactory.arbitrator()).to.be.equal(
            arbitrator.address
        );
        expect(await kpiTokensFactory.fee()).to.be.equal(30);
        expect(await kpiTokensFactory.voteTimeout()).to.be.equal(120);
        expect(await kpiTokensFactory.feeReceiver()).to.be.equal(
            feeReceiver.address
        );
    });
});

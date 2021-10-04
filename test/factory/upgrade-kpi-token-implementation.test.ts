import { expect } from "chai";
import { fixture } from "../fixtures";
import { constants, Wallet } from "ethers";
import { waffle } from "hardhat";

const { loadFixture } = waffle;

describe("KPITokensFactory - Upgrade KPI token implementation", () => {
    it("should fail when a non-owner tries upgrading the implementation template", async () => {
        const { kpiTokensFactory, testAccount } = await loadFixture(fixture);
        await expect(
            kpiTokensFactory
                .connect(testAccount)
                .upgradeKpiTokenImplementation(constants.AddressZero)
        ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("should fail when upgrading the implementation template to the 0 address", async () => {
        const { kpiTokensFactory } = await loadFixture(fixture);
        await expect(
            kpiTokensFactory.upgradeKpiTokenImplementation(
                constants.AddressZero
            )
        ).to.be.revertedWith("ZeroAddressKpiTokenImplementation");
    });

    it("should succeed in the right conditions", async () => {
        const { kpiToken, kpiTokensFactory } = await loadFixture(fixture);
        expect(await kpiTokensFactory.kpiTokenImplementation()).to.be.equal(
            kpiToken.address
        );
        const newImplementation = Wallet.createRandom();
        await kpiTokensFactory.upgradeKpiTokenImplementation(
            newImplementation.address
        );
        expect(await kpiTokensFactory.kpiTokenImplementation()).to.be.equal(
            newImplementation.address
        );
    });
});

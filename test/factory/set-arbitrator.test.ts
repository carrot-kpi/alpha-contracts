import { expect } from "chai";
import { fixture } from "../fixtures";
import { constants, Wallet } from "ethers";
import { waffle } from "hardhat";

const { loadFixture } = waffle;

describe("KPITokensFactory - Set arbitrator", () => {
    it("should fail when a non-owner tries to set a new fee", async () => {
        const { kpiTokensFactory, testAccount } = await loadFixture(fixture);
        await expect(
            kpiTokensFactory
                .connect(testAccount)
                .setArbitrator(Wallet.createRandom().address)
        ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("should fail when setting a 0-address arbitrator", async () => {
        const { kpiTokensFactory } = await loadFixture(fixture);
        await expect(
            kpiTokensFactory.setArbitrator(constants.AddressZero)
        ).to.be.revertedWith("KF07");
    });

    it("should succeed in the right conditions", async () => {
        const { kpiTokensFactory } = await loadFixture(fixture);
        const newArbitrator = Wallet.createRandom().address;
        expect(await kpiTokensFactory.arbitrator()).to.not.be.equal(
            newArbitrator
        );
        await kpiTokensFactory.setArbitrator(newArbitrator);
        expect(await kpiTokensFactory.arbitrator()).to.be.equal(newArbitrator);
    });
});

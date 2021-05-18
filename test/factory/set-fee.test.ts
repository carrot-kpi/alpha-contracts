import { expect } from "chai";
import { fixture } from "../fixtures";
import { waffle } from "hardhat";

const { loadFixture } = waffle;

describe("KPITokensFactory - Set fee", () => {
    it("should fail when a non-owner tries to set a new fee", async () => {
        const { kpiTokensFactory, testAccount } = await loadFixture(fixture);
        await expect(
            kpiTokensFactory.connect(testAccount).setFee(1)
        ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("should fail when setting the fee to 100%", async () => {
        const { kpiTokensFactory } = await loadFixture(fixture);
        await expect(kpiTokensFactory.setFee(10000)).to.be.revertedWith("KF06");
    });

    it("should succeed in the right conditions", async () => {
        const { kpiTokensFactory } = await loadFixture(fixture);
        expect(await kpiTokensFactory.fee()).to.be.equal(
            30 // default fee of .3%
        );
        const newFee = 50; // .5%
        await kpiTokensFactory.setFee(newFee);
        expect(await kpiTokensFactory.fee()).to.be.equal(newFee);
    });
});

import { expect } from "chai";
import { fixture } from "../fixtures";
import { waffle } from "hardhat";

const { loadFixture } = waffle;

describe("KPITokensFactory - Set vote timeout", () => {
    it("should fail when a non-owner tries to set a new fee", async () => {
        const { kpiTokensFactory, testAccount } = await loadFixture(fixture);
        await expect(
            kpiTokensFactory.connect(testAccount).setVoteTimeout(100)
        ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("should fail when setting 0 as the vote timeout", async () => {
        const { kpiTokensFactory } = await loadFixture(fixture);
        await expect(kpiTokensFactory.setVoteTimeout(0)).to.be.revertedWith(
            "KF08"
        );
    });

    it("should succeed in the right conditions", async () => {
        const { kpiTokensFactory } = await loadFixture(fixture);
        const newTimeout = 10000;
        expect(await kpiTokensFactory.voteTimeout()).to.not.be.equal(
            newTimeout
        );
        await kpiTokensFactory.setVoteTimeout(newTimeout);
        expect(await kpiTokensFactory.voteTimeout()).to.be.equal(newTimeout);
    });
});

import { expect } from "chai";
import { fixture } from "../fixtures";
import { constants, Wallet } from "ethers";
import { waffle } from "hardhat";

const { loadFixture } = waffle;

describe("KPITokensFactory - Set fee receiver", () => {
    it("should fail when a non-owner tries to set the fee receiver", async () => {
        const { kpiTokensFactory, testAccount } = await loadFixture(fixture);
        await expect(
            kpiTokensFactory
                .connect(testAccount)
                .setFeeReceiver(Wallet.createRandom().address)
        ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("should fail when setting a 0-address fee receiver", async () => {
        const { kpiTokensFactory } = await loadFixture(fixture);
        await expect(
            kpiTokensFactory.setFeeReceiver(constants.AddressZero)
        ).to.be.revertedWith("KF16");
    });

    it("should succeed in the right conditions", async () => {
        const { kpiTokensFactory } = await loadFixture(fixture);
        const newFeeReceiver = Wallet.createRandom().address;
        expect(await kpiTokensFactory.feeReceiver()).to.not.be.equal(
            newFeeReceiver
        );
        await kpiTokensFactory.setFeeReceiver(newFeeReceiver);
        expect(await kpiTokensFactory.feeReceiver()).to.be.equal(
            newFeeReceiver
        );
    });
});

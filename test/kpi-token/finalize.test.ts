import { expect } from "chai";
import { testBooleanKpiTokenFixture } from "../fixtures";
import { waffle } from "hardhat";
import { fastForward, fastForwardTo } from "../utils";
import { formatBytes32String } from "ethers/lib/utils";

const { loadFixture } = waffle;

describe("KPIToken - Finalize", () => {
    it("should fail when finalize is called but the question is not yet answered on Reality.eth", async () => {
        const { kpiToken } = await loadFixture(testBooleanKpiTokenFixture);
        // voting start timestamp is 2 minutes in the future since KPI token
        // initialization by default, so this should fail
        await expect(kpiToken.finalize()).to.be.revertedWith("KT01");
    });

    it("should succeed when finalize is called and the question is answered with yes on Reality.eth", async () => {
        const {
            kpiToken,
            kpiExpiry,
            realitio,
            realiyQuestionId,
            voteTimeout,
            collateralToken,
            collateralData,
        } = await loadFixture(testBooleanKpiTokenFixture);
        await fastForwardTo(kpiExpiry);
        await realitio.submitAnswer(
            realiyQuestionId,
            "0x0000000000000000000000000000000000000000000000000000000000000001",
            0,
            { value: 1 }
        );
        await fastForward(voteTimeout + 10);
        expect(await realitio.isFinalized(realiyQuestionId)).to.be.true;
        await kpiToken.finalize();
        expect(await kpiToken.finalized()).to.be.true;
        expect(await kpiToken.finalKpiProgress()).to.be.equal(1);
        const creatorAddress = await kpiToken.creator();
        expect(await collateralToken.balanceOf(creatorAddress)).to.be.equal(0);
        expect(await collateralToken.balanceOf(kpiToken.address)).to.be.equal(
            collateralData.amount.sub(collateralData.amount.mul(30).div(10000)) // fees must be removed
        );
    });

    it("should succeed when finalize is called, the question is answered with false on Reality.eth", async () => {
        const {
            kpiToken,
            kpiExpiry,
            realitio,
            realiyQuestionId,
            voteTimeout,
            collateralToken,
            collateralData,
        } = await loadFixture(testBooleanKpiTokenFixture);
        await fastForwardTo(kpiExpiry);
        await realitio.submitAnswer(
            realiyQuestionId,
            formatBytes32String(""),
            0,
            { value: 1 }
        );
        await fastForward(voteTimeout + 10);
        expect(await realitio.isFinalized(realiyQuestionId)).to.be.true;
        await kpiToken.finalize();
        expect(await kpiToken.finalized()).to.be.true;
        expect(await kpiToken.finalKpiProgress()).to.be.equal(0);
        const creatorAddress = await kpiToken.creator();
        expect(await collateralToken.balanceOf(creatorAddress)).to.be.equal(
            collateralData.amount.sub(collateralData.amount.mul(30).div(10000)) // fees must be removed
        );
        expect(await collateralToken.balanceOf(kpiToken.address)).to.be.equal(
            0
        );
    });
});

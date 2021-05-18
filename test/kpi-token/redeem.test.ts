import { expect } from "chai";
import { testKpiTokenFixture } from "../fixtures";
import { waffle } from "hardhat";
import { fastForward, fastForwardTo } from "../utils";
import { formatBytes32String } from "ethers/lib/utils";

const { loadFixture } = waffle;

describe("KPIToken - Redeem", () => {
    it("should fail when the kpi token is not finalized", async () => {
        const { kpiToken } = await loadFixture(testKpiTokenFixture);
        // voting start timestamp is 2 minutes in the future since KPI token
        // initialization by default, so this should fail
        await expect(kpiToken.redeem()).to.be.revertedWith("KT02");
    });

    it("should fail when the kpi is finalized but a user with no token balance calls", async () => {
        const {
            kpiToken,
            oracleData,
            realitio,
            realiyQuestionId,
            voteTimeout,
            testAccount,
        } = await loadFixture(testKpiTokenFixture);
        await fastForwardTo(oracleData.kpiExpiry);
        await realitio.submitAnswer(
            realiyQuestionId,
            "0x0000000000000000000000000000000000000000000000000000000000000001",
            0,
            { value: 1 }
        );
        await fastForward(voteTimeout + 10);
        await kpiToken.finalize();
        await expect(kpiToken.redeem()).to.be.revertedWith("KT03");
    });

    it("should succeed when the kpi is finalized to false (not reached) and a user with balance calls", async () => {
        const {
            kpiToken,
            oracleData,
            realitio,
            realiyQuestionId,
            voteTimeout,
            testAccount,
        } = await loadFixture(testKpiTokenFixture);
        await fastForwardTo(oracleData.kpiExpiry);
        await realitio.submitAnswer(
            realiyQuestionId,
            formatBytes32String("0"),
            0,
            { value: 1 }
        );
        await fastForward(voteTimeout + 10);
        await kpiToken.finalize();
        await kpiToken.connect(testAccount).redeem();
        expect(await kpiToken.totalSupply()).to.be.equal(0);
    });
});

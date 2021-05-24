import { expect } from "chai";
import {
    getScalarKpiTokenFixture,
    testBooleanKpiTokenFixture,
} from "../fixtures";
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

    it("should succeed when finalize is called on a scalar kpi and the kpi has been reached at 50%", async () => {
        const {
            kpiToken,
            kpiExpiry,
            realitio,
            realiyQuestionId,
            voteTimeout,
            collateralToken,
            collateralData,
        } = await loadFixture(getScalarKpiTokenFixture(0, 100));
        await fastForwardTo(kpiExpiry);
        await realitio.submitAnswer(
            realiyQuestionId,
            "0x0000000000000000000000000000000000000000000000000000000000000032",
            0,
            { value: 1 }
        );
        await fastForward(voteTimeout + 10);
        expect(await realitio.isFinalized(realiyQuestionId)).to.be.true;
        await kpiToken.finalize();
        expect(await kpiToken.finalized()).to.be.true;
        expect(await kpiToken.finalKpiProgress()).to.be.equal(50);
        const creatorAddress = await kpiToken.creator();
        // fees must be removed
        const collateralMinusFees = collateralData.amount.sub(
            collateralData.amount.mul(30).div(10000)
        );
        const halfCollateral = collateralMinusFees.div(2);
        // half of the collateral should be returned to the creator
        expect(await collateralToken.balanceOf(creatorAddress)).to.be.equal(
            halfCollateral
        );
        expect(await collateralToken.balanceOf(kpiToken.address)).to.be.equal(
            halfCollateral
        );
    });

    it("should succeed when finalize is called on a scalar kpi with narrow range and the kpi has been reached at 10%", async () => {
        const {
            kpiToken,
            kpiExpiry,
            realitio,
            realiyQuestionId,
            voteTimeout,
            collateralToken,
            collateralData,
        } = await loadFixture(getScalarKpiTokenFixture(0, 10));
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
        // fees must be removed
        const collateralMinusFees = collateralData.amount.sub(
            collateralData.amount.mul(30).div(10000)
        );
        expect(await collateralToken.balanceOf(creatorAddress)).to.be.equal(
            collateralMinusFees.div(10).mul(9)
        );
        expect(await collateralToken.balanceOf(kpiToken.address)).to.be.equal(
            collateralMinusFees.div(10)
        );
    });

    it("should succeed when finalize is called on a scalar kpi and the kpi has been below the lower bound", async () => {
        const {
            kpiToken,
            kpiExpiry,
            realitio,
            realiyQuestionId,
            voteTimeout,
            collateralToken,
            collateralData,
        } = await loadFixture(getScalarKpiTokenFixture(50, 100));
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
        expect(await kpiToken.finalKpiProgress()).to.be.equal(0);
        const creatorAddress = await kpiToken.creator();
        // fees must be removed
        const collateralMinusFees = collateralData.amount.sub(
            collateralData.amount.mul(30).div(10000)
        );
        expect(await collateralToken.balanceOf(creatorAddress)).to.be.equal(
            collateralMinusFees
        );
        expect(await collateralToken.balanceOf(kpiToken.address)).to.be.equal(
            0
        );
    });

    it("should succeed when finalize is called on a scalar kpi and the kpi has been above the higher bound", async () => {
        const {
            kpiToken,
            kpiExpiry,
            realitio,
            realiyQuestionId,
            voteTimeout,
            collateralToken,
            collateralData,
        } = await loadFixture(getScalarKpiTokenFixture(50, 100));
        await fastForwardTo(kpiExpiry);
        await realitio.submitAnswer(
            realiyQuestionId,
            "0x0000000000000000000000000000000000000000000000000000000000011111",
            0,
            { value: 1 }
        );
        await fastForward(voteTimeout + 10);
        expect(await realitio.isFinalized(realiyQuestionId)).to.be.true;
        await kpiToken.finalize();
        expect(await kpiToken.finalized()).to.be.true;
        expect(await kpiToken.finalKpiProgress()).to.be.equal(50);
        const creatorAddress = await kpiToken.creator();
        // fees must be removed
        const collateralMinusFees = collateralData.amount.sub(
            collateralData.amount.mul(30).div(10000)
        );
        expect(await collateralToken.balanceOf(creatorAddress)).to.be.equal(0);
        expect(await collateralToken.balanceOf(kpiToken.address)).to.be.equal(
            collateralMinusFees
        );
    });

    it("should succeed when finalize is called on a scalar kpi and the kpi has reached exactly the higher bound", async () => {
        const {
            kpiToken,
            kpiExpiry,
            realitio,
            realiyQuestionId,
            voteTimeout,
            collateralToken,
            collateralData,
        } = await loadFixture(getScalarKpiTokenFixture(50, 1000));
        await fastForwardTo(kpiExpiry);
        await realitio.submitAnswer(
            realiyQuestionId,
            "0x00000000000000000000000000000000000000000000000000000000000003E8",
            0,
            { value: 1 }
        );
        await fastForward(voteTimeout + 10);
        expect(await realitio.isFinalized(realiyQuestionId)).to.be.true;
        await kpiToken.finalize();
        expect(await kpiToken.finalized()).to.be.true;
        expect(await kpiToken.finalKpiProgress()).to.be.equal(950);
        const creatorAddress = await kpiToken.creator();
        // fees must be removed
        const collateralMinusFees = collateralData.amount.sub(
            collateralData.amount.mul(30).div(10000)
        );
        expect(await collateralToken.balanceOf(creatorAddress)).to.be.equal(0);
        expect(await collateralToken.balanceOf(kpiToken.address)).to.be.equal(
            collateralMinusFees
        );
    });

    it("should succeed when finalize is called on a scalar kpi and the Reality.eth answer is invalid", async () => {
        const {
            kpiToken,
            kpiExpiry,
            realitio,
            realiyQuestionId,
            voteTimeout,
            collateralToken,
            collateralData,
        } = await loadFixture(getScalarKpiTokenFixture(50, 100));
        await fastForwardTo(kpiExpiry);
        await realitio.submitAnswer(
            realiyQuestionId,
            "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
            0,
            { value: 1 }
        );
        await fastForward(voteTimeout + 10);
        expect(await realitio.isFinalized(realiyQuestionId)).to.be.true;
        await kpiToken.finalize();
        expect(await kpiToken.finalized()).to.be.true;
        expect(await kpiToken.finalKpiProgress()).to.be.equal(0);
        const creatorAddress = await kpiToken.creator();
        // fees must be removed
        const collateralMinusFees = collateralData.amount.sub(
            collateralData.amount.mul(30).div(10000)
        );
        expect(await collateralToken.balanceOf(creatorAddress)).to.be.equal(
            collateralMinusFees
        );
        expect(await collateralToken.balanceOf(kpiToken.address)).to.be.equal(
            0
        );
    });
});

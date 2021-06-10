import { expect } from "chai";
import { testBooleanKpiTokenFixture } from "../fixtures";
import { ethers, waffle } from "hardhat";
import { fastForward, fastForwardTo } from "../utils";
import { formatBytes32String, randomBytes } from "ethers/lib/utils";
import { ERC20__factory } from "../../typechain";

const { loadFixture } = waffle;

describe("KPIToken - Redeem", () => {
    it("should fail when the kpi token is not finalized", async () => {
        const { kpiToken } = await loadFixture(testBooleanKpiTokenFixture);
        // voting start timestamp is 2 minutes in the future since KPI token
        // initialization by default, so this should fail
        await expect(kpiToken.redeem()).to.be.revertedWith("KT04");
    });

    it("should fail when the kpi is finalized but a user with no token balance calls", async () => {
        const {
            kpiToken,
            realitio,
            realiyQuestionId,
            voteTimeout,
            kpiExpiry,
        } = await loadFixture(testBooleanKpiTokenFixture);
        await fastForwardTo(kpiExpiry);
        await realitio.submitAnswer(
            realiyQuestionId,
            "0x0000000000000000000000000000000000000000000000000000000000000001",
            0,
            { value: 1 }
        );
        await fastForward(voteTimeout + 10);
        await kpiToken.finalize();
        await expect(kpiToken.redeem()).to.be.revertedWith("KT05");
    });

    it("should succeed when the kpi is finalized to false (not reached) and a user with balance calls", async () => {
        const {
            kpiToken,
            kpiExpiry,
            realitio,
            realiyQuestionId,
            voteTimeout,
            testAccount,
        } = await loadFixture(testBooleanKpiTokenFixture);
        await fastForwardTo(kpiExpiry);
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

    it("should succeed in the right proportions when the kpi is reached and multiple people own the token", async () => {
        const {
            kpiToken,
            kpiExpiry,
            realitio,
            realiyQuestionId,
            voteTimeout,
            testAccount,
            collateralData,
        } = await loadFixture(testBooleanKpiTokenFixture);
        const collateralContract = await ERC20__factory.connect(
            collateralData.token,
            ethers.provider
        );
        const signers = await ethers.getSigners();
        const randomAccount = signers[5];

        const totalSupply = await kpiToken.totalSupply();
        const randomAccountBalance = totalSupply.mul(60).div(100);
        await kpiToken
            .connect(testAccount)
            .transfer(randomAccount.address, randomAccountBalance);

        await fastForwardTo(kpiExpiry);
        await realitio.submitAnswer(
            realiyQuestionId,
            formatBytes32String("0"),
            0,
            { value: 1 }
        );
        await fastForward(voteTimeout + 10);
        await kpiToken.finalize();

        await kpiToken.connect(testAccount).redeem();
        expect(await kpiToken.totalSupply()).to.be.equal(
            totalSupply.mul(60).div(100)
        );
        expect(
            await collateralContract.balanceOf(testAccount.address)
        ).to.be.equal(collateralData.amount.mul(40).div(100));

        await kpiToken.connect(randomAccount).redeem();
        expect(await kpiToken.totalSupply()).to.be.equal(0);
        expect(
            await collateralContract.balanceOf(randomAccount.address)
        ).to.be.equal(collateralData.amount.mul(60).div(100));
    });

    it("should succeed in the right proportions when the kpi is reached and multiple people own the token", async () => {
        const {
            kpiToken,
            kpiExpiry,
            realitio,
            realiyQuestionId,
            voteTimeout,
            testAccount,
            collateralData,
        } = await loadFixture(testBooleanKpiTokenFixture);
        const collateralContract = await ERC20__factory.connect(
            collateralData.token,
            ethers.provider
        );
        const signers = await ethers.getSigners();
        const randomAccount1 = signers[5];
        const randomAccount2 = signers[6];

        const totalSupply = await kpiToken.totalSupply();
        const randomAccount1Balance = totalSupply.mul(60).div(100);
        await kpiToken
            .connect(testAccount)
            .transfer(randomAccount1.address, randomAccount1Balance);
        const randomAccount2Balance = totalSupply.mul(30).div(100);
        await kpiToken
            .connect(testAccount)
            .transfer(randomAccount2.address, randomAccount2Balance);

        await fastForwardTo(kpiExpiry);
        await realitio.submitAnswer(
            realiyQuestionId,
            formatBytes32String("0"),
            0,
            { value: 1 }
        );
        await fastForward(voteTimeout + 10);
        await kpiToken.finalize();

        await kpiToken.connect(testAccount).redeem();
        expect(await kpiToken.totalSupply()).to.be.equal(
            totalSupply.mul(90).div(100)
        );
        expect(
            await collateralContract.balanceOf(testAccount.address)
        ).to.be.equal(collateralData.amount.mul(10).div(100));

        await kpiToken.connect(randomAccount1).redeem();
        expect(await kpiToken.totalSupply()).to.be.equal(
            totalSupply.mul(30).div(100)
        );
        expect(
            await collateralContract.balanceOf(randomAccount1.address)
        ).to.be.equal(collateralData.amount.mul(60).div(100));

        await kpiToken.connect(randomAccount2).redeem();
        expect(await kpiToken.totalSupply()).to.be.equal(0);
        expect(
            await collateralContract.balanceOf(randomAccount2.address)
        ).to.be.equal(collateralData.amount.mul(30).div(100));
    });
});

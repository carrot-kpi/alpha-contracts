import { expect } from "chai";
import { fixture } from "../fixtures";
import { constants } from "ethers";
import { waffle } from "hardhat";
import {
    encodeRealityQuestion,
    getKpiTokenAddressFromReceipt,
    getRealityQuestionId,
} from "../utils";
import { DateTime } from "luxon";
import { parseEther } from "ethers/lib/utils";

const { loadFixture } = waffle;

describe("KPITokensFactory - Create KPI token", () => {
    it("should fail when collateral token is the 0 address", async () => {
        const { kpiTokensFactory } = await loadFixture(fixture);
        await expect(
            kpiTokensFactory.createKpiToken(
                encodeRealityQuestion("Test?"),
                Math.floor(DateTime.now().plus({ minutes: 2 }).toSeconds()),
                { token: constants.AddressZero, amount: 1 },
                { name: "Test", symbol: "TEST", totalSupply: 10 },
                { lowerBound: 0, higherBound: 1 }
            )
        ).to.be.revertedWith("KF09");
    });

    it("should fail when collateral amount is 0", async () => {
        const { kpiTokensFactory, collateralToken } = await loadFixture(
            fixture
        );
        await expect(
            kpiTokensFactory.createKpiToken(
                encodeRealityQuestion("Test?"),
                Math.floor(DateTime.now().plus({ minutes: 2 }).toSeconds()),
                { token: collateralToken.address, amount: 0 },
                { name: "Test", symbol: "TEST", totalSupply: 10 },
                { lowerBound: 0, higherBound: 1 }
            )
        ).to.be.revertedWith("KF10");
    });

    it("should fail when no name is given", async () => {
        const { kpiTokensFactory, collateralToken } = await loadFixture(
            fixture
        );
        await expect(
            kpiTokensFactory.createKpiToken(
                encodeRealityQuestion("Test?"),
                Math.floor(DateTime.now().plus({ minutes: 2 }).toSeconds()),
                { token: collateralToken.address, amount: 1 },
                { name: "", symbol: "TEST", totalSupply: 10 },
                { lowerBound: 0, higherBound: 1 }
            )
        ).to.be.revertedWith("KF11");
    });

    it("should fail when no symbol is given", async () => {
        const { kpiTokensFactory, collateralToken } = await loadFixture(
            fixture
        );
        await expect(
            kpiTokensFactory.createKpiToken(
                encodeRealityQuestion("Test?"),
                Math.floor(DateTime.now().plus({ minutes: 2 }).toSeconds()),
                { token: collateralToken.address, amount: 1 },
                { name: "Test", symbol: "", totalSupply: 10 },
                { lowerBound: 0, higherBound: 1 }
            )
        ).to.be.revertedWith("KF12");
    });

    it("should fail when total supply is 0", async () => {
        const { kpiTokensFactory, collateralToken } = await loadFixture(
            fixture
        );
        await expect(
            kpiTokensFactory.createKpiToken(
                encodeRealityQuestion("Test?"),
                Math.floor(DateTime.now().plus({ minutes: 2 }).toSeconds()),
                { token: collateralToken.address, amount: 1 },
                { name: "Test", symbol: "TEST", totalSupply: 0 },
                { lowerBound: 0, higherBound: 1 }
            )
        ).to.be.revertedWith("KF13");
    });

    it("should fail when no question is given", async () => {
        const { kpiTokensFactory, collateralToken } = await loadFixture(
            fixture
        );
        await expect(
            kpiTokensFactory.createKpiToken(
                "",
                Math.floor(DateTime.now().plus({ minutes: 2 }).toSeconds()),
                { token: collateralToken.address, amount: 1 },
                { name: "Test", symbol: "TEST", totalSupply: 10 },
                { lowerBound: 0, higherBound: 1 }
            )
        ).to.be.revertedWith("KF14");
    });

    it("should fail when kpi expiry is in the past", async () => {
        const { kpiTokensFactory, collateralToken } = await loadFixture(
            fixture
        );
        await expect(
            kpiTokensFactory.createKpiToken(
                encodeRealityQuestion("Test?"),
                Math.floor(DateTime.now().minus({ minutes: 2 }).toSeconds()),
                { token: collateralToken.address, amount: 1 },
                { name: "Test", symbol: "TEST", totalSupply: 10 },
                { lowerBound: 0, higherBound: 1 }
            )
        ).to.be.revertedWith("KF15");
    });

    it("should fail when the user has not enough collateral balance", async () => {
        const { kpiTokensFactory, collateralToken } = await loadFixture(
            fixture
        );
        await expect(
            kpiTokensFactory.createKpiToken(
                encodeRealityQuestion("Test?"),
                Math.floor(DateTime.now().plus({ minutes: 2 }).toSeconds()),
                { token: collateralToken.address, amount: 1 },
                { name: "Test", symbol: "TEST", totalSupply: 10 },
                { lowerBound: 0, higherBound: 1 }
            )
        ).to.be.revertedWith("ERC20: transfer amount exceeds balance");
    });

    it("should fail when the user has not enough allowance set", async () => {
        const {
            kpiTokensFactory,
            collateralToken,
            testAccount,
        } = await loadFixture(fixture);
        const collateralAmount = parseEther("10");
        await collateralToken.mint(testAccount.address, collateralAmount);
        await expect(
            kpiTokensFactory.connect(testAccount).createKpiToken(
                encodeRealityQuestion("Test?"),
                Math.floor(DateTime.now().plus({ minutes: 2 }).toSeconds()),
                {
                    token: collateralToken.address,
                    amount: collateralAmount,
                },
                { name: "Test", symbol: "TEST", totalSupply: 10 },
                { lowerBound: 0, higherBound: 1 }
            )
        ).to.be.revertedWith("ERC20: transfer amount exceeds allowance");
    });

    it("should succeed in the right conditions", async () => {
        const {
            kpiToken,
            kpiTokensFactory,
            collateralToken,
            testAccount,
            feeReceiver,
            arbitrator,
        } = await loadFixture(fixture);
        const collateralAmount = parseEther("100");
        await collateralToken.mint(testAccount.address, collateralAmount);
        await collateralToken
            .connect(testAccount)
            .approve(kpiTokensFactory.address, collateralAmount);
        const question = encodeRealityQuestion("Test?");
        const kpiExpiry = Math.floor(
            DateTime.now().plus({ minutes: 2 }).toSeconds()
        );
        const transaction = await kpiTokensFactory
            .connect(testAccount)
            .createKpiToken(
                question,
                kpiExpiry,
                { token: collateralToken.address, amount: collateralAmount },
                { name: "Test", symbol: "TEST", totalSupply: 10 },
                { lowerBound: 0, higherBound: 1 }
            );
        const receipt = await transaction.wait();
        expect(await collateralToken.balanceOf(testAccount.address)).to.equal(
            0
        );
        expect(
            await collateralToken.balanceOf(kpiTokensFactory.address)
        ).to.equal(0);
        const feeAmount = collateralAmount.mul(30).div(10000); // 30 bips is the default fee
        expect(
            await collateralToken.balanceOf(feeReceiver.address)
        ).to.be.equal(feeAmount);
        const createdKpiToken = await kpiToken.attach(
            getKpiTokenAddressFromReceipt(receipt)
        );
        expect(
            await collateralToken.balanceOf(createdKpiToken.address)
        ).to.equal(collateralAmount.sub(feeAmount));
        expect(await createdKpiToken.collateralToken()).to.be.equal(
            collateralToken.address
        );
        const timeout = await kpiTokensFactory.voteTimeout();
        expect(await createdKpiToken.kpiId()).to.be.equal(
            getRealityQuestionId(
                0,
                kpiExpiry,
                question,
                arbitrator.address,
                timeout,
                kpiTokensFactory.address,
                0
            )
        );
        const oracle = await kpiTokensFactory.oracle();
        expect(await createdKpiToken.oracle()).to.be.equal(oracle);
        expect(await createdKpiToken.creator()).to.be.equal(
            testAccount.address
        );
        expect(await createdKpiToken.finalKpiProgress()).to.be.equal(0);
        expect(await createdKpiToken.finalized()).to.be.false;
    });
});

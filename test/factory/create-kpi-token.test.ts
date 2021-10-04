import { expect } from "chai";
import { fixture } from "../fixtures";
import { constants, Wallet } from "ethers";
import { waffle } from "hardhat";
import {
    encodeRealityQuestion,
    getCollateralAmountPlusFees,
    getKpiTokenAddressFromReceipt,
    getRealityQuestionId,
} from "../utils";
import { DateTime } from "luxon";

const { loadFixture } = waffle;

describe("KPITokensFactory - Create KPI token", () => {
    it("should fail when collateral token is the 0 address", async () => {
        const { kpiTokensFactory, arbitrator } = await loadFixture(fixture);
        await expect(
            kpiTokensFactory.createKpiToken(
                {
                    question: encodeRealityQuestion("Test?"),
                    expiry: Math.floor(
                        DateTime.now().plus({ minutes: 2 }).toSeconds()
                    ),
                    timeout: 60,
                    arbitrator: arbitrator.address,
                },
                { token: constants.AddressZero, amount: 1 },
                { name: "Test", symbol: "TEST", totalSupply: 10 },
                { lowerBound: 0, higherBound: 1 }
            )
        ).to.be.revertedWith("ZeroAddressCollateralToken");
    });

    it("should fail when collateral amount is 0", async () => {
        const {
            kpiTokensFactory,
            collateralToken,
            arbitrator,
        } = await loadFixture(fixture);
        await expect(
            kpiTokensFactory.createKpiToken(
                {
                    question: encodeRealityQuestion("Test?"),
                    expiry: Math.floor(
                        DateTime.now().plus({ minutes: 2 }).toSeconds()
                    ),
                    timeout: 60,
                    arbitrator: arbitrator.address,
                },
                { token: collateralToken.address, amount: 0 },
                { name: "Test", symbol: "TEST", totalSupply: 10 },
                { lowerBound: 0, higherBound: 1 }
            )
        ).to.be.revertedWith("InvalidCollateralAmount");
    });

    it("should fail when no name is given", async () => {
        const {
            kpiTokensFactory,
            collateralToken,
            arbitrator,
        } = await loadFixture(fixture);
        await expect(
            kpiTokensFactory.createKpiToken(
                {
                    question: encodeRealityQuestion("Test?"),
                    expiry: Math.floor(
                        DateTime.now().plus({ minutes: 2 }).toSeconds()
                    ),
                    timeout: 60,
                    arbitrator: arbitrator.address,
                },
                { token: collateralToken.address, amount: 1 },
                { name: "", symbol: "TEST", totalSupply: 10 },
                { lowerBound: 0, higherBound: 1 }
            )
        ).to.be.revertedWith("InvalidTokenName");
    });

    it("should fail when no symbol is given", async () => {
        const {
            kpiTokensFactory,
            collateralToken,
            arbitrator,
        } = await loadFixture(fixture);
        await expect(
            kpiTokensFactory.createKpiToken(
                {
                    question: encodeRealityQuestion("Test?"),
                    expiry: Math.floor(
                        DateTime.now().plus({ minutes: 2 }).toSeconds()
                    ),
                    timeout: 60,
                    arbitrator: arbitrator.address,
                },
                { token: collateralToken.address, amount: 1 },
                { name: "Test", symbol: "", totalSupply: 10 },
                { lowerBound: 0, higherBound: 1 }
            )
        ).to.be.revertedWith("InvalidTokenSymbol");
    });

    it("should fail when total supply is 0", async () => {
        const {
            kpiTokensFactory,
            collateralToken,
            arbitrator,
        } = await loadFixture(fixture);
        await expect(
            kpiTokensFactory.createKpiToken(
                {
                    question: encodeRealityQuestion("Test?"),
                    expiry: Math.floor(
                        DateTime.now().plus({ minutes: 2 }).toSeconds()
                    ),
                    timeout: 60,
                    arbitrator: arbitrator.address,
                },
                { token: collateralToken.address, amount: 1 },
                { name: "Test", symbol: "TEST", totalSupply: 0 },
                { lowerBound: 0, higherBound: 1 }
            )
        ).to.be.revertedWith("ZeroTotalSupply");
    });

    it("should fail when no question is given", async () => {
        const { kpiTokensFactory, collateralToken } = await loadFixture(
            fixture
        );
        await expect(
            kpiTokensFactory.createKpiToken(
                {
                    question: "",
                    expiry: Math.floor(
                        DateTime.now().plus({ minutes: 2 }).toSeconds()
                    ),
                    timeout: 60,
                    arbitrator: Wallet.createRandom().address,
                },
                { token: collateralToken.address, amount: 1 },
                { name: "Test", symbol: "TEST", totalSupply: 10 },
                { lowerBound: 0, higherBound: 1 }
            )
        ).to.be.revertedWith("InvalidRealityQuestion");
    });

    it("should fail when kpi expiry is in the past", async () => {
        const { kpiTokensFactory, collateralToken } = await loadFixture(
            fixture
        );
        await expect(
            kpiTokensFactory.createKpiToken(
                {
                    question: encodeRealityQuestion("Test?"),
                    expiry: Math.floor(
                        DateTime.now().minus({ minutes: 2 }).toSeconds()
                    ),
                    timeout: 60,
                    arbitrator: Wallet.createRandom().address,
                },
                { token: collateralToken.address, amount: 1 },
                { name: "Test", symbol: "TEST", totalSupply: 10 },
                { lowerBound: 0, higherBound: 1 }
            )
        ).to.be.revertedWith("InvalidRealityExpiry");
    });

    it("should fail when a 0-address arbitrator is given", async () => {
        const { kpiTokensFactory, collateralToken } = await loadFixture(
            fixture
        );
        await expect(
            kpiTokensFactory.createKpiToken(
                {
                    question: encodeRealityQuestion("Test?"),
                    expiry: Math.floor(
                        DateTime.now().plus({ minutes: 2 }).toSeconds()
                    ),
                    timeout: 60,
                    arbitrator: constants.AddressZero,
                },
                { token: collateralToken.address, amount: 1 },
                { name: "Test", symbol: "TEST", totalSupply: 10 },
                { lowerBound: 0, higherBound: 1 }
            )
        ).to.be.revertedWith("ZeroAddressRealityArbitrator");
    });

    it("should fail when the user has not enough collateral balance", async () => {
        const { kpiTokensFactory, collateralToken } = await loadFixture(
            fixture
        );
        await expect(
            kpiTokensFactory.createKpiToken(
                {
                    question: encodeRealityQuestion("Test?"),
                    expiry: Math.floor(
                        DateTime.now().plus({ minutes: 2 }).toSeconds()
                    ),
                    timeout: 60,
                    arbitrator: Wallet.createRandom().address,
                },
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
        const { baseAmount, totalAmount } = getCollateralAmountPlusFees("10");
        await collateralToken.mint(testAccount.address, totalAmount);
        await expect(
            kpiTokensFactory.connect(testAccount).createKpiToken(
                {
                    question: encodeRealityQuestion("Test?"),
                    expiry: Math.floor(
                        DateTime.now().plus({ minutes: 2 }).toSeconds()
                    ),
                    timeout: 60,
                    arbitrator: Wallet.createRandom().address,
                },
                {
                    token: collateralToken.address,
                    amount: baseAmount,
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
        const {
            baseAmount,
            feeAmount,
            totalAmount,
        } = getCollateralAmountPlusFees("100");
        await collateralToken.mint(testAccount.address, totalAmount);
        await collateralToken
            .connect(testAccount)
            .approve(kpiTokensFactory.address, totalAmount);
        const question = encodeRealityQuestion("Test?");
        const kpiExpiry = Math.floor(
            DateTime.now().plus({ minutes: 2 }).toSeconds()
        );
        const timeout = 60;
        const transaction = await kpiTokensFactory
            .connect(testAccount)
            .createKpiToken(
                {
                    question: question,
                    expiry: kpiExpiry,
                    timeout,
                    arbitrator: arbitrator.address,
                },
                { token: collateralToken.address, amount: baseAmount },
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
        expect(
            await collateralToken.balanceOf(feeReceiver.address)
        ).to.be.equal(feeAmount);
        const createdKpiToken = await kpiToken.attach(
            getKpiTokenAddressFromReceipt(receipt)
        );
        expect(
            await collateralToken.balanceOf(createdKpiToken.address)
        ).to.equal(baseAmount);
        expect(await createdKpiToken.collateralToken()).to.be.equal(
            collateralToken.address
        );
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

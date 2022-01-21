import { loadFixture, MockProvider } from "ethereum-waffle";
import { Wallet } from "ethers";
import { parseEther } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { DateTime } from "luxon";
import {
    KPITokensFactory,
    KPITokensFactory__factory,
    KPIToken,
    KPIToken__factory,
    Realitio,
    Realitio__factory,
    ERC20PresetMinterPauser,
    ERC20PresetMinterPauser__factory,
} from "../../typechain-types";
import {
    encodeRealityQuestion,
    getCollateralAmountPlusFees,
    getEvmTimestamp,
    getKpiTokenAddressFromReceipt,
    getRealityQuestionId,
} from "../utils";

export const preFactoryDeploymentFixture = async (
    _: any,
    provider: MockProvider
) => {
    const [, testAccount, oracleAccount] = provider.getWallets();

    const realitioFactory = (await ethers.getContractFactory(
        "Realitio"
    )) as Realitio__factory;
    const realitio = (await realitioFactory.deploy()) as Realitio;

    const kpiTokenFactory = (await ethers.getContractFactory(
        "KPIToken"
    )) as KPIToken__factory;
    const kpiToken = (await kpiTokenFactory.deploy()) as KPIToken;

    const kpiTokensFactoryFactory = (await ethers.getContractFactory(
        "KPITokensFactory"
    )) as KPITokensFactory__factory;

    const collateralTokenFactory = (await ethers.getContractFactory(
        "ERC20PresetMinterPauser"
    )) as ERC20PresetMinterPauser__factory;
    const collateralToken = (await collateralTokenFactory.deploy(
        "Collateral",
        "CLT"
    )) as ERC20PresetMinterPauser;

    return {
        testAccount,
        oracleAccount,
        kpiToken,
        realitio,
        kpiTokensFactoryFactory,
        collateralToken,
    };
};

export const fixture = async (_: any, provider: MockProvider) => {
    const [, testAccount, oracleAccount] = provider.getWallets();

    const realitioFactory = (await ethers.getContractFactory(
        "Realitio"
    )) as Realitio__factory;
    const realitio = (await realitioFactory.deploy()) as Realitio;

    const kpiTokenFactory = (await ethers.getContractFactory(
        "KPIToken"
    )) as KPIToken__factory;
    const kpiToken = (await kpiTokenFactory.deploy()) as KPIToken;

    const kpiTokensFactoryFactory = (await ethers.getContractFactory(
        "KPITokensFactory"
    )) as KPITokensFactory__factory;
    const arbitrator = Wallet.createRandom(); // pseudo-random arbitrator for test purposes
    const feeReceiver = Wallet.createRandom(); // pseudo-random fee receiver for test purposes
    const voteTimeout = 120; // 3 minutes vote timeout
    const kpiTokensFactory = (await kpiTokensFactoryFactory.deploy(
        kpiToken.address,
        realitio.address,
        arbitrator.address,
        30,
        voteTimeout,
        feeReceiver.address
    )) as KPITokensFactory;

    const collateralTokenFactory = (await ethers.getContractFactory(
        "ERC20PresetMinterPauser"
    )) as ERC20PresetMinterPauser__factory;
    const collateralToken = (await collateralTokenFactory.deploy(
        "Collateral",
        "CLT"
    )) as ERC20PresetMinterPauser;

    return {
        testAccount,
        oracleAccount,
        realitio,
        kpiToken,
        kpiTokensFactory,
        collateralToken,
        feeReceiver,
        arbitrator,
        voteTimeout,
    };
};

export const testBooleanKpiTokenFixture = async (
    _: any,
    provider: MockProvider
) => {
    const {
        kpiTokensFactory,
        testAccount,
        collateralToken,
        realitio,
        arbitrator,
        voteTimeout,
    } = await fixture(_, provider);
    const { baseAmount, totalAmount } = getCollateralAmountPlusFees("10");

    // mint collateral to caller
    await collateralToken.mint(testAccount.address, totalAmount);

    // approving collateral to factory
    await collateralToken
        .connect(testAccount)
        .approve(kpiTokensFactory.address, totalAmount);

    // creating kpi token
    const kpiExpiry = Math.floor(
        DateTime.now().plus({ minutes: 5 }).toMillis() / 1000
    );
    const question = encodeRealityQuestion("Will this test pass?");
    const collateralData = {
        token: collateralToken.address,
        amount: baseAmount,
    };
    const transaction = await kpiTokensFactory
        .connect(testAccount)
        .createKpiToken(
            question,
            kpiExpiry,
            collateralData,
            {
                name: "Test KPI token",
                symbol: "KPI",
                totalSupply: parseEther("100000"),
            },
            { lowerBound: 0, higherBound: 1 }
        );
    const receipt = await transaction.wait();

    const kpiTokenFactory = (await ethers.getContractFactory(
        "KPIToken"
    )) as KPIToken__factory;
    const kpiToken = kpiTokenFactory.attach(
        getKpiTokenAddressFromReceipt(receipt)
    );

    return {
        testAccount,
        kpiToken,
        collateralToken,
        question,
        kpiExpiry,
        realitio,
        realiyQuestionId: getRealityQuestionId(
            0,
            kpiExpiry,
            question,
            arbitrator.address,
            voteTimeout,
            kpiTokensFactory.address,
            0
        ),
        voteTimeout,
        collateralData,
    };
};

export const getScalarKpiTokenFixture = (
    lowerBound: number,
    higherBound: number
) => async (_: any, provider: MockProvider) => {
    const {
        kpiTokensFactory,
        testAccount,
        collateralToken,
        realitio,
        arbitrator,
        voteTimeout,
    } = await fixture(_, provider);
    const { baseAmount, feeAmount, totalAmount } = getCollateralAmountPlusFees(
        "10"
    );

    // mint collateral to caller
    await collateralToken.mint(testAccount.address, totalAmount);

    // approving collateral to factory
    await collateralToken
        .connect(testAccount)
        .approve(kpiTokensFactory.address, totalAmount);

    // creating kpi token
    const kpiExpiry = Math.floor((await getEvmTimestamp()) + 300); // 5 minutes from the current EVM timestamp
    const question = encodeRealityQuestion("Will this test pass?");
    const collateralData = {
        token: collateralToken.address,
        amount: baseAmount,
    };
    const transaction = await kpiTokensFactory
        .connect(testAccount)
        .createKpiToken(
            question,
            kpiExpiry,
            collateralData,
            {
                name: "Test KPI token",
                symbol: "KPI",
                totalSupply: parseEther("100000"),
            },
            { lowerBound, higherBound }
        );
    const receipt = await transaction.wait();

    const kpiTokenFactory = (await ethers.getContractFactory(
        "KPIToken"
    )) as KPIToken__factory;
    const kpiToken = kpiTokenFactory.attach(
        getKpiTokenAddressFromReceipt(receipt)
    );

    return {
        testAccount,
        kpiToken,
        collateralToken,
        question,
        kpiExpiry,
        realitio,
        realiyQuestionId: getRealityQuestionId(
            1,
            kpiExpiry,
            question,
            arbitrator.address,
            voteTimeout,
            kpiTokensFactory.address,
            0
        ),
        voteTimeout,
        collateralData,
    };
};

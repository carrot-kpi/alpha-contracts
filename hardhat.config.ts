import { HardhatUserConfig } from "hardhat/types/config";
import "dotenv/config";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "./tasks/deploy";
import "./tasks/create-uniswap-v2-twap-kpi-token";
import "./tasks/create-reality-eth-kpi-token";
import "./tasks/create-manual-reality-eth-erc20-kpi-token";
import "./tasks/create-manual-reality-eth-aave-erc20-kpi-token";
import "./tasks/upgrade-uniswap-v2-twap-template";
import "./tasks/upgrade-erc20-kpi-token-template";
import "./tasks/upgrade-manual-reality-eth-oracle-template";
import "./tasks/get-manual-reality-orace-calldata";
import "./tasks/upgrade-aave-erc20-kpi-token-template";

const infuraId = process.env.INFURA_ID;
const accounts = process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [];

const hardhatConfig: HardhatUserConfig = {
    networks: {
        mainnet: {
            url: `https://mainnet.infura.io/v3/${infuraId}`,
            chainId: 1,
        },
        rinkeby: {
            url: `https://rinkeby.infura.io/v3/${infuraId}`,
            chainId: 4,
            accounts,
        },
        kovan: {
            url: `https://kovan.infura.io/v3/${infuraId}`,
            chainId: 42,
            accounts,
        },
        arbitrumTestnetV3: {
            url: "https://kovan3.arbitrum.io/rpc",
            accounts,
            gasPrice: 0,
        },
        xdai: {
            url: "https://xdai.poanetwork.dev",
            accounts,
            gasPrice: 0,
        },
    },
    solidity: {
        compilers: [
            {
                version: "0.8.13",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 2000,
                        details: {
                            yul: true,
                        },
                    },
                },
            },
        ],
    },
    etherscan: {
        apiKey: process.env.ETHERSCAN_API_KEY,
    },
};

export default hardhatConfig;

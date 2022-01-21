import { HardhatUserConfig } from "hardhat/types/config";
import { config } from "dotenv";
import "solidity-coverage";
import "hardhat-gas-reporter";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-dependency-compiler";
import "./tasks/deploy";
import "./tasks/create-uniswap-v2-twap-kpi-token";
import "./tasks/create-reality-eth-kpi-token";
import "./tasks/create-manual-reality-eth-kpi-token";
import "./tasks/upgrade-uniswap-v2-twap-template";
import "./tasks/upgrade-erc20-kpi-token-template";
import "./tasks/upgrade-manual-reality-eth-oracle-template";

config();

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
                version: "0.8.11",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
            {
                version: "0.4.25",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
        ],
    },
    gasReporter: {
        currency: "USD",
        enabled: process.env.GAS_REPORT_ENABLED === "true",
    },
    etherscan: {
        apiKey: process.env.ETHERSCAN_API_KEY,
    },
    dependencyCompiler: {
        paths: [
            "@realitio/realitio-contracts/truffle/contracts/Realitio.sol",
            "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol",
        ],
    },
};

export default hardhatConfig;

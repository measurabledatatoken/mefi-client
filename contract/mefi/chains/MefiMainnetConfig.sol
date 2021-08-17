// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "../interfaces/MefiChainConfig.sol";

contract MefiMainnetConfig is MefiChainConfig {
    uint256 public override chainId = 1;
    address public override tokenAddr = 0x814e0908b12A99FeCf5BC101bB5d0b8B5cDf7d26;
    address public override oracleAddr = 0x66C22dC23fEe2D972BE1D72cE6C04986290BC4fE;
    bytes32 public override requestStockPriceJobId = "770dc00f53d94d56b062b5843a18e21c";
}
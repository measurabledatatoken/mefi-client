// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "../interfaces/MefiChainConfig.sol";

contract MefiBSCTestnetConfig is MefiChainConfig {
    uint256 public override chainId = 97;
    address public override tokenAddr = 0x3e76EECc362E426967b3CD114C89f53F56478769;
    address public override oracleAddr = 0x4D17034E1d959a989D5953D09b40F34f77FACBfc;
    bytes32 public override requestStockPriceJobId = "2687a9320368446b9565ef9f1a1b9daa";
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "../interfaces/MefiChainConfig.sol";

contract MefiRinkebyConfig is MefiChainConfig {
    uint256 public override chainId = 4;
    address public override tokenAddr = 0xd043d85dF623E6168C6DE5d4728dD2844D9d5B3C;
    address public override oracleAddr = 0x395CeE958F302349Ce4a91EFa0A531Be938Fdb06;
    bytes32 public override requestStockPriceJobId = "2cfc1a80981e4a3597b623d07e3ef7ff";
    uint256 public override requestStockPriceJobFee = 10000000000000000000;
}
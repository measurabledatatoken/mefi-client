// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface MefiChainConfig {
    function chainId() external view returns (uint256);
    function tokenAddr() external view returns (address);
    function oracleAddr() external view returns (address);
    function requestStockPriceJobId() external view returns (bytes32);
    function requestStockPriceJobFee() external view returns (uint256);
}
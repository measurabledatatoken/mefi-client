// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "https://github.com/measurabledatatoken/mefi-client/blob/main/contract/mefi/MefiClient.sol";
import "https://github.com/measurabledatatoken/mefi-client/blob/main/contract/mefi/chains/MefiRinkebyConfig.sol";

contract MefiOracleConsumer is MefiClient, MefiRinkebyConfig {
    bytes32 public curReqId;

    mapping(bytes32 => string) public prices;
    mapping(bytes32 => string) public currencies;
    mapping(bytes32 => string) public dates;

    constructor() public {
        setPublicMefiToken();
        setOracleAddress(oracleAddr);
    }

    // REQUEST STOCK PRICE JOB

    /**
     * update Job ID once Oracle contract has been deployed elsewhere again
     */
    function setRequestStockPriceJobId(string memory _jobId) onlyOwner public {
        requestStockPriceJobId = stringToBytes32(_jobId);
    }

    function getRequestStockPriceJobIdString() public view returns (string memory) {
        return bytes32ToString(requestStockPriceJobId);
    }

    /**
     * Initial request
     */
    function requestStockPrice(string memory _symbol) public returns (bytes32) {
        Mefi.Request memory req = buildMefiStockPriceRequest(requestStockPriceJobId, _symbol, address(this), this.fulfillStockPrice.selector);
        curReqId = sendMefiRequest(req, requestStockPriceJobFee);
        return curReqId;
    }

    /**
     * Callback function
     */
    function fulfillStockPrice(bytes32 _requestId, bytes32 _result) public recordMefiFulfillment(_requestId) {
        string[] memory data = readStockPriceWithTime(_result);
        prices[_requestId] = data[0];
        dates[_requestId] = data[1];
        currencies[_requestId] = data[2];
    }
}
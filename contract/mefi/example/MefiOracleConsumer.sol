// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "https://github.com/measurabledatatoken/mefi-client/blob/main/contract/mefi/MefiClient.sol";

contract MefiOracleConsumer is MefiClient {
    bytes32 private requestStockPriceJobId = "2cfc1a80981e4a3597b623d07e3ef7ff";

    bytes32 public curReqId;

    mapping(bytes32 => uint256) public prices;
    mapping(bytes32 => uint256) public dates;

    constructor() public {
        setPublicMefiToken();
        setOracleAddress(0x395CeE958F302349Ce4a91EFa0A531Be938Fdb06);
    }

    // REQUEST STOCK PRICE JOB

    /**
     * update Job ID once Oracle contract has been deployed elsewhere again
     */
    function setRequestStockPriceJobId(string memory _jobId) onlyOwner public {
        requestStockPriceJobId = stringToBytes32(_jobId);
    }

    function getRequestStockPriceJobId() public view returns (string memory) {
        return bytes32ToString(requestStockPriceJobId);
    }

    /**
     * Initial request
     */
    function requestStockPrice(string memory _symbol, uint256 _fee) public returns (bytes32) {
        Mefi.Request memory req = buildMefiStockPriceRequest(requestStockPriceJobId, _symbol, address(this), this.fulfillStockPrice.selector);
        curReqId = sendMefiRequest(req, _fee);
        return curReqId;
    }

    /**
     * Callback function
     */
    function fulfillStockPrice(bytes32 _requestId, bytes32 _result) public recordMefiFulfillment(_requestId) {
        uint[] memory data = readStockPriceWithTime(_result);
        prices[_requestId] = data[0];
        dates[_requestId] = data[1];
    }
}
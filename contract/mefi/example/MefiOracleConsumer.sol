// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "https://github.com/measurabledatatoken/mefi-client/blob/main/contract/mefi/MefiClient.sol";

contract MefiOracleConsumer is MefiClient {
    address private oracle;
    bytes32 private jobId;

    uint256 public price;
    uint256 public time;

    constructor() public {
        setPublicMefiToken();
        setOracle(0xD506A8d3130A0892Fd2556368eC04f3dB60026ae);
        jobId = "21143a9fbb924b849d303807f3e25eca";
    }

    function setOracle(address _oracle) public {
        oracle = _oracle;
        setMefiOracle(oracle);
    }

    function setJobId(string memory _jobId) public {
        jobId = stringToBytes32(_jobId);
    }

    /**
     * Initial request
     */
    function requestStockPrice(string memory _symbol, uint256 _fee) public {
        Mefi.Request memory req = buildMefiStockPriceRequest(jobId, _symbol, address(this), this.fulfillStockPrice.selector);
        sendMefiRequest(req, _fee);
    }

    /**
     * Callback function
     */
    function fulfillStockPrice(bytes32 _requestId, bytes32 _result) public recordMefiFulfillment(_requestId) {
        uint[] memory data = readStockPriceWithTime(_result);
        price = data[0];
        time = data[1];
    }
}
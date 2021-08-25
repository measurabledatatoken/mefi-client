// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Mefi.sol";
import "./interfaces/ENSInterface.sol";
import "./interfaces/MDTTokenInterface.sol";
import "./interfaces/MefiRequestInterface.sol";
import "./vendor/Ownable.sol";
import {ENSResolver as ENSResolver_Mefi} from "./vendor/ENSResolver.sol";

/**
 * @title The MefiClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Mefi network
 */
contract MefiClient is Ownable {
    using Mefi for Mefi.Request;

    uint256 constant internal MDT = 10 ** 18;
    uint256 constant private AMOUNT_OVERRIDE = 0;
    address constant private SENDER_OVERRIDE = address(0);
    uint256 constant private ARGS_VERSION = 1;
    bytes32 constant private ENS_TOKEN_SUBNAME = keccak256("mdt");
    bytes32 constant private ENS_ORACLE_SUBNAME = keccak256("oracle");

    address constant private MDT_TOKEN_ADDRESS_MAINNET = 0x814e0908b12A99FeCf5BC101bB5d0b8B5cDf7d26; // Mainnet
    address constant private MDT_TOKEN_ADDRESS_RINKEBY = 0xd043d85dF623E6168C6DE5d4728dD2844D9d5B3C; // Rinkeby
    address constant private MDT_TOKEN_ADDRESS_BSC_TESTNET = 0xd043d85dF623E6168C6DE5d4728dD2844D9d5B3C; // BSC Testnet
    uint256 constant private CHAIN_ID_MAINNET = 1;
    uint256 constant private CHAIN_ID_RINKEBY = 4;
    uint256 constant private CHAIN_ID_BSC_TESTNET = 97;

    ENSInterface private ens;
    bytes32 private ensNode;
    MDTTokenInterface private mdt;
    MefiRequestInterface private oracle;
    uint256 private requestCount = 1;
    mapping(bytes32 => address) private pendingRequests;

    address internal oracleAddress;

    event MefiRequested(bytes32 indexed id);
    event MefiFulfilled(bytes32 indexed id);
    event MefiCancelled(bytes32 indexed id);

    function setOracleAddress(address _oracleAddress) onlyOwner public {
        oracleAddress = _oracleAddress;
        setMefiOracle(oracleAddress);
    }

    function getOracleAddress() public view returns (address) {
        return oracleAddress;
    }

    /**
     * @notice Creates a request that can hold additional parameters
     * @param _specId The Job Specification ID that the request will be created for
     * @param _callbackAddress The callback address that the response will be sent to
     * @param _callbackFunctionSignature The callback function signature to use for the callback address
     * @return A Mefi Request struct in memory
     */
    function buildMefiRequest(
        bytes32 _specId,
        address _callbackAddress,
        bytes4 _callbackFunctionSignature
    ) internal pure returns (Mefi.Request memory) {
        Mefi.Request memory req;
        return req.initialize(_specId, _callbackAddress, _callbackFunctionSignature);
    }

    /**
     * @notice Creates a request that can hold additional parameters
     * @param _specId The Job Specification ID that the request will be created for
     * @param _symbol The symbol that the stock price of which is requested for
     * @param _callbackAddress The callback address that the response will be sent to
     * @param _callbackFunctionSignature The callback function signature to use for the callback address
     * @return A Mefi Request struct in memory
     */
    function buildMefiStockPriceRequest(
        bytes32 _specId,
        string memory _symbol,
        address _callbackAddress,
        bytes4 _callbackFunctionSignature
    ) internal pure returns (Mefi.Request memory) {
        Mefi.Request memory req;
        req = req.initialize(_specId, _callbackAddress, _callbackFunctionSignature);
        req.add("symbol", _symbol);
        return req;
    }

    /**
     * @notice Creates a Mefi request to the stored oracle address
     * @dev Calls `mefiRequestTo` with the stored oracle address
     * @param _req The initialized Mefi Request
     * @param _payment The amount of MDT to send for the request
     * @return requestId The request ID
     */
    function sendMefiRequest(Mefi.Request memory _req, uint256 _payment)
    internal
    returns (bytes32)
    {
        return sendMefiRequestTo(address(oracle), _req, _payment);
    }

    /**
     * @notice Creates a Mefi request to the specified oracle address
     * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
     * send MDT which creates a request on the target oracle contract.
     * Emits MefiRequested event.
     * @param _oracle The address of the oracle for the request
     * @param _req The initialized Mefi Request
     * @param _payment The amount of MDT to send for the request
     * @return requestId The request ID
     */
    function sendMefiRequestTo(address _oracle, Mefi.Request memory _req, uint256 _payment)
    internal
    returns (bytes32 requestId)
    {
        requestId = keccak256(abi.encodePacked(this, requestCount));
        _req.nonce = requestCount;
        pendingRequests[requestId] = _oracle;
        emit MefiRequested(requestId);
        require(mdt.transferAndCall(_oracle, _payment, encodeRequest(_req)), "unable to transferAndCall to oracle");
        requestCount += 1;

        return requestId;
    }

    /**
     * @notice Allows a request to be cancelled if it has not been fulfilled
     * @dev Requires keeping track of the expiration value emitted from the oracle contract.
     * Deletes the request from the `pendingRequests` mapping.
     * Emits MefiCancelled event.
     * @param _requestId The request ID
     * @param _payment The amount of MDT sent for the request
     * @param _callbackFunc The callback function specified for the request
     * @param _expiration The time of the expiration for the request
     */
    function cancelMefiRequest(
        bytes32 _requestId,
        uint256 _payment,
        bytes4 _callbackFunc,
        uint256 _expiration
    )
    internal
    {
        MefiRequestInterface requested = MefiRequestInterface(pendingRequests[_requestId]);
        delete pendingRequests[_requestId];
        emit MefiCancelled(_requestId);
        requested.cancelOracleRequest(_requestId, _payment, _callbackFunc, _expiration);
    }

    /**
     * @notice Sets the stored oracle address
     * @param _oracle The address of the oracle contract
     */
    function setMefiOracle(address _oracle) internal {
        oracle = MefiRequestInterface(_oracle);
    }

    /**
     * @notice Sets the MDT token address
     * @param _mdt The address of the MDT token contract
     */
    function setMefiToken(address _mdt) internal {
        mdt = MDTTokenInterface(_mdt);
    }

    function getChainID() internal pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * @notice Sets the mefi token address for the public
     * network as given by the Pointer contract
     */
    function setPublicMefiToken() internal {
        uint256 chainId = getChainID();
        require(CHAIN_ID_MAINNET == chainId || CHAIN_ID_RINKEBY == chainId || CHAIN_ID_BSC_TESTNET == chainId, 'Client is deployed on chain without MDT contract');

        if (CHAIN_ID_MAINNET == chainId) {
            setMefiToken(MDT_TOKEN_ADDRESS_MAINNET);
        } else if (CHAIN_ID_RINKEBY == chainId) {
            setMefiToken(MDT_TOKEN_ADDRESS_RINKEBY);
        } else if (CHAIN_ID_BSC_TESTNET == chainId) {
            setMefiToken(MDT_TOKEN_ADDRESS_BSC_TESTNET);
        }
    }

    /**
     * @notice Retrieves the stored address of the MDT
     * @return The address of the MDT
     */
    function mefiTokenAddress()
    internal
    view
    returns (address)
    {
        return address(mdt);
    }

    /**
     * @notice Retrieves the stored address of the oracle contract
     * @return The address of the oracle contract
     */
    function mefiOracleAddress()
    internal
    view
    returns (address)
    {
        return address(oracle);
    }

    /**
     * @notice Allows for a request which was created on another contract to be fulfilled
     * on this contract
     * @param _oracle The address of the oracle contract that will fulfill the request
     * @param _requestId The request ID used for the response
     */
    function addMefiExternalRequest(address _oracle, bytes32 _requestId)
    internal
    notPendingRequest(_requestId)
    {
        pendingRequests[_requestId] = _oracle;
    }

    /**
     * @notice Sets the stored oracle and MDT contracts with the addresses resolved by ENS
     * @dev Accounts for subnodes having different resolvers
     * @param _ens The address of the ENS contract
     * @param _node The ENS node hash
     */
    function useMefiWithENS(address _ens, bytes32 _node)
    internal
    {
        ens = ENSInterface(_ens);
        ensNode = _node;
        bytes32 mdtSubnode = keccak256(abi.encodePacked(ensNode, ENS_TOKEN_SUBNAME));
        ENSResolver_Mefi resolver = ENSResolver_Mefi(ens.resolver(mdtSubnode));
        setMefiToken(resolver.addr(mdtSubnode));
        updateMefiOracleWithENS();
    }

    /**
     * @notice Sets the stored oracle contract with the address resolved by ENS
     * @dev This may be called on its own as long as `useMefiWithENS` has been called previously
     */
    function updateMefiOracleWithENS()
    internal
    {
        bytes32 oracleSubnode = keccak256(abi.encodePacked(ensNode, ENS_ORACLE_SUBNAME));
        ENSResolver_Mefi resolver = ENSResolver_Mefi(ens.resolver(oracleSubnode));
        setMefiOracle(resolver.addr(oracleSubnode));
    }

    /**
     * @notice Encodes the request to be sent to the oracle contract
     * @dev The Mefi node expects values to be in order for the request to be picked up. Order of types
     * will be validated in the oracle contract.
     * @param _req The initialized Mefi Request
     * @return The bytes payload for the `transferAndCall` method
     */
    function encodeRequest(Mefi.Request memory _req)
    private
    view
    returns (bytes memory)
    {
        return abi.encodeWithSelector(
            oracle.oracleRequest.selector,
            SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
            AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of MDT sent
            _req.id,
            _req.callbackAddress,
            _req.callbackFunctionId,
            _req.nonce,
            ARGS_VERSION,
            _req.buf.buf);
    }

    /**
     * @notice Ensures that the fulfillment is valid for this contract
     * @dev Use if the contract developer prefers methods instead of modifiers for validation
     * @param _requestId The request ID for fulfillment
     */
    function validateMefiCallback(bytes32 _requestId)
    internal
    recordMefiFulfillment(_requestId)
        // solhint-disable-next-line no-empty-blocks
    {}

    function readStockPriceWithTime(bytes32 x) internal pure returns (string[] memory) {
        bytes memory bytesString = new bytes(32);
        uint len = 0;
        for (uint i = 0; i < 32; i++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * i)));
            if (char != 0) {
                bytesString[len++] = char;
            }
        }

        uint count = 3;
        string[] memory data = new string[](count);
        uint index = 0;
        // price & timestamp are integers, currency as a string will follow behind
        for (uint i = 0; i < len || index < 2;) {
            uint c = getCharAt(bytesString, i);
            // TODO: actually can match pattern as bytes32 to reduce cost
            if (isDigit(c)) {// \d
                //                data[index] = data[index] * 10 + c - 48;
                for (uint j = 0; i + j < len - 1; j++) {// find the ending digit
                    uint nextC = getCharAt(bytesString, i + j + 1);
                    if (!isDigit(nextC)) {
                        data[index] = bytesToString(bytesString, i, j + 1);
                        i += j;
                        break;
                    }
                }
                //            } else if ((c >= 65 && c <= 90) || (c >= 97 && c <= 122)) { // \w // will not encounter alphabet without encountering double quote first
            } else if (44 == c) {// comma as array separator
                index++;
            } else if (34 == c) {// double quote for string-type field
                for (uint j = 1; i + j < len; j++) {// find the paired closing quote
                    uint nextC = getCharAt(bytesString, i + j);
                    if (34 == nextC) {
                        if (1 == j) {
                            data[index] = "";
                        } else {
                            data[index] = bytesToString(bytesString, i + 1, j - 1);
                        }
                        i += j;
                    }
                }
            }
            i++;
        }

        return data;
    }

    function getCharAt(bytes memory str, uint pos) internal pure returns (uint) {
        return uint(uint8(str[pos]));
    }

    function isDigit(uint char) internal pure returns (bool) {
        return char >= 48 && char <= 57;
    }

    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory b = bytes(source);
        if (b.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function bytes32ToString(bytes32 x) internal pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }

        return bytesToString(bytesString, 0, charCount);
    }

    function bytesToString(bytes memory bytesString, uint start, uint len) internal pure returns (string memory) {
        bytes memory substring = new bytes(len);
        for (uint j = 0; j < len; j++) {
            substring[j] = bytesString[start + j];
        }
        return string(substring);
    }

    /**
     * @dev Reverts if the sender is not the oracle of the request.
     * Emits MefiFulfilled event.
     * @param _requestId The request ID for fulfillment
     */
    modifier recordMefiFulfillment(bytes32 _requestId) {
        require(msg.sender == pendingRequests[_requestId],
            "Source must be the oracle of the request");
        delete pendingRequests[_requestId];
        emit MefiFulfilled(_requestId);
        _;
    }

    /**
     * @dev Reverts if the request is already pending
     * @param _requestId The request ID for fulfillment
     */
    modifier notPendingRequest(bytes32 _requestId) {
        require(pendingRequests[_requestId] == address(0), "Request is already pending");
        _;
    }
}

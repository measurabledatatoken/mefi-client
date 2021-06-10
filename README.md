# mefi-client


  We provide an [example](https://github.com/measurabledatatoken/mefi-client/blob/main/contract/mefi/example/MefiOracleConsumer.sol) demonstrate how to work with MeFi Oracle.
  
  Before you deploy your own client contract, please notice there'll be different addresses of Oracle contracts and different job IDs for different chains. You need to verify whether the environment of Oracle and JobID you specify in contructor belongs to the chain you deploy on or not. Right now MeFi Oracle is deployed on Mainnet and Rinkeby only. 
  
  ```
  Mainnet:
    Oracle:
      0x66C22dC23fEe2D972BE1D72cE6C04986290BC4fE
    Job ID(Request Stock Price):
      770dc00f53d94d56b062b5843a18e21c
  ```
  
  ```
  Rinkeby:
    Oracle:
      0x395CeE958F302349Ce4a91EFa0A531Be938Fdb06
    Job ID(Request Stock Price):
      2cfc1a80981e4a3597b623d07e3ef7ff
  ```

  Don't worry if you get it wrong accidently, you can update it by invoking `setOracleAddress` or `setRequestStockPriceJobId`, but it'll cost you some gas fee.
  
  If you don't want your source code published, do save the code snippet you deployed, you can use Remix service to generate its corresponding ABI json file to interact with your contract later.
  
  Since the payment during the contract interaction will be established by contract itself instead of your wallet, you have to send some MDT to your deployed contract before you invoke `requestStockPrice` function.
  
  Once you establish a request, you can monitor the `Internal Txns` on Etherscan to wait for an incoming transaction right after your outgoing transaction(request). Once you see one, you can check the result on public fields `prices` & `date` by providing the request ID(`curReqId`).

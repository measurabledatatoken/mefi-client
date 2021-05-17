# mefi-client


  We provide an [example](https://github.com/measurabledatatoken/mefi-client/blob/main/contract/mefi/example/MefiOracleConsumer.sol) demonstrate how to work with MeFi Oracle.
  
  Before you deploy your own client contract, please notice there'll be different addresses of Oracle contracts and different job IDs for different chains. You need to verify whether the environment of Oracle and JobID you specify in contructor belongs to the chain you deploy on or not. Right now MeFi Oracle is deployed on Mainnet and Rinkeby only. 
  
  ```
  Mainnet:
    Oracle:
      0x7779F290101E5591Baf864901861D9788C0c252c
    Job ID:
      0ff87c6ffcc845f388d42ba4915be595
  ```
  
  ```
  Rinkeby:
    Oracle:
      0xD506A8d3130A0892Fd2556368eC04f3dB60026ae
    Job ID:
      21143a9fbb924b849d303807f3e25eca
  ```

  Don't worry if you get it wrong accidently, you can update it by invoking `setOracle` or `setJobId`, but it'll cost you some gas fee.
  
  If you don't want your source code published, do save the code snippet you deployed, you can use Remix service to generate its corresponding ABI json file to interact with your contract later.
  
  Since the payment during the contract interaction will be established by contract itself instead of your wallet, you have to send some MDT to your deployed contract before you invoke `requestStockPrice` function.
  
  Once you establish a request, you can monitor the `Internal Txns` on Etherscan to wait for an incoming transaction right after your outgoing transaction(request). Once you see one, you can check the result on public fields `prices` & `date` by providing the request ID(`curReqId`).

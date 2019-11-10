pragma solidity ^0.5.0;


//Guys, i am facing this issue already used identifier, i don;t know why i just imported it once, i have been googling this but haven't found any solution and as i said i have imported it only once so please see to this once all contracts are deployed except this
//import "../../../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../../flashloan/base/FlashLoanReceiverBase.sol";
import "../tokens/MintableERC20.sol";
import "./KyberNetworkProxy.sol";
import "./UniswapExchange.sol";


contract MockFlashLoanReceiver is FlashLoanReceiverBase {

    using SafeMath for uint256;
    event ExecutedWithFail(address _reserve, uint256 _amount, uint256 _fee);
    event ExecutedWithSuccess(address _reserve, uint256 _amount, uint256 _fee);

    event trademade(uint256 tokens, uint256 _amount);

    constructor(ILendingPoolAddressesProvider _provider) FlashLoanReceiverBase(_provider)  public {
    }



    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee) external returns(uint256 returnedAmount) {
        //mint to this contract the specific amount
        MintableERC20 token = MintableERC20(_reserve);


        //check the contract has the specified balance
        require(_amount <= getBalanceInternal(address(this), _reserve), "Invalid balance for the contract");
        
        //BOT LOGIC
        token.approve(0xB4ca10f43caF503b7Aa0a77757B99c78212D6b92, _amount);
                // Exchange for token -> eth
        UniswapExchange followerUniSwapExchange = UniswapExchange(0xB4ca10f43caF503b7Aa0a77757B99c78212D6b92);

        uint256 DEADLINE = block.timestamp + 200;
        // Swap token -> Eth
        uint256 eth_bought = followerUniSwapExchange.tokenToEthSwapInput(_amount, 0, DEADLINE);
        // Exchange for Eth -> token
        KyberNetworkProxy swapEth = KyberNetworkProxy(); //pass in the deployed address since this is a proxy contract so we need to deploy it manually.
        
        // Swap Eth -> Token
        uint token_bought = swapEth.swapEtherToToken.value(_reserve, _fee).send(eth_bought); //first parameter is the token we wnat to recieve which will always be DAI and 2nd is conversion rate, which i just substituting as _fee for now.

        emit trademade(token_bought, _amount);
        //returning amount + fee to the destination
        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));
        emit ExecutedWithSuccess(_reserve, _amount, _fee);
        return _amount.add(_fee);

    }
}

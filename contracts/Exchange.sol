pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // TODO: remove?
import "./interfaces/IFactory.sol";

contract Exchange is ERC20 {
    using SafeMath for uint256; // TODO: use this for math?

    IERC20 token;
    IFactory factory;

    constructor(address token_address) ERC20("Sandman Swap", "DREAM") {
        require(
            token_address != address(0),
            "constructor: invalid token address"
        );

        token = IERC20(token_address);
        factory = IFactory(msg.sender);
    }

    function ethToTokenExchange(uint256 desiredTokenAmount) public payable {
        require(
            desiredTokenAmount > 0,
            "ethToTokenExchange: desiredTokenAmount too small"
        );

        uint256 tokensAmount = getExchangeAmount(
            msg.value,
            address(this).balance - msg.value,
            getTokenBalance()
        );

        require(
            tokensAmount >= desiredTokenAmount,
            "ethToTokenExchange: not enough tokens"
        );

        token.transfer(msg.sender, tokensAmount);
    }

    function tokenToEthExchange(uint256 tokenAmount, uint256 desiredEthAmount)
        public
        payable
    {
        require(
            tokenAmount > 0 && desiredEthAmount > 0,
            "tokenToEthExchange: exchange amount too small"
        );

        uint256 ethAmount = getExchangeAmount(
            tokenAmount,
            getTokenBalance(),
            address(this).balance
        );

        require(
            ethAmount >= desiredEthAmount,
            "tokenToEthExchange: not enough eth"
        );

        payable(msg.sender).transfer(ethAmount);
        token.transferFrom(msg.sender, address(this), tokenAmount);
    }

    function addLiquidity(uint256 tokensDeposit)
        public
        payable
        returns (uint256)
    {
        require(
            tokensDeposit > 0 && msg.value > 0,
            "addLiquidity: deposit amount too small"
        );

        if (getTokenBalance() == 0) {
            token.transferFrom(msg.sender, address(this), tokensDeposit);

            uint256 liquidity = address(this).balance;
            _mint(msg.sender, liquidity);

            return liquidity;
        } else {
            uint256 ethReserved = address(this).balance - msg.value;
            uint256 tokensReserved = getTokenBalance();
            uint256 tokenRatioAmount = (msg.value * ethReserved) /
                tokensReserved;

            require(
                tokenRatioAmount >= tokensDeposit,
                "addLiquidity: not enough liquidity"
            );

            token.transferFrom(msg.sender, address(this), tokenRatioAmount);

            uint256 liquidity = (msg.value * totalSupply()) / ethReserved;
            _mint(msg.sender, liquidity);

            return liquidity;
        }
    }

    function removeLiquidity(uint256 lpAmount)
        public
        returns (uint256, uint256)
    {
        require(lpAmount > 0, "removeLiquidity: lpAmount too small");

        uint256 ethWithdraw = (address(this).balance * lpAmount) /
            totalSupply();
        uint256 tokensWithdraw = (getTokenBalance() * lpAmount) / totalSupply();

        _burn(msg.sender, lpAmount);

        payable(msg.sender).transfer(ethWithdraw);
        token.transferFrom(address(this), msg.sender, tokensWithdraw);

        return (ethWithdraw, tokensWithdraw);
    }

    function getTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @notice Get exchange rate for ETH to Tokens.
     * @param ethAmount ETH to sell for Tokens.
     * @return Token exchange amount.
     */
    function getTokenExchangeAmount(uint256 ethAmount)
        private
        view
        returns (uint256)
    {
        require(ethAmount > 0, "getTokenExchangeAmount: ethAmount too small");

        return
            getExchangeAmount(
                ethAmount,
                address(this).balance,
                getTokenBalance()
            );
    }

    /**
     * @notice Get exchange rate for Tokens to ETH.
     * @param tokenAmount Tokens to sell for ETH.
     * @return ETH exchange amount.
     */
    function getEthExchangeAmount(uint256 tokenAmount)
        private
        view
        returns (uint256)
    {
        require(
            tokenAmount > 0,
            "getTokenExchangeAmount: tokenAmount too small"
        );

        return
            getExchangeAmount(
                tokenAmount,
                getTokenBalance(),
                address(this).balance
            );
    }

    /**
     * @notice Amount for ETH-to-Token or Token-to-ETH conversion.
     * @param sellAmount Amount of ETH or Tokens being sold.
     * @param sellReserve Amount of ETH or Tokens in reserves.
     * @param buyReserve Amount of Tokens or ETH in reserves.
     * @return Amount of ETH or Tokens.
     */
    function getExchangeAmount(
        uint256 sellAmount,
        uint256 sellReserve,
        uint256 buyReserve
    ) private pure returns (uint256) {
        require(
            sellReserve > 0 && buyReserve > 0,
            "getExchangePrice: invalid reserve amounts"
        );

        return (sellAmount * buyReserve) / (sellReserve + sellAmount);
    }
}

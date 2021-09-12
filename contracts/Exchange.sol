pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // TODO: remove?

import "./interfaces/IExchange.sol";
import "./interfaces/IFactory.sol";

contract Exchange is ERC20, IExchange {
    // using SafeMath for uint256; // TODO: use this for math?

    // Token for exchange with ETH
    IERC20 token;
    // Exchange manager for Token-to-Token exchanges.
    IFactory factory;

    constructor(address token_address) ERC20("Sandman Swap", "DREAM") {
        require(
            token_address != address(0),
            "constructor: invalid token address"
        );

        token = IERC20(token_address);
        factory = IFactory(msg.sender);
    }

    function ethToTokenExchange(uint256 desiredTokenAmount)
        public
        payable
        override
    {
        ethToTokenTransferHelper(desiredTokenAmount, msg.sender);
    }

    function tokenToEthExchange(uint256 tokenAmount, uint256 desiredEthAmount)
        public
        payable
        override
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

    function tokenToTokenExchange(
        uint256 tokenAmount,
        uint256 desiredOtherTokenAmount,
        address otherTokenAddress
    ) external payable override {
        require(
            tokenAmount > 0 && desiredOtherTokenAmount > 0,
            "tokenToTokenExchange: token amounts too small"
        );
        require(
            otherTokenAddress != address(0),
            "tokenToTokenExchange: invalid token2Address"
        );

        address otherTokenExchangeAddress = factory.getExchange(
            otherTokenAddress
        );

        require(
            otherTokenExchangeAddress != address(this) &&
                otherTokenExchangeAddress != address(0),
            "tokenToTokenExchange: token2Address is not an exchange"
        );

        uint256 ethAmount = getExchangeAmount(
            tokenAmount,
            getTokenBalance(),
            address(this).balance
        );

        token.transferFrom(msg.sender, address(this), tokenAmount);
        IExchange(otherTokenExchangeAddress).ethToTokenTransfer{
            value: ethAmount
        }(desiredOtherTokenAmount, msg.sender);
    }

    function ethToTokenTransfer(uint256 desiredTokenAmount, address recipient)
        external
        payable
        override
    {
        ethToTokenTransferHelper(desiredTokenAmount, recipient);
    }

    function addLiquidity(uint256 tokensDeposit)
        public
        payable
        override
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
        override
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

    /**
     * @notice Echanges ETH for Tokens for recipient.
     * @param desiredTokenAmount Amount of tokens to exchange for.
     * @param recipient Address of recipient.
     */
    function ethToTokenTransferHelper(
        uint256 desiredTokenAmount,
        address recipient
    ) private {
        require(
            desiredTokenAmount > 0,
            "ethToTokenTransfer: desiredTokenAmount too small"
        );

        uint256 tokenAmount = getExchangeAmount(
            msg.value,
            address(this).balance - msg.value,
            getTokenBalance()
        );

        require(
            tokenAmount >= desiredTokenAmount,
            "ethToTokenExchange: not enough tokens"
        );

        token.transfer(recipient, tokenAmount);
    }

    /**
     * @notice Token reserves balance.
     * @return Token balance.
     */
    function getTokenBalance() private view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @notice Amount for ETH-to-Token or Token-to-ETH conversion (includes 0.03% fee).
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

        uint256 sellAmountWithFee = sellAmount * 997;
        uint256 numerator = (sellAmountWithFee * buyReserve);
        uint256 denominator = buyReserve * 1000 + sellAmountWithFee;

        return numerator / denominator;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // TODO: remove?

import "./interfaces/IExchange.sol";
import "./interfaces/IFactory.sol";

contract Exchange is ERC20, IExchange {
    // using SafeMath for uint256; // TODO: use this for math?

    // Events
    event LogAddLiquidity(
        address indexed sender, 
        uint256 indexed eth, 
        uint256 indexed tok);
    event LogRemoveLiquidity(
        address indexed sender, 
        uint256 indexed eth, 
        uint256 indexed tok);
    
    // Token for exchange with ETH
    address public token;
    // Exchange manager for Token-to-Token exchanges.
    address public factory;

    constructor(address token_address) ERC20("Sandman Swap", "DREAM") {
        require(
            token_address != address(0),
            "constructor: invalid token address"
        );

        token = token_address;
        factory = msg.sender;
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
            getTokenReserves(),
            getEthReserves()
        );

        require(
            ethAmount >= desiredEthAmount,
            "tokenToEthExchange: not enough eth"
        );

        payable(msg.sender).transfer(ethAmount);
        IERC20(token).transferFrom(msg.sender, address(this), tokenAmount);
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

        address otherTokenExchangeAddress = IFactory(factory).getExchange(
            otherTokenAddress
        );

        require(
            otherTokenExchangeAddress != address(this) &&
                otherTokenExchangeAddress != address(0),
            "tokenToTokenExchange: token2Address is not an exchange"
        );

        uint256 ethAmount = getExchangeAmount(
            tokenAmount,
            getTokenReserves(),
            getEthReserves()
        );

        IERC20(token).transferFrom(msg.sender, address(this), tokenAmount);
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

    function addLiquidity(uint256 tokenDeposit)
        public
        payable
        override
        returns (uint256)
    {
        require(
            tokenDeposit > 0 && msg.value > 0,
            "addLiquidity: deposit amount too small"
        );

        if (getTokenReserves() == 0) {
            IERC20(token).transferFrom(msg.sender, address(this), tokenDeposit);

            uint256 liquidity = getEthReserves();
            _mint(msg.sender, liquidity);

            emit LogAddLiquidity(msg.sender, msg.value, tokenDeposit);

            return liquidity;
        } else {
            uint256 ethReserves = getEthReserves() - msg.value;
            uint256 tokenReserves = getTokenReserves();
            uint256 tokenRatioAmount = (msg.value * tokenReserves) / ethReserves;

            require(
                tokenDeposit >= tokenRatioAmount,
                "addLiquidity: not enough liquidity"
            );

            IERC20(token).transferFrom(msg.sender, address(this), tokenDeposit);

            uint256 liquidity = (msg.value * totalSupply()) / ethReserves;
            _mint(msg.sender, liquidity);

            emit LogAddLiquidity(msg.sender, msg.value, tokenDeposit);

            return liquidity;
        }
    }

    function removeLiquidity(uint256 lpAmount)
        public
        override
        returns (uint256, uint256)
    {
        require(lpAmount > 0, "removeLiquidity: lpAmount too small");
        require(totalSupply() >= lpAmount, "removeLiquidity: not enough liquidity");

        uint256 ethWithdraw = (getEthReserves() * lpAmount) /
            totalSupply();
        uint256 tokensWithdraw = (getTokenReserves() * lpAmount) / totalSupply();

        _burn(msg.sender, lpAmount);

        payable(msg.sender).transfer(ethWithdraw);
        IERC20(token).transfer(msg.sender, tokensWithdraw);

        emit LogRemoveLiquidity(msg.sender, ethWithdraw, tokensWithdraw);

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
            getEthReserves() - msg.value,
            getTokenReserves()
        );

        require(
            tokenAmount >= desiredTokenAmount,
            "ethToTokenExchange: not enough tokens"
        );

        IERC20(token).transfer(recipient, tokenAmount);
    }

    function getTokenReserves() public view override returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @notice ETH reserves balance.
     * @return ETH balance.
     */
    function getEthReserves() private view returns (uint256) {
        return address(this).balance;
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

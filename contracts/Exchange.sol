// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IExchange.sol";
import "./interfaces/IFactory.sol";

contract Exchange is ERC20, IExchange {
    using SafeMath for uint256;

    // Events
    event LogAddLiquidity(
        address indexed sender,
        uint256 indexed eth,
        uint256 indexed tok
    );
    event LogRemoveLiquidity(
        address indexed sender,
        uint256 indexed eth,
        uint256 indexed tok
    );
    event TokenPurchase(
        address indexed buyer,
        uint256 indexed ethSold,
        uint256 indexed tokensBought
    );
    event EthPurchase(
        address indexed buyer,
        uint256 indexed tokensSold,
        uint256 indexed ethBought
    );

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
        ethToTokenTransfer(desiredTokenAmount, msg.sender);
    }

    function tokenToEthExchange(uint256 tokenAmount, uint256 desiredEthAmount)
        public
        payable
        override
    {
        tokenToEthTransfer(tokenAmount, desiredEthAmount, msg.sender);
    }

    function tokenToTokenExchange(
        uint256 tokenAmount,
        uint256 desiredOtherTokenAmount,
        address otherTokenAddress
    ) external payable override {
        tokenToTokenTransfer(
            tokenAmount,
            desiredOtherTokenAmount,
            otherTokenAddress,
            msg.sender
        );
    }

    function ethToTokenTransfer(uint256 desiredTokenAmount, address recipient)
        public
        payable
        override
    {
        require(
            desiredTokenAmount > 0,
            "ethToTokenTransfer: desiredTokenAmount too small"
        );

        uint256 tokenAmount = getExchangeAmount(
            msg.value,
            getEthReserves().sub(msg.value),
            getTokenReserves()
        );

        require(
            tokenAmount >= desiredTokenAmount,
            "ethToTokenExchange: not enough tokens"
        );

        IERC20(token).transfer(recipient, tokenAmount);

        emit TokenPurchase(recipient, tokenAmount, msg.value);
    }

    function tokenToEthTransfer(
        uint256 tokenAmount,
        uint256 desiredEthAmount,
        address recipient
    ) public payable override {
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

        payable(recipient).transfer(ethAmount);
        IERC20(token).transferFrom(msg.sender, address(this), tokenAmount);

        emit EthPurchase(recipient, tokenAmount, ethAmount);
    }

    function tokenToTokenTransfer(
        uint256 tokenAmount,
        uint256 desiredOtherTokenAmount,
        address otherTokenAddress,
        address recipient
    ) public payable override {
        require(
            tokenAmount > 0 && desiredOtherTokenAmount > 0,
            "tokenToTokenExchange: token amounts too small"
        );
        require(
            otherTokenAddress != address(0) && otherTokenAddress != token,
            "tokenToTokenExchange: invalid otherTokenAddress"
        );

        address otherTokenExchangeAddress = IFactory(factory).getExchange(
            otherTokenAddress
        );

        require(
            otherTokenExchangeAddress != address(0),
            "tokenToTokenExchange: otherTokenAddress does not have not an exchange"
        );

        uint256 ethAmount = getExchangeAmount(
            tokenAmount,
            getTokenReserves(),
            getEthReserves()
        );

        require(
            ethAmount > 0,
            "tokenToTokenExchange: intermediary eth amount too small"
        );

        IERC20(token).transferFrom(msg.sender, address(this), tokenAmount);

        IExchange(otherTokenExchangeAddress).ethToTokenTransfer{
            value: ethAmount
        }(desiredOtherTokenAmount, recipient);

        emit EthPurchase(msg.sender, tokenAmount, ethAmount);
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
            uint256 ethReserves = getEthReserves().sub(msg.value);
            uint256 tokenReserves = getTokenReserves();
            uint256 tokenRatioAmount = msg.value.mul(tokenReserves).div(
                ethReserves
            );

            require(
                tokenDeposit >= tokenRatioAmount,
                "addLiquidity: not enough liquidity"
            );

            IERC20(token).transferFrom(msg.sender, address(this), tokenDeposit);

            uint256 liquidity = msg.value.mul(totalSupply()).div(ethReserves);
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
        require(
            totalSupply() >= lpAmount,
            "removeLiquidity: not enough liquidity"
        );

        uint256 ethWithdraw = getEthReserves().mul(lpAmount).div(totalSupply());
        uint256 tokensWithdraw = getTokenReserves().mul(lpAmount).div(
            totalSupply()
        );

        _burn(msg.sender, lpAmount);

        payable(msg.sender).transfer(ethWithdraw);
        IERC20(token).transfer(msg.sender, tokensWithdraw);

        emit LogRemoveLiquidity(msg.sender, ethWithdraw, tokensWithdraw);

        return (ethWithdraw, tokensWithdraw);
    }

    function getTokenToEthExchangeRate(uint256 tokenAmount)
        public
        view
        override
        returns (uint256)
    {
        require(
            tokenAmount > 0,
            "getTokenToEthExchangeRate: tokenAmount too small"
        );

        return
            getExchangeAmount(
                tokenAmount,
                getTokenReserves(),
                getEthReserves()
            );
    }

    function getEthToTokenExchangeRate(uint256 ethAmount)
        public
        view
        override
        returns (uint256)
    {
        require(
            ethAmount > 0,
            "getEthToTokenExchangeRate: ethAmount too small"
        );

        return
            getExchangeAmount(ethAmount, getEthReserves(), getTokenReserves());
    }

    /**
     * @notice Token reserves balance.
     * @return Token balance.
     */
    function getTokenReserves() private view returns (uint256) {
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

        uint256 sellAmountWithFee = sellAmount.mul(997);
        uint256 numerator = sellAmountWithFee.mul(buyReserve);
        uint256 denominator = sellReserve.mul(1000).add(sellAmountWithFee);

        return numerator.div(denominator);
    }
}

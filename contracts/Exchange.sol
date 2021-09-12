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

    function addLiquidity(uint256 tokensDeposit)
        public
        payable
        returns (uint256)
    {
        require(
            tokensDeposit > 0 && msg.value > 0,
            "addLiquidity: invalid argument"
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
        require(lpAmount > 0, "removeLiquidity: invalid argument");

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
}

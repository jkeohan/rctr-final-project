// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/IFactory.sol";
import "./Exchange.sol";

contract Factory is IFactory {
    event LogCreateExchange(address indexed token, address indexed exchange);

    mapping(address => address) public tokenToExchange;

    function createExchange(address tokenAddress)
        public
        override
        returns (address)
    {
        require(
            tokenAddress != address(0),
            "createExchange: tokenAddress is invalid"
        );
        require(
            tokenToExchange[tokenAddress] == address(0),
            "createExchange: tokenAddress already has an exchange"
        );

        Exchange exchange = new Exchange(tokenAddress);
        tokenToExchange[tokenAddress] = address(exchange);

        emit LogCreateExchange(tokenAddress, address(exchange));

        return address(exchange);
    }

    function getExchange(address tokenAddress)
        public
        view
        override
        returns (address)
    {
        return tokenToExchange[tokenAddress];
    }
}

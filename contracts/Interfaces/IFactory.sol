// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IFactory {
    /**
     * @notice Creates a new ETH/Token exchange.
     * @param tokenAddress The address of the Token to be traded.
     * @return The address of the newly created exchange.
     */
    function createExchange(address tokenAddress) external returns (address);

    /**
     * @notice Gets exchange for the provided Token.
     * @param tokenAddress The address of the Token exchange being searched for.
     * @return The address of the exchange.
     */
    function getExchange(address tokenAddress) external view returns (address);
}

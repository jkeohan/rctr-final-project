// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IExchange {
    /**
     * @notice Exchange ETH for Tokens (transferred to buyer).
     * @param desiredTokenAmount Amount of tokens to exchange for.
     */
    function ethToTokenExchange(uint256 desiredTokenAmount) external payable;

    /**
     * @notice Exchange Tokens for ETH (transferred to buyer).
     * @param tokenAmount Amount of Tokens provided.
     * @param desiredEthAmount Amount of ETH to exchange for.
     */
    function tokenToEthExchange(uint256 tokenAmount, uint256 desiredEthAmount)
        external
        payable;

    /**
     * @notice Exchange Tokens for Tokens (transferred to buyer).
     * @param tokenAmount Amount of Token 1 provided.
     * @param desiredOtherTokenAmount Amount of Token 2 to exchange for.
     * @param otherTokenAddress Address of Token 2 contract.
     */
    function tokenToTokenExchange(
        uint256 tokenAmount,
        uint256 desiredOtherTokenAmount,
        address otherTokenAddress
    ) external payable;

    /**
     * @notice Exchange ETH for Tokens (transferred to recipient).
     * @param desiredTokenAmount Amount of tokens to exchange for.
     * @param recipient Address of recipient.
     */
    function ethToTokenTransfer(uint256 desiredTokenAmount, address recipient)
        external
        payable;

    /**
     * @notice Exchange Tokens for ETH (transferred to recipient).
     * @param tokenAmount Amount of Tokens provided.
     * @param desiredEthAmount Amount of ETH to exchange for.
     * @param recipient Address of recipient.
     */
    function tokenToEthTransfer(
        uint256 tokenAmount,
        uint256 desiredEthAmount,
        address recipient
    ) external payable;

    /**
     * @notice Exchange Tokens for Tokens (transferred to recipient).
     * @param tokenAmount Amount of Token 1 provided.
     * @param desiredOtherTokenAmount Amount of Token 2 to exchange for.
     * @param otherTokenAddress Address of Token 2 contract.
     * @param recipient Address of recipient.
     */
    function tokenToTokenTransfer(
        uint256 tokenAmount,
        uint256 desiredOtherTokenAmount,
        address otherTokenAddress,
        address recipient
    ) external payable;

    /**
     * @notice Deposit ETH & Tokens to mint DREAM (LP-tokens).
     * @param tokenDeposit Maximum amount of tokens to deposit.
     * @return Amount of DREAM minted.
     */
    function addLiquidity(uint256 tokenDeposit)
        external
        payable
        returns (uint256);

    /**
     * @notice Burn DREAM (LP-tokens) to withdraw ETH & Tokens.
     * @param lpAmount Amount of DREAM to burn.
     * @return Amount of ETH & Tokens withdrawn.
     */
    function removeLiquidity(uint256 lpAmount)
        external
        returns (uint256, uint256);

    /**
     * @notice ETH received for provided Tokens.
     * @param tokenAmount Amount of Tokens provided.
     * @return ETH received.
     */
    function getTokenToEthExchangeRate(uint256 tokenAmount)
        external
        view
        returns (uint256);

    /**
     * @notice Token received for provided ETH.
     * @param ethAmount Amount of ETH provided.
     * @return Tokens received.
     */
    function getEthToTokenExchangeRate(uint256 ethAmount)
        external
        view
        returns (uint256);
}

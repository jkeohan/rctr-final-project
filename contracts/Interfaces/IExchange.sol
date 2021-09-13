// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IExchange {
    /**
     * @notice Exchange ETH for Tokens.
     * @param desiredTokenAmount Amount of tokens to exchange for.
     */
    function ethToTokenExchange(uint256 desiredTokenAmount) external payable;

    /**
     * @notice Exchange Tokens for ETH.
     * @param tokenAmount Amount of Tokens provided.
     * @param desiredEthAmount Amount of ETH to exchange for.
     */
    function tokenToEthExchange(uint256 tokenAmount, uint256 desiredEthAmount)
        external
        payable;

    /**
     * @notice Exchange Tokens for ETH.
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
     * @notice Exchange ETH for Tokens.
     * @param desiredTokenAmount Amount of tokens to exchange for.
     * @param recipient Address of recipient.
     */
    function ethToTokenTransfer(uint256 desiredTokenAmount, address recipient)
        external
        payable;

    /**
     * @notice Deposit ETH & Tokens to mint DREAM (LP-tokens).
     * @param tokensDeposit Amount of tokens to deposit.
     * @return Amount of DREAM minted.
     */
    function addLiquidity(uint256 tokensDeposit)
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
     * @notice Token reserves balance.
     * @return Token balance.
     */
    function getTokenReserves() external view returns (uint256);
}

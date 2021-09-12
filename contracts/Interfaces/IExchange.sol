pragma solidity ^0.8.7;

interface IExchange {
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
     * @notice Exchange Token balance.
     * @return Token balance.
     */
    function getTokenBalance() external view returns (uint256);
}

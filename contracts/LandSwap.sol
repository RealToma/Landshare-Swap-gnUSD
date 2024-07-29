// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LandshareSwap is Ownable {
    IERC20 public gnUSD;
    IERC20 public LAND;
    uint256 public swapAmount; // fixed amount of gnUSD to swap

    event Swap(address indexed user, uint256 gnUSDAmount, uint256 LANDAmount);
    event SwapAmountUpdated(uint256 newSwapAmount);
    event TokenAddressesUpdated(address newGnUSD, address newLAND);

    constructor(address _gnUSD, address _LAND) {
        gnUSD = IERC20(_gnUSD);
        LAND = IERC20(_LAND);
        swapAmount = 0.1 * 10**18; // default swap amount of 0.1 gnUSD (in wei)
    }

    function swap() external {
        require(gnUSD.balanceOf(msg.sender) >= swapAmount, "Insufficient gnUSD balance");
        require(LAND.balanceOf(address(this)) >= swapAmount, "Insufficient LAND balance in contract");

        gnUSD.transferFrom(msg.sender, address(this), swapAmount);
        LAND.transfer(msg.sender, swapAmount);

        emit Swap(msg.sender, swapAmount, swapAmount);
    }

    function updateSwapAmount(uint256 newSwapAmount) external onlyOwner {
        require(newSwapAmount > 0, "Swap amount must be greater than 0");
        swapAmount = newSwapAmount;
        emit SwapAmountUpdated(newSwapAmount);
    }

    function updateTokenAddresses(address newGnUSD, address newLAND) external onlyOwner {
        gnUSD = IERC20(newGnUSD);
        LAND = IERC20(newLAND);
        emit TokenAddressesUpdated(newGnUSD, newLAND);
    }

    function withdrawTokens(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Insufficient token balance in contract");
        token.transfer(msg.sender, amount);
    }
}
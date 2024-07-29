// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WrappedSOH is ERC20, Ownable {
    event EventMinted(address indexed to, uint256 amount);
    event EventBurned(address indexed from, uint256 amount);

    address[] public whitelist;

    constructor() ERC20("Wrapped SOH", "WSOH") {
        _mint(msg.sender, 40000000 * 10 ** uint(decimals()));
    }

    function mint(address account, uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        _mint(account, amount);
        emit EventMinted(account, amount);
    }

    function burn(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        _burn(msg.sender, amount);
        emit EventBurned(msg.sender, amount);
    }

    function isWhitelisted(address account) public view returns (bool) {
        for (uint i = 0; i < whitelist.length; i++) {
            if (whitelist[i] == account) {
                return true;
            }
        }
        return false;
    }

    function addToWhitelist(address account) external onlyOwner {
        require(account != address(0), "Address cannot be zero");
        require(!isWhitelisted(account), "Address is already whitelisted");
        whitelist.push(account); // Add the address to the whitelist array
    }

    function removeFromWhitelist(address account) external onlyOwner {
        require(!isWhitelisted(account), "Address is not whitelisted");
        for (uint i = 0; i < whitelist.length; i++) {
            if (whitelist[i] == account) {
                whitelist[i] = whitelist[whitelist.length - 1];
                whitelist.pop();
                break;
            }
        }
    }

    function transOwnership(address newOwner) external onlyOwner {
        transferOwnership(newOwner);
    }
}

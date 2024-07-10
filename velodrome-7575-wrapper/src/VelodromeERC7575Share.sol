// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IERC7575Share} from "./interfaces/IERC7575.sol";

contract VelodromeERC7575Share is ERC20, IERC7575Share {
    mapping(address asset => address) public vault;
    mapping(address vault => bool) public isVault;
    address public immutable factory;

    constructor(string memory name, string memory symbol) ERC20(name, symbol, 18) {
        factory = msg.sender;
    }

    function updateVault(address _asset, address _vault) public {
        vault[_asset] = _vault;
        isVault[_vault] = true;
        emit VaultUpdate(_asset, _vault);
    }

    function mint(address to, uint256 amount) external {
        require(isVault[msg.sender], "UNAUTHORIZED");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(isVault[msg.sender], "UNAUTHORIZED");
        _burn(from, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == 0x01ffc9a7 // ERC165 Interface ID for ERC165
            || interfaceId == 0xf815c03d; // ERC7575 Interface ID for Share Token
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract Pilot is ERC20Burnable, Ownable {

    using SafeMath for uint256;
    uint256 public constant MAX_SUPPLY = 1 * 10**8 * 1e18;
    uint256 public constant MIN_SUPPLY = 5 * 10**7 * 1e18;

    bool public isInit = false;
    uint256 public lpBonusFee = 5;
    uint256 public marketFee = 3;
    uint256 public burnFee = 1;
    uint256 public fundFee = 1;

    address public lpBonusAddr;
    address public marketAddr;
    address public fundAddr;


    mapping (address => bool) private _isExcludedFromFee;


    constructor() public ERC20("Pilot", "Pilot") {}

    function initSupply(
        address _opAddr,
        address _airdropAddr,
        address _liquidityAddr,
        address _chairAddr,
        address _vendingMachineAddr,
        address _powerBankAddr,
        address _TreadmillAddr,
        address _maskAddr,
        address _otherToolAddr
) external onlyOwner {
        require(!isInit, "inited");
        isInit = true;
        _mint(_opAddr, MAX_SUPPLY.mul(20).div(100));
        _mint(_airdropAddr, MAX_SUPPLY.mul(10).div(100));
        _mint(_liquidityAddr, MAX_SUPPLY.mul(10).div(100));
        _mint(_chairAddr, MAX_SUPPLY.mul(10).div(100));
        _mint(_vendingMachineAddr, MAX_SUPPLY.mul(10).div(100));
        _mint(_powerBankAddr, MAX_SUPPLY.mul(10).div(100));
        _mint(_TreadmillAddr, MAX_SUPPLY.mul(5).div(100));
        _mint(_maskAddr, MAX_SUPPLY.mul(5).div(100));
        _mint(_otherToolAddr, MAX_SUPPLY.mul(20).div(100));
    }

    function setAddrs(address _lpBonusAddr, address _marketAddr, address _fundAddr) external onlyOwner {
        lpBonusAddr = _lpBonusAddr;
        marketAddr = _marketAddr;
        fundAddr = _fundAddr;
    }

    function setFees(uint _lpBonus, uint _market, uint _burn, uint _fund) external onlyOwner {
        require(_lpBonus.add(_market).add(_burn).add(_fund) == 10, "invalid fees");
        lpBonusFee = _lpBonus;
        marketFee = _market;
        burnFee = _burn;
        fundFee = _fund;
    }

    function setExcludeFromFee(address account, bool enable) external onlyOwner {
        _isExcludedFromFee[account] = enable;
    }

    function multiTransfer(address[] memory receivers, uint256[] memory amounts) external {
        for (uint256 i = 0; i < receivers.length; i++) {
            transfer(receivers[i], amounts[i]);
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override virtual {
        require(amount > 0, "Transfer amount must be greater than zero");
        if(!_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient]) {
            super._transfer(sender, lpBonusAddr, amount.mul(lpBonusFee).div(100));
            if(totalSupply() <= MIN_SUPPLY) {
                super._transfer(sender, marketAddr, amount.mul(marketFee.add(burnFee)).div(100));
            } else {
                super._transfer(sender, marketAddr, amount.mul(marketFee).div(100));
                uint burnAmount = amount.mul(burnFee).div(100);
                if(totalSupply().sub(burnAmount) < MIN_SUPPLY) {
                    burnAmount = totalSupply().sub(MIN_SUPPLY);
                }
                _burn(sender, burnAmount);
            }
            super._transfer(sender, fundAddr, amount.mul(fundFee).div(100));
            super._transfer(sender, recipient, amount.mul(90).div(100));
        } else {
            super._transfer(sender, recipient, amount);
        }

    }
}

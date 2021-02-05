// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.4;
pragma abicoder v2;

contract MockContract {
    constructor() public {
        setVal(0);
    }

    function main(uint256 _val) external {
        setVal(_val);
    }

    function getVal() external view returns (uint256 val_) {
        bytes32 position = keccak256("mock.contract.value");
        assembly {
            val_ := sload(position)
        }
    }

    function setVal(uint256 val_) internal {
        bytes32 position = keccak256("mock.contract.value");
        assembly {
            sstore(position, val_)
        }
    }
}

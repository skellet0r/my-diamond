// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.4;
pragma abicoder v2;

import {IDiamondCut} from "../interfaces/ERC2535/IDiamondCut.sol";
import {LibDiamond} from "./libraries/LibDiamond.sol";

contract Diamond {
    constructor(IDiamondCut.FacetCut[] memory _diamondCut) payable {
        LibDiamond.diamondCut(_diamondCut, address(0), new bytes(0));

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
        address facet = ds.selectorToFacetAddress[msg.sig];
        require(facet != address(0)); // dev: Function does not exist
        assembly {
            // copy the call data to memory[0:0+calldatasize()]
            calldatacopy(0, 0, calldatasize())
            // delegatecall to the contract forwarding the gas available
            // get the result indicator
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // copy the teturn data to memory[0:0+returndatasize()]
            returndatacopy(0, 0, returndatasize())
            // if failed revert with error msg returned
            // if success return the result
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }
}

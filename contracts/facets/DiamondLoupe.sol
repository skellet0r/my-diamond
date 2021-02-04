// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.4;
pragma abicoder v2;

import {IDiamondLoupe} from "../../interfaces/ERC2535/IDiamondLoupe.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

contract DiamondLoupe is IDiamondLoupe {
    function facetFunctionSelectors(address _facet)
        external
        view
        override
        returns (bytes4[] memory facetFunctionSelectors_)
    {
        // load the diamond storage
        LibDiamond.DiamondStorage ds = LibDiamond.diamondStorage();
        // require _facet address is in the array of diamond facets
        require(ds.facets.contains(_facet)); // dev: Invalid facet address

        // get the known function selectors for facet_
        selectors = ds.facetAddressToFunctionSelectors[facet_];
        // initialize return array to be the same size as our array of selectors
        facetFunctionSelectors_ = new bytes4[](selectors.length());
        // for loop which assigns each selector into the return array
        for (
            uint256 selectorIndex;
            selectorIndex < selectors.length();
            selectorIndex++
        ) {
            facetFunctionSelectors_[selectorIndex] = ds.bytes32ToBytes4(
                selectors[selectorIndex]
            );
        }
    }
}

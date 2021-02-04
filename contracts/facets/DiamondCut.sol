// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.4;
pragma abicoder v2;

import {IDiamondCut} from "../../interfaces/ERC2535/IDiamondCut.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

contract DiamondCut is IDiamondCut {
    function diamondCut(
        IDiamondCut.FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        // loop through all the cuts
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            // what action is being performed
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                // add the functions
                LibDiamond.addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                // do something
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                // do something
            } else {
                // revert because the wrong action was given
                revert(); // dev: Incorrect FacetCutAction
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        // initialize the diamond
    }
}

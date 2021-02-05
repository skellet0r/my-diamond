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
        // Add/Replace/Remove functions
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }
}

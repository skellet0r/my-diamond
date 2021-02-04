// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.4;
pragma abicoder v2;

/// @title IDiamondCut Interface
/// @notice Used to add/replace/remove any number of functions from/to a diamond in a single transaction.
/// @dev Implementation of this interface should be its own facet.
interface IDiamondCut {
    // Add=0, Replace=1, Remove=2
    enum FacetCutAction {Add, Replace, Remove}

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }
    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    /** @notice Add/replace/remove any number of functions and optionally execute
        a function with delegatecall
        @param _diamondCut Contains the facet addresses and function selectors
        @param _init The address of the contract or facet to execute _calldata
        @param _calldata A function call, including function selector and arguments
        _calldata is executed with delegatecall on _init
    */
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;
}

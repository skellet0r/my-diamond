// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.4;
pragma abicoder v2;

import {EnumerableSet} from "openzeppelin/contracts/utils/EnumerableSet.sol";

/// @title Storage library related to the Diamond Standard implementation
/// @author Edward Amor
library LibDiamond {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        // Useful for getting all the function selectors at an address
        mapping(address => EnumerableSet.Bytes32Set) facetAddressToFunctionSelectors;
        // Query the address for which function selector is available
        mapping(bytes4 => address) selectorToFacetAddress;
        // All the available facets' addresses
        EnumerableSet.AddressSet facets;
    }

    /// @dev Retrieve the diamond storage
    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

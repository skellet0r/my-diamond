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

    /// @dev convert a bytes32 value to a bytes4
    function bytes32ToBytes4(bytes32 _value)
        internal
        pure
        returns (bytes4 value_)
    {
        value_ = bytes4(_value);
    }

    /// @dev Useful for converting the enumerableset.bytes32 to bytes4 array
    function selectorsBytes32ToBytes4Array(
        EnumerableSet.Bytes32Set storage _selectors
    ) internal view returns (bytes4[] memory selectors_) {
        // initialize return array to be the same size as our array of selectors
        selectors_ = new bytes4[](_selectors.length());
        // for loop which assigns each selector into the return array
        for (
            uint256 selectorIndex;
            selectorIndex < _selectors.length();
            selectorIndex++
        ) {
            selectors_[selectorIndex] = bytes32ToBytes4(
                _selectors.at(selectorIndex)
            );
        }
    }

    /// @dev Add a collection of functions to diamond
    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        // need functions to add
        require(_functionSelectors.length > 0); // dev: No selectors in facet to cut
        // get the storage
        DiamondStorage storage ds = diamondStorage();
        // facet address can't be zero address
        require(_facetAddress != address(0)); // dev: Add facet can't be address(0)
        // verify the contract has code to execute
        enforceHasContractCode(_facetAddress);
        // loop through each selector
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            // get the current iterations function selector
            bytes4 selector = _functionSelectors[selectorIndex];
            // check what the selectors facet address is
            address oldFacetAddress = ds.selectorToFacetAddress[selector];
            // verify there is no previous facet contract
            require(oldFacetAddress == address(0)); // dev: Can't add function that already exists
            // add the facet address and selector position in selector array for the selector
            ds.selectorToFacetAddress[selector] = _facetAddress;
            bool addSelector =
                ds.facetAddressToFunctionSelectors[_facetAddress].add(selector);
            require(addSelector); // dev: selector already present in facet
            ds.facets.add(_facetAddress);
        }
    }

    /// @dev Verify a contract has code
    function enforceHasContractCode(address _contract) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0); // dev: Add facet has no code
    }
}

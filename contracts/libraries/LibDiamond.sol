// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.4;
pragma abicoder v2;

import {EnumerableSet} from "openzeppelin/contracts/utils/EnumerableSet.sol";
import {IDiamondCut} from "../../interfaces/ERC2535/IDiamondCut.sol";

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

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

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

    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
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
                // Replace some functions
                LibDiamond.replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                // Remove some functions
                LibDiamond.removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                // revert because the wrong action was given
                revert(); // dev: Incorrect FacetCutAction
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        // initialize the diamond
        initializeDiamondCut(_init, _calldata);
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
                ds.facetAddressToFunctionSelectors[_facetAddress].add(
                    bytes32(selector)
                );
            require(addSelector); // dev: selector already present in facet
            ds.facets.add(_facetAddress);
        }
    }

    /// @dev Replace a function selector in a diamond
    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        // need functions to add
        require(_functionSelectors.length > 0); // dev: No selectors in facet to cut
        // get the storage
        DiamondStorage storage ds = diamondStorage();
        // facet address can't be zero address
        require(_facetAddress != address(0)); // dev: Replace facet can't be address(0)

        enforceHasContractCode(_facetAddress); // dev: Replace facet has no code
        // loop through each selector
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            // get the current selector
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAddress[selector];
            // can't replace immutable functions -- functions defined directly in the diamond
            require(oldFacetAddress != address(this)); // dev: Can't replace immutable function
            require(oldFacetAddress != _facetAddress); // dev: Can't replace function with same function
            require(oldFacetAddress != address(0)); // dev: Can't replace function that doesn't exist
            // replace old facet address
            ds.selectorToFacetAddress[selector] = _facetAddress;
            bool removeOld =
                ds.facetAddressToFunctionSelectors[oldFacetAddress].remove(
                    bytes32(selector)
                );
            require(removeOld); // dev: Failed to remove selector from old facet address
            bool addNew =
                ds.facetAddressToFunctionSelectors[_facetAddress].add(
                    bytes32(selector)
                );
            require(addNew); // dev: Failed to add selector to new facet address
            if (
                ds.facetAddressToFunctionSelectors[oldFacetAddress].length() ==
                0
            ) {
                ds.facets.remove(oldFacetAddress);
            }
        }
    }

    /// @dev Remove a collection of functions from diamond
    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        // need functions to add
        require(_functionSelectors.length > 0); // dev: No selectors in facet to cut
        // get the storage
        DiamondStorage storage ds = diamondStorage();
        // facet address can't be zero address
        require(_facetAddress != address(0)); // dev: Add facet can't be address(0)
        // loop through each selector we are removing
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            // get the current
            bytes4 selector = _functionSelectors[selectorIndex];

            address facetAddress = ds.selectorToFacetAddress[selector];
            require(facetAddress != address(0)); // dev: Can't remove function that doesn't exist
            // can't remove immutable functions -- functions defined directly in the diamond
            require(facetAddress != address(this)); // dev: Can't remove immutable function
            // delete the selector
            bool removeSelector =
                ds.facetAddressToFunctionSelectors[facetAddress].remove(
                    bytes32(selector)
                );
            require(removeSelector); // dev: failed to remove selector
            // if there are no more selectors for a facet, remove the facet
            if (
                ds.facetAddressToFunctionSelectors[facetAddress].length() == 0
            ) {
                ds.facets.remove(facetAddress);
            }
            delete ds.selectorToFacetAddress[selector];
        }
    }

    /// @dev Initialize the diamond cut
    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(_calldata.length == 0); // dev: _init is address(0) but_calldata is not empty
        } else {
            // if we are calling an address then our calldata > 0
            require(_calldata.length > 0); // dev: _calldata is empty but _init is not address(0)
            // if the address we are calling is not this contract verify it has code
            if (_init != address(this)) {
                enforceHasContractCode(_init); // dev: _init address has no code
            }
            // issue a delegate call to the contract
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            // if it isn't successful
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error if one is given
                    revert(string(error));
                } else {
                    // if no revert message give our own
                    revert("LibDiamondCut: _init function reverted");
                }
            }
            // if the delegatecall is successful then finish
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

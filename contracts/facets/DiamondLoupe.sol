// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.4;
pragma abicoder v2;

import {IDiamondLoupe} from "../../interfaces/ERC2535/IDiamondLoupe.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {EnumerableSet} from "openzeppelin/contracts/utils/EnumerableSet.sol";

contract DiamondLoupe is IDiamondLoupe {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    function facets()
        external
        view
        override
        returns (IDiamondLoupe.Facet[] memory facets_)
    {
        // load the diamond storage
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        // get the diamond facets
        EnumerableSet.AddressSet storage _facets = ds.facets;
        // initialize size of the return
        facets_ = new IDiamondLoupe.Facet[](_facets.length());
        for (uint256 facetIndex; facetIndex < _facets.length(); facetIndex++) {
            // assign the facet to the index
            facets_[facetIndex] = IDiamondLoupe.Facet({
                facetAddress: _facets.at(facetIndex),
                functionSelectors: LibDiamond.selectorsBytes32ToBytes4Array(
                    ds.facetAddressToFunctionSelectors[_facets.at(facetIndex)]
                )
            });
        }
    }

    function facetFunctionSelectors(address _facet)
        external
        view
        override
        returns (bytes4[] memory facetFunctionSelectors_)
    {
        // load the diamond storage
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        // require _facet address is in the array of diamond facets
        require(ds.facets.contains(_facet)); // dev: Invalid facet address

        // get the known function selectors for _facet
        EnumerableSet.Bytes32Set storage selectors =
            ds.facetAddressToFunctionSelectors[_facet];
        // use library function to quickly make the return array
        facetFunctionSelectors_ = LibDiamond.selectorsBytes32ToBytes4Array(
            selectors
        );
    }

    function facetAddresses()
        external
        view
        override
        returns (address[] memory facetAddresses_)
    {
        // load the diamond storage
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        // the enumerable set of facets
        EnumerableSet.AddressSet storage _facets = ds.facets;
        // initialize size of the return array
        facetAddresses_ = new address[](ds.facets.length());
        for (uint256 facetIndex; facetIndex < _facets.length(); facetIndex++) {
            // assign the facet to the index
            facetAddresses_[facetIndex] = _facets.at(facetIndex);
        }
    }

    function facetAddress(bytes4 _functionSelector)
        external
        view
        override
        returns (address facetAddress_)
    {
        // load the diamond storage
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddress_ = ds.selectorToFacetAddress[_functionSelector];
    }
}

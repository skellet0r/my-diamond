"""Test the implementation of the Diamond Loupe interface.

The interface will be implemented as its own facet, however
it will be interacted with through the Diamond contract.
"""
import brownie


def test_retrieve_all_facets_and_facet_selectors(
    loupe, diamondcut, diamondloupe, DiamondCut, DiamondLoupe
):
    result = loupe.facets()
    addresses, sigs_ = list(zip(*result))
    signatures = {str(sig) for sigs in sigs_ for sig in sigs}

    assert set([diamondcut.address, diamondloupe.address]) <= set(addresses)
    assert set(DiamondCut.signatures.values()) <= signatures
    assert set(DiamondLoupe.signatures.values()) <= signatures


def test_retrieve_all_selectors_for_a_facet(
    adam, loupe, DiamondCut, diamondcut,
):
    result = loupe.facetFunctionSelectors(diamondcut.address)

    assert {str(s) for s in result} == set(DiamondCut.signatures.values())


def test_retrieve_all_selectors_for_facet_fails_for_unsupported_facet(
    adam, loupe, zero_address
):
    # can't debut with revert comments
    with brownie.reverts():
        loupe.facetFunctionSelectors(zero_address)


def test_retrieve_all_facet_addresses(adam, loupe, diamondcut, diamondloupe):
    result = loupe.facetAddresses()

    assert set([diamondcut.address, diamondloupe.address]) <= set(result)


def test_retrieve_facet_which_supports_selector(
    adam, loupe, DiamondLoupe, diamondloupe
):
    result = loupe.facetAddress(DiamondLoupe.signatures["facetAddresses"])

    assert result == diamondloupe.address


def test_retrieve_facet_fails_for_unsupported_selector(adam, loupe):
    with brownie.reverts():
        loupe.facetAddress("0x00000000")

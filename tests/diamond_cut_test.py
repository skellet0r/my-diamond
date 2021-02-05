"""Test the implementation of the Diamond Cut interface.

The interface will be implemented as its own facet, however
it will be interacted with through the Diamond contract.
"""
import pytest
import brownie
from brownie.convert import to_bytes


@pytest.fixture(scope="module")
def mock_contract(adam, MockContract):
    return adam.deploy(MockContract)


def test_diamond_cut_emits_DiamondCut_event(
    adam, zero_address, cut, mock_contract, MockContract
):
    data = [[mock_contract.address, 0, list(MockContract.signatures.values())]]
    tx = cut.diamondCut(data, zero_address, to_bytes(0), {"from": adam},)

    # debugging abilities are reduced due to using Contract.from_abi
    assert len(tx.events) == 1


def test_retrieve_all_facets_is_updated_with_new_facets(
    adam, zero_address, loupe, cut, mock_contract, MockContract
):
    before = loupe.facetAddresses()

    data = [[mock_contract.address, 0, list(MockContract.signatures.values())]]
    cut.diamondCut(
        data, zero_address, to_bytes(0), {"from": adam},
    )

    after = loupe.facetAddresses()

    assert mock_contract.address not in before
    assert mock_contract.address in after


def test_retrieve_all_facets_is_updated_with_new_selectors(
    adam, zero_address, cut, loupe, mock_contract, MockContract
):
    before = loupe.facets()

    data = [[mock_contract.address, 0, list(MockContract.signatures.values())]]
    cut.diamondCut(
        data, zero_address, to_bytes(0), {"from": adam},
    )

    after = loupe.facets()
    addresses, sigs_ = list(zip(*after))
    signatures = {str(sig) for sigs in sigs_ for sig in sigs}

    assert before != after
    assert mock_contract.address in addresses
    assert set(MockContract.signatures.values()) <= signatures


def test_diamond_delegates_call_with_calldata_to_init(
    adam, zero_address, cut, loupe, mock_contract, MockContract
):

    before = mock_contract.getVal()  # this will be 0

    data = [[mock_contract.address, 0, list(MockContract.signatures.values())]]
    cut.diamondCut(
        data, zero_address, to_bytes(0), {"from": adam},
    )

    after = mock_contract.getVal()  # this should be 100

    assert before == 0
    assert after == 100


def test_no_delegatecall_when_init_is_zero_address_and_no_calldata(
    adam, zero_address, cut, loupe, mock_contract, MockContract
):

    before = mock_contract.getVal()  # this will be 0

    data = [[mock_contract.address, 0, list(MockContract.signatures.values())]]
    cut.diamondCut(
        data, zero_address, to_bytes(0), {"from": adam},
    )

    after = mock_contract.getVal()  # this should still be 0

    assert before == after


def test_diamond_cut_fails_when_given_calldata_but_no_init(
    adam, zero_address, cut, mock_contract, MockContract
):

    with brownie.reverts("dev: _init is address(0) but_calldata is not empty"):
        data = [[mock_contract.address, 0, list(MockContract.signatures.values())]]
        cut.diamondCut(
            data, zero_address, to_bytes(0), {"from": adam},
        )


def test_diamond_cut_fails_when_given_init_but_no_calldata(
    adam, zero_address, cut, mock_contract, MockContract
):

    with brownie.reverts("dev: _calldata is empty but _init is not address(0)"):
        data = [[mock_contract.address, 0, list(MockContract.signatures.values())]]
        cut.diamondCut(
            data, zero_address, to_bytes(0), {"from": adam},
        )

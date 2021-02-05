"""Test the implementation of the Diamond Cut interface.

The interface will be implemented as its own facet, however
it will be interacted with through the Diamond contract.
"""
import pytest
import brownie
from brownie import Contract
from brownie.convert import to_bytes


@pytest.fixture(scope="module")
def mock_contract(adam, MockContract):
    return adam.deploy(MockContract)


@pytest.fixture(scope="module")
def diamondmock(adam, MockContract, diamond):
    return Contract.from_abi("Mock Diamond", diamond.address, MockContract.abi)


def test_diamond_cut_emits_DiamondCut_event(
    adam, zero_address, cut, mock_contract, MockContract
):
    _calldata = mock_contract.main.encode_input(100)
    data = [[mock_contract.address, 0, list(MockContract.signatures.values())]]
    tx = cut.diamondCut(data, mock_contract.address, _calldata, {"from": adam})

    # debugging abilities are reduced due to using Contract.from_abi
    assert len(tx.events) == 1


def test_retrieve_all_facets_is_updated_with_new_facets(
    adam, zero_address, loupe, cut, mock_contract, MockContract
):
    before = loupe.facetAddresses()

    _calldata = mock_contract.main.encode_input(100)
    data = [[mock_contract.address, 0, list(MockContract.signatures.values())]]
    cut.diamondCut(data, mock_contract.address, _calldata, {"from": adam})

    after = loupe.facetAddresses()

    assert mock_contract.address not in before
    assert mock_contract.address in after


def test_retrieve_all_facets_is_updated_with_new_selectors(
    adam, zero_address, cut, loupe, mock_contract, MockContract
):
    before = loupe.facets()

    _calldata = mock_contract.main.encode_input(100)
    data = [[mock_contract.address, 0, list(MockContract.signatures.values())]]
    cut.diamondCut(data, mock_contract.address, _calldata, {"from": adam})

    after = loupe.facets()
    addresses, sigs_ = list(zip(*after))
    signatures = {str(sig) for sigs in sigs_ for sig in sigs}

    assert before != after
    assert mock_contract.address in addresses
    assert set(MockContract.signatures.values()) <= signatures


def test_diamond_delegates_call_with_calldata_to_init(
    adam, zero_address, cut, loupe, mock_contract, MockContract, diamondmock
):

    before = mock_contract.getVal()  # this will be 0

    _calldata = mock_contract.main.encode_input(100)
    data = [[mock_contract.address, 0, list(MockContract.signatures.values())]]
    cut.diamondCut(data, mock_contract.address, _calldata, {"from": adam})

    after = diamondmock.getVal()  # this should be 100

    assert before == 0
    assert after == 100


@pytest.mark.skip(reason="Can't properly send calldata for some reason")
def test_no_delegatecall_when_init_is_zero_address_and_no_calldata(
    adam, zero_address, cut, loupe, mock_contract, MockContract, diamondmock
):

    data = [[mock_contract.address, 0, list(MockContract.signatures.values())]]
    _calldata = cut.diamondCut.encode_input(data, zero_address, to_bytes("0x", "bytes"))
    # cut.diamondCut({"from": adam}, data=_calldata)
    adam.transfer(cut, 0, data=_calldata)

    after = diamondmock.getVal()  # this should still be 0

    assert after == 0


def test_diamond_cut_fails_when_given_calldata_but_no_init(
    adam, zero_address, cut, mock_contract, MockContract
):

    with brownie.reverts("_init is address(0) but_calldata is not empty"):
        _calldata = mock_contract.main.encode_input(100)
        data = [[mock_contract.address, 0, list(MockContract.signatures.values())]]
        cut.diamondCut(data, zero_address, _calldata, {"from": adam})


@pytest.mark.skip(reason="Can't properly send calldata for some reason")
def test_diamond_cut_fails_when_given_init_but_no_calldata(
    adam, zero_address, cut, mock_contract, MockContract
):

    with brownie.reverts("dev: _calldata is empty but _init is not address(0)"):
        data = [[mock_contract.address, 0, list(MockContract.signatures.values())]]
        cut.diamondCut(
            data, mock_contract.address, to_bytes(0), {"from": adam},
        )

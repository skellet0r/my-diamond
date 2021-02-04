import brownie
from brownie.network.contract import ProjectContract, ContractContainer
from brownie.convert import to_address, to_bytes
import pytest


class FacetCutAction:

    Add = 0
    Replace = 1
    Remove = 2


@pytest.fixture(scope="module")
def diamondcut(adam, DiamondCut: ContractContainer) -> ProjectContract:
    return adam.deploy(DiamondCut)


@pytest.fixture(scope="module")
def diamondloupe(adam, DiamondLoupe: ContractContainer) -> ProjectContract:
    return adam.deploy(DiamondLoupe)


@pytest.fixture(scope="module")
def diamond(
    adam,
    Diamond: ContractContainer,
    DiamondCut: ContractContainer,
    diamondcut,
    DiamondLoupe: ContractContainer,
    diamondloupe,
) -> ProjectContract:
    facetcuts = [
        [diamondcut.address, FacetCutAction.Add, list(DiamondCut.signatures.values())],
        [
            diamondloupe.address,
            FacetCutAction.Add,
            list(DiamondLoupe.signatures.values()),
        ],
    ]

    ZERO_ADDRESS = to_address("0x0000000000000000000000000000000000000000")
    return adam.deploy(Diamond, facetcuts, ZERO_ADDRESS, to_bytes(0))


class TestDiamondLoupeImplementation:
    """Test the implementation of the Diamond Loupe interface.

    The interface will be implemented as its own facet, however
    it will be interacted with through the Diamond contract.
    """

    def test_retrieve_all_facets_and_facet_selectors(
        adam,
        diamond,
        DiamondCut: ContractContainer,
        diamondcut,
        DiamondLoupe: ContractContainer,
        diamondloupe,
    ):
        result = diamond.facets({"from": adam})

        assert result == [
            (diamondcut.address, list(DiamondCut.signatures.values())),
            (diamondloupe.address, list(DiamondLoupe.signatures.values())),
        ]

    def test_retrieve_all_selectors_for_a_facet(
        adam, diamond, DiamondCut: ContractContainer, diamondcut,
    ):
        result = diamond.facetFunctionSelectors(diamondcut.address, {"from": adam})

        assert result == list(DiamondCut.signatures.values())

    def test_retrieve_all_selectors_for_facet_fails_for_unsupported_facet(
        adam, diamond
    ):
        with brownie.reverts("dev: Invalid facet address"):
            diamond.facetFunctionSelectors(
                to_address("0xb908672C524d3799688FC522346CdFAb12e1198e")
            )

    def test_retrieve_all_facet_addresses(adam, diamond, diamondcut, diamondloupe):
        result = diamond.facetAddresses()

        assert result == [diamondcut.address, diamondloupe.address]

    def test_retrieve_facet_which_supports_selector(
        adam, diamond, DiamondLoupe: ContractContainer, diamondloupe
    ):
        result = diamond.facetAddress(
            to_bytes(DiamondLoupe.signatures["facetAddresses"], "bytes4")
        )

        assert result == diamondloupe.address

    def test_retrieve_facet_fails_for_unsupported_selector(adam, diamond):
        with brownie.reverts("dev: Unsupported selector"):
            diamond.facetAddress(to_bytes("0xdd62ed3e", "bytes4"))


class TestDiamondCutImplementation:
    """Test the implementation of the Diamond Cut interface.

    The interface will be implemented as its own facet, however
    it will be interacted with through the Diamond contract.
    """

    def test_diamond_cut_emits_DiamondCut_event(
        adam, diamond, MockContract: ContractContainer
    ):
        mock = adam.deploy(MockContract)
        tx = diamond.diamondCut(
            [[mock.address, 0, list(MockContract.signatures.values())]],
            to_address("0x0000000000000000000000000000000000000000"),
            to_bytes(0),
        )

        assert "DiamondCut" in tx.events

    def test_retrieve_all_facets_is_updated_with_new_facets(
        adam, diamond, MockContract: ContractContainer
    ):
        before = diamond.facetAddresses()

        mock = adam.deploy(MockContract)
        diamond.diamondCut(
            [[mock.address, 0, list(MockContract.signatures.values())]],
            to_address("0x0000000000000000000000000000000000000000"),
            to_bytes(0),
        )

        after = diamond.facetAddresses()

        assert mock.address not in before
        assert mock.address in after

    def test_retrieve_all_facets_is_updated_with_new_selectors(
        adam, diamond, MockContract: ContractContainer
    ):
        before = diamond.facets()

        mock = adam.deploy(MockContract)
        diamond.diamondCut(
            [[mock.address, 0, list(MockContract.signatures.values())]],
            to_address("0x0000000000000000000000000000000000000000"),
            to_bytes(0),
        )

        after = diamond.facets()
        after_selectors = [selector for facet in after for selector in facet[1]]

        assert before != after
        assert MockContract.signatures["main"] in after_selectors

    def test_diamond_delegates_call_with_calldata_to_init(
        adam, diamond, MockContract: ContractContainer
    ):

        mock = adam.deploy(MockContract)

        before = mock.getVal()  # this will be 0

        diamond.diamondCut(
            [[mock.address, 0, list(MockContract.signatures.values())]],
            mock.address,
            MockContract.signatures["main"],
        )

        after = mock.getVal()  # this should be 100

        assert before == 0
        assert after == 100

    def test_no_delegatecall_when_init_is_zero_address_and_no_calldata(
        adam, diamond, MockContract: ContractContainer
    ):

        mock = adam.deploy(MockContract)

        before = mock.getVal()  # this will be 0

        diamond.diamondCut(
            [[mock.address, 0, list(MockContract.signatures.values())]],
            to_address("0x0000000000000000000000000000000000000000"),
            to_bytes(0),
        )

        after = mock.getVal()  # this should still be 0

        assert before == after

    def test_diamond_cut_fails_when_given_calldata_but_no_init(
        adam, diamond, MockContract: ContractContainer
    ):

        mock = adam.deploy(MockContract)

        with brownie.reverts("dev: _init is address(0) but_calldata is not empty"):
            diamond.diamondCut(
                [[mock.address, 0, list(MockContract.signatures.values())]],
                to_address("0x0000000000000000000000000000000000000000"),
                MockContract.signatures["main"],
            )

    def test_diamond_cut_fails_when_given_init_but_no_calldata(
        adam, diamond, MockContract: ContractContainer
    ):

        mock = adam.deploy(MockContract)

        with brownie.reverts("dev: _calldata is empty but _init is not address(0)"):
            diamond.diamondCut(
                [[mock.address, 0, list(MockContract.signatures.values())]],
                mock.address,
                to_bytes(0),
            )

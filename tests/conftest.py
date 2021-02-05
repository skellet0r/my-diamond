import pytest
from brownie import Contract
from brownie.convert import to_address


class FacetCutAction:

    Add = 0
    Replace = 1
    Remove = 2


@pytest.fixture(scope="module")
def adam(accounts):
    """Get the first available account."""
    return accounts[0]


@pytest.fixture(scope="module")
def barry(accounts):
    """Get the second available account."""
    return accounts[1]


@pytest.fixture(scope="module")
def charlie(accounts):
    """Get the third available account."""
    return accounts[2]


@pytest.fixture(scope="module")
def zero_address():
    return to_address("0x0000000000000000000000000000000000000000")


@pytest.fixture(scope="module")
def diamondcut(adam, DiamondCut):
    """Deploy the DiamondCut contract."""
    return adam.deploy(DiamondCut)


@pytest.fixture(scope="module")
def diamondloupe(adam, DiamondLoupe):
    """Deploy the DiamondLoupe contract."""
    return adam.deploy(DiamondLoupe)


@pytest.fixture(scope="module")
def diamond(adam, diamondcut, diamondloupe, Diamond, DiamondCut, DiamondLoupe):
    """Deploy the Diamond contract, and initialize with DiamondCut and DiamondLoupe."""
    facet_cuts = [
        (diamondcut.address, FacetCutAction.Add, list(DiamondCut.signatures.values())),
        (
            diamondloupe.address,
            FacetCutAction.Add,
            list(DiamondLoupe.signatures.values()),
        ),
    ]
    return adam.deploy(Diamond, facet_cuts)


@pytest.fixture(scope="module")
def cut(diamond, DiamondCut):
    """Diamond contract with cut functions available."""
    return Contract.from_abi("Diamond Cut", diamond.address, DiamondCut.abi)


@pytest.fixture(scope="module")
def loupe(diamond, DiamondLoupe):
    """Diamond contract with loupe functions available."""
    return Contract.from_abi("Diamond Loupe", diamond.address, DiamondLoupe.abi)


@pytest.fixture(scope="module")
def facet_cut_actions():
    return FacetCutAction


@pytest.fixture(autouse=True)
def isolate(fn_isolation):
    """Isolate each function"""
    pass

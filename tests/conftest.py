import pytest


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


@pytest.fixture(autouse=True)
def isolate(fn_isolation):
    """Isolate each function"""
    pass

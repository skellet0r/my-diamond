# Python Dev Dapp Template

A template for building dapps with `eth-brownie` and `reactjs`.

## Getting Started

There are a couple of things you'll need to edit once you've created your repository using this template:

- [ ] Change environment name in `environment.yml`
- [ ] Change project name in `package.json`
- [ ] Change header in this `README.md`

To initialize your environment you'll need to have the following dependencies pre-installed:

- [ ] `conda` - package manager
- [ ] `npm` - package manager

> Note: This project uses python for smart contract development, but reactjs and nodejs for front-end development.

Follow the steps below to complete the environment initialization:

```bash
$ conda env create -f environment.yml  # install smart contract dependencies in new venv
$ conda activate [insert-env-name]  # env name is the name you entered in environment.yml
$ npm ci  # clean slate install of front-end project dependencies
```

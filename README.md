# Token Conversion 💱

Contract implements the terms of the [FDT](https://etherscan.io/token/0xed1480d12be41d92f36f5f7bdd88212e381a3677) -> [BOND](https://etherscan.io/token/0x0391D2021f89DC339F60Fff84546EA23E337750f) conversion as outlined [here](https://forum.barnbridge.com/t/combine-fiat-dao-into-barnbridge/807) and ratified in a BarnBridge governance vote. 

## Warning ⚠️

This contract is only safe to use for converting [FDT](https://etherscan.io/token/0xed1480d12be41d92f36f5f7bdd88212e381a3677) to [BOND](https://etherscan.io/token/0x0391D2021f89DC339F60Fff84546EA23E337750f) tokens. Using this contract with other tokens may result in the loss of funds.

## Installation
This repository uses Foundry for building and testing and Solhint for formatting the contracts.
If you do not have Foundry already installed, you'll need to run the commands below.

### Install Foundry
```sh
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Set .env
Copy and update contents from `.env.example` to `.env`

## Tests

After installing dependencies with `make`, run `make test` to run the tests.

Note that tests run on forked mainnet state so make sure the RPC endpoint is properly configured in the `.env` file.

## Building and testing

```sh
git clone https://github.com/ultrasound-labs/token-conversion.git
cd token-conversion
make # This installs the project's dependencies.
make test # This runs forked mainnet tests.
```

## Deployment

After building and testing you can deploy the contract with the following command

```sh
make deploy
```

This runs the `./scripts/deploy.sh` script. Make sure to define your environment variables in the `.env` file first.
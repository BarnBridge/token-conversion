# Token Conversion 💱

Contract implements the terms of the FDT -> BOND conversion as outlined [here](https://forum.barnbridge.com/t/combine-fiat-dao-into-barnbridge/807) and ratified in a BarnBridge governance vote. 

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

## Changes

Listed in the [CHANGELOG.md](./CHANGELOG.md) file which follows the https://keepachangelog.com/en/1.0.0/ format. 

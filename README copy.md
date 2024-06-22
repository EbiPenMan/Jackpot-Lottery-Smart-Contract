# Jackpot Lottery Smart Contract

[![Solidity](https://img.shields.io/badge/Solidity-0.8.26-orange.svg)](https://soliditylang.org/)
[![Contributions Welcome](https://img.shields.io/badge/Contributions-Welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Foundry][foundry-badge]][foundry] 
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE.md)



[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg


## Introduction

The Jackpot Lottery Smart Contract is a decentralized lottery system built on the Ethereum blockchain. Participants can buy tickets, and draws are executed at regular intervals. Winners are determined based on matching numbers, and prizes are distributed accordingly.

## Features

- Buy tickets with custom numbers
- Weekly draws with random number generation
- Prize distribution based on matching numbers
- Owner fee collection and withdrawal
- View draw results and prizes
- Secure and transparent using Solidity and smart contracts

## Getting Started


### Foundry Template
We used [` this `](https://github.com/PaulRBerg/foundry-template) Foundry-based template for developing Solidity smart contracts, with sensible defaults. if you have any questions refer to it.

### What's Inside

- [Forge](https://github.com/foundry-rs/foundry/blob/master/forge): compile, test, fuzz, format, and deploy smart
  contracts
- [Forge Std](https://github.com/foundry-rs/forge-std): collection of helpful contracts and utilities for testing
- [Prettier](https://github.com/prettier/prettier): code formatter for non-Solidity files
- [Solhint](https://github.com/protofire/solhint): linter for Solidity code

### Installation
To deploy and interact with this smart contract, follow these steps:

1. Clone the repository:
   ```sh
   git clone https://github.com/EbiPenMan/Jackpot-Lottery-Smart-Contract.git
   cd jackpot-lottery-smart-contract
   ```

2. Install dependencies:
   ```sh
    bun install # install Solhint, Prettier, and other Node.js deps
   ```


If this is your first time with Foundry, check out the
[installation](https://github.com/foundry-rs/foundry#installation) instructions.

### VSCode Integration

This template is IDE agnostic, but for the best user experience, you may want to use it in VSCode alongside Nomic
Foundation's [Solidity extension](https://marketplace.visualstudio.com/items?itemName=NomicFoundation.hardhat-solidity).

For guidance on how to integrate a Foundry project in VSCode, please refer to this
[guide](https://book.getfoundry.sh/config/vscode).

## Installing Dependencies

Foundry typically uses git submodules to manage dependencies, but this template uses Node.js packages because
[submodules don't scale](https://twitter.com/PaulRBerg/status/1736695487057531328).

This is how to install dependencies:

1. Install the dependency using your preferred package manager, e.g. `bun install dependency-name`
   - Use this syntax to install from GitHub: `bun install github:username/repo-name`
2. Add a remapping for the dependency in [remappings.txt](./remappings.txt), e.g.
   `dependency-name=node_modules/dependency-name`

Note that OpenZeppelin Contracts is pre-installed, so you can follow that as an example.

### Deployment

1. Compile the contract:
   ```sh
   forge compile
   ```

2. Deploy the contract to a local network:
   ```sh
   forge deploy
   ```

## Usage


### Build

Build the contracts:

```sh
$ forge build
```

### Clean

Delete the build artifacts and cache directories:

```sh
$ forge clean
```

### Compile

Compile the contracts:

```sh
$ forge build
```

### Coverage

Get a test coverage report:

```sh
$ forge coverage
```

### Deploy

Deploy to Anvil:

```sh
$ forge script script/Deploy.s.sol --broadcast --fork-url http://localhost:8545
```

For this script to work, you need to have a `MNEMONIC` environment variable set to a valid
[BIP39 mnemonic](https://iancoleman.io/bip39/).

For instructions on how to deploy to a testnet or mainnet, check out the
[Solidity Scripting](https://book.getfoundry.sh/tutorials/solidity-scripting.html) tutorial.

### Format

Format the contracts:

```sh
$ forge fmt
```

### Gas Usage

Get a gas report:

```sh
$ forge test --gas-report
```

### Lint

Lint the contracts:

```sh
$ bun run lint
```

### Test

Run the tests:

```sh
$ forge test
```

Generate test coverage and output result to the terminal:

```sh
$ bun run test:coverage
```

Generate test coverage with lcov report (you'll have to open the `./coverage/index.html` file in your browser, to do so
simply copy paste the path):

```sh
$ bun run test:coverage:report
```


### Interacting with the Contract

Once the contract is deployed, you can interact with it using any Ethereum wallet or a decentralized application (DApp).

#### Buying Tickets

```javascript
import { Jackpot } from 'Jackpot';

const jackpot = new Jackpot('YOUR_DEPLOYED_CONTRACT_ADDRESS');

await jackpot.buyTicket([[1, 2, 3, 4, 5]], [10], { value: 0.0055 });
```

#### Executing a Draw

```javascript
await jackpot.executeDraw();
```

#### Claiming a Prize

```javascript
await jackpot.claimPrize(0);
```

## Roadmap

- [x] Initial contract implementation
- [x] Ticket purchasing functionality
- [x] Draw execution logic
- [x] Prize claiming mechanism
- [ ] Frontend integration
- [ ] More comprehensive test coverage
- [ ] Integration with Chainlink VRF for true randomness
- [ ] Multi-token support for ticket purchasing
- [ ] Implement security audits and best practices

## Contributing

We welcome contributions from the community! To contribute, please see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


---

### Disclaimer
This project has not undergone security auditing yet. Before using or relying on this project, it is recommended to ensure that security enhancements and proper testing have been conducted.
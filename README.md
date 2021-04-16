# Polarfox Core Smart Contracts
This repo contains all of the core smart contracts used to run [Polarfox](polarfox.io).

[![code style: prettier](https://img.shields.io/badge/code_style-prettier-ff69b4.svg?style=flat-square)](https://github.com/prettier/prettier)
[![Actions Status](https://github.com/Polarfox-DEX/polarfox-core/workflows/CI/badge.svg)](https://github.com/Polarfox-DEX/polarfox-core)
[![npm version](https://img.shields.io/npm/v/@polarfox/core/latest.svg)](https://www.npmjs.com/package/@polarfox/core/v/latest)

## Deployed Contracts [MAINNET AVALANCHE]
Factory address: `...`

Router address: `...`

## Deployed Contracts [TESTNET AVALANCHE]
Factory address: `0x5b48659781dccb21031Bdd510f0e46163cC95Ea2`

Router address: `...`

## Running
These contracts are compiled and deployed using [Hardhat](https://hardhat.org/). They can also be run using the Remix IDE. A tutorial for using Remix is located [here](https://docs.avax.network/build/tutorials/platform/deploy-a-smart-contract-on-avalanche-using-remix-and-metamask).

To prepare the dev environment, run `yarn install`. To compile the contracts, run `yarn compile`. Yarn is available to install [here](https://classic.yarnpkg.com/en/docs/install/#debian-stable) if you need it.

# Local Development

The following assumes the use of `node@>=10`.

## Install Dependencies

`yarn`

## Compile Contracts

`yarn compile`

## Run Tests

`yarn test`

## Attribution
These contracts were adapted from these Uniswap repos: [uniswap-v2-core](https://github.com/Uniswap/uniswap-v2-core), [uniswap-v2-periphery](https://github.com/Uniswap/uniswap-v2-core), and [uniswap-lib](https://github.com/Uniswap/uniswap-lib).

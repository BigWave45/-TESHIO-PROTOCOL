# Teshio Protocol

Teshio is an experimental Gno-native protocol for separating the principal claim on a GnoSwap liquidity position from the right to receive its future swap fees for a defined term.

The initial design targets **Gno testnet**. It is a research and prototype project, not a production financial product.

## Core idea

A liquidity provider deposits an eligible, unstaked GnoSwap position NFT into a Teshio vault. The vault retains custody of the NFT and accounts for two distinct claims:

- **Principal claim:** the right to recover the underlying position after the agreement expires.
- **Fee claim:** the right to receive eligible swap fees collected during the agreement term.

The fee claim may be transferred or sold. The principal claim remains locked until the fee claim expires and the vault has completed its accounting.

Teshio does not promise a fixed return. A position may generate little or no fees, and its underlying token balances and market value can change.

## Initial scope

- One GnoSwap position per agreement.
- Unstaked position NFTs only.
- Fixed maturity selected at creation.
- Seller-defined upfront price for the fee claim.
- Fees distributed only after they have actually been collected by the vault.
- Principal redemption after maturity and settlement.
- No leverage, lending, liquidation engine, AMM, or oracle dependency in the first prototype.

## Design status

The protocol is at the specification and feasibility-validation stage. The first implementation milestone is to prove that a Teshio realm can safely custody a GnoSwap position NFT, collect fees as its owner, account for the received GRC-20 tokens, and enforce mutually exclusive principal and fee claims.

See [docs/PROTOCOL_SPEC.md](docs/PROTOCOL_SPEC.md) for the initial lifecycle and unresolved security questions.

## Disclaimer

This repository contains experimental smart-contract software. It has not been audited. Do not deposit assets of value.

# Teshio Protocol

Teshio is an experimental Gno-native protocol exploring the separation of principal ownership and future fee rights attached to GnoSwap liquidity positions.

The initial implementation targets **Gno testnet (Onyx)**. This is prototype software, not a production financial product.

## Product mechanism

A liquidity provider deposits an eligible, unstaked GnoSwap position NFT into a Teshio agreement. Teshio holds the NFT and records two distinct economic claims:

- **Principal claim:** the right to recover the same underlying position NFT after the agreement is closed and final fee accounting is complete.
- **Fee claim:** the right to withdraw the actual net swap fees Teshio collects while the agreement is active.

The fee claim is not a promise of fixed yield. A position may generate little or no fees, and its underlying token composition and market value can change.

## Settlement rule

GnoSwap's current `CollectFee` interface does not accept a historical timestamp or fee-growth cutoff. Teshio therefore cannot enforce an exact wall-clock maturity boundary.

The prototype uses an **earliest close time** instead:

1. The agreement cannot close before its earliest close time.
2. Once that time has passed, anyone may trigger closure.
3. Teshio performs a final fee collection during the close transaction.
4. The actual net amounts collected are credited to the fee claimant.
5. After closure, no further fees can be collected under that agreement.
6. The principal claimant can redeem the NFT after final accounting.

If closing is delayed, fees accrued between the earliest close time and the successful close transaction are included. This is a deliberate v0.2 rule and must be disclosed to buyers.

## Initial scope

- One unstaked GnoSwap position NFT per agreement.
- One principal claimant and one fee claimant.
- Seller-defined asking price.
- Actual collected fees only; no guaranteed return.
- Earliest close time and permissionless close.
- No leverage, lending, liquidation, oracle dependency, or secondary market in the first prototype.

## Automated validation

GitHub Actions runs the Gno formatter, linter, and a local-node realm-load check against the current Gno testnet package imports. A passing workflow is required before treating the contract as compilation-validated. The workflow does not deploy Teshio to a shared network or submit transactions.

See [Gno validation workflow](.github/workflows/gno-validation.yml).

## Engineering status

The repository contains an initial custody realm at `contract/r/teshio/protocol.gno`. Its source-level calls were compared with the current public GnoSwap source. It has **not** yet been compiled, deployed, or exercised on Onyx testnet.

Not yet implemented: agreement purchase, fee collection accounting, fee withdrawals, close, and principal redemption.

See:
- [Protocol specification](docs/PROTOCOL_SPEC.md)
- [Settlement model](docs/SETTLEMENT_MODEL.md)
- [GnoSwap integration analysis](docs/GNOSWAP_INTEGRATION.md)
- [Custody test plan](docs/CUSTODY_TEST_PLAN.md)
- [Source API audit](docs/SOURCE_API_AUDIT.md)

## Risk notice

The code is unaudited and experimental. Do not deposit assets of value.

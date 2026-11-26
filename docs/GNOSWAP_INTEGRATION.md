# GnoSwap Integration Spike

**Status:** Source-level validation complete; testnet execution not yet performed  
**Target:** Onyx testnet  
**Scope:** NFT custody and fee collection only

## Verified from the current GnoSwap source

### 1. Position NFTs are transferable when unstaked

GnoSwap's GNFT package implements GRC-721 ownership, approvals, and transfers. Its documented transfer API is:

```go
gnft.Approve(cross(cur), approvedAddress, tokenID)
gnft.TransferFrom(cross(cur), from, to, tokenID)
```

A position held by the staker contract is locked to staker-mediated movement. The first Teshio version must reject staked positions.

Source: [GNFT README](https://github.com/gnoswap-labs/gnoswap/blob/main/contract/r/gnoswap/gnft/README.md)

### 2. A Teshio realm can become the NFT owner

The intended deposit sequence is:

1. The user approves the Teshio realm address for the specific position NFT.
2. The user calls Teshio's deposit method with the position ID.
3. Teshio calls `gnft.TransferFrom(cross(cur), depositor, teshioAddress, tokenID)`.
4. Teshio reads `gnft.OwnerOf(tokenID)` and requires the returned owner to equal its own realm address.
5. Teshio records the position ID as escrowed only after the ownership check succeeds.

The Teshio realm address should be captured during realm initialization with `cur.Address()`. Do not accept a user-supplied destination address for custody.

This sequence is consistent with GNFT's owner/approval checks, but must still be exercised in an Onyx testnet transaction.

### 3. Fee collection pays the NFT owner or position operator

The public GnoSwap position proxy exposes:

```go
position.CollectFee(cross(cur), positionID)
```

It returns the position ID, net token0 and token1 amounts, pool key, and raw amounts before the withdrawal fee.

The implementation checks that the caller is the NFT owner or its configured position operator. It passes that caller address to the pool's fee collection path, which pays the collected tokens directly to that address.

Therefore, if Teshio owns the NFT and calls `position.CollectFee(cross(cur), positionID)`, the expected recipient is Teshio's realm address. The vault can then account for the tokens and later distribute them.

Sources:

- [Position proxy](https://github.com/gnoswap-labs/gnoswap/blob/main/contract/r/gnoswap/position/proxy.gno)
- [Position implementation](https://github.com/gnoswap-labs/gnoswap/blob/main/contract/r/gnoswap/position/v1/position.gno)
- [Position transfer and fee collection scenario](https://github.com/gnoswap-labs/gnoswap/blob/main/contract/r/scenario/position/position_transfer_with_collect_fee_filetest.gno)

### 4. Position metadata can be read without owning its internal storage

The public position getter package exposes:

- `GetPositionPoolKey(positionID)`
- `GetPositionLiquidity(positionID)`
- `GetPositionTicks(positionID)`
- `GetPositionOwner(positionID)`
- `GetUnclaimedFee(positionID)`
- `IsBurned(positionID))

These read methods allow Teshio to verify that a position exists, is not burned, has non-zero liquidity, and is currently owned by the Teshio realm.

Source: [Position getter API](https://github.com/gnoswap-labs/gnoswap/blob/main/contract/r/gnoswap/position/getter.gno)

## First contract milestone

Do not implement a yield marketplace yet. First prove custody and collection in isolation.

### Required methods

- `DepositPosition(positionID)`: require caller ownership/approval, reject an already escrowed ID, transfer the NFT into Teshio, verify custody, and record the depositor.
- `CollectPositionFees(positionID)`: require an active escrow record, verify Teshio still owns the NFT, call GnoSwap `CollectFee`, and record the actual net token amounts returned.
- `GetEscrow(positionID)`: read-only view of depositor, custody state, and cumulative fee amounts.

The first milestone should not allow NFT withdrawal, claim sales, arbitrary token paths, or user-defined payout addresses. Keep the NFT locked while the custody test is being validated.

## Testnet acceptance sequence

1. Create a GnoSwap position on Onyx testnet with a supported test token pair.
2. Approve the deployed Teshio realm for that exact NFT.
3. Deposit it through Teshio.
4. Query GNFT owner and verify that the owner is the Teshio realm.
5. Attempt a second deposit of the same NFT and verify it fails.
6. Attempt direct transfer by the former owner and verify it fails.
7. Generate swap fees for the position.
8. Call Teshio fee collection.
9. Verify Teshio's token balances increased by the net amounts returned from GnoSwap.
10. Call fee collection again with no new fees and verify no duplicate credit is created.

## Blocking questions before implementing fee distribution

- Confirm the exact deployed Onyx realm paths for GNFT, position, and position getters. Do not assume the mainnet paths and implementation version are identical to the GitHub default branch.
- Confirm the token0 and token1 realm paths can be obtained reliably from the position pool key, or from a public getter. The vault must never trust user-supplied token paths.
- Confirm the current Gno token transfer interfaces and whether Teshio can transfer collected tokens to a fee claimant.
- Define maturity cutoff semantics before any fee claim is sold. Fees accrued before maturity but collected after maturity must not be silently assigned to the wrong period.
- Verify transaction atomicity on-chain: a failed NFT transfer, fee collection, or accounting update must revert the whole call.

## Important limitation

GnoSwap's source code proves the intended authorization and payout logic at source level. It does not prove that Teshio has successfully called these methods on Onyx testnet. No deployment or live transaction is claimed by this document.

# GnoSwap Integration Spike

**Target:** Onyx testnet  
**Status:** Source signatures inspected; testnet integration not yet executed.

## Confirmed source-level interfaces

The current public GnoSwap source exposes the following APIs:

### GNFT

Package: `gno.land/r/gnoswap/gnft`

- `OwnerOf(tid grc721.TokenID) (address, error)`
- `TransferFrom(cur realm, from, to address, tid grc721.TokenID) error`
- `Approve(cur realm, approved address, tid grc721.TokenID) error`
- `Exists(tid grc721.TokenID) bool`

The transfer implementation delegates authorization to the GRC-721 ledger and explicitly restricts staked positions to staker-mediated movement.

### Position getters

Package: `gno.land/r/gnoswap/position`

- `GetPositionLiquidity(positionId uint64) (string, error)`
- `IsBurned(positionId uint64) (bool, error)`
- `GetPositionOwner(positionId uint64) (address, error)`
- `GetPositionPoolKey(positionId uint64) (string, error)`
- `GetUnclaimedFee(positionId uint64) (...)` (confirm the exact return tuple in the checked-out source before use)

### Position actions

Package: `gno.land/r/gnoswap/position`

- `CollectFee(cur realm, positionId uint64) (uint64, string, string, string, string, string)`

The implementation checks that the calling realm is the owner or configured operator of the unstaked NFT. It directs the collected tokens to that caller. Therefore, if Teshio owns the NFT and makes the inter-realm call, the expected fee recipient is the Teshio realm.

## Deposit call sequence

1. User approves the Teshio realm for the exact NFT with GNFT `Approve`.
2. User calls Teshio `DepositPosition`.
3. Teshio checks the caller owns the NFT.
4. Teshio checks the position has non-zero liquidity and is not burned.
5. Teshio calls GNFT `TransferFrom(cross(cur), depositor, teshioAddress, tokenID)`.
6. Teshio independently reads `OwnerOf` and requires its own realm address.
7. Only then does Teshio write the escrow record.

## Fee collection sequence to implement

1. Require an active Teshio agreement and current Teshio custody.
2. Call GnoSwap `CollectFee(cross(cur), positionID)`.
3. Record the returned net token0 and token1 amounts, not estimates.
4. Credit those exact amounts to the fee claimant's internal balances.
5. Ensure all steps revert atomically if any downstream operation fails.

## Unresolved integration blockers

- Verify the imported realm paths and deployed implementation versions on Onyx.
- Compile the current Teshio source against the current Gno toolchain.
- Execute the NFT approval and deposit sequence on Onyx.
- Prove the inter-realm `CollectFee` call sends both tokens to Teshio.
- Resolve token0/token1 realm paths from trusted position data, never user-supplied paths.
- Confirm safe GRC-20 balance and transfer interfaces before implementing fee withdrawals.
- Test transaction atomicity and panic/revert behavior.

Source references:
- [GNFT implementation](https://github.com/gnoswap-labs/gnoswap/blob/main/contract/r/gnoswap/gnft/gnft.gno)
- [Position getters](https://github.com/gnoswap-labs/gnoswap/blob/main/contract/r/gnoswap/position/getter.gno)
- [Position proxy](https://github.com/gnoswap-labs/gnoswap/blob/main/contract/r/gnoswap/position/proxy.gno)
- [Position implementation](https://github.com/gnoswap-labs/gnoswap/blob/main/contract/r/gnoswap/position/v1/position.gno)
- [Transfer/fee-collection scenario](https://github.com/gnoswap-labs/gnoswap/blob/main/contract/r/scenario/position/position_transfer_with_collect_fee_filetest.gno)

Source inspection is not a substitute for compiling and executing against Onyx. No live testnet success is claimed.

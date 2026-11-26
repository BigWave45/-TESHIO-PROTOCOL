# Teshio Custody Test Plan

**Target:** Onyx testnet  
**Contract:** `contract/r/teshio/protocol.gno`  
**Status:** Test plan only; no live testnet execution claimed.

## Current methods

- `DepositPosition(cur, positionID)`
- `GetEscrow(positionID)`
- `IsPositionEscrowed(positionID)`

There is no fee collection, agreement purchase, fee withdrawal, close, or NFT redemption method yet.

## Preconditions

1. Compile and deploy Teshio to Onyx.
2. Confirm deployed GNFT and position realm paths match the imports.
3. Create an unstaked GnoSwap position with non-zero liquidity.
4. Confirm the test wallet owns the NFT.
5. Approve the Teshio realm for that exact token ID.

## Positive test

1. GNFT `OwnerOf` returns the user's address.
2. Teshio `IsPositionEscrowed` returns false.
3. Call Teshio `DepositPosition`.
4. GNFT `OwnerOf` now returns the Teshio realm address.
5. Teshio `GetEscrow` returns the original depositor and true.
6. Teshio `IsPositionEscrowed` returns true.

## Negative tests

- Deposit without NFT approval.
- Deposit an NFT owned by another account.
- Deposit the same position twice.
- Deposit a burned position.
- Deposit a zero-liquidity position.
- Former owner attempts direct transfer after deposit.
- Deposit a nonexistent position ID.

Every expected failure must leave ownership and escrow state unchanged.

## Exit criteria

Custody is validated only when the contract compiles and the positive and negative tests pass against Onyx. Source inspection alone is not acceptance evidence.

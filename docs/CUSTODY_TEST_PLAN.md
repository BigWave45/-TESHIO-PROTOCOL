# Teshio Custody Test Plan

**Target:** Onyx testnet  
**Contract under test:** `contract/r/teshio/protocol.gno`  
**Status:** Test plan only; no live testnet execution claimed.

## Current contract surface

- `DepositPosition(cur, positionID)`
- `GetEscrow(positionID)`
- `IsPositionEscrowed(positionID)`

The current contract intentionally has no withdrawal method and no fee-claim marketplace.

## Preconditions

1. Deploy Teshio to Onyx testnet.
2. Identify the deployed GNFT and GnoSwap position realm paths and confirm they match the imported paths in the source.
3. Create an unstaked GnoSwap position with non-zero liquidity.
4. Confirm the connected wallet is the NFT owner.
5. Approve the deployed Teshio realm address for that exact NFT using GNFT `Approve`.

## Positive test

1. Read GNFT `OwnerOf(positionID)`; it must return the user's address.
2. Read Teshio `IsPositionEscrowed(positionID)`; it must return false.
3. Call Teshio `DepositPosition(positionID)`.
4. Read GNFT `OwnerOf(positionID)`; it must now return the Teshio realm address.
5. Read Teshio `GetEscrow(positionID)`; it must return the original depositor and true.
6. Read Teshio `IsPositionEscrowed(positionID)`; it must return true.

## Negative tests

- Deposit without NFT approval: transaction must fail and no escrow record may be written.
- Deposit an NFT owned by another account: transaction must fail.
- Deposit an already escrowed position ID: transaction must fail.
- Deposit a burned position: transaction must fail.
- Deposit a zero-liquidity position: transaction must fail.
- After successful deposit, former owner attempts direct transfer: transaction must fail.
- Pass a non-existent position ID: transaction must fail without creating an escrow record.

## Atomicity checks

After each expected failure, confirm:

- GNFT owner is unchanged;
- `IsPositionEscrowed` is false unless the earlier deposit succeeded;
- no partial or duplicate escrow record exists.

## Exit criteria

Custody is validated only after the positive test and every negative test pass against the deployed Onyx realm. Source inspection alone is not acceptance evidence.

## Known limitations

- The current contract is not yet compiled or deployed.
- It has no withdrawal, fee collection, or fee distribution methods.
- It assumes the imported GnoSwap realm paths and APIs are available on the target testnet.
- A full integration test is still required to verify realm-call context and NFT approval behavior in the deployed environment.

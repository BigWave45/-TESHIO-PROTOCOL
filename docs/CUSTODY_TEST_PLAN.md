# Teshio Custody Test Plan

**Target:** Onyx testnet  
**Contract:** `contract/r/teshio/protocol.gno`  
**Status:** Test specification only. No tests have been executed; no live testnet execution is claimed.

## Scope

This plan covers the current custody prototype only:

- `DepositPosition(cur, positionID)`
- `GetEscrow(positionID)`
- `IsPositionEscrowed(positionID)`

There is no fee collection, agreement purchase, fee withdrawal, close, or NFT redemption method yet. Those require a separate lifecycle test suite after implementation.

## Preconditions

1. The exact repository revision compiles with the intended Gno toolchain.
2. The GNFT and position realm imports resolve to the intended deployed package versions.
3. A test account owns an unstaked GnoSwap position NFT with non-zero liquidity.
4. The position is not burned.
5. The account approves the Teshio realm to transfer that exact NFT.
6. The test records the NFT owner and Teshio escrow query results before each scenario.

## Scenario matrix

| ID | Scenario | Setup | Expected result |
|---|---|---|---|
| CUST-01 | Valid deposit | Caller owns an existing, unburned, non-zero-liquidity NFT and approves Teshio | Call succeeds; GNFT owner becomes Teshio; escrow records the caller; both escrow queries report true |
| CUST-02 | No approval | Caller owns an eligible NFT but has not approved Teshio | Transfer fails; transaction aborts; NFT remains with caller; no escrow record |
| CUST-03 | Wrong owner | Caller attempts to deposit an NFT owned by another account | Rejected before transfer; NFT owner and escrow state remain unchanged |
| CUST-04 | Duplicate deposit | Deposit an NFT successfully, then attempt the same position ID again | Second call is rejected; Teshio remains owner; original depositor record is unchanged |
| CUST-05 | Zero liquidity | Caller owns and approves an unburned position whose liquidity getter returns zero | Rejected before transfer; NFT remains with caller; no escrow record |
| CUST-06 | Burned position | Caller presents a position for which the burned-state getter returns true | Rejected before transfer; NFT and escrow state remain unchanged |
| CUST-07 | Missing position record | Position liquidity or burned-state lookup returns an error | Rejected; no transfer and no escrow record |
| CUST-08 | Nonexistent NFT | GNFT owner lookup returns an error for the derived token ID | Rejected; no escrow record |
| CUST-09 | Former owner transfer attempt | After successful deposit, the former owner attempts to transfer the NFT without current authorization | GNFT rejects the transfer; Teshio remains owner |
| CUST-10 | Custody query | Query after a successful deposit while Teshio still owns the NFT | `GetEscrow` returns the original depositor and true; `IsPositionEscrowed` returns true |
| CUST-11 | Custody mismatch query | Simulate or arrange a state where the escrow record exists but GNFT owner lookup errors or reports another owner | `GetEscrow` reports custody false; it must not report verified custody |
| CUST-12 | Invalid realm context | Invoke the deposit method without the expected current-realm context | Rejected before any state or NFT ownership change |

## Assertions required for every rejected transaction

A panic or returned error alone is insufficient evidence. After each rejected scenario, verify:

- GNFT `OwnerOf` is unchanged.
- No new escrow record exists.
- Any pre-existing escrow record is unchanged.
- The NFT has not become inaccessible due to a partial transfer.

Gno transaction atomicity should cause state changes in a failed transaction to roll back. This must still be verified for the actual cross-realm GNFT call path; it is not established by this document.

## Local test commands

Run from the repository/package root with a compatible Gno toolchain and all imports available:

```sh
gno fmt ./...
gno lint ./...
gno test ./...
```

The Gno test runner uses a mocked VM. Passing local tests is useful evidence, but it does not prove behavior on Onyx or prove that the deployed GNFT/position realms match the local import sources.

## Onyx acceptance gate

Custody is accepted only after all of the following are recorded against the target network:

1. Teshio compiles and deploys successfully.
2. The imported GNFT and position package paths resolve on Onyx.
3. CUST-01 passes with a real test position.
4. Each applicable negative scenario passes.
5. NFT ownership and escrow state are independently queried after each transaction.
6. Transaction hashes and observed results are recorded.

Until these checks are completed, Teshio custody remains an unverified prototype.

# Source API Audit

**Audit date:** 2026-11-26  
**Scope:** Compare the current Teshio custody realm with the public GnoSwap source on its default branch.  
**Result:** The intended API names and signatures inspected here match the current source. This is not a compiler result or testnet verification.

## Teshio calls reviewed

| Teshio call | GnoSwap declaration | Result |
|---|---|---|
| `gnft.OwnerOf(grc721.TokenID)` | `OwnerOf(tid grc721.TokenID) (address, error)` | Match |
| `gnft.TransferFrom(cross(cur), from, to, tid)` | `TransferFrom(cur realm, from, to address, tid grc721.TokenID) error` | Match |
| `position.GetPositionLiquidity(uint64)` | `GetPositionLiquidity(uint64) (string, error)` | Match |
| `position.IsBurned(uint64)` | `IsBurned(uint64) (bool, error)` | Match |

The GnoSwap source also confirms that GNFT transfer authorization is enforced by its GRC-721 ledger, and that staked position NFTs are restricted to staker-mediated movement.

## Important boundaries

- These signatures were read from the repository's current default branch. The deployed Onyx contracts may be at a different revision or configuration.
- The audit did not run `gnokey`, `gno test`, `gnodev`, or a compiler.
- The audit did not prove that the current Teshio package compiles. In particular, the local Gno toolchain version, package resolution, and realm import availability still need verification.
- No testnet transaction was submitted.
- No claim is made that fee collection, token accounting, agreement sale, or redemption exists in the current contract.

## Next validation gate

Before adding more protocol state, compile the current realm against the current Gno toolchain. Then run a minimal realm test for: caller context, NFT approval, transfer into the Teshio realm, ownership verification, duplicate deposit rejection, and atomic rollback on failure.

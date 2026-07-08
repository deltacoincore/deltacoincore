# Deltacoin Core v1.1.1 Release Notes

Deltacoin Core v1.1.1 is a wallet and node hotfix for the v1.1 hybrid
proof-of-work/proof-of-stake release.

## Hotfix Changes

- Proof-of-stake wallet blocks now include valid mempool transactions after the
  coinstake transaction, so normal sends can confirm while the chain is moving
  by staking.
- Automatic wallet staking now respects the configured stake target spacing
  before minting another local proof-of-stake block.
- `getstakinginfo` now reports the current staking difficulty for easier node
  and explorer diagnostics.
- The expected proof-of-stake block-version marker no longer triggers the
  confusing "unknown new rules activated" warning.
- `getblocktemplate` accepts legacy pool callers that omit the modern `segwit`
  rules list.
- `getaccountaddress` is restored as a legacy compatibility alias for older pool
  and service software.

## Compatibility

- Protocol version remains `70016`.
- Hybrid PoS activation remains block `83100`.
- Proof-of-stake reward remains fixed at `333 DECO`.
- No wallet rescan or chain reset should be required for normal upgrades.

## Acknowledgements

- Special thanks to Elmo40 for early and ongoing Deltacoin support.

Operators should upgrade staking wallets and public nodes so transactions do
not remain waiting in mempool while proof-of-stake blocks are being produced.

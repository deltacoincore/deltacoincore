# Deltacoin Core v1.1.0 Release Notes

Deltacoin Core v1.1.0 is a mandatory network upgrade that introduces the
hybrid proof-of-work/proof-of-stake revival release.

All wallets, nodes, explorers, pools, and services should upgrade before the
mainnet activation height.

## Mandatory Upgrade

- Mainnet hybrid PoS activation height: `83100`.
- Protocol version: `70016`.
- Older clients may not follow valid post-activation proof-of-stake blocks.
- Operators should verify release checksums before replacing existing binaries.

## Consensus Changes

- Blocks before activation remain unchanged and continue to use proof-of-work.
- After activation, proof-of-work blocks remain valid when they satisfy normal
  proof-of-work rules.
- After activation, proof-of-stake blocks are accepted when they satisfy the new
  coinstake validation rules.
- Proof-of-stake blocks use an explicit block-version marker and a coinstake
  transaction.
- Proof-of-stake reward is fixed at `333 DELTA`.
- Post-activation proof-of-work subsidy is restored to `9999 DELTA`.
- Maximum money is set to `8,000,000,000 DELTA`.
- Mainnet DNS discovery uses `node.deltacoincore.com`. DNS seeds are discovery
  helpers only and are not consensus dependencies.

## Wallet And RPC

- Qt wallet includes staking-only unlock support.
- `walletpassphrase` accepts an optional staking-only argument.
- `getstakinginfo` reports activation state, staking state, min age, spacing,
  timestamp mask, weight, network stake weight, expected time, and reward.
- `getstakereport` reports recent wallet staking rewards.
- `getnewaddress` remains available for service and wallet integrations.

## Upgrade Notes

- Encrypted wallets must be unlocked for staking before they can mint PoS
  blocks.
- Stake eligibility uses coin age and stake weight. The default minimum stake
  age is 24 hours.
- Existing balances are preserved through the upgrade.
- Node operators should keep a backup of wallet files before upgrading.

## Validation Performed

- Regtest staking smoke test passed with protocol `70016`.
- Pre-activation PoS rejection was tested.
- Short PoS tip invalidate/reconsider behavior was tested.
- Rebuilt Linux binaries reported the corrected v1.1.0 copyright ranges and
  passed the staking smoke test.
- Windows and Linux release artifacts were packaged with SHA-256 checksums.

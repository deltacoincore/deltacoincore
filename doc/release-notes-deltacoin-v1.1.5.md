# Deltacoin Core v1.1.5 Release Notes

Deltacoin Core v1.1.5 corrects automatic proof-of-stake timing on the hybrid
PoW/PoS network.

## Recommended Update

Staking wallets and staking nodes should update to v1.1.5. Other v1.1.4 nodes
remain network compatible, but updating is recommended so automatic staking
participates in the corrected timing behavior.

## Changes

- Removes an automatic-staking delay that held the earliest local stake
  attempt at 304 seconds against the network's 300-second PoS target.
- Restores 16-second timestamp-window searches for eligible automatic stakes.
- Allows PoS difficulty to respond normally when stake blocks arrive faster
  or slower than the target spacing.
- Adds deterministic PoS retarget regression coverage.
- Adds an automatic-staking smoke test that verifies a normal wallet can mint
  below the former 304-second floor.
- Keeps protocol version `70016` and all existing consensus parameters.

## Upgrade Notes

This release does not change addresses, wallet files, rewards, activation
heights, or the established blockchain. Shut down the previous wallet cleanly,
replace the application files, and start v1.1.5 normally. No reindex or wallet
migration is required.

## Acknowledgements

- Special thanks to Elmo40 for longstanding support of Deltacoin.
- Special thanks to LuckyDogPool for continued network and pool support.

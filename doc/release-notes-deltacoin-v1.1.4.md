# Deltacoin Core v1.1.4 Release Notes

Deltacoin Core v1.1.4 is a wallet reliability and staking-status update for
the hybrid PoW/PoS network. It prevents rejected sends and disconnected stake
transactions from leaving valid wallet inputs unavailable.

## Recommended Update

All desktop wallets, staking nodes, pools, explorers, and services are
encouraged to update. This release is especially important for wallets that
send transactions or participate in staking.

## Changes

- Returns a clear failure when a locally created transaction is rejected
  instead of retaining it as an inactive wallet transaction.
- Releases inputs from rejected transactions automatically so users do not
  need to abandon those transactions manually.
- Prevents disconnected or orphaned coinstake records from reserving
  active-chain UTXOs.
- Automatically abandons stale coinstake records when their block is
  disconnected.
- Corrects staking network-weight units in the RPC and desktop wallet.
- Corrects expected staking-time estimates derived from wallet and network
  weight.
- Keeps protocol version `70016` and all existing consensus parameters.

## Upgrade Notes

This release does not change addresses, wallet files, rewards, activation
heights, or the established blockchain. Shut down the previous wallet cleanly,
replace the application files, and start v1.1.4 normally. No reindex is
required.

Wallets affected by an older rejected transaction may still display that
historical transaction until it is abandoned, but confirmed active-chain
outputs remain intact. Back up `wallet.dat` before any wallet maintenance.

## Acknowledgements

- Special thanks to Elmo40 for longstanding support of Deltacoin.
- Special thanks to LuckyDogPool for continued network and pool support.

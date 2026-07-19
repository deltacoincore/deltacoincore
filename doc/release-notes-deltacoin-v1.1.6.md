# Deltacoin Core v1.1.6 Release Notes

Deltacoin Core v1.1.6 corrects proof-of-stake weight and estimated-time
reporting as network difficulty grows.

## Recommended Update

This is a recommended maintenance update for wallets, staking nodes, and
services that consume `getstakinginfo`. It does not change consensus rules,
the network protocol, rewards, addresses, or wallet files.

## Changes

- Prevents the estimated network stake weight from overflowing to zero at
  higher PoS difficulty.
- Keeps the inherited kernel estimate in its native weight scale rather than
  multiplying it by the base coin unit.
- Ignores non-positive timestamp intervals when sampling recent PoS blocks.
- Aligns the desktop staking tooltip and `getstakinginfo` RPC output.
- Adds regression coverage for the observed overflow and numeric boundaries.
- Keeps protocol version `70016` and all existing consensus parameters.

## Upgrade Notes

Shut down the previous wallet cleanly, replace the application files, and
start v1.1.6 normally. No reindex or wallet migration is required. Older
v1.1.5 nodes remain network compatible.

## Acknowledgements

- Special thanks to Elmo40 for longstanding support of Deltacoin.
- Special thanks to LuckyDogPool for continued network and pool support.

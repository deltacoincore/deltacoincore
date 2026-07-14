# Deltacoin Core v1.1.3 Release Notes

Deltacoin Core v1.1.3 is a mandatory synchronization reliability update for
the hybrid PoW/PoS network. It corrects headers-first synchronization after the
independent PoW/PoS difficulty split at block 85000.

## Mandatory Update

All wallets, nodes, pools, explorers, and services should update. Nodes that
restart or catch up from behind can otherwise reject valid post-split headers
and stop synchronizing.

## Changes

- Preserves the PoS/PoW block type while indexing header-only blocks.
- Correctly calculates split PoW/PoS difficulty during headers-first catch-up.
- Prevents valid updated peers from accumulating a ban score during catch-up.
- Recovers nodes that already cached affected header-only entries.
- Keeps protocol version `70016` and all existing network consensus parameters.

## Upgrade Notes

This release does not change addresses, wallet files, rewards, activation
heights, or the established blockchain. Shut down the previous wallet cleanly,
replace the application files, and start v1.1.3 normally. No reindex is
required.

## Acknowledgements

- Special thanks to Elmo40 for longstanding support of Deltacoin.
- Additional thanks to LuckyDogPool for continued network and pool support.

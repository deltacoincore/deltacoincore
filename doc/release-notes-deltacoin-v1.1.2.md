# Deltacoin Core v1.1.2 Release Notes

Deltacoin Core v1.1.2 is a mandatory network update for the hybrid PoW/PoS
chain. This release separates PoW and PoS difficulty tracking so each block
type retargets from its own recent history after the activation height.

## Mandatory Update

All staking wallets, nodes, pools, explorers, and services should update before
block 85000. Nodes that remain on older hybrid builds may follow the wrong
difficulty rule after that height.

## Changes

- Adds independent PoW and PoS difficulty retargeting beginning at block 85000.
- Keeps PoW mining templates on the PoW difficulty path.
- Ensures locally-created PoS block candidates calculate stake difficulty using
  the PoS block-version marker.
- Keeps `getdifficulty` and `getmininginfo.difficulty` PoW-facing for mining
  pool compatibility.
- Adds explicit RPC reporting for `difficulty_pow`, `difficulty_pos`,
  `hybrid_pos_activationheight`, and `hybrid_difficulty_splitheight`.
- Keeps protocol version `70016`.

## Notes

This update does not change the Deltacoin ticker, address format, wallet files,
or protocol version. Existing wallets can be opened normally after upgrading.

## Acknowledgements

- Special thanks to Elmo40 for early and ongoing Deltacoin support.
- Appreciation to LuckyDogPool for operating pool infrastructure and supporting
  the network through the hybrid update.

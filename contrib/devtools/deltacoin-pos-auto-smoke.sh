#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Usage: $0 <binary-dir> [data-dir]" >&2
    exit 2
fi

binary_dir="$(cd "$1" && pwd)"
daemon="$binary_dir/deltacoind"
cli="$binary_dir/deltacoin-cli"
data_dir="${2:-$(mktemp -d -t deltacoin-pos-auto-smoke-XXXXXXXX)}"
rpc_user="smoke"
rpc_password="smoke-pass"

if [[ ! -x "$daemon" || ! -x "$cli" ]]; then
    echo "Missing executable deltacoind or deltacoin-cli in $binary_dir" >&2
    exit 2
fi

mkdir -p "$data_dir"
cat > "$data_dir/deltacoin.conf" <<EOF
regtest=1
server=1
listen=0
staking=1
rpcuser=$rpc_user
rpcpassword=$rpc_password
EOF

rpc() {
    "$cli" -regtest "-datadir=$data_dir" "-rpcuser=$rpc_user" "-rpcpassword=$rpc_password" "$@"
}

cleanup() {
    rpc stop >/dev/null 2>&1 || true
}
trap cleanup EXIT

"$daemon" -regtest "-datadir=$data_dir" -daemon -server -listen=0 -staking=1 \
    "-rpcuser=$rpc_user" "-rpcpassword=$rpc_password" >/dev/null

ready=false
for _ in $(seq 1 120); do
    if rpc getblockchaininfo >/dev/null 2>&1; then
        ready=true
        break
    fi
    sleep 1
done
if [[ "$ready" != true ]]; then
    echo "RPC did not become ready within 120 seconds" >&2
    exit 1
fi

address="$(rpc getnewaddress)"
rpc generatetoaddress 101 "$address" >/dev/null
starting_height="$(rpc getblockcount)"

deadline=$((SECONDS + 180))
auto_stake_hash=""
while (( SECONDS < deadline )); do
    current_height="$(rpc getblockcount)"
    if (( current_height > starting_height )); then
        candidate_hash="$(rpc getbestblockhash)"
        candidate_version="$(rpc getblockheader "$candidate_hash" | python3 -c 'import json,sys; print(json.load(sys.stdin)["versionHex"])')"
        if [[ "$candidate_version" == "20000100" ]]; then
            auto_stake_hash="$candidate_hash"
            break
        fi
    fi
    sleep 2
done

if [[ -z "$auto_stake_hash" ]]; then
    echo "Automatic staking did not produce a PoS block within 180 seconds" >&2
    exit 1
fi

read -r stake_time previous_hash < <(
    rpc getblockheader "$auto_stake_hash" |
        python3 -c 'import json,sys; value=json.load(sys.stdin); print(value["time"], value["previousblockhash"])'
)
previous_time="$(
    rpc getblockheader "$previous_hash" |
        python3 -c 'import json,sys; print(json.load(sys.stdin)["time"])'
)"
spacing=$((stake_time - previous_time))
search_interval="$(
    rpc getstakinginfo |
        python3 -c 'import json,sys; print(json.load(sys.stdin)["search-interval"])'
)"

if (( spacing >= 304 )); then
    echo "Automatic PoS spacing remained pinned at ${spacing}s" >&2
    exit 1
fi
if (( search_interval <= 0 || search_interval > 32 )); then
    echo "Unexpected automatic staking search interval: ${search_interval}s" >&2
    exit 1
fi

printf 'Automatic PoS hash: %s\n' "$auto_stake_hash"
printf 'Automatic PoS spacing: %ss\n' "$spacing"
printf 'Staking search interval: %ss\n' "$search_interval"
printf 'Result: PASS\n'

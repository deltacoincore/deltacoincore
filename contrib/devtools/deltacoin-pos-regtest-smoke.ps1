param(
    [Parameter(Mandatory = $true)]
    [string]$BinaryDir,

    [string]$DataDir = "",

    [int]$StakeWaitSeconds = 65
)

$ErrorActionPreference = "Stop"

$daemon = Join-Path $BinaryDir "deltacoind.exe"
$cli = Join-Path $BinaryDir "deltacoin-cli.exe"

if (-not (Test-Path -LiteralPath $daemon)) {
    throw "Missing daemon: $daemon"
}
if (-not (Test-Path -LiteralPath $cli)) {
    throw "Missing CLI: $cli"
}

if (-not $DataDir) {
    $DataDir = Join-Path ([System.IO.Path]::GetTempPath()) ("deltacoin-pos-smoke-" + [System.Guid]::NewGuid().ToString("N"))
}

if (Test-Path -LiteralPath $DataDir) {
    Remove-Item -LiteralPath $DataDir -Recurse -Force
}
New-Item -ItemType Directory -Path $DataDir | Out-Null
Set-Content -LiteralPath (Join-Path $DataDir "deltacoin.conf") -Encoding ASCII -Value "regtest=1`nrpcuser=smoke`nrpcpassword=smoke-pass`nserver=1`nlisten=0`n"

function Invoke-DeltaRpc {
    param([Parameter(Mandatory = $true)][string]$RpcArgs)

    $cmd = '"' + $cli + '" -regtest "-datadir=' + $DataDir + '" -rpcuser=smoke -rpcpassword=smoke-pass ' + $RpcArgs
    $out = cmd /c "$cmd 2>&1"
    if ($LASTEXITCODE -ne 0) {
        throw "RPC failed [$RpcArgs]: $out"
    }
    return ($out | Out-String).Trim()
}

function Start-Delta {
    $args = "-regtest -datadir=`"$DataDir`" -server -listen=0 -rpcuser=smoke -rpcpassword=smoke-pass"
    $proc = Start-Process -FilePath $daemon -ArgumentList $args -WindowStyle Hidden -PassThru
    for ($i = 0; $i -lt 120; $i++) {
        Start-Sleep -Seconds 1
        if (-not (Get-Process -Id $proc.Id -ErrorAction SilentlyContinue)) {
            throw "deltacoind exited before RPC became ready"
        }
        try {
            [void](Invoke-DeltaRpc "getblockchaininfo")
            return $proc
        } catch {
            if ($i -eq 119) {
                throw
            }
        }
    }
}

$p = $null
try {
    $p = Start-Delta
    $addr = Invoke-DeltaRpc "getnewaddress"
    try {
        [void](Invoke-DeltaRpc "generatetoaddress 101 $addr")
    } catch {
        [void](Invoke-DeltaRpc "generate 101")
    }

    $heightAfterMine = Invoke-DeltaRpc "getblockcount"
    $stakingInfo = Invoke-DeltaRpc "getstakinginfo"
    $networkInfo = Invoke-DeltaRpc "getnetworkinfo"
    $initialStakeReport = Invoke-DeltaRpc "getstakereport"

    $networkInfoJson = $networkInfo | ConvertFrom-Json
    if ($networkInfoJson.protocolversion -ne 70016) {
        throw "Unexpected protocol version: $($networkInfoJson.protocolversion)"
    }

    $stakingInfoJson = $stakingInfo | ConvertFrom-Json
    foreach ($field in @("search-interval", "weight", "netstakeweight", "expectedtime")) {
        if (-not ($stakingInfoJson.PSObject.Properties.Name -contains $field)) {
            throw "getstakinginfo is missing expected field: $field"
        }
    }

    $initialStakeReportJson = $initialStakeReport | ConvertFrom-Json
    if ($initialStakeReportJson.'Stake counted' -ne 0) {
        throw "Fresh regtest wallet reported unexpected mature stakes before creating a PoS block"
    }

    Start-Sleep -Seconds $StakeWaitSeconds

    $pos = Invoke-DeltaRpc "createposblock"
    $best = Invoke-DeltaRpc "getbestblockhash"
    $block = Invoke-DeltaRpc "getblock $best 2"

    if ($block -notmatch '"versionHex": "20000100"') {
        throw "Accepted block does not expose the expected proof-of-stake version marker"
    }
    if ($block -notmatch '"accepted": true' -and $pos -notmatch '"accepted": true') {
        throw "createposblock did not report accepted=true"
    }

    try {
        [void](Invoke-DeltaRpc "generatetoaddress 101 $addr")
    } catch {
        [void](Invoke-DeltaRpc "generate 101")
    }
    $matureStakeReport = Invoke-DeltaRpc "getstakereport"
    $matureStakeReportJson = $matureStakeReport | ConvertFrom-Json
    if ($matureStakeReportJson.'Stake counted' -lt 1) {
        throw "getstakereport did not count the matured coinstake"
    }

    [void](Invoke-DeltaRpc "stop")
    Start-Sleep -Seconds 3
    if (Get-Process -Id $p.Id -ErrorAction SilentlyContinue) {
        Stop-Process -Id $p.Id -Force
    }

    $p = Start-Delta
    $heightAfterRestart = Invoke-DeltaRpc "getblockcount"
    $bestAfterRestart = Invoke-DeltaRpc "getbestblockhash"
    [void](Invoke-DeltaRpc "stop")

    [pscustomobject]@{
        DataDir = $DataDir
        Address = $addr
        HeightAfterMine = $heightAfterMine
        HeightAfterRestart = $heightAfterRestart
        BestAfterRestart = $bestAfterRestart
        StakingInfo = $stakingInfo
        InitialStakeReport = $initialStakeReport
        MatureStakeReport = $matureStakeReport
        Result = "PASS"
    } | Format-List
} finally {
    Start-Sleep -Seconds 2
    if ($p -and (Get-Process -Id $p.Id -ErrorAction SilentlyContinue)) {
        Stop-Process -Id $p.Id -Force
    }
}

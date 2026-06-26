param(
    [Parameter(Mandatory = $true)]
    [string]$BinaryDir,

    [string]$DataRoot = "",

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

if (-not $DataRoot) {
    $DataRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("deltacoin-pos-split-smoke-" + [System.Guid]::NewGuid().ToString("N"))
}

if (Test-Path -LiteralPath $DataRoot) {
    Remove-Item -LiteralPath $DataRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $DataRoot | Out-Null

function New-NodeDataDir {
    param([Parameter(Mandatory = $true)][string]$Name)
    $dir = Join-Path $DataRoot $Name
    New-Item -ItemType Directory -Path $dir | Out-Null
    Set-Content -LiteralPath (Join-Path $dir "deltacoin.conf") -Encoding ASCII -Value "regtest=1`nrpcuser=smoke`nrpcpassword=smoke-pass`nserver=1`nlisten=0`n"
    return $dir
}

function Invoke-DeltaRpc {
    param(
        [Parameter(Mandatory = $true)][string]$DataDir,
        [Parameter(ValueFromRemainingArguments = $true)][string[]]$RpcArgs
    )

    $baseArgs = @("-regtest", "-datadir=$DataDir", "-rpcuser=smoke", "-rpcpassword=smoke-pass")
    $out = & $cli @baseArgs @RpcArgs 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "RPC failed [$($RpcArgs -join ' ')]: $out"
    }
    return ($out | Out-String).Trim()
}

function Start-Delta {
    param(
        [Parameter(Mandatory = $true)][string]$DataDir,
        [int]$ActivationHeight = -1
    )

    $args = @("-regtest", "-datadir=$DataDir", "-server", "-listen=0", "-rpcuser=smoke", "-rpcpassword=smoke-pass")
    if ($ActivationHeight -ge 0) {
        $args += "-posactivationheight=$ActivationHeight"
    }
    $proc = Start-Process -FilePath $daemon -ArgumentList $args -WindowStyle Hidden -PassThru
    for ($i = 0; $i -lt 120; $i++) {
        Start-Sleep -Seconds 1
        if (-not (Get-Process -Id $proc.Id -ErrorAction SilentlyContinue)) {
            throw "deltacoind exited before RPC became ready"
        }
        try {
            [void](Invoke-DeltaRpc -DataDir $DataDir getblockchaininfo)
            return $proc
        } catch {
            if ($i -eq 119) {
                throw
            }
        }
    }
}

function Stop-Delta {
    param(
        [string]$DataDir,
        [System.Diagnostics.Process]$Process
    )

    if ($DataDir) {
        try {
            [void](Invoke-DeltaRpc -DataDir $DataDir stop)
        } catch {
        }
    }
    Start-Sleep -Seconds 2
    if ($Process -and (Get-Process -Id $Process.Id -ErrorAction SilentlyContinue)) {
        Stop-Process -Id $Process.Id -Force
    }
}

$proc = $null
$preActivationResult = $null
$reorgResult = $null

try {
    $preDir = New-NodeDataDir "pre-activation"
    $proc = Start-Delta -DataDir $preDir -ActivationHeight 200
    $preAddr = Invoke-DeltaRpc -DataDir $preDir getnewaddress
    try {
        [void](Invoke-DeltaRpc -DataDir $preDir generatetoaddress 101 $preAddr)
    } catch {
        [void](Invoke-DeltaRpc -DataDir $preDir generate 101)
    }
    Stop-Delta -DataDir $preDir -Process $proc
    $proc = $null

    $makerDir = Join-Path $DataRoot "activated-maker"
    Copy-Item -LiteralPath $preDir -Destination $makerDir -Recurse
    $proc = Start-Delta -DataDir $makerDir -ActivationHeight 1
    Start-Sleep -Seconds $StakeWaitSeconds
    $prePosRaw = Invoke-DeltaRpc -DataDir $makerDir createposblock
    $prePosJson = $prePosRaw | ConvertFrom-Json
    if (-not $prePosJson.accepted) {
        throw "Activated maker did not create a PoS block for the pre-activation rejection test"
    }
    $prePosHash = Invoke-DeltaRpc -DataDir $makerDir getbestblockhash
    $prePosHex = Invoke-DeltaRpc -DataDir $makerDir getblock $prePosHash false
    Stop-Delta -DataDir $makerDir -Process $proc
    $proc = $null

    $proc = Start-Delta -DataDir $preDir -ActivationHeight 200
    $submitResult = Invoke-DeltaRpc -DataDir $preDir submitblock $prePosHex
    if ([string]::IsNullOrWhiteSpace($submitResult) -or $submitResult -eq "null") {
        throw "Pre-activation node accepted a PoS block before activation"
    }
    if ($submitResult -notmatch "bad-pos-not-active|proof-of-stake before hybrid activation") {
        throw "Pre-activation block rejection did not include the expected reason: $submitResult"
    }
    $preActivationResult = "PASS"
    Stop-Delta -DataDir $preDir -Process $proc
    $proc = $null

    $reorgDir = New-NodeDataDir "reorg"
    $proc = Start-Delta -DataDir $reorgDir
    $reorgAddr = Invoke-DeltaRpc -DataDir $reorgDir getnewaddress
    try {
        [void](Invoke-DeltaRpc -DataDir $reorgDir generatetoaddress 101 $reorgAddr)
    } catch {
        [void](Invoke-DeltaRpc -DataDir $reorgDir generate 101)
    }
    Start-Sleep -Seconds $StakeWaitSeconds

    $posRaw = Invoke-DeltaRpc -DataDir $reorgDir createposblock
    $posJson = $posRaw | ConvertFrom-Json
    if (-not $posJson.accepted) {
        throw "createposblock did not report accepted=true"
    }
    $posHash = Invoke-DeltaRpc -DataDir $reorgDir getbestblockhash
    $heightBeforeInvalidate = [int](Invoke-DeltaRpc -DataDir $reorgDir getblockcount)

    [void](Invoke-DeltaRpc -DataDir $reorgDir invalidateblock $posHash)
    $heightAfterInvalidate = [int](Invoke-DeltaRpc -DataDir $reorgDir getblockcount)
    $bestAfterInvalidate = Invoke-DeltaRpc -DataDir $reorgDir getbestblockhash
    if ($heightAfterInvalidate -ge $heightBeforeInvalidate) {
        throw "invalidateblock did not rewind the PoS tip"
    }
    if ($bestAfterInvalidate -eq $posHash) {
        throw "invalidateblock left the invalidated PoS block active"
    }

    [void](Invoke-DeltaRpc -DataDir $reorgDir reconsiderblock $posHash)
    $bestAfterReconsider = Invoke-DeltaRpc -DataDir $reorgDir getbestblockhash
    if ($bestAfterReconsider -ne $posHash) {
        throw "reconsiderblock did not restore the PoS tip"
    }

    $reorgResult = "PASS"
    Stop-Delta -DataDir $reorgDir -Process $proc
    $proc = $null

    [pscustomobject]@{
        DataRoot = $DataRoot
        PreActivationRejection = $preActivationResult
        ReorgInvalidateReconsider = $reorgResult
        PosHash = $posHash
        HeightBeforeInvalidate = $heightBeforeInvalidate
        HeightAfterInvalidate = $heightAfterInvalidate
        Result = "PASS"
    } | Format-List
} finally {
    if ($proc) {
        Stop-Delta -Process $proc
    }
}

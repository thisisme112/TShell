$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root "assets\agent"
New-Item -ItemType Directory -Force $out | Out-Null
Push-Location (Join-Path $root "agent")
try {
  $env:GOOS = "linux"; $env:GOARCH = "amd64"
  go build -o (Join-Path $out "tshell-agent-linux-amd64") .
  $env:GOOS = "windows"; $env:GOARCH = "amd64"
  go build -o (Join-Path $out "tshell-agent-windows-amd64.exe") .
}
finally {
  Pop-Location
}

# Builds Setup.exe from Setup.cs using the .NET Framework C# compiler.
# No extra tools required on Windows (csc.exe ships with the OS framework).
$ErrorActionPreference = 'Stop'

$candidates = @(
  'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe',
  'C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe'
)
$csc = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $csc) { throw 'csc.exe not found. This script requires Windows with .NET Framework 4.5+.' }

$src = Join-Path $PSScriptRoot 'Setup.cs'
$out = Join-Path $PSScriptRoot 'Setup.exe'
if (-not (Test-Path -LiteralPath $src)) { throw "Missing $src" }

& $csc /nologo /t:exe /optimize /out:"$out" /r:System.IO.Compression.FileSystem.dll "$src"
if ($LASTEXITCODE -ne 0) { throw 'Setup.cs compilation failed' }

$hash = (Get-FileHash -LiteralPath $out -Algorithm SHA256).Hash
Write-Host "Built $out"
Write-Host "SHA-256: $hash"
Write-Host 'Test it with: .\Setup.exe --help'

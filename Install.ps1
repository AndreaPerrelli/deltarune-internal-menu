param([string]$GameFolder,[string]$ToolPath,[int[]]$Chapters=@(1,2,3,4,5))
$ErrorActionPreference='Stop'
Set-StrictMode -Version 2
if(!$GameFolder){$GameFolder=Read-Host 'DELTARUNE folder (the one containing DELTARUNE.exe)'}
if(!$ToolPath){$ToolPath=Read-Host 'Full path to UndertaleModCli.exe version 0.9.2.0'}
$game=(Resolve-Path -LiteralPath $GameFolder).Path
$cli=(Resolve-Path -LiteralPath $ToolPath).Path
if(!(Test-Path -LiteralPath (Join-Path $game 'DELTARUNE.exe'))){throw 'Select the game root containing DELTARUNE.exe.'}
if([IO.Path]::GetFileName($cli) -ne 'UndertaleModCli.exe'){throw 'Select UndertaleModCli.exe from the official Windows CLI release.'}
$version=(& $cli --version | Out-String).Trim()
if($LASTEXITCODE -ne 0 -or $version -notmatch '^0\.9\.2\.0(?:\+|$)'){throw 'This release requires UndertaleModTool CLI 0.9.2.0.'}
if(Get-Process DELTARUNE -ErrorAction SilentlyContinue){throw 'Close DELTARUNE before installing.'}
$payload=Join-Path $PSScriptRoot 'payload'
$jobs=@()
$envNames=@('IM_RELEASE_CHAPTER','IM_RELEASE_PAYLOAD','IM_RELEASE_REPORT','IM_RELEASE_MUSIC')
$savedEnv=@{};foreach($name in $envNames){$savedEnv[$name]=[Environment]::GetEnvironmentVariable($name,'Process')}
try{
 foreach($c in @($Chapters|Select-Object -Unique)){
  if($c -lt 1 -or $c -gt 5){throw 'Chapters must be between 1 and 5.'}
  $dir=Join-Path $game "chapter${c}_windows"
  $target=Join-Path $dir 'data.win'
  if(!(Test-Path -LiteralPath $target)){Write-Host "Chapter $c not installed; skipped.";continue}
  $originalHash=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
  $stateDir=Join-Path $dir '.internal-menu-release'
  $stateFile=Join-Path $stateDir 'state.json'
  if(Test-Path -LiteralPath $stateFile){
   $old=Get-Content -LiteralPath $stateFile -Raw|ConvertFrom-Json
   if($originalHash -eq $old.patchedSHA256 -and $old.version -eq '1.2.0'){Write-Host "Chapter $c already installed; skipped.";continue}
   if($originalHash -ne $old.originalSHA256){throw "Chapter $c has changed since the last installation. Restore the previous menu or use a clean archive first."}
  }
  New-Item -ItemType Directory -Force -Path $stateDir|Out-Null
  $id=[Guid]::NewGuid().ToString('N')
  $candidate=Join-Path $stateDir "$id.patched.win"
  $backup=Join-Path $stateDir "$id.original.win"
  $report=Join-Path $stateDir "$id.report.json"
  $log=Join-Path $stateDir "$id.build.log"
  $env:IM_RELEASE_CHAPTER=[string]$c;$env:IM_RELEASE_PAYLOAD=$payload
  $env:IM_RELEASE_REPORT=$report;$env:IM_RELEASE_MUSIC=Join-Path $game 'mus'
  Write-Host "Preparing chapter $c from YOUR archive..."
  & $cli load $target -s (Join-Path $payload 'Patch.csx') -o $candidate -f *> $log
  if($LASTEXITCODE -ne 0 -or !(Test-Path -LiteralPath $candidate) -or !(Test-Path -LiteralPath $report)){
   throw "Chapter $c could not be patched. No prepared archives have been installed. See $log"
  }
  $r=Get-Content -LiteralPath $report -Raw|ConvertFrom-Json
  if(!$r.completed -or !$r.originalStringsPreserved -or $r.chapter -ne $c){throw "Invalid build report for chapter $c"}
  & $cli load $candidate -s (Join-Path $payload 'Verify.csx') *>> $log
  if($LASTEXITCODE -ne 0 -or !(Test-Path -LiteralPath ($report+'.verified'))){throw "Chapter $c verification failed. See $log"}
  $jobs+=@{chapter=$c;target=$target;candidate=$candidate;backup=$backup;stateFile=$stateFile;report=$report;originalHash=$originalHash;patchedHash=(Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash}
 }
 # Finish all compilation and text checks before committing any prepared archive.
 if(Get-Process DELTARUNE -ErrorAction SilentlyContinue){throw 'DELTARUNE started during preparation. Close it and retry.'}
 foreach($job in $jobs){if((Get-FileHash -LiteralPath $job.target -Algorithm SHA256).Hash -ne $job.originalHash){throw 'A game archive changed during preparation; no prepared files installed.'}}
 foreach($job in $jobs){
  if((Get-FileHash -LiteralPath $job.target -Algorithm SHA256).Hash -ne $job.originalHash){throw 'Archive changed before replacement; stopping. Already-installed chapters can be restored with Uninstall.cmd.'}
  $state=[ordered]@{version='1.2.0';chapter=$job.chapter;status='Prepared';originalSHA256=$job.originalHash;patchedSHA256=$job.patchedHash;backupFile=[IO.Path]::GetFileName($job.backup);reportFile=[IO.Path]::GetFileName($job.report)}
  $state|ConvertTo-Json|Set-Content -LiteralPath $job.stateFile -Encoding UTF8
  [IO.File]::Replace($job.candidate,$job.target,$job.backup)
  if((Get-FileHash -LiteralPath $job.backup -Algorithm SHA256).Hash -ne $job.originalHash){throw 'Backup verification failed; retain all files for recovery.'}
  if((Get-FileHash -LiteralPath $job.target -Algorithm SHA256).Hash -ne $job.patchedHash){throw 'Installed archive verification failed; use Uninstall.cmd.'}
  $state.status='Installed';$state|ConvertTo-Json|Set-Content -LiteralPath $job.stateFile -Encoding UTF8
  Write-Host "Installed chapter $($job.chapter). Original language/text preserved."
 }
 Write-Host 'Done. Start the game normally and press F1. No language or save files were written.'
}finally{foreach($name in $envNames){[Environment]::SetEnvironmentVariable($name,$savedEnv[$name],'Process')}}

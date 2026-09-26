param([string]$GameFolder,[int[]]$Chapters=@(1,2,3,4,5))
$ErrorActionPreference='Stop'
if(!$GameFolder){$GameFolder=Read-Host 'DELTARUNE folder (the one containing DELTARUNE.exe)'}
$game=(Resolve-Path -LiteralPath $GameFolder).Path
if(!(Test-Path -LiteralPath (Join-Path $game 'DELTARUNE.exe'))){throw 'Select the DELTARUNE game root.'}
if(Get-Process DELTARUNE -ErrorAction SilentlyContinue){throw 'Close DELTARUNE before restoring.'}
$jobs=@()
foreach($c in @($Chapters|Select-Object -Unique)){
 if($c -lt 1 -or $c -gt 5){throw 'Chapters must be between 1 and 5.'}
 $dir=Join-Path $game "chapter${c}_windows";$target=Join-Path $dir 'data.win'
 $stateDir=Join-Path $dir '.internal-menu-release';$stateFile=Join-Path $stateDir 'state.json'
 if(!(Test-Path -LiteralPath $stateFile)){continue}
 $state=Get-Content -LiteralPath $stateFile -Raw|ConvertFrom-Json
 if($state.chapter -ne $c -or $state.backupFile -ne [IO.Path]::GetFileName($state.backupFile)){throw 'Invalid backup metadata.'}
 $current=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
 if($current -eq $state.originalSHA256){Write-Host "Chapter $c already restored.";continue}
 if($current -ne $state.patchedSHA256){throw "Chapter $c changed after installation (update or another mod). Refusing to overwrite it."}
 $backup=Join-Path $stateDir $state.backupFile
 if((Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash -ne $state.originalSHA256){throw "Chapter $c backup is missing or damaged."}
 $jobs+=@{target=$target;backup=$backup;state=$state;stateFile=$stateFile;dir=$stateDir}
}
foreach($job in $jobs){
 if((Get-FileHash -LiteralPath $job.target -Algorithm SHA256).Hash -ne $job.state.patchedSHA256){throw 'Archive changed before restore; stopping.'}
 $tmp=Join-Path $job.dir ([Guid]::NewGuid().ToString('N')+'.restore.win')
 Copy-Item -LiteralPath $job.backup -Destination $tmp
 [IO.File]::Replace($tmp,$job.target,($tmp+'.removed-menu.win'))
 if((Get-FileHash -LiteralPath $job.target -Algorithm SHA256).Hash -ne $job.state.originalSHA256){throw 'Restored file failed verification.'}
 $job.state.status='Restored';$job.state|ConvertTo-Json|Set-Content -LiteralPath $job.stateFile -Encoding UTF8
 Write-Host "Restored chapter $($job.state.chapter), including its original language/mods."
}
Write-Host 'Backups retained. Save files were not changed.'


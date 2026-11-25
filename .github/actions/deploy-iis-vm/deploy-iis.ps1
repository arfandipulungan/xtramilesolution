param(
  [Parameter(Mandatory)] [string] $AppName,
  [Parameter(Mandatory)] [string] $Version,
  [Parameter(Mandatory)] [string] $BlobUrl,
  [string] $SiteName = $AppName,
  [string] $HealthPath = '/health',
  [int]    $KeepReleases = 5
)
$ErrorActionPreference = 'Stop'
Import-Module WebAdministration

$root   = "D:\sites\$AppName\releases"
$target = Join-Path $root $Version
$zip    = Join-Path $env:TEMP "$AppName-$Version.zip"

# 1. Download with the VM's managed identity (no keys or SAS on the VM)
$token = (Invoke-RestMethod -Headers @{ Metadata = 'true' } `
  -Uri 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://storage.azure.com/').access_token
Invoke-WebRequest -Uri $BlobUrl -OutFile $zip -UseBasicParsing `
  -Headers @{ Authorization = "Bearer $token"; 'x-ms-version' = '2020-04-08' }

# 2. Extract into a new versioned folder; previous releases stay on disk
New-Item -ItemType Directory -Force -Path $target | Out-Null
Expand-Archive -Path $zip -DestinationPath $target -Force

# 3. Switch the site to the new release
$previous = (Get-ItemProperty "IIS:\Sites\$SiteName").physicalPath
$pool     = (Get-ItemProperty "IIS:\Sites\$SiteName").applicationPool
Set-ItemProperty "IIS:\Sites\$SiteName" -Name physicalPath -Value $target
Restart-WebAppPool -Name $pool

# 4. Health check; roll back to the previous folder on failure
$healthy = $false
foreach ($i in 1..10) {
  try {
    $r = Invoke-WebRequest -Uri "http://localhost$HealthPath" -UseBasicParsing -TimeoutSec 10
    if ($r.StatusCode -eq 200) { $healthy = $true; break }
  } catch { }
  Start-Sleep -Seconds 6
}
if (-not $healthy) {
  Write-Output "Health check failed, rolling back to $previous"
  Set-ItemProperty "IIS:\Sites\$SiteName" -Name physicalPath -Value $previous
  Restart-WebAppPool -Name $pool
  throw "Release $Version failed and was rolled back"
}

# 5. Keep only the last N releases
Get-ChildItem $root -Directory | Sort-Object CreationTime -Descending |
  Select-Object -Skip $KeepReleases | Remove-Item -Recurse -Force
Write-Output "Deployed $AppName $Version"

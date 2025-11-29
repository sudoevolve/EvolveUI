# Double-click to run and enter the project name interactively
param(
  [string]$Name,
  [string]$Destination = ".",
  [string]$Template = ""
)

if (-not $Name -or $Name.Trim().Length -eq 0) {
  $Name = Read-Host "Please enter the project name (required)"
  if (-not $Name) { Write-Host "Project name cannot be empty. Exiting script."; pause; exit 1 }
}

if (-not $Destination -or $Destination.Trim().Length -eq 0) {
  $repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
  $workspaceRoot = Split-Path -Parent $repoRoot
  $defaultDest = (Resolve-Path -LiteralPath $workspaceRoot).Path
  $Destination = Read-Host "Please enter the destination directory (default: $defaultDest)"
  if (-not $Destination -or $Destination.Trim().Length -eq 0) { $Destination = $defaultDest }
}

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$templatesPath = Join-Path $repoRoot "..\scaffold\templates"
$availableTemplates = @(Get-ChildItem -Directory $templatesPath | Sort-Object Name | Select-Object -ExpandProperty Name)

$explicitTemplate = $PSBoundParameters.ContainsKey('Template')
if (-not $explicitTemplate) {
  Write-Host "Available templates:"
  for ($i = 0; $i -lt $availableTemplates.Count; $i++) { Write-Host "[$($i+1)] $($availableTemplates[$i])" }
  $choice = Read-Host "Enter template number or name (default: 1)"
  if (-not $choice -or $choice.Trim().Length -eq 0) {
    $Template = $availableTemplates[0]
  } elseif ($choice -match '^[0-9]+$') {
    $idx = [int]$choice
    if ($idx -ge 1 -and $idx -le $availableTemplates.Count) { $Template = $availableTemplates[$idx - 1] } else { Write-Error "Invalid template number: $choice"; pause; exit 1 }
  } else {
    $Template = $choice
  }
}
$templateRoot = Join-Path $repoRoot "..\scaffold\templates\$Template"
if (-not (Test-Path $templateRoot)) { Write-Error "Template not found: $templateRoot"; pause; exit 1 }
if (-not (Test-Path $Destination)) { New-Item -ItemType Directory -Path $Destination -Force | Out-Null }
$destRoot = (Resolve-Path -LiteralPath $Destination).Path
$newProjectDir = Join-Path $destRoot $Name
if (Test-Path $newProjectDir) { Write-Error "Destination directory already exists: $newProjectDir"; pause; exit 1 }
New-Item -ItemType Directory -Path $newProjectDir | Out-Null
Copy-Item -Recurse -Force (Join-Path $templateRoot "*") $newProjectDir
(Get-Content (Join-Path $newProjectDir "CMakeLists.txt") -Encoding UTF8) -replace "__PROJECT_NAME__", $Name | Set-Content -Encoding UTF8 (Join-Path $newProjectDir "CMakeLists.txt")
if (Test-Path (Join-Path $newProjectDir "main.cpp")) {
  (Get-Content (Join-Path $newProjectDir "main.cpp") -Encoding UTF8) -replace "__PROJECT_NAME__", $Name | Set-Content -Encoding UTF8 (Join-Path $newProjectDir "main.cpp")
}
(Get-Content (Join-Path $newProjectDir "Main.qml") -Encoding UTF8) -replace "{{PROJECT_NAME}}", $Name | Set-Content -Encoding UTF8 (Join-Path $newProjectDir "Main.qml")
if (Test-Path (Join-Path $newProjectDir "package.bat")) {
  (Get-Content (Join-Path $newProjectDir "package.bat") -Encoding UTF8) -replace "{{PROJECT_NAME}}", $Name | Set-Content -Encoding UTF8 (Join-Path $newProjectDir "package.bat")
}
if (-not (Test-Path (Join-Path $newProjectDir "components"))) { New-Item -ItemType Directory -Path (Join-Path $newProjectDir "components") -Force | Out-Null }
Copy-Item -Recurse -Force (Join-Path $repoRoot "..\components\*") (Join-Path $newProjectDir "components")
Copy-Item -Recurse -Force (Join-Path $repoRoot "..\fonts") (Join-Path $newProjectDir "fonts")
Copy-Item -Force (Join-Path $repoRoot "..\src.qrc") (Join-Path $newProjectDir "src.qrc")
Write-Host "Project generated: $newProjectDir"
Write-Host "Build commands:"
Write-Host "cmake -S `"$newProjectDir`" -B `"$newProjectDir\build`""
Write-Host "cmake --build `"$newProjectDir\build`""
Write-Host "Selected template: $Template"
Write-Host ""
Write-Host "Press any key to exit..."
pause

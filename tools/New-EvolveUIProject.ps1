# Double-click to run and enter the project name interactively
param()

$Name = Read-Host "Please enter the project name (required)"
if (-not $Name) {
    Write-Host "Project name cannot be empty. Exiting script."; pause; exit 1
}

$Destination = Read-Host "Please enter the destination directory (default: current directory)"
if (-not $Destination) {
    $Destination = "."
}

$Template = Read-Host "Please enter the template name (default: basic)"
if (-not $Template) {
    $Template = "basic"
}
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$templateRoot = Join-Path $repoRoot "..\scaffold\templates\$Template"
if (-not (Test-Path $templateRoot)) { Write-Error "Template not found: $templateRoot"; pause; exit 1 }
if (-not (Test-Path $Destination)) { New-Item -ItemType Directory -Path $Destination -Force | Out-Null }
$destRoot = (Resolve-Path -LiteralPath $Destination).Path
$newProjectDir = Join-Path $destRoot $Name
if (Test-Path $newProjectDir) { Write-Error "Destination directory already exists: $newProjectDir"; pause; exit 1 }
New-Item -ItemType Directory -Path $newProjectDir | Out-Null
Copy-Item -Recurse -Force (Join-Path $templateRoot "*") $newProjectDir
(Get-Content (Join-Path $newProjectDir "CMakeLists.txt")) -replace "__PROJECT_NAME__", $Name | Set-Content (Join-Path $newProjectDir "CMakeLists.txt")
if (Test-Path (Join-Path $newProjectDir "main.cpp")) {
  (Get-Content (Join-Path $newProjectDir "main.cpp")) -replace "__PROJECT_NAME__", $Name | Set-Content (Join-Path $newProjectDir "main.cpp")
}
(Get-Content (Join-Path $newProjectDir "Main.qml")) -replace "{{PROJECT_NAME}}", $Name | Set-Content (Join-Path $newProjectDir "Main.qml")
(Get-Content (Join-Path $newProjectDir "package.bat")) -replace "{{PROJECT_NAME}}", $Name | Set-Content (Join-Path $newProjectDir "package.bat")
Copy-Item -Recurse -Force (Join-Path $repoRoot "..\components") (Join-Path $newProjectDir "components")
Copy-Item -Recurse -Force (Join-Path $repoRoot "..\fonts") (Join-Path $newProjectDir "fonts")
Copy-Item -Force (Join-Path $repoRoot "..\src.qrc") (Join-Path $newProjectDir "src.qrc")
Write-Host "Project generated: $newProjectDir"
Write-Host "Build commands:"
Write-Host "cmake -S `"$newProjectDir`" -B `"$newProjectDir\build`""
Write-Host "cmake --build `"$newProjectDir\build`""
Write-Host ""
Write-Host "Press any key to exit..."
pause
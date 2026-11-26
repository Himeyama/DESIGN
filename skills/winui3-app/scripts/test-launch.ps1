[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$Project,
    [Parameter(Mandatory)] [string]$ExePath,
    [Parameter(Mandatory)] [string]$ExpectedTitle,
    [string]$Configuration = 'Debug',
    [string]$RuntimeIdentifier,
    [ValidateRange(1, 300)] [int]$WaitSeconds = 10
)

$ErrorActionPreference = 'Stop'

$projectFile = (Resolve-Path -LiteralPath $Project).ProviderPath
$buildArguments = @('build', $projectFile, '--configuration', $Configuration, '--nologo')
if ($RuntimeIdentifier) {
    $buildArguments += @('--runtime', $RuntimeIdentifier)
}

& dotnet @buildArguments
if ($LASTEXITCODE -ne 0) {
    throw "Build failed with exit code $LASTEXITCODE."
}

$executable = (Resolve-Path -LiteralPath $ExePath).ProviderPath
$process = Start-Process -FilePath $executable -WorkingDirectory (Split-Path -Parent $executable) -PassThru
try {
    if ($process.WaitForExit($WaitSeconds * 1000)) {
        throw "App exited before the ${WaitSeconds}s startup check. Exit code: $($process.ExitCode)."
    }

    $process.Refresh()
    if ($process.HasExited) {
        throw "App exited during the startup check. Exit code: $($process.ExitCode)."
    }

    $title = $process.MainWindowTitle
    if ($process.MainWindowHandle -eq [IntPtr]::Zero -or $title -cne $ExpectedTitle) {
        throw "Expected main window title '$ExpectedTitle'. Actual title: '$title'."
    }
    if (-not $process.Responding) {
        throw "Main window '$title' is not responding."
    }

    Write-Output "Startup passed after ${WaitSeconds}s. Main window: '$title'."
}
finally {
    try {
        if (-not $process.HasExited) {
            $process.Kill()
            if (-not $process.WaitForExit(5000)) {
                throw "Test process $($process.Id) did not exit after termination."
            }
        }
    }
    catch [System.InvalidOperationException] {
        if (-not $process.HasExited) {
            throw
        }
    }
    finally {
        $process.Dispose()
    }
}

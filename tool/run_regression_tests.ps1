$ErrorActionPreference = "Stop"

function Run-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name,
        [Parameter(Mandatory = $true)]
        [scriptblock] $Command
    )

    Write-Host ""
    Write-Host "== $Name ==" -ForegroundColor Cyan
    $stepWatch = [System.Diagnostics.Stopwatch]::StartNew()

    & $Command

    $stepWatch.Stop()
    Write-Host "PASS $Name ($($stepWatch.Elapsed.TotalSeconds.ToString('0.00')) s)" -ForegroundColor Green
}

$totalWatch = [System.Diagnostics.Stopwatch]::StartNew()

Run-Step "Shared unit and widget tests" {
    flutter test test\shared
}

Run-Step "Panel logic tests" {
    flutter test test\pregnant test\gynecologist test\dietitian test\admin
}

Run-Step "Form validation tests" {
    flutter test test\form_validation
}

Run-Step "Performance tests" {
    flutter test test\performance
}

Run-Step "Cross-platform consistency tests" {
    flutter test test\cross_platform
}

Run-Step "Stress / data volume tests" {
    flutter test test\stress
}

Run-Step "Web dashboard tests" {
    node --test test\web_dashboard\*.mjs
}

Run-Step "Security rules tests" {
    npm run test:security
}

$totalWatch.Stop()

Write-Host ""
Write-Host "REGRESSION TESTS PASSED ($($totalWatch.Elapsed.TotalSeconds.ToString('0.00')) s)" -ForegroundColor Green
Write-Host ""
Write-Host "Optional live Firebase integration command:"
Write-Host "flutter test integration_test\firebase_smoke_test.dart -d <deviceId> --dart-define=RUN_FIREBASE_INTEGRATION=true"

$ErrorActionPreference = 'Stop'

$testValues = @{
    SCRIBEBA_APP_PASSWORD   = 'TEST_ONLY_APP_PASSWORD'
    SCRIBEBA_SESSION_SECRET = 'TEST_ONLY_SESSION_SECRET_012345678901234567890123456789'
    NEBIUS_API_KEY          = 'TEST_ONLY_NEBIUS_API_KEY'
}
$previousValues = @{}
foreach ($name in $testValues.Keys) {
    $previousValues[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
    [Environment]::SetEnvironmentVariable($name, $testValues[$name], 'Process')
}

$global:LastExitCode = 0
$global:awsDeploymentTempFile = $null
function global:aws {
    $global:LASTEXITCODE = 0
    $command = "$($args[0]) $($args[1])"

    if ($command -eq 'lightsail get-container-services') {
        return '{"containerServices":[{"containerServiceName":"scribeba-prod","url":"https://scribeba.test.invalid"}]}'
    }
    if ($command -eq 'ecr describe-repositories') {
        return '{"repositories":[{"repositoryUri":"000000000000.dkr.ecr.ap-southeast-1.amazonaws.com/scribeba-app"}]}'
    }
    if ($command -eq 'ecr describe-images') {
        return 'sha256:test-only'
    }
    if ($command -eq 'lightsail create-container-service-deployment') {
        $argumentIndex = [Array]::IndexOf($args, '--cli-input-json')
        if ($argumentIndex -lt 0) {
            throw 'The mock deployment call did not use a JSON file.'
        }

        $uri = [string]$args[$argumentIndex + 1]
        $path = ([Uri]$uri).LocalPath
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw 'The temporary deployment payload was not created.'
        }
        $global:awsDeploymentTempFile = $path
        $payload = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        $container = $payload.containers.scribeba
        if ($container.environment.SCRIBEBA_APP_PASSWORD -ne $testValues.SCRIBEBA_APP_PASSWORD -or
            $container.environment.SCRIBEBA_SESSION_SECRET -ne $testValues.SCRIBEBA_SESSION_SECRET -or
            $container.environment.NEBIUS_API_KEY -ne $testValues.NEBIUS_API_KEY) {
            throw 'The deployment payload did not contain the expected test values.'
        }
        if ($payload.publicEndpoint.healthCheck.path -ne '/api/health') {
            throw 'The health check path is incorrect.'
        }
        return
    }

    throw 'Unexpected AWS CLI command in mock test.'
}

try {
    $scriptPath = Join-Path $PSScriptRoot 'deploy-lightsail.ps1'
    $missingSecretsFile = Join-Path ([IO.Path]::GetTempPath()) 'scribeba-test-no-secrets.json'
    & $scriptPath -ImageTag 'test-only' -SecretsFile $missingSecretsFile | Out-Null

    if (-not $global:awsDeploymentTempFile -or (Test-Path -LiteralPath $global:awsDeploymentTempFile)) {
        throw 'The temporary deployment payload was not removed.'
    }

    Write-Output 'Mock deployment payload and temporary-file cleanup passed.'
}
finally {
    foreach ($name in $testValues.Keys) {
        [Environment]::SetEnvironmentVariable($name, $previousValues[$name], 'Process')
    }
    Remove-Item Function:\aws -ErrorAction SilentlyContinue
    Remove-Variable awsDeploymentTempFile -Scope Global -ErrorAction SilentlyContinue
    Remove-Variable LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue
}

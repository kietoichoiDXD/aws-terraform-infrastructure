[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9._-]+$')]
    [string]$ImageTag,

    [string]$Region = 'ap-southeast-1',
    [string]$ServiceName = 'scribeba-prod',
    [string]$RepositoryName = 'scribeba-app',
    [string]$SecretsFile = (Join-Path (Split-Path -Parent $PSScriptRoot) 'deploy-secrets.local.json')
)

$ErrorActionPreference = 'Stop'

$secrets = $null
if (Test-Path -LiteralPath $SecretsFile -PathType Leaf) {
    try {
        $secrets = Get-Content -LiteralPath $SecretsFile -Raw | ConvertFrom-Json
    }
    catch {
        throw 'The local deployment secrets file is not valid JSON.'
    }
}

function Get-DeploymentValue {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Default = ''
    )

    $value = [Environment]::GetEnvironmentVariable($Name, 'Process')
    if (-not [string]::IsNullOrWhiteSpace($value)) {
        return $value
    }

    if ($null -ne $secrets) {
        $property = $secrets.PSObject.Properties[$Name]
        if ($null -ne $property -and -not [string]::IsNullOrWhiteSpace([string]$property.Value)) {
            return [string]$property.Value
        }
    }

    return $Default
}

$appPassword = Get-DeploymentValue 'SCRIBEBA_APP_PASSWORD'
$sessionSecret = Get-DeploymentValue 'SCRIBEBA_SESSION_SECRET'
$nebiusApiKey = Get-DeploymentValue 'NEBIUS_API_KEY'
$nebiusBaseUrl = Get-DeploymentValue 'NEBIUS_BASE_URL' 'https://api.studio.nebius.ai/v1'
$nebiusModel = Get-DeploymentValue 'NEBIUS_MODEL' 'Qwen/Qwen3-30B-A3B'
$allowedOrigin = Get-DeploymentValue 'SCRIBEBA_ALLOWED_ORIGIN'

if ([string]::IsNullOrWhiteSpace($appPassword)) {
    throw 'Set SCRIBEBA_APP_PASSWORD in the process environment or ignored local secrets file.'
}
if ($sessionSecret.Length -lt 32) {
    throw 'SCRIBEBA_SESSION_SECRET must contain at least 32 characters.'
}
if ([string]::IsNullOrWhiteSpace($nebiusApiKey)) {
    throw 'Set NEBIUS_API_KEY in the process environment or ignored local secrets file.'
}

$serviceJson = & aws lightsail get-container-services --region $Region --output json --no-cli-pager 2>$null
if ($LASTEXITCODE -ne 0) {
    throw 'Could not read Lightsail service metadata. Check AWS CLI credentials and region access.'
}
$serviceList = ($serviceJson | ConvertFrom-Json).containerServices
$service = @($serviceList | Where-Object { $_.containerServiceName -eq $ServiceName } | Select-Object -First 1)
if ($service.Count -eq 0) {
    throw 'The Lightsail service does not exist. Create it with Terraform before deploying the app.'
}
if ([string]::IsNullOrWhiteSpace($allowedOrigin)) {
    $allowedOrigin = ([string]$service[0].url).TrimEnd('/')
}
if ($allowedOrigin -notmatch '^https://') {
    throw 'SCRIBEBA_ALLOWED_ORIGIN must be an HTTPS origin.'
}

$repositoryJson = & aws ecr describe-repositories --region $Region --repository-names $RepositoryName --output json --no-cli-pager 2>$null
if ($LASTEXITCODE -ne 0) {
    throw 'Could not read ECR repository metadata. Check AWS CLI permissions.'
}
$repositoryUri = [string](($repositoryJson | ConvertFrom-Json).repositories | Select-Object -First 1 -ExpandProperty repositoryUri)

$imageDigest = & aws ecr describe-images --region $Region --repository-name $RepositoryName --image-ids "imageTag=$ImageTag" --query 'imageDetails[0].imageDigest' --output text --no-cli-pager 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($imageDigest) -or $imageDigest -eq 'None') {
    throw 'The requested immutable image tag was not found in ECR.'
}

$containerEnvironment = @{
    PORT                       = '8000'
    SCRIBEBA_PUBLIC_MODE       = 'true'
    SCRIBEBA_ALLOWED_ORIGIN    = $allowedOrigin
    SCRIBEBA_APP_PASSWORD      = $appPassword
    SCRIBEBA_SESSION_SECRET    = $sessionSecret
    SCRIBEBA_MODE              = 'live'
    NEBIUS_API_KEY             = $nebiusApiKey
    NEBIUS_BASE_URL            = $nebiusBaseUrl
    NEBIUS_MODEL               = $nebiusModel
    SCRIBEBA_COOKIE_SAMESITE   = 'Lax'
}

$deployment = @{
    serviceName = $ServiceName
    containers = @{
        scribeba = @{
            image       = "${repositoryUri}:${ImageTag}"
            ports       = @{ '8000' = 'HTTP' }
            environment = $containerEnvironment
        }
    }
    publicEndpoint = @{
        containerName    = 'scribeba'
        containerPort    = 8000
        healthCheck = @{
            path                = '/api/health'
            successCodes       = '200-299'
            intervalSeconds    = 30
            timeoutSeconds     = 10
            healthyThreshold   = 2
            unhealthyThreshold = 3
        }
    }
}

$tempFile = Join-Path ([IO.Path]::GetTempPath()) ("scribeba-lightsail-deployment-{0}.json" -f [guid]::NewGuid().ToString('N'))
try {
    $json = $deployment | ConvertTo-Json -Depth 12 -Compress
    [IO.File]::WriteAllText($tempFile, $json, [Text.UTF8Encoding]::new($false))
    if ([IO.Path]::DirectorySeparatorChar -eq '\') {
        $payloadUri = 'file:///' + $tempFile.Replace('\', '/')
    }
    else {
        $payloadUri = 'file://' + $tempFile
    }

    & aws lightsail create-container-service-deployment --region $Region --cli-input-json $payloadUri --no-cli-pager 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'Lightsail rejected the deployment request. Check service status and AWS permissions.'
    }
}
finally {
    if (Test-Path -LiteralPath $tempFile -PathType Leaf) {
        [IO.File]::Delete($tempFile)
    }
    $appPassword = $null
    $sessionSecret = $null
    $nebiusApiKey = $null
    $containerEnvironment = $null
    $deployment = $null
    $json = $null
}

Write-Output "Submitted ScribeBA deployment for service $ServiceName using image tag $ImageTag."

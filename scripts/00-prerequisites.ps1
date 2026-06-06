param(
    [string]$ResourceGroupName = "rg-algebra-cloud-project",
    [string]$Location = "francecentral"
)

Write-Host "Checking required tools..." -ForegroundColor Cyan

$tools = @("az", "kubectl", "docker")

foreach ($tool in $tools) {
    $exists = Get-Command $tool -ErrorAction SilentlyContinue
    if (-not $exists) {
        Write-Warning "$tool is not available in PATH."
    } else {
        Write-Host "$tool found." -ForegroundColor Green
    }
}

Write-Host "`nChecking Azure login..." -ForegroundColor Cyan

$account = az account show 2>$null | ConvertFrom-Json

if (-not $account) {
    Write-Host "You are not logged in. Starting az login..."
    az login
    $account = az account show | ConvertFrom-Json
}

Write-Host "Subscription: $($account.name)"
Write-Host "Tenant: $($account.tenantId)"
Write-Host "User: $($account.user.name)"

Write-Host "`nChecking resource group..." -ForegroundColor Cyan

$rgExists = az group exists --name $ResourceGroupName

if ($rgExists -eq "true") {
    Write-Host "Resource group exists: $ResourceGroupName" -ForegroundColor Green
} else {
    Write-Host "Resource group does not exist yet. It will be created by Bicep deployment." -ForegroundColor Yellow
}

Write-Host "`nCurrent public IP:" -ForegroundColor Cyan
try {
    $publicIp = Invoke-RestMethod "https://ifconfig.me"
    Write-Host "$publicIp/32" -ForegroundColor Green
} catch {
    Write-Warning "Could not detect public IP."
}

Write-Host "`nPrerequisite check completed."
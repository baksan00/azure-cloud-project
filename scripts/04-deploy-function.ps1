param(
    [string]$ResourceGroupName = "rg-algebra-cloud-project",
    [string]$FunctionAppFolder = ".\app\function-app",
    [string]$ZipPath = ".\function-app.zip"
)

if (-not (Test-Path $FunctionAppFolder)) {
    throw "Function App folder not found: $FunctionAppFolder"
}

Write-Host "Finding Function App..." -ForegroundColor Cyan

$functionAppName = az functionapp list `
    --resource-group $ResourceGroupName `
    --query "[0].name" `
    --output tsv

if (-not $functionAppName) {
    throw "No Function App found in resource group $ResourceGroupName."
}

Write-Host "Function App: $functionAppName"

Write-Host "Checking runtime settings..." -ForegroundColor Cyan

az functionapp config appsettings set `
    --resource-group $ResourceGroupName `
    --name $functionAppName `
    --settings `
        FUNCTIONS_WORKER_RUNTIME=powershell `
        FUNCTIONS_WORKER_RUNTIME_VERSION=~7

Write-Host "Creating ZIP package..." -ForegroundColor Cyan

if (Test-Path $ZipPath) {
    Remove-Item $ZipPath -Force
}

Push-Location $FunctionAppFolder

Compress-Archive `
    -Path .\* `
    -DestinationPath "..\..\function-app.zip" `
    -Force

Pop-Location

Write-Host "ZIP content:" -ForegroundColor Cyan
tar -tf $ZipPath

Write-Host "Deploying Function App ZIP..." -ForegroundColor Cyan

az functionapp deployment source config-zip `
    --resource-group $ResourceGroupName `
    --name $functionAppName `
    --src $ZipPath

Write-Host "Syncing Function triggers..." -ForegroundColor Cyan

$subscriptionId = az account show --query id -o tsv

az rest `
    --method post `
    --uri "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$functionAppName/syncfunctiontriggers?api-version=2022-03-01"

Write-Host "Restarting Function App..." -ForegroundColor Cyan

az functionapp restart `
    --resource-group $ResourceGroupName `
    --name $functionAppName

Start-Sleep -Seconds 30

Write-Host "Functions:" -ForegroundColor Cyan

az functionapp function list `
    --resource-group $ResourceGroupName `
    --name $functionAppName `
    --query "[].{Name:name,InvokeUrl:invokeUrlTemplate}" `
    --output table

Write-Host "Function deployment completed." -ForegroundColor Green
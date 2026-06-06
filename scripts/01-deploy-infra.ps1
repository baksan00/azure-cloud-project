param(
    [string]$DeploymentName = "main-full-final",
    [string]$Location = "francecentral",
    [string]$TemplateFile = ".\infra\bicep\main.bicep",
    [string]$ParametersFile = ".\infra\bicep\main.parameters.local.json",
    [switch]$WhatIf
)

if (-not (Test-Path $TemplateFile)) {
    throw "Template file not found: $TemplateFile"
}

if (-not (Test-Path $ParametersFile)) {
    throw "Parameters file not found: $ParametersFile"
}

Write-Host "Building Bicep template..." -ForegroundColor Cyan
az bicep build --file $TemplateFile

if ($LASTEXITCODE -ne 0) {
    throw "Bicep build failed."
}

if ($WhatIf) {
    Write-Host "Running what-if deployment..." -ForegroundColor Cyan

    az deployment sub what-if `
        --name "$DeploymentName-whatif" `
        --location $Location `
        --template-file $TemplateFile `
        --parameters "@$ParametersFile"
} else {
    Write-Host "Running deployment..." -ForegroundColor Cyan

    az deployment sub create `
        --name $DeploymentName `
        --location $Location `
        --template-file $TemplateFile `
        --parameters "@$ParametersFile"
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "Infrastructure deployment command completed." -ForegroundColor Green
} else {
    throw "Infrastructure deployment failed."
}
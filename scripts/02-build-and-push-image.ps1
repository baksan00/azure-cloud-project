param(
    [string]$ResourceGroupName = "rg-algebra-cloud-project",
    [string]$ImageName = "aks-sample",
    [string]$ImageTag = "v1",
    [string]$DockerContext = ".\app\aks-sample"
)

if (-not (Test-Path $DockerContext)) {
    throw "Docker context folder not found: $DockerContext"
}

Write-Host "Finding Azure Container Registry..." -ForegroundColor Cyan

$acrName = az acr list `
    --resource-group $ResourceGroupName `
    --query "[0].name" `
    --output tsv

if (-not $acrName) {
    throw "No Azure Container Registry found in resource group $ResourceGroupName."
}

$acrLoginServer = az acr show `
    --name $acrName `
    --query loginServer `
    --output tsv

Write-Host "ACR name: $acrName"
Write-Host "ACR login server: $acrLoginServer"

Write-Host "Logging in to ACR..." -ForegroundColor Cyan
az acr login --name $acrName

Write-Host "Building Docker image..." -ForegroundColor Cyan
docker build -t "${ImageName}:${ImageTag}" $DockerContext

if ($LASTEXITCODE -ne 0) {
    throw "Docker build failed."
}

Write-Host "Tagging Docker image..." -ForegroundColor Cyan
docker tag "${ImageName}:${ImageTag}" "${acrLoginServer}/${ImageName}:${ImageTag}"

Write-Host "Pushing Docker image..." -ForegroundColor Cyan
docker push "${acrLoginServer}/${ImageName}:${ImageTag}"

if ($LASTEXITCODE -ne 0) {
    throw "Docker push failed."
}

Write-Host "Image pushed successfully:" -ForegroundColor Green
Write-Host "${acrLoginServer}/${ImageName}:${ImageTag}"
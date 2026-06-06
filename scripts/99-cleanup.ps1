param(
    [string]$ResourceGroupName = "rg-algebra-cloud-project",
    [switch]$StopAks,
    [switch]$DeallocateJumpVm,
    [switch]$StopFunctionApp,
    [switch]$DeleteApplicationGateway,
    [switch]$DeleteResourceGroup
)

Write-Host "Cleanup script started." -ForegroundColor Cyan

if ($StopAks) {
    Write-Host "Stopping AKS..." -ForegroundColor Yellow

    $aksName = az aks list `
        --resource-group $ResourceGroupName `
        --query "[0].name" `
        --output tsv

    if ($aksName) {
        az aks stop `
            --resource-group $ResourceGroupName `
            --name $aksName
    } else {
        Write-Warning "AKS not found."
    }
}

if ($DeallocateJumpVm) {
    Write-Host "Deallocating Jump VM..." -ForegroundColor Yellow

    $jumpVmName = "vm-jump-win"

    az vm deallocate `
        --resource-group $ResourceGroupName `
        --name $jumpVmName
}

if ($StopFunctionApp) {
    Write-Host "Stopping Function App..." -ForegroundColor Yellow

    $functionAppName = az functionapp list `
        --resource-group $ResourceGroupName `
        --query "[0].name" `
        --output tsv

    if ($functionAppName) {
        az functionapp stop `
            --resource-group $ResourceGroupName `
            --name $functionAppName
    } else {
        Write-Warning "Function App not found."
    }
}

if ($DeleteApplicationGateway) {
    Write-Host "Deleting Application Gateway..." -ForegroundColor Red

    $appgwName = az network application-gateway list `
        --resource-group $ResourceGroupName `
        --query "[0].name" `
        --output tsv

    if ($appgwName) {
        az network application-gateway delete `
            --resource-group $ResourceGroupName `
            --name $appgwName
    } else {
        Write-Warning "Application Gateway not found."
    }

    Write-Host "Deleting Application Gateway public IP if it exists..." -ForegroundColor Red

    az network public-ip delete `
        --resource-group $ResourceGroupName `
        --name pip-appgw 2>$null
}

if ($DeleteResourceGroup) {
    Write-Host "WARNING: This will delete the entire resource group: $ResourceGroupName" -ForegroundColor Red
    $confirmation = Read-Host "Type DELETE to continue"

    if ($confirmation -eq "DELETE") {
        az group delete `
            --name $ResourceGroupName `
            --yes
    } else {
        Write-Host "Resource group deletion cancelled."
    }
}

Write-Host "Cleanup script completed." -ForegroundColor Green
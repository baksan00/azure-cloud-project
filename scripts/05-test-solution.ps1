param(
    [string]$ResourceGroupName = "rg-algebra-cloud-project",
    [string]$FunctionRoute = "functionap"
)

Write-Host "Testing deployed solution..." -ForegroundColor Cyan

Write-Host "`nResource list:" -ForegroundColor Cyan
az resource list `
    --resource-group $ResourceGroupName `
    --query "[].{Name:name,Type:type,Location:location}" `
    --output table

Write-Host "`nAKS test:" -ForegroundColor Cyan

$aksName = az aks list `
    --resource-group $ResourceGroupName `
    --query "[0].name" `
    --output tsv

if ($aksName) {
    az aks get-credentials `
        --resource-group $ResourceGroupName `
        --name $aksName `
        --overwrite-existing | Out-Null

    kubectl get nodes
    kubectl get all -n demo
} else {
    Write-Warning "AKS cluster not found."
}

Write-Host "`nFunction App test:" -ForegroundColor Cyan

$functionHostName = az functionapp list `
    --resource-group $ResourceGroupName `
    --query "[0].defaultHostName" `
    --output tsv

if ($functionHostName) {
    $functionUrl = "https://$functionHostName/$FunctionRoute"
    Write-Host "Testing: $functionUrl"

    try {
        Invoke-RestMethod $functionUrl
    } catch {
        Write-Warning "Function App test failed: $($_.Exception.Message)"
    }
} else {
    Write-Warning "Function App not found."
}

Write-Host "`nApplication Gateway test:" -ForegroundColor Cyan

$appgwPublicIp = az network public-ip show `
    --resource-group $ResourceGroupName `
    --name pip-appgw `
    --query ipAddress `
    --output tsv 2>$null

if ($appgwPublicIp) {
    Write-Host "Application Gateway public IP: $appgwPublicIp"

    Write-Host "Test these URLs in browser because the certificate is self-signed:"
    Write-Host "https://$appgwPublicIp/"
    Write-Host "https://$appgwPublicIp/functionap"
} else {
    Write-Warning "Application Gateway public IP not found."
}

Write-Host "`nPostgreSQL server:" -ForegroundColor Cyan

az postgres flexible-server list `
    --resource-group $ResourceGroupName `
    --query "[].{Name:name,State:state,FQDN:fullyQualifiedDomainName}" `
    --output table

Write-Host "`nSolution test completed." -ForegroundColor Green
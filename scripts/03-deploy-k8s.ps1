param(
    [string]$ResourceGroupName = "rg-algebra-cloud-project",
    [string]$K8sFolder = ".\k8s"
)

if (-not (Test-Path $K8sFolder)) {
    throw "Kubernetes folder not found: $K8sFolder"
}

Write-Host "Finding AKS cluster..." -ForegroundColor Cyan

$aksName = az aks list `
    --resource-group $ResourceGroupName `
    --query "[0].name" `
    --output tsv

if (-not $aksName) {
    throw "No AKS cluster found in resource group $ResourceGroupName."
}

Write-Host "AKS cluster: $aksName"

$powerState = az aks show `
    --resource-group $ResourceGroupName `
    --name $aksName `
    --query "powerState.code" `
    --output tsv

if ($powerState -ne "Running") {
    Write-Host "AKS is not running. Starting AKS..." -ForegroundColor Yellow

    az aks start `
        --resource-group $ResourceGroupName `
        --name $aksName
}

Write-Host "Getting AKS credentials..." -ForegroundColor Cyan

az aks get-credentials `
    --resource-group $ResourceGroupName `
    --name $aksName `
    --overwrite-existing

Write-Host "Applying Kubernetes manifests..." -ForegroundColor Cyan

kubectl apply -f "$K8sFolder\namespace.yaml"
kubectl apply -f "$K8sFolder\deployment.yaml"
kubectl apply -f "$K8sFolder\service.yaml"

Write-Host "`nKubernetes resources:" -ForegroundColor Cyan
kubectl get all -n demo

Write-Host "`nKubernetes deployment completed." -ForegroundColor Green
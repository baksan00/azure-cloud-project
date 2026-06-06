<div align="center">
  <a href="https://github.com/baksan00/azure-cloud-project" target="_blank">
    <img src="docs/Azure.png" width="160" alt="Azure Logo">
  </a>

  <h2> Azure Cloud Project </h2>
</div>


## 💡 Project overview - IaC
This project implements a secure and repeatable Microsoft Azure cloud infrastructure for a multi-tier application.

The solution is deployed with Infrastructure as Code using Azure Bicep. It includes networking, compute, storage, database, identity, security, monitoring, and application routing components.

The main goal of the project is to demonstrate how an Azure environment can be deployed in a structured way, validated through Azure CLI, and documented for auditing and future redeployment.


## ✨ Architecture
- Two virtual networks: Management and Application
- VNET peering between both networks
- Windows Jump VM for private administration
- Azure Kubernetes Service for container workloads
- Azure Function App for serverless HTTP workload
- Azure Container Registry for container images
- Azure Database for PostgreSQL Flexible Server with private access
- Azure Storage Account with Blob Storage and Azure Files
- Azure Key Vault for certificate and secret storage
- Application Gateway with HTTPS routing
- Log Analytics Workspace and Azure Monitor
- Managed identities and role-based access control
  
## ✨ Prerequisites
Required tools:

- Azure subscription
- Azure CLI
- Azure Bicep
- Docker Desktop
- kubectl
- PowerShell
- Git

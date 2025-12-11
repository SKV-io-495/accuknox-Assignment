<#
.SYNOPSIS
    Sets up the DVWA environment on Kubernetes.
.DESCRIPTION
    Updates the secret manifest with a provided (or default) password and applies all Kubernetes manifests.
.PARAMETER Password
    The MySQL root password to set. Defaults to 'dvwa_password_123' if not provided.
#>
# Default to empty to enforce explicit passing or error
param (
    [Parameter(Mandatory=$true)]
    [string]$Password
)

$ErrorActionPreference = "Stop"

Write-Host "Setting up DVWA on Kubernetes..." -ForegroundColor Cyan

# Define paths
$ScriptDir = Split-Path $MyInvocation.MyCommand.Path
$K8sDir = Join-Path $ScriptDir "..\k8s"
$SecretTemplate = Join-Path $K8sDir "01-db-auth.yaml.template"
$SecretFile = Join-Path $K8sDir "01-db-auth.yaml"

# 1. Update Secret File from Template
Write-Host "Generating secrets manifest from template..."
if (Test-Path $SecretTemplate) {
    $TemplateContent = Get-Content $SecretTemplate -Raw
    $SecretContent = $TemplateContent -replace "PASSWORD_PLACEHOLDER", $Password
    $SecretContent | Out-File -FilePath $SecretFile -Encoding UTF8
    Write-Host "Secret manifest generated at $SecretFile" -ForegroundColor Green
} else {
    Write-Error "Template file not found: $SecretTemplate"
}

# 2. Apply Manifests
Write-Host "Applying Kubernetes manifests..."
if (Get-Command kubectl -ErrorAction SilentlyContinue) {
    kubectl apply -f $K8sDir
    Write-Host "Manifests applied successfully." -ForegroundColor Green
    
    Write-Host "`nTo access DVWA, run:" -ForegroundColor Yellow
    Write-Host "minikube service dvwa-service"
} else {
    Write-Host "Error: 'kubectl' command not found. Please install kubectl." -ForegroundColor Red
}

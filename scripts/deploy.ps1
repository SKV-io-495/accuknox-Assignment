<#
.SYNOPSIS
    Automated deployment script for DVWA on Minikube.
.DESCRIPTION
    1. Checks if Minikube is running, starts it if not.
    2. Reads MYSQL_PASSWORD from .env (or prompts if missing).
    3. Updates Kubernetes secrets.
    4. Deploys MySQL and waits for it to be ready.
    5. Deploys DVWA and waits for it to be ready.
    6. Outputs the service URL.
#>

$ErrorActionPreference = "Stop"

# --- Functions ---
function Get-EnvVar {
    param([string]$Path)
    $envVars = @{}
    if (Test-Path $Path) {
        Get-Content $Path | ForEach-Object {
            if ($_ -match "^\s*([^#=]+)\s*=\s*(.*)$") {
                $envVars[$matches[1]] = $matches[2]
            }
        }
    }
    return $envVars
}

# --- Main Script ---

$ScriptDir = Split-Path $MyInvocation.MyCommand.Path
$RootDir = Join-Path $ScriptDir ".."
$EnvFile = Join-Path $RootDir ".env"
$K8sDir = Join-Path $RootDir "k8s"

Write-Host "=== DVWA Deployment Started ===" -ForegroundColor Cyan

# 1. Minikube Status Check
Write-Host "`n[1/5] Checking Minikube status..."
$MinikubeStatus = minikube status --format='{{.Host}}' 2>$null
if ($MinikubeStatus -ne "Running") {
    Write-Host "Minikube is not running. Starting it now..." -ForegroundColor Yellow
    minikube start
    if ($LASTEXITCODE -ne 0) { Write-Error "Failed to start Minikube."; exit 1 }
} else {
    Write-Host "Minikube is running." -ForegroundColor Green
}

# 2. Secret Configuration
Write-Host "`n[2/5] Configuring Secrets..."
$EnvVars = Get-EnvVar -Path $EnvFile
$DbPassword = $EnvVars["MYSQL_PASSWORD"]

if ([string]::IsNullOrWhiteSpace($DbPassword)) {
    Write-Host "Warning: MYSQL_PASSWORD not found in .env" -ForegroundColor Yellow
    $DbPassword = Read-Host "Please enter the MySQL Root Password to use"
    if ([string]::IsNullOrWhiteSpace($DbPassword)) { Write-Error "Password cannot be empty."; exit 1 }
} else {
    Write-Host "Using MYSQL_PASSWORD from .env" -ForegroundColor Green
}

# Run the setup script to update secrets
& "$ScriptDir\setup.ps1" -Password $DbPassword | Out-Null
Write-Host "Secrets manifest updated." -ForegroundColor Green

# 3. Deploy MySQL Backend
Write-Host "`n[3/5] Deploying MySQL Backend..."
kubectl apply -f (Join-Path $K8sDir "02-mysql.yaml")
Write-Host "Waiting for MySQL to be ready..."
kubectl rollout status deployment/mysql-backend --timeout=120s
if ($LASTEXITCODE -ne 0) { Write-Error "MySQL deployment failed to stabilize."; exit 1 }

# 4. Deploy DVWA Frontend
Write-Host "`n[4/5] Deploying DVWA Frontend..."
kubectl apply -f (Join-Path $K8sDir "03-dvwa.yaml")
Write-Host "Waiting for DVWA to be ready..."
kubectl rollout status deployment/dvwa-frontend --timeout=120s
if ($LASTEXITCODE -ne 0) { Write-Error "DVWA deployment failed to stabilize."; exit 1 }

# 5. Access Info
Write-Host "`n[5/5] Deployment Complete!" -ForegroundColor Green
Write-Host "Service URL:"
minikube service dvwa-service --url

Write-Host "`nDeployment finished successfully." -ForegroundColor Cyan

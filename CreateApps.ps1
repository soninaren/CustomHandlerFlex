param(
  [int]$Count = 10,
  [string]$BaseEnv = "nasoniflexenv",
  [string]$BaseRg = "nasonirg-flex",
  [string]$BasePlan = "nasonifuncflexplan",
  [string]$BaseApp = "nasoniflexfuncapp",
  [string]$BaseStorage = "nasoniflexstor",
  [string]$Location = "eastus",
  [string]$TemplateFile = "Bicep/main.bicep",
  # Explicit runtime settings so the CLI never prompts
  [string]$FunctionAppRuntime = "python",
  [string]$FunctionAppRuntimeVersion = "3.12"
)

# Ensure Azure CLI is logged in
if (-not (az account show --only-show-errors 2>$null)) {
  Write-Host "Please run 'az login' first." -ForegroundColor Yellow
  exit 1
}

for ($i = 1; $i -le $Count; $i++) {
  $suffix = "{0:D2}" -f $i

  $environmentName   = "$BaseEnv$suffix"
  $resourceGroupName = "$BaseRg$suffix"
  $functionPlanName  = "$BasePlan$suffix"
  $functionAppName   = "$BaseApp$suffix"
  # Storage account: max 24 chars, lowercase, must be unique globally
  $rawStorage = "$BaseStorage$suffix"
  $storageAccountName = $rawStorage.ToLower()
  if ($storageAccountName.Length -gt 24) {
    throw "Storage account name '$storageAccountName' exceeds 24 characters. Shorten BaseStorage."
  }

  $deploymentName = "multi-$suffix"

  Write-Host "=== Deploying set $suffix ===" -ForegroundColor Cyan
  Write-Host "Env: $environmentName"
  Write-Host "RG : $resourceGroupName"
  Write-Host "Plan: $functionPlanName"
  Write-Host "App : $functionAppName"
  Write-Host "Stor: $storageAccountName"
  
  az deployment sub create `
    --name $deploymentName `
    --location $Location `
    --template-file $TemplateFile `
    --parameters `
  location=$Location `
      environmentName=$environmentName `
      resourceGroupName=$resourceGroupName `
      functionPlanName=$functionPlanName `
      functionAppName=$functionAppName `
  storageAccountName=$storageAccountName `
  functionAppRuntime=$FunctionAppRuntime `
  functionAppRuntimeVersion=$FunctionAppRuntimeVersion `
    --only-show-errors

  if ($LASTEXITCODE -ne 0) {
    Write-Host "Deployment $deploymentName failed. Halting." -ForegroundColor Red
    break
  } else {
    Write-Host "Deployment $deploymentName succeeded." -ForegroundColor Green
  }
}

Write-Host "All done."
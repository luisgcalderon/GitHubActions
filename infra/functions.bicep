param location string = resourceGroup().location

@description('Function app runtime version. Example: 8 (for dotnet-isolated)')
param functionAppRuntimeVersion string = '3.14'

@description('Blob container used by Function app deployment storage configuration')
param functionsDeploymentContainerName string = 'functions-deployment'
resource FuncStorage 'Microsoft.Storage/storageAccounts@2026-04-01' = {
  name: 'dvccfuncstg'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}
resource funcDepContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2026-04-01' = {
  name: '${FuncStorage.name}/default/${functionsDeploymentContainerName}'
}

resource appServicePlan 'Microsoft.Web/serverfarms@2025-03-01' = {
  name: 'dvccfuncappplan'
  location: location
  kind: 'functionapp'
  sku: {
    tier: 'FlexConsumption'
    name: 'FC1'
  }
  properties: {
    reserved: true
  }
}

var functionsContainerUrl = 'https://${FuncStorage.name}.blob.${environment().suffixes.storage}/${functionsDeploymentContainerName}'
var deploymentConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${FuncStorage.name};AccountKey=${FuncStorage.listKeys().keys[0].value};BlobEndpoint=${functionsContainerUrl}'
output url string = functionsContainerUrl
resource azureFunction 'Microsoft.Web/sites@2025-03-01' = {
  name: 'dvccfuncapp'
  location: location
  kind: 'functionapp,linux'
  properties: {
    serverFarmId: appServicePlan.id
    functionAppConfig: {
      deployment: {
        storage: {
          authentication: {
            type: 'StorageAccountConnectionString'
            storageAccountConnectionStringName: 'DEPLOYMENT_CONNECTION'
          }
          type: 'blobContainer'
          value: functionsContainerUrl
        }
      }
      scaleAndConcurrency: {
        instanceMemoryMB: 512
        maximumInstanceCount: 5
      }
      runtime: {
        name: 'python'
        version: functionAppRuntimeVersion
      }
    }
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${FuncStorage.name};AccountKey=${FuncStorage.listKeys().keys[0].value}'
        }
        {
          name: 'DEPLOYMENT_CONNECTION'
          value: deploymentConnectionString
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
      ]
    }
  }
}

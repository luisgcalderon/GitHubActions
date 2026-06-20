param location string = resourceGroup().location

resource FuncStorage 'Microsoft.Storage/storageAccounts@2026-04-01' = {
  name: 'dvccfuncstg'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
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

resource azureFunction 'Microsoft.Web/sites@2025-03-01' = {
  name: 'dvccfuncapp'
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    functionAppConfig: {
      deployment: {
        storage: {
          authentication: {
            storageAccountConnectionStringName: 'AzureWebJobsStorage'
            type: 'StorageAccountConnectionString'
          }
          type: 'blobContainer'
          value: 'dvccfuncapp'
        }
      }
      scaleAndConcurrency: {
        instanceMemoryMB: 512
        maximumInstanceCount: 5
      }
      runtime: {
        name: 'python'
        version: '3.14'
      }
    }
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${FuncStorage.name};AccountKey=${FuncStorage.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
      ]
    }
  }
}

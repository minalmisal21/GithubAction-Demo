param environmentAcronym string
param clientIdentifier string
param location string = resourceGroup().location
param locationAcronym string = 'ae'
param tagValues object
param storageSkuName string = 'Standard_RAGRS'

var storageAccount = '${clientIdentifier}${locationAcronym}sabc${environmentAcronym}'
var internalTags = {
  Purpose: 'Azure storage account'
}
var tags = union(tagValues, internalTags)

resource storage 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccount
  location: location
  tags: tags
  sku: {
    name: storageSkuName
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
  }
}

resource storage_blob_default 'Microsoft.Storage/storageAccounts/blobServices@2022-05-01' = {
  parent: storage
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: false
    }
  }
}

resource storage_table_default 'Microsoft.Storage/storageAccounts/tableServices@2021-09-01' = {
  name: 'default'
  parent: storage
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource storage_table_BCErrorType 'Microsoft.Storage/storageAccounts/tableServices/tables@2021-09-01' = {
  parent: storage_table_default
  name: 'BCErrorType'
  properties: {}
}

resource storage_table_BCIntegrationEmail 'Microsoft.Storage/storageAccounts/tableServices/tables@2021-09-01' = {
  parent: storage_table_default
  name: 'BCIntegrationEmail'
  properties: {}
}

resource storage_table_BCIntegrationLog 'Microsoft.Storage/storageAccounts/tableServices/tables@2021-09-01' = {
  parent: storage_table_default
  name: 'BCIntegrationLog'
  properties: {}
}


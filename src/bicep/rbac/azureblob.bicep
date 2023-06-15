param environmentAcronym string
param locationAcronym string = 'ae'
param clientIdentifier string

var storageAccount = '${clientIdentifier}${locationAcronym}sabc${environmentAcronym}'
var logicAppBCConnectorSBBC = '${clientIdentifier}-${locationAcronym}-la-bcconnector-sb-bc-${environmentAcronym}'

resource ref_storageaccount 'Microsoft.Storage/storageAccounts@2022-05-01' existing = {
  name: storageAccount
}

resource ref_la_bcconnector_sb_bc 'Microsoft.Logic/workflows@2019-05-01' existing = {
  name: logicAppBCConnectorSBBC
}

@description('This is the built-in Storage Blob Data Contributor role. See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#StorageBlobDataContributorRole')
resource storageBlobDataContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

resource azblobroleassignment_1 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, ref_la_bcconnector_sb_bc.name, storageBlobDataContributorRoleDefinition.id)
  scope: ref_storageaccount
  properties: {
    roleDefinitionId: storageBlobDataContributorRoleDefinition.id
    principalId: ref_la_bcconnector_sb_bc.identity.principalId
    principalType: 'ServicePrincipal'
  }
}


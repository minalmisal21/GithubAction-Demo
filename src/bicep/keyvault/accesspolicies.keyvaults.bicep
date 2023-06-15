param environmentAcronym string
param locationAcronym string = 'ae'
param clientIdentifier string

var keyvaultName = '${clientIdentifier}-${locationAcronym}-kv-${environmentAcronym}'
var logicAppPostToIntegrationFramework = '${clientIdentifier}-${locationAcronym}-la-post-integration-framework-${environmentAcronym}'
var logicAppSBConnectorBCSB = '${clientIdentifier}-${locationAcronym}-la-sbconnector-bc-sb-${environmentAcronym}'


resource ref_la_sbconnector_bc_sb 'Microsoft.Logic/workflows@2019-05-01' existing = {
  name: logicAppSBConnectorBCSB
}
resource ref_la_post_integration_framework 'Microsoft.Logic/workflows@2019-05-01' existing = {
  name: logicAppPostToIntegrationFramework
}

resource keyVault_add_accesspolicy 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  name: '${keyvaultName}/add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: ref_la_sbconnector_bc_sb.identity.principalId
        permissions: {
          secrets: [
            'Get'
            'List'
          ]
        }
      }
      {
        tenantId: subscription().tenantId
        objectId: ref_la_post_integration_framework.identity.principalId
        permissions: {
          secrets: [
            'Get'
            'List'
          ]
        }
      }
      {
        tenantId: subscription().tenantId
        objectId: ref_la_post_integration_framework.identity.principalId
        permissions: {
          secrets: [
            'Get'
            'List'
          ]
        }
      }
    ]
  }
}

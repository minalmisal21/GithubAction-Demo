param environmentAcronym string
param location string = resourceGroup().location
param locationAcronym string = 'ae'
param tagValues object
param logicAppState string = 'Enabled'
param clientIdentifier string
param BCIntegrationFrameworkApiEndpoint string

var logicAppName = '${clientIdentifier}-${locationAcronym}-la-post-integration-framework-${environmentAcronym}'
var logAnalyticsWorkspaceName = '${clientIdentifier}-${locationAcronym}-log-${environmentAcronym}'
var internalTags = {
  Purpose: ''
}
var tags = union(tagValues, internalTags)

resource ref_apiconnection_keyvault 'Microsoft.Web/connections@2016-06-01' existing = {
  name: 'keyvault'
}


resource resource_logicapp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: logicAppState
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
        BCIntegrationFrameworkApiEndpoint: {
          defaultValue: BCIntegrationFrameworkApiEndpoint
          type: 'String'
        }
      }
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {
            }
          }
        }
      }
      actions: {
        Get_BCOAuthClientID: {
          runAfter: {
            Get_BCOAuthTenantID: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'keyvault\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/secrets/@{encodeURIComponent(\'bcOAuthClientID\')}/value'
          }
        }
        Get_BCOAuthSecret: {
          runAfter: {
            Get_BCOAuthClientID: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'keyvault\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/secrets/@{encodeURIComponent(\'bcOAuthSecret\')}/value'
          }
        }
        Get_BCOAuthTenantID: {
          runAfter: {}
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'keyvault\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/secrets/@{encodeURIComponent(\'bcOAuthTenantID\')}/value'
          }
        }
        HTTP_Post_to_IF: {
          runAfter: {
            Get_BCOAuthSecret: [
              'Succeeded'
            ]
          }
          type: 'Http'
          inputs: {
            authentication: {
              audience: 'https://api.businesscentral.dynamics.com'
              clientId: '@body(\'Get_BCOAuthClientID\')?[\'value\']'
              secret: '@body(\'Get_BCOAuthSecret\')?[\'value\']'
              tenant: '@body(\'Get_BCOAuthTenantID\')?[\'value\']'
              type: 'ActiveDirectoryOAuth'
            }
            body: '@triggerBody()'
            method: 'POST'
            uri: '@parameters(\'BCIntegrationFrameworkApiEndpoint\')'
          }
        }
        Response: {
          runAfter: {
            HTTP_Post_to_IF: [
              'Succeeded'
              'Failed'
              'Skipped'
              'TimedOut'
            ]
          }
          type: 'Response'
          kind: 'Http'
          inputs: {
            body: '@body(\'HTTP_Post_to_IF\')'
            statusCode: '@outputs(\'HTTP_Post_to_IF\')[\'statusCode\']'
          }
        }
      }
      outputs: {
      }
    }
    parameters: {
      '$connections': {
        value: {
          keyvault: {
            connectionId: ref_apiconnection_keyvault.id
            connectionName: 'keyvault'
            connectionProperties: {
              authentication: {
                type: 'ManagedServiceIdentity'
              }
            }
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/keyvault'
          }
        }
      }
    }
  }
}

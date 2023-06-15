param environmentAcronym string
param location string = resourceGroup().location
param locationAcronym string = 'ae'
param tagValues object
param logicAppState string = 'Enabled'
param clientIdentifier string

var defaultErrorType = '250'
var defaultErrorCategory = 'default'
var internalTags = {
  Purpose: 'Handles requests for error configuration details based on the error type'
}
var tags = union(tagValues, internalTags)
var logicAppName = '${clientIdentifier}-${locationAcronym}-la-error-configuration-details-${environmentAcronym}'
var logAnalyticsWorkspaceName = '${clientIdentifier}-${locationAcronym}-log-${environmentAcronym}'

resource ref_apiconnection_azuretables 'Microsoft.Web/connections@2016-06-01' existing = {
  name: 'azuretables'
}

resource resource_logicapp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  tags: tags
  properties: {
    state: logicAppState
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {
          }
          type: 'Object'
        }
      }
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {
              properties: {
                error: {
                  properties: {
                    code: {
                      type: 'string'
                    }
                    message: {
                      type: 'string'
                    }
                  }
                  type: 'object'
                }
              }
              type: 'object'
            }
          }
        }
      }
      actions: {
        Initialize_ErrorCategory: {
          runAfter: {
            Initialize_ErrorType: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'ErrorCategory'
                type: 'string'
                value: defaultErrorCategory
              }
            ]
          }
        }
        Initialize_ErrorType: {
          runAfter: {
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'ErrorType'
                type: 'string'
                value: defaultErrorType
              }
            ]
          }
        }
        Response: {
          runAfter: {
            Scope: [
              'Succeeded'
              'Failed'
              'Skipped'
              'TimedOut'
            ]
          }
          type: 'Response'
          kind: 'Http'
          inputs: {
            body: {
              errorCategory: '@variables(\'ErrorCategory\')'
              errorType: '@variables(\'ErrorType\')'
            }
            statusCode: '@variables(\'ErrorType\')'
          }
        }
        Scope: {
          actions: {
            Filter_array: {
              runAfter: {
                Get_Error_Type_Array: [
                  'Succeeded'
                ]
              }
              type: 'Query'
              inputs: {
                from: '@body(\'Get_Error_Type_Array\')?[\'value\']'
                where: '@contains(triggerBody()?[\'error\']?[\'message\'], item()?[\'ErrorMessage\'])'
              }
            }
            For_each_ErrorType_Array: {
              foreach: '@body(\'Filter_array\')'
              actions: {
                Set_ErrorCategory: {
                  runAfter: {
                    Set_ErrorType: [
                      'Succeeded'
                    ]
                  }
                  type: 'SetVariable'
                  inputs: {
                    name: 'ErrorCategory'
                    value: '@items(\'For_each_ErrorType_Array\')?[\'PartitionKey\']'
                  }
                }
                Set_ErrorType: {
                  runAfter: {
                  }
                  type: 'SetVariable'
                  inputs: {
                    name: 'ErrorType'
                    value: '@{items(\'For_each_ErrorType_Array\')?[\'ErrorNumber\']}'
                  }
                }
              }
              runAfter: {
                Filter_array: [
                  'Succeeded'
                ]
              }
              type: 'Foreach'
            }
            Get_Error_Type_Array: {
              runAfter: {
              }
              type: 'ApiConnection'
              inputs: {
                host: {
                  connection: {
                    name: '@parameters(\'$connections\')[\'azuretables\'][\'connectionId\']'
                  }
                }
                method: 'get'
                path: '/Tables/@{encodeURIComponent(\'bcErrorType\')}/entities'
              }
            }
          }
          runAfter: {
            Initialize_ErrorCategory: [
              'Succeeded'
            ]
          }
          type: 'Scope'
        }
      }
      outputs: {
      }
    }
    parameters: {
      '$connections': {
        value: {
          azuretables: {
            connectionId: ref_apiconnection_azuretables.id
            connectionName: 'azuretables'
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/azuretables'
          }
        }
      }
    }
  }
}

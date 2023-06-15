param environmentAcronym string
param location string = resourceGroup().location
param locationAcronym string = 'ae'
param tagValues object
param logicAppState string = 'Enabled'
param clientIdentifier string

var logicAppName = '${clientIdentifier}-${locationAcronym}-la-post-sbtopic-${environmentAcronym}'
var logAnalyticsWorkspaceName = '${clientIdentifier}-${locationAcronym}-log-${environmentAcronym}'
var internalTags = {
  Purpose: 'handles requests and post them to a service bus topic'
}
var tags = union(tagValues, internalTags)

resource ref_apiconnection_servicebus 'Microsoft.Web/connections@2016-06-01' existing = {
  name: 'servicebus'
}

resource resource_logicapp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
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
                content: {
                  type: 'string'
                }
                contentInBlob: {
                  type: 'string'
                }
                correlationID: {
                  type: 'string'
                }
                dataVersion: {
                  type: 'string'
                }
                destination: {
                  type: 'string'
                }
                direction: {
                  type: 'string'
                }
                errorCategory: {
                  type: 'string'
                }
                errorCode: {
                  type: 'string'
                }
                errorEvent: {
                  type: 'string'
                }
                errorMessage: {
                  type: 'string'
                }
                messageType: {
                  type: 'string'
                }
                originalSubscriber: {
                  type: 'string'
                }
                partnerReference: {
                  type: 'string'
                }
                source: {
                  type: 'string'
                }
                subscriber: {
                  type: 'string'
                }
                topic: {
                  type: 'string'
                }
              }
              type: 'object'
            }
          }
        }
      }
      actions: {
        Initialize_messageTime: {
          runAfter: {
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'messageTime'
                type: 'string'
                value: '@{formatDateTime(convertFromUtc(utcNow(),\'New Zealand Standard Time\'), \'yyyy-MM-dd HH:mm:ss\')}'
              }
            ]
          }
        }
        Response: {
          runAfter: {
            Send_message: [
              'Succeeded'
            ]
          }
          type: 'Response'
          kind: 'Http'
          inputs: {
            statusCode: 200
          }
        }
        Send_message: {
          runAfter: {
            Initialize_messageTime: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            body: {
              ContentData: '@{base64(triggerBody()?[\'content\'])}'
              ContentType: 'application/json'
              Properties: {
                contentInBlob: '@triggerBody()?[\'contentInBlob\']'
                correlationID: '@triggerBody()?[\'correlationID\']'
                dataVersion: '@triggerBody()?[\'dataVersion\']'
                destination: '@triggerBody()?[\'destination\']'
                direction: '@triggerBody()?[\'direction\']'
                errorCategory: '@triggerBody()?[\'errorCategory\']'
                errorCode: '@triggerBody()?[\'errorCode\']'
                errorEvent: '@triggerBody()?[\'errorEvent\']'
                errorMessage: '@triggerBody()?[\'errorMessage\']'
                messageTime: '@variables(\'messageTime\')'
                messageType: '@triggerBody()?[\'messageType\']'
                originalSubscriber: '@triggerBody()?[\'originalSubscriber\']'
                partnerReference: '@triggerBody()?[\'partnerReference\']'
                source: '@triggerBody()?[\'source\']'
                subscriber: '@triggerBody()?[\'subscriber\']'
                topic: '@triggerBody()?[\'topic\']'
              }
              SessionId: '@{guid()}'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'servicebus\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/@{encodeURIComponent(encodeURIComponent(triggerBody()?[\'topic\']))}/messages'
            queries: {
              systemProperties: 'Run Details'
            }
          }
        }
      }
      outputs: {
      }
    }
    parameters: {
      '$connections': {
        value: {
          servicebus: {
            connectionId: ref_apiconnection_servicebus.id
            connectionName: 'servicebus'
            connectionProperties: {
              authentication: {
                type: 'ManagedServiceIdentity'
              }
            }
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/servicebus'
          }
        }
      }
    }
  }
}

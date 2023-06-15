param environmentAcronym string
param location string = resourceGroup().location
param locationAcronym string = 'ae'
param tagValues object
param logicAppState string = 'Enabled'
param clientIdentifier string
param BCEnvironment string
param isProduction bool


var nullBodyErrorCode = '253'
var nullBodyMessage = 'Please fill in the Body message.'
var logicAppName = '${clientIdentifier}-${locationAcronym}-la-sbconnector-bc-sb-${environmentAcronym}'
var logicAppPostToServiceBusTopic = '${clientIdentifier}-${locationAcronym}-la-post-sbtopic-${environmentAcronym}'
var logicAppErrorConfigurationDetails = '${clientIdentifier}-${locationAcronym}-la-error-configuration-details-${environmentAcronym}'
var logAnalyticsWorkspaceName = '${clientIdentifier}-${locationAcronym}-log-${environmentAcronym}'
var internalTags = {
  Purpose: 'TBD'
}
var tags = union(tagValues, internalTags)


resource ref_la_post_sbtopic 'Microsoft.Logic/workflows@2019-05-01' existing = {
  name: logicAppPostToServiceBusTopic
}

resource ref_la_error_configuration_details 'Microsoft.Logic/workflows@2019-05-01' existing = {
  name: logicAppErrorConfigurationDetails
}
resource ref_apiconnection_keyvault 'Microsoft.Web/connections@2016-06-01' existing = {
  name: 'keyvault'
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
        BCEnvironment: {
          defaultValue: BCEnvironment
          type: 'String'
        }
        isProduction: {
          defaultValue: isProduction
          type: 'Bool'
        }
      }
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {
              properties: {
                bodytext: {
                  type: 'string'
                }
                correlationid: {
                  type: 'string'
                }
                destination: {
                  type: 'string'
                }
                direction: {
                  type: 'string'
                }
                entryno: {
                  type: 'integer'
                }
                errortext: {
                  type: 'string'
                }
                messagemype: {
                  type: 'string'
                }
                source: {
                  type: 'string'
                }
                statusws: {
                  type: 'string'
                }
                version: {
                  type: 'integer'
                }
              }
              type: 'object'
            }
          }
        }
      }
      actions: {
        Check_Null_Body: {
          actions: {
            Terminate: {
              runAfter: {
              }
              type: 'Terminate'
              inputs: {
                runError: {
                  code: nullBodyErrorCode
                  message: nullBodyMessage
                }
                runStatus: 'Failed'
              }
            }
          }
          runAfter: {
            Filter_Scope_Result: [
              'Succeeded'
            ]
          }
          expression: {
            and: [
              {
                equals: [
                  '@triggerBody()'
                  '@null'
                ]
              }
            ]
          }
          type: 'If'
        }
        Filter_Scope_Result: {
          runAfter: {
            Scope: [
              'Failed'
            ]
          }
          type: 'Query'
          inputs: {
            from: '@result(\'Scope\')'
            where: '@equals(item()[\'status\'], \'Failed\')'
          }
        }
        Get_bcIFSecret: {
          runAfter: {
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'keyvault\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/secrets/@{encodeURIComponent(\'bcIFSecret\')}/value'
          }
        }
        Initialize_ErrorMessage: {
          runAfter: {
            Check_Null_Body: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'ErrorMessage'
                type: 'string'
                value: '@{if(\r\n  contains(\r\n    first(body(\'Filter_Scope_Result\')),\'error\'),\r\n  first(body(\'Filter_Scope_Result\'))?[\'error\']?[\'message\'],\r\n  if(\r\n    contains(first(body(\'Filter_Scope_Result\'))?[\'outputs\']?[\'body\'],\'error\'),\r\n    first(body(\'Filter_Scope_Result\'))?[\'outputs\']?[\'body\']?[\'error\']?[\'message\'],\r\n    if(contains(first(body(\'Filter_Scope_Result\'))?[\'outputs\']?[\'body\'],\'Failed\'),first(body(\'Filter_Scope_Result\'))?[\'outputs\']?[\'body\'],\r\n\tfirst(body(\'Filter_Scope_Result\'))?[\'outputs\']?[\'body\'])\r\n\t))}'
              }
            ]
          }
        }
        Scope: {
          actions: {
            For_each: {
              foreach: '@body(\'Parse_TriggerBody\')'
              actions: {
                Condition_Check_Environment: {
                  actions: {
                    '${logicAppPostToServiceBusTopic}': {
                      runAfter: {
                      }
                      type: 'Workflow'
                      inputs: {
                        body: {
                          content: '@items(\'For_each\')?[\'data\']?[\'details\']'
                          contentInBlob: 'false'
                          correlationID: '@items(\'For_each\')?[\'data\']?[\'correlationid\']'
                          dataVersion: '@{items(\'For_each\')[\'dataversion\']}'
                          destination: '@items(\'For_each\')?[\'data\']?[\'destination\']'
                          direction: 'Outbound'
                          messageType: '@items(\'For_each\')[\'eventType\']'
                          source: '@items(\'For_each\')?[\'data\']?[\'source\']'
                          subscriber: '@items(\'For_each\')[\'subject\']'
                          topic: '@items(\'For_each\')[\'topic\']'
                        }
                        host: {
                          triggerName: 'manual'
                          workflow: {
                            id:ref_la_post_sbtopic.id
                          }
                        }
                      }
                    }
                  }
                  runAfter: {
                  }
                  expression: {
                    and: [
                      {
                        equals: [
                          '@items(\'For_each\')[\'environment\']'
                          '@parameters(\'BCEnvironment\')'
                        ]
                      }
                      {
                        equals: [
                          '@items(\'For_each\')[\'isproduction\']'
                          '@parameters(\'isProduction\')'
                        ]
                      }
                      {
                        equals: [
                          '@triggerOutputs()[\'headers\'][\'IFSecret\']'
                          '@body(\'Get_bcIFSecret\')?[\'value\']'
                        ]
                      }
                    ]
                  }
                  type: 'If'
                }
              }
              runAfter: {
                Parse_TriggerBody: [
                  'Succeeded'
                ]
              }
              type: 'Foreach'
            }
            Parse_TriggerBody: {
              runAfter: {
              }
              type: 'ParseJson'
              inputs: {
                content: '@triggerBody()'
                schema: {
                  items: {
                    properties: {
                      data: {
                        properties: {
                          correlationid: {
                            type: 'string'
                          }
                          destination: {
                            type: 'string'
                          }
                          details: {
                            type: 'string'
                          }
                          source: {
                            type: 'string'
                          }
                        }
                        type: 'object'
                      }
                      dataversion: {
                        type: 'integer'
                      }
                      environment: {
                        type: 'string'
                      }
                      eventTime: {
                        type: 'string'
                      }
                      eventType: {
                        type: 'string'
                      }
                      id: {
                        type: 'string'
                      }
                      isproduction: {
                        type: 'string'
                      }
                      subject: {
                        type: 'string'
                      }
                      tenant: {
                        type: 'string'
                      }
                      topic: {
                        type: 'string'
                      }
                    }
                    required: [
                      'id'
                      'tenant'
                      'environment'
                      'isproduction'
                      'topic'
                      'eventType'
                      'subject'
                      'eventTime'
                      'data'
                      'dataversion'
                    ]
                    type: 'object'
                  }
                  type: 'array'
                }
              }
            }
          }
          runAfter: {
            Get_bcIFSecret: [
              'Succeeded'
            ]
          }
          type: 'Scope'
        }
        '${logicAppErrorConfigurationDetails}': {
          runAfter: {
            Initialize_ErrorMessage: [
              'Succeeded'
            ]
          }
          type: 'Workflow'
          inputs: {
            body: {
              error: {
                code: 'Service Bus Connector Error'
                message: '@variables(\'ErrorMessage\')'
              }
            }
            host: {
              triggerName: 'manual'
              workflow: {
                id: ref_la_error_configuration_details.id
              }
            }
          }
        }
        '${logicAppPostToServiceBusTopic}_first_failure_only': {
          runAfter: {
            '${logicAppErrorConfigurationDetails}': [
              'Succeeded'
            ]
          }
          type: 'Workflow'
          inputs: {
            body: {
              content: '@{if(\r\n  contains(\r\n    first(body(\'Parse_TriggerBody\')),\'content\'),\r\n  first(body(\'Parse_TriggerBody\'))?[\'content\'],\r\n  \'\')}'
              contentInBlob: '@{if(\r\n  contains(\r\n    first(body(\'Parse_TriggerBody\')),\'contentInBlob\'),\r\n  first(body(\'Parse_TriggerBody\'))?[\'contentInBlob\'],\r\n  \'\')}'
              correlationID: '@{if(\r\n  contains(\r\n    first(body(\'Parse_TriggerBody\')),\'correlationID\'),\r\n  first(body(\'Parse_TriggerBody\'))?[\'correlationID\'],\r\n  \'\')}'
              dataVersion: '@{if(\r\n  contains(\r\n    first(body(\'Parse_TriggerBody\')),\'dataVersion\'),\r\n  first(body(\'Parse_TriggerBody\'))?[\'dataVersion\'],\r\n  \'\')}'
              destination: '@{if(\r\n  contains(\r\n    first(body(\'Parse_TriggerBody\')),\'destination\'),\r\n  first(body(\'Parse_TriggerBody\'))?[\'destination\'],\r\n  \'\')}'
              direction: '@{if(\r\n  contains(\r\n    first(body(\'Parse_TriggerBody\')),\'direction\'),\r\n  first(body(\'Parse_TriggerBody\'))?[\'direction\'],\r\n  \'\')}'
              errorCategory: '@{body(\'${logicAppErrorConfigurationDetails}\')[\'errorCategory\']}'
              errorCode: '@{body(\'${logicAppErrorConfigurationDetails}\')[\'errorCode\']}'
              errorEvent: logicAppName
              errorMessage: '@variables(\'ErrorMessage\')'
              messageType: '@{if(\r\n  contains(\r\n    first(body(\'Parse_TriggerBody\')),\'messageType\'),\r\n  first(body(\'Parse_TriggerBody\'))?[\'messageType\'],\r\n  \'\')}'
              originalSubscriber: '@{if(\r\n  contains(\r\n    first(body(\'Parse_TriggerBody\')),\'subject\'),\r\n  first(body(\'Parse_TriggerBody\'))?[\'subject\'],\r\n  \'\')}'
              source: '@{if(\r\n  contains(\r\n    first(body(\'Parse_TriggerBody\')),\'source\'),\r\n  first(body(\'Parse_TriggerBody\'))?[\'source\'],\r\n  \'\')}'
              subscriber: 'errorQueue'
              topic: '@{if(\r\n  contains(\r\n    first(body(\'Parse_TriggerBody\')),\'topic\'),\r\n  first(body(\'Parse_TriggerBody\'))?[\'topic\'],\r\n  \'\')}'
            }
            host: {
              triggerName: 'manual'
              workflow: {
                id: ref_la_post_sbtopic.id
              }
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

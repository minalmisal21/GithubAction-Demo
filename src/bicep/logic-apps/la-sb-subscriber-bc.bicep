param environmentAcronym string
param location string = resourceGroup().location
param locationAcronym string = 'ae'
param tagValues object
param logicAppState string = 'Enabled'
param clientIdentifier string

var logicAppName = '${clientIdentifier}-${locationAcronym}-la-sb-subscriber-bc-${environmentAcronym}'
var logicAppPostToServiceBusTopic = '${clientIdentifier}-${locationAcronym}-la-post-sbtopic-${environmentAcronym}'
var logicAppPostToIntegrationFramework = '${clientIdentifier}-${locationAcronym}-la-post-integration-framework-${environmentAcronym}'
var logicAppErrorConfigurationDetails = '${clientIdentifier}-${locationAcronym}-la-error-configuration-details-${environmentAcronym}'
var logAnalyticsWorkspaceName = '${clientIdentifier}-${locationAcronym}-log-${environmentAcronym}'
var internalTags = {
  Purpose: ''
}
var tags = union(tagValues, internalTags)
var errorQueueSubscriber = 'errorQueue'
var noOfAttempt = 10
var successFlag = (noOfAttempt + 1)
var delayMinute = 1
var untilExpression = '@greater(variables(\'NoOfAttempt\'),${noOfAttempt})'

resource ref_la_post_integration_framework 'Microsoft.Logic/workflows@2019-05-01' existing = {
  name: logicAppPostToIntegrationFramework
}
resource ref_la_post_sbtopic 'Microsoft.Logic/workflows@2019-05-01' existing = {
  name: logicAppPostToServiceBusTopic
}
resource ref_la_error_configuration_details 'Microsoft.Logic/workflows@2019-05-01' existing = {
  name: logicAppErrorConfigurationDetails
}


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
        'When_one_or_more_messages_arrive_in_a_topic_(auto-complete)': {
          recurrence: {
            frequency: 'Minute'
            interval: 3
          }
          evaluatedRecurrence: {
            frequency: 'Minute'
            interval: 3
          }
          splitOn: '@triggerBody()'
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'servicebus\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/@{encodeURIComponent(encodeURIComponent(\'bcintegration\'))}/subscriptions/@{encodeURIComponent(\'businessCentral\')}/messages/batch/head'
            queries: {
              maxMessageCount: 20
              sessionId: 'None'
              subscriptionType: 'Main'
            }
          }
          runtimeConfiguration: {
            concurrency: {
              runs: 5
            }
          }
        }
      }
      actions: {
        Filter_Scope_Result: {
          runAfter: {
            Scope: [
              'Failed'
            ]
          }
          type: 'Query'
          inputs: {
            from: '@result(\'Until\')'
            where: '@equals(item()[\'status\'], \'Failed\')'
          }
        }
        Initialize_NoOfAttempt: {
          runAfter: {
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'NoOfAttempt'
                type: 'integer'
                value: 0
              }
            ]
          }
        }
        Initialize_ErrorCategory: {
          runAfter: {
            Initialize_NoOfAttempt: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'ErrorCategory'
                type: 'string'
              }
            ]
          }
        }
        Scope: {
          actions: {
            Until: {
              actions: {
                Set_Error_Category: {
                  runAfter: {
                    '${logicAppErrorConfigurationDetails}': [
                      'Succeeded'
                    ]
                  }
                  type: 'SetVariable'
                  inputs: {
                    name: 'ErrorCategory'
                    value: '@{body(\'${logicAppErrorConfigurationDetails}\')[\'errorCategory\']}'
                  }
                }
                'Set_variable_to_skip_-_Successful': {
                  runAfter: {
                    '${logicAppPostToIntegrationFramework}': [
                      'Succeeded'
                    ]
                  }
                  type: 'SetVariable'
                  inputs: {
                    name: 'NoOfAttempt'
                    value: successFlag
                  }
                }
                Switch_errorHandler: {
                  runAfter: {
                    Set_Error_Category: [
                      'Succeeded'
                      'TimedOut'
                      'Skipped'
                      'Failed'
                    ]
                  }
                  cases: {
                    Case_TableLock: {
                      case: 252
                      actions: {
                        Delay: {
                          runAfter: {
                            Increment_NoOfAttempt: [
                              'Succeeded'
                            ]
                          }
                          type: 'Wait'
                          inputs: {
                            interval: {
                              count: delayMinute
                              unit: 'Minute'
                            }
                          }
                        }
                        Increment_NoOfAttempt: {
                          runAfter: {
                          }
                          type: 'SetVariable'
                          inputs: {
                            name: 'NoOfAttempt'
                            value: 1
                          }
                        }
                      }
                    }
                  }
                  default: {
                    actions: {
                      'Set_variable_to_skip_-_None': {
                        runAfter: {
                        }
                        type: 'SetVariable'
                        inputs: {
                          name: 'NoOfAttempt'
                          value: successFlag
                        }
                      }
                    }
                  }
                  expression: '@outputs(\'${logicAppErrorConfigurationDetails}\')[\'statusCode\']'
                  type: 'Switch'
                }
                '${logicAppErrorConfigurationDetails}': {
                  runAfter: {
                    '${logicAppPostToIntegrationFramework}': [
                      'Failed'
                      'Skipped'
                      'TimedOut'
                    ]
                  }
                  type: 'Workflow'
                  inputs: {
                    body: '@body(\'${logicAppPostToIntegrationFramework}\')'
                    host: {
                      triggerName: 'manual'
                      workflow: {
                        id: ref_la_error_configuration_details.id
                      }
                    }
                  }
                }
                '${logicAppPostToIntegrationFramework}': {
                  runAfter: {
                  }
                  type: 'Workflow'
                  inputs: {
                    body: {
                      bodytext: '@{base64ToString(triggerBody()?[\'ContentData\'])}'
                      correlationid: '@{triggerBody()[\'Properties\'][\'correlationid\']}'
                      destination: 'BC'
                      direction: 'Inbound'
                      messagemype: '@{triggerBody()[\'Properties\'][\'messageType\']}'
                      source: '@{triggerBody()[\'Properties\'][\'source\']}'
                      version: 1
                    }
                    host: {
                      triggerName: 'manual'
                      workflow: {
                        id: ref_la_post_integration_framework.id
                      }
                    }
                    retryPolicy: {
                      type: 'none'
                    }
                  }
                }
              }
              runAfter: {
              }
              expression: untilExpression
              limit: {
                count: 1
                timeout: 'PT1H'
              }
              type: 'Until'
            }
          }
          runAfter: {
            Initialize_ErrorCategory: [
              'Succeeded'
            ]
          }
          type: 'Scope'
        }
        '${logicAppPostToServiceBusTopic}': {
          runAfter: {
            Filter_Scope_Result: [
              'Succeeded'
            ]
          }
          type: 'Workflow'
          inputs: {
            body: {
              content: '@base64ToString(triggerBody()?[\'ContentData\'])'
              contentInBlob: 'false'
              correlationID: '@{triggerBody()[\'Properties\'][\'correlationid\']}'
              dataVersion: '@{triggerBody()[\'Properties\'][\'dataversion\']}'
              destination: '@{triggerBody()[\'Properties\'][\'destination\']}'
              direction: '@{triggerBody()[\'Properties\'][\'direction\']}'
              errorCategory: '@variables(\'ErrorCategory\')'
              errorCode: '@outputs(\'${logicAppErrorConfigurationDetails}\')[\'statusCode\']'
              errorEvent: logicAppName
              errorMessage: '@{if(\r\n  contains(\r\n    first(body(\'Filter_Scope_Result\')),\r\n    \'error\'),\r\n  first(body(\'Filter_Scope_Result\'))?[\'error\']?[\'message\'],\r\n  if(\r\n    contains(\r\n      first(body(\'Filter_Scope_Result\'))?[\'outputs\']?[\'body\'],\r\n      \'error\'),\r\n    first(body(\'Filter_Scope_Result\'))?[\'outputs\']?[\'body\']?[\'error\']?[\'message\'],\r\n    first(body(\'Filter_Scope_Result\'))?[\'outputs\']?[\'body\']))}'
              messageType: '@{triggerBody()[\'Properties\'][\'messageType\']}'
              originalSubscriber: '@{triggerBody()[\'Properties\'][\'subscriber\']}'
              partnerReference: '@{triggerBody()[\'Properties\'][\'partnerReference\']}'
              source: '@{triggerBody()[\'Properties\'][\'source\']}'
              subscriber: errorQueueSubscriber
              topic: '@{triggerBody()[\'Properties\'][\'topic\']}'
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

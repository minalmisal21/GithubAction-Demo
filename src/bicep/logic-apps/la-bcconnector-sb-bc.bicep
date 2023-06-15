param environmentAcronym string
param location string = resourceGroup().location
param locationAcronym string = 'ae'
param tagValues object
param logicAppState string = 'Enabled'
param clientIdentifier string

var errorQueueSubscriber = 'errorQueue'
var noOfAttempt = 10
var successFlag = (noOfAttempt + 1)
var delayMinute = 1
var untilExpression = '@greater(variables(\'NoOfAttempt\'),${noOfAttempt})'
var logicAppName = '${clientIdentifier}-${locationAcronym}-la-bcconnector-sb-bc-${environmentAcronym}'
var logicAppPostToServiceBusTopic = '${clientIdentifier}-${locationAcronym}-la-post-sbtopic-${environmentAcronym}'
var logicAppPostToIntegrationFramework = '${clientIdentifier}-${locationAcronym}-la-post-integration-framework-${environmentAcronym}'
var logicAppErrorConfigurationDetails = '${clientIdentifier}-${locationAcronym}-la-error-configuration-details-${environmentAcronym}'
var storageAccount = '${clientIdentifier}${locationAcronym}sabc${environmentAcronym}'
var logAnalyticsWorkspaceName = '${clientIdentifier}-${locationAcronym}-log-${environmentAcronym}'
var internalTags = {
  Purpose: ''
}
var tags = union(tagValues, internalTags)

resource ref_apiconnection_servicebus 'Microsoft.Web/connections@2016-06-01' existing = {
  name: 'servicebus'
}
resource ref_apiconnection_azureblob 'Microsoft.Web/connections@2016-06-01' existing = {
  name: 'azureblob'
}

resource ref_apiconnection_azuretables 'Microsoft.Web/connections@2016-06-01' existing = {
  name: 'azuretables'
}
resource ref_la_post_integration_framework 'Microsoft.Logic/workflows@2019-05-01' existing = {
  name: logicAppPostToIntegrationFramework
}
resource ref_la_post_sbtopic 'Microsoft.Logic/workflows@2019-05-01' existing = {
  name: logicAppPostToServiceBusTopic
}

resource ref_la_error_configuration_details 'Microsoft.Logic/workflows@2019-05-01' existing = {
  name: logicAppErrorConfigurationDetails
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
            interval: 1
          }
          evaluatedRecurrence: {
            frequency: 'Minute'
            interval: 1
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
              maxMessageCount: 10
              subscriptionType: 'Main'
            }
          }
          runtimeConfiguration: {
            concurrency: {
              runs: 1
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
        Initialize_ErrorCategory: {
          runAfter: {
            Initialize_MessageContent: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'ErrorCategory'
                type: 'String'
              }
            ]
          }
        }
        Initialize_ErrorMessage: {
          runAfter: {
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'ErrorMessage'
                type: 'string'
              }
            ]
          }
        }
        Initialize_MessageContent: {
          runAfter: {
            Initialize_ProcessedSuccessfully: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'MessageContent'
                type: 'string'
              }
            ]
          }
        }
        Initialize_NoOfAttempt: {
          runAfter: {
            Initialize_ErrorMessage: [
              'Succeeded'
            ]
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
        Initialize_ProcessedSuccessfully: {
          runAfter: {
            Initialize_NoOfAttempt: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'ProcessedSuccessfully'
                type: 'boolean'
                value: '@false'
              }
            ]
          }
        }
        Scope: {
          actions: {
            Condition: {
              actions: {
                Get_blob_content_using_path: {
                  runAfter: {
                    Parse_SB_Content: [
                      'Succeeded'
                    ]
                  }
                  type: 'ApiConnection'
                  inputs: {
                    host: {
                      connection: {
                        name: '@parameters(\'$connections\')[\'azureblob\'][\'connectionId\']'
                      }
                    }
                    method: 'get'
                    path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'${storageAccount}\'))}/GetFileContentByPath'
                    queries: {
                      inferContentType: true
                      path: '@body(\'Parse_SB_Content\')?[\'blobaddress\']'
                      queryParametersSingleEncoded: true
                    }
                  }
                }
                Parse_SB_Content: {
                  runAfter: {
                  }
                  type: 'ParseJson'
                  inputs: {
                    content: '@json(base64ToString(triggerBody()?[\'ContentData\']))'
                    schema: {
                      properties: {
                        blobaddress: {
                          type: 'string'
                        }
                        blobfilename: {
                          type: 'string'
                        }
                        filedate: {
                          type: 'string'
                        }
                        filetype: {
                          type: 'string'
                        }
                        originalfilename: {
                          type: 'string'
                        }
                      }
                      type: 'object'
                    }
                  }
                }
                'Set_MessageContent_-_Blob_-_Base_64': {
                  runAfter: {
                    Get_blob_content_using_path: [
                      'Succeeded'
                    ]
                  }
                  type: 'SetVariable'
                  inputs: {
                    name: 'MessageContent'
                    value: '@{body(\'Get_blob_content_using_path\')}'
                  }
                }
                'Set_MessageContent_-_Blob_-_Normal': {
                  runAfter: {
                    'Set_MessageContent_-_Blob_-_Base_64': [
                      'Failed'
                    ]
                  }
                  type: 'SetVariable'
                  inputs: {
                    name: 'MessageContent'
                    value: '@{body(\'Get_blob_content_using_path\')}'
                  }
                }
              }
              runAfter: {
              }
              else: {
                actions: {
                  'Set_MessageContent_-_ServiceBus_-_Base64': {
                    runAfter: {
                    }
                    type: 'SetVariable'
                    inputs: {
                      name: 'MessageContent'
                      value: '@{base64ToString(triggerBody()?[\'ContentData\'])}'
                    }
                  }
                  'Set_MessageContent_-_ServiceBus_-_Decode': {
                    runAfter: {
                      'Set_MessageContent_-_ServiceBus_-_Base64': [
                        'Failed'
                      ]
                    }
                    type: 'SetVariable'
                    inputs: {
                      name: 'MessageContent'
                      value: '@triggerBody()?[\'ContentData\']'
                    }
                  }
                }
              }
              expression: {
                and: [
                  {
                    equals: [
                      '@toUpper(triggerBody()[\'Properties\'][\'contentInBlob\'])'
                      'TRUE'
                    ]
                  }
                ]
              }
              type: 'If'
            }
            Until: {
              actions: {
                Insert_or_Merge_Entity: {
                  runAfter: {
                    'Set_variable_to_skip_-_Successful': [
                      'Succeeded'
                    ]
                  }
                  type: 'ApiConnection'
                  inputs: {
                    body: {
                      LogicApp3Name: '@{workflow()[\'name\']}'
                      LogicApp3RunID: '@{workflow()[\'run\'][\'name\']}'
                      Status: '@{if(variables(\'ProcessedSuccessfully\'),\'ProcessedInBC\',\'FailedInBC\')}'
                    }
                    host: {
                      connection: {
                        name: '@parameters(\'$connections\')[\'azuretables\'][\'connectionId\']'
                      }
                    }
                    method: 'patch'
                    path: '/Tables/@{encodeURIComponent(\'bcIntegrationLog\')}/entities(PartitionKey=\'@{encodeURIComponent(triggerBody()[\'Properties\'][\'source\'])}\',RowKey=\'@{encodeURIComponent(triggerBody()[\'Properties\'][\'correlationid\'])}\')'
                  }
                }
                Insert_or_Merge_Entity_Failed: {
                  runAfter: {
                    Switch_ErrorHandler: [
                      'Succeeded'
                    ]
                  }
                  type: 'ApiConnection'
                  inputs: {
                    body: {
                      LogicApp3Name: '@{workflow()[\'name\']}'
                      LogicApp3RunID: '@{workflow()[\'run\'][\'name\']}'
                      Status: '@{if(variables(\'ProcessedSuccessfully\'),\'ProcessedInBC\',\'FailedInBC\')}'
                    }
                    host: {
                      connection: {
                        name: '@parameters(\'$connections\')[\'azuretables\'][\'connectionId\']'
                      }
                    }
                    method: 'patch'
                    path: '/Tables/@{encodeURIComponent(\'bcIntegrationLog\')}/entities(PartitionKey=\'@{encodeURIComponent(triggerBody()[\'Properties\'][\'source\'])}\',RowKey=\'@{encodeURIComponent(triggerBody()[\'Properties\'][\'correlationid\'])}\')'
                  }
                }
                Set_ErrorCategory: {
                  runAfter: {
                    '${logicAppErrorConfigurationDetails}': [
                      'Succeeded'
                    ]
                  }
                  type: 'SetVariable'
                  inputs: {
                    name: 'ErrorCategory'
                    value: '@body(\'${logicAppErrorConfigurationDetails}\')[\'errorCategory\']'
                  }
                }
                Set_ProcessedSuccessfully: {
                  runAfter: {
                    '${logicAppPostToIntegrationFramework}': [
                      'Succeeded'
                    ]
                  }
                  type: 'SetVariable'
                  inputs: {
                    name: 'ProcessedSuccessfully'
                    value: '@true'
                  }
                }
                'Set_variable_to_skip_-_Successful': {
                  runAfter: {
                    Set_ProcessedSuccessfully: [
                      'Succeeded'
                    ]
                  }
                  type: 'SetVariable'
                  inputs: {
                    name: 'NoOfAttempt'
                    value: successFlag
                  }
                }
                Switch_ErrorHandler: {
                  runAfter: {
                    Set_ErrorCategory: [
                      'Succeeded'
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
                          type: 'IncrementVariable'
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
                      'TimedOut'
                      'Failed'
                    ]
                  }
                  type: 'Workflow'
                  inputs: {
                    body: {
                      error: {
                        message: '@{body(\'${logicAppPostToIntegrationFramework}\')}'
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
                '${logicAppPostToIntegrationFramework}': {
                  runAfter: {
                  }
                  type: 'Workflow'
                  inputs: {
                    body: {
                      BodyText: '@{variables(\'MessageContent\')}'
                      CorrelationID: '@{triggerBody()[\'Properties\'][\'correlationid\']}'
                      Destination: '@{triggerBody()[\'Properties\'][\'Destination\']}'
                      Direction: '@{triggerBody()[\'Properties\'][\'Direction\']}'
                      Messagemype: '@{triggerBody()[\'Properties\'][\'messageType\']}'
                      Source: '@{triggerBody()[\'Properties\'][\'Source\']}'
                      Version: '@{triggerBody()[\'Properties\'][\'dataversion\']}'
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
                Condition: [
                  'Succeeded'
                ]
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
        Set_variable_ErrorMessage: {
          runAfter: {
            Filter_Scope_Result: [
              'Succeeded'
            ]
          }
          type: 'SetVariable'
          inputs: {
            name: 'ErrorMessage'
            value: '@{if(contains(first(body(\'Filter_Scope_Result\')),\'error\'),first(body(\'Filter_Scope_Result\'))?[\'error\']?[\'message\'],if(contains(first(body(\'Filter_Scope_Result\'))?[\'outputs\']?[\'body\'],\'error\'),first(body(\'Filter_Scope_Result\'))?[\'outputs\']?[\'body\']?[\'error\']?[\'message\'],first(body(\'Filter_Scope_Result\'))?[\'outputs\']?[\'body\']))}'
          }
        }
        '${logicAppPostToServiceBusTopic}': {
          runAfter: {
            Set_variable_ErrorMessage: [
              'Succeeded'
            ]
          }
          type: 'Workflow'
          inputs: {
            body: {
              content: '@base64ToString(triggerBody()?[\'ContentData\'])'
              contentInBlob: '@{triggerBody()[\'Properties\'][\'contentInBlob\']}'
              correlationID: '@{triggerBody()[\'Properties\'][\'correlationid\']}'
              dataVersion: '@{triggerBody()[\'Properties\'][\'dataversion\']}'
              destination: '@{triggerBody()[\'Properties\'][\'destination\']}'
              direction: '@{triggerBody()[\'Properties\'][\'direction\']}'
              errorCategory: '@variables(\'ErrorCategory\')'
              errorCode: '@outputs(\'${logicAppErrorConfigurationDetails}\')[\'statusCode\']'
              errorEvent: logicAppName
              errorMessage: '@variables(\'ErrorMessage\')'
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
          azureblob: {
            connectionId: ref_apiconnection_azureblob.id
            connectionName: 'azureblob'
            connectionProperties: {
              authentication: {
                type: 'ManagedServiceIdentity'
              }
            }
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/azureblob'
          }
          azuretables: {
            connectionId: ref_apiconnection_azuretables.id
            connectionName: 'azuretables'
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/azuretables'
          }
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

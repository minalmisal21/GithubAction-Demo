param environmentAcronym string
param location string = resourceGroup().location
param locationAcronym string = 'ae'
param tagValues object
param logicAppState string = 'Enabled'
param clientIdentifier string

var logicAppName = '${clientIdentifier}-${locationAcronym}-la-sb-errorqueue-processor-${environmentAcronym}'
var logAnalyticsWorkspaceName = '${clientIdentifier}-${locationAcronym}-log-${environmentAcronym}'

var internalTags = {
  Purpose: ''
}
var tags = union(tagValues, internalTags)

resource ref_apiconnection_servicebus 'Microsoft.Web/connections@2016-06-01' existing = {
  name: 'servicebus'
}
resource ref_apiconnection_office365 'Microsoft.Web/connections@2016-06-01' existing = {
  name: 'office365'
}

resource ref_apiconnection_azuretables 'Microsoft.Web/connections@2016-06-01' existing = {
  name: 'azuretables'
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
        EmailCSS: {
          defaultValue: '<style> #errors {   font-family: Arial, Helvetica, sans-serif;   border-collapse: collapse;   width: 100%; }  #errors td, #errors th {   border: 1px solid #ddd;   padding: 8px; }  #errors tr:nth-child(even){background-color: #f2f2f2;}  #errors tr:hover {background-color: #ddd;}  #errors th {   padding-top: 12px;   padding-bottom: 12px;   text-align: left;   background-color: #0583EF;   color: white; } </style>'
          type: 'String'
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
            path: '/@{encodeURIComponent(encodeURIComponent(\'bcintegration\'))}/subscriptions/@{encodeURIComponent(\'errorQueue\')}/messages/batch/head'
            queries: {
              maxMessageCount: 20
              subscriptionType: 'Main'
            }
          }
        }
      }
      actions: {
        Condition: {
          actions: {
            Send_message: {
              runAfter: {
              }
              type: 'ApiConnection'
              inputs: {
                body: {
                  ContentData: '@{triggerBody()?[\'ContentData\']}'
                  Properties: '@removeProperty(setProperty(body(\'Parse_JSON\')[\'Properties\'],\'subscriber\',body(\'Parse_JSON\')[\'Properties\'][\'originalsubscriber\']),\'originalsubscriber\')'
                }
                host: {
                  connection: {
                    name: '@parameters(\'$connections\')[\'servicebus\'][\'connectionId\']'
                  }
                }
                method: 'post'
                path: '/@{encodeURIComponent(encodeURIComponent(\'bcintegration\'))}/messages'
                queries: {
                  systemProperties: 'None'
                }
              }
            }
          }
          runAfter: {
            Send_approval_email: [
              'Succeeded'
            ]
          }
          expression: {
            and: [
              {
                equals: [
                  '@body(\'Send_approval_email\')?[\'SelectedOption\']'
                  'Retry'
                ]
              }
            ]
          }
          type: 'If'
        }
        Create_HTML_table: {
          runAfter: {
            Parse_JSON: [
              'Succeeded'
            ]
          }
          type: 'Table'
          inputs: {
            columns: [
              {
                header: 'Originated From'
                value: '@body(\'Parse_JSON\')[\'Properties\'][\'source\']'
              }
              {
                header: 'Destination'
                value: '@body(\'Parse_JSON\')[\'Properties\'][\'destination\']'
              }
              {
                header: 'Error Message'
                value: '@body(\'Parse_JSON\')[\'Properties\'][\'errorMessage\']'
              }
            ]
            format: 'HTML'
            from: '@createArray(triggerBody())'
          }
        }
        Get_Recipient_List: {
          runAfter: {
            Initialize_ErrorCategory: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'azuretables\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/Tables/@{encodeURIComponent(\'bcIntegrationEmail\')}/entities'
            queries: {
              '$filter': 'PartitionKey eq \'@{variables(\'ErrorCategory\')}\''
              '$select': 'Recipient'
            }
          }
        }
        Initialize_ErrorCategory: {
          runAfter: {
            Create_HTML_table: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'ErrorCategory'
                type: 'string'
                value: '@{if(equals(triggerBody()[\'Properties\'][\'errorCode\'],\'251\'),\'Business\',if(equals(triggerBody()[\'Properties\'][\'errorCode\'],\'252\'),\'Technical\',if(equals(triggerBody()[\'Properties\'][\'errorCode\'],\'253\'),\'Technical\',   if(equals(triggerBody()[\'Properties\'][\'errorCode\'],\'254\'),\'Technical\', \'Default\'))))}'
              }
            ]
          }
        }
        Parse_JSON: {
          runAfter: {
          }
          type: 'ParseJson'
          inputs: {
            content: '@triggerBody()'
            schema: {
            }
          }
        }
        Send_approval_email: {
          runAfter: {
            Get_Recipient_List: [
              'Succeeded'
            ]
          }
          type: 'ApiConnectionWebhook'
          inputs: {
            body: {
              Message: {
                Body: '@{parameters(\'EmailCSS\')}\nYou have selected to receive alert email for hirepool Business Integration. If you want to opt-out from the emails, please contact the system administrator. \n<br>\n<br>\n@{replace(body(\'Create_HTML_table\'),\'<table>\',\'<table id="errors">\')}'
                HeaderText: 'Attention Required'
                HideHTMLMessage: true
                Importance: 'High'
                Options: 'Retry, Reject'
                SelectionText: 'Do you want to retry the integration message?'
                ShowHTMLConfirmationDialog: false
                Subject: '@{concat( body(\'Parse_JSON\')[\'Properties\']?[\'subject\'],\' Integration From \',body(\'Parse_JSON\')[\'Properties\'][\'source\'], \' to \',body(\'Parse_JSON\')[\'Properties\'][\'Destination\'], \' require your attention.\')}'
                To: '@{body(\'Get_Recipient_List\').value[0].Recipient}'
                UseOnlyHTMLMessage: true
              }
              NotificationUrl: '@{listCallbackUrl()}'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'office365\'][\'connectionId\']'
              }
            }
            path: '/approvalmail/$subscriptions'
          }
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
          office365: {
            connectionId: ref_apiconnection_office365.id
            connectionName: 'office365'
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/office365'
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

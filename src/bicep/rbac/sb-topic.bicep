param environmentAcronym string
param locationAcronym string = 'ae'
param clientIdentifier string
param sbtopicName string = 'bcintegration'

var serviceBusNamespace = '${clientIdentifier}-${locationAcronym}-sb-${environmentAcronym}'
var logicAppBCConnectorSBBC = '${clientIdentifier}-${locationAcronym}-la-bcconnector-sb-bc-${environmentAcronym}'
var logicAppPostToServiceBusTopic = '${clientIdentifier}-${locationAcronym}-la-post-sbtopic-${environmentAcronym}'
var logicAppErrorQueueProcessor = '${clientIdentifier}-${locationAcronym}-la-sb-errorqueue-processor-${environmentAcronym}'
var logicAppErrorSBSubscriber = '${clientIdentifier}-${locationAcronym}-la-sb-subscriber-bc-${environmentAcronym}'

resource ref_servicebustopic 'Microsoft.ServiceBus/namespaces/topics@2021-11-01' existing = {
  name: '${serviceBusNamespace}/${sbtopicName}'
}
resource ref_la_bcconnector_sb_bc 'Microsoft.Logic/workflows@2019-05-01' existing = {
  name: logicAppBCConnectorSBBC
}


resource ref_la_post_sbtopic 'Microsoft.Logic/workflows@2019-05-01' existing = {
  name: logicAppPostToServiceBusTopic
}


resource ref_la_sb_errorqueue_processor 'Microsoft.Logic/workflows@2019-05-01' existing = {
  name: logicAppErrorQueueProcessor
}

resource ref_la_sb_subscriber_bc 'Microsoft.Logic/workflows@2019-05-01' existing = {
  name: logicAppErrorSBSubscriber
}


@description('This is the built-in Azure Service Bus Data Receiver role. See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#AzureServiceBusDataReceiver')
resource serviceBusDataReceiverRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'
}

@description('This is the built-in Azure Service Bus Data Sender role. See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#AzureServiceBusDataSender')
resource serviceBusDataSenderRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39'
}

resource servicebusdatareceiverroleassignment_1 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, ref_la_bcconnector_sb_bc.name, serviceBusDataReceiverRoleDefinition.id)
  scope: ref_servicebustopic
  properties: {
    roleDefinitionId: serviceBusDataReceiverRoleDefinition.id
    principalId: ref_la_bcconnector_sb_bc.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource servicebusdatasenderroleassignment_1 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, ref_la_post_sbtopic.name, serviceBusDataSenderRoleDefinition.id)
  scope: ref_servicebustopic
  properties: {
    roleDefinitionId: serviceBusDataSenderRoleDefinition.id
    principalId: ref_la_post_sbtopic.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource servicebusdatareceiverroleassignment_2 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, ref_la_sb_errorqueue_processor.name, serviceBusDataReceiverRoleDefinition.id)
  scope: ref_servicebustopic
  properties: {
    roleDefinitionId: serviceBusDataReceiverRoleDefinition.id
    principalId: ref_la_sb_errorqueue_processor.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource servicebusdatasenderroleassignment_2 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, ref_la_sb_errorqueue_processor.name, serviceBusDataSenderRoleDefinition.id)
  scope: ref_servicebustopic
  properties: {
    roleDefinitionId: serviceBusDataSenderRoleDefinition.id
    principalId: ref_la_sb_errorqueue_processor.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource servicebusdatareceiverroleassignment_3 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, ref_la_sb_subscriber_bc.name, serviceBusDataReceiverRoleDefinition.id)
  scope: ref_servicebustopic
  properties: {
    roleDefinitionId: serviceBusDataReceiverRoleDefinition.id
    principalId: ref_la_sb_subscriber_bc.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

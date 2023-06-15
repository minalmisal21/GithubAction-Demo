param environmentAcronym string
param clientIdentifier string
param location string = resourceGroup().location
param locationAcronym string = 'ae'
param sbtopicName string = 'bcintegration'
param tagValues object

var serviceBusNamespace = '${clientIdentifier}-${locationAcronym}-sb-${environmentAcronym}'
var internalTags = {
    Purpose: 'service message broker for ${clientIdentifier}'
  }
  var tags = union(tagValues, internalTags)
  

resource resource_servicebus 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' = {
  name: serviceBusNamespace
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
    zoneRedundant: false
  }
}

resource resource_servicebus_topic 'Microsoft.ServiceBus/namespaces/topics@2022-01-01-preview' = {
  parent: resource_servicebus
  name: sbtopicName
  properties: {
    maxMessageSizeInKilobytes: 256
    defaultMessageTimeToLive: 'P14D'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    enableBatchedOperations: true
    status: 'Active'
    supportOrdering: true
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    enablePartitioning: false
    enableExpress: false
  }
}

resource resource_servicebus_topic_subscription_errorQueue 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2022-01-01-preview' = {
  parent: resource_servicebus_topic
  name: 'errorQueue'
  properties: {
    isClientAffine: false
    lockDuration: 'PT5M'
    requiresSession: false
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: false
    deadLetteringOnFilterEvaluationExceptions: false
    maxDeliveryCount: 1
    status: 'Active'
    enableBatchedOperations: true
    autoDeleteOnIdle: 'P14D'
  }
}

resource resource_servicebus_topic_subscription_errorQueue_rules 'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules@2022-01-01-preview' = {
  parent: resource_servicebus_topic_subscription_errorQueue
  name: 'errorQueue'
  properties: {
    filterType: 'CorrelationFilter'
    correlationFilter: {
      properties: {
        subscriber: 'errorQueue'
      }
    }
  }
}


resource resource_servicebus_topic_subscription_businessCentral 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2022-01-01-preview' = {
  parent: resource_servicebus_topic
  name: 'businessCentral'
  properties: {
    isClientAffine: false
    lockDuration: 'PT5M'
    requiresSession: false
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: false
    deadLetteringOnFilterEvaluationExceptions: false
    maxDeliveryCount: 1
    status: 'Active'
    enableBatchedOperations: true
    autoDeleteOnIdle: 'P14D'
  }
}

resource resource_servicebus_topic_subscription_businessCentral_rules 'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules@2022-01-01-preview' = {
  parent: resource_servicebus_topic_subscription_businessCentral
  name: 'businessCentral'
  properties: {
    filterType: 'CorrelationFilter'
    correlationFilter: {
      properties: {
        subscriber: 'businessCentral'
      }
    }
  }
}


resource resource_servicebus_topic_subscription_mrApple 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2022-01-01-preview' = {
  parent: resource_servicebus_topic
  name: 'mrApple'
  properties: {
    isClientAffine: false
    lockDuration: 'PT5M'
    requiresSession: false
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: false
    deadLetteringOnFilterEvaluationExceptions: false
    maxDeliveryCount: 1
    status: 'Active'
    enableBatchedOperations: true
    autoDeleteOnIdle: 'P14D'
  }
}

resource resource_servicebus_topic_subscription_mrApple_rules 'Microsoft.ServiceBus/namespaces/topics/subscriptions/rules@2022-01-01-preview' = {
  parent: resource_servicebus_topic_subscription_mrApple
  name: 'mrAppleFilter'
  properties: {
    filterType: 'CorrelationFilter'
    correlationFilter: {
      properties: {
        subscriber: 'mrApple'
      }
    }
  }
}

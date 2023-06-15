param environmentAcronym string
param location string = resourceGroup().location
param locationAcronym string = 'ae'
param dailyQuotaGb int = 1
param tagValues object
param clientIdentifier string

var logAnalyticsWorkspaceName = '${clientIdentifier}-${locationAcronym}-log-${environmentAcronym}'
var internalTags = {
  Purpose: 'Log Analytics workspace environment for Azure monitor logs'
}
var tags = union(tagValues, internalTags)

resource loganalyticsworkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: tags
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    workspaceCapping: {
      dailyQuotaGb: dailyQuotaGb
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

resource loganalyticsworkspacediagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: loganalyticsworkspace
  name: 'diagnosticSettings'
  properties: {
    workspaceId: loganalyticsworkspace.id
    logs: [
      {
        category: 'Audit'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
    ]
  }
}

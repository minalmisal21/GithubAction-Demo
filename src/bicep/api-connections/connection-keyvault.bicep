param environmentAcronym string
param location string
param locationAcronym string = 'ae'
param tagValues object
param clientIdentifier string

var internalTags = {
  Purpose: 'api connection for Azure keyvault'
}
var tags = union(tagValues, internalTags)
var keyvaultName = '${clientIdentifier}-${locationAcronym}-kv-${environmentAcronym}'

resource apiconnection_keyvault 'Microsoft.Web/connections@2016-06-01' = {
  name: 'keyvault'
  location: location
  tags: tags
  properties: {
    api: {
      id: 'subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/keyvault'
    }
    customParameterValues: {
    }
    parameterValues: {
      vaultName: keyvaultName
    }
    displayName: '${keyvaultName}-keyvault'
  }
}

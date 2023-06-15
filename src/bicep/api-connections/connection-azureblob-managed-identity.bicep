param environmentAcronym string
param location string
param locationAcronym string = 'ae'
param tagValues object
param clientIdentifier string

var internalTags = {
  Purpose: 'api connection for Azure Blob'
}
var tags = union(tagValues, internalTags)
var storageAccount = '${clientIdentifier}${locationAcronym}sabc${environmentAcronym}'


resource apiconnection_azureblob 'Microsoft.Web/connections@2016-06-01' = {
  name: 'azureblob'
  location: location
  tags: tags
  properties: {
    displayName: '${storageAccount}-azureblob'
    customParameterValues: {
    }
    parameterValueSet: {
      name: 'managedIdentityAuth'
      values: {}
    }
    api: {
      id: 'subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/azureblob'
    }
  }
}

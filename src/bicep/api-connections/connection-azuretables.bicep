param environmentAcronym string
param location string
param locationAcronym string = 'ae'
param tagValues object
param clientIdentifier string

var internalTags = {
  Purpose: 'api connection for Azure Tables'
}
var tags = union(tagValues, internalTags)
var storageAccount = '${clientIdentifier}${locationAcronym}sabc${environmentAcronym}'

resource ref_storageaccount 'Microsoft.Storage/storageAccounts@2019-06-01' existing = {
  name: storageAccount
}

resource apiconnection_azuretables 'Microsoft.Web/connections@2016-06-01' = {
  name: 'azuretables'
  location: location
  tags: tags
  properties: {
    displayName: '${storageAccount}-azuretables'
    customParameterValues: {
    }
    parameterValues: {
      storageaccount: storageAccount
      sharedkey: listKeys(ref_storageaccount.id, ref_storageaccount.apiVersion).keys[0].value
    }
    api: {
      id: 'subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/azuretables'
    }
  }
}

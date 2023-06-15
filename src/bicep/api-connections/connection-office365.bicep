param location string
param tagValues object

var internalTags = {
  Purpose: 'api connection for office365'
}
var tags = union(tagValues, internalTags)

resource apiconnection_office365 'Microsoft.Web/connections@2016-06-01' = {
  name: 'office365'
  location: location
  tags: tags
  properties: {
    api: {
      id: 'subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/office365'
    }
    customParameterValues: {
    }
    displayName: 'office365'
  }
}

param environmentAcronym string
param location string
param locationAcronym string = 'ae'
param clientIdentifier string

var serviceBusNamespace = '${clientIdentifier}-${locationAcronym}-sb-${environmentAcronym}'

resource apiconnection_servicebusnamespace 'Microsoft.Web/connections@2018-07-01-preview' = {
  name: 'servicebus'
  location: location
  kind: 'V1'
  properties: {
    api: {
      id: 'subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/servicebus'
    }
    displayName: '${serviceBusNamespace}-servicebus'
    connectionState: 'Enabled'
    parameterValueSet: {
      name: 'managedIdentityAuth'
      values: {
        namespaceEndpoint: {
          value: 'sb://${serviceBusNamespace}.servicebus.windows.net'
        }
      }
    }
  }
}

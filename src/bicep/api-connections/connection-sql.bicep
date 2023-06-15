param location string
param tagValues object
param sqlServer string = 'HSC-HIST'
param sqlDatabase string = 'BC'
param clientIdentifier string
param onPremiseDataGateway string = '${clientIdentifier}-common-datagateway'
param onPremiseDataGatewayResourceGroup string = 'rg-common-datagateway'
@secure()
param sqlUserName string
@secure()
param sqlPassword string 

var internalTags = {
  Purpose: 'api connection for Sql'
}
var tags = union(tagValues, internalTags)

resource ref_onpremise_datagateway 'Microsoft.Web/connectionGateways@2016-06-01' existing = {
  name: onPremiseDataGateway
  scope: resourceGroup(onPremiseDataGatewayResourceGroup)
  }


resource apiconnection_sql 'Microsoft.Web/connections@2016-06-01' = {
  name: 'sql'
  location: location
  tags: tags
  properties: {
    displayName: toLower('${sqlServer}-sql')
    customParameterValues: {
    }
    parameterValueSet: {
      name: 'windowsAuthentication'
      values: {
        gateway: {
          value: {
            id: ref_onpremise_datagateway.id
          }
        }
        server: {
          value: sqlServer
        }
        database: {
          value: sqlDatabase
        }
        username: {
          value: sqlUserName
        }
        password: {
          value: sqlPassword
        }
      }
    }
    api: {
      id: 'subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/sql'
    }
  }
}

param environmentAcronym string
param clientIdentifier string
param location string = resourceGroup().location
param locationAcronym string = 'ae'
param tagValues object
param devOpsServiceConnectionObjectId string

var keyvaultName = '${clientIdentifier}-${locationAcronym}-kv-${environmentAcronym}'
var internalTags = {
    Purpose: 'Azure keyvault for ${clientIdentifier}'
}
var tags = union(tagValues, internalTags)

resource resource_keyvault 'Microsoft.KeyVault/vaults@2016-10-01' = {
    name: keyvaultName
    location: location
    tags: tags
    properties: {
        sku: {
            family: 'A'
            name: 'standard'
        }
        tenantId: subscription().tenantId
        accessPolicies: [
            {
                tenantId: subscription().tenantId
                objectId: devOpsServiceConnectionObjectId
                permissions: {
                    keys: []
                    secrets: [
                        'get'
                        'list'
                        'set'
                    ]
                    certificates: []
                }
            }
        ]
        enabledForDeployment: true
        enabledForDiskEncryption: false
        enabledForTemplateDeployment: true
        enableSoftDelete: true
    }
}

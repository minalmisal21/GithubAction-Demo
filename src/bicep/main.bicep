param deployIAC bool = false
param deployAPIConnections bool = false
param deployRBAC bool = false
param deployCommonLogicApps bool = false
param isProduction bool
param environmentAcronym string
param devOpsServiceConnectionObjectId string
param BCIntegrationFrameworkApiEndpoint string
param BCEnvironment string
param clientIdentifier string
param location string = resourceGroup().location
param currentDateTime string = utcNow('yyyy-MM-dd-HHmmss')

var tagValues = {
  CreatedBy: 'Hawk-AzureDevOps'
  DeploymentDate: currentDateTime
  Environment: toUpper(environmentAcronym)
  ManagedBy: 'Theta'
}

////////////////////////////////////////////////// START IAC /////////////////////////////////////////////////

// module module_iac_kv 'iac/keyvault.bicep' = if (deployIAC) {
//   name: 'module_iac_kv_${currentDateTime}'
//   params: {
//     environmentAcronym: environmentAcronym
//     location: location
//     tagValues: tagValues
//     devOpsServiceConnectionObjectId: devOpsServiceConnectionObjectId
//     clientIdentifier: clientIdentifier
//   }
// }

// module module_iac_sb 'iac/servicebus.bicep' = if (deployIAC) {
//   name: 'module_iac_sb_${currentDateTime}'
//   params: {
//     environmentAcronym: environmentAcronym
//     location: location
//     tagValues: tagValues
//     clientIdentifier: clientIdentifier
//   }
// }

// module module_iac_storage 'iac/storageaccount.bicep' = if (deployIAC) {
//   name: 'module_iac_storage_${currentDateTime}'
//   params: {
//     environmentAcronym: environmentAcronym
//     location: location
//     tagValues: tagValues
//     clientIdentifier: clientIdentifier
//   }
// }

module module_iac_log_analytics 'iac/loganalytics.bicep' = if (deployIAC) {
  name: 'module_iac_log_analytics_${currentDateTime}'
  params: {
    environmentAcronym: environmentAcronym
    location: location
    tagValues: tagValues
    clientIdentifier: clientIdentifier
  }
}

module module_iac_application_insights 'iac/appinsights.bicep' = if (deployIAC) {
  name: 'module_iac_application_insights_${currentDateTime}'
  params: {
    environmentAcronym: environmentAcronym
    location: location
    tagValues: tagValues
    clientIdentifier: clientIdentifier
  }
}

////////////////////////////////////////////////// END IAC /////////////////////////////////////////////////

////////////////////////////////////////////////// START API Connections /////////////////////////////////////////////////
// module module_api_conn_office365 'api-connections/connection-office365.bicep' = if (deployAPIConnections) {
//   name: 'module_api_conn_office365_${currentDateTime}'
//   params: {
//     location: location
//     tagValues: tagValues
//   }
// }
// module module_api_conn_azblob_managedidentity 'api-connections/connection-azureblob-managed-identity.bicep' = if (deployAPIConnections) {
//   name: 'module_api_conn_azblob_managedidentity_${currentDateTime}'
//   params: {
//     environmentAcronym: environmentAcronym
//     location: location
//     tagValues: tagValues
//   }
//   dependsOn: [
//     module_iac_storage
//   ]
// }

// module module_api_conn_aztables 'api-connections/connection-azuretables.bicep' = if (deployAPIConnections) {
//   name: 'module_api_conn_aztables_${currentDateTime}'
//   params: {
//     environmentAcronym: environmentAcronym
//     location: location
//     tagValues: tagValues
//     clientIdentifier: clientIdentifier
//   }
//   dependsOn: [
//     module_iac_storage
//   ]
// }

// module module_api_conn_kv_managedidentity 'api-connections/connection-keyvault-managed-identity.bicep' = if (deployAPIConnections) {
//   name: 'module_api_conn_kv_managedidentity_${currentDateTime}'
//   params: {
//     environmentAcronym: environmentAcronym
//     location: location
//     tagValues: tagValues
//     clientIdentifier: clientIdentifier
//   }
//   dependsOn: [
//     module_iac_kv
//   ]
// }

// module module_api_conn_sb_managedidentity 'api-connections/connection-servicebus-managed-identity.bicep' = if (deployAPIConnections) {
//   name: 'module_api_conn_sb_managedidentity_${currentDateTime}'
//   params: {
//     environmentAcronym: environmentAcronym
//     location: location
//     clientIdentifier: clientIdentifier
//   }
//   dependsOn: [
//     module_iac_sb
//   ]
// }

//////////////////////////////////////////////////////////// END API Connections /////////////////////////////////////////////

////////////////////////////////////////////////// START Logic Apps /////////////////////////////////////////////////
// module module_la_errorconfigurationdetails 'logic-apps/la-error-configuration-details.bicep' = if (deployCommonLogicApps) {
//   name: 'module_la_errorconfigurationdetails_${currentDateTime}'
//   params: {
//     environmentAcronym: environmentAcronym
//     tagValues: tagValues
//     location: location
//     clientIdentifier: clientIdentifier
//   }
//   dependsOn: [
//     module_api_conn_aztables
//     module_iac_storage
//   ]
// }
// module module_la_post_sbtopic 'logic-apps/la-post-sbtopic.bicep' = if (deployCommonLogicApps) {
//   name: 'module_la_post_sbtopic_${currentDateTime}'
//   params: {
//     environmentAcronym: environmentAcronym
//     tagValues: tagValues
//     location: location
//     clientIdentifier: clientIdentifier
//   }
//   dependsOn: [
//     module_api_conn_sb_managedidentity
//   ]
// }

// module module_la_post_integration_framework 'logic-apps/la-post-integration-framework.bicep' = if (deployCommonLogicApps) {
//   name: 'module_la_post_integration_framework_${currentDateTime}'
//   params: {
//     environmentAcronym: environmentAcronym
//     tagValues: tagValues
//     location: location
//     BCIntegrationFrameworkApiEndpoint: BCIntegrationFrameworkApiEndpoint
//     clientIdentifier: clientIdentifier
//   }
//   dependsOn: [
//     module_api_conn_azblob_managedidentity
//     module_api_conn_aztables
//     module_api_conn_sb_managedidentity
//     module_iac_storage
//     module_la_post_sbtopic
//     module_la_errorconfigurationdetails
//   ]
// }

// module module_la_bcconnector_sb_bc 'logic-apps/la-bcconnector-sb-bc.bicep' = if (deployCommonLogicApps) {
//   name: 'module_la_bcconnector_sb_bc_${currentDateTime}'
//   params: {
//     environmentAcronym: environmentAcronym
//     tagValues: tagValues
//     location: location
//     clientIdentifier: clientIdentifier
//   }
//   dependsOn: [
//     module_api_conn_azblob_managedidentity
//     module_api_conn_aztables
//     module_api_conn_sb_managedidentity
//     module_iac_storage
//     module_la_post_sbtopic
//     module_la_errorconfigurationdetails
//     module_la_post_integration_framework
//   ]
// }

// module module_la_sbconnector_bc_sb 'logic-apps/la-sbconnector-bc-sb.bicep' = if (deployCommonLogicApps) {
//   name: 'module_la_sbconnector_bc_sb_${currentDateTime}'
//   params: {
//     environmentAcronym: environmentAcronym
//     tagValues: tagValues
//     location: location
//     isProduction: isProduction
//     BCEnvironment: BCEnvironment
//     clientIdentifier: clientIdentifier
//   }
//   dependsOn: [
//     module_api_conn_kv_managedidentity
//     module_la_post_sbtopic
//     module_la_errorconfigurationdetails
//   ]
// }


// module module_la_sb_errorqueue_processor 'logic-apps/la-sb-errorqueue-processor.bicep' = if (deployCommonLogicApps) {
//   name: 'module_la_sb_errorqueue_processor_${currentDateTime}'
//   params: {
//     environmentAcronym: environmentAcronym
//     tagValues: tagValues
//     location: location
//     clientIdentifier: clientIdentifier
//   }
//   dependsOn: [
//     module_api_conn_aztables
//     module_api_conn_office365
//     module_api_conn_sb_managedidentity
//     module_iac_storage
//     module_la_post_sbtopic
//   ]
// }

// module module_la_sb_subscriber_bc 'logic-apps/la-sb-subscriber-bc.bicep' = if (deployCommonLogicApps) {
//   name: 'module_la_sb_subscriber_bc_${currentDateTime}'
//   params: {
//     environmentAcronym: environmentAcronym
//     tagValues: tagValues
//     location: location
//     clientIdentifier: clientIdentifier
//   }
//   dependsOn: [
//     module_api_conn_aztables
//     module_api_conn_office365
//     module_api_conn_sb_managedidentity
//     module_iac_storage
//     module_la_post_sbtopic
//     module_la_post_integration_framework
//     module_la_errorconfigurationdetails
//   ]
// }

// ////////////////////////////////////////////////// END Logic Apps /////////////////////////////////////////////////

// ////////////////////////////////////////////////// START RBAC /////////////////////////////////////////////////
// module module_rbac_azblob 'rbac/azureblob.bicep' = if (deployRBAC) {
//   name: 'module_rbac_azblob_${currentDateTime}'
//   params: {
//     environmentAcronym: environmentAcronym
//     clientIdentifier: clientIdentifier
//   }
//   dependsOn: [
//     module_la_bcconnector_sb_bc
//   ]
// }

// module module_rbac_sb 'rbac/sb-topic.bicep' = if (deployRBAC) {
//   name: 'module_rbac_sb_${currentDateTime}'
//   params: {
//     environmentAcronym: environmentAcronym
//     clientIdentifier: clientIdentifier
//   }
//   dependsOn: [
//     module_iac_sb
//     module_la_post_sbtopic
//     module_la_bcconnector_sb_bc
//     module_la_sb_errorqueue_processor
//     module_la_sb_subscriber_bc
//   ]
// }

// ////////////////////////////////////////////////// END RBAC /////////////////////////////////////////////////

// ////////////////////////////////////////////////// START KV Access Policy /////////////////////////////////////////////////
// module module_kv_access_policy 'keyvault/accesspolicies.keyvaults.bicep' = {
//   name: 'module_kv_access_policy_${currentDateTime}'
//   params: {
//     environmentAcronym: environmentAcronym
//     clientIdentifier: clientIdentifier
//   }
//   dependsOn: [
//     module_la_sbconnector_bc_sb
//     module_la_post_integration_framework
//   ]
// }

////////////////////////////////////////////////// END KV Access Policy /////////////////////////////////////////////////


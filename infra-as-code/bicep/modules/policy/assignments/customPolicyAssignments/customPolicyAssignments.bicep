metadata name = 'ALZ Bicep - Custom Policy Assignments and Exemptions'
metadata description = 'Assigns Custom Policy Assignments and Exemptions to the Management Group hierarchy'

type policyAssignmentSovereigntyGlobalOptionsType = {
  @description('Enable/disable Sovereignty Baseline - Global Policies at root management group.')
  parTopLevelSovereigntyGlobalPoliciesEnable: bool

  @description('Allowed locations for resource deployment. Empty = deployment location only.')
  parListOfAllowedLocations: string[]

  @description('Effect for Sovereignty Baseline - Global Policies.')
  parPolicyEffect: ('Audit' | 'Deny' | 'Disabled' | 'AuditIfNotExists')
}

type policyAssignmentSovereigntyConfidentialOptionsType = {
  @description('Approved Azure resource types. Empty = allow all.')
  parAllowedResourceTypes: string[]

  @description('Allowed locations for resource deployment. Empty = deployment location only.')
  parListOfAllowedLocations: string[]

  @description('Approved VM SKUs for Azure Confidential Computing. Empty = allow all.')
  parAllowedVirtualMachineSKUs: string[]

  @description('Effect for Sovereignty Baseline - Confidential Policies.')
  parPolicyEffect: ('Audit' | 'Deny' | 'Disabled' | 'AuditIfNotExists')
}

@description('Prefix for management group hierarchy.')
@minLength(2)
@maxLength(10)
param parTopLevelManagementGroupPrefix string = 'alz'

@description('Optional suffix for management group names/IDs.')
@maxLength(10)
param parTopLevelManagementGroupSuffix string = ''

@description('Set the enforcement mode to DoNotEnforce for specific custom policies.')
param parPolicyAssignmentsToDisableEnforcement array = []

@description('Set the enforcement mode to DoNotEnforce for all custom policies.')
param parDisableCustomDefaultPolicies bool = false

@description('Names of policy assignments to exclude.')
param parExcludedPolicyAssignments array = []

// **Variables**

// Orchestration Module Variables
var varDeploymentNameWrappers = {
  basePrefix: 'ALZB'
  #disable-next-line no-loc-expr-outside-params //Policies resources are not deployed to a region, like other resources, but the metadata is stored in a region hence requiring this to keep input parameters reduced. See https://github.com/Azure/ALZ-Bicep/wiki/FAQ#why-are-some-linter-rules-disabled-via-the-disable-next-line-bicep-function for more information
  baseSuffixTenantAndManagementGroup: '${deployment().location}-${uniqueString(deployment().location, parTopLevelManagementGroupPrefix)}'
}

var varModDepNames = {
  modPolAssiIntRootDeployDenyResLocations: take('${varDeploymentNameWrappers.basePrefix}-denyResLoc-intRoot-${varDeploymentNameWrappers.baseSuffixTenantAndManagementGroup}', 64)
  modPolAssiIntRootDeployDenyRSGLocations: take('${varDeploymentNameWrappers.basePrefix}-denyRSGLoc-intRoot-${varDeploymentNameWrappers.baseSuffixTenantAndManagementGroup}', 64)
  modPolAssiPlatformDenyPublicEndpoints: take('${varDeploymentNameWrappers.basePrefix}-denyPubEnd-platform-${varDeploymentNameWrappers.baseSuffixTenantAndManagementGroup}', 64)
  modPolAssiPlatformDenyPipOnNic: take('${varDeploymentNameWrappers.basePrefix}-denyPipNic-platform-${varDeploymentNameWrappers.baseSuffixTenantAndManagementGroup}', 64)
  modPolAssiLzsDenyPublicEndpoints: take('${varDeploymentNameWrappers.basePrefix}-denyPubEnd-lz-${varDeploymentNameWrappers.baseSuffixTenantAndManagementGroup}', 64)
  modPolAssiLzsDenyPipOnNic: take('${varDeploymentNameWrappers.basePrefix}-denyPipNic-lz-${varDeploymentNameWrappers.baseSuffixTenantAndManagementGroup}', 64)
  modPolAssiLzsDenyHybridNet: take('${varDeploymentNameWrappers.basePrefix}-denyHybridNet-lz-${varDeploymentNameWrappers.baseSuffixTenantAndManagementGroup}', 64)
}

var varPolicyAssignmentDeployDenyResLocations = {
  definitionId: '/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c'
  libDefinition: loadJsonContent('../../../policy/assignments/lib/policy_assignments/policy_assignment_es_deny_resource_locations.tmpl.json')
}

var varPolicyAssignmentDeployDenyRSGLocations = {
  definitionId: '/providers/Microsoft.Authorization/policyDefinitions/e765b5de-1225-4ba3-bd56-1ac6695af988'
  libDefinition: loadJsonContent('../../../policy/assignments/lib/policy_assignments/policy_assignment_es_deny_rsg_locations.tmpl.json')
}

var varPolicyAssignmentDenyPublicEndpoints = {
  definitionId: '${varTopLevelManagementGroupResourceId}/providers/Microsoft.Authorization/policySetDefinitions/Deny-PublicPaaSEndpoints'
  libDefinition: loadJsonContent('../../../policy/assignments/lib/policy_assignments/policy_assignment_es_deny_public_endpoints.tmpl.json')
}

var varPolicyAssignmentDenyPublicIPOnNIC = {
  definitionId: '/providers/Microsoft.Authorization/policyDefinitions/83a86a26-fd1f-447c-b59d-e51f44264114'
  libDefinition: loadJsonContent('../../../policy/assignments/lib/policy_assignments/policy_assignment_es_deny_public_ip_on_nic.tmpl.json')
}

var varPolicyAssignmentDenyHybridNetworking = {
  definitionId: '/providers/Microsoft.Authorization/policyDefinitions/6c112d4e-5bc7-47ae-a041-ea2d9dccd749'
  libDefinition: loadJsonContent('../../../policy/assignments/lib/policy_assignments/policy_assignment_es_deny_hybridnetworking.tmpl.json')
}

// Management Groups Variables - Used For Policy Assignments
var varManagementGroupIds = {
  intRoot: '${parTopLevelManagementGroupPrefix}${parTopLevelManagementGroupSuffix}'
  platform: '${parTopLevelManagementGroupPrefix}-platform${parTopLevelManagementGroupSuffix}'
  landingZones: '${parTopLevelManagementGroupPrefix}-landingzones${parTopLevelManagementGroupSuffix}'
  landingZonesCorp: '${parTopLevelManagementGroupPrefix}-landingzones-corp${parTopLevelManagementGroupSuffix}'
  landingZonesOnline: '${parTopLevelManagementGroupPrefix}-landingzones-online${parTopLevelManagementGroupSuffix}'
  landingZonesConfidentialCorp: '${parTopLevelManagementGroupPrefix}-landingzones-confidential-corp${parTopLevelManagementGroupSuffix}'
  landingZonesConfidentialOnline: '${parTopLevelManagementGroupPrefix}-landingzones-confidential-online${parTopLevelManagementGroupSuffix}'
}

type typManagementGroupIdOverrides = {
  intRoot: string?
  platform: string?
  landingZones: string?
  landingZonesCorp: string?
  landingZonesOnline: string?
  landingZonesConfidentialCorp: string?
  landingZonesConfidentialOnline: string?
}

@description('Specify the ALZ Default Management Group IDs to override as specified in `varManagementGroupIds`. Useful for scenarios when renaming ALZ default management groups names and IDs but not their intent or hierarchy structure.')
param parManagementGroupIdOverrides typManagementGroupIdOverrides?

var varManagementGroupIdsUnioned = union(
  varManagementGroupIds,
  parManagementGroupIdOverrides ?? {}
)

var varTopLevelManagementGroupResourceId = '/providers/Microsoft.Management/managementGroups/${varManagementGroupIdsUnioned.intRoot}'

// **Scope**
targetScope = 'managementGroup'

// Modules - Policy Assignments - Intermediate Root Management Group

// Module - Policy Assignment - Deny-Resource-Locations
module modPolAssiIntRootDeployDenyResLocations '../../../policy/assignments/policyAssignmentManagementGroup.bicep' = if (!contains(parExcludedPolicyAssignments, varPolicyAssignmentDeployDenyResLocations.libDefinition.name)) {
  scope: managementGroup(varManagementGroupIdsUnioned.intRoot)
  name: varModDepNames.modPolAssiIntRootDeployDenyResLocations
  params: {
    parPolicyAssignmentDefinitionId: varPolicyAssignmentDeployDenyResLocations.definitionId
    parPolicyAssignmentName: varPolicyAssignmentDeployDenyResLocations.libDefinition.name
    parPolicyAssignmentDisplayName: varPolicyAssignmentDeployDenyResLocations.libDefinition.properties.displayName
    parPolicyAssignmentDescription: varPolicyAssignmentDeployDenyResLocations.libDefinition.properties.description
    parPolicyAssignmentParameters: varPolicyAssignmentDeployDenyResLocations.libDefinition.properties.parameters
    parPolicyAssignmentIdentityType: varPolicyAssignmentDeployDenyResLocations.libDefinition.identity.type
    parPolicyAssignmentEnforcementMode: (parDisableCustomDefaultPolicies || contains(parPolicyAssignmentsToDisableEnforcement, varPolicyAssignmentDeployDenyResLocations.libDefinition.name)) ? 'DoNotEnforce' : varPolicyAssignmentDeployDenyResLocations.libDefinition.properties.enforcementMode
  }
}

// Module - Policy Assignment - Deny-RSG-Locations
module modPolAssiIntRootDeployDenyRSGLocations '../../../policy/assignments/policyAssignmentManagementGroup.bicep' = if (!contains(parExcludedPolicyAssignments, varPolicyAssignmentDeployDenyRSGLocations.libDefinition.name)) {
  scope: managementGroup(varManagementGroupIdsUnioned.intRoot)
  name: varModDepNames.modPolAssiIntRootDeployDenyRSGLocations
  params: {
    parPolicyAssignmentDefinitionId: varPolicyAssignmentDeployDenyRSGLocations.definitionId
    parPolicyAssignmentName: varPolicyAssignmentDeployDenyRSGLocations.libDefinition.name
    parPolicyAssignmentDisplayName: varPolicyAssignmentDeployDenyRSGLocations.libDefinition.properties.displayName
    parPolicyAssignmentDescription: varPolicyAssignmentDeployDenyRSGLocations.libDefinition.properties.description
    parPolicyAssignmentParameters: varPolicyAssignmentDeployDenyRSGLocations.libDefinition.properties.parameters
    parPolicyAssignmentIdentityType: varPolicyAssignmentDeployDenyRSGLocations.libDefinition.identity.type
    parPolicyAssignmentEnforcementMode: (parDisableCustomDefaultPolicies || contains(parPolicyAssignmentsToDisableEnforcement, varPolicyAssignmentDeployDenyRSGLocations.libDefinition.name)) ? 'DoNotEnforce' : varPolicyAssignmentDeployDenyRSGLocations.libDefinition.properties.enforcementMode
  }
}

// Modules - Policy Assignments - Platform Management Group

// Module - Policy Assignment - Deny-Public-Endpoints
module modPolAssiPlatformDenyPublicEndpoints '../../../policy/assignments/policyAssignmentManagementGroup.bicep' = if (!contains(parExcludedPolicyAssignments, varPolicyAssignmentDenyPublicEndpoints.libDefinition.name)) {
  scope: managementGroup(varManagementGroupIdsUnioned.platform)
  name: varModDepNames.modPolAssiPlatformDenyPublicEndpoints
  params: {
    parPolicyAssignmentDefinitionId: varPolicyAssignmentDenyPublicEndpoints.definitionId
    parPolicyAssignmentName: varPolicyAssignmentDenyPublicEndpoints.libDefinition.name
    parPolicyAssignmentDisplayName: varPolicyAssignmentDenyPublicEndpoints.libDefinition.properties.displayName
    parPolicyAssignmentDescription: varPolicyAssignmentDenyPublicEndpoints.libDefinition.properties.description
    parPolicyAssignmentParameters: varPolicyAssignmentDenyPublicEndpoints.libDefinition.properties.parameters
    parPolicyAssignmentIdentityType: varPolicyAssignmentDenyPublicEndpoints.libDefinition.identity.type
    parPolicyAssignmentEnforcementMode: (parDisableCustomDefaultPolicies || contains(parPolicyAssignmentsToDisableEnforcement, varPolicyAssignmentDenyPublicEndpoints.libDefinition.name)) ? 'DoNotEnforce' : varPolicyAssignmentDenyPublicEndpoints.libDefinition.properties.enforcementMode
  }
}

// Module - Policy Assignment - Deny-Public-IP-On-NIC
module modPolAssiPlatformDenyPipOnNic '../../../policy/assignments/policyAssignmentManagementGroup.bicep' = if (!contains(parExcludedPolicyAssignments, varPolicyAssignmentDenyPublicIPOnNIC.libDefinition.name)) {
  scope: managementGroup(varManagementGroupIdsUnioned.platform)
  name: varModDepNames.modPolAssiPlatformDenyPipOnNic
  params: {
    parPolicyAssignmentDefinitionId: varPolicyAssignmentDenyPublicIPOnNIC.definitionId
    parPolicyAssignmentDefinitionVersion: varPolicyAssignmentDenyPublicIPOnNIC.libDefinition.properties.definitionVersion
    parPolicyAssignmentName: varPolicyAssignmentDenyPublicIPOnNIC.libDefinition.name
    parPolicyAssignmentDisplayName: varPolicyAssignmentDenyPublicIPOnNIC.libDefinition.properties.displayName
    parPolicyAssignmentDescription: varPolicyAssignmentDenyPublicIPOnNIC.libDefinition.properties.description
    parPolicyAssignmentParameters: varPolicyAssignmentDenyPublicIPOnNIC.libDefinition.properties.parameters
    parPolicyAssignmentIdentityType: varPolicyAssignmentDenyPublicIPOnNIC.libDefinition.identity.type
    parPolicyAssignmentEnforcementMode: (parDisableCustomDefaultPolicies || contains(parPolicyAssignmentsToDisableEnforcement, varPolicyAssignmentDenyPublicIPOnNIC.libDefinition.name)) ? 'DoNotEnforce' : varPolicyAssignmentDenyPublicIPOnNIC.libDefinition.properties.enforcementMode
  }
}

// Modules - Policy Assignments - Landing Zones Management Group

// Module - Policy Assignment - Deny-Public-Endpoints
module modPolAssiLzsDenyPublicEndpoints '../../../policy/assignments/policyAssignmentManagementGroup.bicep' = if (!contains(parExcludedPolicyAssignments, varPolicyAssignmentDenyPublicEndpoints.libDefinition.name)) {
  scope: managementGroup(varManagementGroupIdsUnioned.landingZones)
  name: varModDepNames.modPolAssiLzsDenyPublicEndpoints
  params: {
    parPolicyAssignmentDefinitionId: varPolicyAssignmentDenyPublicEndpoints.definitionId
    parPolicyAssignmentName: varPolicyAssignmentDenyPublicEndpoints.libDefinition.name
    parPolicyAssignmentDisplayName: varPolicyAssignmentDenyPublicEndpoints.libDefinition.properties.displayName
    parPolicyAssignmentDescription: varPolicyAssignmentDenyPublicEndpoints.libDefinition.properties.description
    parPolicyAssignmentParameters: varPolicyAssignmentDenyPublicEndpoints.libDefinition.properties.parameters
    parPolicyAssignmentIdentityType: varPolicyAssignmentDenyPublicEndpoints.libDefinition.identity.type
    parPolicyAssignmentEnforcementMode: (parDisableCustomDefaultPolicies || contains(parPolicyAssignmentsToDisableEnforcement, varPolicyAssignmentDenyPublicEndpoints.libDefinition.name)) ? 'DoNotEnforce' : varPolicyAssignmentDenyPublicEndpoints.libDefinition.properties.enforcementMode
  }
}

// Module - Policy Assignment - Deny-Public-IP-On-NIC
module modPolAssiLzsDenyPipOnNic '../../../policy/assignments/policyAssignmentManagementGroup.bicep' = if (!contains(parExcludedPolicyAssignments, varPolicyAssignmentDenyPublicIPOnNIC.libDefinition.name)) {
  scope: managementGroup(varManagementGroupIdsUnioned.landingZones)
  name: varModDepNames.modPolAssiLzsDenyPipOnNic
  params: {
    parPolicyAssignmentDefinitionId: varPolicyAssignmentDenyPublicIPOnNIC.definitionId
    parPolicyAssignmentDefinitionVersion: varPolicyAssignmentDenyPublicIPOnNIC.libDefinition.properties.definitionVersion
    parPolicyAssignmentName: varPolicyAssignmentDenyPublicIPOnNIC.libDefinition.name
    parPolicyAssignmentDisplayName: varPolicyAssignmentDenyPublicIPOnNIC.libDefinition.properties.displayName
    parPolicyAssignmentDescription: varPolicyAssignmentDenyPublicIPOnNIC.libDefinition.properties.description
    parPolicyAssignmentParameters: varPolicyAssignmentDenyPublicIPOnNIC.libDefinition.properties.parameters
    parPolicyAssignmentIdentityType: varPolicyAssignmentDenyPublicIPOnNIC.libDefinition.identity.type
    parPolicyAssignmentEnforcementMode: (parDisableCustomDefaultPolicies || contains(parPolicyAssignmentsToDisableEnforcement, varPolicyAssignmentDenyPublicIPOnNIC.libDefinition.name)) ? 'DoNotEnforce' : varPolicyAssignmentDenyPublicIPOnNIC.libDefinition.properties.enforcementMode
  }
}

// Module - Policy Assignment - Deny-HybridNetworking
module modPolAssiLzsDenyHybridNet '../../../policy/assignments/policyAssignmentManagementGroup.bicep' = if (!contains(parExcludedPolicyAssignments, varPolicyAssignmentDenyHybridNetworking.libDefinition.name)) {
  scope: managementGroup(varManagementGroupIdsUnioned.landingZones)
  name: varModDepNames.modPolAssiLzsDenyHybridNet
  params: {
    parPolicyAssignmentDefinitionId: varPolicyAssignmentDenyHybridNetworking.definitionId
    parPolicyAssignmentDefinitionVersion: varPolicyAssignmentDenyHybridNetworking.libDefinition.properties.definitionVersion
    parPolicyAssignmentName: varPolicyAssignmentDenyHybridNetworking.libDefinition.name
    parPolicyAssignmentDisplayName: varPolicyAssignmentDenyHybridNetworking.libDefinition.properties.displayName
    parPolicyAssignmentDescription: varPolicyAssignmentDenyHybridNetworking.libDefinition.properties.description
    parPolicyAssignmentParameters: varPolicyAssignmentDenyHybridNetworking.libDefinition.properties.parameters
    parPolicyAssignmentIdentityType: varPolicyAssignmentDenyHybridNetworking.libDefinition.identity.type
    parPolicyAssignmentEnforcementMode: (parDisableCustomDefaultPolicies || contains(parPolicyAssignmentsToDisableEnforcement, varPolicyAssignmentDenyHybridNetworking.libDefinition.name)) ? 'DoNotEnforce' : varPolicyAssignmentDenyHybridNetworking.libDefinition.properties.enforcementMode
  }
}

// Modules - Policy Assignments - Confidential Online Management Group

// (No confidential online management group policy assignments in this module)

// Modules - Policy Assignments - Confidential Corp Management Group

// (No confidential corp management group policy assignments in this module)

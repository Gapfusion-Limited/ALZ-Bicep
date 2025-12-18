targetScope = 'managementGroup'

metadata name = 'ALZ Bicep - Management Groups Module with Scope Escape'
metadata description = 'ALZ Bicep Module to set up Management Group structure, using Scope Escaping feature of ARM to allow deployment not requiring tenant root scope access.'

@sys.description('Prefix used for the management group hierarchy. This management group will be created as part of the deployment.')
@minLength(2)
@maxLength(10)
param parTopLevelManagementGroupPrefix string = 'alz'

@sys.description('Optional suffix for the management group hierarchy. This suffix will be appended to management group names/IDs. Include a preceding dash if required. Example: -suffix')
@maxLength(10)
param parTopLevelManagementGroupSuffix string = ''

@sys.description('Display name for top level management group. This name will be applied to the management group prefix defined in parTopLevelManagementGroupPrefix parameter.')
@minLength(2)
param parTopLevelManagementGroupDisplayName string = 'Azure Landing Zones'

@sys.description('Optional parent for Management Group hierarchy, used as intermediate root Management Group parent, if specified. If empty, default, will deploy beneath Tenant Root Management Group.')
param parTopLevelManagementGroupParentId string = ''

@sys.description('Deploys Corp & Online Management Groups beneath Landing Zones Management Group if set to true.')
param parLandingZoneMgAlzDefaultsEnable bool = true

@sys.description('Deploys Management, Security, Identity and Connectivity Management Groups beneath Platform Management Group if set to true.')
param parPlatformMgAlzDefaultsEnable bool = true

@sys.description('Deploys Confidential Corp & Confidential Online Management Groups beneath Landing Zones Management Group if set to true.')
param parLandingZoneMgConfidentialEnable bool = false

@sys.description('Dictionary Object to allow additional or different child Management Groups of Landing Zones Management Group to be deployed.')
param parLandingZoneMgChildren object = {}

@sys.description('Dictionary Object to allow additional or different child Management Groups of Platform Management Group to be deployed.')
param parPlatformMgChildren object = {}

@description('Deploys Sandbox Management Group beneath the top level Management Group if set to true.')
param parSandboxMgEnable bool

@description('Deploys Decommissioned Management Group beneath the top level Management Group if set to true.')
param parDecommissionedMgEnable bool

@description('Deploys the BHF Cloud Service Provider (CSP) Management Group beneath the top level Management Group if set to true')
param parCloudServiceProviderMgEnable bool

// Platform and Child Management Groups
var varPlatformMg = {
  //name: '${parTopLevelManagementGroupPrefix}-platform${parTopLevelManagementGroupSuffix}'
  name: 'Platform2'
  displayName: 'Platform'
}

// Used if parPlatformMgAlzDefaultsEnable == true
var varPlatformMgChildrenAlzDefault = {
  connectivity2: {
    displayName: 'Connectivity'
  }
  identity2: {
    displayName: 'Identity'
  }
  management2: {
    displayName: 'Management'
  }
  security2: {
    displayName: 'Security'
  }
}

// Landing Zones & Child Management Groups
var varLandingZoneMg = {
  //name: '${parTopLevelManagementGroupPrefix}-landingzones${parTopLevelManagementGroupSuffix}'
  name: 'LandingZones2'
  displayName: 'Landing Zones'
}

// Used if parLandingZoneMgAlzDefaultsEnable == true
var varLandingZoneMgChildrenAlzDefault = {
  corp2: {
    displayName: 'Corp'
  }
  online2: {
    displayName: 'Online'
  }
}

// Used if parLandingZoneMgConfidentialEnable == true
var varLandingZoneMgChildrenConfidential = {
  'confidential-corp2': {
    displayName: 'Confidential Corp'
  }
  'confidential-online2': {
    displayName: 'Confidential Online'
  }
}

// Build final onject based on input parameters for child MGs of LZs
var varLandingZoneMgChildrenUnioned = (parLandingZoneMgAlzDefaultsEnable && parLandingZoneMgConfidentialEnable && (!empty(parLandingZoneMgChildren)))
  ? union(varLandingZoneMgChildrenAlzDefault, varLandingZoneMgChildrenConfidential, parLandingZoneMgChildren)
  : (parLandingZoneMgAlzDefaultsEnable && parLandingZoneMgConfidentialEnable && (empty(parLandingZoneMgChildren)))
      ? union(varLandingZoneMgChildrenAlzDefault, varLandingZoneMgChildrenConfidential)
      : (parLandingZoneMgAlzDefaultsEnable && !parLandingZoneMgConfidentialEnable && (!empty(parLandingZoneMgChildren)))
          ? union(varLandingZoneMgChildrenAlzDefault, parLandingZoneMgChildren)
          : (parLandingZoneMgAlzDefaultsEnable && !parLandingZoneMgConfidentialEnable && (empty(parLandingZoneMgChildren)))
              ? varLandingZoneMgChildrenAlzDefault
              : (!parLandingZoneMgAlzDefaultsEnable && parLandingZoneMgConfidentialEnable && (!empty(parLandingZoneMgChildren)))
                  ? union(varLandingZoneMgChildrenConfidential, parLandingZoneMgChildren)
                  : (!parLandingZoneMgAlzDefaultsEnable && parLandingZoneMgConfidentialEnable && (empty(parLandingZoneMgChildren)))
                      ? varLandingZoneMgChildrenConfidential
                      : (!parLandingZoneMgAlzDefaultsEnable && !parLandingZoneMgConfidentialEnable && (!empty(parLandingZoneMgChildren)))
                          ? parLandingZoneMgChildren
                          : (!parLandingZoneMgAlzDefaultsEnable && !parLandingZoneMgConfidentialEnable && (empty(parLandingZoneMgChildren)))
                              ? {}
                              : {}
var varPlatformMgChildrenUnioned = (parPlatformMgAlzDefaultsEnable && (!empty(parPlatformMgChildren)))
  ? union(varPlatformMgChildrenAlzDefault, parPlatformMgChildren)
  : (parPlatformMgAlzDefaultsEnable && (empty(parPlatformMgChildren)))
      ? varPlatformMgChildrenAlzDefault
      : (!parPlatformMgAlzDefaultsEnable && (!empty(parPlatformMgChildren)))
          ? parPlatformMgChildren
          : (!parPlatformMgAlzDefaultsEnable && (empty(parPlatformMgChildren))) ? {} : {}

// Sandbox Management Group
var varSandboxMg = {
  //name: '${parTopLevelManagementGroupPrefix}-sandbox${parTopLevelManagementGroupSuffix}'
  name: 'Sandbox2'
  displayName: 'Sandbox'
}

// Decomissioned Management Group
var varDecommissionedMg = {
  //name: '${parTopLevelManagementGroupPrefix}-decommissioned${parTopLevelManagementGroupSuffix}'
  name: 'Decommissioned2'
  displayName: 'Decommissioned'
}

// Level 1
resource resTopLevelMg 'Microsoft.Management/managementGroups@2023-04-01' = {
  scope: tenant()
  name: '${parTopLevelManagementGroupPrefix}${parTopLevelManagementGroupSuffix}'
  properties: {
    displayName: parTopLevelManagementGroupDisplayName
    details: {
      parent: {
        id: empty(parTopLevelManagementGroupParentId)
          ? '/providers/Microsoft.Management/managementGroups/${tenant().tenantId}'
          : contains(
                toLower(parTopLevelManagementGroupParentId),
                toLower('/providers/Microsoft.Management/managementGroups/')
              )
              ? parTopLevelManagementGroupParentId
              : '/providers/Microsoft.Management/managementGroups/${parTopLevelManagementGroupParentId}'
      }
    }
  }
}

// Level 2
resource resPlatformMg 'Microsoft.Management/managementGroups@2023-04-01' = {
  scope: tenant()
  name: varPlatformMg.name
  properties: {
    displayName: varPlatformMg.displayName
    details: {
      parent: {
        id: resTopLevelMg.id
      }
    }
  }
}

resource resLandingZonesMg 'Microsoft.Management/managementGroups@2023-04-01' = {
  scope: tenant()
  name: varLandingZoneMg.name
  properties: {
    displayName: varLandingZoneMg.displayName
    details: {
      parent: {
        id: resTopLevelMg.id
      }
    }
  }
}

//BHF Custom Level 2 for CSP (Cloud Service Provider)
resource resCspMg 'Microsoft.Management/managementGroups@2023-04-01' = if (parCloudServiceProviderMgEnable) {
  scope: tenant()
  name: 'CSP2'
  properties: {
    displayName: 'CSP'
    details: {
      parent: {
        id: resTopLevelMg.id
      }
    }
  }
}

resource resSandboxMg 'Microsoft.Management/managementGroups@2023-04-01' = if (parSandboxMgEnable) {
  scope: tenant()
  name: varSandboxMg.name
  properties: {
    displayName: varSandboxMg.displayName
    details: {
      parent: {
        id: resTopLevelMg.id
      }
    }
  }
}

resource resDecommissionedMg 'Microsoft.Management/managementGroups@2023-04-01' = if (parDecommissionedMgEnable) {
  scope: tenant()
  name: varDecommissionedMg.name
  properties: {
    displayName: varDecommissionedMg.displayName
    details: {
      parent: {
        id: resTopLevelMg.id
      }
    }
  }
}

// Level 3 - Child Management Groups under Landing Zones MG
resource resLandingZonesChildMgs 'Microsoft.Management/managementGroups@2023-04-01' = [
  for mg in items(varLandingZoneMgChildrenUnioned): if (!empty(varLandingZoneMgChildrenUnioned)) {
    scope: tenant()
    //name: '${parTopLevelManagementGroupPrefix}-landingzones-${mg.key}${parTopLevelManagementGroupSuffix}'
    name: mg.key
    properties: {
      displayName: mg.value.displayName
      details: {
        parent: {
          id: resLandingZonesMg.id
        }
      }
    }
  }
]

//Level 3 - Child Management Groups under Platform MG
resource resPlatformChildMgs 'Microsoft.Management/managementGroups@2023-04-01' = [
  for mg in items(varPlatformMgChildrenUnioned): if (!empty(varPlatformMgChildrenUnioned)) {
    scope: tenant()
    //name: '${parTopLevelManagementGroupPrefix}-platform-${mg.key}${parTopLevelManagementGroupSuffix}'
    name: mg.key
    properties: {
      displayName: mg.value.displayName
      details: {
        parent: {
          id: resPlatformMg.id
        }
      }
    }
  }
]

//BHF Custom Level 3 for CSP's (Cloud Service Provider's)
resource resCspRsMg 'Microsoft.Management/managementGroups@2023-04-01' = if (parCloudServiceProviderMgEnable) {
  scope: tenant()
  name: 'Rackspace2'
  properties: {
    displayName: 'Rackspace'
    details: {
      parent: {
        id: resCspMg.id
      }
    }
  }
}

//BHF Custom Level 5 LandingZones Level 4 Management Groups)
//Data Science Environment (DSE)
resource resDmlzRsMg 'Microsoft.Management/managementGroups@2023-04-01' = if (!empty(parLandingZoneMgChildren)) {
  scope: tenant()
  name: 'DMLZ2'
  properties: {
    displayName: 'Data Management Landing Zone'
    details: {
      parent: {
        id: resourceId('Microsoft.Management/managementGroups', 'DSE2')
      }
    }
  }
  dependsOn: [
    resLandingZonesChildMgs
  ]
}

resource resDlzRsMg 'Microsoft.Management/managementGroups@2023-04-01' = if (!empty(parLandingZoneMgChildren)) {
  scope: tenant()
  name: 'DLZ2'
  properties: {
    displayName: 'Data Science Environment - DLZ'
    details: {
      parent: {
        id: resourceId('Microsoft.Management/managementGroups', 'DSE2')
      }
    }
  }
  dependsOn: [
    resLandingZonesChildMgs
  ]
}

//Enterprise Common Services (ECS)
resource resEcscirRsMg 'Microsoft.Management/managementGroups@2023-04-01' = if (!empty(parLandingZoneMgChildren)) {
  scope: tenant()
  name: 'ECSCIR2'
  properties: {
    displayName: 'Common Integration and Reporting'
    details: {
      parent: {
        id: resourceId('Microsoft.Management/managementGroups', 'ECS2')
      }
    }
  }
  dependsOn: [
    resLandingZonesChildMgs
  ]
}

resource resEcsmgmtRsMg 'Microsoft.Management/managementGroups@2023-04-01' = if (!empty(parLandingZoneMgChildren)) {
  scope: tenant()
  name: 'ECSMGMT2'
  properties: {
    displayName: 'Enterprise Common Services Management'
    details: {
      parent: {
        id: resourceId('Microsoft.Management/managementGroups', 'ECS2')
      }
    }
  }
  dependsOn: [
    resLandingZonesChildMgs
  ]
}

resource resEcsrfRsMg 'Microsoft.Management/managementGroups@2023-04-01' = if (!empty(parLandingZoneMgChildren)) {
  scope: tenant()
  name: 'ECSRF2'
  properties: {
    displayName: 'Retail and Finance'
    details: {
      parent: {
        id: resourceId('Microsoft.Management/managementGroups', 'ECS2')
      }
    }
  }
  dependsOn: [
    resLandingZonesChildMgs
  ]
}

// Output Management Group IDs
output outTopLevelManagementGroupId string = resTopLevelMg.id

output outPlatformManagementGroupId string = resPlatformMg.id
output outPlatformChildrenManagementGroupIds array = [
  //for mg in items(varPlatformMgChildrenUnioned): '/providers/Microsoft.Management/managementGroups/${parTopLevelManagementGroupPrefix}-platform-${mg.key}${parTopLevelManagementGroupSuffix}'
  for mg in items(varPlatformMgChildrenUnioned): '/providers/Microsoft.Management/managementGroups/${mg.key}'
]

output outLandingZonesManagementGroupId string = resLandingZonesMg.id
output outLandingZoneChildrenManagementGroupIds array = [
  //for mg in items(varLandingZoneMgChildrenUnioned): '/providers/Microsoft.Management/managementGroups/${parTopLevelManagementGroupPrefix}-landingzones-${mg.key}${parTopLevelManagementGroupSuffix}'
  for mg in items(varLandingZoneMgChildrenUnioned): '/providers/Microsoft.Management/managementGroups/${mg.key}'
]

output outSandboxManagementGroupId string = resSandboxMg.id

output outDecommissionedManagementGroupId string = resDecommissionedMg.id

// Output Management Group Names
output outTopLevelManagementGroupName string = resTopLevelMg.name

output outPlatformManagementGroupName string = resPlatformMg.name
output outPlatformChildrenManagementGroupNames array = [
  for mg in items(varPlatformMgChildrenUnioned): mg.value.displayName
]

output outLandingZonesManagementGroupName string = resLandingZonesMg.name
output outLandingZoneChildrenManagementGroupNames array = [
  for mg in items(varLandingZoneMgChildrenUnioned): mg.value.displayName
]

output outSandboxManagementGroupName string = resSandboxMg.name

output outDecommissionedManagementGroupName string = resDecommissionedMg.name

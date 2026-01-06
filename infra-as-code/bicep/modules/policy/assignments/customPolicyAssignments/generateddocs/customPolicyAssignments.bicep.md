# ALZ Bicep - Custom Policy Assignments and Exemptions

Assigns Custom Policy Assignments and Exemptions to the Management Group hierarchy

## Parameters

Parameter name | Required | Description
-------------- | -------- | -----------
parTopLevelManagementGroupPrefix | No       | Prefix for management group hierarchy.
parTopLevelManagementGroupSuffix | No       | Optional suffix for management group names/IDs.
parPolicyAssignmentsToDisableEnforcement | No       | Set the enforcement mode to DoNotEnforce for specific custom policies.
parDisableCustomDefaultPolicies | No       | Set the enforcement mode to DoNotEnforce for all custom policies.
parExcludedPolicyAssignments | No       | Names of policy assignments to exclude.
parManagementGroupIdOverrides | Yes      | Specify the ALZ Default Management Group IDs to override as specified in `varManagementGroupIds`. Useful for scenarios when renaming ALZ default management groups names and IDs but not their intent or hierarchy structure.

### parTopLevelManagementGroupPrefix

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Prefix for management group hierarchy.

- Default value: `alz`

### parTopLevelManagementGroupSuffix

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Optional suffix for management group names/IDs.

### parPolicyAssignmentsToDisableEnforcement

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Set the enforcement mode to DoNotEnforce for specific custom policies.

### parDisableCustomDefaultPolicies

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Set the enforcement mode to DoNotEnforce for all custom policies.

- Default value: `False`

### parExcludedPolicyAssignments

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Names of policy assignments to exclude.

### parManagementGroupIdOverrides

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

Specify the ALZ Default Management Group IDs to override as specified in `varManagementGroupIds`. Useful for scenarios when renaming ALZ default management groups names and IDs but not their intent or hierarchy structure.

## Snippets

### Parameter file

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "metadata": {
        "template": "infra-as-code/bicep/modules/policy/assignments/customPolicyAssignments/customPolicyAssignments.json"
    },
    "parameters": {
        "parTopLevelManagementGroupPrefix": {
            "value": "alz"
        },
        "parTopLevelManagementGroupSuffix": {
            "value": ""
        },
        "parPolicyAssignmentsToDisableEnforcement": {
            "value": []
        },
        "parDisableCustomDefaultPolicies": {
            "value": false
        },
        "parExcludedPolicyAssignments": {
            "value": []
        },
        "parManagementGroupIdOverrides": {
            "value": null
        }
    }
}
```

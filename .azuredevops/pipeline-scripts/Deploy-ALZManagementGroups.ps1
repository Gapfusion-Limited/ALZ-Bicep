[CmdletBinding(SupportsShouldProcess=$false)]
param(
    [Parameter(Mandatory=$true)]
    [string]$pseudoRootParentManagementGroupId,
   
    [Parameter(Mandatory = $true)]
    [string]$Location,

    [Parameter()]
    [String]$TemplateFile = "infra-as-code\bicep\modules\managementGroups\",

    [Parameter()]
    [String]$TemplateParameterFile = "infra-as-code\bicep\modules\managementGroups\parameters\managementGroups.parameters.all.json",

    [Parameter(Mandatory = $true)]
    [Boolean]$WhatIfEnabled

)

# Debug - check the exact value and type
Write-Host "PARAM VALUE: '$WhatIfEnabled' | TYPE: $($WhatIfEnabled.GetType().FullName) | IsTrue: $($WhatIfEnabled -eq $true) | IsFalse: $($WhatIfEnabled -eq $false)" -ForegroundColor Magenta
Write-Host "PREFERENCE: WhatIfPreference = $WhatIfPreference" -ForegroundColor Magenta

# Disable the global WhatIfPreference to ensure our explicit control works
$WhatIfPreference = $false

# Convert string values to boolean if needed
if ($WhatIfEnabled -is [string]) {
  $WhatIfEnabled = [System.Convert]::ToBoolean($WhatIfEnabled)
}

# Parameters necessary for deployment

$inputObject = @{
  ManagementGroupId     = $pseudoRootParentManagementGroupId
  DeploymentName        = -join ('alz-MGDeployment-{0}' -f (Get-Date -Format 'yyyyMMddTHHMMssffffZ'))[0..63]
  Location              = $Location
  TemplateFile          = $TemplateFile + "managementGroupsScopeEscape.bicep"
  TemplateParameterFile = $TemplateParameterFile
  Verbose               = $true
}

Write-Host "Deploying Management Groups under Pseudo Root Parent Management Group ID: $pseudoRootParentManagementGroupId"

if ($WhatIfEnabled) {
  Write-Host "Executing in WhatIf mode..." -ForegroundColor Yellow
  New-AzManagementGroupDeployment -WhatIf @inputObject
}
else {
  Write-Host "Executing Deployment..." -ForegroundColor Green
  New-AzManagementGroupDeployment @inputObject
}
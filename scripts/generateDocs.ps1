# https://github.com/Azure/ALZ-Bicep/wiki/Contributing#manually-generating-the-parameter-markdown-files

# Scan for Bicep files recursively in the infra-as-code/bicep/ directory and build them in parallel
Write-Host "==> Starting Bicep build (parallel capable)"
#$bicepFiles = Get-ChildItem -Recurse -Path infra-as-code/bicep/ -Filter '*.bicep' -Exclude 'callModuleFromACR.example.bicep','orchHubSpoke.bicep'
$bicepFiles = Get-ChildItem -Recurse -Path infra-as-code/bicep/modules/policy/assignments/customPolicyAssignments -Filter '*.bicep' -Exclude 'callModuleFromACR.example.bicep','orchHubSpoke.bicep'
if ($PSVersionTable.PSVersion.Major -lt 7) {
  Write-Host "PowerShell version does not support -Parallel. Falling back to sequential builds."
  foreach ($f in $bicepFiles) {
    Write-Information "==> Attempting Bicep Build For File: $f" -InformationAction Continue
    $null = bicep build $f.FullName 2>&1 | Tee-Object -Variable buildOut
    if ($LASTEXITCODE -ne 0) { throw "Bicep build failed for $($f.FullName): `n$buildOut" }
  }
} else {
  $throttle = if ($env:BICEP_BUILD_PARALLEL_LIMIT) { [int]$env:BICEP_BUILD_PARALLEL_LIMIT } else { 8 }
  Write-Host "Using parallel builds with ThrottleLimit=$throttle"
  $errors = [System.Collections.Concurrent.ConcurrentBag[string]]::new()
  $bicepFiles | ForEach-Object -Parallel {
    try {
      Write-Information "==> [Parallel] Building: $($_.FullName)" -InformationAction Continue
      $out = bicep build $_.FullName 2>&1
      if ($LASTEXITCODE -ne 0) { throw "Bicep build failed (exit $LASTEXITCODE) for $($_.FullName): `n$out" }
      else { $out | ForEach-Object { Write-Host $_ } }
    }
    catch {
      [System.Console]::Error.WriteLine($_)
      $errBag = $using:errors
      $msg = "{0}: {1}" -f $_.FullName, $_
      [void]$errBag.Add($msg)
    }
  } -ThrottleLimit $throttle
  if ($errors.Count -gt 0) {
    Write-Host '--- Bicep build errors detected ---'
    $errors | ForEach-Object { Write-Host $_ }
    throw "One or more Bicep builds failed."
  }
}

Install-Module -Name 'PSDocs.Azure' -Repository PSGallery -force; Import-Module PSDocs.Azure -Force
# Scan for Azure JSON template file recursively in the infra-as-code/bicep/ directory and generate markdown in parallel
Write-Host "==> Starting markdown generation (parallel capable)"
#$templates = Get-AzDocTemplateFile -Path infra-as-code/bicep/
$templates = Get-AzDocTemplateFile -Path infra-as-code/bicep/modules/policy/assignments/customPolicyAssignments
$mdThrottle = if ($env:MD_GEN_PARALLEL_LIMIT) { [int]$env:MD_GEN_PARALLEL_LIMIT } else { 8 }
$mdErrors = [System.Collections.Concurrent.ConcurrentBag[string]]::new()
if ($PSVersionTable.PSVersion.Major -lt 7) {
  Write-Host "PowerShell version does not support -Parallel for markdown generation. Falling back to sequential."
  foreach ($t in $templates) {
    try {
      $template = Get-Item -Path $t.TemplateFile
      $templateraw = Get-Content -Raw -Path $t.Templatefile
      $version = $template.Directory.Name
      $docNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($template.Name)
      $jobj = ConvertFrom-Json -InputObject $templateraw
      $outputpathformds = $template.DirectoryName + '/generateddocs'
      New-Item -Path $outputpathformds -ItemType Directory -Force | Out-Null
      $convertedfullpath = $template.DirectoryName + "\\" + $template.Name
      $jobj | ConvertTo-Json -Depth 100 | Set-Content -Path $convertedfullpath
      $mdname = $docNameWithoutExtension + '.bicep'
      Invoke-PSDocument -Module PSDocs.Azure -OutputPath $outputpathformds -InputObject $template.FullName -InstanceName $mdname -Culture en-US
    }
    catch {
      Write-Host "[Markdown-Error] $($template.FullName): $_"
      $mdErrors.Add("$($template.FullName): $_")
    }
  }
} else {
  Write-Host "Using parallel markdown generation with ThrottleLimit=$mdThrottle"
  $templates | ForEach-Object -Parallel {
    try {
      $template = Get-Item -Path $_.TemplateFile
      $templateraw = Get-Content -Raw -Path $_.Templatefile
      $version = $template.Directory.Name
      $docNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($template.Name)
      $jobj = ConvertFrom-Json -InputObject $templateraw
      $outputpathformds = $template.DirectoryName + '/generateddocs'
      New-Item -Path $outputpathformds -ItemType Directory -Force | Out-Null
      $convertedfullpath = $template.DirectoryName + "\\" + $template.Name
      $jobj | ConvertTo-Json -Depth 100 | Set-Content -Path $convertedfullpath
      $mdname = $docNameWithoutExtension + '.bicep'
      Invoke-PSDocument -Module PSDocs.Azure -OutputPath $outputpathformds -InputObject $template.FullName -InstanceName $mdname -Culture en-US
    }
    catch {
      [System.Console]::Error.WriteLine($_)
      $mdErrBag = $using:mdErrors
      $msg = "{0}: {1}" -f $_.TemplateFile, $_
      [void]$mdErrBag.Add($msg)
    }
  } -ThrottleLimit $mdThrottle
}
if ($mdErrors.Count -gt 0) {
  Write-Host '--- Markdown generation errors detected ---'
  $mdErrors | ForEach-Object { Write-Host $_ }
  throw "One or more markdown generations failed."
}

# Clean up generated JSON files from Bicep build
#Get-ChildItem -Recurse -Path infra-as-code/bicep/ -Filter '*.json' -Exclude 'bicepconfig.json','*.parameters.json','*.parameters.*.json','policy_*' | ForEach-Object {
Get-ChildItem -Recurse -Path infra-as-code/bicep/modules/policy/assignments/customPolicyAssignments -Filter '*.json' -Exclude 'bicepconfig.json','*.parameters.json','*.parameters.*.json','policy_*' | ForEach-Object {
  Write-Information "==> Removing generated JSON file $_ from Bicep Build" -InformationAction Continue
  Remove-Item -Path $_.FullName
}
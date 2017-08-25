<#
.SYNOPSIS
This is a LabVIEW Troubleshooting Toolbox, you can find more information in DESCRIPTION.

LVDiagTool.[ps1]
      [-Configure {-TargetInfo {-Address <hostname-or-ip> | -UserName <username> | -Password <password>
                                            | -SshPort <ssh-port>}
                         |-LabVIEWInstallationFolder <FilePath>
                         |-DefaultLogFileDropFolder <FilePath>}]
      [-{Enable|Disable}DebugTokens { -All
                                      |-HostMachine {All | DWarnDialogMultiples | PromoteDWarnInternals
                                                    | DPrintfLogging | Debugging | NumStatusItemsToLog}
                                      |-Target  {All | DWarnDialogMultiples | PromoteDWarnInternals
                                                | DPrintfLogging | Debugging | NumStatusItemsToLog}]
                                      |-NIMAX {All | SafeModeEnabled | SshdEnabled | ConsoleOutEnabled}}]
      [-AdjustTargetUserLimit {-StackSize <Size> | -CoreDumpSize <Size>}]
      [-FetchCoreDump]
      [-GenerateReport {-HostTechReport | -TargetTechReport| -}]
      [-Restart  {LabVIEW | Target | TargetRunTime}]
      [-Help]
#>

Param(
    [switch][alias("enable")]$EnableDebugTokens,
    [switch][alias("disable")]$DisableDebugTokens,
    [switch]$All,
    [string]$NIMAX,
    [string]$Target,
    [string]$HostMachine,
    [switch]$AdjustTargetUserLimit,
    [string]$StackSize,
    [string]$CoreDumpSize,
    [string]$Restart,
    [switch]$Configure,
    [switch]$TargetInfo,
    [string]$Address,
    [string]$UserName,
    [string]$Password,
    [string]$SshPort,
    [string]$LabVIEWInstallationFolder,
    [string]$DefaultLogFileDropFolder,
    [switch]$FetchCoreDump,
    [switch]$GenerateReport,
    [switch]$HostTechReport,
    [switch]$TargetTechReport,
    [switch]$Y,
    [switch]$Help)

$script:scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$script:setRTPath = $script:scriptPath+"/setRT.sh"
$script:helpContentPath = $script:scriptPath+"/HelpContent.txt"
$script:setRTTempPath = $script:scriptPath+"/setRTTemp.txt"
$script:utilityPath = $script:scriptPath+"/LVDiagToolsUtilities.ps1"
$script:plinkPath = $script:scriptPath+"/plink.exe"
$script:pscpPath = $script:scriptPath+"/pscp.exe"
$script:configPath = $script:scriptPath+"/config.xml"
$script:generateReportExe = $script:scriptPath+"/GenerateReport.exe"
$script:configTable = Import-Clixml $script:configPath
$script:tokensConstTable  = @{
  "DWarnDialogMultiples"  = @{$True="True";$False="False"};
  "promoteDWarnInternals" = @{$True="True";$False="False"};
  "DPrintfLogging"        = @{$True="True";$False="False"};
  "Debugging"             = @{$True="True";$False="False"};
  "numstatusitemstolog"   = @{$True="99999";$False="1000"};
}
$script:NIMAXTokenTable = @{
  "SafeMode.enabled"    = "True"
  "sshd.enabled"        = "True"
  "ConsoleOut.enabled"  = "True"
}
$script:wrongTokenErrorMessage="Wrong Token, only DWarnDialogMultiples | PromoteDWarnInternals | DPrintfLogging | Debugging | NumStatusItemsToLog can set"
$script:wrongNIMAXErrorMessage="Wrong Token, only SafeModeEnabled | SshdEnabled | ConsoleOutEnabled can set"
. $script:utilityPath

if($Help.isPresent)
{
  Get-Content $script:helpContentPath
  return
}
$confirmation = Read-Host "Are you Sure You Want To Proceed( Y or N ):"
if (($confirmation -ne 'y') -and (-not $Y.isPresent))
{
  return
}

$script:OS=(Get-WmiObject Win32_OperatingSystem).osarchitecture

if($script:OS.Equals("32-bit"))
{
    Write-Debug "OS: 32bit"
    $script:iniFilePrefix="C:\Program Files\National Instruments\"
}
Else
{
    Write-Debug "OS: 64bit"
    $script:iniFilePrefix="C:\Program Files (x86)\National Instruments\"
}


if($script:configTable["LabVIEWInstallationFolder"])
{
  $script:labViewVersion=($script:configTable["LabVIEWInstallationFolder"].split("\") | findstr LabVIEW).TrimEnd()
}
else
{
  $script:labViewVersion=(Get-ChildItem  $script:iniFilePrefix | Select-Object -Property Name | findstr LabVIEW)[-1].TrimEnd()
}

if($script:labViewVersion.split(" ")[-1].CompareTo("2014") -eq 1)
{
    Write-Debug "LV 2015 and newer"
    $script:bashIniFile="/etc/natinst/share/lvrt.conf"
}
else
{
    Write-Debug "LV 2014 and older"
    $script:bashIniFile="/etc/natinst/share/ni-rt.ini"
}
Write-Debug ("LabVIEW version: "+$script:labViewVersion.split(" ")[-1])


if( -not $script:configTable["LabVIEWInstallationFolder"])
{
  $script:configTable["LabVIEWInstallationFolder"]=$script:iniFilePrefix+$script:labViewVersion
}

if( -not $script:configTable["DefaultLogFileDropFolder"])
{
  $script:configTable["DefaultLogFileDropFolder"]="c:\temp"
}

$script:iniFilePath=$script:configTable["LabVIEWInstallationFolder"]+"\LabVIEW.ini"
Write-Debug ("Ini file path: "+$script:iniFilePath)

$script:iniTempFilePath=$script:configTable["LabVIEWInstallationFolder"]+"\temp"
New-Item $script:iniTempFilePath -force -type file | Out-Null

$script:LabVIEWExecutePath=$script:configTable["LabVIEWInstallationFolder"]+"\LabVIEW.exe"


#function AddIniTokenToTempFile($token,$value,$isinsert)
#{
#$isTokenFind=$FALSE
#if($isinsert){$matchRegex="\[LabVIEW\]"}
#else {$matchRegex=$token}
#( Get-Content  $script:iniTempFilePath  -ErrorAction Stop ) |  Foreach-Object {
#           if($_ -match "^"+$matchRegex)
#           {
#                #Add Lines after the selected pattern
#                if($isinsert){$_}
#                $token+"="+$value
#                $isTokenFind=$TRUE
#           }
#           else
#           {
#                $_
#           }
#  } | Set-Content $script:iniTempFilePath  -ErrorAction Stop
# return $isTokenFind
#}
#
#function AddOneToken($token,$value)
#{
#    if( -not  (AddIniTokenToTempFile $token $value $false)  )
#    {
#      AddIniTokenToTempFile $token $value $true >$null
#    }
#}
#
#function CheckINIFileAndUpdate($tokenTable,$enable)
#{
# try
#   {
#    Get-Content  $script:iniFilePath -ErrorAction Stop | Set-Content $script:iniTempFilePath -ErrorAction Stop
#
#    foreach($token in $tokenTable.keys)
#    {
#    AddOneToken $token $tokenTable[$token][$enable]
#    }
#
#    cp $script:iniTempFilePath $script:iniFilePath -ErrorAction Stop
#    Write-Debug ("Write temp back to ini file: "+$?)
#   }
# catch [Exception]
#   {
#    Write-Host $_.Exception.ToString()
#   }
# finally
#   {
#    Remove-Item $script:iniTempFilePath
#   }
#}
#
#function GetPasswordArg()
#{
#  if($script:configTable["Password"])
#  {
#    return "-pw",$script:configTable["Password"]
#  }
#  else
#  {
#    return ""
#  }
#}
#function GetSSHAddress()
#{
#  if($script:configTable["UserName"])
#  {
#    return $script:configTable["UserName"]+"@"+$script:configTable["Address"]
#  }
#  else
#  {
#    return $script:configTable["Address"]
#  }
#}
#
#function ValidateSSHAdress($func)
#{
#    if($script:configTable["Address"])
#    {
#        Write-Output "Connecting to $(GetSSHAddress)......"
#        & $func $args
#    }
#    else
#    {
#        Write-Output "-TargetAdress is needed you should use -Configure to set it,for more details use get-help"
#        Exit 1
#    }
#}
#
#function RestartTargetRunTime()
#{
#  RunCommandOnTarget "/etc/init.d/nilvrt restart"
#  Write-Output "Resart LVRT is ok!"
#}
#function RestartTarget()
#{
#  RunCommandOnTarget "reboot"
#  Write-Output "Wating for reboot!"
#  if( (Test-Connection -quiet $script:configTable["Address"] -delay 10 -count 3) -or
#      (Test-Connection -quiet $script:configTable["Address"] -delay 10 -count 4) )
#  {
#      Write-Output "Reboot done."
#      return
#  }
#  Write-Output "Timeout(70s) to reconnect to the target. Please check the target."
#  Exit 1
#}
#function RestartLabVIEW()
#{
#  $labviewProcess = Get-Process -Name LabVIEW
#  if($labviewProcess)
#  {
#    Stop-Process -InputObject $labviewProcess
#  }
#  else
#  {
#    Write-Output "LabVIEW seems not running, we start it now"
#  }
#  Start-Process $script:LabVIEWExecutePath
#}
#
#function PrepareForSetRTTempfile()
#{
#  Copy-Item $script:setRTPath $script:setRTTempPath -force
#  Add-Content $script:setRTTempPath "iniFile=`"$script:bashIniFile`""
#}
#function UpdateTokensOnTarget()
#{
#   & $script:plinkPath -ssh $(GetSSHAddress) $(GetPasswordArg) -m $script:setRTTempPath | Write-Output
#   if(-not $?)
#   {
#     Exit 1
#   }
#}
#function RunCommandOnTarget($command)
#{
#  & $script:plinkPath -ssh $(GetSSHAddress) $(GetPasswordArg) $command 2>&1 | Write-Output
#  if(-not $?)
#  {
#    Exit 1
#  }
#}
#function CheckToken($token)
#{
#  if($script:tokensConstTable.ContainsKey("$token"))
#  {
#    return $True
#  }
#  else
#  {
#    return $True
#  }
#}
PrepareForSetRTTempfile
if($Configure.isPresent)
{
  if($TargetInfo.isPresent)
  {
   if($Address)
    {
    $script:configTable["Address"]=$Address
    }
    if($UserName)
    {
    $script:configTable["UserName"]=$UserName
    }
    if($Password)
    {
    $script:configTable["Password"]=$Password
    }
    if($SshPort)
    {
    $script:configTable["SshPort"]=$SshPort
    }
  }
  if($LabVIEWInstallationFolder)
  {
  $script:configTable["LabVIEWInstallationFolder"]=$LabVIEWInstallationFolder
  }
  if($DefaultLogFileDropFolder)
  {
  $script:configTable["DefaultLogFileDropFolder"]=$DefaultLogFileDropFolder
  }
  SaveConfig
}

if($Restart)
{
  switch($Restart)
  {
    "LabVIEW"       {RestartLabVIEW; break;}
    "Target"        {ValidateSSHAdress RestartTarget | Out-Null ; break;}
    "TargetRunTime" {ValidateSSHAdress RestartTargetRunTime | Out-Null ; break;}
  }
}

if($EnableDebugTokens.isPresent)
{
  if($HostMachine)
  {
    if($HostMachine -eq "All")
    {
      CheckINIFileAndUpdate $script:tokensConstTable $True
    }
    elseif($script:tokensConstTable.ContainsKey("$HostMachine"))
    {
      CheckINIFileAndUpdate @{$HostMachine=$script:tokensConstTable[$HostMachine]} $True
    }
    else
    {
      Write-Output $script:wrongTokenErrorMessage
      return
    }
  }
  elseif($Target)
  {
    if($Target -eq "All")
    {
      Add-Content $script:setRTTempPath "EnableINITokens"
    }
    elseif($script:tokensConstTable.ContainsKey("$Target"))
    {
      Add-Content $script:setRTTempPath "EnableINITokens $Target"
    }
    else
    {
        Write-Output $script:wrongTokenErrorMessage
        return
    }
    ValidateSSHAdress UpdateTokensOnTarget | Out-Null
  }
  elseif($NIMAX){
    if($NIMAX -eq "All")
    {
      Add-Content $script:setRTTempPath "EnableNiMaxTokens"
    }
    elseif($script:NIMAXTokenTable.ContainsKey("$NIMAX"))
    {
      Add-Content $script:setRTTempPath "EnableNiMaxTokens $NIMAX"
    }
    else
    {
      Write-Output $script:wrongNIMAXErrorMessage
      return
    }
    ValidateSSHAdress UpdateTokensOnTarget | Out-Null
  }
  elseif($ALL.isPresent)
  {
    CheckINIFileAndUpdate $script:tokensConstTable $True
    Add-Content $script:setRTTempPath "EnableINITokens"
    Add-Content $script:setRTTempPath "EnableNiMaxTokens"
    ValidateSSHAdress UpdateTokensOnTarget | Out-Null
  }
}


if($DisableDebugTokens.isPresent)
{
  if($HostMachine)
  {
    if($HostMachine -eq "All")
    {
      CheckINIFileAndUpdate $script:tokensConstTable $False
    }
    elseif($script:tokensConstTable.ContainsKey("$HostMachine"))
    {
      CheckINIFileAndUpdate @{$HostMachine=$script:tokensConstTable[$HostMachine]} $False
    }
    else
    {
      Write-Output $script:wrongTokenErrorMessage
      return
    }
  }
  elseif($Target)
  {
    if($Target -eq "All")
    {
      Add-Content $script:setRTTempPath "DisableINITokens"
    }
    elseif($script:tokensConstTable.ContainsKey("$Target"))
    {
      Add-Content $script:setRTTempPath "DisableINITokens $Target"
    }
    else
    {
        Write-Output $script:wrongTokenErrorMessage
        return
    }
    ValidateSSHAdress UpdateTokensOnTarget | Out-Null
  }
  elseif($NIMAX){
    if($NIMAX -eq "All")
    {
      Add-Content $script:setRTTempPath "DisableNiMaxTokens"
    }
    elseif($script:NIMAXTokenTable.ContainsKey("$NIMAX"))
    {
      Add-Content $script:setRTTempPath "DisableNiMaxTokens $NIMAX"
    }
    else
    {
      Write-Output $script:wrongNIMAXErrorMessage
      return
    }
    ValidateSSHAdress UpdateTokensOnTarget | Out-Null
  }
  elseif($ALL.isPresent)
  {
    CheckINIFileAndUpdate $script:tokensConstTable $False
    Add-Content $script:setRTTempPath "DisableINITokens"
    Add-Content $script:setRTTempPath "DisableNiMaxTokens"
    ValidateSSHAdress UpdateTokensOnTarget | Out-Null
  }
}

if($AdjustTargetUserLimit.isPresent)
{
  if($StackSize)
  {
    Add-Content $script:setRTTempPath "SetThreadSizeAndDumpFileSize Stack"
  }
  elseif($CoreDumpSize)
  {
    Add-Content $script:setRTTempPath "SetThreadSizeAndDumpFileSize CoreDump"
  }
  else
  {
    Write-Output "-StackSize or -CoreDumpSize should be set."
    return
  }
  ValidateSSHAdress UpdateTokensOnTarget | Out-Null
}
if($FetchCoreDump.isPresent)
{
    ValidateSSHAdress RunCommandOnTarget "cd /var/local/natinst/log/ && tar -cf myCoreDump.tar core_dump.\!usr\!local\!natinst\!labview\!lvrt"
    & $script:pscpPath ($(GetSSHAddress)+":/var/local/natinst/log/myCoreDump.tar") $script:configTable["DefaultLogFileDropFolder"] | Write-Output
    if(-not $?)
    {
      Exit 1
    }
}
#function CheckExistAndRename($path,$name)
#{
#  if(Test-Path $path)
#  {
#    Move-Item $path ((Split-Path -Path D:\tempHostNiMAXReport.zip -parent )+$name) -force
#  }
#  else
#  {
#    Write-Output "Generate $name failed"
#    Exit 1
#  }
#}
if($GenerateReport.isPresent)
{
    $hostReportTempPath = Join-Path -path $script:configTable["DefaultLogFileDropFolder"] -ChildPath "tempHostNiMAXReport.zip"
    $targetReportTempPath = Join-Path -path $script:configTable["DefaultLogFileDropFolder"] -ChildPath "tempTargetNiMAXReport.zip"

    if($TargetTechReport.isPresent)
    {
      & $script:generateReportExe $script:configTable["Address"] $targetReportTempPath | Out-Null
      CheckExistAndRename $targetReportTempPath "TargetNiMAXReport.zip"
    }
    elseif($HostTechReport.isPresent)
    {
      & $script:generateReportExe localhost $hostReportTempPath | Out-Null
      CheckExistAndRename $hostReportTempPath "HostNiMAXReport.zip"
    }
    else
    {
      & $script:generateReportExe $script:configTable["Address"] $targetReportSavePath | Out-Null
      CheckExistAndRename $targetReportTempPath "TargetNiMAXReport.zip"
      & $script:generateReportExe localhost $hostReportSavePath | Out-Null
      CheckExistAndRename $hostReportTempPath "HostNiMAXReport.zip"
    }
}
if(Test-Path $script:setRTTempPath)
{
  Remove-Item $script:setRTTempPath
}

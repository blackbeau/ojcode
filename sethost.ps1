<#

.SYNOPSIS
This is a simple Powershell script to explain how to create help

.DESCRIPTION
The script itself will only print 'Hello World'. But that's cool. It's main objective is to show off the cool help thingy anyway.

.EXAMPLE
./HelloWorld.ps1

.NOTES
Put some notes here.

.LINK
http://kevinpelgrims.wordpress.com

#>


#Param(
 #   [parameter(Mandatory=$true)] #(Mandatory=$true)
  #  [alias("set")]
  #  $Settarget,
  #  [alias("tar")]
  #  $Target,
  #  [alias("pa")]

Param(
    [string]
    [AllowEmptyString()]$test,
    [switch][alias("enable")]$EnableDebugSettings,
    [switch][alias("disable")]$DisableDebugSettings,
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
    [switch]$TargetTechReport)

$script:scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$script:setRTPath = $script:scriptPath+"/setRT.txt"
$script:setRTTempPath = $script:scriptPath+"/setRTTemp.txt"
$script:plinkPath = $script:scriptPath+"/plink.exe"
$script:ConfigPath = $script:scriptPath+"/config.xml"
$script:GenerateReportExe = $script:scriptPath+"/GenerateReport.exe"
$script:ConfigTable = Import-Clixml $script:ConfigPath
$script:TokensConstTable = @{
  "DWarnDialogMultiples"  = @{$True="True";$False="False"};
  "promoteDWarnInternals" = @{$True="True";$False="False"};
  "DPrintfLogging"        = @{$True="True";$False="False"};
  "Debugging"             = @{$True="True";$False="False"};
  "numstatusitemstolog"   = @{$True="99999";$False="1000"};
}

function SaveConfig()
{
    Export-Clixml -Path config.xml -InputObject $script:ConfigTable
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

$script:labViewVersion=(Get-ChildItem  $script:iniFilePrefix | Select-Object -Property Name | findstr LabVIEW)[-1].TrimEnd()

if($script:labViewVersion.split(" ")[-1].CompareTo("2014") -eq 1)
{
    Write-Debug "LV 2015 and newer"
    $script:bashIniFile="/etc/natinst/share/lvrt.conf"
}
Else
{
    Write-Debug "LV 2014 and older"
    $script:bashIniFile="/etc/natinst/share/ni-rt.ini"
}
Write-Debug ("LabVIEW version: "+$script:labViewVersion.split(" ")[-1])
#(Get-Content $script:setRTPath ) | Foreach-Object {
#
#           if($_ -match "^iniFile=")
#           {
#                #Add Lines after the selected pattern
#                "iniFile="+$script:bashIniFile
#           }
#           else
#           {
#           $_
#           }
# } | Set-Content $script:setRTPath

if( -not $script:ConfigTable["LabVIEWInstallationFolder"])
{
  $script:ConfigTable["LabVIEWInstallationFolder"]=$script:iniFilePrefix+$script:labViewVersion
}

if( -not $script:ConfigTable["DefaultLogFileDropFolder"])
{
  $script:ConfigTable["DefaultLogFileDropFolder"]="c:\temp"
}

$script:iniFilePath=$script:ConfigTable["LabVIEWInstallationFolder"]+"\LabVIEW.ini"
Write-Debug ("Ini file path: "+$script:iniFilePath)

$script:iniTempFilePath=$script:ConfigTable["LabVIEWInstallationFolder"]+"\temp"
New-Item $script:iniTempFilePath -force -type file | Out-Null

$script:LabVIEWExecutePath=$script:ConfigTable["LabVIEWInstallationFolder"]+"\LabVIEW.exe"

#function GetTokenLine($token)
#{
#   $findAns=(cat $script:iniFilePath | findstr -N $token )
#   if ( $findAns -eq $null )
#   {
#      return 0
#   }
#   else
#   {
#      return $findAns.split(":")[0]
#   }
#
#}
#
#function AddIniToken($token,$value)
#{
#    $tokenAlreadyExistLineNumber =(GetTokenLine $token)
#    #echo "$defaultLineNumberToInsert,??,$tokenLineNumber"
#    if($tokenAlreadyExistLineNumber -eq 0)
#    {
#     $tokenToAdd.add($token+"="+$value)
#     #$fileArrayList.insert($defaultLineNumberToInsert,$token+"="+$value)
#    }
#    else
#    {
#     $fileArrayList[$tokenAlreadyExistLineNumber-1] = $token+"="+$value
#    }
#}
#
#function CheckINIFileAndUpdate()
#{
#  try
#   {
#    $tokenToAdd = New-Object System.Collections.ArrayList
#    $fileArrayList=[System.Collections.ArrayList](cat $script:iniFilePath -ErrorAction Stop  )
#    $defaultLineNumberToInsert=(GetTokenLine \[LabVIEW\])
#    AddIniToken  DWarnDialogMultiples True
#    AddIniToken  promoteDWarnInternals True
#    AddIniToken  DPrintfLogging True
#    AddIniToken  Debugging True
#    AddIniToken  numstatusitemstolog 99999
#    $fileArrayList.insert($defaultLineNumberToInsert,$tokenToAdd)
#    $fileArrayList | % {$_ | Out-File -append  $script:iniTempFilePath}
#    Write-Debug ("Write ini to temp file: "+$?)
#    cp $script:iniTempFilePath $script:iniFilePath
#    Write-Debug ("Write temp back to ini file: "+$?)
#    }
#  catch [Exception]
#    {
#    Write-Host $_.Exception.ToString()
#    }
#  finally
#    {
#    Remove-Item $script:iniTempFilePath
#    }
#}
#
#function UndoINIFileAndUpdate
#{
#  try
#   {
#    Get-Content $script:iniFilePath -ErrorAction Stop |  Foreach-Object {
#
#           if($_ -match "^(?!((^DWarnDialogMultiples)|(^promoteDWarnInternals)|(^DPrintfLogging)|(^Debugging)|(^numstatusitemstolog)))")
#           {
#               $_
#           }
#         } | Set-Content  $script:iniTempFilePath -ErrorAction Stop
#    cp $script:iniTempFilePath $script:iniFilePath -ErrorAction Stop
#    Write-Debug ("Write temp back to ini file: "+$?)
#    }
#  catch [Exception]
#    {
#    Write-Host $_.Exception.ToString()
#    }
#  finally
#    {
#    Remove-Item $script:iniTempFilePath
#    }
#}

#UndoINIFileAndUpdate

function AddIniTokenToTempFile($token,$value,$isinsert)
{
$isTokenFind=$FALSE
if($isinsert){$matchRegex="\[LabVIEW\]"}
else {$matchRegex=$token}
( Get-Content  $script:iniTempFilePath  -ErrorAction Stop ) |  Foreach-Object {
           if($_ -match "^"+$matchRegex)
           {
                #Add Lines after the selected pattern
                if($isinsert){$_}
                $token+"="+$value
                $isTokenFind=$TRUE
           }
           else
           {
                $_
           }
  } | Set-Content $script:iniTempFilePath  -ErrorAction Stop
 return $isTokenFind
}

function AddOneToken($token,$value)
{
    #$re =  AddIniTokenToTempFile $token $value $false
    if( -not  (AddIniTokenToTempFile $token $value $false)  )
    {
      AddIniTokenToTempFile $token $value $true >$null
    }
}

function CheckINIFileAndUpdateV2($tokenTable,$enable)
{
 try
   {

    Get-Content  $script:iniFilePath -ErrorAction Stop | Set-Content $script:iniTempFilePath -ErrorAction Stop

    foreach($token in $tokenTable.keys)
    {
    AddOneToken $token $tokenTable[$token][$enable]
    }

    #AddOneToken  DWarnDialogMultiples $iniTokenFlag
    #
    #AddOneToken  promoteDWarnInternals $iniTokenFlag
    #
    #AddOneToken  DPrintfLogging $iniTokenFlag
    #
    #AddOneToken  Debugging $iniTokenFlag
    #
    #AddOneToken  numstatusitemstolog $iniTokenNum

    cp $script:iniTempFilePath $script:iniFilePath -ErrorAction Stop
    Write-Debug ("Write temp back to ini file: "+$?)
   }
 catch [Exception]
   {
    Write-Host $_.Exception.ToString()
   }
 finally
   {
    Remove-Item $script:iniTempFilePath
   }
}

#CheckINIFileAndUpdateV2 $false
#CheckINIFileAndUpdate
#./plink -ssh admin@10.144.16.189  -m shc.txt
#foreach ($line in $fileArrayList)
#{
#   #echo $line
#    $line | Out-File -append  $script:iniTempFilePath
#}

#if($Settarget.Equals("all"))
#{
#    Write-Debug "set both host and target"
#    CheckINIFileAndUpdate
#    ./plink -ssh $target  -m setRT.txt
#}
#elseif($Settarget.Equals("host"))
#{
 #   Write-Debug "set only on host"
 #   CheckINIFileAndUpdate
#}
#else
#{
#    Write-Debug "set only on target"
#    ./plink -ssh $target  -m setRT.txt
#}
function GetPasswordArg()
{
  if($script:ConfigTable["Password"])
  {
    return "-pw",$script:ConfigTable["Password"]
  }
  else{
    return ""
  }
}
function GetSSHAddress()
{
  if($script:ConfigTable["UserName"])
  {
    return $script:ConfigTable["UserName"]+"@"+$script:ConfigTable["Address"]
  }
  else
  {
    return $script:ConfigTable["Address"]
  }
}

function ValidateSSHAdress($func)
{
if($script:ConfigTable["Address"])
    {
        & $func
    }
    else
    {
        echo "`n-SSHAdress is needed to specify target address( like -SSHAdress root@192.168.1.1 ),for more details use get-help"
    }
}

function RestartTargetRunTime()
{
     & $script:plinkPath -ssh $(GetSSHAddress) $(GetPasswordArg) "/etc/init.d/nilvrt restart"
        if($?)
        {
            echo "`nResart LVRT is ok!"
        }
        else
        {
            echo "`nResart LVRT is failed, please retry!"
        }
}
function RestartTarget()
{
    & $script:plinkPath -ssh $(GetSSHAddress) $(GetPasswordArg) reboot
    if($?)
    {
      echo "`nWating for reboot!"
      if( (Test-Connection -quiet $script:ConfigTable["Address"] -delay 10 -count 3) -or
           (Test-Connection -quiet $script:ConfigTable["Address"] -delay 10 -count 4) )
      {
          echo "`nReboot is ok!"
          return
      }
    }
    echo "`nReboot target is failed, please retry!"
}
function RestartLabVIEW()
{
  $labviewProcess = Get-Process -Name LabVIEW
  if($labviewProcess)
  {
    Stop-Process -InputObject $labviewProcess
  }
  else
  {
    echo "LabVIEW seems not running, we start it now"
  }
  Start-Process $script:LabVIEWExecutePath
}

function prepareForSetRTTempfile()
{
  Copy-Item $script:setRTPath $script:setRTTempPath -force
  Add-Content $script:setRTTempPath "iniFile=`"$script:bashIniFile`""
}
function updateTokensOnTarget()
{
   & $script:plinkPath -ssh $(GetSSHAddress) $(GetPasswordArg) -m $script:setRTTempPath
}
#if($RebootRT.isPresent)
#{
#  ValidateSSHAdress RestartTarget
#  return
#}
#
#if($ResartLVRT.isPresent)
#{
#  ValidateSSHAdress RestartTargetRunTime
#  return
#}
prepareForSetRTTempfile
if($Configure.isPresent)
{
  if($TargetInfo.isPresent)
  {
   if($Address)
    {
    $script:ConfigTable["Address"]=$Address
    }
    if($UserName)
    {
    $script:ConfigTable["UserName"]=$UserName
    }
    if($Password)
    {
    $script:ConfigTable["Password"]=$Password
    }
    if($SshPort)
    {
    $script:ConfigTable["SshPort"]=$SshPort
    }
  }
  if($LabVIEWInstallationFolder)
  {
  $script:ConfigTable["LabVIEWInstallationFolder"]=$LabVIEWInstallationFolder
  }
  if($DefaultLogFileDropFolder)
  {
  $script:ConfigTable["DefaultLogFileDropFolder"]=$DefaultLogFileDropFolder
  }
  SaveConfig
}

if($Restart)
{
  switch($Restart)
  {
    "LabVIEW"       {RestartLabVIEW; break;}
    "Target"        {ValidateSSHAdress RestartTarget; break;}
    "TargetRunTime" {ValidateSSHAdress RestartTargetRunTime; break;}
  }
}
if($EnableDebugSettings.isPresent)
{
  if($HostMachine){
    if($HostMachine -eq "All")
    {
      CheckINIFileAndUpdateV2 $script:TokensConstTable $True

    }
    else
    {
      CheckINIFileAndUpdateV2 @{$HostMachine=$script:TokensConstTable[$HostMachine]} $True # todo check tokens add plink
    }
  }
  elseif($Target)
  {
    if($Target -eq "All")
    {
      Add-Content $script:setRTTempPath "EnableINITokens"
    }
    else
    {
      Add-Content $script:setRTTempPath "EnableINITokens $Target"
    }
    ValidateSSHAdress updateTokensOnTarget
  }
  elseif($NIMAX){
    if($NIMAX -eq "All")
    {
      Add-Content $script:setRTTempPath "EnableNiMaxTokens"
    }
    else
    {
      Add-Content $script:setRTTempPath "EnableNiMaxTokens $NIMAX"
    }
    ValidateSSHAdress updateTokensOnTarget
  }
  elseif($ALL.isPresent)
  {
    CheckINIFileAndUpdateV2 $script:TokensConstTable $True
    Add-Content $script:setRTTempPath "EnableINITokens"
    Add-Content $script:setRTTempPath "EnableNiMaxTokens"
    ValidateSSHAdress updateTokensOnTarget
  }
}


if($DisableDebugSettings.isPresent)
{
  if($HostMachine){
    if($HostMachine -eq "All")
    {
      CheckINIFileAndUpdateV2 $script:TokensConstTable $False

    }
    else
    {
      CheckINIFileAndUpdateV2 @{$HostMachine=$script:TokensConstTable[$HostMachine]} $False # todo check tokens add plink
    }
  }
  elseif($Target)
  {
    if($Target -eq "All")
    {
      Add-Content $script:setRTTempPath "DisableINITokens"
    }
    else
    {
      Add-Content $script:setRTTempPath "DisableINITokens $Target"
    }
    ValidateSSHAdress updateTokensOnTarget
  }
  elseif($NIMAX){
    if($NIMAX -eq "All")
    {
      Add-Content $script:setRTTempPath "DisableNiMaxTokens"
    }
    else
    {
      Add-Content $script:setRTTempPath "DisableNiMaxTokens $NIMAX"
    }
    ValidateSSHAdress updateTokensOnTarget
  }
  elseif($ALL.isPresent)
  {
    CheckINIFileAndUpdateV2 $script:TokensConstTable $False
    Add-Content $script:setRTTempPath "DisableINITokens"
    Add-Content $script:setRTTempPath "DisableNiMaxTokens"
    ValidateSSHAdress updateTokensOnTarget
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
    echo "-StackSize or -CoreDumpSize should be set."
  }
}
if($FetchCoreDump.isPresent)
{
    & $script:plinkPath -ssh $(GetSSHAddress) $(GetPasswordArg) "ls /var/local/natinst/log/core_dump.\!usr\!local\!natinst\!labview\!lvrt"
    if($?){
      & $script:plinkPath -ssh $(GetSSHAddress) $(GetPasswordArg) "tar -cf myCoreDump.tar core_dump.\!usr\!local\!natinst\!labview\!lvrt"
      & $script:pscpPath $(GetSSHAddress)":/var/local/natinst/log/myCoreDump.tar" $script:ConfigTable["DefaultLogFileDropFolder"]
    }
}
if($GenerateReport.isPresent)
{
    $hostReportSavePath = Join-Path -path $script:ConfigTable["DefaultLogFileDropFolder"] -ChildPath "\HostNiMAXReport.zip"
    $targetReportSavePath = Join-Path -path $script:ConfigTable["DefaultLogFileDropFolder"] -ChildPath "\TargetNiMAXReport.zip"
    if($TargetTechReport.isPresent)
    {
      & $script:GenerateReportExe $script:ConfigTable["Address"] $targetReportSavePath　#todo
    }
    elseif($HostTechReport.isPresent)
    {
      & $script:GenerateReportExe localhost $hostReportSavePath  #todo
    }
    else
    {
      & $script:GenerateReportExe $script:ConfigTable["Address"] $targetReportSavePath　#todo check file get ok
      & $script:GenerateReportExe localhost $hostReportSavePath  #todo
    }
}

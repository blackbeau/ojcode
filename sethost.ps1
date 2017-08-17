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
    [switch]
    [alias("enable")]
    $EnableDebugSettings,
    [switch]
    [alias("disable")]
    $DisableDebugSettings,
    [switch]
    $ALL,
    [switch]
    $Target,
    [switch]
    $HostMachine,
    [string]
    $Tokens,
    [string]
    $RunTimeStackSize,
    [string]
    $CoreDumpSize,
    [string]
    $Restart,
    [switch]
    $Configure,
    [switch]
    $TargetInfo,
    [string]
    $Address,
    [string]
    $UserName,
    [string]
    $Password,
    [string]
    $SshPort,
    [string]
    $LabVIEWInstallationFolder,
    [string]
    $DefaultLogFileDropFolder
  )

$script:scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$script:setRTPath = $script:scriptPath+"/setRT.txt"
$script:setRTTempPath = $script:scriptPath+"/setRTTemp.txt"
$script:plinkPath = $script:scriptPath+"/plink.exe"
$script:ConfigPath = $script:scriptPath+"/config.xml"
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

function GetSSHAddress()
{
   $script:ConfigTable["UserName"]+"@"+$script:ConfigTable["Address"]
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

if( -not $script:ConfigTable["DefaultLogFileDropFolder "])
{
  $script:ConfigTable["DefaultLogFileDropFolder"]="c:\temp"
}

$script:iniFilePath=$script:ConfigTable["LabVIEWInstallationFolder"]+"\LabVIEW.ini"
Write-Debug ("Ini file path: "+$script:iniFilePath)

$script:iniTempFilePath=$script:ConfigTable["LabVIEWInstallationFolder"]+"\temp"
New-Item $script:iniTempFilePath -force -type file | Out-Null

$script:LabVIEWExecutePath=$script:ConfigTable["LabVIEWInstallationFolder"]+"\LabVIEW.exe"

function GetTokenLine($token)
{
   $findAns=(cat $script:iniFilePath | findstr -N $token )
   if ( $findAns -eq $null )
   {
      return 0
   }
   else
   {
      return $findAns.split(":")[0]
   }

}

function AddIniToken($token,$value)
{
    $tokenAlreadyExistLineNumber =(GetTokenLine $token)
    #echo "$defaultLineNumberToInsert,??,$tokenLineNumber"
    if($tokenAlreadyExistLineNumber -eq 0)
    {
     $tokenToAdd.add($token+"="+$value)
     #$fileArrayList.insert($defaultLineNumberToInsert,$token+"="+$value)
    }
    else
    {
     $fileArrayList[$tokenAlreadyExistLineNumber-1] = $token+"="+$value
    }
}

function CheckINIFileAndUpdate()
{
  try
   {
    $tokenToAdd = New-Object System.Collections.ArrayList
    $fileArrayList=[System.Collections.ArrayList](cat $script:iniFilePath -ErrorAction Stop  )
    $defaultLineNumberToInsert=(GetTokenLine \[LabVIEW\])
    AddIniToken  DWarnDialogMultiples True
    AddIniToken  promoteDWarnInternals True
    AddIniToken  DPrintfLogging True
    AddIniToken  Debugging True
    AddIniToken  numstatusitemstolog 99999
    $fileArrayList.insert($defaultLineNumberToInsert,$tokenToAdd)
    $fileArrayList | % {$_ | Out-File -append  $script:iniTempFilePath}
    Write-Debug ("Write ini to temp file: "+$?)
    cp $script:iniTempFilePath $script:iniFilePath
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

function UndoINIFileAndUpdate
{
  try
   {
    Get-Content $script:iniFilePath -ErrorAction Stop |  Foreach-Object {

           if($_ -match "^(?!((^DWarnDialogMultiples)|(^promoteDWarnInternals)|(^DPrintfLogging)|(^Debugging)|(^numstatusitemstolog)))")
           {
               $_
           }
         } | Set-Content  $script:iniTempFilePath -ErrorAction Stop
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

#UndoINIFileAndUpdate

function AddIniTokenToTempFile($token,$value,$isinsert)
{
$isTokenFind=$FALSE
if($isinsert){$matchrex="\[LabVIEW\]"}
else {$matchrex=$token}
( Get-Content  $script:iniTempFilePath  -ErrorAction Stop ) |  Foreach-Object {
           if($_ -match "^"+$matchrex)
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
     & $script:plinkPath -ssh $(GetSSHAddress) "/etc/init.d/nilvrt restart"
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
    & $script:plinkPath -ssh $(GetSSHAddress) reboot
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
  Add-Content $script:setRTTempPath "iniFile=/"$script:bashIniFile/""
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

if($Configure.isPresent)
{
  if($TargetInfo.isPresent)
  {
   if($Address)
    {
    $ConfigTable["Address"]=$Address
    }
    if($UserName)
    {
    $ConfigTable["UserName"]=$UserName
    }
    if($Password)
    {
    $ConfigTable["Password"]=$Password
    }
    if($SshPort)
    {
    $ConfigTable["SshPort"]=$SshPort
    }
  }
  if($LabVIEWInstallationFolder)
  {
  $ConfigTable["LabVIEWInstallationFolder"]=$LabVIEWInstallationFolder
  }
  if($DefaultLogFileDropFolder)
  {
  $ConfigTable["DefaultLogFileDropFolder"]=$DefaultLogFileDropFolder
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
  if($HostMachine.isPresent){
    if($Tokens)
    {
      CheckINIFileAndUpdateV2 @{$Tokens=$script:TokensConstTable[$Tokens]} $True
    }
    else
    {
      CheckINIFileAndUpdateV2 $script:TokensConstTable $True
    }
  }
  elseif($Target.isPresent)
  {
    if($Tokens){
      Add-Content $script:setRTTempPath "EnableINITokens $Tokens"
    }
    elseif($RunTimeStackSize){
      Add-Content $script:setRTTempPath "IncreaseThreadSizeAndDumpFileSize Stack"
    }
    elseif($CoreDumpSize){
      Add-Content $script:setRTTempPath "IncreaseThreadSizeAndDumpFileSize CoreDump"
    }
    else{
      Add-Content $script:setRTTempPath "EnableINITokens`t
                                         IncreaseThreadSizeAndDumpFileSize"
    }
  }
  else {
    CheckINIFileAndUpdateV2 $script:TokensConstTable $True
    Add-Content $script:setRTTempPath "EnableINITokens`t
                                       IncreaseThreadSizeAndDumpFileSize"

  }
}
if($DisableDebugSettings.isPresent)
{
  if($HostMachine.isPresent){
    if($Tokens)
    {
      CheckINIFileAndUpdateV2 @{$Tokens=$script:TokensConstTable[$Tokens]} $False
    }
    else
    {
      CheckINIFileAndUpdateV2 $script:TokensConstTable $False
    }
  }
  elseif($Target.isPresent)
  {
    if($Tokens){
      Add-Content $script:setRTTempPath "DisableINITokens $Tokens"
    }
    elseif($RunTimeStackSize){
      Add-Content $script:setRTTempPath "UndoIncreaseThreadSizeAndDumpFileSize Stack"
    }
    elseif($CoreDumpSize){
      Add-Content $script:setRTTempPath "UndoIncreaseThreadSizeAndDumpFileSize CoreDump"
    }
    else{
      Add-Content $script:setRTTempPath "DisableINITokens`t
                                         UndoIncreaseThreadSizeAndDumpFileSize"
    }

  }
  else {
    CheckINIFileAndUpdateV2 $script:TokensConstTable $False
    Add-Content $script:setRTTempPath "DisableINITokens`t
                                       UndoIncreaseThreadSizeAndDumpFileSize"

  }
}
#if($EnableDebugSetting){
# ValidateSSHAdress $SSHAdress "CheckINIFileAndUpdateV2 $false"
#
#}

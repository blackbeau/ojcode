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
  #  $Path)
  
Param(
    [string]
    [alias("enable")]
    $EnableDebugSetting,
    [string]
    [alias("disable")]
    $DisableDebugSetting,
    [string]
    [alias("fetch")]
    $FetchCoreDump,
    [string]
    [alias("ssh")]
    $SSHAdress,
    [string]
    $Path
  )
    
    
$script:scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$script:setRTPath = $script:scriptPath+"/setRT.txt"
echo $script:scriptPath
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
(Get-Content  $script:setRTPath  ) |  Foreach-Object { 
           
           if($_ -match "^iniFile=")
           {
                #Add Lines after the selected pattern
                "iniFile="+$script:bashIniFile
           }
           else
           {
           $_
           }
  } | Set-Content $script:setRTPath 


$script:iniFilePath=$script:iniFilePrefix+$script:labViewVersion+"\LabVIEW.ini"
Write-Debug ("Ini file path: "+$script:iniFilePath)

$script:iniTempFilePath=$script:iniFilePrefix+$script:labViewVersion+"\temp"
New-Item $script:iniTempFilePath -force -type file | Out-Null

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

function CheckINIFileAndUpdateV2($isUndo)
{
 try
   {
    if($isUndo)
    {
     $iniTokenFlag="False"
     $iniTokenNum="0"
    }
    else 
    {
     $iniTokenFlag="True"
     $iniTokenNum="99999"
    }
    Get-Content  $script:iniFilePath -ErrorAction Stop | Set-Content $script:iniTempFilePath -ErrorAction Stop
    
    AddOneToken  DWarnDialogMultiples $iniTokenFlag 
    
    AddOneToken  promoteDWarnInternals $iniTokenFlag 
    
    AddOneToken  DPrintfLogging $iniTokenFlag 
   
    AddOneToken  Debugging $iniTokenFlag 
 
    AddOneToken  numstatusitemstolog $iniTokenNum
    
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


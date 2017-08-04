Param(
    [parameter(Mandatory=$true)]
    [alias("set")]
    $Settarget,
    [alias("tar")]
    $Target,
    [alias("pa")]
    $Path)


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

$script:labViewVersion=(Get-ChildItem  $iniFile | Select-Object -Property Name | findstr LabVIEW)[-1].TrimEnd()

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
(Get-Content  .\setRT.txt ) |  Foreach-Object {

           if($_ -match "^iniFile=")
           {
                #Add Lines after the selected pattern
                "iniFile="+$script:bashIniFile
           }
           else
           {
           $_
           }
  } | Set-Content .\setRT.txt


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

function CheckINIFileAndUpdate
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


#CheckINIFileAndUpdate
#./plink -ssh admin@10.144.16.189  -m shc.txt
#foreach ($line in $fileArrayList)
#{
#   #echo $line
#    $line | Out-File -append  $script:iniTempFilePath
#}

if($Settarget.Equals("all"))
{
    Write-Debug "set both host and target"
    CheckINIFileAndUpdate
    ./plink -ssh $target  -m setRT.txt
}
elseif($Settarget.Equals("host"))
{
    Write-Debug "set only on host"
    CheckINIFileAndUpdate
}
else
{
    Write-Debug "set only on target"
    ./plink -ssh $target  -m setRT.txt
}

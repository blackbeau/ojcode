
$script:OS=(Get-WmiObject Win32_OperatingSystem).osarchitecture

if($script:OS.Equals("32-bit") -eq 1)
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

$script:iniFilePath=$script:iniFilePrefix+$script:labViewVersion+"\LabVIEW.ini"
Write-Debug ("Ini file path: "+$script:iniFilePath)

$script:iniTempFilePath=$script:iniFilePrefix+$script:labViewVersion+"\temp"
New-Item $script:iniTempFilePath -force -type file

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
    $defaultLineNumberToInsert=(GetTokenLine \[LabVIEW\])
    $tokenLineNumber =(GetTokenLine $token)
    echo "$defaultLineNumberToInsert,??,$tokenLineNumber"
    if($tokenLineNumber -eq 0)
    {
     $fileArrayList.insert($defaultLineNumberToInsert,$token+"="+$value)
    }
    else
    {
     $fileArrayList[$tokenLineNumber-1]=$token+"="+$value
    }
}

function CheckINIFileAndUpdate
{
    [System.Collections.ArrayList]$fileArrayList=(cat $script:iniFilePath)
    AddIniToken  DWarnDialogMultiples True
    AddIniToken  promoteDWarnInternals True
    AddIniToken  DPrintfLogging True
    AddIniToken  Debugging True
    AddIniToken  numstatusitemstolog 99999
    $fileArrayList | % {$_ | Out-File -append  $script:iniTempFilePath}
    Write-Debug ("write to temp:"+$?)
    mv $script:iniTempFilePath $script:iniFilePath -force
    Write-Debug ("write back :"+$?)
}
#(cat $script:iniFilePath | findstr -N \[LabVIEW\])

CheckINIFileAndUpdate

#foreach ($line in $fileArrayList)
#{
#   #echo $line
#    $line | Out-File -append  $script:iniTempFilePath
#}

#!/bin/sh
# $1 Ini file path
iniFile=$1
iniTempFile=""
lvrtConfigFile="/etc/init.d/lvrt-wrapper"    #  "/etc/init.d/lvrt-wrapper"
niMaxIniFile="/etc/natinst/share/ni-rt.ini"
lvtrString="\[LVRT\]"
sysString="\[SYSTEMSETTINGS\]"

GetTokenLine()
{
  grep  -n  "$2"   $1  | cut  -d  ":"  -f  1
}

AddIniToken()
{
  # $1 file to check
  # $2 token
  # $3 value
  # $4 ini head to get default line number to insert
  local defaultLineNumberToInsert
  local tokenLineNumber
  defaultLineNumberToInsert=`GetTokenLine $1 "$4"`
  tokenLineNumber=`GetTokenLine $1 $2`
  echo $tokenLineNumber,$defaultLineNumberToInsert
  if [ -n "$tokenLineNumber" ]; then
      echo "$2 token exist"
      sed -i "${tokenLineNumber}c\\$2=$3" $1
  else
      echo "add $2 token"
      sed -i "${defaultLineNumberToInsert}a\\${2}=${3}" $1
  fi
}

CheckINIFileAndUpdate()
{
    AddIniToken $1 DWarnDialogMultiples True $lvtrString
    AddIniToken $1 promoteDWarnInternals True $lvtrString
    AddIniToken $1 DPrintfLogging True $lvtrString
    AddIniToken $1 Debugging True $lvtrString
    AddIniToken $1 numstatusitemstolog 99999 $lvtrString
}

CheckNIMaxINIFileAndUpdate()
{
    AddIniToken $1 SafeMode.enabled False $sysString
    AddIniToken $1 sshd.enabled True $sysString
    AddIniToken $1 ConsoleOut.enabled True $sysString
}

IncreaseThreadSizeAndDumpFileSize()
{
  local defaultLineNumberToInsert
  local tokenLineNumber
  defaultLineNumberToInsert=`GetTokenLine $1 "$2"`
  tokenLineNumber=`GetTokenLine $1 "$2"`
  echo $defaultLineNumberToInsert,$tokenLineNumber
  if [ -n "$tokenLineNumber" ]; then
      echo "$2 token exist"
      sed -i "${tokenLineNumber}c\\$2 $3" $1
  else
      echo "add $2 token"
      sed -i "${defaultLineNumberToInsert}a\\${2} ${3}" $1
  fi
}

CheckINIFileAndUpdate $iniFile
CheckNIMaxINIFileAndUpdate $niMaxIniFile
IncreaseThreadSizeAndDumpFileSize $lvrtConfigFile "ulimit -s" 512
IncreaseThreadSizeAndDumpFileSize $lvrtConfigFile "ulimit -c" unlimited
reboot

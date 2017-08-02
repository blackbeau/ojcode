#!/bin/sh
iniFile=""
iniTempFile=""
lvrtConfigFile=/etc/init.d/lvrt-wrapper
GetTokenLine()
{
  grep  -n  "$2"   $1  | cut  -d  ":"  -f  1
}
AddIniToken()
{
  local defaultLineNumberToInsert
  local tokenLineNumber
  defaultLineNumberToInsert=`GetTokenLine $1 LVRT`
  tokenLineNumber=`GetTokenLine $1 $2`
  #echo $tokenLineNumber $defaultLineNumberToInsert
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
    AddIniToken $1 DWarnDialogMultiples True
    AddIniToken $1 promoteDWarnInternals True
    AddIniToken $1 DPrintfLogging True
    AddIniToken $1 Debugging True
    AddIniToken $1 numstatusitemstolog 99999
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
#CheckINIFileAndUpdate $1
#
# #/etc/init.d/lvrt-wrapper
IncreaseThreadSizeAndDumpFileSize $1 "ulimit -s" 512
IncreaseThreadSizeAndDumpFileSize $1 "ulimit -c" unlimited

rm core_dump.\!usr\!local\!natinst\!labview\!lvrt

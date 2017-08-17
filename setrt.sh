#!/bin/bash
# $1 Ini file path
iniFile=$1
isUndoOperation=true
iniTempFile=""
lvrtConfigFile="/etc/init.d/lvrt-wrapper"    #  "/etc/init.d/lvrt-wrapper"
niMaxIniFile="/etc/natinst/share/ni-rt.ini"
lvtrString="\[LVRT\]"
sysString="\[SYSTEMSETTINGS\]"
declare -A constEnableTokenTable=( [DWarnDialogMultiples]=True
                             [promoteDWarnInternals]=True
                             [DPrintfLogging]=True
                             [Debugging]=True
                             [numstatusitemstolog]=99999 )
declare -A constDisableTokenTable=( [DWarnDialogMultiples]=False
                            [promoteDWarnInternals]=False
                            [DPrintfLogging]=False
                            [Debugging]=False
                            [numstatusitemstolog]=1000 )
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
      sed -i "${defaultLineNumberToInsert}a\\$2=$3" $1
  fi
}

EnableINITokens()
{
  if [ -n "$1" ]; then
    AddIniToken $iniFile $1 ${constEnableTokenTable[$1]} $lvtrString
  else
      for key in "${!constEnableTokenTable[@]}"
      do
        AddIniToken $iniFile $key ${constEnableTokenTable[$key]} $lvtrString
      done
  fi
    # AddIniToken $1 DWarnDialogMultiples True $lvtrString
    # AddIniToken $1 promoteDWarnInternals True $lvtrString
    # AddIniToken $1 DPrintfLogging True $lvtrString
    # AddIniToken $1 Debugging True $lvtrString
    # AddIniToken $1 numstatusitemstolog 99999 $lvtrString
}
DisableINITokens()
{
  if [ -n "$1" ]; then
    AddIniToken $iniFile $1 ${constDisableTokenTable[$1]} $lvtrString
  else
      for key in "${!constDisableTokenTable[@]}"
      do
        AddIniToken $iniFile $key ${constDisableTokenTable[$key]} $lvtrString
      done
  fi
  # AddIniToken $1 DWarnDialogMultiples False $lvtrString
  # AddIniToken $1 promoteDWarnInternals False $lvtrString
  # AddIniToken $1 DPrintfLogging False $lvtrString
  # AddIniToken $1 Debugging False $lvtrString
  # AddIniToken $1 numstatusitemstolog 0 $lvtrString
}
CheckNIMaxINIFileAndUpdate()
{
    AddIniToken $1 SafeMode.enabled False $sysString
    AddIniToken $1 sshd.enabled True $sysString
    AddIniToken $1 ConsoleOut.enabled True $sysString
}

SetThreadSizeAndDumpFileSize()
{
  echo $1
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
      sed -i "${defaultLineNumberToInsert}a\\$2 $3" $1
  fi
}

IncreaseThreadSizeAndDumpFileSize()
{
  if [ "$1" = "Stack" ];then
      SetThreadSizeAndDumpFileSize $lvrtConfigFile "ulimit -s" $2
  elif [ "$1" = "CoreDump" ];then
      SetThreadSizeAndDumpFileSize $lvrtConfigFile "ulimit -c" $2
  else
    SetThreadSizeAndDumpFileSize $lvrtConfigFile "ulimit -s" 512
    SetThreadSizeAndDumpFileSize $lvrtConfigFile "ulimit -c" unlimited
  fi
}

UndoIncreaseThreadSizeAndDumpFileSize()
{
  if [ "$1" = "Stack" ];then
      SetThreadSizeAndDumpFileSize $lvrtConfigFile "ulimit -s" $2
  elif [ "$1" = "CoreDump" ];then
      SetThreadSizeAndDumpFileSize $lvrtConfigFile "ulimit -c" $2
  else
    SetThreadSizeAndDumpFileSize $lvrtConfigFile "ulimit -s" 256
    SetThreadSizeAndDumpFileSize $lvrtConfigFile "ulimit -c" 4096
  fi
}
undoAllOperation(){
  UndoINIFile
  UndoIncreaseThreadSizeAndDumpFileSize
}

# if [ $isUndoOperation = "false" ];then
#   echo "false"
#   EnableINITokens $iniFile
#   CheckNIMaxINIFileAndUpdate $niMaxIniFile
#   IncreaseThreadSizeAndDumpFileSize
#   reboot
# else
#   echo "true"
#   undoAllOperation
# fi
iniFilePath=$1
IncreaseThreadSizeAndDumpFileSize
#DisableINITokens numstatusitemstolog
# CheckNIMaxINIFileAndUpdate $niMaxIniFile
# IncreaseThreadSizeAndDumpFileSize
# reboot

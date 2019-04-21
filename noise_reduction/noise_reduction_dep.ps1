# This script checks dependencies for running noise_reduction*.ps1 scripts and
# produces warnings in cases where those dependencies are not found.
#
# -Joshua McNeill (joshua.mcneill at uga.edu)

# Check the current version of PS and print a warning if it's before 5.1
if ("$($psversiontable.psversion.major).$($psversiontable.psversion.minor)" -lt 5.1)
  {
  write-host "----`nYou're using an older version of PowerShell.`nIf the script fails, try updating to at least version 5.1.`n----"
  }

# Check to see if FFmpeg is in PATH
if (-not ($Env:Path -like "*FFmpeg*"))
  {
  write-host "----`nFFmpeg is either not installed or not in your PATH.`nIf this script fails, that might be why.`n(Only applicable to running noise_reduction.ps1.)`n----"
  }

# Check to see if SoX is in PATH
if (-not ($Env:Path -like "*SoX*"))
  {
  write-host "----`nSoX is either not installed or not in your PATH.`nIf this script fails, that might be why.`n----"
  }

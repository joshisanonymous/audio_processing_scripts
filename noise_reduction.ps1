######################################################################################
# This script is meant to automatically apply SoX noise reduction to any number      #
# of audio recordings, specifically those of speech, that are in a single directory. #
# It attempts to skip over all absolute silences and find normal silences from       #
# which to generate noise profiles that can then be used to apply noise reduction.   #
# To adjust settings for silence detection to be more or less conservative, search   #
# for "silencedetect" and modify the values after n= (amplitude ratio for the        #
# threshold) and d= (duration of silence to count as silence). To adjust settings    #
# for how severe the noise reduction should be, search for "noisered" and adjust     #
# the value at the end of the line, ranging from 0.0 to 1.0 where 1.0 is more        #
# reduction and 0.0 is less.                                                         #
#                                                                                    #
# -Joshua McNeill (joshua.mcneill at uga.edu)                                           #
#                                                                                    #
# Dependencies: FFmpeg, SoX                                                          #
#                                                                                    #
######################################################################################

# Check the current version of PS and print a warning if it's before 5.1
if ("$($psversiontable.psversion.major).$($psversiontable.psversion.minor)" -lt 5.1)
  {
  write-host "----`nYou're using an older version of PowerShell.`nIf the script fails, try updating to at least version 5.1.`n----"
  }

# Check to see if FFmpeg is in PATH
if (-not ($Env:Path -like "*FFmpeg*"))
  {
  write-host "----`nFFmpeg is either not installed or not in your PATH.`nIf this script fails, that might be why.`n----"
  }

# Check to see if SoX is in PATH
if (-not ($Env:Path -like "*SoX*"))
  {
  write-host "----`nSoX is either not installed or not in your PATH.`nIf this script fails, that might be why.`n----"
  }

# Prompt the user to make sure they're set up correctly
$dir = read-host "----`nWhere are your recordings located (e.g., `".\`" for the current directory, `"C:\Recordings\`", etc.)"

# Prompt the user for the file extension of their recordings
$ext = read-host "----`nWhat is the file extension of the recordings you're working with (e.g., `"wav`")"

# Prompt the user for thresholds and durations to consider as absolute silence
$abs_thres = read-host "----`nBelow what amplitude ratio should silence be considered absolute?`nLower may increase the number of recordings that can have noise reduction`napplied automatically but will increase the ris of having it applied poorly,`nand vice versa. The default is 0.01"
$abs_dur = read-host "----`nHow many seconds should absolute silence last before it is considered absolute?`nShorter may increase the number of recordings that can have noise reduction`napplied automatically but will increase the risk of having it applied poorly,`nand vice versa. The default is 1"

# Prompt the user for thresholds and durations to consider as normal silence
$norm_thres = read-host "----`nBelow what amplitude ratio should sound be considered normal silence?`nGood values can vary greatly between recordings. The default is 0.1"
$norm_dur = read-host "----`nHow many seconds should normal silence last before it is considered silence?`nShorter may increase the number of recordings that can have noise reduction`napplied automatically but will increase the risk of having it applied poorly,`nand vice versa. The default is 1"

# Get a list of recordings
$allrecordings = get-childitem -name "$dir*.$ext"

# Create a subdirectory where cleaned recordings will be moved and tell the user to wait
new-item -path "${dir}Cleaned_Recordings" -itemtype directory
write-host "Please wait..."

foreach ($recording in $allrecordings)
  {
  # Detect normal silence
  ffmpeg -i $dir$recording -af silencedetect=n=${norm_thres}:d=$norm_dur -f null - > "${dir}normal_silences.txt" 2>&1
  $normal_silence_check = get-content -path "${dir}normal_silences.txt"

  # Verify if normal silence was in fact found
  if ($normal_silence_check -like "*silence_start*")
    {
    # Start the index from the first time stamp matched
    $groupsindex = 1

    # Get the absolute silences
    ffmpeg -i $dir$recording -af silencedetect=n=${abs_thres}:d=$abs_dur -f null - > "${dir}absolute_silences.txt" 2>&1
    $absolute_silence_check = get-content -path "${dir}absolute_silences.txt"

    # Match the normal silences
    $normal_silence_starts = select-string -path "${dir}normal_silences.txt" -pattern "silence_start: (.*)$"
    $normal_silence_ends = select-string -path "${dir}normal_silences.txt" -pattern "silence_end: (.*) \| silence_duration: .*$"

    # Save the time stamps for the first normal silence matches
    $silence_start = $normal_silence_starts.matches.groups[$groupsindex].value
    $silence_end = $normal_silence_ends.matches.groups[$groupsindex].value

    # Verify that the first normal silence matches are not absolute silence and
    # loop through the matches until either a non-absolute silence is found or
    # otherwise all matches have been checked
    while ($absolute_silence_check -like "*$silence_start*")
      {
      $groupsindex = $groupsindex + 2
      if ($groupsindex -lt $normal_silence_starts.matches.groups.count)
        {
        $silence_start = $normal_silence_starts.matches.groups[$groupsindex].value
        $silence_end = $normal_silence_ends.matches.groups[$groupsindex].value
        }
      else
        {
        write-output "`"Contains only absolute silences`",$recording" >> "${dir}recordings_to_do_manually.csv"
        $silence_start = "END UNSUCCESSFUL LOOP"
        }
      }

    # Moves to the next recording in the case that no good normal silence matches
    # were found
    if ($groupsindex -gt $normal_silence_starts.matches.groups.count)
      {
      continue
      }

    # Trim the normal silence and save it to a new audio file
    sox $dir$recording ${dir}normal_silence.$ext trim $silence_start =$silence_end

    # Create noise profile from the normal silence audio file
    sox ${dir}normal_silence.$ext -n noiseprof ${dir}temp.noise-profile

    # Apply noise reduction to the recording using the noise profile
    sox $dir$recording ${dir}cleaned_$recording noisered ${dir}temp.noise-profile 0.3

    # Creates moves all the cleaned recordings to a subdirectory called Cleaned_Recordings
    move-item -path "${dir}cleaned_$recording" -destination "${dir}Cleaned_Recordings"
    }
  else
    {
    # Add filename to log to do manually
    write-output "`"Failed to find normal silence`",$recording" >> "${dir}recordings_to_do_manually.csv"
    }
  }

# Cleans up extraneous files
remove-item $dir*_silences.txt, ${dir}normal_silence.$ext, ${dir}temp.noise-profile

# Print result messages
get-childitem -name "$dir" > ${dir}directory_contents.txt
$recordings_to_do_manually_check = get-content -path "${dir}directory_contents.txt"
if ($recordings_to_do_manually_check -like "*recordings_to_do_manually*")
  {
  write-host "Your cleaned recordings are in ${dir}Cleaned_Recordings."
  write-host "Check ${dir}recordings_to_do_manually.csv for files that need to be done manually."
  }
else
  {
  write-host "They can be found in ${dir}Cleaned_Recordings."
  write-host "All recordings cleaned!"
  }

# Final cleanup
remove-item ${dir}directory_contents.txt

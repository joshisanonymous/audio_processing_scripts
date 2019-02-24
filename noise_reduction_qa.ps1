# This script is meant to do a quality control check on the silences that were
# used in noise_reduction.ps1 to create noise profiles (saved in
# time_stamps_used.csv). It will play each silence, one by one,
# and ask the user to identify whether the silence was acceptable or not and
# to add comments to each one, all of which is saved to a new csv file:
# noise_reduction_qa_results.csv.
#
# -Joshua McNeill (joshua.mcneill at uga.edu)
#
# Dependencies: SoX

# Check dependencies
. .\noise_reduction_dep.ps1

# Prompt the user for the location of the time_stamps_used.csv and how many files
# that they want to check
$dir_time_stamps = read-host "----`nWhere is time_stamps_used.csv located (e.g., `".\`" for the current directory, `"C:\Recordings\`", etc.)"
$dir_recordings = read-host "----`nWhere are your recordings located (e.g., `".\`" for the current directory, `"C:\Recordings\`", etc.)"
$lines = read-host "----`nHow many of the $($(get-content "${dir_time_stamps}time_stamps_used.csv").length) silences do you want to check?"

# Move to the location of the recordings
set-location -path "$dir_recordings"

# Create a temp file with a random list of files the same size as $lines,
# save the the filenames, start time stamps, and end time stamps to a variable,
# then delete the temp file.
get-content ${dir_time_stamps}time_stamps_used.csv | get-random -count $lines > "${dir_time_stamps}time_stamps_temp.csv"
$files_and_stamps = select-string -path "${dir_time_stamps}time_stamps_temp.csv" -pattern "^(.*),(.*),(.*)$"
remove-item -path "${dir_time_stamps}time_stamps_temp.csv"

# Start with the first match, which should be a filename
$groupsindex = 1

# Playback each silence from one second before to one second after, ask if it
# sounded acceptable, if there was anything noteworthy, then save the results to
# a time_stamps_checked.csv
while ($groupsindex -lt $files_and_stamps.matches.groups.count)
  {
  # Run a loop that plays the audio currently in the parent loop at the specified
  # time stamp loation and then ask if it was acceptable. The child loop allows
  # the user to repeat the silence or to add time (in seconds) around the silence.DESCRIPTION
  # $acceptability is set to "r" so that the audio plays at least once.
  $acceptability = "r"
  do
    {
    if ($acceptability -match "[rR]")
      {
      $temp_start_time = $files_and_stamps.matches.groups[$groupsindex + 1].value
      $temp_end_time = $files_and_stamps.matches.groups[$groupsindex + 2].value
      sox $files_and_stamps.matches.groups[$groupsindex].value -d trim $temp_start_time =$temp_end_time
      }
    elseif ($acceptability -match "[1-9]")
      {
      $temp_start_time = [decimal]$files_and_stamps.matches.groups[$groupsindex + 1].value - $acceptability
      $temp_end_time = [decimal]$files_and_stamps.matches.groups[$groupsindex + 2].value + $acceptability
      sox $files_and_stamps.matches.groups[$groupsindex].value -d trim $temp_start_time =$temp_end_time
      }
    $acceptability = read-host "Was this a good silence (y for yes, n for no, r for repeat, 1-9 to repeat with 1-9 seconds around the silence)"
    }
  until ($acceptability -match "[YnNn]")

  $comment = read-host "Do you have any comments on this silence"

  # Save match values to variable as values so that they work right with write-output
  $file = $files_and_stamps.matches.groups[$groupsindex].value
  $start_time = $files_and_stamps.matches.groups[$groupsindex + 1].value
  $end_time = $files_and_stamps.matches.groups[$groupsindex + 2].value

  # Save the results to a csv file
  write-output "$file,$start_time,$end_time,$acceptability,`"$comment`"" >> time_stamps_checked.csv

  # Move to the next set of matches
  $groupsindex = $groupsindex + 4
  }

write-host "That's all of them!`nThe results are saved in ${dir_recordings}time_stamps_checked.csv."

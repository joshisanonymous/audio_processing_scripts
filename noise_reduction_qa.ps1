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

# Prompt the user for the location of the time_stamps_used.csv
$dir_time_stamps = read-host "----`nWhere is time_stamps_used.csv located (e.g., `".\`" for the current directory, `"C:\Recordings\`", etc.)"
$dir_recordings = read-host "----`nWhere are your recordings located (e.g., `".\`" for the current directory, `"C:\Recordings\`", etc.)"

# Move to the location of the recordings
set-location -path "$dir_recordings"

# Group the filenames, start time stamps, and end time stamps
$files_and_stamps = select-string -path "${dir_time_stamps}time_stamps_used.csv" -pattern "^(.*),(.*),(.*)$"

# Start with the first match, which should be a filename
$groupsindex = 1

# Playback each silence from one second before to one second after, ask if it
# sounded acceptable, if there was anything noteworthy, then save the results to
# a time_stamps_checked.csv
while ($groupsindex -lt $files_and_stamps.matches.groups.count)
  {
  $temp_start_time = $files_and_stamps.matches.groups[$groupsindex + 1].value - 1
  $temp_end_time = $files_and_stamps.matches.groups[$groupsindex + 2].value + 1
  sox $files_and_stamps.matches.groups[$groupsindex].value -d trim $temp_start_time =$temp_end_time

  # Save match values to variable as values so that they work right with write-output
  $file = $files_and_stamps.matches.groups[$groupsindex].value
  $start_time = $files_and_stamps.matches.groups[$groupsindex + 1].value
  $end_time = $files_and_stamps.matches.groups[$groupsindex + 2].value

  $acceptability = read-host "Was this a good silence (y/n)"
  $comment = read-host "Do you have any comments on this silence"
  write-output "$file,$start_time,$end_time,$acceptability,`"$comment`"" >> time_stamps_checked.csv

  # Move to the next set of matches
  $groupsindex = $groupsindex + 4
  }

write-host "That's all of them!`nThe results are saved in ${dir_recordings}time_stamps_checked.csv."

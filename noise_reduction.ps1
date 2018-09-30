# This script is meant to automatically apply SoX noise reduction to any number of audio recordings,
# specifically those of speech, that are in a single directory. It ignores recordings that contain
# absolute silence but otherwise generates noise profiles from portions of silence in rest that are
# then used to apply noise reduction. To adjust settings for silence detection be adjusted to be more
# or less conservative, search for "silencedetect" and modify the values after n= (amplitude ratio for
# the threshold) and d= (duration of silence to count as silence). To adjust settings for how severe
# the noise reduction should be, search for "noisered" and adjust the value at the end of the line,
# ranging from 0.0 to 1.0 where 1.0 is more reduction and 0.0 is less. -Josh McNeill

# Dependencies: FFmpeg, SoX

# Prompt the user to make sure they're set up correctly
$right_location = read-host "Are you running this script from within the directory where the relevant recordings are located (y/n)?"

if ($right_location -eq "n")
    {
        write-host "Put this script in the same directory as your recordings, then execute it."
    }
    else
        {
            # Prompt the user for the file extension of their recordings
            $ext = read-host "What is the file extension of the recordings you're working with?"

            # Get a list of recordings.
            $allrecordings = get-childitem -name *.$ext

            # Create a subdirectory where cleaned recordings will be moved and tell the user to wait
            new-item -name Cleaned_Recordings -itemtype directory
            write-host "Please wait..."

            foreach ($recording in $allrecordings)
                {
                    # Detect absolute silence
                    ffmpeg -i $recording -af silencedetect=n=0.01:d=1 -f null - > "absolute_silences.txt" 2>&1
        
                    # Was there absolute silence?
                    if ("absolute_silences.txt" -match "start_silence")
                        {
                            # If yes, keep add the file name to a log.
                            $recording >> "recordings_to_do_manually.txt"
                        }
                        else
                        {
                            # If not, detect normal silence
                            ffmpeg -i $recording -af silencedetect=n=0.1:d=1 -f null - > "normal_silences.txt" 2>&1
                
                            # Store the first normal silence start time
                            $silence_start = (select-string -path "normal_silences.txt" -pattern "silence_start: (.*)$").Matches.Groups[1].Value
                
                            # Store the first normal silence end time
                            $silence_end = (select-string -path "normal_silences.txt" -pattern "silence_end: (.*) \| silence_duration: (.*)$").Matches.Groups[1].Value

                            # Trim the normal silence and save it to a new audio file
                            sox $recording normal_silence.$ext trim $silence_start =$silence_end

                            # Create noise profile from the normal silence audio file
                            sox normal_silence.$ext -n noiseprof temp.noise-profile

                            # Apply noise reduction to the recording using the noise profile
                            sox $recording cleaned_$recording noisered temp.noise-profile 0.3

                            # Creates moves all the cleaned recordings to a subdirectory called Cleaned_Recordings
                            move-item -path "cleaned_$recording" -destination ".\Cleaned_Recordings"
                        }
                }
            # Cleans up extraneous files
            Remove-Item *_silences.txt, normal_silence.$ext, temp.noise-profile

            # Print result messages
            get-childitem -name > directory_contents.txt
            if ("directory_contents.txt" -match "recordings_to_do_manually.txt")
                {
                    write-host "Your cleaned recordings are in \Cleaned_Recordings."
                    write-host "Don't forget to manually apply noise reduction to the files in recordings_to_do_manually.txt!"
                }
                else
                    {
                        write-host "All recordings cleaned!"
                        write-host "They can be found in .\Cleaned_Recordings."
                    }
            # Final cleanup
            remove-item directory_contents.txt
        }
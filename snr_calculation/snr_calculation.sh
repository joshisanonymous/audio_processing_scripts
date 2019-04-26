# This is just a simple loop that uses a signal-to-noise calculator utility for
# speech audio to calculate the SNR for many files at once. It then saves the
# results in a .csv file for further analysis.
#
# Dependency: snr_calculator, which can be obtained at
# https://www.isip.piconepress.com/projects/speech/software/legacy/signal_to_noise/
#
# Use: Specify the files that you want to calculate the SNR for as positional
# parameter, e.g. bash snr_batch.sh talking.wav speechfile*.wav
#
# -Joshua McNeill, joshua dot mcneill at uga dot edu

echo "Please wait..."

for file in $@
do
  # Save the current file's SNR to $snr
  snr=`snr_calculator.exe -num_chans 1 -input $file |
       awk '{ printf("%s", $5) }'`

  # Save just the filename from $file to $filename (in cases where a path was used)
  if [[ $file =~ /([^/]*)$ ]]
  then
    filename=${BASH_REMATCH[1]}
  else
    filename=$file
  fi

  # Save the filename and SNR value to a .csv
  echo "$filename,$snr" >> snr_values.csv
done

echo "All done!"
echo "The results can be found in `pwd`/snr_values.csv."

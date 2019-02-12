# This script is meant to be run from noise_reduction.ps1 and simply uses SoX
# to apply noise reduction. The purpose of having this in its own file is to
# allow users to easily comment out the actual noise reduction if they wish to
# perform that step with any software other than SoX.
#
# -Joshua McNeill (josha.mcneill at uga.edu)

# Trim the normal silence and save it to a new audio file
sox $dir$recording ${dir}normal_silence.$ext trim $silence_start =$silence_end

# Create noise profile from the normal silence audio file
sox ${dir}normal_silence.$ext -n noiseprof ${dir}temp.noise-profile

# Apply noise reduction to the recording using the noise profile
sox $dir$recording ${dir}cleaned_$recording noisered ${dir}temp.noise-profile 0.3

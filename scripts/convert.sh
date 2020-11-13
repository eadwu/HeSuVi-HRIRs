#! /usr/bin/env nix-shell
#! nix-shell ../shell.nix -i bash

for file in hrir/*.wav; do
  basename="$(basename "${file}" .wav)"

  printf "Converting %s\n" "$file"
  mkdir -p "7.0-stereo-pairs/${basename}"
  hesuvi_convert "$file" "7.0-stereo-pairs/${basename}/${basename}_L.wav" "7.0-stereo-pairs/${basename}/${basename}_R.wav"
done

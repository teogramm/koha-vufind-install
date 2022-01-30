#!/usr/bin/bash

# Find which Koha dependencies are avaiable in the official repositories.
# To use this script, place it in the same directory as the koha_perl_deps.pl script.


deps=$(perl ./koha_perl_deps.pl -m 2> /dev/null | awk '{print $1}' | head -n -4 | tail -n +5)

for line in $deps; do
  output=$(dnf -C provides "perl(${line})" 2>&1  | sed -n '2p' | awk '{print $1}')
  if [[ $output =~ ^Error ]]; then
    echo ${line} >> "koha-notfound.txt"
  else
    echo ${output} >> "koha-found.txt"
  fi
done

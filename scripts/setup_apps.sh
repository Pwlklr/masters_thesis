#!/bin/bash

cd ~/masters_thesis/apps || exit

echo "Cloning the 4 apps"
git clone https://github.com/adeyosemanputra/pygoat.git
git clone https://github.com/nVisium/django.nV.git
git clone https://github.com/anxolerd/dvpwa.git
git clone https://github.com/erev0s/VAmPI.git

echo "Ready!"

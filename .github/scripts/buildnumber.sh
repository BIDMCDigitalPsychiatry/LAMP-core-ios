#!/bin/bash
set -eo pipefail


git add .
git commit -m "bump version"
git remote set-url --push origin https://jijopulikkottil:$GITHUB_TOKEN@github.com/BIDMCDigitalPsychiatry/LAMP-core-ios
git push origin HEAD
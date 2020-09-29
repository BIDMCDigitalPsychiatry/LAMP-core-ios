#!/bin/bash
set -eo pipefail

xcrun agvtool new-version -all 1
git add .
git commit -m "bump version"
git push origin HEAD
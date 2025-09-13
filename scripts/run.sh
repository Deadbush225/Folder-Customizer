#!/usr/bin/env zsh

git add -A
git commit -m "(fix) update windeployqt and pruning"
git tag -f v0.0.15
git push origin main --tags -f
#!/usr/bin/env zsh

git add -A
git commit -m "(fix) port to eUpdater"
git tag -f v0.0.14
git push origin main --tags -f
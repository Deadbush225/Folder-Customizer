#!/usr/bin/env zsh

git add -A
git commit -m "(feat) add manifest.json to packages + Separate menu for Help"
git tag -f v0.0.11
git push origin main --tags -f
#!/usr/bin/env zsh

git add -A
git commit -m "(feat) add auto refresh helper for windows + context menu to the install"
git tag -f v0.0.9
git push origin main --tags -f
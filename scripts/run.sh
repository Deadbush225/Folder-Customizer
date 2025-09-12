#!/usr/bin/env zsh

git add -A
git commit -m "(fix) replace png with ico in installer"
git tag -f v0.0.15
git push origin main --tags -f
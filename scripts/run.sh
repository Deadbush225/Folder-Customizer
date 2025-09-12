#!/usr/bin/env zsh

git add -A
git commit -m "(fix) Fix installer source paths + installer icons"
git tag -f v0.0.15
git push origin main --tags -f
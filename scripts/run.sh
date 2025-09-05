#!/usr/bin/env zsh

git add -A
git commit -m "(feat) consistent naming + clean dist to clean old assets"
git tag -f v0.0.10
git push origin main --tags -f
#!/usr/bin/env zsh

git add -A
git commit -m "attempt to fix boost not found error"
git tag -f v0.0.9
git push origin main --tags -f
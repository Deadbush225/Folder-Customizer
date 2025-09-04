#!/usr/bin/env zsh

git add -A
git commit -m "attempt for cross platform"
git tag -f v0.0.9
git push origin main --tags -f
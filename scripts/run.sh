#!/usr/bin/env zsh

git add -A
git commit -m "(build) generalized package deployment"
git tag -f v0.0.15
git push origin main --tags -f
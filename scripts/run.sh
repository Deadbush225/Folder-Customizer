#!/usr/bin/env zsh

git add -A
git commit -m "(fix) \"Check Updates\" not working"
git tag -f v0.0.12
git push origin main --tags -f
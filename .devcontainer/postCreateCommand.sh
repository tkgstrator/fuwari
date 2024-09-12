#!/bin/zsh

sudo chown -R bun:bun public
sudo chown -R bun:bun node_modules 

bun install --frozen-lockfile --ignore-scripts
#!/bin/bash

commmitCount=$(git rev-list --count master)
export GIT_COMMIT_NUMBER=$commmitCount
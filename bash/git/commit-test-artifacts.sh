#!/bin/bash
# When you need to commit some automagically generated/updated files, like snaps, screenshots etc.

MSG="Update tests artifacts"
echo "${MSG}"
git commit -m "${MSG}"

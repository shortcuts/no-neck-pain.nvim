#!/bin/bash

if [[ -z "$NEXT_TAG" ]]; then
  echo "usage: NEXT_TAG=0.2.2 make release"
  exit 1
fi

echo "Generating changelog for version $NEXT_TAG"

git-chglog -o CHANGELOG.md -no-case --next-tag=$NEXT_TAG

echo "Pushing release commit and tag $NEXT_TAG"

git add .
git commit -m "chore: release v$NEXT_TAG"
git tag $NEXT_TAG
git push origin main $NEXT_TAG

echo "Creating release v$NEXT_TAG"

NOTES=$(git-chglog -no-case $NEXT_TAG)
gh release create $NEXT_TAG -t v$NEXT_TAG --notes "$NOTES"

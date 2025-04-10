#!/bin/bash

VERSION=$INPUT_VERSION
PR_BODY=$INPUT_PR_BODY
GITHUB_TOKEN=$INPUT_GITHUB_TOKEN
GITHUB_REPOSITORY=$INPUT_GITHUB_REPOSITORY
GITHUB_API_URL="https://api.github.com"
GITHUB_RELEASE_URL="$GITHUB_API_URL/repos/$GITHUB_REPOSITORY/releases"

echo "Configure git user"
git config --global user.name "Datom Actions"
git config --global user.email "actions@datom.com"

echo "Creating tag for version $VERSION"
git tag -a "$VERSION" -m "Release $VERSION"
echo "Pushing tag $VERSION to origin"
git push origin "$VERSION"


description=$(echo "$PR_BODY" | jq -Rs .)
echo "Creating release for version $VERSION"
response_file=$(mktemp)
response=$(curl -s -o "$response_file" -w "%{http_code}" -X POST \
     -H "Authorization: token $GITHUB_TOKEN" \
     -H "Accept: application/vnd.github.v3+json" \
     -d '{
           "tag_name": "'"$VERSION"'",
           "target_commitish": "main",
           "name": "'"$VERSION"'",
           "body": '"$description"',
           "draft": false,
           "prerelease": false
         }' \
     "$GITHUB_RELEASE_URL")

if [ "$response" -eq 201 ]; then
    echo "✅ INFO : Release created correctly"
else
    echo "❌ Something went wrong, received status -> $response"
    echo "Response body:"
    cat "$response_file"
    rm "$response_file"
    exit 1
fi

rm "$response_file"
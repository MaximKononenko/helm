#!/bin/bash
BUILD_URL=$SYSTEM_TEAMFOUNDATIONCOLLECTIONURI/$SYSTEM_TEAMPROJECT/_build/results?buildId=$BUILD_BUILDID
BUILD_TIME=$(date '+%Y-%m-%dT%H:%M:%SZ')
jq --arg buildtime "$BUILD_TIME" \
   --arg buildurl "$BUILD_URL" \
   --arg machinename "$AGENT_MACHINENAME" \
   --arg pipestarttime "$SYSTEM_PIPELINESTARTTIME" \
   --arg commitmsg "$BUILD_SOURCEVERSIONMESSAGE"  \
   --arg commitid "$BUILD_SOURCEVERSION" \
   --arg commitauthor "$BUILD_SOURCEVERSIONAUTHOR" \
   --arg branch "$BUILD_SOURCEBRANCHNAME" \
   --arg appname "$APPLICATIONNAME" '.build.time |= $buildtime | .release.build |= $buildurl | .git.build.host |= $machinename | .git.build.time |= $pipestarttime | .git.commit.message.full |= $commitmsg | .git.commit.id |= $commitid | .git.commit.user.name |= $commitauthor | .git.branch |= $branch | .build.name |= $appname' \
   < $(Build.SourcesDirectory)/devops/assets/eui-info-template.json > $(Build.SourcesDirectory)/dist/build-info.json
echo "============ BUILD-INFO.JSON =============="
cat $(Build.SourcesDirectory)/dist/build-info.json
echo "==========================================="

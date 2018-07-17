#!/bin/bash
set -x
rootDir=$quickstartRootDir
logDir="$rootDir/log"

source "$rootDir/bash/scripts/predix_funcs.sh"
source "$rootDir/bash/scripts/variables.sh"
source "$rootDir/bash/scripts/error_handling_funcs.sh"
source "$rootDir/bash/scripts/files_helper_funcs.sh"
source "$rootDir/bash/scripts/curl_helper_funcs.sh"
source "$rootDir/bash/scripts/local-setup-funcs.sh"

MACHINE_HOME="$1"
CURRENT_DIR=$(pwd)
echo "CURRENT_DIR : $CURRENT_DIR"
echo "MAVEN_SETTINGS_FILE : $MAVEN_SETTINGS_FILE"

echo "Deploying predix-machine-template-processor"
rm -rf predix-machine-template-processor
getRepoURL "predix-machine-template-processor" git_url ../version.json
echo "git url : $git_url"
getRepoVersion "predix-machine-template-processor" branch ../version.json
echo "git repo version : $branch"

__echo_run git clone $git_url -b $branch
cd predix-machine-template-processor
echo "CURRENT_DIR $(pwd)"
if [[ $RUN_COMPILE_REPO -eq 1 ]]; then
  __echo_run mvn -q clean install -U -Dmaven.compiler.source=1.8 -Dmaven.compiler.target=1.8 -f pom.xml -s $MAVEN_SETTINGS_FILE
else
  __echo_run mvn clean dependency:copy -B -Dmdep.useBaseVersion=true -s $MAVEN_SETTINGS_FILE
fi

echo "Fetching project name"
PROJECT_ARTIFACT_ID=$(printf 'VER\t${project.artifactId}' | mvn help:evaluate | grep '^VER' | cut -f2)
echo "PROJECT_ARTIFACT_ID : $PROJECT_ARTIFACT_ID"
echo "Fetching project version"
PROJECT_VERSION=$(printf 'VER\t${project.version}' | mvn help:evaluate | grep '^VER' | cut -f2)
echo "PROJECT_VERSION : $PROJECT_VERSION"

MACHINE_BUNDLE="$PROJECT_ARTIFACT_ID-$PROJECT_VERSION.jar"
echo "MACHINE_BUNDLE_JAR : $MACHINE_BUNDLE"

if [[ ! -e $MACHINE_HOME/machine/bin/vms/solution.ini ]]; then
  cp config/solution.ini $MACHINE_HOME/machine/bin/vms/
fi
__find_and_replace_string "{MACHINE_PROCESSOR_VERSION}" "$PROJECT_VERSION" "$MACHINE_HOME/machine/bin/vms/solution.ini" "$buildBasicAppLogDir" "$MACHINE_HOME/machine/bin/vms/solution.ini"

#sed 's#{MACHINE_BUNDLE_JAR}#${MACHINE_BUNDLE}#' config/solution.ini > "$MACHINE_HOME/machine/bin/vms/solution.ini"
#sed -i -e "s#<name>{MACHINE_BUNDLE_JAR}</name>#<name>$MACHINE_BUNDLE</name>#" config/solution.ini
#__echo_run cp config/solution.ini $MACHINE_HOME/machine/bin/vms/solution.ini
__echo_run cp target/$MACHINE_BUNDLE "$MACHINE_HOME/machine/bundles"
cd ..
rm -rf predix-machine-template-processor

echo "#################### Build and setup the adatper end ####################"

cd "$CURRENT_DIR"
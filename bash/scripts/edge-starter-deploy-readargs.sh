#!/bin/bash
set -e
arguments="$*"
#echo "arguments : $arguments"

# Reset all variables that might be set
RUN_EDGE_APP_LOCAL=0
RUN_DEPLOY_TO_EDGE=0

source "$rootDir/bash/scripts/build-basic-app-readargs.sh"


function processReadargs() {
	#process all the switches as normal
	while :; do
			doShift=0
			processEdgeStarterReadargsSwitch $@
			if [[ $doShift == 2 ]]; then
				shift
				shift
			fi
			if [[ $doShift == 1 ]]; then
				shift
			fi
			if [[ $@ == "" ]]; then
				break;
			else
	  			shift
			fi
			#echo "processReadargs $@"
	done
	#echo "Switches=${SWITCH_DESC_ARRAY[*]}"
	printEdgeStarterVariables
}

function processEdgeStarterReadargsSwitch() {
	#process all the switches as normal - not all switches are functions, so we take a pass through and set some variables
	#echo "here$@"
	case $1 in
		-run-edge-app|--run-edge-app)
			RUN_EDGE_APP_LOCAL=1
			SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-run-edge-app|--run-edge-app"
			SWITCH_ARRAY[SWITCH_INDEX++]="-run-edge-app"
			PRINT_USAGE=0
			;;
		-deploy-edge-app|--deploy-edge-app)
			RUN_DEPLOY_TO_EDGE=1
			SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-deploy-edge-app|--deploy-edge-app"
			SWITCH_ARRAY[SWITCH_INDEX++]="-deploy-edge-app"
			PRINT_USAGE=0
			;;
		-create-packages|--create-packages)
			RUN_CREATE_PACKAGES=1
			SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-create-packages|--create-packages"
			SWITCH_ARRAY[SWITCH_INDEX++]="-create-packages"
			PRINT_USAGE=0
			;;
		-repo-name|--repo-name)
			REPO_NAME="$2"
			SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-repo-name|--repo-name"
			SWITCH_ARRAY[SWITCH_INDEX++]="-repo-name"
			PRINT_USAGE=0
			;;
		-app-name|--app-name)
			APP_NAME="$2"
			SWITCH_DESC_ARRAY[SWITCH_DESC_INDEX++]="-app-name|--app-name"
			SWITCH_ARRAY[SWITCH_INDEX++]="-app-name"
			PRINT_USAGE=0
			;;
		-check-docker-login)
			CHECK_DOCKER_LOGIN=1
			DTR_NAME="$2"
			PRINT_USAGE=0
			;;
		-?*)
			doShift=0
			SUPPRESS_PRINT_UNKNOWN=1
			UNKNOWN_SWITCH=0
			processBuildBasicAppReadargsSwitch $@
			if [[ $UNKNOWN_SWITCH == 1 ]]; then
				echo "unknown Edge Manager switch=$1"
			fi
      ;;
		*)               # Default case: If no more options then break out of the loop.
			;;
  esac
	if [[ -z $DTR_NAME ]]; then
		DTR_NAME="dtr.predix.io"
	fi
}


function printEdgeStarterVariables() {
	if [[ "$RUN_PRINT_VARIABLES" == "1" ]]; then
		printBBAVariables
	fi
	echo "EDGE STARTER APP:"
	echo "  RUN_EDGE_APP_LOCAL  : $RUN_EDGE_APP_LOCAL"
	echo "  RUN_DEPLOY_TO_EDGE  : $RUN_DEPLOY_TO_EDGE"
	echo "      "
	export RUN_EDGE_APP_LOCAL
	export RUN_DEPLOY_TO_EDGE
	export REPO_NAME
	export CHECK_DOCKER_LOGIN
	export DTR_NAME
}

function __print_out_usage
{
	echo -e "\nUsage:\n"
	echo -e "./$SCRIPT_NAME [ options ]\n"

  echo -e "Device options are as below"
  echo "configurations:"
	echo "[-cd |      	 --create-device]          					=> Create Device"
	echo -e "./$SCRIPT_NAME                                 => Run all switches"
}

#	----------------------------------------------------------------
#	Function for processing switches in the order they were passed in
#		Accepts 2 arguments:
#			binding app
#			switch to process
#  Returns:
#	----------------------------------------------------------------
function runFunctionsForEdgeStarter() {
	while :; do
			SUPPRESS_PRINT_UNKNOWN=1
			runFunctionsForBasicApp $1 $2
			case $2 in
					-h|--help)
						__print_out_usage
						break
						;;
					--run-edge-app|--run-edge-app)
						 echo "calling --run-edge-app|--run-edge-app"
            runEdgeStarterLocal $1
            break
            ;;
					-create-packages|--create-packages)
						createPackages $1
						;;
					-deploy-edge-app|--deploy-edge-app)
					 	echo "calling -deploy-edge-app|--deploy-edge-app"
            deployToEdge $1
            break
          	;;
					-check-docker-login)
						checkDockerLogin $DTR_NAME
						;;
		      *)
            echo 'WARN: Unknown ES function (ignored) in runFunction: %s\n' "$1 $2" >&2
            break
						;;
	    esac
	done
}

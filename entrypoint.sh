#!/bin/sh
set -e
set -x

# echo '[INFO] Preparing...'
# echo '[INFO] Print environment variables:'
# echo "SHELL=[$SHELL]"
# echo "HOME=[$HOME]"
# echo "GITHUB_WORKSPACE=[$GITHUB_WORKSPACE]"
# echo "GITHUB_RUN_ID=[$GITHUB_RUN_ID]"
# echo "GITHUB_REPOSITORY=[$GITHUB_REPOSITORY]"
# echo "GITHUB_SHA=[$GITHUB_SHA]"
# echo "USER_NAME=[$USER_NAME]"
# echo "USER_EMAIL=[$USER_EMAIL]"
# echo "GITHUB_TOKEN=[$GITHUB_TOKEN]"

# OUTPUT_DIR="${BOOK_DIR}/_book"
# export OUTPUT_DIR
# echo "OUTPUT_DIR=[$OUTPUT_DIR]"

# NAME_REPO=$(echo "$GITHUB_REPOSITORY" | cut -d "/" -f 2)

DEFAULT_BRANCH="gh-pages"
BUILD() {

    DIR="$PWD/docx"
    FILE="$PWD/docx/README.md"

    if [ -d "$DIR" ]; 
    then
        {
            echo "folder exits, create other folder"
            NAME="$(date +%s | md5 | base64 | head -c 12 ; echo)"
            DIR="$PWD/$NAME"
        }
    else
        {
            echo "folder didn't exist, create new folder"
            mkdir $DIR
            ls -la
        }
    fi
    git clone "https://${USER_NAME}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" $DIR

    if [ -f "$FILE" ]; 
    then
        {
            echo "File docx exist"
            cat $FILE
        }
    else
        {
            echo "File docx didn't exist, create new file"
            echo "## Docx empty pls update them" > $FILE
        }
    fi

    cd $DIR

    npx honkit build
}

GENERATE_VARIABLES_FOR_DEPLOY() {
    echo '[INFO] Start to deploy...'
    echo '[INFO] Preparing...'
    echo '[INFO] Print environment variables:'

    echo "GITHUB_REPOSITORY=$GITHUB_REPOSITORY"
    echo "GITHUB_WORKSPACE=$GITHUB_WORKSPACE"

    echo GITHUB_REPOSITORY=$GITHUB_REPOSITORY

    NAME_FOLDER=$( echo "$GITHUB_REPOSITORY" | cut -d "/" -f 2 )

    echo "$NAME_FOLDER"
    FOLDER_CODE=${NAME_FOLDER}_result
    export FOLDER_CODE
    echo $FOLDER_CODE

    if [ -d "$DIR/_book" ]; 
    then
        {
            echo "folder exits"
            DIR="$DIR/_book"
            ls -la $DIR
        }
    else
        {
            exit 1
        }
    fi
}

COPY_OUTPUT() {
    
    cd $GITHUB_WORKSPACE
    mkdir $FOLDER_CODE
    git clone "https://${USER_NAME}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" $FOLDER_CODE
    cd $FOLDER_CODE
    
    existed_in_remote=$(git ls-remote --heads origin $DEFAULT_BRANCH)
    if [ -z ${existed_in_remote} ]; 
    then
        {
            git checkout -b $DEFAULT_BRANCH
        }
    else
        {
            git checkout $DEFAULT_BRANCH
        }
    fi

    echo '[INFO] Copy GitBook output pages...'
    mkdir $GITHUB_WORKSPACE/dot_git_temp
    cp -rf .git/* $GITHUB_WORKSPACE/dot_git_temp


    rm -rf $GITHUB_WORKSPACE/$FOLDER_CODE
    mkdir $GITHUB_WORKSPACE/$FOLDER_CODE
    mkdir $GITHUB_WORKSPACE/$FOLDER_CODE/.git

    cp -rf $GITHUB_WORKSPACE/dot_git_temp/* $GITHUB_WORKSPACE/$FOLDER_CODE/.git
    cp -rf $DIR/* $GITHUB_WORKSPACE/$FOLDER_CODE/


    cd $GITHUB_WORKSPACE/$FOLDER_CODE
}

PUSH_REPO() {
    echo '[INFO] Add new commit for branch...'

    git config --local user.name "$USER_NAME"
    git config --local user.email "$USER_EMAIL"
    git status
    git add --all
    git commit -m "Deploy to Github Pages (from $GITHUB_SHA)"

    git log
    echo '[INFO] Push to result...'
    git status
    git branch -a
    git push origin $DEFAULT_BRANCH
    echo '[INFO] Deploy completed...!'
}

MAIN(){
    #Build gitbook by honkit
    BUILD

    # Preparing variable
    GENERATE_VARIABLES_FOR_DEPLOY

    # Copy honkit on repo
    COPY_OUTPUT

    # Push result on repo
    PUSH_REPO
}

MAIN

##########################Main Process############################
if [ "${1#-}" != "${1}" ] || [ -z "$(command -v "${1}")" ]; then
  set -- node "$@"
fi

exec "$@"

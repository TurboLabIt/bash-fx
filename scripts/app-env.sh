#!/usr/bin/env bash

if [ ! -z "${PROJECT_DIR}" ] && [ -f "${PROJECT_DIR}env" ]; then

  APP_ENV=$(head -n 1 ${PROJECT_DIR}env)

elif [ ! -z "${PROJECT_DIR}" ] && [ -d "${PROJECT_DIR}.git" ]; then

  git config --global --add safe.directory "${PROJECT_DIR}"
  GIT_BRANCH=$(git -C $PROJECT_DIR branch | grep \* | cut -d ' ' -f2-)
fi


if [ "$GIT_BRANCH" = "master" ]; then

  APP_ENV=prod

elif [ "$GIT_BRANCH" = "staging" ]; then

  APP_ENV=staging

elif [ "$GIT_BRANCH" = "dev" ] || [[ "$GIT_BRANCH" = "dev-"* ]]; then

  APP_ENV=dev
fi


devOnlyCheck ()
{
  if [ "$APP_ENV" != "dev" ]; then
    fxCatastrophicError "🧑‍💻 This script can run in the **DEV** environment only! Current env: ##$APP_ENV##"
  fi
}

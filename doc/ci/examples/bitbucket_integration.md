# Using GitLab CI/CD with a Bitbucket Cloud repository

GitLab CI/CD can be used with any Git repository using Pull Mirroring.

1. In GitLab create a **CI/CD project** using the Git URL option and the HTTPS
   URL for your Bitbucket repository.

    GitLab will automatically configure polling-based pull mirroring.

1. In GitLab create a **Personal Access Token** with `API` scope to
   authenticate the Bitbucket web hook notifying GitLab of new commits.

1. In Bitbucket from **Settings > Webhooks** create a new web hook to notify
   GitLab of new commits.

    The web hook URL should be set to the GitLab API to trigger pull mirroring,
    using the Personal Access Token we just generated for authentication.

    ```
    https://gitlab.com/api/v4/projects/<NAMESPACE>%2F<PROJECT>/mirror/pull?private_token=<PERSONAL_ACCESS_TOKEN>
    ```

    The web hook Trigger should be set to 'Repository Push'.

    ![Bitbucket Cloud webhook](img/bitbucket_webhook.png)

    After saving, test the web hook by pushing a change to your Bitbucket
    repository.

1. In Bitbucket create an **App Password** from **Bitbucket Settings > App
   Passwords** to authenticate the build status script setting commit build
   statuses in Bitbucket. Repository write permissions are required.

    ![Bitbucket Cloud webhook](img/bitbucket_app_password.png)

1. Add a script to push the pipeline status to Bitbucket and update the
   `.gitlab-ci.yml` to use the script.


    ```
    # Notify per job

    test:
      stage: test

      before_script:
         - BUILD_STATUS=running ./build_status

      after_script:
         - BUILD_STATUS=passed ./build_status

      script:
         - echo "Success"

    # Notify per pipeline

    # TODO
    ```

    Create the `build_status` script and making it executable
    (`chmod +x build_status`):

    ```bash
    #!/usr/bin/env bash

    # Push GitLab CI/CD build status to Bitbucket Cloud

    #
    # INSTRUCTIONS
    #
    # 1. Generate an "App Password" with repository write permissions
    # 2. Set the GitLab CI/CD secret variables
    #    - BITBUCKET_ACCESS_TOKEN: your app password
    #    - BITBUCKET_USERNAME: your username for authentication
    #    - BITBUCKET_NAMESPACE
    #    - BITBUCKET_REPOSITORY

    if [ -z "$BITBUCKET_ACCESS_TOKEN" ]; then
    echo "ERROR: BITBUCKET_ACCESS_TOKEN is not set"
    exit 1
    fi
    if [ -z "$BITBUCKET_USERNAME" ]; then
    echo "ERROR: BITBUCKET_USERNAME is not set"
    exit 1
    fi
    if [ -z "$BITBUCKET_NAMESPACE" ]; then
    echo "Setting BITBUCKET_NAMESPACE to $CI_PROJECT_NAMESPACE"
    BITBUCKET_NAMESPACE=$CI_PROJECT_NAMESPACE
    fi
    if [ -z "$BITBUCKET_REPOSITORY" ]; then
    echo "Setting BITBUCKET_REPOSITORY to $CI_PROJECT_NAME"
    BITBUCKET_REPOSITORY=$CI_PROJECT_NAME
    fi

    BITBUCKET_API_ROOT="https://api.bitbucket.org/2.0"
    BITBUCKET_STATUS_API="$BITBUCKET_API_ROOT/repositories/$BITBUCKET_NAMESPACE/$BITBUCKET_REPOSITORY/commit/$CI_COMMIT_SHA/statuses/build"
    BITBUCKET_KEY="ci/gitlab-ci/$CI_JOB_NAME"

    case "$BUILD_STATUS" in
    running)
       BITBUCKET_STATE="INPROGRESS"
       BITBUCKET_DESCRIPTION="The build is running!"
       ;;
    passed)
       BITBUCKET_STATE="SUCCESSFUL"
       BITBUCKET_DESCRIPTION="The build passed!"
       ;;
    failed)
       BITBUCKET_STATE="FAILED"
       BITBUCKET_DESCRIPTION="The build failed."
       ;;
    esac

    echo "Pushing status to $BITBUCKET_STATUS_API..."
    curl --request POST $BITBUCKET_STATUS_API \
    --user $BITBUCKET_USERNAME:$BITBUCKET_ACCESS_TOKEN \
    --header "Content-Type:application/json" \
    --silent \
    --data "{ \"state\": \"$BITBUCKET_STATE\", \"key\": \"$BITBUCKET_KEY\", \"description\":
    \"$BITBUCKET_DESCRIPTION\",\"url\": \"$CI_PROJECT_URL/-/jobs/$CI_JOB_ID\" }"
    ```

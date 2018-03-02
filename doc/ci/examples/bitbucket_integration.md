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

1. Update your `.gitlab-ci.yml` to push commit statuses to Bitbucket.

    ```
    example gitlab.yml
    ```

    ```bash
    example script
    ```

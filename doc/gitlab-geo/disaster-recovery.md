# GitLab Geo Disaster Recovery

> **Note:**
This is not officially supported yet, please don't use as your only
Disaster Recovery strategy as you may lose data.

GitLab Geo replicates your database and your Git repositories. We will
support and replicate more data in the future, that will enable you to
fail-over with minimal effort, in a disaster situation.

See [current limitations](README.md#current-limitations)
for more information.


## Promoting a secondary node

We don't provide yet an automated way to promote a node and do fail-over,
but you can do it manually if you have `root` access to the machine.

You must make the changes in the exact specific order:

1. Take down your primary node (or make sure it will not go up during this
   process or you may lose data)
2. Wait for any database replication to finish
3. Promote the Postgres in your secondary node as primary

    * Remove the configuration lines that you added to your gitlab configuration
      file [here](https://docs.gitlab.com/ee/gitlab-geo/database.html#step-2-configure-the-secondary-server)

    * Create a trigger file to stop replication and promote to primary

        ```
        # For Omnibus installations
	touch /tmp/postgresql.trigger
	```

    * Reconfigure for the changes to take effect.

4. Log-in to your secondary node with a user with `sudo` permission
5. Open the interactive rails console: `sudo gitlab-rails console` and execute:
    * List your primary node and note down it's id:

        ```ruby
        Gitlab::Geo.primary_node
        ```
    * Turn your primary into a secondary:

        ```ruby
        Gitlab::Geo.primary_node.update(primary: false)
        ```
    * List your secondary nodes and note down the id of the one you want to promote:

        ```ruby
        Gitlab::Geo.secondary_nodes
        ```
    * To promote a node with id `2` execute:

        ```ruby
        GeoNode.find(2).update!(primary: true)
        ```
    * Now you have to cleanup your new promoted node by running:

        ```ruby
        Gitlab::Geo.primary_node.oauth_application.destroy!
        Gitlab::Geo.primary_node.system_hook.destroy!
        ```
    * And refresh your old primary node to behave correctly as secondary (assuming id is `1`)

        ```ruby
        GeoNode.find(1).save!
        ```
    * To exit the interactive console, type: `exit`

    * Your secondary node is now a primary, you can log in and start using it.

    * If you have other secondary nodes, read through the [setup instructions](https://docs.gitlab.com/ee/gitlab-geo/README.html#setup-instructions)
      and make the relevant changes for them to connect to the new primary.

    * It is now safe to bring your original primary back online if you need to
      get files from it, remember to not leave it on it it's current state
      and accessible at it's old URL because your users might start using it.

6. If you want the [files that Geo does not sync](https://docs.gitlab.com/ee/gitlab-geo/README.html#what-data-is-replicated-to-a-secondary-node)
   Rsync everything in `/var/opt/gitlab/gitlab-rails/uploads` and
   `/var/opt/gitlab/gitlab-rails/shared` from your old node to the new one.
   You can do this by restoring from a backup you made of your primary or get it
   directly from the primary if the filesystem becomes accessible again.

# Project mirror API

A project's mirror is its pull mirror.

A project mirror is not the same as remote mirrors, which are push mirrors.
There is seperate documentation for the [remote mirrors API](project_remote_mirrors.md).

There is
[an issue](https://gitlab.com/gitlab-org/gitlab-ce/issues/51763)
to improve the naming of push and pull mirrors.

## Start the pull mirroring process **[STARTER]**

> Introduced in [GitLab Starter](https://about.gitlab.com/pricing) 10.3.

```
POST /projects/:id/mirror/pull
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/:id/mirror/pull
```

## Delete a mirror

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/issues/54574) in GitLab 11.8

Deletes the existing project mirror.

```
DELETE /projects/:id/mirror
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |


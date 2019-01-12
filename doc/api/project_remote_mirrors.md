# Project remote mirrors API

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/issues/54574) in GitLab 11.8

A project's remote mirrors are its push mirrors.

Remote mirrors are not not the same as a project mirror, which is a pull mirror.
There is seperate documentation for the [project mirror API](project_mirror.md).

There is
[an issue](https://gitlab.com/gitlab-org/gitlab-ce/issues/51763)
to improve the naming of push and pull mirrors.

## Delete remote mirror

Deletes an existing project remote mirror. This returns a `204 No Content` status code if the operation was successful or `404` if the resource was not found.

```
DELETE /projects/:id/remote_mirrors/:remote_mirror_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `remote_mirror_id` | integer | yes | The id of the project's remote mirror |


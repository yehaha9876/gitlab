# License

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/issues/7054) in GitLab 11.9.

In order to interact with license queries and mutations, you need to authenticate yourself
as an admin.

## Queries

### Retrieve a license

```
query license($id: ID!) {
  metadata {
    license(id: $id) {
      userPermissions { readLicense }
      id
      plan
      expired
      createdAt
      startsAt
      expiresAt
      currentActiveUsersCount
      restrictedUserCount
      historicalMax
      overage
      licensee {
        name
        email
        company
      }
    }
  }
}

```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The license id |

Example arguments:

```json
{
  "id": 2
}
```

Example response:

```json
{
  "data": {
    "metadata": {
      "license": {
        "userPermissions": {
          "readLicense": true
        },
        "id": "11",
        "plan": "ultimate",
        "expired": true,
        "createdAt": "2019-02-07 01:47:52 UTC",
        "startsAt": "2019-01-12",
        "expiresAt": "2019-02-12",
        "currentActiveUsersCount": 28,
        "restrictedUserCount": 100,
        "historicalMax": 28,
        "overage": 0,
        "licensee": {
          "name": "Luke Bennett",
          "email": "lbennett@gitlab.com",
          "company": "GitLab"
        }
      }
    }
  }
}
```

It returns `null` if the license does not exist.

### Retrieve a collection of licenses

```
query licenses($after: String!, $first: Int, $sort: Sort) {
  metadata {
    licenses(after: $after, first: $first, sort: $sort) {
      edges {
        node {
          id
          plan
          ...
      	}
        cursor
      }
      pageInfo {
        startCursor
      	endCursor
      	hasNextPage
        hasPreviousPage
      }
    }
  }
}
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `after` | string | yes | The previous cursor, can be an empty string |
| `before` | string | no | Return the licenses before this cursor |
| `first` | integer | no | Returns the first _n_ licenses |
| `last` | integer | no | Returns the last _n_ licenses |
| `sort` | Sort | no | A `Sort` type i.e. `sort: id_asc` |

Example arguments:

```json
{
  "after": "",
  "first": 2,
  "sort": "id_desc"
}
```

Example response:

```json
{
  "data": {
    "metadata": {
      "licenses": {
        "edges": [
          {
            "node": {
              "id": "3",
              "plan": "ultimate"
              ...
            },
            "cursor": "Mw=="
          },
          {
            "node": {
              "id": "7",
              "plan": "ultimate"
              ...
            },
            "cursor": "Nw=="
          }
        ],
        "pageInfo": {
          "startCursor": "Mw==",
          "endCursor": "Nw==",
          "hasNextPage": true,
          "hasPreviousPage": false
        }
      }
    }
  }
}
```

It returns an empty array if there are no licenses.

## Mutations

### Delete a license

```
mutation licenseDelete($input: LicenseDeleteInput!) {
  licenseDelete(input: $input) {
    license {
      id
      plan
      ...
    }
  }
}
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `input` | LicenseDeleteInput | yes | An object with an `id` property of the license to delete |

Example arguments:

```json
{ "input": { "id": 8 } }
```

Example response:

```json
{
  "data": {
    "licenseDelete": {
      "license": {
        "id": "8",
        "plan": "ultimate"
        ...
      }
    }
  }
}
```

It returns `null` if the license does not exist.

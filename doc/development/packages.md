# Packages

This document should help you add another package management system support to GitLab.

See already supported package types in [Packages documentation](../administration/packages.md)

Since GitLab packages UI is pretty generic there should be possible to add new 
package system support by solely backend changes. This guide is superficial and does 
not cover the way the code should be written. However you can find a good example 
by looking at existing merge requests with Maven and NPM support: 

* [NPM registry support](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/8673). 
* [Maven repository](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/6607).
* [Instance level endpoint for Maven repository](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/8757)

## General information

Points below describe existing database model. 

1. Every package belongs to a project. 
1. Every package file belongs to a package.
1. Package can have 1+ package files.
1. Package model stores information about package and version.

## API endpoints

Package systems work with GitLab via API. For example `ee/lib/api/npm_packages.rb` 
implements API endpoints to work with NPM client. So the first thing to do is to 
add a new `ee/lib/api/your_name_packages.rb` file with API endpoints that are 
necessary to make package system client to work. Usually that means having 
endpoints like: 

* GET package information.
* GET package file content.
* PUT upload package.

Since packages belong to a project, it's expected to have project-level endpoint
for uploading and downloading package. For example: 

```
GET https://gitlab.com/api/v4/projects/<your_project_id>/packages/npm/
PUT https://gitlab.com/api/v4/projects/<your_project_id>/packages/npm/
```

Group-level and instance-level endpoints are good to have but are optional. 

**NOTE**: To avoid name conflict for instance-level endpoints we use 
[the package naming convention](../user/project/packages/npm_registry.html#package-naming-convention)

## Configuration

GitLab has packages section in the config. It applies to all package systems supported
by GitLab. Usually you don't need to add anything there. 

Packages can be configured to use object storage. That means your code should 
support object storage. 

## Database

Current database model allows you to store name and version for each package. 
Every time you upload a new package, you can either create a new record of `Package`
or add files to existing record. `PackageFile` should be able to store all file related
information like file name, side, sha1 etc. 

If there is some specific data need to be stored for only one package system support, 
consider creating a separate metadata model. See `packages_maven_metadata` table 
and `Packages::MavenMetadatum` model 


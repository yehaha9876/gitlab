---
comments: false
---

# GitLab development guides

## Get started!

- Setup GitLab's development environment with [GitLab Development Kit (GDK)](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/master/doc/howto/README.md)
- [GitLab contributing guide](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CONTRIBUTING.md)
- [Architecture](architecture.md) of GitLab
- [Rake tasks](rake_tasks.md) for development

## Processes

- [GitLab core team & GitLab Inc. contribution process](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/PROCESS.md)
- [Generate a changelog entry with `bin/changelog`](changelog.md)
- [Code review guidelines](code_review.md) for reviewing code and having code reviewed.
- [Limit conflicts with EE when developing on CE](limit_ee_conflicts.md)
- [Guidelines for implementing Enterprise Edition feature](ee_features.md)

## UX and frontend guides

- [UX guide](ux_guide/index.md) for building GitLab with existing CSS styles and elements
- [Frontend guidelines](fe_guide/index.md)

## Backend guides

- [API styleguide](api_styleguide.md) Use this styleguide if you are
  contributing to the API.
- [Sidekiq guidelines](sidekiq_style_guide.md) for working with Sidekiq workers
- [Working with Gitaly](gitaly.md)
- [Manage feature flags](feature_flags.md)
- [View sent emails or preview mailers](emails.md)
- [Shell commands](shell_commands.md) in the GitLab codebase
- [`Gemfile` guidelines](gemfile.md)
- [Sidekiq debugging](sidekiq_debugging.md)
- [Gotchas](gotchas.md) to avoid
- [Issue and merge requests state models](object_state_models.md)
- [How to dump production data to staging](db_dump.md)
- [Working with the GitHub importer](github_importer.md)

## Performance guides

- [Instrumentation](instrumentation.md)
- [Performance guidelines](performance.md)
- [Merge request performance guidelines](merge_request_performance_guidelines.md)
  for ensuring merge requests do not negatively impact GitLab performance

## Databases guides

### Migrations

- [What requires downtime?](what_requires_downtime.md)
- [SQL guidelines](sql.md) for working with SQL queries
- [Migrations style guide](migration_style_guide.md) for creating safe SQL migrations
- [Post deployment migrations](post_deployment_migrations.md)
- [Background migrations](background_migrations.md)
- [Swapping tables](swapping_tables.md)

### Best practices

- [Merge Request checklist](database_merge_request_checklist.md)
- [Adding database indexes](adding_database_indexes.md)
- [Foreign keys & associations](foreign_keys.md)
- [Single table inheritance](single_table_inheritance.md)
- [Polymorphic associations](polymorphic_associations.md)
- [Serializing data](serializing_data.md)
- [Hash indexes](hash_indexes.md)
- [Storing SHA1 hashes as binary](sha1_as_binary.md)
- [Iterating tables in batches](iterating_tables_in_batches.md)
- [Ordering table columns](ordering_table_columns.md)
- [Verifying database capabilities](verifying_database_capabilities.md)

## Testing guides

- [Testing standards and style guidelines](testing_guide/index.md)
- [Frontend testing standards and style guidelines](testing_guide/frontend_testing.md)

## Documentation guides

- [Documentation styleguide](doc_styleguide.md): Use this styleguide if you are
  contributing to the documentation.
- [Writing documentation](writing_documentation.md)
  - [Distinction between general documentation and technical articles](writing_documentation.md#distinction-between-general-documentation-and-technical-articles)

## Internationalization (i18n) guides

- [Introduction](i18n/index.md)
- [Externalization](i18n/externalization.md)
- [Translation](i18n/translation.md)

## Build guides

- [Building a package for testing purposes](build_test_package.md)

## Compliance

- [Licensing](licensing.md) for ensuring license compliance

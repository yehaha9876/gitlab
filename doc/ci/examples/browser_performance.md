# Analyze website performance with Sitespeed.io

This example shows how to run [Sitespeed.io][sitespeed] on your code by using
GitLab CI/CD and Sitespeed using Docker-in-Docker.

First, you need a GitLab Runner with the [docker-in-docker executor][dind].

Once you set up the Runner, add a new job to `.gitlab-ci.yml`, called `performance`:

```yaml
  stage: performance
  image: docker:git
  services:
    - docker:dind
  script:
    - mkdir gitlab-exporter
    - wget -O ./gitlab-exporter/index.js https://gitlab.com/gitlab-org/gl-performance/raw/master/index.js
    - mkdir sitespeed-results
    - docker run --shm-size=1g --rm -v "$(pwd)":/sitespeed.io sitespeedio/sitespeed.io --plugins.add ./gitlab-exporter --outputFolder sitespeed-results https://my.website.com
    - mv sitespeed-results/data/performance.json performance.json
  artifacts:
    paths:
    - [performance.json]
```

This will create a `performance` job in your CI pipeline and will run Sitespeed against the webpage you define.

For a more detailed example which allows specifying a list of URL's to test as well as passing an environment URL, see the `performance` job included in [Auto DevOps](https://gitlab.com/gitlab-org/gitlab-ci-yml/blob/master/Auto-DevOps.gitlab-ci.yml).

For GitLab [Enterprise Edition Premium][ee] users, this information can be automatically
extracted and shown right in the merge request widget. [Learn more on performance
diffs in merge requests](../../user/project/merge_requests/performance_diff.md).

[sitespeed]: https://www.sitespeed.io
[dind]: ../docker/using_docker_build.md#use-docker-in-docker-executor
[ee]: https://about.gitlab.com/gitlab-ee/

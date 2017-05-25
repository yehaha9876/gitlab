/* eslint-disable quote-props, quotes, comma-dangle */
export default {
  "id": 123,
  "user": {
    "name": "Root",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": null,
    "web_url": "http://localhost:3000/root"
  },
  "active": false,
  "coverage": null,
  "path": "/root/ci-mock/pipelines/123",
  "details": {
    "status": {
      "icon": "icon_status_success",
      "text": "passed",
      "label": "passed",
      "group": "success",
      "has_details": true,
      "details_path": "/root/ci-mock/pipelines/123",
      "favicon": "/assets/ci_favicons/dev/favicon_status_success-308b4fc054cdd1b68d0865e6cfb7b02e92e3472f201507418f8eddb74ac11a59.ico"
    },
    "duration": 9,
    "finished_at": "2017-04-19T14:30:27.542Z",
    "stages": [{
      "name": "test",
      "title": "test: passed",
      "groups": [{
        "name": "test",
        "size": 1,
        "status": {
          "icon": "icon_status_success",
          "text": "passed",
          "label": "passed",
          "group": "success",
          "has_details": true,
          "details_path": "/root/ci-mock/builds/4153",
          "favicon": "/assets/ci_favicons/dev/favicon_status_success-308b4fc054cdd1b68d0865e6cfb7b02e92e3472f201507418f8eddb74ac11a59.ico",
          "action": {
            "icon": "icon_action_retry",
            "title": "Retry",
            "path": "/root/ci-mock/builds/4153/retry",
            "method": "post"
          }
        },
        "jobs": [{
          "id": 4153,
          "name": "test",
          "build_path": "/root/ci-mock/builds/4153",
          "retry_path": "/root/ci-mock/builds/4153/retry",
          "playable": false,
          "created_at": "2017-04-13T09:25:18.959Z",
          "updated_at": "2017-04-13T09:25:23.118Z",
          "status": {
            "icon": "icon_status_success",
            "text": "passed",
            "label": "passed",
            "group": "success",
            "has_details": true,
            "details_path": "/root/ci-mock/builds/4153",
            "favicon": "/assets/ci_favicons/dev/favicon_status_success-308b4fc054cdd1b68d0865e6cfb7b02e92e3472f201507418f8eddb74ac11a59.ico",
            "action": {
              "icon": "icon_action_retry",
              "title": "Retry",
              "path": "/root/ci-mock/builds/4153/retry",
              "method": "post"
            }
          }
        }]
      }],
      "status": {
        "icon": "icon_status_success",
        "text": "passed",
        "label": "passed",
        "group": "success",
        "has_details": true,
        "details_path": "/root/ci-mock/pipelines/123#test",
        "favicon": "/assets/ci_favicons/dev/favicon_status_success-308b4fc054cdd1b68d0865e6cfb7b02e92e3472f201507418f8eddb74ac11a59.ico"
      },
      "path": "/root/ci-mock/pipelines/123#test",
      "dropdown_path": "/root/ci-mock/pipelines/123/stage.json?stage=test"
    }, {
      "name": "deploy",
      "title": "deploy: passed",
      "groups": [{
        "name": "deploy to production",
        "size": 1,
        "status": {
          "icon": "icon_status_success",
          "text": "passed",
          "label": "passed",
          "group": "success",
          "has_details": true,
          "details_path": "/root/ci-mock/builds/4166",
          "favicon": "/assets/ci_favicons/dev/favicon_status_success-308b4fc054cdd1b68d0865e6cfb7b02e92e3472f201507418f8eddb74ac11a59.ico",
          "action": {
            "icon": "icon_action_retry",
            "title": "Retry",
            "path": "/root/ci-mock/builds/4166/retry",
            "method": "post"
          }
        },
        "jobs": [{
          "id": 4166,
          "name": "deploy to production",
          "build_path": "/root/ci-mock/builds/4166",
          "retry_path": "/root/ci-mock/builds/4166/retry",
          "playable": false,
          "created_at": "2017-04-19T14:29:46.463Z",
          "updated_at": "2017-04-19T14:30:27.498Z",
          "status": {
            "icon": "icon_status_success",
            "text": "passed",
            "label": "passed",
            "group": "success",
            "has_details": true,
            "details_path": "/root/ci-mock/builds/4166",
            "favicon": "/assets/ci_favicons/dev/favicon_status_success-308b4fc054cdd1b68d0865e6cfb7b02e92e3472f201507418f8eddb74ac11a59.ico",
            "action": {
              "icon": "icon_action_retry",
              "title": "Retry",
              "path": "/root/ci-mock/builds/4166/retry",
              "method": "post"
            }
          }
        }]
      }, {
        "name": "deploy to staging",
        "size": 1,
        "status": {
          "icon": "icon_status_success",
          "text": "passed",
          "label": "passed",
          "group": "success",
          "has_details": true,
          "details_path": "/root/ci-mock/builds/4159",
          "favicon": "/assets/ci_favicons/dev/favicon_status_success-308b4fc054cdd1b68d0865e6cfb7b02e92e3472f201507418f8eddb74ac11a59.ico",
          "action": {
            "icon": "icon_action_retry",
            "title": "Retry",
            "path": "/root/ci-mock/builds/4159/retry",
            "method": "post"
          }
        },
        "jobs": [{
          "id": 4159,
          "name": "deploy to staging",
          "build_path": "/root/ci-mock/builds/4159",
          "retry_path": "/root/ci-mock/builds/4159/retry",
          "playable": false,
          "created_at": "2017-04-18T16:32:08.420Z",
          "updated_at": "2017-04-18T16:32:12.631Z",
          "status": {
            "icon": "icon_status_success",
            "text": "passed",
            "label": "passed",
            "group": "success",
            "has_details": true,
            "details_path": "/root/ci-mock/builds/4159",
            "favicon": "/assets/ci_favicons/dev/favicon_status_success-308b4fc054cdd1b68d0865e6cfb7b02e92e3472f201507418f8eddb74ac11a59.ico",
            "action": {
              "icon": "icon_action_retry",
              "title": "Retry",
              "path": "/root/ci-mock/builds/4159/retry",
              "method": "post"
            }
          }
        }]
      }],
      "status": {
        "icon": "icon_status_success",
        "text": "passed",
        "label": "passed",
        "group": "success",
        "has_details": true,
        "details_path": "/root/ci-mock/pipelines/123#deploy",
        "favicon": "/assets/ci_favicons/dev/favicon_status_success-308b4fc054cdd1b68d0865e6cfb7b02e92e3472f201507418f8eddb74ac11a59.ico"
      },
      "path": "/root/ci-mock/pipelines/123#deploy",
      "dropdown_path": "/root/ci-mock/pipelines/123/stage.json?stage=deploy"
    }],
    "artifacts": [],
    "manual_actions": [{
      "name": "deploy to production",
      "path": "/root/ci-mock/builds/4166/play",
      "playable": false
    }]
  },
  "flags": {
    "latest": true,
    "triggered": false,
    "stuck": false,
    "yaml_errors": false,
    "retryable": false,
    "cancelable": false
  },
  "ref": {
    "name": "master",
    "path": "/root/ci-mock/tree/master",
    "tag": false,
    "branch": true
  },
  "commit": {
    "id": "798e5f902592192afaba73f4668ae30e56eae492",
    "short_id": "798e5f90",
    "title": "Merge branch 'new-branch' into 'master'\r",
    "created_at": "2017-04-13T10:25:17.000+01:00",
    "parent_ids": ["54d483b1ed156fbbf618886ddf7ab023e24f8738", "c8e2d38a6c538822e81c57022a6e3a0cfedebbcc"],
    "message": "Merge branch 'new-branch' into 'master'\r\n\r\nAdd new file\r\n\r\nSee merge request !1",
    "author_name": "Root",
    "author_email": "admin@example.com",
    "authored_date": "2017-04-13T10:25:17.000+01:00",
    "committer_name": "Root",
    "committer_email": "admin@example.com",
    "committed_date": "2017-04-13T10:25:17.000+01:00",
    "author": {
      "name": "Root",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": null,
      "web_url": "http://localhost:3000/root"
    },
    "author_gravatar_url": null,
    "commit_url": "http://localhost:3000/root/ci-mock/commit/798e5f902592192afaba73f4668ae30e56eae492",
    "commit_path": "/root/ci-mock/commit/798e5f902592192afaba73f4668ae30e56eae492"
  },
  "created_at": "2017-04-13T09:25:18.881Z",
  "updated_at": "2017-04-19T14:30:27.561Z",
  "triggerer" : [{
    "id": 129,
    "user": null,
    "active": true,
    "coverage": null,
    "path": "/gitlab-org/gitlab-ce/pipelines/129",
    "project_name": "GitLab CE",
    "details": {
      "status": {
        "icon": "icon_status_running",
        "text": "running",
        "label": "running",
        "group": "running",
        "has_details": true,
        "details_path": "/gitlab-org/gitlab-ce/pipelines/129",
        "favicon": "/assets/ci_favicons/dev/favicon_status_running-c3ad2fc53ea6079c174e5b6c1351ff349e99ec3af5a5622fb77b0fe53ea279c1.ico"
      },
      "duration": null,
      "finished_at": null
    },
    "flags": {
      "latest": false,
      "triggered": false,
      "stuck": false,
      "yaml_errors": false,
      "retryable": true,
      "cancelable": true
    },
    "ref": {
      "name": "7-5-stable",
      "path": "/gitlab-org/gitlab-ce/commits/7-5-stable",
      "tag": false,
      "branch": true
    },
    "commit": {
      "id": "23433d4d8b20d7e45c103d0b6048faad38a130ab",
      "short_id": "23433d4d",
      "title": "Version 7.5.0.rc1",
      "created_at": "2014-11-17T15:44:14.000+01:00",
      "parent_ids": [
        "30ac909f30f58d319b42ed1537664483894b18cd"
      ],
      "message": "Version 7.5.0.rc1\n",
      "author_name": "Jacob Vosmaer",
      "author_email": "contact@jacobvosmaer.nl",
      "authored_date": "2014-11-17T15:44:14.000+01:00",
      "committer_name": "Jacob Vosmaer",
      "committer_email": "contact@jacobvosmaer.nl",
      "committed_date": "2014-11-17T15:44:14.000+01:00",
      "author": null,
      "author_gravatar_url": "http://www.gravatar.com/avatar/e66d11c0eedf8c07b3b18fca46599807?s=80&d=identicon",
      "commit_url": "http://localhost:3000/gitlab-org/gitlab-ce/commit/23433d4d8b20d7e45c103d0b6048faad38a130ab",
      "commit_path": "/gitlab-org/gitlab-ce/commit/23433d4d8b20d7e45c103d0b6048faad38a130ab"
    },
    "retry_path": "/gitlab-org/gitlab-ce/pipelines/129/retry",
    "cancel_path": "/gitlab-org/gitlab-ce/pipelines/129/cancel",
    "created_at": "2017-05-24T14:46:20.090Z",
    "updated_at": "2017-05-24T14:46:29.906Z"
  }],
  "triggered": [
    {
      "id": 132,
      "user": null,
      "active": true,
      "coverage": null,
      "path": "/gitlab-org/gitlab-ce/pipelines/132",
      "project_name": "GitLab CE",
      "details": {
        "status": {
          "icon": "icon_status_running",
          "text": "running",
          "label": "running",
          "group": "running",
          "has_details": true,
          "details_path": "/gitlab-org/gitlab-ce/pipelines/132",
          "favicon": "/assets/ci_favicons/dev/favicon_status_running-c3ad2fc53ea6079c174e5b6c1351ff349e99ec3af5a5622fb77b0fe53ea279c1.ico"
        },
        "duration": null,
        "finished_at": null
      },
      "flags": {
        "latest": false,
        "triggered": false,
        "stuck": false,
        "yaml_errors": false,
        "retryable": true,
        "cancelable": true
      },
      "ref": {
        "name": "crowd",
        "path": "/gitlab-org/gitlab-ce/commits/crowd",
        "tag": false,
        "branch": true
      },
      "commit": {
        "id": "b9d58c4cecd06be74c3cc32ccfb522b31544ab2e",
        "short_id": "b9d58c4c",
        "title": "getting user keys publically through http without any authentication, the github…",
        "created_at": "2013-10-03T12:50:33.000+05:30",
        "parent_ids": [
          "e219cf7246c6a0495e4507deaffeba11e79f13b8"
        ],
        "message": "getting user keys publically through http without any authentication, the github way. E.g: http://github.com/devaroop.keys\n\nchangelog updated to include ssh key retrieval feature update\n",
        "author_name": "devaroop",
        "author_email": "devaroop123@yahoo.co.in",
        "authored_date": "2013-10-02T20:39:29.000+05:30",
        "committer_name": "devaroop",
        "committer_email": "devaroop123@yahoo.co.in",
        "committed_date": "2013-10-03T12:50:33.000+05:30",
        "author": null,
        "author_gravatar_url": "http://www.gravatar.com/avatar/35df4b155ec66a3127d53459941cf8a2?s=80&d=identicon",
        "commit_url": "http://localhost:3000/gitlab-org/gitlab-ce/commit/b9d58c4cecd06be74c3cc32ccfb522b31544ab2e",
        "commit_path": "/gitlab-org/gitlab-ce/commit/b9d58c4cecd06be74c3cc32ccfb522b31544ab2e"
      },
      "retry_path": "/gitlab-org/gitlab-ce/pipelines/132/retry",
      "cancel_path": "/gitlab-org/gitlab-ce/pipelines/132/cancel",
      "created_at": "2017-05-24T14:46:24.644Z",
      "updated_at": "2017-05-24T14:48:55.226Z"
    },
    {
      "id": 133,
      "user": null,
      "active": true,
      "coverage": null,
      "path": "/gitlab-org/gitlab-ce/pipelines/133",
      "project_name": "GitLab CE",
      "details": {
        "status": {
          "icon": "icon_status_running",
          "text": "running",
          "label": "running",
          "group": "running",
          "has_details": true,
          "details_path": "/gitlab-org/gitlab-ce/pipelines/133",
          "favicon": "/assets/ci_favicons/dev/favicon_status_running-c3ad2fc53ea6079c174e5b6c1351ff349e99ec3af5a5622fb77b0fe53ea279c1.ico"
        },
        "duration": null,
        "finished_at": null
      },
      "flags": {
        "latest": false,
        "triggered": false,
        "stuck": false,
        "yaml_errors": false,
        "retryable": true,
        "cancelable": true
      },
      "ref": {
        "name": "crowd",
        "path": "/gitlab-org/gitlab-ce/commits/crowd",
        "tag": false,
        "branch": true
      },
      "commit": {
        "id": "b6bd4856a33df3d144be66c4ed1f1396009bb08b",
        "short_id": "b6bd4856",
        "title": "getting user keys publically through http without any authentication, the github…",
        "created_at": "2013-10-02T20:39:29.000+05:30",
        "parent_ids": [
          "e219cf7246c6a0495e4507deaffeba11e79f13b8"
        ],
        "message": "getting user keys publically through http without any authentication, the github way. E.g: http://github.com/devaroop.keys\n",
        "author_name": "devaroop",
        "author_email": "devaroop123@yahoo.co.in",
        "authored_date": "2013-10-02T20:39:29.000+05:30",
        "committer_name": "devaroop",
        "committer_email": "devaroop123@yahoo.co.in",
        "committed_date": "2013-10-02T20:39:29.000+05:30",
        "author": null,
        "author_gravatar_url": "http://www.gravatar.com/avatar/35df4b155ec66a3127d53459941cf8a2?s=80&d=identicon",
        "commit_url": "http://localhost:3000/gitlab-org/gitlab-ce/commit/b6bd4856a33df3d144be66c4ed1f1396009bb08b",
        "commit_path": "/gitlab-org/gitlab-ce/commit/b6bd4856a33df3d144be66c4ed1f1396009bb08b"
      },
      "retry_path": "/gitlab-org/gitlab-ce/pipelines/133/retry",
      "cancel_path": "/gitlab-org/gitlab-ce/pipelines/133/cancel",
      "created_at": "2017-05-24T14:46:24.648Z",
      "updated_at": "2017-05-24T14:48:59.673Z"
    },
    {
      "id": 130,
      "user": null,
      "active": true,
      "coverage": null,
      "path": "/gitlab-org/gitlab-ce/pipelines/130",
      "project_name": "GitLab CE",
      "details": {
        "status": {
          "icon": "icon_status_running",
          "text": "running",
          "label": "running",
          "group": "running",
          "has_details": true,
          "details_path": "/gitlab-org/gitlab-ce/pipelines/130",
          "favicon": "/assets/ci_favicons/dev/favicon_status_running-c3ad2fc53ea6079c174e5b6c1351ff349e99ec3af5a5622fb77b0fe53ea279c1.ico"
        },
        "duration": null,
        "finished_at": null
      },
      "flags": {
        "latest": false,
        "triggered": false,
        "stuck": false,
        "yaml_errors": false,
        "retryable": true,
        "cancelable": true
      },
      "ref": {
        "name": "crowd",
        "path": "/gitlab-org/gitlab-ce/commits/crowd",
        "tag": false,
        "branch": true
      },
      "commit": {
        "id": "6d7ced4a2311eeff037c5575cca1868a6d3f586f",
        "short_id": "6d7ced4a",
        "title": "Whitespace fixes to patch",
        "created_at": "2013-10-08T13:53:22.000-05:00",
        "parent_ids": [
          "1875141a963a4238bda29011d8f7105839485253"
        ],
        "message": "Whitespace fixes to patch\n",
        "author_name": "Dale Hamel",
        "author_email": "dale.hamel@srvthe.net",
        "authored_date": "2013-10-08T13:53:22.000-05:00",
        "committer_name": "Dale Hamel",
        "committer_email": "dale.hamel@invenia.ca",
        "committed_date": "2013-10-08T13:53:22.000-05:00",
        "author": null,
        "author_gravatar_url": "http://www.gravatar.com/avatar/cd08930e69fa5ad1a669206e7bafe476?s=80&d=identicon",
        "commit_url": "http://localhost:3000/gitlab-org/gitlab-ce/commit/6d7ced4a2311eeff037c5575cca1868a6d3f586f",
        "commit_path": "/gitlab-org/gitlab-ce/commit/6d7ced4a2311eeff037c5575cca1868a6d3f586f"
      },
      "retry_path": "/gitlab-org/gitlab-ce/pipelines/130/retry",
      "cancel_path": "/gitlab-org/gitlab-ce/pipelines/130/cancel",
      "created_at": "2017-05-24T14:46:24.630Z",
      "updated_at": "2017-05-24T14:49:45.091Z"
    }
  ],
};

const failedPipeline = {
  id: 1,
  user: {
    id: 1,
    name: "Test",
    username: "test",
    state: "active",
    avatar_url: "https://www.gravatar.com/avatar/395842744c8d57c80f8e5fbeffe0a50b?s=80\u0026d=identicon",
    web_url: "http://localhost:3000/test",
    status_tooltip_html: null,
    path: "/test",
  },
  active: false,
  path: "/test/test-project/pipelines/1",
  details: {
    status: {
      icon: "status_failed",
      text: "failed",
      label: "failed",
      group: "failed",
      tooltip: "failed",
      has_details: true,
      details_path: "test/test-project/pipelines/1",
      illustration: null,
    },
    finished_at: "2019-02-02T08:00:03.970Z",
  },
  ref: {
    name: "master",
    path: "test/test-project/commits/master",
    tag: false,
    branch: true,
    merge_request: false,
  },
  commit: {
    id: "e778416d94deaf75bdabcc8fdd6b7d21f482bcca",
    short_id: "e778416d",
    title: "Add new file to the branch I'm working on",
    message: "Add new file to the branch I'm working on",
    author: {
      id: 1,
      name: "Test",
      username: "test",
      state: "active",
      avatar_url: "https://www.gravatar.com/avatar/395842744c8d57c80f8e5fbeffe0a50b?s=80\u0026d=identicon",
      status_tooltip_html: null,
      path: "/test",
    },
    commit_url: "http://localhost:3000/matteeyah/test-project/commit/e778416d94deaf75bdabcc8fdd6b7d21f482bcca",
    commit_path: "/matteeyah/test-project/commit/e778416d94deaf75bdabcc8fdd6b7d21f482bcca",
  },
};

const passedPipeline = {
  id: 1,
  user: {
    id: 1,
    name: "Test",
    username: "test",
    state: "active",
    avatar_url: "https://www.gravatar.com/avatar/395842744c8d57c80f8e5fbeffe0a50b?s=80\u0026d=identicon",
    web_url: "http://localhost:3000/test",
    status_tooltip_html: null,
    path: "/test",
  },
  active: false,
  path: "/test/test-project/pipelines/1",
  details: {
    status: {
      icon: "status_success",
      text: "success",
      label: "success",
      group: "success",
      tooltip: "success",
      has_details: true,
      details_path: "test/test-project/pipelines/1",
      illustration: null,
    },
    finished_at: "2019-02-02T08:00:03.970Z",
  },
  ref: {
    name: "master",
    path: "test/test-project/commits/master",
    tag: false,
    branch: true,
    merge_request: false,
  },
  commit: {
    id: "e778416d94deaf75bdabcc8fdd6b7d21f482bcca",
    short_id: "e778416d",
    title: "Add new file to the branch I'm working on",
    message: "Add new file to the branch I'm working on",
    author: {
      id: 1,
      name: "Test",
      username: "test",
      state: "active",
      avatar_url: "https://www.gravatar.com/avatar/395842744c8d57c80f8e5fbeffe0a50b?s=80\u0026d=identicon",
      status_tooltip_html: null,
      path: "/test",
    },
    commit_url: "http://localhost:3000/matteeyah/test-project/commit/e778416d94deaf75bdabcc8fdd6b7d21f482bcca",
    commit_path: "/matteeyah/test-project/commit/e778416d94deaf75bdabcc8fdd6b7d21f482bcca",
  },
};

const runningPipeline = {
  id: 1,
  user: {
    id: 1,
    name: "Test",
    username: "test",
    state: "active",
    avatar_url: "https://www.gravatar.com/avatar/395842744c8d57c80f8e5fbeffe0a50b?s=80\u0026d=identicon",
    web_url: "http://localhost:3000/test",
    status_tooltip_html: null,
    path: "/test",
  },
  active: true,
  path: "/test/test-project/pipelines/1",
  details: {
    status: {
      icon: "status_running",
      text: "running",
      label: "running",
      group: "running",
      tooltip: "running",
      has_details: true,
      details_path: "test/test-project/pipelines/1",
      illustration: null,
    },
    finished_at: "2019-02-02T08:00:03.970Z",
  },
  ref: {
    name: "master",
    path: "test/test-project/commits/master",
    tag: false,
    branch: true,
    merge_request: false,
  },
  commit: {
    id: "e778416d94deaf75bdabcc8fdd6b7d21f482bcca",
    short_id: "e778416d",
    title: "Add new file to the branch I'm working on",
    message: "Add new file to the branch I'm working on",
    author: {
      id: 1,
      name: "Test",
      username: "test",
      state: "active",
      avatar_url: "https://www.gravatar.com/avatar/395842744c8d57c80f8e5fbeffe0a50b?s=80\u0026d=identicon",
      status_tooltip_html: null,
      path: "/test",
    },
    commit_url: "http://localhost:3000/matteeyah/test-project/commit/e778416d94deaf75bdabcc8fdd6b7d21f482bcca",
    commit_path: "/matteeyah/test-project/commit/e778416d94deaf75bdabcc8fdd6b7d21f482bcca",
  },
};

export default {
  projects: [{
      id: 1,
      description: "",
      name: "test-project",
      name_with_namespace: "Test / test-project",
      path: "test-project",
      path_with_namespace: "test/test-project",
      created_at: "2019-02-01T15:40:27.522Z",
      default_branch: "master",
      tag_list: [],
      avatar_url: null,
      namespace: {
        id: 1,
        name: "test",
        path: "test",
        kind: "user",
        full_path: "user",
        parent_id: null,
      },
      remove_path: "/-/operations?project_id=1",
      last_pipeline: passedPipeline,
      downstream_pipelines: [],
      alert_count: 0,
    },
    {
      id: 2,
      description: "",
      name: "test-project",
      name_with_namespace: "Test / test-project",
      path: "test-project",
      path_with_namespace: "test/test-project",
      created_at: "2019-02-01T15:40:27.522Z",
      default_branch: "master",
      tag_list: [],
      avatar_url: null,
      namespace: {
        id: 1,
        name: "test",
        path: "test",
        kind: "user",
        full_path: "user",
        parent_id: null,
      },
      remove_path: "/-/operations?project_id=1",
      last_pipeline: passedPipeline,
      upstream_pipeline: passedPipeline,
      downstream_pipelines: [
        passedPipeline,
        passedPipeline,
        passedPipeline,
      ],
      alert_count: 0,
    },
    {
      id: 3,
      description: "",
      name: "test-project",
      name_with_namespace: "Test / test-project",
      path: "test-project",
      path_with_namespace: "test/test-project",
      created_at: "2019-02-01T15:40:27.522Z",
      default_branch: "master",
      tag_list: [],
      avatar_url: null,
      namespace: {
        id: 1,
        name: "test",
        path: "test",
        kind: "user",
        full_path: "user",
        parent_id: null,
      },
      remove_path: "/-/operations?project_id=1",
      last_pipeline: passedPipeline,
      upstream_pipeline: passedPipeline,
      downstream_pipelines: [
        passedPipeline,
        failedPipeline,
        passedPipeline,
      ],
      alert_count: 0,
    },
    {
      id: 4,
      description: "",
      name: "test-project",
      name_with_namespace: "Test / test-project",
      path: "test-project",
      path_with_namespace: "test/test-project",
      created_at: "2019-02-01T15:40:27.522Z",
      default_branch: "master",
      tag_list: [],
      avatar_url: null,
      namespace: {
        id: 1,
        name: "test",
        path: "test",
        kind: "user",
        full_path: "user",
        parent_id: null,
      },
      remove_path: "/-/operations?project_id=1",
      last_pipeline: passedPipeline,
      downstream_pipelines: [],
      alert_count: 1,
    },
    {
      id: 5,
      description: "",
      name: "test-project",
      name_with_namespace: "Test / test-project",
      path: "test-project",
      path_with_namespace: "test/test-project",
      created_at: "2019-02-01T15:40:27.522Z",
      default_branch: "master",
      tag_list: [],
      avatar_url: null,
      namespace: {
        id: 1,
        name: "test",
        path: "test",
        kind: "user",
        full_path: "user",
        parent_id: null,
      },
      remove_path: "/-/operations?project_id=1",
      last_pipeline: passedPipeline,
      upstream_pipeline: passedPipeline,
      downstream_pipelines: [
        passedPipeline,
        failedPipeline,
        passedPipeline,
      ],
      alert_count: 1,
    },
    {
      id: 6,
      description: "",
      name: "test-project",
      name_with_namespace: "Test / test-project",
      path: "test-project",
      path_with_namespace: "test/test-project",
      created_at: "2019-02-01T15:40:27.522Z",
      default_branch: "master",
      tag_list: [],
      avatar_url: null,
      namespace: {
        id: 1,
        name: "test",
        path: "test",
        kind: "user",
        full_path: "user",
        parent_id: null,
      },
      remove_path: "/-/operations?project_id=1",
      last_pipeline: failedPipeline,
      upstream_pipeline: passedPipeline,
      downstream_pipelines: [],
      alert_count: 1,
    },
    {
      id: 7,
      description: "",
      name: "test-project",
      name_with_namespace: "Test / test-project",
      path: "test-project",
      path_with_namespace: "test/test-project",
      created_at: "2019-02-01T15:40:27.522Z",
      default_branch: "master",
      tag_list: [],
      avatar_url: null,
      namespace: {
        id: 1,
        name: "test",
        path: "test",
        kind: "user",
        full_path: "user",
        parent_id: null,
      },
      remove_path: "/-/operations?project_id=1",
      last_pipeline: failedPipeline,
      downstream_pipelines: [],
      alert_count: 0,
    },
    {
      id: 8,
      description: "",
      name: "test-project",
      name_with_namespace: "Test / test-project",
      path: "test-project",
      path_with_namespace: "test/test-project",
      created_at: "2019-02-01T15:40:27.522Z",
      default_branch: "master",
      tag_list: [],
      avatar_url: null,
      namespace: {
        id: 1,
        name: "test",
        path: "test",
        kind: "user",
        full_path: "user",
        parent_id: null,
      },
      remove_path: "/-/operations?project_id=1",
      last_pipeline: failedPipeline,
      upstream_pipeline: passedPipeline,
      downstream_pipelines: [],
      alert_count: 0,
    },
    {
      id: 9,
      description: "",
      name: "test-project",
      name_with_namespace: "Test / test-project",
      path: "test-project",
      path_with_namespace: "test/test-project",
      created_at: "2019-02-01T15:40:27.522Z",
      default_branch: "master",
      tag_list: [],
      avatar_url: null,
      namespace: {
        id: 1,
        name: "test",
        path: "test",
        kind: "user",
        full_path: "user",
        parent_id: null,
      },
      remove_path: "/-/operations?project_id=1",
      last_pipeline: runningPipeline,
      upstream_pipeline: passedPipeline,
      downstream_pipelines: [],
      alert_count: 0,
    },
    {
      id: 20,
      description: "",
      name: "test-project",
      name_with_namespace: "Test / test-project",
      path: "test-project",
      path_with_namespace: "test/test-project",
      created_at: "2019-02-01T15:40:27.522Z",
      default_branch: "master",
      tag_list: [],
      avatar_url: null,
      namespace: {
        id: 1,
        name: "test",
        path: "test",
        kind: "user",
        full_path: "user",
        parent_id: null,
      },
      remove_path: "/-/operations?project_id=1",
      last_pipeline: passedPipeline,
      upstream_pipeline: passedPipeline,
      downstream_pipelines: [
        passedPipeline,
        passedPipeline,
        passedPipeline,
        passedPipeline,
        passedPipeline,
        passedPipeline,
        passedPipeline,
        passedPipeline,
        passedPipeline,
        passedPipeline,
        passedPipeline,
        passedPipeline,
        passedPipeline,
        passedPipeline,
        passedPipeline,
        passedPipeline,
        passedPipeline,
        passedPipeline,
        passedPipeline,
        passedPipeline,
        passedPipeline,
      ],
      alert_count: 0,
    },
  ]
};
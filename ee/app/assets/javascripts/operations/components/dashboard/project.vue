<script>
import { mapActions } from 'vuex';
import { __ } from '~/locale';
import ProjectHeader from './project_header.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import Commit from '~/vue_shared/components/commit.vue';
import TimeAgo from './time_ago.vue';
import Alerts from './alerts.vue';
import ProjectPipeline from './project_pipeline.vue';

export default {
  components: {
    ProjectHeader,
    UserAvatarLink,
    Commit,
    TimeAgo,
    Alerts,
    ProjectPipeline,
  },
  props: {
    project: {
      type: Object,
      required: true,
    },
  },
  computed: {
    hasPipelineFailed() {
      return this.lastPipeline && this.lastPipeline.details.status.group === 'failed';
    },
    hasPipelineErrors() {
      return this.project.alert_count > 0;
    },
    cardClasses() {
      return {
        'ops-dashboard-project-card-warning': !this.hasPipelineFailed && this.hasPipelineErrors,
        'ops-dashboard-project-card-failed': this.hasPipelineFailed,
      };
    },
    noPipelineMessage() {
      return __('The branch for this project has no active pipeline configuration.');
    },
    user() {
      return this.lastPipeline && this.lastPipeline.user ? this.lastPipeline.user : null;
    },
    lastPipeline() {
      return this.project.last_pipeline && this.project.last_pipeline.id
        ? this.project.last_pipeline
        : null;
    },
    commitRef() {
      return {
        ...this.lastPipeline.ref,
        ref_url: this.lastPipeline.ref.path,
      };
    },
    finishedTime() {
      return this.lastPipeline.details.finished_at;
    },
    isPipelineRunning() {
      return this.lastPipeline.details.status.group === 'running';
    },
  },
  methods: {
    ...mapActions(['removeProject']),
  },
};
</script>
<template>
  <div class="ops-dashboard-project card">
    <project-header
      :project="project"
      :has-pipeline-failed="hasPipelineFailed"
      :has-errors="hasPipelineErrors"
      @remove="removeProject"
    />

    <div :class="cardClasses" class="ops-dashboard-project-card-body card-body">
      <div v-if="!lastPipeline" class="h-100 d-flex justify-content-center align-items-center">
        <div class="text-plain text-center bold w-75 ops-dashboard-project-empty-state">
          {{ noPipelineMessage }}
        </div>
      </div>

      <div v-else>
        <div class="row">
          <div class="col-1 align-self-center">
            <user-avatar-link
              v-if="user"
              :link-href="user.path"
              :img-src="user.avatar_url"
              :tooltip-text="user.name"
              :img-size="24"
            />
          </div>

          <div class="col-6 pr-0 align-self-center ops-dashboard-project-commit">
            <commit
              :tag="lastPipeline.ref.tag"
              :commit-ref="commitRef"
              :short-sha="lastPipeline.commit.short_id"
              :commit-url="lastPipeline.commit.commit_url"
              :title="lastPipeline.commit.title"
              :author="lastPipeline.commit.author"
              :show-branch="true"
            />
          </div>

          <div class="col-5 pl-0 text-right align-self-center">
            <time-ago v-if="!isPipelineRunning" :finished-time="finishedTime" />
            <alerts :count="project.alert_count" />
          </div>

          <div class="col-12">
            <project-pipeline
              :current-status="lastPipeline.details.status"
              :upstream-pipeline="project.upstream_pipeline"
              :downstream-pipelines="project.downstream_pipelines"
              :has-pipeline-failed="hasPipelineFailed"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

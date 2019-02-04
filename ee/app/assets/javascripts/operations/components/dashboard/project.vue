<script>
import { mapActions } from 'vuex';
import { __ } from '~/locale';
import timeago from '~/vue_shared/mixins/timeago';
import Icon from '~/vue_shared/components/icon.vue';
import Commit from '~/vue_shared/components/commit.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import TimeAgo from './time_ago.vue';
import DashboardAlerts from './alerts.vue';
import ProjectHeader from './project_header.vue';
import ProjectPipeline from './project_pipeline.vue';

export default {
  components: {
    Icon,
    Commit,
    DashboardAlerts,
    ProjectHeader,
    ProjectPipeline,
    TimeAgo,
    UserAvatarLink,
  },
  mixins: [timeago],
  props: {
    project: {
      type: Object,
      required: true,
    },
  },
  computed: {
    user() {
      return this.project.last_deployment && this.project.last_deployment.user
        ? this.project.last_deployment.user
        : null;
    },
    finishedTime() {
      return this.project.last_deployment && this.project.last_deployment.finished_time;
    },
    isPipelineRunning() {
      return this.project.pipeline_status.group === 'running';
    },
    hasErrors() {
      return this.project.alert_count > 0;
    },
    hasPipelineFailed() {
      return this.project.pipeline_status.group === 'failed';
    },
    cardClasses() {
      return {
        'ops-dashboard-project-card-warning': !this.hasPipelineFailed && this.hasErrors,
        'ops-dashboard-project-card-failed': this.hasPipelineFailed,
      };
    },
    hasPipelineStatus() {
      return this.project.pipeline_status !== null && this.project.pipeline_status !== undefined;
    },
    hasLastDeployment() {
      return this.project.last_deployment !== null && this.project.last_deployment !== undefined;
    },
    hasCommit() {
      return (
        this.hasLastDeployment &&
        this.project.last_deployment.commit !== null &&
        this.project.last_deployment.commit !== undefined
      );
    },
    commitRef() {
      return {
        ...this.project.last_deployment.ref,
        ref_url: this.project.last_deployment.ref.ref_path,
      };
    },
    noPipelineMessage() {
      return __('The branch for this project has no active pipeline configuration.');
    },
    emptyProjectMessage() {
      return __('The branch for this project is empty');
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
      :has-errors="hasErrors"
      @remove="removeProject"
    />
    <div :class="cardClasses" class="ops-dashboard-project-card-body card-body">
      <div v-if="!hasLastDeployment" class="h-100 d-flex justify-content-center align-items-center">
        <div class="text-plain text-center bold w-75 ops-dashboard-project-empty-state">
          {{ noPipelineMessage }}
        </div>
      </div>
      <div v-else-if="!hasCommit" class="h-100 d-flex justify-content-center align-items-center">
        <div class="text-plain text-center bold w-75 ops-dashboard-project-empty-state">
          {{ emptyProjectMessage }}
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
              v-if="project.last_deployment"
              :tag="project.last_deployment.tag"
              :commit-ref="commitRef"
              :short-sha="project.last_deployment.commit.short_id"
              :commit-url="project.last_deployment.commit.commit_url"
              :title="project.last_deployment.commit.title"
              :author="project.last_deployment.commit.author"
              :show-branch="true"
            />
          </div>

          <div class="col-5 pl-0 text-right align-self-center">
            <time-ago v-if="!isPipelineRunning" :finished-time="finishedTime" />
            <dashboard-alerts
              :count="project.alert_count"
              :last-alert="project.last_alert"
              :alert-path="project.alert_path"
            />
          </div>
        </div>

        <project-pipeline
          v-if="hasPipelineStatus"
          :project="project"
          :has-pipeline-failed="hasPipelineFailed"
        />
      </div>
    </div>
  </div>
</template>

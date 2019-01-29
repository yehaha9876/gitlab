<script>
import { mapActions } from 'vuex';
import timeago from '~/vue_shared/mixins/timeago';
import Icon from '~/vue_shared/components/icon.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import TimeAgo from './time_ago.vue';
import DashboardAlerts from './alerts.vue';
import ProjectHeader from './project_header.vue';
import ProjectCommit from './project_commit.vue';
import ProjectPipeline from './project_pipeline.vue';

export default {
  components: {
    Icon,
    DashboardAlerts,
    ProjectHeader,
    ProjectCommit,
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
    <div :class="cardClasses" class="card-body">
      <div class="row">
        <div class="col-1 align-self-center">
          <user-avatar-link
            v-if="user"
            :link-href="user.path"
            :img-src="user.avatar_url"
            :tooltip-text="user.name"
          />
        </div>

        <div class="col-6 align-self-center ops-dashboard-project-commit">
          <project-commit
            v-if="project.last_deployment"
            :last-deployment="project.last_deployment"
          />
        </div>

        <div class="col-5 text-right align-self-center">
          <time-ago v-if="!isPipelineRunning" :finished-time="finishedTime" />
          <dashboard-alerts
            :count="project.alert_count"
            :last-alert="project.last_alert"
            :alert-path="project.alert_path"
          />
        </div>
      </div>

      <project-pipeline :project="project" :has-pipeline-failed="hasPipelineFailed" />
    </div>
  </div>
</template>

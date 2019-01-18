<script>
import { mapActions } from 'vuex';
import timeago from '~/vue_shared/mixins/timeago';
import Icon from '~/vue_shared/components/icon.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
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
    hasDeployment() {
      return this.project.last_deployment !== null;
    },
    lastDeployed() {
      return this.hasDeployment ? this.timeFormated(this.project.last_deployment.created_at) : null;
    },
  },
  methods: {
    ...mapActions(['removeProject']),
  },
};
</script>

<template>
  <div class="card">
    <project-header :project="project" class="card-header" @remove="removeProject" />
    <div class="card-body">
      <div class="row">
        <div class="col-1 align-self-center">
          <user-avatar-link
            v-if="user"
            :link-href="user.path"
            :img-src="user.avatar_url"
            :tooltip-text="user.name"
          />
        </div>

        <div class="col-7 align-self-center operations-dashboard-project-commit">
          <template v-if="project.last_deployment">
            <project-commit :last-deployment="project.last_deployment" />
          </template>
        </div>

        <div class="col-4 text-right align-self-center">
          <dashboard-alerts
            :count="project.alert_count"
            :last-alert="project.last_alert"
            :alert-path="project.alert_path"
          />
        </div>
      </div>

      <project-pipeline :project="project" />
    </div>
  </div>
</template>

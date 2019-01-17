<script>
import { mapActions } from 'vuex';
import timeago from '~/vue_shared/mixins/timeago';
import Icon from '~/vue_shared/components/icon.vue';
import Commit from '~/vue_shared/components/commit.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import DashboardAlerts from './alerts.vue';
import ProjectHeader from './project_header.vue';

export default {
  components: {
    Icon,
    Commit,
    DashboardAlerts,
    ProjectHeader,
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
    commitRef() {
      return this.hasDeployment && this.project.last_deployment.ref
        ? {
            name: this.project.last_deployment.ref.name,
            ref_url: this.project.last_deployment.ref.ref_path,
          }
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
        <div class="col-1">
          <user-avatar-link
            v-if="user"
            :link-href="user.path"
            :img-src="user.avatar_url"
            :tooltip-text="user.name"
          />
        </div>

        <div class="col-7">
          <template v-if="project.last_deployment">
            <commit
              :commit-ref="commitRef"
              :short-sha="project.last_deployment.commit.short_id"
              :commit-url="project.last_deployment.commit.commit_url"
              :title="project.last_deployment.commit.title"
              :author="user"
              :tag="project.last_deployment.tag"
            />
          </template>
        </div>

        <div class="col-4 text-right">
          <dashboard-alerts
            :count="project.alert_count"
            :last-alert="project.last_alert"
            :alert-path="project.alert_path"
          />
        </div>
      </div>
      <div class="text-center">downstream info</div>
    </div>
  </div>
</template>

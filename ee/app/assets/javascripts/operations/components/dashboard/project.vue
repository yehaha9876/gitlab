<script>
import { mapActions } from 'vuex';
import _ from 'underscore';
import { GlTooltip } from '@gitlab/ui';
import { __ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import Commit from '~/vue_shared/components/commit.vue';
import Tooltip from '~/vue_shared/directives/tooltip';
import ProjectHeader from './project_header.vue';
import Alerts from './alerts.vue';
import ProjectPipeline from './project_pipeline.vue';
import { STATUS_FAILED, STATUS_RUNNING } from '../../constants';

export default {
  components: {
    ProjectHeader,
    UserAvatarLink,
    Commit,
    Alerts,
    ProjectPipeline,
    GlTooltip,
    Icon,
  },
  directives: {
    Tooltip,
  },
  mixins: [timeagoMixin],
  props: {
    project: {
      type: Object,
      required: true,
    },
  },
  tooltips: {
    timeAgo: __('Finished'),
    triggerer: __('Triggerer'),
  },
  computed: {
    hasPipelineFailed() {
      return (
        this.lastPipeline &&
        this.lastPipeline.details &&
        this.lastPipeline.details.status &&
        this.lastPipeline.details.status.group === STATUS_FAILED
      );
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
      return this.lastPipeline && !_.isEmpty(this.lastPipeline.user)
        ? this.lastPipeline.user
        : null;
    },
    lastPipeline() {
      return !_.isEmpty(this.project.last_pipeline) ? this.project.last_pipeline : null;
    },
    commitRef() {
      return this.lastPipeline && !_.isEmpty(this.lastPipeline.ref)
        ? {
            ...this.lastPipeline.ref,
            ref_url: this.lastPipeline.ref.path,
          }
        : {};
    },
    finishedTime() {
      return (
        this.lastPipeline && this.lastPipeline.details && this.lastPipeline.details.finished_at
      );
    },
    finishedTimeTitle() {
      return this.tooltipTitle(this.finishedTime);
    },
    shouldShowTimeAgo() {
      return (
        this.lastPipeline &&
        this.lastPipeline.details &&
        this.lastPipeline.details.status &&
        this.lastPipeline.details.status.group !== STATUS_RUNNING &&
        this.finishedTime
      );
    },
  },
  methods: {
    ...mapActions(['removeProject']),
  },
};
</script>
<template>
  <div class="ops-dashboard-project card border-0">
    <project-header
      :project="project"
      :has-pipeline-failed="hasPipelineFailed"
      :has-errors="hasPipelineErrors"
      @remove="removeProject"
    />

    <div :class="cardClasses" class="ops-dashboard-project-card bg-secondary card-body">
      <div v-if="lastPipeline" class="row">
        <div class="col-1 align-self-center">
          <user-avatar-link
            v-if="user"
            :link-href="user.path"
            :img-src="user.avatar_url"
            :tooltip-text="user.name"
            :img-size="32"
          />
        </div>

        <div class="col-10 col-sm-6 pr-0 pl-5 align-self-center align-middle ci-table">
          <commit
            :tag="commitRef.tag"
            :commit-ref="commitRef"
            :short-sha="lastPipeline.commit.short_id"
            :commit-url="lastPipeline.commit.commit_url"
            :title="lastPipeline.commit.title"
            :author="lastPipeline.commit.author"
            :show-branch="true"
          />
        </div>

        <div class="col-sm-5 pl-0 text-right align-self-center d-none d-sm-block">
          <div v-if="shouldShowTimeAgo" class="js-dashboard-project-time-ago text-secondary">
            <icon name="clock" class="ops-dashboard-project-time-ago-icon align-text-bottom" />

            <time ref="timeAgo">
              {{ timeFormated(finishedTime) }}
            </time>
            <gl-tooltip :target="() => $refs.timeAgo">
              <div class="bold">{{ $options.tooltips.timeAgo }}</div>
              <div>{{ finishedTimeTitle }}</div>
            </gl-tooltip>
          </div>
          <alerts :count="project.alert_count" />
        </div>

        <div class="col-12">
          <project-pipeline
            :project-name="project.name_with_namespace"
            :status="lastPipeline.details.status"
            :upstream-pipeline="project.upstream_pipeline"
            :downstream-pipelines="project.downstream_pipelines"
            :has-pipeline-failed="hasPipelineFailed"
          />
        </div>
      </div>

      <div v-else class="h-100 d-flex justify-content-center align-items-center">
        <div class=" text-plain text-metric text-center bold w-75">
          {{ noPipelineMessage }}
        </div>
      </div>
    </div>
  </div>
</template>

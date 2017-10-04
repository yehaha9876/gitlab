<script>
  /* global Flash */
  import Cookies from 'js-cookie';
  import iconLock from 'icons/_icon_lock.svg';
  import iconNoData from 'icons/_icon_no_data.svg';
  import stageCodeComponent from './stage_code_component.vue';
  import stagePlanComponent from './stage_plan_component.vue';
  import stageComponent from './stage_component.vue';
  import stageReviewComponent from './stage_review_component.vue';
  import stageStagingComponent from './stage_staging_component.vue';
  import stageTestComponent from './stage_test_component.vue';
  import loadingIcon from '../../vue_shared/components/loading_icon.vue';
  import pipelineHealth from './pipeline_health.vue';
  import panelHeader from './panel_header.vue';
  import banner from './banner.vue';
  import CycleAnalyticsService from '../cycle_analytics_service';
  import CycleAnalyticsStore from '../cycle_analytics_store';
  import '../../flash';

  const OVERVIEW_DIALOG_COOKIE = 'cycle_analytics_help_dismissed';

  export default {
    name: 'cycleAnaliticsApp',
    props: {
      endpoint: {
        type: String,
        required: true,
      },
      helpPath: {
        type: String,
        required: true,
      },
      noData: {
        type: Boolean,
        required: true,
      },
      cssClass: {
        type: String,
        required: false,
      },
    },
    components: {
      'stage-issue-component': stageComponent,
      'stage-plan-component': stagePlanComponent,
      'stage-code-component': stageCodeComponent,
      'stage-test-component': stageTestComponent,
      'stage-review-component': stageReviewComponent,
      'stage-staging-component': stageStagingComponent,
      'stage-production-component': stageComponent,
      loadingIcon,
      banner,
      panelHeader,
      pipelineHealth,
      stageComponent,
    },
    data() {
      const store = new CycleAnalyticsStore();
      const service = new CycleAnalyticsService({ requestPath: this.endpoint });

      return {
        store,
        service,
        state: store.state,
        isLoading: false,
        isLoadingStage: false,
        isEmptyStage: false,
        hasError: false,
        startDate: 30,
        isOverviewDialogDismissed: Cookies.get(OVERVIEW_DIALOG_COOKIE),
      };
    },
    computed: {
      currentStage() {
        return this.store.currentActiveStage();
      },
      iconLock() {
        return iconLock;
      },
      hasNoPermissions() {
        return !this.isLoadingStage && !this.currentStage.isUserAllowed;
      },
      iconNoData() {
        return iconNoData;
      },
    },
    methods: {
      handleError() {
        this.store.setErrorState(true);
        return Flash('There was an error while fetching cycle analytics data.');
      },
      onClickDropdown(value) {
        this.startDate = value;
        this.fetchCycleAnalyticsData({ startDate: this.startDate });
      },
      fetchCycleAnalyticsData(options) {
        const fetchOptions = options || { startDate: this.startDate };

        this.isLoading = true;

        this.service
          .fetchCycleAnalyticsData(fetchOptions)
          .then(resp => resp.json())
          .then((response) => {
            this.store.setCycleAnalyticsData(response);
            this.selectDefaultStage();
            this.isLoading = false;
          })
          .catch(() => {
            this.handleError();
            this.isLoading = false;
          });
      },
      selectDefaultStage() {
        const stage = this.state.stages[0];
        this.selectStage(stage);
      },
      selectStage(stage) {
        if (this.isLoadingStage) return;
        if (this.currentStage === stage) return;

        if (!stage.isUserAllowed) {
          this.store.setActiveStage(stage);
          return;
        }

        this.isLoadingStage = true;
        this.store.setStageEvents([], stage);
        this.store.setActiveStage(stage);

        this.service
          .fetchStageData({
            stage,
            startDate: this.startDate,
          })
          .then(resp => resp.json())
          .then((response) => {
            this.isEmptyStage = !response.events.length;
            this.store.setStageEvents(response.events, stage);
            this.isLoadingStage = false;
          })
          .catch(() => {
            this.isLoadingStage = false;
            this.isEmptyStage = true;
          });
      },
      dismissOverviewDialog() {
        this.isOverviewDialogDismissed = true;
        Cookies.set(OVERVIEW_DIALOG_COOKIE, '1', { expires: 365 });
      },

    },
    created() {
      this.fetchCycleAnalyticsData();
    },
  };
</script>
<template>
<div :class="cssClass" id="cycle-analytics">
    <banner
      v-if="noData && !isOverviewDialogDismissed"
      @dimissBanner="dismissOverviewDialog"
      :help-path="helpPath"
      />
    <template v-if="!isLoading && !hasError">
      <pipeline-health
        :analytics-data="state"
        :start-date="startDate"
        @onClickDropdown="onClickDropdown"
        />

      <div class="panel panel-default stage-panel">
        <panel-header :current-state="currentStage" />

        <div class="stage-panel-body">
          <div class="nav stage-nav">
            <ul>
              <li
                class="stage-nav-item"
                v-for="(stage, i) in state.stages"
                :class="{ active: stage.active }"
                @click="selectStage(stage)">
                <div class="stage-nav-item-cell stage-name">
                  {{ stage.title }}
                </div>
                <div class="stage-nav-item-cell stage-median">
                  <template v-if="stage.isUserAllowed">
                    <span v-if="stage.value">
                      {{stage.value}}
                    </span>
                    <span
                      v-else
                      class="stage-empty">
                      {{__('Not enough data')}}
                      </span>
                  </template>
                  <template v-else>
                    <span class="not-available">
                      {{__('Not available')}}
                    </span>
                  </template>
                </div>
              </li>
            </ul>
          </div>
          <div class="section stage-events">
            <loading-icon
              v-if="isLoadingStage"
              :inline="true"
              />
            <div
              v-else-if="hasNoPermissions"
              class="no-access-stage">
              <div class="icon-lock" v-html="iconLock">
              </div>
              <h4>
                {{ __('You need permission.') }}
              </h4>
              <p>
                {{ __('Want to see the data? Please ask an administrator for access.') }}
              </p>
            </div>
            <template v-else>
              <div
                v-if="isEmptyStage && !isLoadingStage"
                class="empty-stage">
                <div class="icon-no-data" v-html="iconNoData"></div>
                <h4>
                  {{ __('We don\'t have enough data to show this stage.') }}
                </h4>
                <p>
                  {{currentStage.emptyStageText}}
                </p>
              </div>
              <template v-else>
                <component
                  :is="currentStage.component"
                  :stage="currentStage"
                  :items="state.events"
                  />
              </template>
            </template>
          </div>
        </div>
      </div>
    </template>
  </div>

</template>

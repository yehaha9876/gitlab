<script>
import DeleteFeatureFlag from './delete_feature_flag.vue';
import { GlButton, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
export default {
  components: {
    DeleteFeatureFlag,
    GlButton,
    GlLink,
    Icon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    csrfToken: {
      type: String,
      required: true,
    },
    featureFlags: {
      type: Array,
      required: true,
    },
  },
};
</script>
<template>
  <div class="table-holder">
    <div class="gl-responsive-table-row table-row-header" role="row">
      <div class="table-section section-10" role="columnheader">{{ s__('FeatureFlags|Status') }}</div>
      <div
        class="table-section section-50"
        role="columnheader"
      >{{ s__('FeatureFlags|Feature flag') }}</div>
    </div>

    <template v-for="(featureFlag, i) in featureFlags">
      <div class="gl-responsive-table-row" role="row" :key="`feature-flag-item-${i}`">
        <div class="table-section section-10" role="gridcell">
          <div class="table-mobile-header" role="rowheader">{{ s__('FeatureFlags|Status') }}</div>
          <div class="table-mobile-content">
            <template v-if="featureFlag.enabled">
              <span class="badge badge-success">{{ s__('FeatureFlags|Active') }}</span>
            </template>
            <template v-else>
              <span class="badge badge-danger">{{ s__('FeatureFlags|Inactive') }}</span>
            </template>
          </div>
        </div>

        <div class="table-section section-50" role="gridcell">
          <div class="table-mobile-header" role="rowheader">{{ s__('FeatureFlags|Feature Flag') }}</div>
          <div class="table-mobile-content d-flex flex-column">
            <div class="text-monospace text-truncate">{{ featureFlag.name }}</div>
            <div class="text-secondary text-truncate">{{ featureFlag.description }}</div>
          </div>
        </div>

        <div class="table-section section-40 table-button-footer" role="gridcell">
          <div class="table-action-buttons btn-group">
            <template v-if="featureFlag.editUrl">
              <gl-button
                :href="featureFlag.editUrl"
                variant="outline-primary"
                v-gl-tooltip.hover.bottom="__('Edit')"
              >
                <icon name="pencil" :size="16"/>
              </gl-button>
            </template>
            <template v-if="featureFlag.deleteUrl">
              <delete-feature-flag
                :delete-feature-flag-url="featureFlag.deleteUrl"
                :feature-flag-name="featureFlag.name"
                :modal-id="`delete-feature-flag-${i}`"
                :csrf-token="csrfToken"
              />
            </template>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>
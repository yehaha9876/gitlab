<script>
import { GlButton, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
export default {
  components: {
    GlButton,
    GlLink,
    Icon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    canDeleteFeatureFlag: {
      type: Boolean,
      required: true,
    },
    canUpdateFeatureFlag: {
      type: Boolean,
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
  <div class="table-holder border-top">
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
            <template v-if="canUpdateFeatureFlag">
              <gl-button
                :href="`feature_flags/${featureFlag.id}/edit`"
                variant="outline-primary"
                v-gl-tooltip.hover.bottom="__('Edit')"
              >
                <icon name="pencil" :size="16"/>
              </gl-button>
            </template>
            <template v-if="canDeleteFeatureFlag">
              <gl-button variant="danger" v-gl-tooltip.hover.bottom="__('Delete')">
                <icon name="remove" :size="16"/>
              </gl-button>
            </template>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>
<template>
  <div class="card instance-license-card instance-license-skeleton-card">
    <div class="card-header d-flex justify-content-between align-items-center py-3">
      <gl-skeleton-loading :lines="1" class="thick" />
    </div>

    <div class="card-body p-0">
      <div class="license-table">
        <div class="license-table-row d-flex">
          <cell class="license-table-header-cell">
            <gl-skeleton-loading :lines="1" slot="title" />
          </cell>
          <cell>
            <gl-skeleton-loading :lines="1" slot="title" />
            <gl-skeleton-loading :lines="1" slot="value" class="thick" />
          </cell>
          <cell>
            <gl-skeleton-loading :lines="1" slot="title" />
            <gl-skeleton-loading :lines="1" slot="value" class="thick" />
          </cell>
          <cell>
            <gl-skeleton-loading :lines="1" slot="title" />
            <gl-skeleton-loading :lines="1" slot="value" class="thick" />
          </cell>
          <cell>
            <gl-skeleton-loading :lines="1" slot="title" />
            <gl-skeleton-loading :lines="1" slot="value" class="thick" />
          </cell>
        </div>
        <div class="license-table-row d-flex">
          <cell class="license-table-header-cell">
            <gl-skeleton-loading :lines="1" slot="title" />
          </cell>
          <cell>
            <gl-skeleton-loading :lines="1" slot="title" />
            <gl-skeleton-loading :lines="1" slot="value" />
          </cell>
          <cell>
            <gl-skeleton-loading :lines="1" slot="title" />
            <gl-skeleton-loading :lines="1" slot="value" />
          </cell>
          <cell>
            <gl-skeleton-loading :lines="1" slot="title" />
            <gl-skeleton-loading :lines="1" slot="value" />
          </cell>
        </div>
        <div class="license-table-row d-flex">
          <cell class="license-table-header-cell">
            <gl-skeleton-loading :lines="1" slot="title" />
          </cell>
          <cell>
            <gl-skeleton-loading :lines="1" slot="title" />
            <gl-skeleton-loading :lines="1" slot="value" />
          </cell>
          <cell>
            <gl-skeleton-loading :lines="1" slot="title" />
            <gl-skeleton-loading :lines="1" slot="value" />
          </cell>
          <cell>
            <gl-skeleton-loading :lines="1" slot="title" />
            <gl-skeleton-loading :lines="1" slot="value" />
          </cell>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { GlSkeletonLoading } from '@gitlab/ui';
import Cell from './instance_licenses_table/cell.vue';

export default {
  name: 'InstanceLicenseSkeletonCard',
  components: {
    GlSkeletonLoading,
    Cell,
  },
};
</script>

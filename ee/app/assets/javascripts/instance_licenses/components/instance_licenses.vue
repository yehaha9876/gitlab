<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import createFlash from '~/flash';
import InstanceLicenseCard from './instance_license_card.vue';
import InstanceLicenseSkeletonCard from './instance_license_skeleton_card.vue';
import licenses from '../queries/licenses.graphql';

const DEFAULT_LICENSES_COUNT = 5;
const DEFAULT_CURSOR = '';

export default {
  name: 'InstanceLicenses',
  apollo: {
    licenses: {
      query: licenses,
      variables: {
        first: DEFAULT_LICENSES_COUNT,
        after: DEFAULT_CURSOR,
      },
    },
  },
  data() {
    return {
      licenses: { edges: [], pageInfo: {} },
    };
  },
  components: {
    InstanceLicenseCard,
    InstanceLicenseSkeletonCard,
    GlButton,
  },
  computed: {
    licensesCollection() {
      return this.licenses.edges.map(({ node }) => node);
    },
    after() {
      return this.licenses.pageInfo.endCursor || '';
    },
    hasNextPage() {
      return this.licenses.pageInfo.hasNextPage;
    },
  },
  methods: {
    loadMoreLicenses() {
      this.$apollo.queries.licenses
        .fetchMore({
          variables: {
            after: this.after,
          },
          updateQuery(previousResult, { fetchMoreResult }) {
            return {
              licenses: {
                __typename: previousResult.licenses.__typename,
                edges: [...previousResult.licenses.edges, ...fetchMoreResult.licenses.edges],
                pageInfo: fetchMoreResult.licenses.pageInfo,
              },
            };
          },
        })
        .catch(() => createFlash(__('An error occurred while loading more licenses')));
    },

    loadMoreOnScrollEnd() {
      if (!this.hasNextPage || this.$apollo.queries.licenses.loading) return;

      const element = document.scrollingElement;

      if (element.scrollHeight - element.scrollTop === element.clientHeight)
        this.loadMoreLicenses();
    },
  },
  mounted() {
    document.addEventListener('scroll', () => this.loadMoreOnScrollEnd());
  },
};
</script>

<template>
  <div>
    <div class="d-flex justify-content-between align-items-center">
      <h4>{{ __('Instance license') }}</h4>
      <gl-button class="my-3" variant="success">{{ __('Add license') }}</gl-button>
    </div>

    <div class="license-list" id="license-list">
      <ul class="list-unstyled">
        <li v-for="license in licensesCollection" :key="license.id">
          <instance-license-card :license="license" />
        </li>
        <li v-if="$apollo.queries.licenses.loading"><instance-license-skeleton-card /></li>
      </ul>
    </div>
  </div>
</template>

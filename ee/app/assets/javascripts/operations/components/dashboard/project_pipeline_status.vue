<script>
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import Tooltip from '~/vue_shared/directives/tooltip';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { sprintf } from '~/locale';

export default {
  components: {
    CiIcon,
  },
  directives: {
    Tooltip,
  },
  props: {
    status: {
      type: Object,
      required: true,
    },
    relation: {
      type: String,
      required: true,
    },
  },
  computed: {
    statusTitle() {
      const status = capitalizeFirstCharacter(this.status.group);
      return sprintf(
        '<span class="bold">%{relation}</span><br/><span>%{status}</span><br/><span class="text-tertiary">%{name}</span>',
        {
          relation: this.relation,
          status,
          name: this.status.name_with_namespace || '',
        },
      );
    },
  },
};
</script>

<template>
  <a
    v-tooltip
    :href="status.details_path"
    :title="statusTitle"
    data-html="true"
    class="ops-dashboard-project-pipeline-icon"
  >
    <ci-icon :status="status" />
  </a>
</template>

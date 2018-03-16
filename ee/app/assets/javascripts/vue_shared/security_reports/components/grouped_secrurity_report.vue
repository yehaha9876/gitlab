<script>
  import { mapGetters, mapState } from 'vuex';
  import LoadingRow from './loading_row.vue';
  import ErrorRow from './error_row.vue';


  export default {
    name: 'GroupedSecurityReport',

  };
</script>
<template>
  <div slot="body">
    <template v-if="hasSast">

    </template>

    <template v-if="hasSastContainer">

    </template>

    <template v-if="hasDast"></template>
  </div>
</template>

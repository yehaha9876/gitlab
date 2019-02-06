<script>
export default {};
</script>
<template>
  <div class="row">
    <div v-for="index in 3" :key="index" class="col-12 col-md-4">
      <div class="ops-dashboard-project card">
        <div class="ops-dashboard-project-header card-header"></div>
        <div class="card-body">
          <div class="row">
            <div class="col-1 align-self-center">
              <div class="ops-dashboard-project-skeleton-avatar p-3 rounded-circle"></div>
            </div>

            <div class="col-6 align-self-center ops-dashboard-project-commit pl-4">
              <div class="ops-dashboard-project-skeleton-info py-2 w-100 mb-2"></div>
              <div class="ops-dashboard-project-skeleton-info py-2 w-100"></div>
            </div>

            <div class="col-5 align-self-center">
              <div class="ops-dashboard-project-skeleton-info py-2 w-100"></div>
            </div>
          </div>

          <div class="ops-dashboard-project-pipeline py-3 mt-3"></div>
        </div>
      </div>
    </div>
  </div>
</template>

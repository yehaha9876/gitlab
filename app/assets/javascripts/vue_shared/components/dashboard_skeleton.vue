<script>
export default {};
</script>
<template>
  <div class="row ops-dashboard-projects">
    <div
      v-for="index in 3"
      :key="index"
      class="col-12 col-md-6 col-xl-4 ops-dashboard-projects-card"
    >
      <div class="ops-dashboard-project card">
        <div class="ops-dashboard-project-header card-header py-4 bg-light"></div>
        <div class="ops-dashboard-project-card card-body bg-secondary">
          <div class="row">
            <div class="col-1 align-self-center">
              <div class="bg-light p-3 rounded-circle"></div>
            </div>

            <div class="col-10 col-sm-6 align-self-center ops-dashboard-project-commit pl-4">
              <div class="ops-dashboard-project-skeleton-info bg-light py-2 w-100 mb-2"></div>
              <div class="ops-dashboard-project-skeleton-info bg-light py-2 w-100"></div>
            </div>

            <div class="col-sm-5 align-self-center d-none d-sm-block">
              <div class="ops-dashboard-project-skeleton-info bg-light py-2 w-100"></div>
            </div>
          </div>

          <div class="ops-dashboard-project-pipeline bg-light py-3 mt-3"></div>
        </div>
      </div>
    </div>
  </div>
</template>

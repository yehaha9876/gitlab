<template>
  <div class="alert-form">
    <div
      class="form-group btn-group"
      role="group"
      aria-label="Operator"
    >
      <button
        type="button"
        class="btn btn-default active"
      >
        &gt;
      </button>
      <button
        type="button"
        class="btn btn-default"
      >
        =
      </button>
      <button
        type="button"
        class="btn btn-default"
      >
        &lt;
      </button>
    </div>
    <div class="form-group">
      <label>Threshold</label>
      <input
        type="text"
        class="form-control"
      />
    </div>
    <div class="action-group">
      <button
        type="button"
        class="btn btn-default"
      >
        Cancel
      </button>
      <button
        type="button"
        class="btn btn-inverted btn-new"
      >
        Save
      </button>
    </div>
  </div>
</template>

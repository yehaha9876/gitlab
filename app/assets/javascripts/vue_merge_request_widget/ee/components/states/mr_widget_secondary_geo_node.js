export default {
  template: `
    <div>
      <button type="button" class="btn btn-success btn-small" disabled="true">Merge</button>
      <span class="bold">
        Merge requests are read-only in a secondary Geo node.
      </span>
      <a title data-title='About this feature' data-toggle='tooltip' data-placement='bottom' data-container='body' href='/help/gitlab-geo/configuration.md'>
        <i class='fa fa-question-circle'></i>
      </a>
    </div>
  `,
};

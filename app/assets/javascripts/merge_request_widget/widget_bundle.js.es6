/* global Vue */
//= require ./widget_store
//= require ./approvals/approvals_bundle

(() => {
  $(() => {
    let widgetSharedStore;

    gl.compileApprovalsWidget = () => {
      const rootEl = document.getElementById('merge-request-widget-app');

      if (gl.MergeRequestWidgetApp) {
        gl.MergeRequestWidgetApp.$destroy();
      } else {
        widgetSharedStore = new gl.MergeRequestWidgetStore(rootEl);
      }

      gl.MergeRequestWidgetApp = new Vue({
        el: rootEl,
        data: widgetSharedStore.data,
      });
    };

    gl.compileApprovalsWidget();
  });
})(window.gl || (window.gl = {}));

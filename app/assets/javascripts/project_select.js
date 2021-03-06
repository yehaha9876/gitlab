/* eslint-disable func-names, space-before-function-paren, wrap-iife, prefer-arrow-callback, no-var, comma-dangle, object-shorthand, one-var, one-var-declaration-per-line, no-else-return, quotes, max-len */
import Api from './api';
import ProjectSelectComboButton from './project_select_combo_button';

(function () {
  this.ProjectSelect = (function () {
    function ProjectSelect() {
      $('.ajax-project-select').each(function(i, select) {
        var placeholder;
        this.groupId = $(select).data('group-id');
        this.includeGroups = $(select).data('include-groups');
        this.allProjects = $(select).data('allprojects') || false;
        this.orderBy = $(select).data('order-by') || 'id';
        this.withIssuesEnabled = $(select).data('with-issues-enabled');
        this.withMergeRequestsEnabled = $(select).data('with-merge-requests-enabled');

        placeholder = "Search for project";
        if (this.includeGroups) {
          placeholder += " or group";
        }

        $(select).select2({
          placeholder: placeholder,
          minimumInputLength: 0,
          query: (function (_this) {
            return function (query) {
              var finalCallback, projectsCallback;
              finalCallback = function (projects) {
                var data;
                data = {
                  results: projects
                };
                return query.callback(data);
              };
              if (_this.includeGroups) {
                projectsCallback = function (projects) {
                  var groupsCallback;
                  groupsCallback = function (groups) {
                    var data;
                    data = groups.concat(projects);
                    return finalCallback(data);
                  };
                  return Api.groups(query.term, {}, groupsCallback);
                };
              } else {
                projectsCallback = finalCallback;
              }
              if (_this.groupId) {
                return Api.groupProjects(_this.groupId, query.term, projectsCallback);
              } else {
                return Api.projects(query.term, {
                  order_by: _this.orderBy,
                  with_issues_enabled: _this.withIssuesEnabled,
                  with_merge_requests_enabled: _this.withMergeRequestsEnabled,
                  membership: !_this.allProjects
                }, projectsCallback);
              }
            };
          })(this),
          id: function(project) {
            return JSON.stringify({
              name: project.name,
              url: project.web_url,
            });
          },
          text: function (project) {
            return project.name_with_namespace || project.name;
          },
          dropdownCssClass: "ajax-project-dropdown"
        });

        return new ProjectSelectComboButton(select);
      });
    }

    return ProjectSelect;
  })();
}).call(window);

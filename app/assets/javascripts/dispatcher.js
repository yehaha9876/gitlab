/* eslint-disable func-names, space-before-function-paren, no-var, prefer-arrow-callback, wrap-iife, no-shadow, consistent-return, one-var, one-var-declaration-per-line, camelcase, default-case, no-new, quotes, no-duplicate-case, no-case-declarations, no-fallthrough, max-len */
import { s__ } from './locale';
/* global ProjectSelect */
import IssuableIndex from './issuable_index';
/* global Milestone */
import IssuableForm from './issuable_form';
import LabelsSelect from './labels_select';
/* global MilestoneSelect */
/* global NewBranchForm */
/* global NotificationsForm */
/* global NotificationsDropdown */
import groupAvatar from './group_avatar';
import GroupLabelSubscription from './group_label_subscription';
/* global LineHighlighter */
import BuildArtifacts from './build_artifacts';
import CILintEditor from './ci_lint_editor';
import groupsSelect from './groups_select';
/* global Search */
/* global Admin */
import NamespaceSelect from './namespace_select';
/* global NewCommitForm */
/* global NewBranchForm */
/* global Project */
/* global ProjectAvatar */
/* global MergeRequest */
/* global Compare */
/* global CompareAutocomplete */
/* global PathLocks */
/* global ProjectFindFile */
/* global ProjectNew */
/* global ProjectShow */
/* global ProjectImport */
import Labels from './labels';
import LabelManager from './label_manager';
/* global Sidebar */
/* global WeightSelect */
/* global AdminEmailSelect */

import Flash from './flash';
import CommitsList from './commits';
import Issue from './issue';
import BindInOut from './behaviors/bind_in_out';
import DeleteModal from './branches/branches_delete_modal';
import Group from './group';
import GroupsList from './groups_list';
import ProjectsList from './projects_list';
import setupProjectEdit from './project_edit';
import MiniPipelineGraph from './mini_pipeline_graph_dropdown';
import BlobLinePermalinkUpdater from './blob/blob_line_permalink_updater';
import Landing from './landing';
import BlobForkSuggestion from './blob/blob_fork_suggestion';
import UserCallout from './user_callout';
import ShortcutsWiki from './shortcuts_wiki';
import Pipelines from './pipelines';
import BlobViewer from './blob/viewer/index';
import GeoNodes from './geo_nodes';
import AutoWidthDropdownSelect from './issuable/auto_width_dropdown_select';
import UsersSelect from './users_select';
import RefSelectDropdown from './ref_select_dropdown';
import GfmAutoComplete from './gfm_auto_complete';
import ShortcutsBlob from './shortcuts_blob';
import SigninTabsMemoizer from './signin_tabs_memoizer';
import Star from './star';
import Todos from './todos';
import TreeView from './tree';
import UsagePing from './usage_ping';
import UsernameValidator from './username_validator';
import VersionCheckImage from './version_check_image';
import Wikis from './wikis';
import ZenMode from './zen_mode';
import initSettingsPanels from './settings_panels';
import initExperimentalFlags from './experimental_flags';
import OAuthRememberMe from './oauth_remember_me';
import PerformanceBar from './performance_bar';
import initBroadcastMessagesForm from './broadcast_message';
import initNotes from './init_notes';
import initLegacyFilters from './init_legacy_filters';
import initIssuableSidebar from './init_issuable_sidebar';
import initProjectVisibilitySelector from './project_visibility';
import GpgBadges from './gpg_badges';
import UserFeatureHelper from './helpers/user_feature_helper';
import initChangesDropdown from './init_changes_dropdown';
import NewGroupChild from './groups/new_group_child';
import AbuseReports from './abuse_reports';
import { ajaxGet, convertPermissionToBoolean } from './lib/utils/common_utils';
import AjaxLoadingSpinner from './ajax_loading_spinner';
import GlFieldErrors from './gl_field_errors';
import GLForm from './gl_form';
import Shortcuts from './shortcuts';
import ShortcutsNavigation from './shortcuts_navigation';
import ShortcutsFindFile from './shortcuts_find_file';
import ShortcutsIssuable from './shortcuts_issuable';
import U2FAuthenticate from './u2f/authenticate';
import Members from './members';
import memberExpirationDate from './member_expiration_date';
import DueDateSelectors from './due_date_select';
import Diff from './diff';

// EE-only
import ApproversSelect from './approvers_select';
import AuditLogs from './audit_logs';
import initGeoInfoModal from './init_geo_info_modal';
import initGroupAnalytics from './init_group_analytics';

(function() {
  var Dispatcher;

  Dispatcher = (function() {
    function Dispatcher() {
      this.initSearch();
      this.initFieldErrors();
      this.initPageScripts();
    }

    Dispatcher.prototype.initPageScripts = function() {
      var path, shortcut_handler, fileBlobPermalinkUrlElement, fileBlobPermalinkUrl;
      const page = $('body').attr('data-page');
      if (!page) {
        return false;
      }

      path = page.split(':');
      shortcut_handler = null;

      $('.js-gfm-input:not(.js-vue-textarea)').each((i, el) => {
        const gfm = new GfmAutoComplete(gl.GfmAutoComplete && gl.GfmAutoComplete.dataSources);
        const enableGFM = convertPermissionToBoolean(el.dataset.supportsAutocomplete);
        gfm.setup($(el), {
          emojis: true,
          members: enableGFM,
          issues: enableGFM,
          milestones: enableGFM,
          mergeRequests: enableGFM,
          labels: enableGFM,
        });
      });

      function initBlobEE() {
        const dataEl = document.getElementById('js-file-lock');

        if (dataEl) {
          const {
            toggle_path,
            path,
           } = JSON.parse(dataEl.innerHTML);

          PathLocks.init(toggle_path, path);
        }
      }

      function initBlob() {
        new LineHighlighter();

        new BlobLinePermalinkUpdater(
          document.querySelector('#blob-content-holder'),
          '.diff-line-num[data-line-number]',
          document.querySelectorAll('.js-data-file-blob-permalink-url, .js-blob-blame-link'),
        );

        shortcut_handler = new ShortcutsNavigation();
        fileBlobPermalinkUrlElement = document.querySelector('.js-data-file-blob-permalink-url');
        fileBlobPermalinkUrl = fileBlobPermalinkUrlElement && fileBlobPermalinkUrlElement.getAttribute('href');
        new ShortcutsBlob({
          skipResetBindings: true,
          fileBlobPermalinkUrl,
        });

        new BlobForkSuggestion({
          openButtons: document.querySelectorAll('.js-edit-blob-link-fork-toggler'),
          forkButtons: document.querySelectorAll('.js-fork-suggestion-button'),
          cancelButtons: document.querySelectorAll('.js-cancel-fork-suggestion-button'),
          suggestionSections: document.querySelectorAll('.js-file-fork-suggestion-section'),
          actionTextPieces: document.querySelectorAll('.js-file-fork-suggestion-section-action'),
        })
          .init();

        initBlobEE();
      }

      const filteredSearchEnabled = gl.FilteredSearchManager && document.querySelector('.filtered-search');

      switch (page) {
        case 'profiles:preferences:show':
          initExperimentalFlags();
          break;
        case 'sessions:new':
          new UsernameValidator();
          new SigninTabsMemoizer();
          new OAuthRememberMe({ container: $(".omniauth-container") }).bindEvents();
          break;
        case 'projects:boards:show':
        case 'projects:boards:index':
          shortcut_handler = new ShortcutsNavigation();
          new UsersSelect();
          break;
        case 'projects:merge_requests:index':
        case 'projects:issues:index':
          if (filteredSearchEnabled) {
            const filteredSearchManager = new gl.FilteredSearchManager(page === 'projects:issues:index' ? 'issues' : 'merge_requests');
            filteredSearchManager.setup();
          }
          const pagePrefix = page === 'projects:merge_requests:index' ? 'merge_request_' : 'issue_';
          new IssuableIndex(pagePrefix);

          shortcut_handler = new ShortcutsNavigation();
          new UsersSelect();
          break;
        case 'projects:issues:show':
          new Issue();
          shortcut_handler = new ShortcutsIssuable();
          new ZenMode();
          initIssuableSidebar();
          break;
        case 'dashboard:milestones:index':
          new ProjectSelect();
          break;
        case 'projects:milestones:show':
          new UserCallout();
        case 'groups:milestones:show':
        case 'dashboard:milestones:show':
          new Milestone();
          new Sidebar();
          break;
        case 'dashboard:issues':
        case 'dashboard:merge_requests':
          new ProjectSelect();
          initLegacyFilters();
          break;
        case 'groups:issues':
        case 'groups:merge_requests':
          if (filteredSearchEnabled) {
            const filteredSearchManager = new gl.FilteredSearchManager(page === 'groups:issues' ? 'issues' : 'merge_requests');
            filteredSearchManager.setup();
          }
          new ProjectSelect();
          break;
        case 'dashboard:todos:index':
          new Todos();
          break;
        case 'dashboard:projects:index':
        case 'dashboard:projects:starred':
        case 'explore:projects:index':
        case 'explore:projects:trending':
        case 'explore:projects:starred':
        case 'admin:projects:index':
          new ProjectsList();
          break;
        case 'explore:groups:index':
          new GroupsList();
          const landingElement = document.querySelector('.js-explore-groups-landing');
          if (!landingElement) break;
          const exploreGroupsLanding = new Landing(
            landingElement,
            landingElement.querySelector('.dismiss-button'),
            'explore_groups_landing_dismissed',
          );
          exploreGroupsLanding.toggle();
          break;
        case 'projects:milestones:new':
        case 'projects:milestones:edit':
        case 'projects:milestones:update':
          new ZenMode();
          new DueDateSelectors();
          new GLForm($('.milestone-form'), true);
          break;
        case 'groups:milestones:new':
        case 'groups:milestones:edit':
        case 'groups:milestones:update':
          new ZenMode();
          new DueDateSelectors();
          new GLForm($('.milestone-form'), false);
          break;
        case 'projects:compare:show':
          new Diff();
          const paddingTop = 16;
          initChangesDropdown(document.querySelector('.navbar-gitlab').offsetHeight - paddingTop);
          break;
        case 'projects:branches:new':
        case 'projects:branches:create':
          new NewBranchForm($('.js-create-branch-form'), JSON.parse(document.getElementById('availableRefs').innerHTML));
          break;
        case 'projects:branches:index':
          AjaxLoadingSpinner.init();
          new DeleteModal();
          break;
        case 'projects:issues:new':
        case 'projects:issues:edit':
          shortcut_handler = new ShortcutsNavigation();
          new GLForm($('.issue-form'), true);
          new IssuableForm($('.issue-form'));
          new LabelsSelect();
          new MilestoneSelect();
          new WeightSelect();
          new gl.IssuableTemplateSelectors();
          break;
        case 'projects:merge_requests:creations:new':
          const mrNewCompareNode = document.querySelector('.js-merge-request-new-compare');
          if (mrNewCompareNode) {
            new Compare({
              targetProjectUrl: mrNewCompareNode.dataset.targetProjectUrl,
              sourceBranchUrl: mrNewCompareNode.dataset.sourceBranchUrl,
              targetBranchUrl: mrNewCompareNode.dataset.targetBranchUrl,
            });
          } else {
            const mrNewSubmitNode = document.querySelector('.js-merge-request-new-submit');
            new MergeRequest({
              action: mrNewSubmitNode.dataset.mrSubmitAction,
            });
          }
          new UserCallout();
        case 'projects:merge_requests:creations:diffs':
        case 'projects:merge_requests:edit':
          new Diff();
          shortcut_handler = new ShortcutsNavigation();
          new GLForm($('.merge-request-form'), true);
          new IssuableForm($('.merge-request-form'));
          new LabelsSelect();
          new MilestoneSelect();
          new gl.IssuableTemplateSelectors();
          new AutoWidthDropdownSelect($('.js-target-branch-select')).init();
          break;
        case 'projects:tags:new':
          new ZenMode();
          new GLForm($('.tag-form'), true);
          new RefSelectDropdown($('.js-branch-select'));
          break;
        case 'projects:snippets:show':
          initNotes();
          break;
        case 'projects:snippets:new':
        case 'projects:snippets:edit':
        case 'projects:snippets:create':
        case 'projects:snippets:update':
          new GLForm($('.snippet-form'), true);
          break;
        case 'snippets:new':
        case 'snippets:edit':
        case 'snippets:create':
        case 'snippets:update':
          new GLForm($('.snippet-form'), false);
          break;
        case 'projects:releases:edit':
          new ZenMode();
          new GLForm($('.release-form'), true);
          break;
        case 'projects:merge_requests:show':
          new Diff();
          shortcut_handler = new ShortcutsIssuable(true);
          new ZenMode();

          initIssuableSidebar();
          initNotes();

          const mrShowNode = document.querySelector('.merge-request');
          window.mergeRequest = new MergeRequest({
            action: mrShowNode.dataset.mrAction,
          });
          break;
        case 'dashboard:activity':
          new gl.Activities();
          break;
        case 'projects:commit:show':
          new Diff();
          new ZenMode();
          shortcut_handler = new ShortcutsNavigation();
          new MiniPipelineGraph({
            container: '.js-commit-pipeline-graph',
          }).bindEvents();
          initNotes();
          initChangesDropdown();
          $('.commit-info.branches').load(document.querySelector('.js-commit-box').dataset.commitPath);
          break;
        case 'projects:commit:pipelines':
          new MiniPipelineGraph({
            container: '.js-commit-pipeline-graph',
          }).bindEvents();
          $('.commit-info.branches').load(document.querySelector('.js-commit-box').dataset.commitPath);
          break;
        case 'projects:activity':
          new gl.Activities();
          shortcut_handler = new ShortcutsNavigation();
          break;
        case 'projects:commits:show':
          CommitsList.init(document.querySelector('.js-project-commits-show').dataset.commitsLimit);
          shortcut_handler = new ShortcutsNavigation();
          GpgBadges.fetch();
          break;
        case 'projects:imports:show':
          new ProjectImport();
          break;
        case 'projects:show':
          shortcut_handler = new ShortcutsNavigation();
          new NotificationsForm();
          new UserCallout({
            setCalloutPerProject: true,
            className: 'js-autodevops-banner',
          });

          if ($('#tree-slider').length) new TreeView();
          if ($('.blob-viewer').length) new BlobViewer();
          if ($('.project-show-activity').length) new gl.Activities();

          $('#tree-slider').waitForImages(function() {
            ajaxGet(document.querySelector('.js-tree-content').dataset.logsPath);
          });

          initGeoInfoModal();
          break;
        case 'projects:edit':
          new UsersSelect();
          groupsSelect();
          setupProjectEdit();
          // Initialize expandable settings panels
          initSettingsPanels();
          new UserCallout({ className: 'js-service-desk-callout' });
          new UserCallout({ className: 'js-mr-approval-callout' });
          break;
        case 'projects:imports:show':
          new ProjectImport();
          break;
        case 'projects:pipelines:new':
          new NewBranchForm($('.js-new-pipeline-form'));
          break;
        case 'projects:pipelines:builds':
        case 'projects:pipelines:failures':
        case 'projects:pipelines:show':
          const { controllerAction } = document.querySelector('.js-pipeline-container').dataset;
          const pipelineStatusUrl = `${document.querySelector('.js-pipeline-tab-link a').getAttribute('href')}/status.json`;

          new Pipelines({
            initTabs: true,
            pipelineStatusUrl,
            tabsOptions: {
              action: controllerAction,
              defaultAction: 'pipelines',
              parentEl: '.pipelines-tabs',
            },
          });
          break;
        case 'groups:activity':
          new gl.Activities();
          break;
        case 'groups:show':
          const newGroupChildWrapper = document.querySelector('.js-new-project-subgroup');
          shortcut_handler = new ShortcutsNavigation();
          new NotificationsForm();
          new NotificationsDropdown();
          new ProjectsList();

          if (newGroupChildWrapper) {
            new NewGroupChild(newGroupChildWrapper);
          }
          break;
        case 'groups:group_members:index':
          memberExpirationDate();
          new Members();
          new UsersSelect();
          break;
        case 'projects:project_members:index':
          memberExpirationDate('.js-access-expiration-date-groups');
          groupsSelect();
          memberExpirationDate();
          new Members();
          new UsersSelect();
          break;
        case 'groups:new':
        case 'admin:groups:new':
        case 'groups:create':
        case 'admin:groups:create':
          BindInOut.initAll();
          new Group();
          groupAvatar();
          break;
        case 'groups:edit':
        case 'admin:groups:edit':
          groupAvatar();
          break;
        case 'projects:tree:show':
          shortcut_handler = new ShortcutsNavigation();

          if (UserFeatureHelper.isNewRepoEnabled()) break;

          new TreeView();
          new BlobViewer();
          new NewCommitForm($('.js-create-dir-form'));

          if (document.querySelector('.js-tree-content').dataset.pathLocksAvailable === 'true') {
            PathLocks.init(
              document.querySelector('.js-tree-content').dataset.pathLocksToggle,
              document.querySelector('.js-tree-content').dataset.pathLocksPath,
            );
          }

          $('#tree-slider').waitForImages(function() {
            ajaxGet(document.querySelector('.js-tree-content').dataset.logsPath);
          });
          break;
        case 'projects:find_file:show':
          const findElement = document.querySelector('.js-file-finder');
          const projectFindFile = new ProjectFindFile($(".file-finder-holder"), {
            url: findElement.dataset.fileFindUrl,
            treeUrl: findElement.dataset.findTreeUrl,
            blobUrlTemplate: findElement.dataset.blobUrlTemplate,
          });
          new ShortcutsFindFile(projectFindFile);
          shortcut_handler = true;
          break;
        case 'projects:blob:show':
          if (UserFeatureHelper.isNewRepoEnabled()) break;
          new BlobViewer();
          initBlob();
          break;
        case 'projects:blame:show':
          initBlob();
          break;
        case 'groups:labels:new':
        case 'groups:labels:edit':
        case 'projects:labels:new':
        case 'projects:labels:edit':
          new Labels();
          break;
        case 'groups:labels:index':
        case 'projects:labels:index':
          if ($('.prioritized-labels').length) {
            new LabelManager();
          }
          $('.label-subscription').each((i, el) => {
            const $el = $(el);

            if ($el.find('.dropdown-group-label').length) {
              new GroupLabelSubscription($el);
            } else {
              new gl.ProjectLabelSubscription($el);
            }
          });
          break;
        case 'projects:network:show':
          // Ensure we don't create a particular shortcut handler here. This is
          // already created, where the network graph is created.
          shortcut_handler = true;
          break;
        case 'projects:forks:new':
          import(/* webpackChunkName: 'project_fork' */ './project_fork')
            .then(fork => fork.default())
            .catch(() => {});
          break;
        case 'projects:artifacts:browse':
          new ShortcutsNavigation();
          new BuildArtifacts();
          break;
        case 'projects:artifacts:file':
          new ShortcutsNavigation();
          new BlobViewer();
          break;
        case 'help:index':
          VersionCheckImage.bindErrorEvent($('img.js-version-status-badge'));
          break;
        case 'search:show':
          new Search();
          new UserCallout();
          break;
        case 'projects:mirrors:show':
        case 'projects:mirrors:update':
          new UsersSelect();
          break;
        case 'admin:emails:show':
          new AdminEmailSelect();
          break;
        case 'admin:audit_logs:index':
          new AuditLogs();
          break;
        case 'projects:settings:repository:show':
          new UsersSelect();
          new UserCallout();
          // Initialize expandable settings panels
          initSettingsPanels();
          break;
        case 'projects:settings:ci_cd:show':
          // Initialize expandable settings panels
          initSettingsPanels();
        case 'groups:settings:ci_cd:show':
          new gl.ProjectVariables();
          break;
        case 'ci:lints:create':
        case 'ci:lints:show':
          new CILintEditor();
          break;
        case 'users:show':
          new UserCallout();
          break;
        case 'admin:conversational_development_index:show':
          new UserCallout();
          break;
        case 'snippets:show':
          new LineHighlighter();
          new BlobViewer();
          initNotes();
          break;
        case 'import:fogbugz:new_user_map':
          new UsersSelect();
          break;
        case 'profiles:personal_access_tokens:index':
        case 'admin:impersonation_tokens:index':
          new DueDateSelectors();
          break;
        case 'projects:clusters:show':
          import(/* webpackChunkName: "clusters" */ './clusters/clusters_bundle')
            .then(cluster => new cluster.default()) // eslint-disable-line new-cap
            .catch((err) => {
              Flash(s__('ClusterIntegration|Problem setting up the cluster JavaScript'));
              throw err;
            });
          break;
        case 'admin:licenses:new':
          const $licenseFile = $('.license-file');
          const $licenseKey = $('.license-key');

          const showLicenseType = () => {
            const $checkedFile = $('input[name="license_type"]:checked').val() === 'file';

            $licenseFile.toggle($checkedFile);
            $licenseKey.toggle(!$checkedFile);
          };

          $('input[name="license_type"]').on('change', showLicenseType);
          showLicenseType();
          break;
        case 'groups:analytics:show':
          initGroupAnalytics();
          break;
      }
      switch (path[0]) {
        case 'sessions':
        case 'omniauth_callbacks':
          if (!gon.u2f) break;
          const u2fAuthenticate = new U2FAuthenticate(
            $('#js-authenticate-u2f'),
            '#js-login-u2f-form',
            gon.u2f,
            document.querySelector('#js-login-2fa-device'),
            document.querySelector('.js-2fa-form'),
          );
          u2fAuthenticate.start();
          // needed in rspec
          gl.u2fAuthenticate = u2fAuthenticate;
        case 'admin':
          new Admin();
          switch (path[1]) {
            case 'broadcast_messages':
              initBroadcastMessagesForm();
              break;
            case 'cohorts':
              new UsagePing();
              break;
            case 'groups':
              new UsersSelect();
              break;
            case 'projects':
              document.querySelectorAll('.js-namespace-select')
                .forEach(dropdown => new NamespaceSelect({ dropdown }));
              break;
            case 'labels':
              switch (path[2]) {
                case 'new':
                case 'edit':
                  new Labels();
              }
            case 'abuse_reports':
              new AbuseReports();
              break;
            case 'geo_nodes':
              new GeoNodes($('.geo-nodes'));
              import(/* webpackChunkName: 'geo_node_form' */ './geo/geo_node_form')
                .then(geoNodeForm => geoNodeForm.default($('.js-geo-node-form')))
                .catch(() => {});
              break;
          }
          break;
        case 'dashboard':
        case 'root':
          new UserCallout();
          break;
        case 'profiles':
          new NotificationsForm();
          new NotificationsDropdown();
          break;
        case 'projects':
          new Project();
          new ProjectAvatar();
          switch (path[1]) {
            case 'compare':
              new CompareAutocomplete();
              break;
            case 'edit':
              shortcut_handler = new ShortcutsNavigation();
              new ProjectNew();
              new ApproversSelect();
              import(/* webpackChunkName: 'project_permissions' */ './projects/permissions')
                .then(permissions => permissions.default())
                .catch(() => {});
              break;
            case 'new':
              new ProjectNew();
              initProjectVisibilitySelector();
              break;
            case 'show':
              new Star();
              new ProjectNew();
              new ProjectShow();
              new NotificationsDropdown();
              break;
            case 'wikis':
              new Wikis();
              shortcut_handler = new ShortcutsWiki();
              new ZenMode();
              new GLForm($('.wiki-form'), true);
              break;
            case 'snippets':
              shortcut_handler = new ShortcutsNavigation();
              if (path[2] === 'show') {
                new ZenMode();
                new LineHighlighter();
                new BlobViewer();
              }
              break;
            case 'labels':
            case 'graphs':
            case 'compare':
            case 'pipelines':
            case 'forks':
            case 'milestones':
            case 'project_members':
            case 'deploy_keys':
            case 'builds':
            case 'hooks':
            case 'services':
            case 'repository':
              shortcut_handler = new ShortcutsNavigation();
          }
          break;
      }
      // If we haven't installed a custom shortcut handler, install the default one
      if (!shortcut_handler) {
        new Shortcuts();
      }

      if (document.querySelector('#peek')) {
        new PerformanceBar({ container: '#peek' });
      }
    };

    Dispatcher.prototype.initSearch = function() {
      // Only when search form is present
      if ($('.search').length) {
        return new gl.SearchAutocomplete();
      }
    };

    Dispatcher.prototype.initFieldErrors = function() {
      $('.gl-show-field-errors').each((i, form) => {
        new GlFieldErrors(form);
      });
    };

    return Dispatcher;
  })();

  $(window).on('load', function() {
    new Dispatcher();
  });
}).call(window);

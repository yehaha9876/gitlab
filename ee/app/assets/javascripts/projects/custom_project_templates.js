import $ from 'jquery';
import projectNew from '~/projects/project_new';

const bindEvents = () => {
  const $newProjectForm = $('#new_project');
  const $useCustomTemplateBtn = $('.custom-template-button > input');
  const $projectFieldsForm = $('.project-fields-form');
  const $selectedIcon = $('.selected-icon');
  const $selectedTemplateText = $('.selected-template');
  const $templateProjectNameInput = $('#template-project-name #project_path');
  const $changeTemplateBtn = $('.change-template');
  const $projectTemplateButtons = $('.project-templates-buttons');
  const $projectFieldsFormInput = $('.project-fields-form input#project_use_custom_template');
  const $subgroupWithTemplatesIdInput = $('.project-fields-form input#project_group_with_project_templates_id');
  const $namespace_select = $projectFieldsForm.find('select#project_namespace_id');

  if ($newProjectForm.length !== 1 || $useCustomTemplateBtn.length === 0) {
    return;
  }

  function enableCustomTemplate() {
    $projectFieldsFormInput.val(true);
  }

  function disableCustomTemplate() {
    $projectFieldsFormInput.val(false);
  }

  function chooseTemplate() {
    const value = $(this).val();
    const subgroupId = $(this).data('subgroup-id');

    if (subgroupId) {
      $subgroupWithTemplatesIdInput.val(subgroupId);
      $namespace_select.val(subgroupId).trigger('change');
      var path = `/${$namespace_select.find('option:selected').data('show-path').split('/')[1]}`

      // Hiding alloptions whose path doesn't match the top parent one
      $namespace_select.find('option').filter(function(){
        var current_path = $(this).data('show-path');
        return current_path != path && !current_path.startsWith(`${path}/`)
      }).addClass('hidden');

      // Hiding those optgroup that doesn't have any option visible
      $namespace_select.find('optgroup').filter(function() {
        var visible_options = $(this).find('option:not(.hidden)').length;
        return visible_options == 0;
      }).addClass('hidden');
    }

    $projectTemplateButtons.addClass('hidden');
    $projectFieldsForm.addClass('selected');
    $selectedIcon.empty();

    $selectedTemplateText.text(value);

    $(this)
      .parents('.template-option')
      .find('.avatar')
      .clone()
      .addClass('d-block')
      .removeClass('s40')
      .appendTo($selectedIcon);

    $templateProjectNameInput.focus();
    enableCustomTemplate();

    const $activeTabProjectName = $('.tab-pane.active #project_name');
    const $activeTabProjectPath = $('.tab-pane.active #project_path');
    $activeTabProjectName.focus();
    $activeTabProjectName
      .keyup(() => projectNew.onProjectNameChange($activeTabProjectName, $activeTabProjectPath));

    $projectFieldsForm.find('select#project_namespace_id').first().val(subgroupId);
  }

  $useCustomTemplateBtn.on('change', chooseTemplate);

  $changeTemplateBtn.on('click', () => {
    $projectTemplateButtons.removeClass('hidden');
    $useCustomTemplateBtn.prop('checked', false);
    $namespace_select.val($namespace_select.find('option[data-options-parent="users"]').val()).trigger('change');
    $namespace_select.find('option').removeClass('hidden');
    $namespace_select.find('optgroup').removeClass('hidden')
    disableCustomTemplate();
  });
};

export default () => {

  const $navElement = $('.nav-link[href="#custom-templates"]');
  const $tabContent = $('.project-templates-buttons#custom-templates');
  const $groupNavElement = $('.nav-link[href="#group-templates"]');
  const $groupTabContent = $('.project-templates-buttons#group-templates');

  $tabContent.on('ajax:success', bindEvents);
  $groupTabContent.on('ajax:success', bindEvents);

  $navElement.one('click', () => {
    $.get($tabContent.data('initialTemplates'));
  });

  $groupNavElement.one('click', () => {
    $.get($groupTabContent.data('initialTemplates'));
  });

  bindEvents();
};

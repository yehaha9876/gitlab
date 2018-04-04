class EpicBaseEntity < Grape::Entity
  include RequestAwareEntity
  include EntityDateHelper
  include ActionView::Helpers::TagHelper

  expose :id
  expose :title
  expose :url do |epic|
    group_epic_path(epic.group, epic)
  end
  expose :human_readable_end_date, if: -> (epic, _) { epic.end_date.present? } do |epic|
    epic.end_date&.to_s(:medium)
  end
  expose :human_readable_timestamp, if: -> (epic, _) { epic.end_date.present? || epic.start_date.present? } do |epic|
    if epic.expired?
      content_tag(:strong, 'Past due')
    elsif epic.upcoming?
      content_tag(:strong, 'Upcoming')
    elsif epic.end_date
      time_ago = time_ago_in_words(epic.end_date)
      content = time_ago.gsub(/\d+/) { |match| "<strong>#{match}</strong>" }
      content.slice!("about ")
      content << " remaining"
      content.html_safe
    elsif epic.start_date && epic.start_date.past?
      days    = epic.elapsed_days
      content = content_tag(:strong, days)
      content << " #{'day'.pluralize(days)} elapsed"
      content.html_safe
    end
  end
end

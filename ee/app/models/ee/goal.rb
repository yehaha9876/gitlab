module EE
  module Goal
    extend ActiveSupport::Concern

    prepended do
      include InternalId
      include CacheMarkdownField
      include StripAttribute

      cache_markdown_field :title, pipeline: :single_line
      cache_markdown_field :description

      belongs_to :project
      belongs_to :group

      has_many :labels, -> { distinct.reorder('labels.title') },  through: :issues

      validates :group, presence: true, unless: :project
      validates :project, presence: true, unless: :group
      validates :completion_threshold, presence: true, numericality: { only_integer: true }

      validate :uniqueness_of_title, if: :title_changed?
      validate :goal_type_check
      validate :start_date_should_be_less_than_due_date, if: proc { |m| m.start_date.present? && m.due_date.present? }


      strip_attributes :title

      state_machine :state, initial: :active do
        event :close do
          transition active: :closed
        end

        event :activate do
          transition closed: :active
        end

        state :closed

        state :active
      end

      alias_attribute :name, :title
    end

    # Goal titles must be unique across project goals and group goals
  def uniqueness_of_title
    if project
      relation = Goal.for_projects_and_groups([project_id], [project.group&.id])
    elsif group
      project_ids = group.projects.map(&:id)
      relation = Goal.for_projects_and_groups(project_ids, [group.id])
    end

    title_exists = relation.find_by_title(title)
    errors.add(:title, "already being used for another group or project goal.") if title_exists
  end

  # Goal should be either a project goal or a group goal
  def goal_type_check
    if group_id && project_id
      field = project_id_changed? ? :project_id : :group_id
      errors.add(field, "goal should belong either to a project or a group.")
    end
  end

    def start_date_should_be_less_than_due_date
      if due_date <= start_date
        errors.add(:due_date, "must be greater than start date")
      end
    end
  end
end

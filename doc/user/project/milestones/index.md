# Milestones

## Overview

Milestones allow you scope issues or merge requests together in a finite time period, during which you intend to work on. You define a start date and due date per milestone. Each milestone also has a tile and description. A milestone can be scoped to a project or to a group.

## Use cases

1. Track work to be completed within a single iteration / sprint.
1. Track work to be released together in a single code release.
1. Track work to be completed in a quarter or a longer period consisting of multiple code releases.

## Milestone in sidebar

Every issue and merge request can be assigned at most one milestone. The milestone is visible in the sidebar of the issue (including in boards) or the merge request. From the sidebar, you can do assignment or unassignment. You can also perform this as a [quick action](doc/user/project/quick_actions.md) in a comment.

![Milestones sidebar](img/milestones_sidebar.png)

![Milestones sidebar assign](img/milestones_sidebar_assign.png)

## Milestone scope

Project milestones can be assigned to issues or merge requests in that project only. Group milestones can be assigned to any issue or merge request of any project in that group. You can [promote a milestone label to a group milestone](#milestone-promotion).

## Milestone state

A milestone is either open or closed.

## Milestone page

From the milestone page, the title and description fields are displayed, as well as the start date and due date. You can also access issues and merge requests that have been assigned that milestone. The total [issue weight](link-to-weights) of issues (project milestone only) in the milestone and the [total issue time spent](link-to-time-tracking) is shown too. A percentage complete value is also displayed, which is calculated as the number of closed/merged merge requests and closed issues divided by the total number of merge requests and issues in the milestone.

### Burndown chart

The milestone page for project milestones also includes a burndown chart.

Group milestone pages will include [a burndown chart in the future](https://gitlab.com/gitlab-org/gitlab-ee/issues/3064).

## Filter by milestone in issue lists and merge request lists

From the project issue list page and the project merge request list page, you can filter by both group milestones and project milestones.

From the group issue list page and the group merge request list page, you can filter by both group labels and project milestones.

![Milestones group issues](img/milestones_group_issues.png)

### Special milestones

You can also filter by special milestones:

- `No Milestone`: Issues or merge requests without an assigned milestone.
- `Upcoming`: Issues or merge requests with the next due open milestone (open milestone with the closest due date in the future).
- `Started`: Issues or merge requests from any milestone with a start date before today.

![Milestones dynamic](img/milestones_special.png)

## Filter by milestone in boards 

From [project boards](doc/user/project/issue_board.md), you can filter by both group milestones and project milestones in the search and filter bar.

From [group boards](doc/user/project/issue_board.md#group-issue-boards), you can filter by both group milestones and project milestones in the search and filter bar.

## Limit by milestone in board config

From [project boards](doc/user/project/issue_board.md), you can limit by both group milestones and project labels in the [board config](doc/user/project/issue_board.md#board-with-configuration).

From [group boards](doc/user/project/issue_board.md#group-issue-boards), you can limit by only group milestones in the [board config](doc/user/project/issue_board.md#board-with-configuration).

## Milestone lists

### Project milestone list page

The project milestone list page displays project milestones scoped to that project.

![Milestones project list]()

### Group milestone list page

The group milestone list page displays group milestones scoped to that project.

![Milestones group list]()

>**Note:**
Project milestones will *no longer* be displayed on the group milestone list page in a future release.

The group milestone list page also displays project milestones that belong to projects that are within this group. If multiple 
project milestones share the same title, they will appear as one list item in this list page. *This list item will be removed in a future release.* If you click on this list item, you get a special page that combines all those project milestones that share the same title. *This special page will be removed along with the list item in a future release.* After these are removed, the group milestone list page will only display group milestones. These features were previously designed to help users view issues from multiple projects together in a special page mimicking a milestone. Since we now group milestones, users are recommended to [promote their project milestones to group milestones](#milestone-promotion). 

![Milestones group list project]()

![Milestones dynamic milestone]()

### Dashboard milestone list page

![Milestones dashboard list]()

## Milestone management

>**Note:**
Only users with [Developer role](../../permissions.md) or higher can manage milestones.

You can create, update, and delete milestones from the milestone list pages or the milestone page itself. You can also open and close milestones.

## Milestone promotion

From the project milestone page, you can promote it to a group milestone. This will merge all project milestones across all projects in this group with the same name into a single group milestone. All issues and merge requests that previously were assigned one of these project milestones will now be assigned the new group milestones. This action cannot be reversed and the changes are permanent.

![Milestones promotion](img/milestone_promotion.png)

>**Note:**
Not all project milestone features are currently available for group milestones. The [burndown chart](#burndown-chart) and [list pages](#milestone-lists) are incomplete for group milestones. Users should consider this before milestone promotion.

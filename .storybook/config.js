/* eslint-disable import/no-extraneous-dependencies, import/no-unresolved, import/extensions */

import { configure } from '@storybook/vue'

function loadStories() {
  require('../stories/mr_widget'),
  require('../stories/mr_widget_states')
}

configure(loadStories, module)

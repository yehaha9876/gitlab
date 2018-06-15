<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import { timeDurationShort } from '../../lib/utils/datetime_utility';

export default {
  components: {
  },
  computed: {
    ...mapState([
      'baseArtifactEndpoint',
      'currentSessionId',
      'sessionLog',
      'isLoadingSession',
      'errorSession',
    ]),
    ...mapGetters([
      'firstSessionLogEntry',
    ]),
  },
  methods: {
    ...mapActions([
      'fetchSessionLog',
    ]),
    onSessionPicked() {
      const sessionId = 'todo';
      this.fetchSessionLog(sessionId);
    },
    formatDuration(timeInSeconds) {
      return timeDurationShort(timeInSeconds);
    },
  },
};
</script>

<template>
  <div>
    <div v-if="isLoadingSession">
      Loading...
    </div>
    <div v-if="errorSession">
      Error loading session: {{ errorSession }}
    </div>

    <div v-if="sessionLog">
      <div
        role="row"
        class="gl-responsive-table-row table-row-header"
      >
        <div
          role="rowheader"
          class="table-section section-20 selenium-ci-view-cell"
        >
          Start
        </div>
        <div
          role="rowheader"
          class="table-section section-20 selenium-ci-view-cell"
        >
          Duration
        </div>
        <div
          role="rowheader"
          class="table-section selenium-ci-view-cell"
        >
          Action
        </div>
      </div>

      <div
        v-for="entry in sessionLog.gitlab"
        :key="entry.id"
        class="gl-responsive-table-row"
      >
        <div
          :title="new Date(entry.startTime)"
          class="table-section section-20 selenium-ci-view-cell selenium-ci-view-duration-cell"
        >
          {{ formatDuration((entry.startTime - firstSessionLogEntry.startTime) / 1000) }}
        </div>
        <div class="table-section section-20 selenium-ci-view-cell selenium-ci-view-duration-cell">
          {{ formatDuration((entry.endTime - entry.startTime) / 1000) }}
        </div>
        <div class="table-section selenium-ci-view-cell">
          {{ entry.type }}: {{ entry.method }} {{ entry.path }}

          <div
            v-if="entry.screenshot"
            class="selenium-ci-view-screenshot-container"
          >
            <!-- TODO: Use proper URL join method or get complete URL from backend -->
            <img
              class="selenium-ci-view-screenshot"
              :src="`${baseArtifactEndpoint}${currentSessionId}/screenshots/${entry.id}.png`"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

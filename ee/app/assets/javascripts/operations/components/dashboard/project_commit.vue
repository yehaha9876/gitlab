<script>
import { GlTooltipDirective } from '@gitlab/ui';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    UserAvatarLink,
    Icon,
  },
  props: {
    lastDeployment: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    /**
     * Used to safely return the commit reference
     *
     * @returns {Object}
     */
    commitRef() {
      return this.lastDeployment && this.lastDeployment.ref;
    },
    /**
     * Used to check the existence of a tag
     *
     * @returns {Boolean}
     */
    tag() {
      return this.lastDeployment && this.lastDeployment.tag;
    },
    /**
     * Used to the commit URL
     *
     * @returns {String}
     */
    commitUrl() {
      return (
        this.lastDeployment && this.lastDeployment.commit && this.lastDeployment.commit.commit_url
      );
    },
    /**
     * Used to safely return the commit short SHA
     *
     * @returns {String}
     */
    shortSha() {
      return (
        this.lastDeployment && this.lastDeployment.commit && this.lastDeployment.commit.short_id
      );
    },
    /**
     * Used to safely return the commit title
     *
     * @returns {String}
     */
    title() {
      return this.lastDeployment && this.lastDeployment.commit && this.lastDeployment.commit.title;
    },
    /**
     * Used to safely return the author of the commit
     *
     * @returns {Object}
     */
    author() {
      return this.lastDeployment && this.lastDeployment.commit && this.lastDeployment.commit.author;
    },
    /**
     * Used to verify if all the properties needed to render the commit
     * ref section were provided.
     *
     * @returns {Boolean}
     */
    hasCommitRef() {
      return this.commitRef && this.commitRef.name && this.commitRef.ref_path;
    },
    /**
     * Used to verify if all the properties needed to render the commit
     * author section were provided.
     *
     * @returns {Boolean}
     */
    hasAuthor() {
      return this.author && this.author.avatar_url && this.author.path && this.author.username;
    },
    /**
     * If information about the author is provided will return a string
     * to be rendered as the alt attribute of the img tag.
     *
     * @returns {String}
     */
    userImageAltDescription() {
      return this.lastDeployment && this.author.username
        ? `${this.author.username}'s avatar`
        : null;
    },
  },
};
</script>
<template>
  <div class="branch-commit">
    <template v-if="hasCommitRef">
      <div class="icon-container">
        <i v-if="tag" class="fa fa-tag" aria-hidden="true"> </i> <icon v-if="!tag" name="branch" />
      </div>

      <a v-gl-tooltip :href="commitRef.ref_path" :title="commitRef.name" class="ref-name">
        {{ commitRef.name }}
      </a>
    </template>
    <icon name="commit" class="commit-icon js-commit-icon" />

    <a :href="commitUrl" class="commit-sha"> {{ shortSha }} </a>

    <div class="commit-title flex-truncate-parent">
      <span v-if="title" class="flex-truncate-child">
        <user-avatar-link
          v-if="hasAuthor"
          :link-href="author.path"
          :img-src="author.avatar_url"
          :img-size="16"
          :img-alt="userImageAltDescription"
          :tooltip-text="author.username"
          class="avatar-image-container"
        />
        <a :href="commitUrl" class="commit-row-message"> {{ title }} </a>
      </span>
      <span v-else> Can't find HEAD commit for this branch </span>
    </div>
  </div>
</template>

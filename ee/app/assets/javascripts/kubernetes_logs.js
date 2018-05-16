import $ from 'jquery';
import axios from '~/lib/utils/axios_utils';
import { getParameterValues } from '~/lib/utils/url_utility';
import createFlash from '~/flash';
import { __, s__, sprintf } from '~/locale';
import _ from 'underscore';

export default class KubernetesPodLogs {
  constructor(container) {
    this.options = $(container).data();
    this.podNameContainer = $(container).find('.js-pod-name');
    this.podName = getParameterValues('pod_name')[0];
    this.$buildOutputContainer = $(container).find('.js-build-output');
    this.$window = $(window);
    // Scroll controllers
    this.$scrollTopBtn = $(container).find('.js-scroll-up');
    this.$scrollBottomBtn = $(container).find('.js-scroll-down');
    this.$refreshLogBtn = $(container).find('.js-refresh-log');
    this.$buildRefreshAnimation = $(container).find('.js-build-refresh');
    this.isLogComplete = false;

    this.scrollThrottled = _.throttle(this.toggleScroll.bind(this), 100);

    if (!this.podName) {
      createFlash(s__('Environments|No pod name has been specified'));
      return;
    }

    const podTitle = sprintf(
      s__('Environments|Pod logs from %{podName}'),
      {
        podName: `<strong>${this.podName}</strong>`,
      },
      false,
    );
    this.podNameContainer.empty();
    this.podNameContainer.append(podTitle);

    this.$window.off('scroll').on('scroll', () => {
      if (!this.isScrolledToBottom()) {
        this.toggleScrollAnimation(false);
      } else if (this.isScrolledToBottom() && !this.isLogComplete) {
        this.toggleScrollAnimation(true);
      }
      this.scrollThrottled();
    });

    this.$scrollTopBtn.off('click').on('click', this.scrollToTop.bind(this));

    this.$scrollBottomBtn.off('click').on('click', this.scrollToBottom.bind(this));

    this.$refreshLogBtn.off('click').on('click', this.getPodLogs.bind(this));

    this.getPodLogs();
  }

  // eslint-disable-next-line class-methods-use-this
  scrollDown() {
    const $document = $(document);
    $document.scrollTop($document.height());
  }

  scrollToBottom() {
    this.scrollDown();
    this.toggleScroll();
  }

  scrollToTop() {
    $(document).scrollTop(0);
    this.toggleScroll();
  }

  getPodLogs() {
    this.scrollToTop();
    this.$buildOutputContainer.empty();
    this.$buildRefreshAnimation.show();
    this.toggleDisableButton(this.$refreshLogBtn, 'true');

    return axios
      .get(this.options.logsPath, {
        params: { pod_name: this.podName },
      })
      .then(res => {
        const logs = res.data.logs;
        const formattedLogs = logs.map(logEntry => `${_.escape(logEntry)} <br />`);
        this.$buildOutputContainer.append(formattedLogs);
        this.scrollDown();
        this.isLogComplete = true;
        this.$buildRefreshAnimation.hide();
        this.toggleDisableButton(this.$refreshLogBtn, false);
      })
      .catch(() => createFlash(__('Something went wrong on our end')));
  }

  toggleScrollAnimation(toggle) {
    this.$scrollBottomBtn.toggleClass('animate', toggle);
  }

  // eslint-disable-next-line class-methods-use-this
  toggleDisableButton($button, disable) {
    if (disable && $button.prop('disabled')) return;
    $button.prop('disabled', disable);
  }

  // eslint-disable-next-line class-methods-use-this
  canScroll() {
    return $(document).height() > $(window).height();
  }

  // eslint-disable-next-line class-methods-use-this
  isScrolledToBottom() {
    const $document = $(document);

    const currentPosition = $document.scrollTop();
    const scrollHeight = $document.height();

    const windowHeight = $(window).height();

    return scrollHeight - currentPosition === windowHeight;
  }

  toggleScroll() {
    const $document = $(document);
    const currentPosition = $document.scrollTop();
    const scrollHeight = $document.height();

    const windowHeight = $(window).height();
    if (this.canScroll()) {
      if (currentPosition > 0 && scrollHeight - currentPosition !== windowHeight) {
        // User is in the middle of the log

        this.toggleDisableButton(this.$scrollTopBtn, false);
        this.toggleDisableButton(this.$scrollBottomBtn, false);
      } else if (currentPosition === 0) {
        // User is at Top of  Log

        this.toggleDisableButton(this.$scrollTopBtn, true);
        this.toggleDisableButton(this.$scrollBottomBtn, false);
      } else if (this.isScrolledToBottom()) {
        // User is at the bottom of the build log.

        this.toggleDisableButton(this.$scrollTopBtn, false);
        this.toggleDisableButton(this.$scrollBottomBtn, true);
      }
    } else {
      this.toggleDisableButton(this.$scrollTopBtn, true);
      this.toggleDisableButton(this.$scrollBottomBtn, true);
    }
  }
}

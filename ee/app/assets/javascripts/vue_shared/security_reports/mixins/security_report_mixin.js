import { s__, n__, __, sprintf } from '~/locale';

export default {
  methods: {
    sastText(newIssues = [], resolvedIssues = [], allIssues = []) {
      const text = [];

      if (!newIssues.length && !resolvedIssues.length && !allIssues.length) {
        text.push(s__('ciReport|SAST detected no security vulnerabilities'));
      } else if (!newIssues.length && !resolvedIssues.length && allIssues.length) {
        text.push(s__('ciReport|SAST detected no new security vulnerabilities'));
      } else if (newIssues.length || resolvedIssues.length) {
        text.push(s__('ciReport|SAST'));
      }

      if (resolvedIssues.length) {
        text.push(n__(
          ' detected %d new vulnerability',
          ' detected %d new vulnerabilities',
          resolvedIssues.length,
        ));
      }

      if (newIssues.length > 0 && resolvedIssues.length > 0) {
        text.push(__(' and'));
      }

      if (newIssues.length) {
        text.push(n__(
          ' detected %d fixed vulnerability',
          ' detected %d fixed vulnerabilities',
          newIssues.length,
        ));
      }

      return text.join('');
    },

    sastContainerText(vulnerabilities = [], approved = [], unapproved = []) {
      if (!vulnerabilities.length) {
        return s__('ciReport|SAST:container no vulnerabilities were found');
      }

      if (!unapproved.length && approved.length) {
        return n__(
          'SAST:container found %d approved vulnerability',
          'SAST:container found %d approved vulnerabilities',
          approved.length,
        );
      } else if (unapproved.length && !approved.length) {
        return n__(
          'SAST:container found %d vulnerability',
          'SAST:container found %d vulnerabilities',
          unapproved.length,
        );
      }

      return `${n__(
        'SAST:container found %d vulnerability,',
        'SAST:container found %d vulnerabilities,',
        vulnerabilities.length,
      )} ${n__(
        'of which %d is approved',
        'of which %d are approved',
        approved.length,
      )}`;
    },

    dastText(dast = []) {
      if (dast.length) {
        return n__(
          'DAST detected %d alert by analyzing the review app',
          'DAST detected %d alerts by analyzing the review app',
          dast.length,
        );
      }

      return s__('ciReport|DAST detected no alerts by analyzing the review app');
    },
  },
};

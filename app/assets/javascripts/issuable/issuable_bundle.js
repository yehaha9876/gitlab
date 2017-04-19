import Vue from 'vue';
import issuableTimeTracker from './time_tracking/time_tracking_bundle';

document.addEventListener('DOMContentLoaded',
  () => new Vue(issuableTimeTracker));

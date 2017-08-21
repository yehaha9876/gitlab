import Cookies from 'js-cookie';

export const getCookieName = cookieId => `feature-highlighted-${cookieId}`;
export const getSelector = highlightId => `.js-feature-highlight[data-highlight=${highlightId}]`;

export const showPopover = function showPopover() {
  this.popover('show');
  this.addClass('disable-animation');
};

export const hidePopover = function hidePopover() {
  this.popover('hide');
  this.removeClass('disable-animation');
};

export const dismiss = function dismiss(cookieId) {
  Cookies.set(getCookieName(cookieId), true);
  hidePopover.call(this);
  this.hide();
};

export const mouseenter = function mouseenter() {
  const $featureHighlight = $(this);
  showPopover.call($featureHighlight);

  document.querySelector('.popover')
    .addEventListener('mouseleave', hidePopover.bind($featureHighlight));
};

export const mouseleave = function mouseleave() {
  if (!document.querySelector('.popover:hover')) {
    const $featureHighlight = $(this);
    hidePopover.call($featureHighlight);
  }
};

export const setupDismissButton = function setupDismissButton() {
  const popoverId = this.getAttribute('aria-describedby');
  const cookieId = this.dataset.highlight;
  const $popover = $(this);

  document.querySelector(`#${popoverId} .dismiss-feature-highlight`)
    .addEventListener('click', dismiss.bind($popover, cookieId));
};

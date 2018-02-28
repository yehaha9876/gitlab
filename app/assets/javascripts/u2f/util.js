export function getChromeVersion(userAgent) {
  const match = userAgent.match(/Chrom(?:e|ium)\/([0-9]+)\./);
  return match ? parseInt(match[1], 10) : false;
}

export function getOperaVersion(userAgent) {
  const match = userAgent.match(/Opera[^0-9]*([0-9]+)[^0-9]+/);
  return match ? parseInt(match[1], 10) : false;
}

export function canInjectU2fApi() {
  const userAgent = typeof navigator !== 'undefined' ? navigator.userAgent : '';
  const isSupportedChrome = userAgent.indexOf('Chrom') >= 0 && getChromeVersion(userAgent) >= 41;
  const isSupportedOpera = userAgent.indexOf('Opera') >= 0 && getOperaVersion(userAgent) >= 40;
  const isMobile = (
    userAgent.indexOf('droid') >= 0 ||
    userAgent.indexOf('CriOS') >= 0 ||
    /\b(iPad|iPhone|iPod)(?=;)/.test(userAgent)
  );
  return (isSupportedChrome || isSupportedOpera) && !isMobile;
}

export default function importU2FLibrary() {
  if (window.u2f) {
    return Promise.resolve(window.u2f);
  }
  if (canInjectU2fApi() || (gon && gon.test_env)) {
    return import(/* webpackMode: "eager" */ 'vendor/u2f').then(() => window.u2f);
  }
  return Promise.reject();
}

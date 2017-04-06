import {
  stateToComponentMap as CEStateToComponentMap,
  statesToShowHelpWidget as CEStatesToShowHelpWidget,
} from '../../stores/state_maps';

const stateToComponentMap = Object.assign({}, CEStateToComponentMap, {
  geoSecondaryNode: 'mr-widget-geo-secondary-node',
});

export default {
  stateToComponentMap,
  statesToShowHelpWidget: CEStatesToShowHelpWidget,
};

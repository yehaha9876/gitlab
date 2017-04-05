import {
  stateToComponentMap as CEStateToComponentMap,
  statesToShowHelpWidget as CEStatesToShowHelpWidget,
} from '../../stores/state_maps';

const stateToComponentMap = Object.assign(CEStateToComponentMap, {
  secondaryGeoNode: 'mr-widget-secondary-geo-node',
});

export default {
  stateToComponentMap,
  statesToShowHelpWidget: CEStatesToShowHelpWidget,
};

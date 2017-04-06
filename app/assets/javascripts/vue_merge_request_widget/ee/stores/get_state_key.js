import CEGetStateKey from '../../stores/get_state_key';

export default (data) => {
  if (this.isGeoSecondaryNode) {
    return 'geoSecondaryNode';
  }
  return CEGetStateKey.call(this, data);
};


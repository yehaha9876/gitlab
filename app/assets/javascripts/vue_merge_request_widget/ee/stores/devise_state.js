import CEDeviseState from '../../stores/devise_state';

export default (data) => {
  if (this.isGeoSecondaryNode) {
    return 'geoSecondaryNode';
  }
  return CEDeviseState.call(this, data);
};


import CEDeviseState from '../../stores/devise_state';

export default (data) => {
  if (data.is_secondary_geo_node) {
    return 'secondaryGeoNode';
  }
  return CEDeviseState.call(this, data);
};


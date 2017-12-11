module Geo
  module Fdw
    class Ci::Build < ::Geo::BaseFdw
      self.table_name = Gitlab::Geo.fdw_table('ci_builds')
    end
  end
end

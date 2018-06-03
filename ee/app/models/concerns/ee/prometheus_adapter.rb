module EE
  module PrometheusAdapter
    def clear_prometheus_reactive_cache!(query_name, *args)
      query_class = query_klass_for(query_name)
      query_args = build_query_args(*args)

      clear_reactive_cache!(query_class.name, *query_args)
    end
  end
end

class Kubeclient::Client
  def format_datetime(value)
    case value
    when DateTime, Time
      value.strftime('%FT%T.%9N%:z')
    when String
      value
    else
      raise ArgumentError, "unsupported type '#{value.class}' of time value '#{value}'"
    end
  end

  # We need to monkey patch this method until
  # https://github.com/abonas/kubeclient/pull/323 is merged
  def proxy_url(kind, name, port, namespace = '')
    discover unless @discovered
    entity_name_plural =
      if %w[services pods nodes].include?(kind.to_s)
        kind.to_s
      else
        @entities[kind.to_s].resource_name
      end

    ns_prefix = build_namespace_prefix(namespace)
    rest_client["#{ns_prefix}#{entity_name_plural}/#{name}:#{port}/proxy"].url
  end

  # We need to monkey-patch until
  # https://github.com/abonas/kubeclient/pull/326 is merged
  def get_pod_log(
    pod_name, namespace,
    container: nil, previous: false,
    timestamps: false, since_time: nil,
    tail_lines: nil)

    params = {}
    params[:previous] = true if previous
    params[:container] = container if container
    params[:timestamps] = timestamps if timestamps
    params[:sinceTime] = format_datetime(since_time) if since_time
    params[:tailLines] = tail_lines if tail_lines

    ns = build_namespace_prefix(namespace)
    handle_exception do
      rest_client[ns + "pods/#{pod_name}/log"]
        .get({ 'params' => params }.merge(@headers))
    end
  end
end

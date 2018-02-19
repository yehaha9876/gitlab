require 'opentracing'
require 'jaeger/client'
require 'rack/tracer'
require 'rails/tracer'

OpenTracing.global_tracer = Jaeger::Client.build(host: 'jaeger-agent.default.svc.cluster.local', port: 6831, service_name: 'gitlab')

Rails::Rack::Tracer.instrument
ActiveRecord::Tracer.instrument(tracer: OpenTracing.global_tracer, 
    active_span: -> { OpenTracing.global_tracer.active_span })
ActiveSupport::Cache::Tracer.instrument(tracer: OpenTracing.global_tracer, 
    active_span: -> { OpenTracing.global_tracer.active_span })
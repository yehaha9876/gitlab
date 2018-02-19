require 'opentracing'
require 'jaeger/client'
require 'rack/tracer'
require 'rails/tracer'


if(ENV['jaeger_tracing'] == 'true') 
    OpenTracing.global_tracer = Jaeger::Client.build(host: ENV['jaeger_host'], port: 6831, service_name: 'gitlab')

    Rails::Rack::Tracer.instrument
    ActiveRecord::Tracer.instrument(tracer: OpenTracing.global_tracer, 
        active_span: -> { OpenTracing.global_tracer.active_span })
    ActiveSupport::Cache::Tracer.instrument(tracer: OpenTracing.global_tracer, 
        active_span: -> { OpenTracing.global_tracer.active_span })
end
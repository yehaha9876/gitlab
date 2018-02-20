##require 'opentracing'
require 'spanmanager'
require 'jaeger/client'
require 'rails/tracer'
require 'sidekiq-opentracing'

if( ENV['jaeger_tracing'] == 'true' )
  
  OpenTracing.global_tracer = SpanManager::Tracer.new(
    Jaeger::Client.build(host: ENV['jaeger_host'], port: 6831, service_name: 'gitlab'),
    SpanManager::ThreadLocalManagedSpanSource.new
    )

  Rails::Tracer.instrument(
    tracer: OpenTracing.global_tracer, 
    active_span: -> { OpenTracing.global_tracer.active_span },
    rack: true
    )

  ActiveRecord::Tracer.instrument(
    tracer: OpenTracing.global_tracer, 
    active_span: -> { OpenTracing.global_tracer.active_span }
    )

  ActiveSupport::Cache::Tracer.instrument(
    tracer: OpenTracing.global_tracer, 
    active_span: -> { OpenTracing.global_tracer.active_span }
    )

  Sidekiq::Tracer.instrument(
    tracer: OpenTracing.global_tracer,
    active_span: -> { OpenTracing.global_tracer.active_span }
    )

end
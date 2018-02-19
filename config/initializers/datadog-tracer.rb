Datadog.configure do |c|
    c.tracer hostname: 'jaeger-agent.default.svc.cluster.local'
    c.use :rails
    c.use :grape
    c.use :sidekiq
    c.use :redis
end
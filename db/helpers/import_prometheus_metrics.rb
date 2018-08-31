def find_group_title(title)
  PrometheusMetric::GROUP_TITLES.map do |key, value|
    return PrometheusMetric.groups[key] if value == title
  end

  raise "Invalid title: #{title}"
end

class ImportPrometheusMetrics
  def initialize(file = 'config/prometheus/additional_metrics.yml')
    @content = YAML.load_file('config/prometheus/additional_metrics.yml')
  end
  
  def execute
    @content.map do |group|
      group_type = find_group_title(group['group'])
      process_metrics(group_type, group['metrics'])
    end

    private

    def process_metrics(group_type, metrics)
      metrics.map do |metric|
        metric['queries'].map do |query|
          process_metric_query(group_type, metric, query)
        end
      end
    end

    def process_metric_query(group_type, metric, query)
      PrometheusMetric.default.find_or_create_by(
        group: group_type,
        title: metric['title'],
        y_label: metric['y_label'],
        legend: query['label'],
      ).update!(
        query: query['query_range'],
        unit: query['unit']
      )
    end
  end
end

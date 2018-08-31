
module Helpers
  class ImportPrometheusMetrics
    def initialize(file = 'config/prometheus/additional_metrics.yml')
      @content = YAML.load_file('config/prometheus/additional_metrics.yml')
    end
    
    def execute
      @content.map do |group|
        group_type = find_group_title_key(group['group'])
        process_metrics(group_type, group['metrics'])
      end
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

    def find_group_title_key(title)
      PrometheusMetric.groups[find_group_title(title)]
    end

    def find_group_title(title)
      PrometheusMetric::GROUP_TITLES.invert[title]
    end
  end
end

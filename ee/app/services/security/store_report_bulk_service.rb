# frozen_string_literal: true

module Security
  # Service for storing a given security report into the database.
  #
  class StoreReportBulkService < ::BaseService

    def initialize(pipeline, report)
      @pipeline = pipeline
      @report = report
      @project = @pipeline.project

      @scanners = {}
      @identifiers = {}
      @occurrences = {}
      @occurrence_identifiers = []
    end

    def execute(report)
      # Ensure we're not trying to insert data twice for this report
      return error("#{@report.type} report already stored for this pipeline, skipping...") if executed?

      store_report(report)

      success
    end

    private

    def executed?
      pipeline.vulnerabilities.report_type(@report.type).any?
    end

    def store_report(report)
      # Step 1: gather objects by type to prepare bulk upserts
      report.vulnerabilities.each do |vulnerabilty|
        vulnerabilty.identifiers.each do |identifier|
          add_identifier(identifier)
          add_occurrence_identifier(vulnerabilty, identifier)
        end

        add_scanner(vulnerabilty.scanner)
        add_occurrence(vulnerabilty)
      end

      # Step 2: upsert objects in bulk
      upsert_identifiers
      upsert_scanners
      upsert_occurrences
      upsert_occurrence_identifiers
    end

    def add_scanner(scanner)
      @scanners[scanner.external_id] ||= scanner
    end

    def add_identifier(identifier)
      @identifiers[identifier.fingerprint] ||= identifier
    end

    def add_occurrence(vulnerabilty)
      @occurrences[vulnerabilty.uuid] ||= vulnerabilty
    end

    def add_occurrence_identifier(vulnerabilty, identifier)
      # We can't actually build OccurrenceIdentifier join model now as we
      # need DB IDs. So we use this temporary hash to keep references.
      @occurrence_identifiers << {
        vulnerability_uuid: vulnerabilty.uuid,
        identifier_fingerprint: identifier.fingerprint
      }
    end

    def upsert_identifiers
      on_conflict_options = {
        keys: %w(project_id fingerprint),
        update_columns: %w(name url)
      }

      ids = bulk_upsert_models(@identifiers.values, on_conflict_options: on_conflict_options, return_ids: true)

      # Assign database ID to saved models
      if !ids.blank?
        @identifiers.values.each_with_index do |model, index|
          model.id = ids[index]
        end
      else # MySQL does not support returning IDs
        @project.vulnerability_identifiers.where(fingerprint: @identifiers.keys).find_each do |db_identifier|
          @identifiers[db_identifier.fingerprint].id = db_identifier.id
        end
      end
    end

    def upsert_scanners
      on_conflict_options = {
        keys: %w(project_id external_id),
        update_columns: %w(name)
      }

      ids = bulk_upsert_models(@scanners.values, on_conflict_options: on_conflict_options, return_ids: true)

      # Assign database ID to saved models
      if !ids.blank?
        @scanners.values.each_with_index do |model, index|
          model.id = ids[index]
        end
      else # MySQL does not support returning IDs
        @project.vulnerability_scanners.where(external_id: @scanners.keys).find_each do |db_scanner|
          @scanners[db_scanner.external_id].id = db_scanner.id
        end
      end
    end

    def upsert_occurrences
      # Refresh scanner IDs now that they
      # have been stored into the database.
      @occurrences.each do |key, occurrence|
        occurrence.scanner_id = occurrence.scanner.id
      end

      on_conflict_options = {
        keys: %w(project_id ref primary_identifier_fingerprint location_fingerprint pipeline_id scanner_id),
        update_columns: %w(name uuid raw_metadata)
      }

      ids = bulk_upsert_models(@occurrences.values, on_conflict_options: on_conflict_options, return_ids: true)

      # Assign database ID to saved models
      unless ids.blank?
        @occurrences.values.each_with_index do |model, index|
          model.id = ids[index]
        end
      else # MySQL does not support returning IDs
        @project.vulnerabilities.where(uuid: @occurrences.keys).find_each do |db_occurrence|
          @occurrences[db_occurrence.uuid].id = db_occurrence.id
        end
      end
    end

    def upsert_occurrence_identifiers
      # Set occurrences and identifiers IDs now that they
      # have been stored into the database.
      models = @occurrence_identifiers.map do |oi|
        Vulnerabilities::OccurrenceIdentifier.new(
          occurrence_id: @occurrences[oi[:vulnerability_uuid]].id,
          identifier_id: @identifiers[oi[:identifier_fingerprint]].id
        )
      end

      on_conflict_options = {
        keys: %w(occurrence_id identifier_id)
      }

      bulk_upsert_models(models, on_conflict_options: on_conflict_options)
    end

    def bulk_upsert_models(models, on_conflict_options: {}, return_ids: false)
      return if models.blank?

      klass = models.first.class

      rows = models.map do |model|
        attributes = model.attributes.except("id")
        attributes["created_at"] = Time.now if model.class.column_names.include?("created_at")
        attributes["updated_at"] = Time.now if model.class.column_names.include?("updated_at")
        attributes
      end

      keys = rows.first.keys.sort
      ar_columns = klass.columns.select { |c| c.name.in? keys}.sort_by(&:name)

      db_table_name = connection.quote_table_name(klass.table_name)
      db_column_names = keys.map { |key| connection.quote_column_name(key) }

      tuples = rows.map do |row|
        keys.zip(ar_columns).map do |key, column|
          connection.quote(row[key], column)
        end
      end

      sql = <<-EOF
        INSERT INTO #{db_table_name} (#{db_column_names.join(', ')})
        VALUES #{tuples.map { |tuple| "(#{tuple.join(', ')})" }.join(', ')}
      EOF

      if on_conflict_options.is_a? Hash
        if Gitlab::Database.postgresql?
          sql = sql + "ON CONFLICT (#{on_conflict_options[:keys].join(', ')})"
          unless on_conflict_options[:update_columns].blank?
            sql = sql + " DO UPDATE SET #{on_conflict_options[:update_columns].map { |c| "#{c} = EXCLUDED.#{c}" }.join(', ')}"
          else
            sql = sql + ' DO NOTHING'
          end
        else # MySQL
          sql = sql + 'ON DUPLICATE KEY'
          unless on_conflict_options[:update_columns].blank?
            sql = sql + " UPDATE #{on_conflict_options[:update_columns].map { |c| "#{c} = VALUES(#{c})" }.join(', ')}"
          else
            sql = sql + ' IGNORE'
          end
        end
      end

      if return_ids && Gitlab::Database.postgresql?
        sql << ' RETURNING id'
      end

      result = connection.execute(sql)

      if return_ids
        result.values.map { |tuple| tuple[0].to_i }
      else
        []
      end
    end

    def connection
      ActiveRecord::Base.connection
    end
  end
end

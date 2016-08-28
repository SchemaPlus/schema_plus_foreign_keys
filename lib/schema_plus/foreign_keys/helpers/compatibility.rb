module SchemaPlus::Compatibility
  module ActiveRecord
    module Migration
      module ClassMethods
        def latest_version
          begin
            ::ActiveRecord::Migration::Current
          rescue
            self
          end
        end
      end
    end

    module ConnectionAdapters
      module AbstractAdapter
        def tables_without_deprecation
          # In the future (AR 5.1?) tables may really return just tables instead of data
          # sources, and the deprecation warning will be removed. We would
          # have to update the method then.
          try :data_sources || tables
        end
      end
    end
  end
end

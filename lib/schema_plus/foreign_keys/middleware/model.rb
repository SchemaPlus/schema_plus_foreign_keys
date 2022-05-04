# frozen_string_literal: true

module SchemaPlus::ForeignKeys
  module Middleware

    module Model
      module ResetColumnInformation

        def after(env)
          env.model.reset_foreign_key_information
        end

      end
    end

  end
end

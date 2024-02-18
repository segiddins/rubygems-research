# frozen_string_literal: true

class VersionImportErrors::IndexView < ApplicationView
  include Phlex::Rails::Helpers::LinkTo
  extend Literal::Attributes
  attribute :pagy, Object
  attribute :version_import_errors, Object
  attribute :counts, Array

  def template
    h1 { "VersionImportErrors" }

    @counts.each do |err, count, version|
      p do
        plain "#{err}: #{count}"
        br
        link_to "example", version_path(version)
      end
    end

    ul do
      @version_import_errors.each do |err|
        li do
          link_to err.version.full_name, err.version
          br
          code { err.error }
        end
      end
    end

    unsafe_raw helpers.pagy_nav(@pagy) if @pagy.pages > 1
  end
end

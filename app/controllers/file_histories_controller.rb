# frozen_string_literal: true

class FileHistoriesController < ApplicationController
  before_action :set_server
  before_action :set_rubygem, only: %i[ show diff ]

  layout -> { ApplicationLayout }

  def show
    rubygem = @rubygem
    path = params[:path]
    if path.nil?
      render plain: rubygem.version_data_entries.distinct.pluck(:full_name).sort.join("\n")
    else
      entries = rubygem.version_data_entries.where(full_name: params[:path]).includes(:version, :blob_excluding_contents).strict_loading
      render FileHistory::ShowView.new(path:, entries:, rubygem: rubygem)
    end
  end

  def diff
    rubygem = @rubygem
    path = params[:path]
    v1 = rubygem.versions.find_by!(number: params[:v1])
    v2 = rubygem.versions.find_by!(number: params[:v2])

    v1_entry = v1.version_data_entries.includes(:blob).find_by(full_name: path)
    v2_entry = v2.version_data_entries.includes(:blob).find_by(full_name: path)

    if v1_entry.nil? && v2_entry.nil?
      render plain: "File not found in either version", status: :not_found
      return
    end

    if v1_entry.nil?
      render plain: "File not found in version #{v1.slug}", status: :not_found
      return
    end

    if v2_entry.nil?
      render plain: "File not found in version #{v2.slug}", status: :not_found
      return
    end

    if v1_entry.blob == v2_entry.blob
      render plain: "Files are identical"
      return
    end

    render FileHistory::DiffView.new(v1_entry:, v2_entry:)
  end

  private
    def set_rubygem
      @rubygem = @server.rubygems.find_by!(name: params[:rubygem_name])
    end

    def set_server
      if params[:server_id].present?
        @server = Server.find(server_id)
      else
        @server = Server.find_by!(url: "https://rubygems.org")
      end
    end
end

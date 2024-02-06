# frozen_string_literal: true

class VersionsController < ApplicationController
  layout -> { ApplicationLayout }

  def show
    version = Version.includes(:rubygem, :server, :version_data_entries).find(params[:id])
    render Versions::ShowView.new(version:)
  end

  def index
    render Versions::IndexView.new
  end
end

# frozen_string_literal: true

class DataSummaryController < ApplicationController
  layout -> { ApplicationLayout }
  
  def index
    render DataSummary::IndexView.new
  end
end

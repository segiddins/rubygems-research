# frozen_string_literal: true

class Versions::IndexView < ApplicationView
  def template
    h1 { "Versions index" }
    p { "Find me in app/views/versions/index_view.rb" }
  end
end

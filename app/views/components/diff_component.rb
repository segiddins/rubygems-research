# frozen_string_literal: true

class DiffComponent < ApplicationComponent
  extend Literal::Properties
  prop :data_old, String
  prop :data_new, String

  def template
    div(style: 'white-space: pre; font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;') do
      data_old = @data_old.lines
      data_new = @data_new.lines
      file_length_difference = 0
      oldhunk = hunk = nil
      diffs = Diff::LCS.diff(data_old, data_new)

      diffs.each do |piece|
        begin # rubocop:disable Style/RedundantBegin
          hunk = Diff::LCS::Hunk.new(data_old, data_new, piece, 5, file_length_difference)
          file_length_difference = hunk.file_length_difference

          next unless oldhunk
          next if hunk.merge(oldhunk)

          hunk(oldhunk)
        ensure
          oldhunk = hunk
        end
      end

      hunk(oldhunk, true)
    end
  end

  def hunk(hunk, last = false)
    return unless hunk
    hunk.diff(:unified, last).each_line do |l|
      case l[0]
      when '-'
        span(style: "color: red;") { l }
      when '+'
        span(style: "color: green;") { l }
      when '@'
        strong { l }
      else
        plain l
      end
    end
    plain "\n"
  end
end

# frozen_string_literal: true

class FileHistoriesController < ApplicationController
  layout -> { ApplicationLayout }

  def show
    rubygem = Rubygem.find_by!(name: params[:rubygem_name])
    path = params[:path]
    if path.nil?
      render plain: rubygem.version_data_entries.distinct.pluck(:full_name).sort.join("\n")
    else
      entries = rubygem.version_data_entries.where(full_name: params[:path]).includes(:version, :blob_excluding_contents).strict_loading
      render FileHistory::ShowView.new(path:, entries:, rubygem: rubygem)
    end
  end

  def diff
    rubygem = Rubygem.find_by!(name: params[:rubygem_name])
    path = params[:path]
    v1 = rubygem.versions.find_by!(number: params[:v1])
    v2 = rubygem.versions.find_by!(number: params[:v2])

    v1_entry = v1.version_data_entries.find_by(full_name: path)
    v2_entry = v2.version_data_entries.find_by(full_name: path)

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

    data_old = v1_entry.blob.decompressed_contents.lines
    data_new = v2_entry.blob.decompressed_contents.lines
    file_length_difference = 0
    diffs = Diff::LCS.diff(data_old, data_new)
    require "diff/lcs/hunk"

    output = []

      # Loop over hunks. If a hunk overlaps with the last hunk, join them.
  # Otherwise, print out the old one.
  oldhunk = hunk = nil

  if :unified == :ed
    real_output = output
    output = []
  end

  lines = params.permit(:lines)[:lines]&.to_i || 5

  diffs.each do |piece|
    begin # rubocop:disable Style/RedundantBegin
      hunk = Diff::LCS::Hunk.new(data_old, data_new, piece, lines, file_length_difference)
      file_length_difference = hunk.file_length_difference

      next unless oldhunk
      next if lines.positive? && hunk.merge(oldhunk)

      output << oldhunk.diff(:unified)
      output << "\n" if :unified == :unified
    ensure
      oldhunk = hunk
    end
  end

  last = oldhunk.diff(:unified, true)
  last << "\n" if last.respond_to?(:end_with?) && !last.end_with?("\n")

  output << last


    render plain: output.join
  end
end

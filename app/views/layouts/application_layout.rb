# frozen_string_literal: true

class ApplicationLayout < ApplicationView
	include Phlex::Rails::Layout
	extend Phlex::Rails::HelperMacros

	register_output_helper :debugbar_head
	register_output_helper :debugbar_body

	def template(&block)
		doctype

		html do
			head do
				title { "You're awesome" }
				meta name: "viewport", content: "width=device-width,initial-scale=1"
				csp_meta_tag
				csrf_meta_tags
				stylesheet_link_tag "application", data_turbo_track: "reload"
				javascript_importmap_tags
				debugbar_head if respond_to?(:debugbar_path)
			end

			body do
				main(&block)
				debugbar_body cable: {url: "wss://rubygems-research.microplane:443"} if respond_to?(:debugbar_path)
			end
		end
	end
end

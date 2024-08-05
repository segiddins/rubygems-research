# frozen_string_literal: true

class RansackAdvancedSearchComponent < ApplicationComponent
  include Phlex::Rails::Helpers::TextField
  include Phlex::Rails::Helpers::CheckBoxTag
  include Phlex::Rails::Helpers::LabelTag
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::CollectionSelect

  class RansackFormBuilder < Phlex::Rails::BufferedFormBuilder
    %i[
      attribute_fields
      condition_fields
      grouping_fields
      label
      predicate_fields
      search_fields
      sort_fields
      value_fields

      fields_for
    ].each do |method_name|
      define_builder_yielding_method method_name, self
    end
  end

  extend Phlex::Rails::HelperMacros
	register_builder_yielding_helper :search_form_for, RansackFormBuilder

  extend Literal::Properties
  prop :search, Object
  prop :search_url, String
  prop :condition_associations, Array
  prop :sort_associations, Array

  def view_template
    search_form_for(@search, url: @search_url, class: "p-2 space-y-2") do |f|
      setup_search_form(f)

      fieldset(class: "border-2 space-y-2 p-2") do
        legend { "Sorting" }
        f.sort_fields do |s|
          _sort_fields(s)
        end
        button_to_add_fields(f, :sort)
      end

      fieldset(class: "border-2 space-y-2 p-2") do
        legend { "Condition Groups" }
        f.grouping_fields do |g|
          _grouping_fields(g)
        end
        button_to_add_fields(f, :grouping)
      end

      section do
        check_box_tag(:distinct, "1", false, class: :cbx)
        label_tag(:distinct, "Return distinct records")
      end

      f.submit(class: "border-2")
    end
  end

  private

  def _grouping_fields(f)
    fieldset class: :fields, 'data-object-name border-2 space-y-2': f.object_name do
      legend(escape: false) do
        plain "Match "
        f.combinator_select
        plain " conditions "
        f.button class: "remove_fields border-2", data: {field_type: :grouping} do
          "Remove Fields"
        end
      end
      f.condition_fields do |c|
        _condition_fields(c)
      end
      button_to_add_fields(f, :condition)
      f.grouping_fields do |g|
        _grouping_fields(g)
      end
      # button_to_nest_fields(:grouping)
    end
  end

  def _condition_fields(f)
    fieldset class: "condition_fields fields border-2", 'data-object-name': f.object_name do
      legend do
        f.button class: :remove_fields, data: {field_type: :condition} do
          "Remove Condition"
        end
      end
      f.attribute_fields do |a|
        span(class: :fields, 'data-object-name': a.object_name, escape: false) { a.attribute_select(associations: @condition_associations) }
      end
      f.predicate_select
      f.value_fields do |v|
        span(class: :value_fields, 'data-object-name': v.object_name, escape: false) { v.text_field(:value) }
      end
    end
  end

  def _sort_fields(f)
    div class: :fields, 'data-object-name': f.object_name, escape: false do
      f.sort_select(associations: @sort_associations)

      button class: :remove_fields do
        "Remove"
      end
    end
  end

  def _inspect(obj)
    pre { plain Object.instance_method(:inspect).bind(obj).call }
  end

  def _pretty_inspect(obj)
    pre { plain Object.instance_method(:pretty_inspect).bind(obj).call }
  end

  def button_to_add_fields(f, type)
    new_object, name = f.object.__send__(:"build_#{type}"), :"#{type}_fields"
    fields = capture do
      f.__send__(name, new_object, child_index: "new_#{type}") do |builder|
        __send__(:"_#{name}", builder)
      end
    end

    button class: "add_fields btn border-2", 'data-field-type': type, 'data-content': fields do
      button_label[type]
    end
  end

  def button_label
    { value:     "Add Value",
      condition: "Add Condition",
      sort:      "Add Sort",
      grouping:  "Add Condition Group" }.freeze
  end

  def setup_search_form(builder)
    fields = capture do
      builder.grouping_fields(builder.object.new_grouping, object_name: "new_object_name", child_index: "new_grouping") do |f|
        _grouping_fields(f)
      end
    end
    content_for :document_ready do
      unsafe_raw <<~JAVASCRIPT
        class Search {
          constructor(templates) {
            this.templates = templates != null ? templates : {};
          }
          remove_fields(button) {
            return $(button).closest(".fields").remove();
          }
          add_fields(button, type, content) {
            var new_id, regexp;
            new_id = crypto.randomUUID();
            regexp = new RegExp("new_" + type, "g");
            return $(button).before(content.replace(regexp, new_id));
          }
          nest_fields(button, type) {
            var id_regexp, new_id, object_name, sanitized_object_name, template;
            new_id = crypto.randomUUID();
            id_regexp = new RegExp("new_" + type, "g");
            template = this.templates[type];
            object_name = $(button).closest(".fields").attr("data-object-name");
            sanitized_object_name = object_name
              .replace(/\\]\[|[^-a-zA-Z0-9:.]/g, "_")
              .replace(/_$/, "");
            template = template.replace(/new_object_name\\[/g, object_name + "[");
            template = template.replace(
              /new_object_name_/,
              sanitized_object_name + "_"
            );
            return $(button).before(template.replace(id_regexp, new_id));
          }
        }
        var search = new Search({grouping: "#{helpers.escape_javascript(fields)}"});
        $(document).on("click", "button.add_fields", function() {
          search.add_fields(this, $(this).data('fieldType'), $(this).data('content'));
          return false;
        });
        $(document).on("click", "button.remove_fields", function() {
          search.remove_fields(this);
          return false;
        });
        $(document).on("click", "button.nest_fields", function() {
          search.nest_fields(this, $(this).data('fieldType'));
          return false;
        });
      JAVASCRIPT
    end
  end
end

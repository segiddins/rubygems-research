# frozen_string_literal: true

class VersionDataEntries::SearchView < ApplicationView
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::NumberToHumanSize

  extend Literal::Properties
  prop :version_data_entries, Object
  prop :pagy, Object
  prop :search, Object

  def view_template
    h1 { "Version Data Entries Search" }

    pre { plain @version_data_entries.unscope(:limit, :offset).to_sql }

    render RansackAdvancedSearchComponent.new(
      search: @search,
      search_url: search_version_data_entries_url,
      condition_associations: %i[rubygem server blob_excluding_contents],
      sort_associations: %i[rubygem version blob_excluding_contents]
    )

    render TableComponent.new(contents: @version_data_entries, columns: {
      "Version" => -> { link_to _1.version.full_name, _1.version },
      "Full Name" => -> { _1.full_name },
      "Size" => -> { number_to_human_size _1.blob_excluding_contents.size },
      "SHA" => -> { link_to _1.blob_excluding_contents.sha256, blob_path(_1.blob_excluding_contents.sha256) if _1.blob_excluding_contents },
      "Mode" => -> { _1.mode.to_s(8) },
      "Linkname" => ->(e) { pre { e.linkname } },
      "mtime" => -> { _1.mtime&.to_fs },
      "version.uploaded_at" => -> { _1.version.uploaded_at.to_fs }
    }.merge(columns_in_query))

    unsafe_raw helpers.pagy_nav(@pagy) if @pagy.pages > 1
  end

  private

  def columns_in_query
    cols = {}
    V.new.accept(@version_data_entries.arel.ast, {})
      .each do |attr, _|
          if attr.relation.name == @version_data_entries.arel_table.name
            cols[attr.name] = ->(v) { pre { v[attr.name].inspect } } if attr.name != "*"
          else
            cols["#{attr.relation.name}.#{attr.name}"] = ->(v) { pre do
              v.send(attr.relation.name.chomp("s"))[attr.name].inspect
          rescue ::NoMethodError => e
            pre { e.message }
            p { "attr" }
            pre { attr.pretty_inspect }
          end }
          end
      end
    cols
  end

  class V < Arel::Visitors::Visitor
    def visit_Arel_Nodes_SelectStatement(o, i)
      visit(o.cores, i)
      visit(o.orders, i)
      i
    end

    def visit_Arel_Nodes_SelectCore(o, i)
      visit(o.projections, i)
      visit(o.wheres, i)
      visit(o.windows, i)
      visit(o.groups, i)
      visit(o.havings, i)
    end

    def visit_Arel_Nodes_Ordering(o, i)
      visit(o.expr, i)
    end

    def visit_Arel_Nodes_Unary(o, i)
      visit(o.expr, i)
    end

    def visit_Arel_Nodes_Binary(o, i)
      visit(o.left, i)
      visit(o.right, i)
    end

    def visit_Arel_Nodes_And(o, i)
      o.children.each do |child|
        visit(child, i)
      end
    end

    def visit_Array(o, i)
      o.each { visit(_1, i) }
    end

    def visit_Arel_Nodes_Casted(o, i)
      visit(o.value, i)
      visit(o.attribute, i)
    end

    def visit_Ignore(o, i) = nil
    alias :visit_String :visit_Ignore
    alias :visit_Time :visit_Ignore
    alias :visit_Date :visit_Ignore
    alias :visit_DateTime :visit_Ignore
    alias :visit_NilClass :visit_Ignore
    alias :visit_TrueClass :visit_Ignore
    alias :visit_FalseClass :visit_Ignore
    alias :visit_Integer :visit_Ignore
    alias :visit_BigDecimal :visit_Ignore
    alias :visit_Float :visit_Ignore
    alias :visit_Symbol :visit_Ignore
    alias :visit_Arel_Nodes_SqlLiteral :visit_Ignore

    def visit_Arel_Attributes_Attribute(o, i)
      i[o] = true
    end
  end
end

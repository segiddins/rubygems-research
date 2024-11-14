# frozen_string_literal: true

class TableComponent < ApplicationComponent
extend Literal::Types
  extend Literal::Properties
  prop :contents, Enumerable
  prop :columns, _Nilable(_Hash(String, Proc))

  include Phlex::DeferredRender

  def template
    table do
      thead do
        @columns&.each_key do |column|
          th { column }
        end
      end

      tbody do
        @contents.each do |row|
          tr do
            @columns&.each_value do |column|
              td { column.call(row) }
            end
          end
        end
      end
    end
  end

  def column(header, &block)
    @columns ||= {}
    @columns[header] = block
  end
end

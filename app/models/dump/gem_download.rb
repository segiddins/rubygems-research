class Dump::GemDownload < Dump::Record
  belongs_to :rubygem, class_name: "Dump::Rubygem"
  belongs_to :version, class_name: "Dump::Version"
end

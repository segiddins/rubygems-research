class ZoektIndexGemJob < ApplicationJob
  queue_as :default

  def perform(version:)
    client.post(
      "http://zoekt-index-gem.rubygems-research.orb.local/index-gem",
      {
        name: version.rubygem.name,
        full_name: version.full_name,
        platform: version.platform,
        server: version.rubygem.server.url,
        rubygem_id: version.rubygem_id,
        gem: Base64.encode64(version.package_blob_with_contents.decompressed_contents)
      }
    )
  end

  def client
    @client ||= Faraday.new(
      url: "http://zoekt-index-gem.rubygems-research.orb.local",
      headers: {
        "Content-Type" => "application/json"
      }
    ) do |faraday|
      faraday.request :json
      faraday.response :json, content_type: /\bjson$/
      faraday.adapter Faraday.default_adapter
    end
  end
end

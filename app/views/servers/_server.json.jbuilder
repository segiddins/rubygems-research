json.extract! server, :id, :url, :created_at, :updated_at
json.url server_url(server, format: :json)

json.extract! blob, :id, :sha256, :contents, :size, :compression, :created_at, :updated_at
json.url blob_url(blob, format: :json)

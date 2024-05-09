return if Rails.env.local?

Rails.application.config.cache_store = :mem_cache_store, ENV['MEMCACHED_ENDPOINT'], {
    failover: true,
    socket_timeout: 1.5,
    socket_failure_delay: 0.2,
    compress: true,
    compression_min_size: 524_288,
    value_max_bytes: 2_097_152 # 2MB
  }

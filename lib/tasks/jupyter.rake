namespace :jupyter do
  task :set_path do
    ENV["PATH"] = ["#{Rails.root}/bin", ENV["PATH"]].join(":")
  end
  task install_kernels: :set_path
end

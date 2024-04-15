namespace :jupyter do
  task :set_path do
    ENV["PATH"] = ["#{ENV["HOME"]}/.local/bin", ENV["PATH"]].join(":")
  end
  task install_kernels: :set_path
end

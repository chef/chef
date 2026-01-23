# Load RUNTIME_ENVIRONMENT from .env file
runtime_env_file = File.join(__dir__, "RUNTIME_ENVIRONMENT")
if File.exist?(runtime_env_file)
  File.readlines(runtime_env_file).each do |line|
    line = line.strip
    next if line.empty? || line.start_with?("#")
    key, value = line.split("=", 2)
    ENV[key] = value if key && value
  end
end

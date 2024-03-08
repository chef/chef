mount "/proc" do
  device "proc"
  fstype "proc"
  options %w{bind rw}
  action %i{ mount enable }
end

mount "/mnt" do
  device "/usr/local"
  fstype "ext4"
  options %w{bind rw}
  action %i{ mount enable }
end

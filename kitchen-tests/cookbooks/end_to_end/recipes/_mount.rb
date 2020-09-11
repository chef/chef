mount "/proc" do
  device "proc"
  fstype "proc"
  options %w{bind rw}
  action %i{ mount enable }
end

mount "/mnt" do
  device "/tmp"
  fstype "ext4"
  options %w{bind rw}
  action %i{ mount enable }
end

mount "/mnt" do
  device "/etc"
  fstype "ext4"
  options %w{bind rw}
  action %i{ mount enable }
end

mount "/proc" do
  device "proc"
  action %i{ disable unmount }
end

mount "/mnt" do
  device "/tmp"
  action %i{ disable unmount }
end

mount "/mnt" do
  device "/etc"
  action %i{ disable unmount }
end

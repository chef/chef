require 'digest/md5'
require 'fileutils'

module MetricFu
  class MD5Tracker

    @@unchanged_md5s = []

    class << self
      def md5_dir(path_to_file, base_dir)
        File.join(base_dir,
                  path_to_file.split('/')[0..-2].join('/'))
      end

      def md5_file(path_to_file, base_dir)
        File.join(md5_dir(path_to_file, base_dir),
                  path_to_file.split('/').last.sub(/\.[a-z]+/, '.md5'))
      end

      def track(path_to_file, base_dir)
        md5 = Digest::MD5.hexdigest(File.read(path_to_file))
        FileUtils.mkdir_p(md5_dir(path_to_file, base_dir), :verbose => false)
        f = File.new(md5_file(path_to_file, base_dir), "w")
        f.puts(md5)
        f.close
        md5
      end

      def file_changed?(path_to_file, base_dir)
        orig_md5_file = md5_file(path_to_file, base_dir)
        return !!track(path_to_file, base_dir) unless File.exist?(orig_md5_file)

        current_md5 = ""
        file = File.open(orig_md5_file, 'r')
        file.each_line { |line| current_md5 << line }
        file.close
        current_md5.chomp!

        new_md5 = Digest::MD5.hexdigest(File.read(path_to_file))
        new_md5.chomp!

        @@unchanged_md5s << path_to_file if new_md5 == current_md5

        return new_md5 != current_md5
      end

      def file_already_counted?(path_to_file)
        return @@unchanged_md5s.include?(path_to_file)
      end
    end
  end
end
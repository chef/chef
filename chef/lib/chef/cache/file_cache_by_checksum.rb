class Chef
  class Cache
    class FileCacheByChecksum
      attr_reader :basedir
      
      def initialize(basedir = Chef::Config[:file_cache_path])
        @basedir = basedir
        
        
      end

      # returns path
      def get_path(checksum)
        path = checksum_path(checksum)
        
        File.exists?(path) ? path : nil
      end
      
      # path = path to tempfile as input
      # returns destination path
      def put(checksum, src_path)
        dest_path = checksum_path(checksum)
        FileUtils.mkdir_p(File.dirname(dest_path))
      
        FileUtils.cp(src_path, dest_path)
        
        dest_path
      end
      
      def checksum_path(checksum)
        File.join(@basedir, checksum[0..1], checksum)
      end
    end
  end
end

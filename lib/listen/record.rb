module Listen
  class Record
    include Celluloid

    attr_accessor :paths, :listener, :last_build_at

    def initialize(listener)
      @listener = listener
      @paths    = _init_paths
    end

    def set_path(path, data)
      @paths[::File.dirname(path)][::File.basename(path)] = file_data(path).merge(data)
    end

    def unset_path(path)
      @paths[::File.dirname(path)].delete(::File.basename(path))
    end

    def file_data(path)
      @paths[::File.dirname(path)][::File.basename(path)] || {}
    end

    def dir_entries(path)
      @paths[path.to_s]
    end

    def build
      @last_build_at = nil
      @paths = _init_paths
      listener.directories.each do |path|
        listener.registry[:change_pool].change(path, type: 'Dir', recursive: true, silence: true, build: true)
      end
    end

    def built!
      @last_build_at = Time.now
    end

    def when_built
      sleep 0.01 until !last_build_at.nil? && last_build_at + 0.1 < Time.now
      yield
    end

    private

    def _init_paths
      Hash.new { |h, k| h[k] = Hash.new }
    end
  end
end

# frozen_string_literal: true

module FileStore
  class DownloadError < StandardError; end

  class BaseStore
    UPLOAD_PATH_REGEX = %r{/(original/\d+X/.*)}
    OPTIMIZED_PATH_REGEX = %r{/(optimized/\d+X/.*)}
    TEMP_UPLOAD_PATH_REGEX = "tmp/uploads"

    def upload_path
      path = File.join(Rails.root, "public", "uploads")
      FileUtils.mkdir_p(path)
      path
    end

    def store_file(_file, _path)
      not_implemented
    end

    def delete_file(_path)
      not_implemented
    end

    def download_file(_path)
      not_implemented
    end

    def not_implemented
      raise NotImplementedError, "This method must be implemented by subclasses"
    end
  end
end

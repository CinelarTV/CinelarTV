# frozen_string_literal: true

module FileStore
  class LocalStore < BaseStore
    def store_file(file, path)
      copy_file(file, path)
      "uploads/#{path}"
    end

    def copy_file(file, path)
      dir = Pathname.new(path).dirname
      FileUtils.mkdir_p(dir)
      FileUtils.open(path, "wb") { |f| f.write(file.read) }
    end

    def relative?(url)
      url.present? && (!url.start_with?("http://") && !url.start_with?("https://"))
    end

    def external?
      false # Uploads from LocalStore are always internal
    end

    def delete_file(path); end

    def download_file(path)
      File.open(path, "rb")
    end
  end
end

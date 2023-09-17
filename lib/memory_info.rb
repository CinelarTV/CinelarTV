# frozen_string_literal: true

class MemoryInfo
  # Returns the total memory in kilobytes, or nil if it can't be determined.
  def total_memory
    @total_memory ||= begin
      if RbConfig::CONFIG["host_os"] =~ /mswin|mingw|cygwin/
        # En Windows, utiliza el comando wmic para obtener información de memoria
        s = `wmic os get TotalVisibleMemorySize /value`
        s.split("=")[1].to_i
      else
        # En sistemas Unix, intenta obtener la información de /proc/meminfo
        s = `grep MemTotal /proc/meminfo`
        /(\d+)/.match(s)[0].try(:to_i)
      end
    rescue StandardError
      nil
    end
  end
end

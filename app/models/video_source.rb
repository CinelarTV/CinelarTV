# frozen_string_literal: true

class VideoSource < ApplicationRecord
  belongs_to :videoable, polymorphic: true

  validates :quality, presence: true
  validates :format, presence: true
  validates :storage_location, presence: true
  # url is validated in the custom validation method

  attr_accessor :video_link_or_file

  enum storage_location: {
    local: "local",
    s3: "cloud",
  }

  enum format: {
    mp4: "mp4",
    m3u8: "m3u8",
  }

  # If the format is m3u8, the quality is adaptative

  enum quality: {
    "144": "144p",
    "240": "240p",
    "360": "360p",
    "480": "480p",
    "720": "720p",
    "1080": "1080p",
    "1440": "1440p",
    "2160": "2160p",
    adaptative: "adaptative",
    legacy: "legacy",
  }

  # Validaciones personalizadas para el enlace o el archivo subido
  validate :validate_video_link_or_file

  private

  def validate_video_link_or_file
    if @video_link_or_file.present?
      # Aquí puedes agregar lógica para manejar el enlace o el archivo subido
      # Por ejemplo, puedes verificar si es un enlace válido o un archivo subido
      # y asignar la URL o realizar la lógica necesaria.
      # Puedes personalizar esta parte según tus necesidades.
      if valid_link?(@video_link_or_file)
        self.url = @video_link_or_file # Asigna el enlace como URL
        self.storage_location = "cloud" # Marca como almacenado en remoto
      elsif @video_link_or_file.is_a?(ActionDispatch::Http::UploadedFile)
        self.url = process_uploaded_file(@video_link_or_file) # Asigna la URL generada por el transcoder
        self.storage_location = "local" # Marca como almacenado en local
      else
        errors.add(:video_link_or_file, "Formato de video no válido")
      end
    else
      errors.add(:video_link_or_file, "Debe proporcionar un enlace o un archivo")
    end
  end

  def valid_link?(link)
    # Aquí puedes agregar lógica para verificar si el enlace es válido
    # Por ejemplo, puedes verificar si el enlace es de YouTube, Vimeo, etc.
    # Puedes personalizar esta parte según tus necesidades.
    # En este ejemplo, solo se verifica que el enlace no esté vacío.
    link.present?
  end

  def process_uploaded_file(file)
    # Genera un nombre único para el archivo, por ejemplo, usando el timestamp
    unique_filename = "#{Time.now.to_i}_#{file.original_filename}"

    # Define la ruta temporal donde se almacenará el archivo
    temp_storage_path = Rails.root.join("tmp", "video_upload", unique_filename).to_s

    # Guarda el archivo en la carpeta temporal
    File.open(temp_storage_path, "wb") do |f|
      f.write(file.read)
    end

    # Aquí puedes implementar la lógica para usar el transcoder y generar el M3U8
    # Esta lógica dependerá de las herramientas y bibliotecas que utilices para la transcodificación

    # Por ejemplo, si utilizas ffmpeg para generar el M3U8 y los archivos TS:
    # `ffmpeg -i #{temp_storage_path} -hls_time 10 -hls_list_size 0 #{temp_storage_path}.m3u8`

    # Define la ruta de la carpeta final donde se almacenarán los archivos transcodificados
    final_storage_folder = Rails.root.join("public", "uploads", unique_filename).to_s

    # Crea la carpeta final si no existe
    FileUtils.mkdir_p(final_storage_folder)

    # Define la ruta del archivo M3U8 en la carpeta final
    final_m3u8_path = File.join(final_storage_folder, "#{unique_filename}.m3u8")

    # Ejecuta el comando para generar el M3U8 y los archivos TS en la carpeta final
    # Reemplaza esto con la lógica específica para tu transcodificador
    # Ejemplo ficticio: `ffmpeg -i #{temp_storage_path} -hls_time 10 -hls_list_size 0 #{final_m3u8_path}`

    # Mueve el archivo M3U8 y los archivos TS generados a la carpeta final
    FileUtils.mv("#{temp_storage_path}.m3u8", final_m3u8_path)
    # Mueve los archivos TS generados en la carpeta temporal a la carpeta final
    FileUtils.mv(Dir.glob("#{temp_storage_path}*.ts"), final_storage_folder)

    # Retorna la URL del archivo M3U8 en la carpeta final
    "/uploads/#{unique_filename}/#{unique_filename}.m3u8"
  end
end

# frozen_string_literal: true

# db/seeds.rb - Seed script for CinelarTV
# Run with: rails db:seed

puts "Seeding database..."

# Create default Doorkeeper application for API auth
unless Doorkeeper::Application.exists?(name: "Default API Client")
  Doorkeeper::Application.create!(
    name: "Default API Client",
    redirect_uri: "urn:ietf:wg:oauth:2.0:oob",
    scopes: "read write",
    confidential: false
  )
  puts "Created default Doorkeeper application"
else
  puts "Default Doorkeeper application already exists"
end

# --- Content Ratings ---
puts "Seeding content ratings..."

content_ratings_data = [
  # Custom system (primary)
  { code: "ALL",   system: "custom", min_age: 0,  name_translations: { "es" => "Para todos", "en" => "All ages" }, description_translations: { "es" => "Apto para todas las edades", "en" => "Suitable for all ages" } },
  { code: "ALL7",  system: "custom", min_age: 7,  name_translations: { "es" => "7+", "en" => "7+" }, description_translations: { "es" => "No recomendado menores de 7", "en" => "Not recommended under 7" } },
  { code: "ALL10", system: "custom", min_age: 10, name_translations: { "es" => "10+", "en" => "10+" }, description_translations: { "es" => "No recomendado menores de 10", "en" => "Not recommended under 10" } },
  { code: "ALL13", system: "custom", min_age: 13, name_translations: { "es" => "13+", "en" => "13+" }, description_translations: { "es" => "No recomendado menores de 13", "en" => "Not recommended under 13" } },
  { code: "ALL16", system: "custom", min_age: 16, name_translations: { "es" => "16+", "en" => "16+" }, description_translations: { "es" => "No recomendado menores de 16", "en" => "Not recommended under 16" } },
  { code: "ALL18", system: "custom", min_age: 18, name_translations: { "es" => "18+", "en" => "18+" }, description_translations: { "es" => "Solo adultos", "en" => "Adults only" } },
  # MPAA reference (for TMDB auto-import mapping)
  { code: "G",     system: "MPAA", min_age: 0,  name_translations: { "es" => "TP", "en" => "G" }, description_translations: { "es" => "Todo público", "en" => "General audiences" } },
  { code: "PG",    system: "MPAA", min_age: 8,  name_translations: { "es" => "PG", "en" => "PG" }, description_translations: { "es" => "Guía parental sugerida", "en" => "Parental guidance suggested" } },
  { code: "PG-13", system: "MPAA", min_age: 13, name_translations: { "es" => "13+", "en" => "PG-13" }, description_translations: { "es" => "No recomendado menores de 13", "en" => "Parents strongly cautioned" } },
  { code: "R",     system: "MPAA", min_age: 17, name_translations: { "es" => "17+", "en" => "R" }, description_translations: { "es" => "Restringido menores de 17", "en" => "Restricted" } },
  { code: "NC-17", system: "MPAA", min_age: 18, name_translations: { "es" => "18+", "en" => "NC-17" }, description_translations: { "es" => "Solo adultos", "en" => "Adults only" } },
  # ICAA (Spain)
  { code: "ICAA-TP",  system: "ICAA", min_age: 0,  name_translations: { "es" => "TP", "en" => "TP" }, description_translations: { "es" => "Todo público", "en" => "General audiences" } },
  { code: "ICAA-7",   system: "ICAA", min_age: 7,  name_translations: { "es" => "7", "en" => "7" }, description_translations: { "es" => "No recomendado menores de 7", "en" => "Not recommended under 7" } },
  { code: "ICAA-12",  system: "ICAA", min_age: 12, name_translations: { "es" => "12", "en" => "12" }, description_translations: { "es" => "No recomendado menores de 12", "en" => "Not recommended under 12" } },
  { code: "ICAA-16",  system: "ICAA", min_age: 16, name_translations: { "es" => "16", "en" => "16" }, description_translations: { "es" => "No recomendado menores de 16", "en" => "Not recommended under 16" } },
  { code: "ICAA-18",  system: "ICAA", min_age: 18, name_translations: { "es" => "18", "en" => "18" }, description_translations: { "es" => "Solo adultos", "en" => "Adults only" } },
  # INCAA (Argentina)
  { code: "ATP",  system: "INCAA", min_age: 0,  name_translations: { "es" => "ATP", "en" => "ATP" }, description_translations: { "es" => "Apto para todo público", "en" => "Suitable for all audiences" } },
  { code: "INCAA-13", system: "INCAA", min_age: 13, name_translations: { "es" => "13", "en" => "13" }, description_translations: { "es" => "No recomendado menores de 13", "en" => "Not recommended under 13" } },
  { code: "INCAA-16", system: "INCAA", min_age: 16, name_translations: { "es" => "16", "en" => "16" }, description_translations: { "es" => "No recomendado menores de 16", "en" => "Not recommended under 16" } },
  { code: "INCAA-18", system: "INCAA", min_age: 18, name_translations: { "es" => "18", "en" => "18" }, description_translations: { "es" => "Solo adultos", "en" => "Adults only" } },
  { code: "INCAA-18+", system: "INCAA", min_age: 18, name_translations: { "es" => "18+", "en" => "18+" }, description_translations: { "es" => "Exclusivamente adultos", "en" => "Adults exclusively" } },
]

content_ratings_data.each do |attrs|
  ContentRating.find_or_create_by!(code: attrs[:code]) do |cr|
    cr.assign_attributes(attrs)
  end
end
puts "  Created #{ContentRating.count} content ratings"

# --- Content Descriptors ---
puts "Seeding content descriptors..."

content_descriptors_data = [
  { key: "violence",         category: "violencia",  severity_level: 2, name_translations: { "es" => "Escenas de violencia", "en" => "Violence" }, description_translations: { "es" => "Contiene escenas de violencia", "en" => "Contains scenes of violence" } },
  { key: "graphic_violence", category: "violencia",  severity_level: 3, name_translations: { "es" => "Violencia gráfica", "en" => "Graphic violence" }, description_translations: { "es" => "Contiene violencia gráfica", "en" => "Contains graphic violence" } },
  { key: "language",         category: "lenguaje",   severity_level: 1, name_translations: { "es" => "Lenguaje malsonante", "en" => "Strong language" }, description_translations: { "es" => "Contiene lenguaje malsonante", "en" => "Contains strong language" } },
  { key: "nudity",           category: "sexual",     severity_level: 2, name_translations: { "es" => "Escenas de desnudez", "en" => "Nudity" }, description_translations: { "es" => "Contiene escenas de desnudez", "en" => "Contains nudity" } },
  { key: "sexual_scenes",    category: "sexual",     severity_level: 3, name_translations: { "es" => "Escenas sexuales", "en" => "Sexual scenes" }, description_translations: { "es" => "Contiene escenas sexuales", "en" => "Contains sexual scenes" } },
  { key: "sexual_refs",      category: "sexual",     severity_level: 1, name_translations: { "es" => "Referencias sexuales", "en" => "Sexual references" }, description_translations: { "es" => "Contiene referencias sexuales", "en" => "Contains sexual references" } },
  { key: "alcohol_drugs",    category: "sustancias", severity_level: 2, name_translations: { "es" => "Consumo de alcohol o drogas", "en" => "Alcohol/drug use" }, description_translations: { "es" => "Muestra consumo de alcohol o drogas", "en" => "Shows alcohol or drug use" } },
  { key: "adult_themes",     category: "temas",      severity_level: 2, name_translations: { "es" => "Temas adultos", "en" => "Adult themes" }, description_translations: { "es" => "Contiene temas para adultos", "en" => "Contains adult themes" } },
  { key: "fear",             category: "miedo",      severity_level: 2, name_translations: { "es" => "Miedo o contenido perturbador", "en" => "Fear/disturbing content" }, description_translations: { "es" => "Contiene escenas de miedo o perturbadoras", "en" => "Contains fear or disturbing content" } },
  { key: "horror",           category: "miedo",      severity_level: 3, name_translations: { "es" => "Terror intenso", "en" => "Intense horror" }, description_translations: { "es" => "Contiene terror intenso", "en" => "Contains intense horror" } },
]

content_descriptors_data.each do |attrs|
  ContentDescriptor.find_or_create_by!(key: attrs[:key]) do |cd|
    cd.assign_attributes(attrs)
  end
end
puts "  Created #{ContentDescriptor.count} content descriptors"

puts "Seeding complete!"

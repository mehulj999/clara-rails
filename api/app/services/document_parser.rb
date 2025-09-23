# app/services/document_parser.rb
class DocumentParser
  Parsed = Struct.new(:kind, :parser_name, :attrs, keyword_init: true)
  # kind: :contract | :unknown

  # hints is a Hash with optional keys:
  #   :domain => "contract"
  #   :subtype => "mobile" | "internet" | "gym" | "insurance"
  #   :provider => "o2" | "lebara" | "vodafone" | ...
  #
  # io_or_path: Tempfile path or string path
  def self.parse(io_or_path, hints: {})
    domain = hints[:domain]&.to_s
    case domain
    when "contract"
      parsed = Parsers::Contracts::Registry.parse(io_or_path, hints: hints)
      return Parsed.new(kind: :contract, parser_name: parsed[:parser_name], attrs: parsed[:attrs]) if parsed
    else
      # other domains (e.g., statement) would go here later
    end

    # If nothing matched:
    Parsed.new(kind: :unknown, parser_name: nil, attrs: {})
  end
end

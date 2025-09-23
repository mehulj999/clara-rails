# app/services/parsers/base.rb
module Parsers
  class Base
    # Return true/false based on text
    def can_handle?(_text)
      false
    end

    # Extract attributes from text; return Hash
    def extract(_text)
      {}
    end
  end
end
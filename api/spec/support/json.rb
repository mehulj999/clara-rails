module JsonHelpers
  def json
    JSON.parse(response.body)
  end
end

RSpec.configure do |c|
  c.include JsonHelpers, type: :request
end

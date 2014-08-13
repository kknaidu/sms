#NOTE these records are present in the central database
#and are used for translating the domain names
class Domain
  include Mongoid::Document

  field :_id, type: String #domain for lookup

  field :subdomain

end


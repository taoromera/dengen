class Goodbad < ActiveRecord::Base
  belongs_to :spot
  attr_accessible :token, :good
end

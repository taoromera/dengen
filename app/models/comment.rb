class Comment < ActiveRecord::Base
  belongs_to :spot
  attr_accessible :content
end

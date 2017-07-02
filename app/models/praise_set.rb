class PraiseSet < ActiveRecord::Base
  has_many :praise_set_songs, -> { order(position: :asc) }
  has_many :songs, :through => :praise_set_songs

  belongs_to :owner, :foreign_key => "owner_email", :primary_key => "email", :class_name => "User"

  validates :event_name, presence: true
  validates :event_date, presence: true
  validates :owner_email, presence: true
end

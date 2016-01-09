class Hostgroup < ActiveRecord::Base
  validates :name, presence: true, uniqueness: true
  validates :hostgroup_id, presence: true, numericality: { only_integer: true }

  has_many :hosts, dependent: :delete_all
end

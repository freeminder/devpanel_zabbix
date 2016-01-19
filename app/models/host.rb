class Host < ActiveRecord::Base
  validates :name,  presence: true, uniqueness: true
  validates :ip,    presence: true
  # validates :dns,   presence: true
  validates :port,  presence: true, numericality: { only_integer: true }

  belongs_to :hostgroup
end

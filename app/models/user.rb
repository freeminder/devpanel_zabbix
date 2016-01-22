class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  #  :registerable,
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable
  
  validates :email, presence: true, uniqueness: true
  # has_secure_password
  # validates :password, presence: true, confirmation: true, length: { minimum: 8 }
  
  belongs_to :team
end

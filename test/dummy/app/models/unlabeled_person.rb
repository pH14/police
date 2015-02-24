class UnlabeledPerson < ActiveRecord::Base
  validates :name, presence: true

  validates_numericality_of :age

  validates :email, format: {
      with: /\A[A-Za-z0-9.+_-]+\@[A-Za-z0-9.\-]+\.edu\Z/,
      message: 'needs to be an .edu e-mail address' }
end

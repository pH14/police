# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

include ActionDispatch::TestProcess  # Want fixture_file_upload.

# Course.

puts 'Starting seeds'

# Site admin.
admin = User.create! email: 'pwh@mit.edu', password: 'mit', password_confirmation: 'mit'
admin.email_credential.verified = true
admin.save!

puts 'Admin created'

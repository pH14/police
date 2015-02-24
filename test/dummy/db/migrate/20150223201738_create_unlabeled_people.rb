class CreateUnlabeledPeople < ActiveRecord::Migration
  def change
    create_table :unlabeled_people do |t|
      t.string :name
      t.integer :age
      t.string :email

      t.timestamps
    end
  end
end

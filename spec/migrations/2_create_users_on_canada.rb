class CreateUsersOnCanada < ActiveRecord::Migration
  using_shard(:canada)

  def self.up
    User.create!(:name => 'Sharding')
  end

  def self.down
    User.delete_all
  end
end

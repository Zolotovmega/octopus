class CreateUsersUsingBlockAndUsing < ActiveRecord::Migration
  using_shard(:brazil)

  def self.up
    Octopus.using_shard(:canada) do
      User.create!(:name => 'Canada')
    end

    User.create!(:name => 'Brazil')
  end

  def self.down
    User.delete_all
  end
end

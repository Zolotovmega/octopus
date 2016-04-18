require 'spec_helper'

describe Octopus::Migration do
  it 'should run just in the master shard' do
    OctopusHelper.migrating_to_version 1 do
      expect(User.using_shard(:master).find_by_name('Master')).not_to be_nil
      expect(User.using_shard(:canada).find_by_name('Master')).to be_nil
    end
  end

  it 'should run on specific shard' do
    OctopusHelper.migrating_to_version 2 do
      expect(User.using_shard(:master).find_by_name('Sharding')).to be_nil
      expect(User.using_shard(:canada).find_by_name('Sharding')).not_to be_nil
    end
  end

  it 'should run on specifieds shards' do
    OctopusHelper.migrating_to_version 3 do
      expect(User.using_shard(:brazil).find_by_name('Both')).not_to be_nil
      expect(User.using_shard(:canada).find_by_name('Both')).not_to be_nil
    end
  end

  it 'should run on specified group' do
    OctopusHelper.migrating_to_version 4 do
      expect(User.using_shard(:canada).find_by_name('Group')).not_to be_nil
      expect(User.using_shard(:brazil).find_by_name('Group')).not_to be_nil
      expect(User.using_shard(:russia).find_by_name('Group')).not_to be_nil
    end
  end

  it 'should run once per shard' do
    OctopusHelper.migrating_to_version 5 do
      expect(User.using_shard(:canada).where(:name => 'MultipleGroup').size).to eq(1)
      expect(User.using_shard(:brazil).where(:name => 'MultipleGroup').size).to eq(1)
      expect(User.using_shard(:russia).where(:name => 'MultipleGroup').size).to eq(1)
    end
  end

  it 'should create users inside block' do
    OctopusHelper.migrating_to_version 12 do
      expect(User.using_shard(:brazil).where(:name => 'UsingBlock1').size).to eq(1)
      expect(User.using_shard(:brazil).where(:name => 'UsingBlock2').size).to eq(1)
      expect(User.using_shard(:canada).where(:name => 'UsingCanada').size).to eq(1)
      expect(User.using_shard(:canada).where(:name => 'UsingCanada2').size).to eq(1)
    end
  end

  it 'should send the query to the correct shard' do
    OctopusHelper.migrating_to_version 13 do
      expect(User.using_shard(:brazil).where(:name => 'Brazil').size).to eq(1)
      expect(User.using_shard(:brazil).where(:name => 'Canada').size).to eq(0)
      expect(User.using_shard(:canada).where(:name => 'Brazil').size).to eq(0)
      expect(User.using_shard(:canada).where(:name => 'Canada').size).to eq(1)
    end
  end

  describe 'when using replication' do
    it 'should run writes on master when you use replication' do
      OctopusHelper.using_environment :production_replicated do
        OctopusHelper.migrating_to_version 10 do
          expect(Cat.find_by_name('Replication')).to be_nil
        end
      end
    end

    it 'should run in all shards, master or another shards' do
      OctopusHelper.using_environment :production_replicated do
        OctopusHelper.migrating_to_version 11 do
          [:slave4, :slave1, :slave2, :slave3].each do |_sym|
            expect(Cat.find_by_name('Slaves')).not_to be_nil
          end
        end
      end
    end
  end

  it 'should store the migration versions in each shard' do
    class SchemaMigration < ActiveRecord::Base; end

    OctopusHelper.migrating_to_version 14 do
      expect(Octopus.using_shard(:canada) { ActiveRecord::Migrator.get_all_versions }).to include(14)
      expect(Octopus.using_shard(:brazil) { ActiveRecord::Migrator.get_all_versions }).to include(14)
      expect(Octopus.using_shard(:russia) { ActiveRecord::Migrator.get_all_versions }).to include(14)
    end
  end

  it 'should run the migrations on shards that are missing them' do
    class SchemaMigration < ActiveRecord::Base; end

    Octopus.using_shard(:master) { SchemaMigration.create(:version => 14) }
    Octopus.using_shard(:canada) { SchemaMigration.create(:version => 14) }

    OctopusHelper.migrating_to_version 14 do
      expect(Octopus.using_shard(:canada) { ActiveRecord::Migrator.get_all_versions }).to include(14)
      expect(Octopus.using_shard(:brazil) { ActiveRecord::Migrator.get_all_versions }).to include(14)
      expect(Octopus.using_shard(:russia) { ActiveRecord::Migrator.get_all_versions }).to include(14)
    end
  end

  describe 'when using a default_migration_group' do
    it 'should run migrations on all shards in the default_migration_group' do
      OctopusHelper.using_environment :octopus_with_default_migration_group do
        OctopusHelper.migrating_to_version 15 do
          expect(Octopus.using_shard(:master) { ActiveRecord::Migrator.get_all_versions }).not_to include(15)
          expect(Octopus.using_shard(:canada) { ActiveRecord::Migrator.get_all_versions }).to include(15)
          expect(Octopus.using_shard(:brazil) { ActiveRecord::Migrator.get_all_versions }).to include(15)
          expect(Octopus.using_shard(:russia) { ActiveRecord::Migrator.get_all_versions }).to include(15)
        end
      end
    end
  end

end

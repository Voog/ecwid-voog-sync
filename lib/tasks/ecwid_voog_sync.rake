namespace :ecwid_voog_sync do
  desc 'Synchronize changed products information'
  task sync: :environment do
    Synchronizer.new.sync!
  end

  desc 'Forced synchronization for all products'
  task full_sync: :environment do
    Synchronizer.new.sync!(forced_update: true)
  end

  desc 'Synchronize catalogs'
  task sync_catalogs: :environment do
    Synchronizer.new.sync_categories!
  end
end

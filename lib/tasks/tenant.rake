# Tenant tasks
namespace :tenant do
  namespace :agg do
    # Create aggregation schema
    desc 'Create the aggregation schema'
    task create: :environment do
      Ekylibre::Tenant.create_aggregation_schema!
    end

    # Drop aggregation schema
    desc 'Drop the aggregation schema'
    task drop: :environment do
      Ekylibre::Tenant.drop_aggregation_schema!
    end
  end

  desc 'Drop a tenant (with TENANT variable)'
  task drop: :environment do
    name = ENV['TENANT'] || ENV['name']
    if Ekylibre::Tenant.exist?(name)
      puts "Drop tenant: #{name.inspect.red}"
      Ekylibre::Tenant.drop(name)
    else
      puts "Unknown tenant: #{name.inspect.red}"
    end
  end

  desc 'Create a tenant (with TENANT variable)'
  task create: :environment do
    name = ENV['TENANT'] || ENV['name']
    Ekylibre::Tenant.create(name) unless Ekylibre::Tenant.exist?(name)
  end

  desc 'Create a tenant with alone admin user (with TENANT, EMAIL, PASSWORD variable)'
  task init: :environment do
    tenant = ENV['TENANT']
    raise 'Need TENANT variable' unless tenant
    Ekylibre::Tenant.create(tenant) unless Ekylibre::Tenant.exist?(tenant)
    Ekylibre::Tenant.switch(tenant) do
      # Set basic preferences
      Preference.set! :language, ENV['LANGUAGE'] || 'fra'
      Preference.set! :country, ENV['COUNTRY'] || 'fr'
      Preference.set! :currency, ENV['CURRENCY'] || 'EUR'
      Preference.set! :map_measure_srs, ENV['MAP_MEASURE_SRS'] || ENV['SRS'] || 'WGS84'
      # Add user
      email = ENV['EMAIL'] || 'admin@ekylibre.org'
      user = User.find_by(email: email)
      if user
        puts 'No user created. Already initialized.'
      else
        attributes = {
          email: email,
          administrator: true,
          password: ENV['PASSWORD'] || '12345678',
          first_name: ENV['FIRST_NAME'] || 'Admin',
          last_name: ENV['LAST_NAME'] || tenant
        }
        attributes[:password_confirmation] = attributes[:password]
        User.create!(attributes)
        puts "Initialized with account #{email}."
        puts "Password is: #{attributes[:password]}" unless ENV['PASSWORD']
      end
    end
  end

  desc 'Rename a tenant (with OLD/NEW variables)'
  task rename: :environment do
    old = ENV['OLD'] || ENV['name']
    new = ENV['NEW']
    if Ekylibre::Tenant.exist?(old)
      Ekylibre::Tenant.rename(old, new)
    else
      puts "Unknown tenant: #{old.inspect.red}"
    end
  end

  task :clear do
    require 'ekylibre/tenant'
    Ekylibre::Tenant.clear!
  end

  task dump: :environment do
    archive = ENV['ARCHIVE'] || ENV['archive']
    tenant = ENV['TENANT'] || ENV['name']
    raise 'Need TENANT env variable to dump' unless tenant
    options = {}
    options[:path] = Pathname.new(archive) if archive
    Ekylibre::Tenant.dump(tenant, options)
  end

  task restore: :environment do
    archive = ENV['ARCHIVE'] || ENV['archive']
    tenant = ENV['TENANT'] || ENV['name']
    options = {}
    if tenant.present?
      archive ||= Rails.root.join('tmp', 'archives', "#{tenant}.zip")
      options[:tenant] = tenant
    end
    raise 'Need ARCHIVE env variable to find archive' unless archive
    Ekylibre::Tenant.restore(archive, options)
  end

  namespace :restore do
    task easy_login: :restore do
      Ekylibre::Tenant.switch!(ENV['TENANT'] || ENV['name'])
      puts
      puts '== ' + 'Modifying User'.yellow + '=' * 61
      User.first.update!(email: 'admin@ekylibre.org', password: '12345678')
      puts
      puts 'Done!'.yellow
      puts
    end
  end

  desc 'List tenants'
  task list: :environment do
    puts Ekylibre::Tenant.list.join(', ') if Ekylibre::Tenant.list.any?
  end
end

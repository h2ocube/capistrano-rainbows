require 'capistrano'

module CapistranoRainbows
  class CapistranoIntegration
    TASKS = [
      'rainbows:start',
      'rainbows:stop',
      'rainbows:restart',
      'rainbows:duplicate',
      'rainbows:reload',
      'rainbows:shutdown',
      'rainbows:add_worker',
      'rainbows:remove_worker'
    ]

    def self.load_into(capistrano_config)
      capistrano_config.load do
        before(CapistranoIntegration::TASKS) do
          _cset(:app_env)                    { (fetch(:rails_env) rescue 'production') }
          _cset(:rainbows_pid)                { "#{fetch(:current_path)}/tmp/pids/rainbows.pid" }
          _cset(:rainbows_env)                { fetch(:app_env) }
          _cset(:rainbows_bin)                { "rainbows" }
          _cset(:rainbows_bundle)             { fetch(:bundle_cmd) rescue 'bundle' }
          _cset(:rainbows_restart_sleep_time) { 2 }
          _cset(:rainbows_user)               { nil }
          _cset(:rainbows_config_path)        { "#{fetch(:current_path)}/config" }
          _cset(:rainbows_config_filename)    { "rainbows.rb" }
        end

        # Check if a remote process exists using its pid file
        #
        def remote_process_exists?(pid_file)
          "[ -e #{pid_file} ] && #{try_rainbows_user} kill -0 `cat #{pid_file}` > /dev/null 2>&1"
        end

        # Stale rainbows process pid file
        #
        def old_rainbows_pid
          "#{rainbows_pid}.oldbin"
        end

        # Command to check if rainbows is running
        #
        def rainbows_is_running?
          remote_process_exists?(rainbows_pid)
        end

        # Command to check if stale rainbows is running
        #
        def old_rainbows_is_running?
          remote_process_exists?(old_rainbows_pid)
        end

        # Get rainbows master process PID (using the shell)
        #
        def get_rainbows_pid(pid_file=rainbows_pid)
          "`cat #{pid_file}`"
        end

        # Get rainbows master (old) process PID
        #
        def get_old_rainbows_pid
          get_rainbows_pid(old_rainbows_pid)
        end

        # Send a signal to a rainbows master processes
        #
        def rainbows_send_signal(signal, pid=get_rainbows_pid)
          "#{try_rainbows_user} kill -s #{signal} #{pid}"
        end

        # Run a command as the :rainbows_user user if :rainbows_user is a string.
        # Otherwise run as default (:user) user.
        #
        def try_rainbows_user
          "#{sudo :as => rainbows_user.to_s}" if rainbows_user.kind_of?(String)
        end

        # Kill rainbowss in multiple ways O_O
        #
        def kill_rainbows(signal)
          script = <<-END
            if #{rainbows_is_running?}; then
              echo "Stopping rainbows...";
              #{rainbows_send_signal(signal)};
            else
              echo "rainbows is not running.";
            fi;
          END

          script
        end

        # Start the rainbows server
        #
        def start_rainbows
          primary_config_path = "#{rainbows_config_path}/#{rainbows_config_filename}"
          secondary_config_path = "#{rainbows_config_path}/rainbows/#{rainbows_env}.rb"

          script = <<-END
            if [ -e #{primary_config_path} ]; then
              rainbows_CONFIG_PATH=#{primary_config_path};
            else
              if [ -e #{secondary_config_path} ]; then
                rainbows_CONFIG_PATH=#{secondary_config_path};
              else
                echo "Config file for \"#{rainbows_env}\" environment was not found at either \"#{primary_config_path}\" or \"#{secondary_config_path}\"";
                exit 1;
              fi;
            fi;

            if [ -e #{rainbows_pid} ]; then
              if #{try_rainbows_user} kill -0 `cat #{rainbows_pid}` > /dev/null 2>&1; then
                echo "rainbows is already running!";
                exit 0;
              fi;

              #{try_rainbows_user} rm #{rainbows_pid};
            fi;

            echo "Starting rainbows...";
            cd #{current_path} && #{try_rainbows_user} BUNDLE_GEMFILE=#{current_path}/Gemfile #{rainbows_bundle} exec #{rainbows_bin} -c $rainbows_CONFIG_PATH -E #{app_env} -D;
          END

          script
        end

        def duplicate_rainbows
          script = <<-END
            if #{rainbows_is_running?}; then
              echo "Duplicating rainbows...";
              #{rainbows_send_signal('USR2')};
            else
              #{start_rainbows}
            fi;
          END

          script
        end

        def rainbows_roles
          fetch(:rainbows_roles, :app)
        end

        #
        # rainbows cap tasks
        #
        namespace :rainbows do
          desc 'Start rainbows master process'
          task :start, :roles => rainbows_roles, :except => {:no_release => true} do
            run start_rainbows
          end

          desc 'Stop rainbows'
          task :stop, :roles => rainbows_roles, :except => {:no_release => true} do
            run kill_rainbows('QUIT')
          end

          desc 'Immediately shutdown rainbows'
          task :shutdown, :roles => rainbows_roles, :except => {:no_release => true} do
            run kill_rainbows('TERM')
          end

          desc 'Restart rainbows'
          task :restart, :roles => rainbows_roles, :except => {:no_release => true} do
            run <<-END
              #{duplicate_rainbows}

              sleep #{rainbows_restart_sleep_time}; # in order to wait for the (old) pidfile to show up

              if #{old_rainbows_is_running?}; then
                #{rainbows_send_signal('QUIT', get_old_rainbows_pid)};
              fi;
            END
          end

          desc 'Duplicate rainbows'
          task :duplicate, :roles => rainbows_roles, :except => {:no_release => true} do
            run duplicate_rainbows()
          end

          desc 'Reload rainbows'
          task :reload, :roles => rainbows_roles, :except => {:no_release => true} do
            run <<-END
              if #{rainbows_is_running?}; then
                echo "Reloading rainbows...";
                #{rainbows_send_signal('HUP')};
              else
                #{start_rainbows}
              fi;
            END
          end

          desc 'Add a new worker'
          task :add_worker, :roles => rainbows_roles, :except => {:no_release => true} do
            run <<-END
              if #{rainbows_is_running?}; then
                echo "Adding a new rainbows worker...";
                #{rainbows_send_signal('TTIN')};
              else
                echo "rainbows is not running.";
              fi;
            END
          end

          desc 'Remove amount of workers'
          task :remove_worker, :roles => rainbows_roles, :except => {:no_release => true} do
            run <<-END
              if #{rainbows_is_running?}; then
                echo "Removing a rainbows worker...";
                #{rainbows_send_signal('TTOU')};
              else
                echo "rainbows is not running.";
              fi;
            END
          end
        end
      end
    end
  end
end

if Capistrano::Configuration.instance
  CapistranoRainbows::CapistranoIntegration.load_into(Capistrano::Configuration.instance)
end

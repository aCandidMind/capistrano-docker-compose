namespace :docker_compose do
  namespace :deploy do
    task :run_steps do
      invoke "docker_compose:deploy:validate"
      %w( build start ).each do |task|
        invoke "docker_compose:#{task}"
      end
    end

    task :validate do
      fetch(:docker_pass_env).each do |env|
        raise "missing #{env} environment variable" if ENV[env].nil?
      end
    end
  end

  desc "build the services (either all or those specified with :docker_compose_build_services)"
  task :build do
    on roles(fetch(:docker_role)) do
      within deploy_path do
        execute :"docker-compose", compose_build_command
      end
    end
  end
  before :build, "docker_compose:prepare_environment"

  desc "start the services (either all or those specified with :docker_compose_build_services)"
  task :start do
    on roles(fetch(:docker_role)) do
      within deploy_path do
        execute :"docker-compose", compose_start_command
      end
    end
  end
  before :start, "docker_compose:prepare_environment"

  desc "stop the services (either all or those specified with :docker_compose_build_services)"
  task :stop do
    on roles(fetch(:docker_role)) do
      within deploy_path do
        execute :"docker-compose", compose_stop_command
        execute :"docker-compose", compose_remove_command unless fetch(:docker_compose_remove_after_stop) == false
      end
    end
  end
  before :stop, "docker_compose:prepare_environment"

  desc "restart the services (either all or those specified with :docker_compose_build_services)"
  task :restart do
    invoke 'docker_compose:stop'
    invoke 'docker_compose:start'
  end

  desc "show the logs of services (either all or those specified with :docker_compose_build_services)"
  task :logs do
    on roles(fetch(:docker_role)) do
      within deploy_path do
        execute :"docker-compose", compose_logs_command
      end
    end
  end

  desc "Show the status of running docker services. This is docker-compose ps"
  task :ps do
    on roles(fetch(:docker_role)) do
      within deploy_path do
        execute :"docker-compose", "ps"
      end
    end
  end

  def compose_start_command
    cmd = ["up", "-d"]
    cmd.unshift("-p #{fetch(:docker_compose_project_name)}") unless fetch(:docker_compose_project_name).nil?
    cmd << fetch(:docker_compose_build_services) unless fetch(:docker_compose_build_services).nil?

    cmd.join(" ")
  end

  def compose_build_command
    cmd = ["build"]
    cmd << fetch(:docker_compose_build_services) unless fetch(:docker_compose_build_services).nil?
    cmd.unshift("-p #{fetch(:docker_compose_project_name)}") unless fetch(:docker_compose_project_name).nil?

    cmd.join(" ")
  end

  def compose_stop_command
    cmd = ["stop"]
    cmd.unshift("-p #{fetch(:docker_compose_project_name)}") unless fetch(:docker_compose_project_name).nil?
    cmd << fetch(:docker_compose_build_services) unless fetch(:docker_compose_build_services).nil?

    cmd.join(" ")
  end

  def compose_remove_command
    cmd = ["rm"]
    cmd.unshift("-p #{fetch(:docker_compose_project_name)}") unless fetch(:docker_compose_project_name).nil?
    cmd << "-f"
    cmd << "-v" if fetch(:docker_compose_remove_volumes) == true
    cmd << fetch(:docker_compose_build_services) unless fetch(:docker_compose_build_services).nil?

    cmd.join(" ")
  end

  def compose_logs_command
    cmd = ["logs"]
    cmd.unshift("-p #{fetch(:docker_compose_project_name)}") unless fetch(:docker_compose_project_name).nil?
    cmd << fetch(:docker_compose_build_services) unless fetch(:docker_compose_build_services).nil?

    cmd.join(" ")
  end
end

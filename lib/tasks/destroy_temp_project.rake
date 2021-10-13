namespace :tmp_project do
  desc 'delete all data of the project'
  task :destroy do
    projects = Project.where.not(tmp_project_id: nil)
    projects.each do |project|
      project.delete_tmp_project
    end
  end
end

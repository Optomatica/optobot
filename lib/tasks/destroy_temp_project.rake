namespace :tmp_project do
  desc 'delete all data of the project'
  task :destroy do
    projects = Project.where.not(tmp_project_id: nil)
    projects.each do |project|
      tmp_project = project.tmp_project
      tmp_project.user_projects.each do |user_project|
        session = user_project.user_chatbot_session
        if (session && session.updated_at < Time.now - 3.hours)
          user_project.user_chatbot_session.destroy
        end
      end
      if UserChatbotSession.all.where(context_id: project.context_ids).empty?
        tmp_project.dialogues.destroy_all
        tmp_project.contexts.destroy_all
        project.tmp_project_id = nil
        project.save!
      end
    end
  end
end

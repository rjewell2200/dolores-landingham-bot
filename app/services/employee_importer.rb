require "slack-ruby-client"

class EmployeeImporter
  def initialize
    configure_slack
  end

  def import_employee(slack_username, dry_run = false)
    # TODO:  Once we can hook up the Team API, we'll want to grab the start
    # TODO:  date of an employee from there instead of defaulting to the
    # TODO:  current date and time.
    error_message = ""
    started_on = Time.now
    success = true

    begin
      if !dry_run
        if !Employee.create(slack_username: slack_username, started_on: started_on)
          success = false
        end
      else
        if Employee.where(slack_username: slack_username).size > 0
          success = false
        end
      end
    rescue => e
      success = false
      error_message = "An error occured when attempting to import the user #{slack_username}: #{e.message} #{e.backtrace.join("\n")}"
    end

    return [success, error_message]
  end

  def import(dry_run = false)
    import_results = {
      created: 0,
      skipped: 0,
      errors: 0
    }

    slack_user_importer = SlackUserImporter.new("", client)
    total_employees = slack_user_importer.slack_usernames.count

    slack_user_importer.slack_usernames.each_with_index do |slack_username, index|
      success, error_message = import_employee(slack_username, dry_run)

      if success
        Rails.logger.info "#{index + 1}/#{total_employees}: Created #{slack_username}".green
        import_results[:created] += 1
      elsif !error_message.blank?
        Rails.logger.error "#{index + 1}/#{total_employees}: #{error_message}".red
        import_results[:errors] += 1
      else
        Rails.logger.info "#{index + 1}/#{total_employees}: Skipped #{slack_username}".yellow
        import_results[:skipped] += 1
      end
    end

    import_results
  end

  private

  def configure_slack
    Slack.configure do |config|
      config.token = ENV['SLACK_API_TOKEN']
    end
  end

  def client
    @client ||= Slack::Web::Client.new
  end
end

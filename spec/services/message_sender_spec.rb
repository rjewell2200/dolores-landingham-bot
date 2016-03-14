require "rails_helper"

describe MessageSender do
  let(:base_dt) { Time.parse("10:00:00 UTC") }
  before { Timecop.freeze(base_dt) }
  let!(:scheduled_message) { create(:scheduled_message) }
  let!(:employee) { create(:employee) }
  let!(:client_double) { Slack::Web::Client.new }
  let!(:slack_channel_id) { 'fake_slack_channel_id' }
  let!(:slack_channel_finder_double) { double(run: slack_channel_id) }

  context 'if sent successfully' do
    before do
      allow(Slack::Web::Client).to receive(:new).and_return(client_double)
      allow(SlackChannelIdFinder).
        to receive(:new).with(employee.slack_username, client_double).
        and_return(slack_channel_finder_double)
      allow(SentScheduledMessage).to receive(:create)
    end

    it "creates a sent scheduled message" do
      MessageSender.new(employee, scheduled_message).run

      expect(SentScheduledMessage).to have_received(:create).with(
        employee: employee,
        scheduled_message: scheduled_message,
        sent_on: Date.today,
        sent_at: Time.parse("10:00:00 UTC"),
        error_message: "",
        message_body: scheduled_message.body,
      )

      Timecop.return
    end

    it 'presists the channel id to the employee\'s slack_channel_id field' do
      MessageSender.new(employee, scheduled_message).run
      expect(employee.reload.slack_channel_id).to eq('fake_slack_channel_id')

      Timecop.return
    end
  end

  context 'if error from SlackApi' do
    before do
      allow(Slack::Web::Client).to receive(:new).and_return(client_double)
      allow(SlackChannelIdFinder).
        to receive(:new).with(employee.slack_username, client_double).
        and_return(slack_channel_finder_double)
      allow(SentScheduledMessage).to receive(:create)
    end

    it "creates a sent scheduled message with error message if error" do
      FakeSlackApi.failure = true
      MessageSender.new(employee, scheduled_message).run

      expect(SentScheduledMessage).to have_received(:create).with(
        employee: employee,
        error_message: "not_authed",
        scheduled_message: scheduled_message,
        sent_on: Date.today,
        sent_at: Time.parse("10:00:00 UTC"),
        message_body: scheduled_message.body,
      )

      Timecop.return
    end
  end

  context 'if channel id not found for slack user' do
    let!(:slack_channel_id_double) { double(run: nil) }
    before do
      allow(Slack::Web::Client).to receive(:new).and_return(client_double)
      allow(SlackChannelIdFinder).
        to receive(:new).with(employee.slack_username, client_double).
        and_return(slack_channel_id_double)
      allow(SentScheduledMessage).to receive(:create)
    end

    it "does not error " do
      MessageSender.new(employee, scheduled_message).run

      expect(SentScheduledMessage).not_to have_received(:create)

      Timecop.return
    end

    it 'persists nil to the employee\'s slack_channel_id' do
      MessageSender.new(employee, scheduled_message).run
      expect(employee.reload.slack_channel_id).to be_nil

      Timecop.return
    end
  end
end

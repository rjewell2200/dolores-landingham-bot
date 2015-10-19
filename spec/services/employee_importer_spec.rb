require "rails_helper"

describe EmployeeImporter do
  describe "#import_employee" do
    it "returns true and no error message if an employee was successfully imported" do
      slack_username = "testusername"
      success, error_message = EmployeeImporter.new.import_employee(slack_username)

      expect(success).to be true
      expect(error_message).to be_empty
    end
  end

  describe "#import" do
    pending it "returns a hash with the number of created empoloyees, skipped employees, and errors that occured"
  end
end

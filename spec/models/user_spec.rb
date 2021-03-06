require 'spec_helper'
require 'devise_two_factor/spec_helpers'

describe User do
  let(:user) { FactoryBot.create(:aptrust_user) }
  let(:inst_admin) { FactoryBot.create(:user, :institutional_admin) }
  let(:inst_id) { subject.institution_id }
  let(:stale_user) { FactoryBot.create(:user, created_at: DateTime.now - 88.days) }

  before :all do
    User.delete_all
    Institution.delete_all
  end

  after :all do
    User.delete_all
    Institution.delete_all
  end

  it { should validate_presence_of(:email) }
  it { should validate_presence_of(:name) }

  # it_behaves_like "two_factor_authenticatable"
  # it_behaves_like "two_factor_backupable"

  it 'should return a valid institution' do
    user.institution.id.should == user.institution_id
  end

  it 'should set a proper grace period' do
    time = Time.now.change(sec: 0)
    user.grace_period.change(sec: 0).should == time
  end

  describe 'as an admin' do
    subject { FactoryBot.create(:user, :admin) }
    its(:groups) { should match_array %w(registered admin) }
  end

  describe 'as an institutional admin' do
    subject { FactoryBot.create(:user, :institutional_admin) }
    its(:groups) { should match_array ['registered', 'institutional_admin', "Admin_At_#{inst_id}"]}
  end

  describe 'as an institutional user' do
    subject { FactoryBot.create(:user, :institutional_user) }
    its(:groups) { should match_array ['registered', 'institutional_user', "User_At_#{inst_id}"]}
  end

  describe '#api_secret_key=' do
    it 'encrypts the key before storing it in database' do
      key = '123'
      user.encrypted_api_secret_key.should be_nil
      stubbed_key = '456'
      user.should_receive(:password_digest).with(key).and_return(stubbed_key)

      user.api_secret_key = key
      user.encrypted_api_secret_key.should == stubbed_key
    end

    it 'sets encrypted key to nil if key is nil' do
      user.api_secret_key = '123'
      user.encrypted_api_secret_key.should_not be_nil
      user.api_secret_key = nil
      user.encrypted_api_secret_key.should be_nil
    end

    it 'sets encrypted key to nil if key is blank' do
      user.api_secret_key = '123'
      user.encrypted_api_secret_key.should_not be_nil
      user.api_secret_key = ''
      user.encrypted_api_secret_key.should be_nil
    end
  end

  describe '#api_secret_key' do
    it 'method exists' do
      user.respond_to?(:api_secret_key).should be true
    end

    it 'returns the unencrypted key if it has been set' do
      user.api_secret_key.should be_nil
      user.api_secret_key = '123'
      user.api_secret_key.should == '123'
    end
  end

  describe '#valid_api_key?' do
    it "returns false if input key doesn't match user's key" do
      user = FactoryBot.create :user, api_secret_key: '123'
      user.valid_api_key?('456').should == false
    end

    it "returns true if input key matches user's key" do
      user = FactoryBot.create :user, api_secret_key: '123'
      user.valid_api_key?('123').should == true
    end

    it "returns false if user's API key is nil" do
      user = FactoryBot.create :user
      user.encrypted_api_secret_key.should be_nil
      user.valid_api_key?(nil).should == false
    end

    it "returns false if user's API key is blank" do
      user = FactoryBot.create :user, encrypted_api_secret_key: ''
      user.encrypted_api_secret_key.should == ''
      user.valid_api_key?('').should == false
    end
  end

  describe '#generate_api_key' do
    it 'sets the encrypted_api_secret_key' do
      user.encrypted_api_secret_key.should be_nil
      user.generate_api_key
      user.encrypted_api_secret_key.should_not be_nil
    end
  end

  describe 'JSON serialization' do
    it "doesn't include the API key" do
      user.api_secret_key = '123abc123abc123abc'
      user.encrypted_api_secret_key.should_not be_nil
      user.to_json.match(/api_secret_key/).present?.should be false
    end
  end

  describe 'soft_delete' do
    it 'deactivates the user' do
      user.soft_delete
      user.deactivated_at.should_not be_nil
      user.encrypted_api_secret_key.should == ''
    end
  end

  describe 'reactivate' do
    it 'reactivates the user' do
      user.soft_delete
      user.reactivate
      user.deactivated_at.should be_nil
    end
  end

  # describe 'session timeout' do
  #   it 'defaults to Devise.timeout_in' do
  #     user.timeout_in.should eq Devise.timeout_in
  #   end
  #   it 'can be reset to an integer value' do
  #     user.set_session_timeout(1234)
  #     user.timeout_in.should eq 1234
  #   end
  # end

  describe 'stale_users' do
    it 'should retrieve a list of stale users' do
      user.created_at = DateTime.now - (ENV['PHAROS_2FA_GRACE_PERIOD'].to_i - 15).days
      user.save!
      inst_admin.created_at = DateTime.now - (ENV['PHAROS_2FA_GRACE_PERIOD'].to_i - 1).days
      inst_admin.save!
      stale_user.created_at = DateTime.now - (ENV['PHAROS_2FA_GRACE_PERIOD'].to_i - 1).days
      stale_user.save!
      users = User.stale_users
      users.count.should eq 2
      users[0].should eq inst_admin
      users[1].should eq stale_user
    end
  end

end

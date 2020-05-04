# == Schema Information
#
# Table name: premis_events
#
#  id                             :integer          not null, primary key
#  identifier                     :string
#  event_type                     :string
#  date_time                      :string
#  outcome_detail                 :string
#  detail                         :string
#  outcome_information            :string
#  object                         :string
#  agent                          :string
#  intellectual_object_id         :integer
#  generic_file_id                :integer
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  outcome                        :string
#  institution_id                 :integer
#  intellectual_object_identifier :string           default(""), not null
#  generic_file_identifier        :string           default(""), not null
#  old_uuid                       :string
#
# Indexes
#
#  index_premis_events_date_time_desc                     (date_time)
#  index_premis_events_on_event_type                      (event_type)
#  index_premis_events_on_event_type_and_outcome          (event_type,outcome)
#  index_premis_events_on_generic_file_id                 (generic_file_id)
#  index_premis_events_on_generic_file_id_and_event_type  (generic_file_id,event_type)
#  index_premis_events_on_generic_file_identifier         (generic_file_identifier)
#  index_premis_events_on_identifier                      (identifier) UNIQUE
#  index_premis_events_on_identifier_and_institution_id   (identifier,institution_id)
#  index_premis_events_on_institution_id                  (institution_id)
#  index_premis_events_on_intellectual_object_id          (intellectual_object_id)
#  index_premis_events_on_intellectual_object_identifier  (intellectual_object_identifier)
#  index_premis_events_on_outcome                         (outcome)
#
class PremisEvent < ApplicationRecord
  self.primary_key = 'id'
  belongs_to :institution
  belongs_to :intellectual_object
  belongs_to :generic_file
  has_and_belongs_to_many :emails

  validates :identifier, :event_type, :date_time, :detail, :outcome, :outcome_detail, :object, :agent, presence: true
  validates :identifier, uniqueness: true

  before_save :init_identifier
  before_save :init_time
  before_save :set_inst_id
  before_save :set_other_identifiers
  #  after_create :update_last_fixity_check

  # ##SCOPES
  scope :with_type, ->(param) { where(event_type: param) if param.present? }
  scope :with_event_identifier, ->(param) { where(identifier: param) if param.present? }
  scope :with_create_date, ->(param) { where(created_at: param) if param.present? }
  scope :created_before, ->(param) { where('premis_events.created_at < ?', param) if param.present? }
  scope :created_after, ->(param) { where('premis_events.created_at >= ?', param) if param.present? }
  scope :with_institution, ->(param) { where(institution_id: param) if param.present? }
  scope :with_outcome, ->(param) { where(outcome: param) if param.present? }
  scope :with_object_identifier, ->(param) { where(intellectual_object_identifier: param) if param.present? }
  scope :with_file_identifier, ->(param) { where(generic_file_identifier: param) if param.present? }
  scope :with_access, lambda { |param|
    if param.present?
      joins(:intellectual_object)
        .where('intellectual_objects.access = ?', param)
    end
  }
  scope :discoverable, lambda { |current_user|
    where(institution_id: current_user.institution.id) unless current_user.admin?
  }
  scope :readable, lambda { |current_user|
    # Inst admin can read anything at their institution.
    # Inst user can read read any unrestricted item at their institution.
    # Admin can read anything.
    if current_user.institutional_admin?
      joins(:intellectual_object)
        .where('intellectual_objects.institution_id = ?', current_user.institution.id)
    elsif current_user.institutional_user?
      joins(:intellectual_object)
        .where("(intellectual_objects.access != 'restricted' and intellectual_objects.institution_id = ?)", current_user.institution.id)
    end
  }
  scope :writable, lambda { |current_user|
    # Only admin has write privileges for now.
    where('(1 = 0)') unless current_user.admin?
  }

  # def to_param
  #   identifier
  # end

  def self.empty_param(param)
    param.blank? || param.nil? || param == '*' || param == '' || param == '%' ? true : false
  end

  def serializable_hash(options = {})
    data = super(options)

    # The following lines are commented out because they
    # cause Rails to issue many SQL queries
    # when we're serializing an IntellectualObject with
    # include_all_relations = true. "Many" can mean
    # over 100,000 in the case of large objects. I'm not
    # even sure that any API client needs this info.
    # If we do find a need for it, we can uncomment it.

    # data.merge!(intellectual_object_id: intellectual_object_id) if self.intellectual_object !nil?
    # data.merge!(generic_file_id: generic_file_id) if self.generic_file !nil?

    # This column is a string, but should be a datetime
    data[:date_time] = Time.parse(self.date_time).utc.iso8601
    data
  end

  def self.failed_fixity_checks(datetime, user)
    if user.admin?
      PremisEvent.with_type(Pharos::Application::PHAROS_EVENT_TYPES['fixity'])
                 .with_outcome('Failure')
                 .created_after(datetime)
    else
      PremisEvent.with_type(Pharos::Application::PHAROS_EVENT_TYPES['fixity'])
                 .with_outcome('Failure')
                 .created_after(datetime)
                 .with_institution(user.institution_id)
    end
  end

  def self.failed_fixity_check_count(datetime, user)
    PremisEvent.failed_fixity_checks(datetime, user).count
  end

  private

  def init_time
    self.date_time = Time.now.utc.iso8601 if self.date_time.nil?
  end

  def init_identifier
    self.identifier = SecureRandom.uuid if self.identifier.nil?
  end

  def set_inst_id
    unless self.intellectual_object.nil?
      self.institution_id = self.intellectual_object.institution_id
    end
  end

  def set_other_identifiers
    if self.intellectual_object_identifier == ''
      self.intellectual_object_identifier = self.intellectual_object.identifier unless self.intellectual_object.nil?
    end
    if self.generic_file_identifier == ''
      self.generic_file_identifier = self.generic_file.identifier unless self.generic_file.nil?
    end
    if (self.event_type == 'fixity check') && !self.generic_file.nil?
      self.generic_file.last_fixity_check = self.date_time
      self.generic_file.save
    end
  end

  #
  # Setting this as an after_create hook seems to cause problems in Postgres
  # when the admin API client calls the GenericFilesController#create_batch
  # method. That method starts a transaction.
  #
  # def update_last_fixity_check
  #   # Some events are related to the IntellectualObject only,
  #   # and do not have an associated GenericFile.
  #   if self.event_type == 'fixity check' and !self.generic_file.nil?
  #     self.generic_file.last_fixity_check = self.date_time
  #     self.generic_file.save!
  #   end
  # end
end

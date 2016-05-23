class InstitutionPolicy < ApplicationPolicy

  def add_user?
    user.admin? ||
        (user.institutional_admin? && user.institution_id == record.id)
  end

  def create?
    user.admin?
  end

  # for intellectual_object
  def create_through_institution?
    user.admin? ||
        (user.institutional_admin? && user.institution_id == record.id)
  end

  def new?
    create?
  end

  def index?
    user.admin? ||  (user.institution_id == record.id)
  end

  def show?
    record.nil? || user.admin? ||  (user.institution_id == record.id)
  end

  def edit?
    update?
  end

  def update?
    user.admin? ||
        (user.institutional_admin? && (user.institution_id == record.id))
  end

  def destroy?
    false
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user.admin?
        scope.all
      else
        scope.where(id: user.institution_id)
      end
    end
  end

end
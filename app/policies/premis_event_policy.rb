class PremisEventPolicy < ApplicationPolicy

  def index?
    user.admin? ||  (user.institution_id == record.id)
  end

  def create?
    user.admin?
  end

  def show?
    user.admin? || user.institution_id == record.id
  end

end

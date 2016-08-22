module ApplicationHelper
  def show_link(object, content = nil, options={})
    content ||= '<i class="glyphicon glyphicon-eye-open"></i> View'
    options[:class] = 'btn doc-action-btn btn-normal btn-sm' if options[:class].nil?
    link_to(content.html_safe, object, options) if policy(object).show?
  end

  def edit_link(object, content = nil, options={})
    content ||= '<i class="glyphicon glyphicon-edit"></i> Edit'
    options[:class] = 'btn doc-action-btn btn-normal btn-sm' if options[:class].nil?
    link_to(content.html_safe, [:edit, object], options) if policy(object).edit?
  end

  def destroy_link(object, content = nil, options={})
    content ||= '<i class="glyphicon glyphicon-trash"></i> Delete'
    options[:class] = 'btn doc-action-btn btn-danger btn-sm' if options[:class].nil?
    options[:method] = :delete if options[:method].nil?
    options[:data] = { confirm: 'Are you sure?' } if options[:confirm].nil?
    link_to(content.html_safe, object, options) if policy(object).destroy?
  end

  def admin_password_link(object, content = nil, options={})
    content ||= '<i class="glyphicon glyphicon-warning-sign"></i> Reset User Password'
    options[:class] = 'btn doc-action-btn btn-danger btn-sm' if options[:class].nil?
    options[:method] = :get if options[:method].nil?
    options[:data] = { confirm: 'Are you sure?' }if options[:confirm].nil?
    link_to(content.html_safe, [:admin_password_reset, object], options) if policy(object).admin_password_reset?
  end

  def create_link(object, content = nil, options={})
    content ||= '<i class="glyphicon glyphicon-plus"></i> Create'
    options[:class] = 'btn doc-action-btn btn-success btn-sm' if options[:class].nil?
    if policy(object).create?
      object_class = (object.kind_of?(Class) ? object : object.class)
      link_to(content.html_safe, [:new, object_class.name.underscore.to_sym], options)
    end
  end

  def header_title
    # TODO put base_title into an ENV
    base_title = 'APTrust'
  end

  def full_title(page_title)
    # TODO put the base_title into an ENV
    base_title = 'APTrust'
    if page_title.empty?
      base_title
    else
      "#{page_title} | #{base_title}"
    end
  end

  def format_boolean_as_yes_no(boolean)
    if boolean == 'true'
      return 'Yes'
    else
      return 'No'
    end
  end

  def display_version
    return '' if Rails.env.production?
    app_version = Pharos::Application::VERSION
    return "Running Pharos ver #{app_version} on Rails #{Rails.version} under Ruby #{RUBY_VERSION}"
  end

  def current_path(param, value)
    old_path = @current
    if old_path.include? param
      old_path = url_for(params.except param)
    end
    if value.kind_of?(Fixnum)
      encoded_val = value
    elsif value.include?('+')
      pieces = value.split('+')
      encoded_val = "#{pieces[0]}%2B#{pieces[1]}"
    else
      encoded_val = URI.escape(value)
    end
    if old_path.include? '?'
      new_path = "#{old_path}&#{param}=#{encoded_val}"
    else
      new_path = "#{old_path}?#{param}=#{encoded_val}"
    end
    new_path
  end
end

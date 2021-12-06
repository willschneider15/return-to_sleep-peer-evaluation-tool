require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @base_title = "Peer Evaluation Tool - "

    @ndm_std_courses = "No Courses"
    @ndm_std_teams = "No Teams"
    @ndm_std_admins = "No Related Admins"
    @ndm_adm_courses = "No Managed Courses"
    @ndm_adm_teams = "No Managed Teams"
    @ndm_adm_admins = "No Co-Admins"

    @instructor = User.new(name: "Example Instructor", email: "instructor@example.com", password: "foobar", password_confirmation: "foobar")
    @instructor.save
    @institution = Institution.new(name_id: "OSU")
    @institution.save
    @admin = Admin.create(user: @instructor, user_id: 1, institution: @institution, institution_id: 1)

    @student = User.create(name: "Example User", email: "user@example.com", password: "foobar", password_confirmation: "foobar")
    @course = Course.create(name: "Example Course Name", class_number: 123)
    @team = Team.create(name: "Example Team Name", course: @course)
  end

  ###############################################################################
  # Student Sign Up Tests
  ###############################################################################

  test "should get sign up" do
    get "/sign_up"
    assert_response :success
    assert_select "title", "#{@base_title}Sign Up"
  end
    
  test "invalid sign-up should not create a new user" do
    get "/sign_up"
    assert_no_difference 'User.count' do
      post "/users", params: { user: { name: "", email: "", password: "", password_confirmation: ""}}
    end
  end

  test "invalid sign-up should trigger error messages" do
    get "/sign_up"
    post "/users", params: { user: { name: "", email: "", password: "", password_confirmation: ""}}
    assert_select "#error-explanation"
  end

  test "valid sign-up should create a new user" do
    get "/sign_up"
    assert_difference 'User.count', 1 do
      post "/users", params: { user: { name: "Jeffrey Gaydos", email: "jg@osu.edu", password: "SomethingC00l", password_confirmation: "SomethingC00l"}}
    end
  end

  ###############################################################################
  # Admin Sign Up Tests
  ###############################################################################

  test "should get sign up for instructors" do
    get "/sign_up/instructors"
    assert_response :success
    assert_select "title", "#{@base_title}Instructors' Sign Up"
  end
    
  test "invalid sign-up for instructors should not create a new user admin" do
    get "/sign_up/instructors"
    assert_no_difference 'User.count' do
      post "/sign_up/instructors", params: { user: { name: "", email: "", password: "", password_confirmation: ""}}
    end
  end

  test "invalid sign-up for instructors should trigger error messages" do
    get "/sign_up/instructors"
    post "/sign_up/instructors", params: { user: { name: "", email: "", password: "", password_confirmation: ""}}
    assert_select "#error-explanation"
  end

  # test "valid instructor sign-up and institution validtion creates an admin user" do
  #   get "/sign_up/instructors"
  #   assert_difference 'User.count', 1 do
  #     post "/sign_up/instructors", params: { user: { name: "Jeffrey Gaydos", email: "jg@osu.edu", password: "SomethingC00l", password_confirmation: "SomethingC00l"}}
  #   end
  #   assert_response :redirect
  #   follow_redirect!
  #   assert_response :success
  #   assert_select "#admin_institution_id", 1
  #   assert_difference 'Admin.count', 1 do
  #     post "/sign_up/institution_auth", params: { admin: { institution_id: "OSU"} }
  #   end
  # end

  ###############################################################################
  # Account Page Tests
  ###############################################################################

  test "Account page shows default message when no related data is available for student" do
    #Logging in...
    get '/login'
    assert_template 'login/init'
    post '/login', params: { session: { email: "user@example.com", password: "foobar" } }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_select "title", "#{@base_title}Account"
    assert session[:user_id]
    
    #Testing that the account page is valid
    assert_select "p.faded", "#{@ndm_std_courses}"
    assert_select "p.faded", "#{@ndm_std_teams}"
    assert_select "p.faded", "#{@ndm_std_admins}"
  end

  test "Account page shows relevant data when present for student" do
    #Setting up "relevant data"
    @student.save
    
    @course.admins << @admin
    @student.courses << @course
    @student.teams << @team

    #Logging in...
    get '/login'
    assert_template 'login/init'
    post '/login', params: { session: { email: "user@example.com", password: "foobar" } }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_select "title", "#{@base_title}Account"
    assert session[:user_id]

    #Testing that the account page is valid
    assert_select "li", "Example Team Name"
    assert_select "li", "Example Course Name | 123"
    assert_select "li", "Example Instructor | Example Course Name"
  end

  test "Account page shows default message when no related data is available for admin user" do
    #Logging in...
    get '/login'
    assert_template 'login/init'
    post '/login', params: { session: { email: "instructor@example.com", password: "foobar" } }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_select "title", "#{@base_title}Account"
    assert session[:user_id]
    
    #Testing that the account page is valid
    assert_select "p.faded", "#{@ndm_adm_courses}"
    assert_select "p.faded", "#{@ndm_adm_teams}"
    assert_select "p.faded", "#{@ndm_adm_admins}"
  end

  test "Account page shows relevant data when present for admin user" do
    #setting up "relevant data"
    @instructor2 = User.new(name: "Example Instructor2", email: "instructor2@example.com", password: "foobar", password_confirmation: "foobar")
    @admin2 = Admin.create(user: @instructor2, user_id: 3, institution: @institution, institution_id: 1)
    @course.admins << @admin
    @course.admins << @admin2
    @course.teams << @team

    #Logging in...
    get '/login'
    assert_template 'login/init'
    post '/login', params: { session: { email: "instructor@example.com", password: "foobar" } }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_select "title", "#{@base_title}Account"
    assert session[:user_id]

    #Testing that the account page is valid
    assert_select "li", "Example Course Name | 123"
    assert_select "li", "Example Team Name"
    assert_select "li", "Example Instructor2"
    assert_select "li", {:count=>0, :text=>"Example Instructor"} #ourself is not a co-admin...
  end

end

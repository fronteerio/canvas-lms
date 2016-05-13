#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AllyController do

  # Create an account that has configured the Ally integration
  def account_with_ally_enabled
    @account ||= Account.create!
    @account.ally_client_id = '1'
    @account.ally_secret = 'secret'
    @account.ally_base_url = 'http://ally.local'
    @account.save
  end

  # Create a course in an account that has Ally disabled
  def course_ally_disabled
    course_with_student({active_enrollment: true, active_course: true})
    user_session(@student)
  end

  # Create a course in an account that has Ally enabled
  def course_ally_enabled
    account_with_ally_enabled
    course({account: @account, active_course: true})
  end

  # Create a course in an account that has Ally enabled and
  # authenticate a student that is enrolled in the course
  def course_with_student_ally_enabled
    account_with_ally_enabled
    opts = {
      active_enrollment: true,
      active_course: true,
      account: @account
    }
    course_with_student(opts)
    user_session(@student)
  end

  # Ensure the the JSON isn't wrapped with `while(1)`
  before :each do
    request.headers['accept'] = 'application/json'
  end

  describe 'GET enabled' do
    it 'should output the ally information' do
      course_ally_disabled
      get :enabled, course_id: @course.id
      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data.keys.length).to be 3
      expect(data['enabled']).to be false
      expect(data['clientId']).to be_nil
      expect(data['baseUrl']).to be_nil
    end

    it 'should output the ally information when enabled' do
      course_with_student_ally_enabled
      get :enabled, course_id: @course.id
      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data.keys.length).to be 3
      expect(data['enabled']).to be true
      expect(data['clientId']).to eq(@course.account.ally_client_id)
      expect(data['baseUrl']).to eq(@course.account.ally_base_url)
    end
  end

  describe 'GET sign' do

    it 'should check whether Ally is enabled for the account' do
      course_ally_disabled
      get 'sign', course_id: @course.id, http_method: 'GET', http_path: '/path/to/ally/api', http_parameters: ''
      assert_status(400)
      expect(response.body).to include('Ally has not been enabled yet')
    end

    it 'should check whether the user is authorized to the course' do
      # Check with an anonymous user
      course_ally_enabled
      get 'sign', course_id: @course.id, http_method: 'GET', http_path: '/path/to/ally/api', http_parameters: ''
      assert_status(401)

      # Check with an unenrolled authenticated user
      user()
      user_session(@user)
      get 'sign', course_id: @course.id, http_method: 'GET', http_path: '/path/to/ally/api', http_parameters: ''
      assert_status(401)

      # Check with an enrolled authenticated user
      student_in_course({course: @course})
      user_session(@student)
      get 'sign', course_id: @course.id, http_method: 'GET', http_path: '/path/to/ally/api', http_parameters: ''
      assert_status(200)
    end

    it 'should output the correct data' do
      course_with_student_ally_enabled
      get 'sign', course_id: @course.id, http_method: 'GET', http_path: '/path/to/ally/api', http_parameters: ''
      assert_status(200)
      data = JSON.parse(response.body)
      expect(data.keys.length).to be 5
      expect(data['clientId']).to eq(@course.account.ally_client_id)
      expect(data['baseUrl']).to eq(@course.account.ally_base_url)
      expect(data['path']).to start_with('/path/to/ally/api')
      expect(data['path']).to include('courseId=')
      expect(data['path']).to include('userId=')
      expect(data['path']).to include('role=')
      expect(data['header']).to start_with('OAuth ')
      expect(data['body']).to be_nil
    end
  end

  describe 'GET proxy' do

    it 'should check whether Ally is enabled for the account' do
      course_ally_disabled
      get 'proxy', course_id: @course.id, http_method: 'GET', http_path: '/path/to/ally/api', http_parameters: ''
      assert_status(400)
      expect(response.body).to include('Ally has not been enabled yet')
    end

    it 'should check whether the user is authorized to the course' do
      course_ally_enabled
      get 'proxy', course_id: @course.id, http_method: 'GET', http_path: '/path/to/ally/api', http_parameters: ''
      assert_status(401)
    end
  end
end

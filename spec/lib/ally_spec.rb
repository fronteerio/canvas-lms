#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe Ally::Client do
  describe '#sign' do
    client_id = '1'
    secret = 'secret'
    base_url = 'https://ally.local'
    course_id = '10'
    user_id = '20'
    role = 'student'
    ally = Ally::Client.new(client_id, secret, base_url)

    it 'returns an appropriate HTTP object' do
      request = ally.sign(course_id, user_id, role, 'GET', '/path/to/ally/api', {})
      expect(request).to be_instance_of(Net::HTTP::Get)
      request = ally.sign(course_id, user_id, role, 'POST', '/path/to/ally/api', {})
      expect(request).to be_instance_of(Net::HTTP::Post)

      # Unsupported methods should raise an error
      expect {
        ally.sign(course_id, user_id, role, 'DELETE', '/path/to/ally/api', {})
      }.to raise_error(ArgumentError)
    end

    it 'returns an OAuth header' do
      request = ally.sign(course_id, user_id, role, 'GET', '/path/to/ally/api', {})
      expect(request).to be_instance_of(Net::HTTP::Get)
      expect(request.to_hash.has_key?('authorization')).to be true
      authorization = request.to_hash['authorization'][0]
      expect(authorization).to start_with('OAuth ')
      expect(authorization).to include("oauth_consumer_key=\"#{client_id}\"")
      expect(authorization).to include('oauth_nonce=')
      expect(authorization).to include('oauth_signature=')
      expect(authorization).to include('oauth_signature_method=')
      expect(authorization).to include('oauth_timestamp=')
      expect(authorization).to include('oauth_version="1.0"')
      expect(authorization).not_to include(secret)
    end

    it 'adds the context information to the parameters' do
      request = ally.sign(course_id, user_id, role, 'GET', '/path/to/ally/api', {fileIds: '1'})
      expect(request.path).to include('fileIds=1')
      expect(request.path).to include("courseId=#{course_id}")
      expect(request.path).to include("userId=#{user_id}")
      expect(request.path).to include("role=#{role}")
    end

    it 'encodes the parameters' do
      request = ally.sign(course_id, user_id, role, 'GET', '/path/to/ally/api', {fileIds: '1,2,3'})
      expect(request.path).to include('fileIds=1%2C2%2C3')
    end
  end
end

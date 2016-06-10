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

require 'oauth'

module Ally

  class Client

    ##
    # Creates a new Ally client
    def initialize(client_id, secret, base_url)
      @client_id = client_id
      @secret = secret
      @base_url = base_url
    end

    ##
    # Sign a request to the Ally API
    #
    #  - course_id:     The Canvas course id
    #  - user_id:       The Canvas user id that is executing the request
    #  - role:          The role of the user within the course
    #  - method:        The type of HTTP request that will be made to the Ally REST API (get or post)
    #  - path:          The path to the Ally REST API
    #  - parameters:    Any parameters that will be sent to the Ally REST API
    def sign(course_id, user_id, role, method, path, parameters)
      consumer = OAuth::Consumer.new(@client_id, @secret, {
        site: @base_url,
        scheme: :header
      })

      # Add the Ally authentication specific parameters
      parameters["userId"] = user_id
      parameters["courseId"] = course_id
      parameters["role"] = role

      if method == 'GET'
        return consumer.create_signed_request(:get, "#{path}?#{parameters.to_query}")
      elsif method == 'POST'
        return consumer.create_signed_request(:post, path, nil, {}, parameters)
      else
        raise ArgumentError, 'method needs to be GET or POST'
      end
    end
  end
end

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

# @API Ally
# API for access Ally data
class AllyController < ApplicationController

  # @API Get Ally information
  # Returns the Ally plugin information
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/ally' \
  #         -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #
  #  { "enabled": true, "clientId": 47831, "baseUrl": "https://prod.ally.ac" }
  #
  def enabled
    plugin_data = get_plugin_data
    data = {
      :enabled => plugin_data[:enabled],
      :clientId => plugin_data[:client_id],
      :baseUrl => plugin_data[:base_url]
    }
    render :json => data
  end

  # @API Create a signed request to the Ally API
  # Get the OAuth signature so a request to the Ally API can be made
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/ally/sign?method=<GET|POST>&path=<path>&parameters=<url encoded parameters>' \
  #         -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #
  #  { "clientId": 47831, "baseUrl": "https://prod.ally.ac", "path": "<path>", "header": "87f82d487f78ffae4dd8b8edaa2547d7", "body": "<urlencoded body>" }
  #
  def sign
    request = get_signed_request_object()
    if (request)
      plugin_data = get_plugin_data()
      data = {
        :clientId => plugin_data[:client_id],
        :baseUrl => plugin_data[:base_url],
        :path => request.path,
        :header => request.to_hash['authorization'][0],
        :body => request.body,
      }
      render :json => data
    end
  end

  ##API Proxy a request to the Ally API
  # Proxy data from the Ally REST API
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/ally/proxy?method=<GET|POST>&path=<path>&parameters=<url encoded parameters>' \
  #         -H 'Authorization: Bearer <token>'
  def proxy
    request = get_signed_request_object()
    if request
      plugin_data = get_plugin_data()
      uri = URI.parse(plugin_data[:base_url])
      http = Net::HTTP.new(uri.host, uri.port)
      response = http.request(request)
      # Render successful requests as JSON
      if response.code == 200 || response.code == 201
        render :json => response.body, :status => response.code
      else
        render :text => response.body, :status => response.code
      end
    end
  end

  protected

  ##
  # Get a request object that can be constructed for the parameters
  # to the `sign` or `proxy` endpoints
  #
  # If the current request context fails any prerequisites, an appropriate
  # error response will be rendered and `false` will be returned
  def get_signed_request_object
    # Respond with a 400 if the Ally plugin hasn't been enabled
    plugin_data = get_plugin_data
    if !plugin_data[:enabled]
      render :text => "Ally has not been enabled yet", :status => :bad_request
      return false
    end

    # Send an appropriate response depending on the role of the user
    get_context()
    role = get_course_role(@context)
    if role.nil?
      render_unauthorized_action
      return false
    end

    # Get the parameters that need to be signed
    method = params['http_method']
    path = params['http_path']
    parameters = params['http_parameters']

    # Perform basic validation of the parameters
    if !(method == "GET" || method == "POST")
      render :text => "The provided http_method needs to be 'GET' or 'POST'", :status => :method_not_allowed
      return false
    elsif !path || !parameters
      render :text => "The http_path and http_parameters need to be provided", :status => :bad_request
      return false
    end

    # Convert the parameters to a hash
    parameters = Rack::Utils.parse_nested_query(parameters)

    # Sign and return the request
    ally_client = Ally::Client.new(plugin_data[:client_id], plugin_data[:secret], plugin_data[:base_url])
    course_id = @context.id
    user_id = @current_user ? @current_user[:id] : "allowed_anonymous"
    return ally_client.sign(course_id, user_id, role, method, path, parameters)
  end

  ##
  # Get the Ally role of the current user within the course.
  #
  # Returns one of:
  #   - "course-manager"  if the user can add or update files in the course
  #   - "student"         if the user has READ rights in the course
  #   - nil               if the user does not have access to the course
  def get_course_role(context)
    if context.grants_any_right?(@current_user, session, *Array([:update, :create]))
      "course-manager"
    elsif context.grants_any_right?(@current_user, session, *Array(:read))
      "student"
    else
      nil
    end
  end

  ##
  # Get the plugin data for this account
  def get_plugin_data
    plugin = Canvas::Plugin.find(:ally)
    enabled = plugin.try(:enabled?)
    data = {
      :enabled => enabled
    }
    if enabled
      data[:client_id] = plugin.settings[:client_id]
      data[:secret] = plugin.settings[:secret_dec]
      data[:base_url] = plugin.settings[:base_url]
    end

    data
  end
end

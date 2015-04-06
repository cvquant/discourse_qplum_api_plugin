# name: qplum_api
# about: API to access qplum APIs 
# version: 0.1
# authors: codeon

register_asset "javascripts/score.js"

load File.expand_path("../qplum_api.rb", __FILE__)

QplumApiPlugin = QplumApiPlugin

after_initialize do 

	module QplumApiPlugin
		class Engine < ::Rails::Engine
			engine_name "qplum_api_engine"
			isolate_namespace QplumApiPlugin
		end

		class QplumApiController < ::ApplicationController
			include CurrentUser

			API_KEY = SiteSetting.qplum_api_key
			API_SECRET = SiteSetting.qplum_api_secret
			API_BASE_PATH = SiteSetting.qplum_api_base_path

			def get_score
				if current_user.nil?
					render status: :forbidden, json: :false
					return 
				else 	
					external_id = current_user.single_sign_on_record.external_id
					url = "#{API_BASE_PATH}users/#{external_id}/score.json"
					response = create_and_execute_get_request(url, {}, true)					
					respond_to do |format|				        
				        format.json { render json: response.body }
				    end
				end
			end

			def add_authentication_headers(request, add_access_token)
				timestamp = Time.now				
				expires_at = timestamp + 30.minutes
				nonce = SecureRandom.hex(32)
				auth_params = {exp: expires_at.to_i, timestamp: timestamp, nonce: nonce}								
				sign = JWT.encode(auth_params, API_SECRET)
				api_key = API_KEY				
				request.add_field("X-qplum_sign", sign)
				request.add_field("X-qplum_api_key", api_key)
				if add_access_token
					if current_user.nil?
						render status: :forbidden, json: :false
						return
					else						
						request.add_field("Authorization", current_user.custom_fields["token"])
					end
				end
				return request
			end

			def create_and_execute_get_request(url, params, add_access_token)
				uri = URI.parse(url)
				uri.query = URI.encode_www_form(params)
				http = Net::HTTP.new(uri.host, uri.port)
				request = Net::HTTP::Get.new(uri.request_uri)
				request = add_authentication_headers(request, add_access_token)
				response = http.request(request)
				return response
			end
		end
	end

	QplumApiPlugin::Engine.routes.draw do
	    get '/score' => 'qplum_api#get_score'
	    # post '/add' => 'qplum_api#add'
  	end

	Discourse::Application.routes.append do
		mount ::QplumApiPlugin::Engine, at: '/qplum_api'
	end
end
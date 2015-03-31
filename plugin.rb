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

			API_KEY = "84cb9c40c0cf8c01"
			API_SECRET = "b2ed129e30666338f1860779a568c18863c7a005afbaa0da018cd37a07adcf96"

			def get_score
				if current_user.nil?
					render status: :forbidden, json: :false
					return 
				else 	
					external_id = current_user.single_sign_on_record.external_id
					url = "http://www.qplum.dev:3001/users/#{external_id}/score.json"
					uri = URI.parse(url)
					auth_params = add_authentication_params({}, true)
					uri.query = URI.encode_www_form(auth_params)
					response = Net::HTTP.get_response(uri)
					respond_to do |format|				        
				        format.json { render json: response.body }
				    end
				end
			end

			def add_authentication_params(params, add_access_token)
				timestamp = Time.now.to_i
				auth_params = params
				auth_params["timestamp"] = timestamp
				auth_params["sign"] = JWT.encode(auth_params, API_SECRET)
				auth_params["api_key"] = API_KEY
				if add_access_token
					if current_user.nil?
						render status: :forbidden, json: :false
						return
					else
						auth_params["access_token"] = current_user.custom_fields["token"]
					end
				end
				return auth_params
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



# name: qplum_api
# about: API to access qplum APIs 
# version: 0.1
# authors: codeon

register_asset "javascripts/discourse/templates/user-dropdown.js.handlebars"
register_asset "javascripts/discourse/templates/user-card.js.handlebars"
register_asset "stylesheets/score.scss"

load File.expand_path("../qplum_api.rb", __FILE__)
 
QplumApiPlugin = QplumApiPlugin

DiscoursePluginRegistry.serialized_current_user_fields << "qplum_score"

after_initialize do 

	User.register_custom_field_type('qplum_score', :integer)

	module QplumApiPlugin
		class Engine < ::Rails::Engine
			engine_name "qplum_api_engine"
			isolate_namespace QplumApiPlugin
		end

		class QplumApiController < ::ApplicationController
			include CurrentUser			

			def update_score
				MessageBus.publish('/qplum_score/1', rand(100..999))
				return
			end

			def get_score
				respond_to do |format|
					msg = {:score => rand(100..999)}
					format.json  { render :json => msg } # don't do msg.to_json
				end
				return
				# user = current_user
				# uid = params[:id]
				# if uid.present?
				# 	user = User.find_by_id(uid)
				# end
				# unless user
				# 	render status: 404, json: :false
				# 	return 
				# end
				# response= Requestor.get_score(current_user, user)
				# unless response 
				# 	render status: :forbidden, json: :false
				# 	return 
				# else
				# 	respond_to do |format|				        
				#         format.json { render json: response.body }
				#     end
				#     return 
				# end				
			end

			def post_event
				response= Requestor.post_event(current_user, params[:user_action], params[:metadata])
				unless response 
					render status: :forbidden, json: :false
					return 
				else
					respond_to do |format|				        
				        format.json { render json: response.body }
				    end
				    return
				end
			end			
		end

		class Requestor 

			API_KEY = SiteSetting.qplum_api_key
			API_SECRET = SiteSetting.qplum_api_secret
			API_BASE_PATH = SiteSetting.qplum_api_base_path

			def self.post_event(current_user, action, metadata)
				if current_user.nil?
					return 
				else					
					external_id = current_user.single_sign_on_record.external_id
					url = "#{API_BASE_PATH}user_events/"
					params = {user_action: action, metadata: metadata.to_json}
					response = create_and_execute_post_request(current_user, url, params, true)
					return response
				end
			end

			def self.get_score(current_user, score_for_user)
				respond_to do |format|
					msg = {:score => rand(100..999)}
					format.json  { render :json => msg } # don't do msg.to_json
				end
				return
				# if current_user.nil?					
				# 	return 
				# else 	
				# 	external_id = score_for_user.single_sign_on_record.external_id
				# 	url = "#{API_BASE_PATH}users/#{external_id}/score.json"
				# 	response = create_and_execute_get_request(current_user, url, {}, true)
				# 	if response.body 
				# 		body = JSON.parse(response.body)
				# 		Rails.logger.info "Response body is #{body}\n\n"
				# 		score = body["score"]
				# 		Rails.logger.debug "Publishing score #{score} to users score\n\n"
				# 		MessageBus.publish("/qplum_score/#{score_for_user.id}", score)
				# 	end
				# 	return response
				# end
			end

			def self.add_authentication_headers(current_user, request, add_access_token)
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

			def self.create_and_execute_get_request(current_user, url, params, add_access_token)
				uri = URI.parse(url)
				uri.query = URI.encode_www_form(params)
				http = Net::HTTP.new(uri.host, uri.port)
				if uri.scheme == "https"
					http.use_ssl = true
					if uri.host == "staging.qplum.co"
						http.verify_mode = OpenSSL::SSL::VERIFY_NONE
					else
						http.verify_mode = OpenSSL::SSL::VERIFY_PEER
						http.ca_path = '/etc/ssl/certs'
					end
				end
				request = Net::HTTP::Get.new(uri.request_uri)
				request = add_authentication_headers(current_user, request, add_access_token)
				response = http.request(request)
				return response
			end

			def self.create_and_execute_post_request(current_user, url, params, add_access_token)
				uri = URI.parse(url)
				# uri.query = URI.encode_www_form(params)
				http = Net::HTTP.new(uri.host, uri.port)
				if uri.scheme == "https"
					http.use_ssl = true
					if uri.host == "staging.qplum.co"
						http.verify_mode = OpenSSL::SSL::VERIFY_NONE
					else
						http.verify_mode = OpenSSL::SSL::VERIFY_PEER
						http.ca_path = '/etc/ssl/certs'
					end
				end
				request = Net::HTTP::Post.new(uri.request_uri)
				request.set_form_data(params)
				request = add_authentication_headers(current_user, request, add_access_token)
				response = http.request(request)
				return response
			end
		end
	end

	Notification.class_eval do
		after_create do 
			if self.notification_type == Notification.types[:granted_badge]
				badge_data = JSON.parse(self.data)
				badge_id = badge_data["badge_id"]
				badge_name = badge_data["badge_name"]
				Rails.logger.info "Granted badge - #{badge_data}, #{badge_id} , #{badge_name}"
				if badge_id
					badge = Badge.includes(:badge_type).find(badge_id)
					type = badge.badge_type.name
					response = QplumApiPlugin::Requestor.post_event(self.user, 
						"badge-granted", 
						{
							"badge_id" => badge_id,
							"badge_name" => badge_name,
							"badge_type" => type,
							"notif_id" => self.id,
							"multiple" => badge.multiple_grant
						}
					)
					if response && response.body 
						body = JSON.parse(response.body)
						if body && body.has_key?("score")
							Rails.logger.debug "After badge-granted , new score is #{body['score']}"
							MessageBus.publish("/qplum_score/#{self.user.id}", body["score"])
						end
					end
				end
			end
		end
	end

	QplumApiPlugin::Engine.routes.draw do
	    get '/score' => 'qplum_api#get_score'
	    get '/score/:id' => 'qplum_api#update_score'
	    get '/updatescore' => 'qplum_api#get_score'
	    post '/event' => 'qplum_api#post_event'
	    # post '/add' => 'qplum_api#add'
  	end

	Discourse::Application.routes.append do
		mount ::QplumApiPlugin::Engine, at: '/qplum_api'
	end
end
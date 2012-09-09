class SmsrouterController < ApplicationController
  def index
    
  end

  def api
    if request.post? 
      @client = Twilio::REST::Client.new ENV['twilio_id'], ENV['twilio_token'] 
      from_number = params[:From]
      sms_in_body = params[:Body]
      #puts sms_in_body
      type = routesms(sms_in_body)[:type]
      puts type
      
      if type == "direction"
        msgBack = sms_in_body
      elsif type == "weather"
        msgBack = weatherMsg(routesms(sms_in_body)[:q])
      elsif type == "error"
        msgBack = routesms(sms_in_body)[:helpMsg]
      else
      end
      
      @client.account.sms.messages.create(
        :from => "+13158951310",
        :to => from_number,
        :body => msgBack
      )
    end
  end
  
  def routesms(sms_in)
    direction_command = ["direction","directions"]
    weather_command = ["weather","weathers"]
    command_list = direction_command + weather_command

          #split the sms string into array
          base_arr = sms_in.split(" ")
          command_in = base_arr[0].downcase
          #this is to detect if the command sent by the user is recognizable by system
          if command_list.include?(command_in)
                  #puts base_arr[0] + " service found\n"
                  
                  #recognize and respond to direction request
                  if direction_command.include?(command_in)
                          
                          #get index of mark for origin and destiny 
                          a = base_arr.index("from")
                          b = base_arr.index("to")
                          
                          # adjust index position to separate 2 locations
                          # in case user put distiny first
                          if a > b 
                            a,b = b,a
                            base_arr[a] = "to"
                            base_arr[b] = "from"
                          end
                          loca_1 = base_arr[(a+1)..(b-1)].join(" ")
                          loca_2 = base_arr[(b+1)..(base_arr.size-1)].join(" ")
                          #puts base_arr[a] +" "+ loca_1
                          #puts base_arr[b] +" "+ loca_2
                          {
                            "type" => command_in,
                            base_arr[a] => loca_1,
                            base_arr[b] => loca_2
                          }
                          #puts result.inspect
                          
                  #recognize and respond to weather request
                  elsif weather_command.include?(command_in)
                    # check if the first word after command is prepsition
                    
                    if base_arr[1] =~ /at|of|in|to/
                      weather_query = base_arr[2..base_arr.length-1].join(" ")
                    else
                      weather_query = base_arr[1..base_arr.length-1].join(" ")
                    end
                          
                            {"type"	=> command_in,
                              "q" 	=> weather_query}
                  end
                  
          #system didn't find a corresponding command
          else  
                  helpMsg = "Please use the following format to get help: direction from city1/street_addr1 to city2/street_addr2, weather of 94115, or weather at san francisco"
                  {
                    "type" => "error",
                    "helpMsg" => helpMsg
                  }
          end
  end  #routesms(sms_in)
  
  def google_direction(origin,destiny)
    
  end
  
  def weatherMsg(q)
    weather_url = "http://free.worldweatheronline.com/feed/weather.ashx"
    query = "&format=json&num_of_days=2&key=" + ENV['weather_token']
    api_call_url = weather_url + "?q=" + q + query
    response = Typhoeus::Request.get api_call_url
    puts response.inspect
    
    temp_c = response[:data][:current_condition][:temm_C]
    temp_f = response[:data][:current_condition][:temm_F]
    
    "current temperature is: " + temp_c + "C/" + temp_f + "F"
    
  end
end

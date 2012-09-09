class SmsrouterController < ApplicationController
  def index
    puts ENV.inspect
  end

  def api
    if request.post? 
      @client = Twilio::REST::Client.new ENV['twilio_id'], ENV['twilio_token'] 
      from_number = params[:From]
      sms_in_body = params[:Body]
      puts routesms(sms_in_body).inspect
      
      @client.account.sms.messages.create(
        :from => "+13158951310",
        :to => from_number,
        :body => sms_in_body
      )
    end
  end
  
  def routesms(sms_in)
    direction_command = ["direction","directions"]
    weather_command = ["weather","weathers"]
    command_list = direction_command + weather_command

          #split the sms string into array
          base_arr = sms_in.split(" ")
          
          #this is to detect if the command sent by the user is recognizable by system
          if command_list.include?(base_arr[0])
                  #puts base_arr[0] + " service found\n"
                  
                  #recognize and respond to direction request
                  if direction_command.include?(base_arr[0])
                          
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
                            "type" => base_arr[0],
                            base_arr[a] => loca_1,
                            base_arr[b] => loca_2
                          }
                          #puts result.inspect
                          
                  #recognize and respond to weather request
                  elsif weather_command.include?(base_arr[0])
                    # check if the first word after command is prepsition
                    
                    if base_arr[1] =~ /at|of|in|to/
                      weather_query = base_arr[2..base_arr.length-1].join(" ")
                    else
                      weather_query = base_arr[1..base_arr.length-1].join(" ")
                    end
                          
                            {"type"	=> base_arr[0],
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
  end  
end

class SmsrouterController < ApplicationController
  def index
    
  end

  def api
    if request.post? || request.get?
      
      from_number = params[:From]
      sms_in_body = params[:Body]
      #puts sms_in_body
      type = routesms(sms_in_body)["type"]
      
      puts "debug info"
      puts sms_in_body
      puts from_number
      puts routesms sms_in_body
      puts type
      @client = Twilio::REST::Client.new ENV['twilio_id'], ENV['twilio_token'] 
      if type == "direction"
        msgBack = google_direction(routesms(sms_in_body)["from"],routesms(sms_in_body)["to"])
      elsif type == "weather"
        msgBack = weatherMsg(routesms(sms_in_body)["q"])
      elsif type == "error"
        msgBack = routesms(sms_in_body)["helpMsg"]
      else
      end
      #@data = weatherMsg(routesms(sms_in_body)["q"])
      #puts msgBack
      
      #p msgBack
      #p cutMsg(msgBack)
      #p cutMsg(msgBack).count
      #p cutMsg(msgBack).last.length
      cuted_msg = cutMsg(msgBack)
      
      for i in 0..cuted_msg.length-1
            @client.account.sms.messages.create(
             :from => +13158951310,
             :to => +16502700918,
             :body => cuted_msg[i]
            )
      sleep 1
      end
    end#end post
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
                            "type" => "direction",
                            base_arr[a] => loca_1,
                            base_arr[b] => loca_2
                          }
            
                          
          #recognize and respond to weather request
          elsif weather_command.include?(command_in)
          # check if the first word after command is prepsition
                    
            if base_arr[1] =~ /at|of|in|to/
              weather_query = base_arr[2..base_arr.length-1].join(" ")
            else
              weather_query = base_arr[1..base_arr.length-1].join(" ")
            end
                          
                     {"type"	=> "weather",
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
    direction_uri = "http://maps.googleapis.com/maps/api/directions/json?origin=" + origin.gsub(" ","+") + "&destination=" + destiny.gsub(" ","+") + "&sensor=false"
    response = ""
    
    json_resp = (JSON.parse(Typhoeus::Request.get(direction_uri).body))["routes"][0]["legs"][0]["steps"]
    i = 0
    json_resp.each do |leg|
      i += 1
      response += leg["html_instructions"]
      response += (i<json_resp.count)? ", " : "." 
    end
    #puts response
    response.gsub("<b>","").gsub("</b>","").gsub('<div style="font-size:0.9em">',' ').gsub("</div>","")
  end
  
  def weatherMsg(q)
    weather_uri = "http://free.worldweatheronline.com/feed/weather.ashx"
    query = "&format=json&num_of_days=2&key=" + ENV['weather_token']
    api_call_uri = weather_uri + "?q=" + q + query
    json_resp = (JSON.parse(Typhoeus::Request.get(api_call_uri).body))["data"]
    #puts json_resp.flatten.inspect
    #puts "br"
    #puts json_resp["current_condition"].inspect
    #puts "br"
    #puts json_resp["weather"].inspect
    #puts "br"
    #puts json_resp["request"].inspect
      
    cur_temp = json_resp["current_condition"][0]["temp_C"] + "C/" + json_resp["current_condition"][0]["temp_F"] + "F"
    cur_desc = json_resp["current_condition"][0]["weatherDesc"][0]["value"].downcase
    
    today_low =   json_resp["weather"][0]["tempMinC"] + "C/" + json_resp["weather"][0]["tempMinF"] + "F"
    today_high =  json_resp["weather"][0]["tempMaxC"] + "C/" + json_resp["weather"][0]["tempMaxF"] + "F"
    today_desc = json_resp["weather"][0]["weatherDesc"][0]["value"].downcase
    
    tom_low =     json_resp["weather"][1]["tempMinC"] + "C/" + json_resp["weather"][0]["tempMinF"] + "F"
    tom_high =    json_resp["weather"][1]["tempMaxC"] + "C/" + json_resp["weather"][0]["tempMaxF"] + "F"
    tom_desc = json_resp["weather"][1]["weatherDesc"][0]["value"].downcase
    
    #final msg to send back
    "Current: "+ cur_desc + ", " + cur_temp +  ", Today: " + today_desc + ", " + today_low + "~" + today_high +  ", Tomorrow: " + tom_desc + ", " + tom_low + "~" + tom_high 
  end
  
  def sendmsg(msg)
    if msg.length<=140
      msg
    else
      msglist = []
    end
  end
  
  #cut message without cutting the word
  def cutMsg(msg)
    if msg.length>160
    
    msg_arr = msg.split(" ")
    msg_single = ""
    msg_cut = []
      for i in 0..msg_arr.count-1
        msg_single +=(msg_arr[i] + " ")
        if msg_single.length>160
          msg_single = msg_single[0..msg_single.length-1-(msg_arr[i].length+1)] # if over 160, cut the last word out
          msg_cut.push msg_single
          puts msg_single.length 
          msg_single = msg_arr[i] + " " #start the next array element with the word just cut out
        end
      end
      msg_cut.push(msg[msg_cut.join(" ").length-2..msg.length])
    else
      msg_cut = [msg]
    end
  end
end

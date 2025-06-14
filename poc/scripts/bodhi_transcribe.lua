package.path = package.path .. ";/usr/local/freeswitch/scripts/?.lua" -- Add the path to the scripts

json = require("json")

-- logme function to log messages
function logme(msg)
    local inspect = require "inspect"
    freeswitch.consoleLog("INFO", inspect(msg))
end

-- Function to terminate the connection (optional if you're handling session:hangup() in the main code
function terminateConnection(uuid)
    os.execute("sleep 2")
    action = "stop"
    api:execute("uuid_bodhi_transcribe", uuid .. " " .. action)
end


if session:ready() then

    -- Set the model to the desired language model
    model = "hi-general-v2-8khz"
    -- check list of available @ https://navana.gitbook.io/bodhi#available-languages-and-asr-models 

    api = freeswitch.API()
    session:sleep(500)
    session:answer()

    uuid = session:getVariable("uuid")
    freeswitch.consoleLog("Info","call started with uuid: " .. tostring(uuid))

    -- Set the API Key and Customer ID if not set in vars.xml
    -- session:execute("set", "BODHI_API_KEY=")
    -- session:execute("export", "BODHI_API_KEY=")
    -- session:execute("set", "BODHI_CUSTOMER_ID=")
    -- session:execute("export", "BODHI_CUSTOMER_ID=")

    local responses = {} -- Array to store all responses

    -- Start the transcription
    local action = "start"
    api:execute("uuid_bodhi_transcribe", uuid .. " " .. action .. " " .. model)

    -- Listen for Bodhi transcription events
    con = freeswitch.EventConsumer()
    con:bind("CUSTOM", "bodhi_transcribe::transcription");
    con:bind("CUSTOM", "bodhi_transcribe::connect_failed");

    local sent_file = false

    -- Send the file
    session:streamFile("ivr/ivr-welcome.wav")
    
    while session:ready() do
        session:execute("sleep", "1000")
        for e in (function() return con:pop(1,10) end) do
            local subclass = e:getHeader("Event-Subclass")
            local body_text = e:getBody()
            logme(body_text)
            
            if subclass == "bodhi_transcribe::connect_failed" then
                freeswitch.consoleLog("ERR", "Connection to transcription service failed.")
                freeswitch.consoleLog("ERR", body_text)
                terminateConnection(uuid)
                session:hangup()
                return
            elseif subclass == "bodhi_transcribe::transcription" then
                local body_json, decode_error = json.decode(body_text)
                if not body_json then
                    freeswitch.consoleLog("ERR", "Error decoding JSON: " .. tostring(decode_error))
                    break
                end
                table.insert(responses, body_json)
                if body_json["type"] == "complete" then
                    local speech_text = body_json["text"]
                    if speech_text ~= nil and not sent_file then
                        sent_file = true
                    end
                end
            end
        end
        -- After sending file once, stop the transcription
        if sent_file then
            os.execute("sleep 5")
            freeswitch.consoleLog("INFO", "Stopping transcription...")
            break  -- Exit the loop after stopping transcription
        end
    end


    -- Print FINAL TRANSCRIBE for each response in the array
    local final_transcription = ""
    for _, response in ipairs(responses) do
        if response["type"] == "complete" then
            speech_text = response["text"]
            if speech_text ~= nil and #speech_text > 0 then
                final_transcription = final_transcription .. speech_text .. " "
            end
        end
    end

    -- Print the concatenated final transcription
    freeswitch.consoleLog("INFO", "Final Transcriptions: " .. final_transcription)

    terminateConnection(uuid)
    os.execute("sleep 2")
    session:hangup()

end
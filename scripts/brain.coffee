myToken = process.env.HUBOT_SLACK_TOKEN
https = require('https')

module.exports = (robot) ->
  robot.respond /message @(.*?) (.*)/i, (res) ->
    username = res.match[1];
    myMessage = res.match[2];
    robot.http("https://slack.com/api/users.list?token=#{myToken}").get() (err, resp, body) ->
      data = JSON.parse body
      if data.ok is true
        for member in data.members
          if member.name is username
              lookingFor = member.id
              robot.http("https://slack.com/api/im.list?token=#{myToken}").get() (err, resp, body) ->
                dms = JSON.parse body
                looking = true
                if dms.ok is true
                  for dm in dms.ims
                    if dm.user is lookingFor
                      looking = false
                      robot.messageRoom "#{dm.id}", "#{myMessage}"
                  if looking is true
                    robot.http("https://slack.com/api/im.open?token=#{myToken}&user=#{lookingFor}").get() (err, resp, body) ->
                      newChannel = JSON.parse body
                      if newChannel.ok is true
                        robot.messageRoom "#{newChannel.channel.id}", "#{myMessage}"
                      else
                        res.reply "Timebot has encounter an error. Timebot is very sorry :( "

                else
                  res.reply "Timebot has encounter an error. Timebot is very sorry :("
      else
        res.reply "Timebot has encounter an error. Timebot is very sorry :("

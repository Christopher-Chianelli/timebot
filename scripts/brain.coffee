myToken = process.env.HUBOT_SLACK_TOKEN
https = require('https')

module.exports = (robot) ->
  myUsers=null
  getUsers = () ->
    robot.http("https://slack.com/api/users.list?token=#{myToken}").get() (err, resp, body) ->
      myUsers = JSON.parse body

  getUsers()

  dmUser = (username, myMessage, errRes) ->
        data = myUsers
        if data.ok
          lookingFor = true
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
                        errRes.reply "Message sent"
                    if looking is true
                      robot.http("https://slack.com/api/im.open?token=#{myToken}&user=#{lookingFor}").get() (err, resp, body) ->
                        newChannel = JSON.parse body
                        if newChannel.ok is true
                          robot.messageRoom "#{newChannel.channel.id}", "#{myMessage}"
                          errRes.reply "Message sent"
                        else
                          errRes.reply "Timebot has encounter an error. Timebot is very sorry :( "
                  else
                    errRes.reply "Timebot has encounter an error. Timebot is very sorry :("

          if lookingFor is true
            errRes.reply "Timebot couldn't find user @#{username}. Sorry :("
        else
          errRes.reply "Timebot has encounter an error. Timebot is very sorry :("
  #-------------------end dmUser-----------------------------------------------#

  robot.respond /message @(.*?) (.*)/i, (res) ->
    username = res.match[1]
    myMessage = res.match[2]
    dmUser username, myMessage, res

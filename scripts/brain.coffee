myToken = process.env.HUBOT_SLACK_TOKEN
Conversation = require('hubot-conversation')
cronJob = require('cron').CronJob

module.exports = (robot) ->
  switchBoard = new Conversation(robot)

  myUsers=null
  getUsers = () ->
    robot.http("https://slack.com/api/users.list?token=#{myToken}").get() (err, resp, body) ->
      myUsers = JSON.parse body

  getUsers()

  dmUser = (username, myMessage) ->
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
                        robot.brain.set username, dm.id
                    if looking is true
                      robot.http("https://slack.com/api/im.open?token=#{myToken}&user=#{lookingFor}").get() (err, resp, body) ->
                        newChannel = JSON.parse body
                        if newChannel.ok is true
                          robot.messageRoom "#{newChannel.channel.id}", "#{myMessage}"
                          robot.brain.set username, newChannel.channel.id
                        else
                          return
                  else
                    return

          if lookingFor is true
            return
        else
          return
  #-------------------end dmUser-----------------------------------------------#

  robot.respond /message @(.*?) (.*)/i, (res) ->
    username = res.match[1]
    myMessage = res.match[2]
    dmUser username, myMessage

  checkShouldStandup = () ->
     now = new Date()
     if now.getUTCHours() == 13 and now.getUTCMinutes() == 0
       doStandup()

  doStandup = () ->
    for member in myUsers.members
      dmUser member.name, "*Are you up yet?* (respond)"
      robot.brain.set member.name + " SU", true


  new cronJob('1 * * * * 1-5', checkShouldStandup, null, true)

  robot.respond /.*/i, (res) ->
    if robot.brain.get("#{res.message.user.name} SU") is true
      if robot.brain.get(res.message.user.name) is res.message.room
        dialog = switchBoard.startDialog(res,3600000)
        res.reply("It is time for our daily standup meeting!")
        res.reply("*1. What did you do yesterday?*")
        dialog.addChoice /timebot (.*)/i, (res2) ->
          res2.reply("*2. What will you do today?*")
          dialog.addChoice /timebot (.*)/i, (res3) ->
              res.reply "Thanks for answering Timebot's questions!"
              robot.messageRoom "C1JDARMC4",
               "Timebot prepared @#{res.message.user.name} standup!\n"
               "*1. What did @#{res.message.user.name} do yesterday?*\n" +
               res2.match[1] +
               "\n*2. What will @#{res.message.user.name} do today?*\n" +
               res3.match[1]
        robot.brain.set "#{res.message.user.name} SU", false

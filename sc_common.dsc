###########################################
# Made by Smellyonionman for Smellycraft. #
#          onion@smellycraft.com          #
#    Tested on Denizen-1.1.0-b4492-DEV    #
#               Version 1.0               #
#-----------------------------------------#
#     Updates and notes are found at:     #
#     https://smellycraft.com/denizen     #
#-----------------------------------------#
#    You may use, modify or share this    #
#    script, provided you don't remove    #
#    or alter lines 1-13 of this file.    #
###########################################
sc_common_init:
    type: task
    debug: false
    script:
    - define namespace:sc_common
    #This task will only output feedback to privileged users
    - define targets:!|:<server.list_online_players.filter[is_op]||null>
    #Initialize global plugin settings
    - if <server.has_file[../Smellycraft/common.yml]||null>:
      - if <yaml.list.contains[sc_common]>:
        - ~yaml unload id:sc_common
      - ~yaml load:../Smellycraft/common.yml id:sc_common
    - else:
      - ~yaml create id:sc_common
      - define payload:<script[sc_common_defaults].to_json||null>
      - if <[payload].matches[null]>:
        - ~webget https://raw.githubusercontent.com/smellyonionman/smellycraft/master/configs/common.yml save:sc_raw headers:host/smellycraft.com:443|user-agent/smellycraft
        - define payload:<entry[sc_raw].result>
      - ~yaml loadtext:<[payload]> id:sc_common
      - yaml set type:! id:sc_common
      - ~yaml savefile:../Smellycraft/common.yml id:sc_common
      - yaml set version:1.0 id:sc_common
    #Initialize scheduler
    - if <server.has_file[../Smellycraft/schedules.yml]||false>:
      - ~yaml load:../Smellycraft/schedules.yml id:sc_schedules
    - else:
      - ~yaml create id:sc_schedules
      - ~yaml savefile:../Smellycraft/schedules.yml id:sc_schedules
    #Load changes to any hand-edited files which correspond to logged-in players
    - foreach <server.list_online_players>:
      - adjust <queue> linked_player:<player[<[value]>]>
      - if <server.has_file[../Smellycraft/playerdata/<player.uuid>.yml].not>:
        - yaml create id:sc_<player.uuid>
      - else:
        - yaml load:../Smellycraft/playerdata/<player.uuid>.yml id:sc_<player.uuid>
    #Initialize plugins cache
    - if <yaml.list.contains[sc_cache].not||null>:
      - yaml create id:sc_cache
    #Initialize player cache
    - if <yaml.list.contains[sc_pcache].not||null>:
      - yaml create id:sc_pcache
    #Brag about it
    - define feedback:<yaml[sc_common].read[messages.admin.reload]||<script[sc_common_defaults].yaml_key[messages.admin.reload]>>
    - inject <script[<yaml[sc_common].read[scripts.narrator]||<script[sc_common_defaults].yaml_key[scripts.narrator]>>]>
sc_common_cmd:
    type: command
    debug: false
    name: smellycraft
    description: <yaml[sc_common].read[messages.command.desc]||<script[sc_common_defaults].yaml_key[messages.command.desc]||Global settings for Smellycraft plugins.>>
    usage: /smellycraft
    script:
    - define namespace:sc_common
    - define admin:<yaml[sc_common].read[permissions.admin]||script[sc_common_defaults].yaml_key[permissions.admin]||smellycraft.admin>>
    #Single-argument commands
    - if <context.args.size.is[==].to[1]||null>:
      - if <context.args.get[1].to_lowercase.matches[reload]||null>:
        - if <player.has_permission[<[admin]>]> || <player.is_op> || <context.server> || false:
          - inject <script[sc_common_init]>
          - stop
      - else if <context.args.get[1].to_lowercase.matches[update]||null>:
        - if <player.has_permission[<[admin]>]> || <player.is_op >|| <context.server> || false:
          - inject <script[<yaml[sc_common].read[scripts.updater]||<script[sc_common_defaults].yaml_key[scripts.updater]>>]>
          - stop
      - else if <context.args.get[1].to_lowercase.matches[set]||null>:
        - define placeholder:<yaml[sc_common].read[messages.admin.args_m]||<script[sc_common_defaults].yaml_key[messages.admin.args_m]||&cError>>
        - define feedback:<element[<[placeholder]>].replace[[args]].with[&ltsetting&gt&sp(&ltsubsetting&gt)&sp&ltstate&gt]>
    #Double-argument commands
    - else if <context.args.size.is[==].to[2]||null>:
      #If not enough args supplied to 'set'
      - if <context.args.get[1].to_lowercase.matches[set]||null>:
        - define placeholder:<yaml[sc_common].read[messages.admin.args_m]||<script[sc_common_defaults].yaml_key[messages.admin.args_m]||&cError>>
        - define feedback:<element[<[placeholder].replace[[args]].with[(&ltsubsetting&gt)&sp&ltstate&gt]>]>
    #Three arguments
    - else if <context.args.size.is[==].to[3]||null>:
      #Change a setting without reloading
      - if <context.args.get[1].to_lowercase.matches[set]||null>:
        - if <context.args.get[2].to_lowercase.matches[update]>:
          - if <context.args.get[3].to_lowercase.matches[(true|false)]||false>:
            - if <player.has_permission[<[admin]>]> || <player.is_op> || false:
              - yaml set settings.<context.args.get[2].to_lowercase>:<context.args.get[3].to_lowercase> id:sc_common
              - define placeholder:<yaml[sc_common].read[messages.admin.set]||<script[sc_common_defaults].yaml_key[messages.admin.set]||&cError>>
              - define feedback:<[placeholder].replace[[setting]].with[<context.args.get[2].to_lowercase>].replace[[state]].with[<context.args.get[3].to_lowercase>]>
            - else:
              - define feedback:<yaml[sc_common].read[messages.admin.permission]||<script[sc_common_defaults].yaml_key[messages.admin.permission]||&cError>>
          - else:
            - define feedback:<yaml[sc_common].read[messages.admin.boolean]||<script[sc_common_defaults].yaml_key[messages.admin.boolean]||&cError>>
        - else if <context.args.get[2].to_lowercase.matches[feedback]>:
          - if <context.args.get[3].to_lowercase.matches[(chat|actionbar|custom)]>:
            - define arg:<context.args.get[3].to_lowercase>
            - yaml set settings.<context.args.get[2].to_lowercase>:<[arg]> id:sc_common
            - define placeholder:<yaml[sc_common].read[messages.admin.set]||<script[sc_common_defaults].yaml_key[messages.admin.set]||&cError>>
            - define feedback:<[placeholder].replace[[setting]].with[<context.args.get[2].to_lowercase>].replace[[state]].with[<tern[<[arg].matches[false]>].pass[&c].fail[&a]><[arg]>]>
          - else:
            - define placeholder:<yaml[sc_common].read[messages.admin.args_i]||<script[sc_common_defaults].yaml_key[messages.admin.args_1]||&cError>>
            - define feedback:<[placeholder].replace[[args]].with[<context.args.remove[1|2].separated_by[,&sp]>]>
        - else:
          - define placeholder:<yaml[sc_common].read[messages.admin.args_i]||<script[sc_common_defaults].yaml_key[messages.admin.args_1]||&cError>>
          - define feedback:<[placeholder].replace[[args]].with[<context.args.remove[1|3].separated_by[,&sp]>]>
    - if <[feedback].exists>:
      - inject <script[<yaml[sc_common].read[scripts.narrator]||<script[sc_common_defaults].yaml_key[scripts.narrator]||sc_common_narrator>>]>
#####################################
#     INJECT: CHECK FOR UPDATES     #
#####################################
sc_common_update:
    type: task
    debug: true
    definitions: namespace
    script:
    #Headers are required for my server, don't alter them too much
    - ~webget https://d.smellycraft.com/update save:sc_versions headers:host/smellycraft.com:443|user-agent/smellycraft
    - define feedback:!
    - if <entry[sc_versions].failed>:
      - define feedback:<yaml[sc_common].read[messages.update.failed]||<script[sc_common_defaults].yaml_key[messages.update.failed]>>
    - else:
      - ~yaml loadtext:<entry[sc_versions].result> id:sc_versions
      #Allow for comparison of version numbers formatted like 4.3.2.1
      - define local:<yaml[<[namespace]>].read[version].split[.]||0>
      - define remote:<yaml[sc_versions].read[plugins.<[namespace]>.version].split[.]||-1>
      - foreach <[local]||null>:
        - if <[value].is[LESS].than[<[remote].get[<[loop_index]>]>]>:
          - define new:true
          - foreach stop
        - else:
          - foreach stop
      - if <[new]||false>:
        - define feedback:"&aVersion <[new]> &9available at &a<yaml[sc_versions].read[plugins.<[namespace]>.url]>"
    - if <[feedback].exists>:
      - inject <script[<yaml[sc_common].read[scripts.narrator]||<script[sc_common_defaults].yaml_key[scripts.narrator]>>]>
    - if <yaml.list.contains[sc_versions]>:
      - yaml unload id:sc_versions
#####################################
#  FEEDBACK: NARRATE OR ACTIONBAR?  #
#####################################
sc_common_feedback:
    type: task
    debug: false
    definitions: namespace|feedback|targets
    script:
    - if <[targets].exists.not>:
      - define targets:<player||<list[]>>
    - if <[targets].matches[null]>:
      - stop
    #Chat messages should be prefixed for easy recognition
    - define prefix:<yaml[<[namespace]>].read[messages.prefix]||<script[<[namespace]>_defaults].yaml_key[messages.prefix]||sc_common>>
    #If configured to override player choices... (1)
    - if <yaml[sc_common].read[settings.feedback.force]||false>:
      #And configured to use text chat...
      - if <yaml[sc_common].read[settings.feedback.mode].matches[chat|narrate]||true>:
        - define men_of_talk:!|:<[targets]>
      - else:
        - define men_of_action:!|:<[targets]>
    #...or if players are allowed to choose for themselves (1)
    - else:
      - foreach <[targets]>:
        #And have not elected for actionbar text... (2)
        - if <yaml[sc_<[value].as_player.uuid>].read[smellycraft.options.feedback].matches[chat|narrate]||true>:
          - define men_of_talk:|:<[value].as_player>
        - else:
          - define men_of_action:|:<[value].as_player>
    - if <[men_of_talk].exists>:
      - narrate <element[<[prefix]>&sp<list[<[feedback]>].separated_by[&sp]||&cError>].unescaped.parse_color.parsed> targets:<[men_of_talk]>
    - if <[men_of_action].exists>:
      - foreach <[feedback]>:
        - actionbar <element[<[value]||&cError>].unescaped.parse_color.parsed> targets:<[men_of_action]>
        - wait <duration[2s]>
#####################################
# MARQUEE: ANIMATED MENU TITLE TEXT #
#####################################
sc_common_marquee:
    type: task
    debug: false
    definitions: title|wait|inv
    script:
    #The title is broken into pieces to better fit the space provided for GUI title
    - repeat <[title].size>:
      #Switch the title of a fake inventory for the values in our list
      - inventory open d:in@generic[size=<context.inventory.size||<[inv].size>>;contents=null;title=<[title].get[<[value]>].unescaped.parse_color>]
      #Give the player a short time to read it
      - wait <duration[<[wait]||1s>]>
    - define title:!
    #Go back to the previous inventory
    - inventory open d:<context.inventory||<[inv]>>
#####################################
#      EVENTS: LOAD/SAVE YAML       #
#####################################
sc_common_events:
    type: world
    debug: false
    events:
        on reload scripts:
        #Fires on first-run and after deleting config (and reloading)
        - if <server.has_file[../Smellycraft/common.yml].not>:
          - inject <script[sc_common_init]>
        on server start priority:-1:
        #Also fires when server is started, to accomodate presence of config file
        - inject <script[sc_common_init]>
        on player join:
        #Playerdata folder stores persistent player-specific settings between restarts
        - if <yaml.list.contains[sc_<player.uuid||null>].not>:
          - if <server.has_file[../Smellycraft/playerdata/<player.uuid||null>.yml]>:
            - ~yaml load:../Smellycraft/playerdata/<player.uuid||null>.yml id:sc_<player.uuid||null>
          - else:
            - ~yaml create id:sc_<player.uuid||null>
        on player quits:
        #Save the player's persistent data to disk
        - if <yaml.list.contains[sc_<player.uuid>]>:
          - ~yaml savefile:../Smellycraft/playerdata/<player.uuid||null>.yml id:sc_<player.uuid>
          - yaml unload id:sc_<player.uuid>
        #Destroy player's cached data on quit, in case they rejoin prior to next restart
        - yaml set <player.uuid>:! id:sc_pcache
        on shutdown:
        - if <yaml.list.contains[sc_common]||false>:
          - yaml savefile:../Smellycraft/common.yml id:sc_common
        - if <yaml.list.contains[sc_schedules]||false>:
          - yaml savefile:../Smellycraft/schedules.yml id:sc_schedules
sc_common_defaults:
  type: yaml data
  settings:
    update: true
    feedback: custom
  scripts:
    narrator: sc_common_feedback
    GUI: sc_common_marquee
    updater: sc_common_update
  permissions:
    admin: smellycraft.admin
  messages:
    prefix: '&9[&aSmellycraft&9]'
    admin:
      permission: '&cYou don''t have permission.'
      reload: '&9Common files have been reloaded.'
      set: '&a[setting] &9has been set to [state]&9.'
      args_m: '&cMissing arguments: [args]'
      args_i: '&cInvalid arguments: [args]'
      boolean: '&cPlease specify true or false.'
      reload: '&9Plugin has been reloaded.'
      disabled: '&cPlugin is currently disabled.'
    update:
      failed:
      - '&cVersion could not be checked.'
      - '&9Try visiting the repository:'
      - '&ahttps://smellycraft.com/denizen'
      enabled: '&aUpdates enabled.'
      enabled-no: '&9Updates are already enabled.'
      disabled: '&cUpdates disabled.'
      disabled-no: '&9Updates are already disabled.'
      specify: '&cPlease specify enable or disable.'
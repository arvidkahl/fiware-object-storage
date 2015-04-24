###*
 * FIWARE Object Storage GE read/write access
 *
 * You will need your FIWARE account credentials for this module to work.
###

needle = require "needle"
chalk = require "chalk"
q = require "q"
btoa = require "btoa"
atob = require "atob"
qs = require "qs"

currentAuthToken = null
currentFullAuthToken = null
currentTenant = null

auth = null 
url = null
user = null 
password = null 
container = null

chalk.enabled = yes
debug = yes

debugInfo = ->
  debugLog.apply null, arguments, "info"
debugSuccess = ->
  debugLog.apply null, arguments, "success"
debugErr = ->
  debugLog.apply null, arguments, "error"

debugLog = (message,level="info")->
  if debug
    switch level
      when "info"
        output = chalk.blue("FIWARE")+": "
        output += message
      when "success"
        output = chalk.green("FIWARE")+": "
        output += message
      when "error"
        output = chalk.red("FIWARE")+": "
        output += chalk.red(message)
    console.log output

getFile = (name)->
  deferred = q.defer()
  unless currentFullAuthToken
    deferred.reject "No Auth Token available"
    return debugErr "No Auth Token available"
  else
    debugLog "Getting File #{name} from #{container}."
    needle.get "http://#{url}:8080/ctm/AUTH_#{currentTenant}/#{container}/#{name}",
      headers :
        "x-auth-token" : currentFullAuthToken
        "x-cdmi-specification-version" : "1.0.1"
    , (err, contents, body)->
      if err
        debugErr err
      else
        debugLog "Got File Contents #{name} from #{container}."
        parsedBody = qs.parse(body.toString())
        deferred.resolve
          meta : JSON.parse parsedBody.meta
          mimetype: parsedBody.mimetype
          value : parsedBody.value
  return deferred.promise


putFile = (name, data, meta)->
  deferred = q.defer()
  unless currentFullAuthToken
    deferred.reject "No Auth Token available"
    return debugErr "No Auth Token available"
  else
    debugLog "Uploading File #{name} to #{container}."
    try
      putData = data
    catch e
      debugErr "Error stringifying data file. "+e
      putData = ""

    needle.put "http://#{url}:8080/ctm/AUTH_#{currentTenant}/#{container}/#{name}",
      mimetype : meta.mimetype
      meta : JSON.stringify meta
      value : putData
    ,
      headers :
        "x-auth-token" : currentFullAuthToken
        "content-type" : "application/cdmi-object"
        "accept" : "application/cdmi-object"
        "x-cdmi-specification-version" : "1.0.1"
    , (err, putResponse)->
      if err
        deferred.reject err
        debugErr "Error uploading file #{name} to #{container}. "+err
      else
        deferred.resolve putResponse?.body
        debugSuccess "Uploaded File #{name} to #{container}."
  return deferred.promise

getFileList =()->
  deferred = q.defer()
  unless currentFullAuthToken
    deferred.reject "No Auth Token available"
    return debugErr "No Auth Token available"
  else
    debugLog "Listing Files."
    needle.get "http://#{url}:8080/ctm/AUTH_#{currentTenant}/#{container}/",
      headers :
        "x-auth-token" : currentFullAuthToken
        "content-type" : "application/cdmi-container"
        "accept" : "*/*"
        "x-cdmi-specification-version" : "1.0.1"
    , (err, listResponse)->
      if err
        deferred.reject err
        debugErr "Error getting file list. "+err
      else
        parsedListData =
          list : []
          container : container
        for item in listResponse?.body?.split "\n"
          parsedListData.list.push item.trim() if item.trim()
        deferred.resolve parsedListData

        debugLog "Files in Container ["+chalk.white(container)+"]:"
        debugLog(" - "+item,"success") for item in parsedListData.list
        if parsedListData.list.length is 0
          debugLog "No Files in this Container", "info"
  return deferred.promise


connectToObjectStorage = (config, callback=->)->

  {auth,url,user,password,container} = config

  debugLog "Connecting to FIWARE Object Storage"
  needle.request "post", "http://#{auth}:4730/v2.0/tokens",
    auth :
      passwordCredentials :
        username : user
        password : password
  ,
    json : true
  , (err, authResponse)->
    if err
      debugErr "Error retrieving Auth Token. "+err
    else
      if authResponse.body?.access?.token
        debugLog chalk.green("Received Auth Token")+". Expires #{authResponse.body.access.token.expires}"
        currentAuthToken = authResponse.body?.access?.token.id
      if authResponse.body?.access?.user?.name
        debugLog "Connected as "+chalk.green("#{authResponse.body.access.user.name}")
      needle.get "http://#{auth}:4730/v2.0/tenants",
        headers :
          "x-auth-token" : currentAuthToken
        json : yes
      , (err, tenantResponse)->
        if err
          debugErr "Error retrieving Tenants. "+err
          callback()
        else
          try
            body = JSON.parse tenantResponse?.body
          catch e
            body = {}
          unless body.tenants
            debugErr "No tenants available."
            callback()
          else
            debugLog "Received Tenants."
            debugLog "Selecting Tenant: ["+chalk.green("#{body.tenants[0].name}")+"] #{body.tenants[0].id} (enabled:"+chalk.green("#{body.tenants[0].enabled}")+")"
            currentTenant = body.tenants[0].id
            needle.request "post", "http://#{auth}:4730/v2.0/tokens",
              auth :
                passwordCredentials :
                  username : user
                  password : password
                tenantName : currentTenant
            ,
              json : true
            , (err, fullAuthResponse)->
              if err
                debugErr "Error receiving Full Token. "+err
                callback()
              else
                if fullAuthResponse.body?.access?.token
                  debugLog "Received Full Token. Expires "+chalk.green("#{fullAuthResponse.body?.access?.token?.expires}"), "success"
                  currentFullAuthToken = fullAuthResponse.body.access.token.id
                  callback()

                else
                  callback()
                  debugErr "No Full Token available."


module.exports = (config)->
  {auth,url,user,password,container} = config

  connectToObjectStorage : (callback)->
    connectToObjectStorage config, callback

  getFileList : getFileList
  putFile : putFile
  getFile : getFile

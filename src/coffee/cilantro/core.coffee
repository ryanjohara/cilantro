define [
    'jquery'
    'underscore'
    'backbone'
    'mediator'
    './channels'
    './utils'
    './session'

    # Core plugins that extend various libraries such as Backbone and jQuery.
    # Note, these are applied in place.
    'plugins/js'
    'plugins/jquery-ajax-queue'
    'plugins/backbone-deferrable'
], ($, _, Backbone, mediator, channels, utils, session) ->

    # Relies on the jquery-ajax-queue plugin to supply this method.
    # This ensures data is not silently lost
    $(window).on 'beforeunload', ->
       if $.hasPendingRequest()
           return "Wow, you're quick! Your data is being saved.
               It will only take a moment."

    currentSession = null

    defaultConfig =
        autoroute: true

    c = config: $.extend true, defaultConfig, @cilantro

    aliases =
        dom: $
        ajax: $.ajax

    methods =
        getOption: (key) ->
            utils.getDotProp(c.config, key)

        setOption: (key, value) ->
            utils.setDotProp(c.config, key, value)

        openSession: (url, credentials) ->
            url ?= @getOption('url')
            credentials ?= @getOption('credentials')
            if not url? then throw new Error('Session cannot be opened, no URL defined')
            session.openSession url, credentials, (sessionData) ->
                currentSession = _.clone sessionData

        closeSession: ->
            session.closeSession ->
                currentSession = null

        getCurrentSession: ->
            currentSession?.root

        getSessionUrl: (name) ->
            session.getSessionUrl(currentSession, name)

        getSerranoVersion: ->
            # If there is no version defined, return the absolute minimum
            if not currentSession?.version?
                return [0, 0, 0]

            # Remove anything after the release level
            versionString =
                String(currentSession.version).replace(/[abf].*$/g, "")

            # Try to split the version string into major, minor, and micro
            # version numbers
            versionFields = versionString.split(".")

            # If we don't have values for all of major, minor, and micro
            # version numbers then return the minimum version.
            if versionFields.length != 3
                return [0, 0, 0]

            return [parseInt(versionFields[0], 10),
                    parseInt(versionFields[1], 10),
                    parseInt(versionFields[2], 10)]

        isSerranoOutdated: ->
            serranoVersion = @getSerranoVersion()

            # If the major version numbers of the minimum and actual versions
            # are not identical then we can use the major version alone as the
            # basis for the "outdatedness".
            if serranoVersion[0] == c.minimumSerranoVersion[0]
                # If the minor version numbers of the minimum and actual
                # versions are not identical then we can simply use the minor
                # version as the basis for the "outdatedness".
                if serranoVersion[1] == c.minimumSerranoVersion[1]
                    # At this point the major and micro versions are equal so
                    # just evaluate based on the micro version
                    return serranoVersion[2] < c.minimumSerranoVersion[2]
                else
                    return serranoVersion[1] < c.minimumSerranoVersion[1]
            else
                return serranoVersion[0] < c.minimumSerranoVersion[0]

    channels = _.extend {}, channels, session.channels

    props = { $, _, Backbone, utils }

    # Construct the base object which is composed core libraries, the
    # mediator methods, and the app-level config
    _.extend c, mediator, channels, props, aliases, methods

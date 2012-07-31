# Form Control Views
#
# Each view corresponds to a particular datatype and representation
# appropriate for the type of data.
#
# Supported types include:
#
# - NumberControl
# - EnumerableControl
# - SearchableControl

define [
    'environ'
    'mediator'
    'jquery'
    'underscore'
    'backbone'
], (environ, mediator, $, _, Backbone) ->

    formActionsTemplate = _.template '
        <div class=form-actions>
            <button class="btn btn-mini btn-danger pull-left" name=remove title="Remove filter">Remove</button>
            <button class="btn btn-mini btn-warning" name=exclude title="Exclude results from query">Exclude</button>
            <button class="btn btn-mini btn-success" name=include title="Include results in query">Include</button>
        </div>
    '

    # To reduce the number of possible operators (and confusion), operators
    # that support negation are presented via a button instead of a separate
    # operator.
    NEGATION_OPERATORS = {}

    DEFAULT_EVENTS =
        'click [name=remove]': 'clearFilter'
        'click [name=include]': 'submitInclude'
        'click [name=exclude]': 'submitExclude'
        'change [name=operator]': 'toggleOperator'

    class Control extends Backbone.View
        template: _.template '
            <div class=control-group>
                <h4 class=control-label>{{ label }} <small class=units>({{ units }})</small></h4>
                <div class=controls>
                    <select class=span4 name=operator></select>
                    <input class=span4 type=text name=value>
                    <p class=help-block>{{ help }}</p>
                </div>
            </div>
        '

        events: DEFAULT_EVENTS

        deferred:
            'loadValues': true

        initialize: (options) ->
            super
            @options = options

            # Subscribe to edits for nodes relating to this DataField
            mediator.subscribe "datacontext/#{ @model.id }/edit", (node) =>
                if node is @node then return
                @set(node)

            @render()

        getTemplateData: ->
            label: @model.get('alt_name') or @model.get('name')
            units: @model.get('data').plural_unit
            help: @model.get 'description'

        renderTemplate: ->
            # Render custom template
            @setElement @template @getTemplateData()
            @$el.append formActionsTemplate()

        render: ->
            @renderTemplate()

            @$label = @$ '.control-label'
            @$value = @$ '[name=value]'
            @$operator = @$ '[name=operator]'
            @$controls = @$ '.controls'
            @$actions = @$ '.form-actions'
            @$include = @$ '[name=include]'
            @$exclude = @$ '[name=exclude]'
            @$remove = @$('[name=remove]').hide()

            # Post-processing of elements
            if @options.label is false
                @$label.hide()

            if not (@getTemplateData().units)
                @$('.units').hide()

            @loadOperators()
            @loadValues()

            @defer 'loadStats', true

            return @

        show: ->
            @resolve()

        hide: ->
            @pending()

        # Event-related methods
        preventDefault: (event) ->
            event.preventDefault()

        toggleOperator: (event) ->
            @toggleActions()

        toggleActions: (event) ->
            if NEGATION_OPERATORS[@$operator.val()]
                @$exclude.prop 'disabled', false
            else
                @$exclude.prop 'disabled', true

        submitInclude: (event) ->
            event.preventDefault()
            @submit @get()

        submitExclude: (event) ->
            event.preventDefault()
            @submit @get negated: true

        clearFilter: (event) ->
            event.preventDefault()
            @clear()

        clear: ->
            if @node then @submit()
            @$remove.hide()

        validate: ->

        # Load the stats for the model and appends a representation of
        # them to the controls area. If not stats are returned, nothing
        # is appended
        loadStats: =>
            url = @model.get('links').stats.href
            Backbone.ajax
                url: url
                success: (resp) =>
                    text = []
                    for key, value of resp
                        if key isnt 'links' and value isnt null
                            key = key.charAt(0).toUpperCase() + key.substr(1)
                            if _.isNumber(value) and value isnt 0
                                _avalue = Math.abs(value)
                                if _avalue < 0.01
                                    value = value.toExponential(2)
                                else if Math.round(value) isnt value
                                    value = App.utils.toDelimitedNumber(value.toPrecision(3))
                            text.push "#{key}: #{value}"

                    if text.length
                        $('<p>')
                            .addClass('help-block')
                            .text(text.join(', '))
                            .appendTo @$controls

        # Data processing-related methods
        loadOperators: =>
            for [operator, text] in (operators = @model.get 'operators')
                if operator.charAt(0) is '-'
                    NEGATION_OPERATORS[operator.substr(1)] = operator
                    continue
                @$operator.append "<option value=\"#{ operator }\">#{ text }</option>"

            # If only one operator, don't bother displaying it
            if @$operator.children().length is 1
                @$operator.hide()

        loadValues: =>
            @set()

        coerceValue: (value) ->
            type = @model.get('data').type

            # Special case since datatypes can be null
            if value is 'null'
                return null

            switch type
                when 'boolean'
                    value = if value is 'true' then true else false
                when 'number'
                    value = parseFloat(value)
            return value

        getValue: (options) ->
            if @$value.is '[type=checkbox],[type=radio]'
                value = @$value.prop 'checked'
            else
                value = @$value.val()
                if value is '' or value is null then return
                if @$value.is 'select'
                    value = (@coerceValue val for val in value)
                else
                    value = @coerceValue value
            return value

        getOperator: (options={}) ->
            operator = @$operator.val()
            if options.negated and NEGATION_OPERATORS[operator]
                operator = NEGATION_OPERATORS[operator]
            return operator

        setValue: (value=null) ->
            if @$value.is '[type=checkbox],[type=radio]'
                @$value.prop 'checked', value
            else
                @$value.val value

        setOperator: (value) ->
            @$operator.val value
            @toggleOperator()

        get: (options) ->
            id: @model.id
            operator: @getOperator options
            value: @getValue options

        set: (node) ->
            node = node or @node
            if not node then return
            @node = node

            value = @node.get 'value'
            operator = @node.get 'operator'

            if /^-/.test operator then operator = operator.substr(1)

            @setOperator operator
            @setValue value
            @$remove.show()

        submit: (data={}) ->
            # If the value is undefined, the condition may be removed
            if data.value is undefined
                if @node
                    @setOperator()
                    @setValue()
                    mediator.publish 'datacontext/remove', @node
                    delete @node
                    @$remove.hide()
                return

            # Validate the data
            if (message = @validate(data))
                @trigger 'error', message
                return

            if @node
                @node.set data
                mediator.publish 'datacontext/update', @node
            else
                @node = new App.Models.DataContextNode data
                mediator.publish 'datacontext/add', @node
            @$remove.show()


    # Add Events interface
    _.extend Control::, Backbone.Events


    class NumberControl extends Control
        template: _.template '
            <div class=control-group>
                <h4 class=control-label>{{ label }} <small class=units>({{ units }})</small></h4>
                <div class=controls>
                    <select class=span4 name=operator></select>
                    <input class=span4 type=text name=value>
                    <input class=span4 type=text name=value-2>
                    <p class=help-block>{{ help }}</p>
                </div>
            </div>
        '
        render: ->
            super
            # Hide the secondary value by default
            @$value2 = @$('[name=value-2]').hide()
            return @

        getValue: (options) ->
            if not (value = super) then return
            if /range/.test @getOperator()
                value2 = @coerceValue @$value2.val()
                [value, value2]
            else
                value

        setValue: (value=null) ->
            if /range/.test @getOperator()
                @$value.val value[0]
                @$value2.val(value[1]).show()
            else
                @$value.val value

        toggleOperator: ->
            super
            if /range/.test @getOperator()
                @$value2.show()
            else
                @$value2.hide()


    class EnumerableControl extends Control
        template: _.template '
            <div class=control-group>
                <h4 class=control-label>{{ label }} <small class=units>({{ units }})</small></h4>
                <div class=controls>
                    <select class=span4 name=operator></select>
                    <input class=span8 name=value>
                    <p class=help-block>{{ help }}</p>
                </div>
            </div>
        '

        initialize: (options) ->
            super
            mediator.subscribe 'datacontext/change', @loadValues

        setValue: (value) ->
            if value then @$value.val value.join ', '

        # Override to split and clean values
        getValue: ->
            if not (value = @$value.val()) then return
            vals = []
            for val in value.split /,/
                if (val = val.trim())
                    vals.push @coerceValue val
            return vals

        loadOperators: =>
            NEGATION_OPERATORS['-in'] = 'in'
            for [operator, text] in (operators = @model.get 'operators')
                if operator is 'in'
                    @$operator.append "<option value=\"#{ operator }\">#{ text }</option>"
                    break
            @$operator.hide()

        # Load remote values, cache locally
        loadValues: =>
            @$el.addClass 'loading'
            Backbone.ajax
                url: environ.absolutePath @model.get('links').values.href
                success: (resp) =>
                    @$value.typeahead
                        source: _.pluck resp, 'value'
                        mode: 'multiple'
                    @set()
                    @$el.removeClass 'loading'


    class SearchableControl extends EnumerableControl
        loadValues: =>


    { Control, NumberControl, EnumerableControl, SearchableControl }

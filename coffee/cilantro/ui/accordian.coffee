define [
    './core'
    './base'
    'tpl!templates/views/accordian-group.html'
    'tpl!templates/views/accordian-section.html'
    'tpl!templates/views/accordian-item.html'
], (c, base, templates...) ->

    templates = c._.object ['group', 'section', 'item'], templates


    class Item extends c.Marionette.ItemView
        tagName: 'li'

        template: templates.item


    class Section extends c.Marionette.CompositeView
        className: 'section'

        itemView: Item

        template: templates.section

        itemViewContainer: '.items'


    class Group extends c.Marionette.CompositeView
        className: 'group'

        template: templates.group

        itemView: Section

        itemViewContainer: '.sections'

        itemSectionItems: 'items'

        options:
            collapsable: true

        itemViewOptions: (model, index) ->
            model: model
            index: index
            collection: model[@itemSectionItems]

        ui:
            icon: '.heading span'
            inner: '.inner'

        events:
            'click > .heading': 'toggleCollapse'
            'shown > .inner': 'showCollapse'
            'hidden > .inner': 'hideCollapse'

        onRender: ->
            if not @options.collapsable
                @$('.inner').removeClass('collapse')
                @$('.heading i').hide()

        toggleCollapse: ->
            if @options.collapsable
                @ui.inner.collapse('toggle')

        showCollapse: ->
            @ui.icon.text('-')

        hideCollapse: ->
            @ui.icon.text('+')


    class Accordian extends c.Marionette.CollectionView
        className: 'accordian'

        itemView: Group

        emptyView: base.EmptyView

        itemGroupSections: 'sections'

        options:
            collapsable: true

        itemViewOptions: (model, index) ->
            model: model
            index: index
            collection: model[@itemGroupSections]
            collapsable: @options.collapsable


    { Accordian, Group, Section, Item }

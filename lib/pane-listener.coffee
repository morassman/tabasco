{$} = require 'atom-space-pen-views'

module.exports =
class PaneListener

  initialize: (@tabasco, @pane) ->
    @jPaneView = $(atom.views.getView(@pane));
    @handler = () => @nodeInserted();
    @jPaneView.bind('DOMNodeInserted', @handler);

  nodeInserted: ->
    children = @jPaneView.children("[is='atom-tabs']");

    if children.length > 0
      @tabasco.paneListenerTriggered(@);

  dispose: ->
    @jPaneView.unbind('DOMNodeInserted', @handler);

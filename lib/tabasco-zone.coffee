{$} = require 'atom-space-pen-views'

module.exports =
class TabascoZone extends HTMLElement

  constructor: ->
    super();

  initialize: (@main, @activePane, @activePaneItem, @targetPane, @position, centerOnly = false) ->
    @.classList.add("tabasco-#{@position}-drop-zone");

    itemView = atom.views.getView(@targetPane.getActiveItem());
    paneView = atom.views.getView(@targetPane);
    @jPaneView = $(paneView);
    offsetHeight = @jPaneView.height();

    if itemView?
      offsetHeight = itemView.offsetHeight;

    top = @jPaneView.height() - offsetHeight;

    vWidth = @jPaneView.width() / 10;
    vHeight = offsetHeight;
    hWidth = @jPaneView.width();
    hHeight = offsetHeight / 10;

    vWidth = Math.min(vWidth, hHeight);
    hHeight = vWidth;

    jMe = $(@);

    if @position == 'left'
      jMe.css({'top' : (top + hHeight) + 'px'});
      jMe.width(vWidth);
      jMe.height(vHeight - hHeight - hHeight);
    else if @position == 'right'
      jMe.css({'top' : (top + hHeight) + 'px'});
      jMe.css({'left' : (@jPaneView.width() - vWidth) + 'px'});
      jMe.width(vWidth);
      jMe.height(vHeight - hHeight - hHeight);
    else if @position == 'top'
      jMe.css({'top' : top + 'px'});
      jMe.css({'left' : vWidth + 'px'});
      jMe.width(hWidth - vWidth - vWidth);
      jMe.height(hHeight);
    else if @position == 'bottom'
      jMe.css({'top' : (@jPaneView.height() - hHeight) + 'px'});
      jMe.css({'left' : vWidth + 'px'});
      jMe.width(hWidth - vWidth - vWidth);
      jMe.height(hHeight);
    else if @position == 'center'
      if centerOnly
        jMe.css({'top' : '0px'});
        jMe.css({'left' : '0px'});
        jMe.width(hWidth);
        jMe.height(vHeight);
      else
        jMe.css({'top' : (top + hHeight) + 'px'});
        jMe.css({'left' : vWidth + 'px'});
        jMe.width(hWidth- vWidth - vWidth);
        jMe.height(vHeight - hHeight - hHeight);

    @.addEventListener('dragenter', @handleDragEnter, false);
    @.addEventListener('dragleave', @handleDragLeave, false);
    @.addEventListener('drop', @handleDrop, false);

    jMe.hide();
    @jPaneView.append(jMe);
    jMe.fadeIn(250)

  handleDragEnter: (e) ->
    @.classList.add("tabasco-#{@position}-drop-zone-hover");

  handleDragLeave: (e) ->
    @.classList.remove("tabasco-#{@position}-drop-zone-hover");

  handleDrop: (e) ->
    if e.ctrlKey
      @copyItemToTarget();
    else
      @moveItemToTarget();

    @main.removeZones();

  copyItemToTarget: ->
    copiedItem = @copyItem(@activePaneItem);

    if @position == 'center'
      @targetPane.addItem(copiedItem);
      @targetPane.activate();
      @targetPane.activateItem(copiedItem);
      return;

    params = {items: [copiedItem]};

    if @position == 'left'
      newPane = @targetPane.splitLeft(params);
    else if @position == 'right'
      newPane = @targetPane.splitRight(params);
    else if @position == 'top'
      newPane = @targetPane.splitUp(params);
    else if @position == 'bottom'
      newPane = @targetPane.splitDown(params);

    newPane?.activate();
    newPane?.activateItem(copiedItem);

  moveItemToTarget: ->
    # Do nothing when moving from a pane to itself.
    if @position == 'center' and @activePane == @targetPane
      return;

    if @activePane != @targetPane
      @activePane.moveItemToPane(@activePaneItem, @targetPane, @targetPane.getItems().length);
      if @activePane.getItems().length == 0
        @activePane.destroy();

    if @position == 'center'
      @targetPane.activate();
      @targetPane.activateItem(@activePaneItem);
      return;

    # Prevent an item from being docked to its own pane if it is the only item.
    if @activePane == @targetPane and @activePane.getItems().length == 1
      return;

    copiedItem = @copyItem(@activePaneItem);
    params = {items: [copiedItem]};

    if @position == 'left'
      newPane = @targetPane.splitLeft(params);
    else if @position == 'right'
      newPane = @targetPane.splitRight(params);
    else if @position == 'top'
      newPane = @targetPane.splitUp(params);
    else if @position == 'bottom'
      newPane = @targetPane.splitDown(params);

    @targetPane.destroyItem(@activePaneItem);
    if @targetPane.getItems().length == 0
      @targetPane.destroy();

    # For some reason this doesn't cause the item to get focus...
    newPane?.activate();
    newPane?.activateItem(newPane.getItems()[0]);

  # Got this from the tabs package.
  copyItem: (item) ->
    item.copy?() ? atom.deserializers.deserialize(item.serialize())

module.exports = document.registerElement('tabasco-zone', prototype: TabascoZone.prototype, extends: 'div')

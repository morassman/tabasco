{$} = require 'atom-space-pen-views'

module.exports =
class TabascoZone extends HTMLElement

  constructor: ->
    super();

  initialize: (@main, @activePane, @activePaneItem, @targetPane, @position) ->
    if @position == 'center'
      @.classList.add('tabasco-grab-zone-center');
    else
      @.classList.add('tabasco-grab-zone');

    itemView = atom.views.getView(@targetPane.getActiveItem());
    @paneView = $(atom.views.getView(@targetPane));
    top = @paneView.height() - itemView.offsetHeight;

    vWidth = @paneView.width() / 10;
    vHeight = itemView.offsetHeight;
    hWidth = @paneView.width();
    hHeight = itemView.offsetHeight / 10;

    vWidth = Math.min(vWidth, hHeight);
    hHeight = vWidth;

    tdz = $(@);

    if @position == 'left'
      tdz.css({'top' : (top + hHeight) + 'px'});
      tdz.width(vWidth);
      tdz.height(vHeight - hHeight - hHeight);
    else if @position == 'right'
      tdz.css({'top' : (top + hHeight) + 'px'});
      tdz.css({'left' : (@paneView.width() - vWidth) + 'px'});
      tdz.width(vWidth);
      tdz.height(vHeight - hHeight - hHeight);
    else if @position == 'top'
      tdz.css({'top' : top + 'px'});
      tdz.css({'left' : vWidth + 'px'});
      tdz.width(hWidth - vWidth - vWidth);
      tdz.height(hHeight);
    else if @position == 'bottom'
      tdz.css({'top' : (@paneView.height() - hHeight) + 'px'});
      tdz.css({'left' : vWidth + 'px'});
      tdz.width(hWidth - vWidth - vWidth);
      tdz.height(hHeight);
    else if @position == 'center'
      tdz.css({'top' : (top + hHeight) + 'px'});
      tdz.css({'left' : vWidth + 'px'});
      tdz.width(hWidth- vWidth - vWidth);
      tdz.height(vHeight - hHeight - hHeight);

    @.addEventListener('dragenter', @handleDragEnter, false);
    @.addEventListener('dragleave', @handleDragLeave, false);
    @.addEventListener('drop', @handleDrop, false);

    @paneView.append(tdz);

  handleDragEnter: (e) ->
    @.classList.add('tabasco-grab-zone-hover');

  handleDragLeave: (e) ->
    @.classList.remove('tabasco-grab-zone-hover');

  handleDrop: (e) ->
    @moveItemToTarget();
    @main.removeZones();

  moveItemToTarget: ->
    if @activePane != @targetPane
      @activePane.moveItemToPane(@activePaneItem, @targetPane, @targetPane.getItems().length);
      if @activePane.getItems().length == 0
        @activePane.destroy();

    if @position == 'center'
      @targetPane.activate();
      @targetPane.activateItem(@activePaneItem);
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

{CompositeDisposable} = require 'atom'
{$} = require 'atom-space-pen-views'
TabascoZone = require './tabasco-zone'

module.exports = Tabasco =
  subscriptions: null

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.packages.onDidActivatePackage (pkg) => @packageActivated(pkg)
    @subscriptions.add atom.packages.onDidDeactivatePackage (pkg) => @packageDeactivated(pkg)
    @subscriptions.add atom.workspace.observePanes (pane) => @paneAdded(pane)
    @subscriptions.add atom.workspace.onDidDestroyPane (pane) => @paneRemoved(pane)
    @subscriptions.add atom.workspace.onDidAddPaneItem => @removeZones()
    @subscriptions.add atom.workspace.onDidDestroyPaneItem => @removeZones()
    @tabBarViews = [];
    @zones = [];

    if atom.packages.isPackageActive('tabs')
      @tabsActivated();

  deactivate: ->
    @subscriptions.dispose()

  packageActivated: (pkg) ->
    if pkg.name == 'tabs'
      @tabs = pkg;

  packageDeactivated: (pkg) ->
    if pkg.name == 'tabs'
      @tabs = null;

  paneAdded: (pane) ->
    if !@tabs?
      return;

    for tabBarView in @tabs.mainModule.tabBarViews
      if tabBarView.pane == pane
        pane.onDidMoveItem => @removeZones();
        pane.onDidAddItem => @removeZones();
        pane.onDidRemoveItem => @removeZones();
        @tabBarViewAdded(tabBarView);
    @removeZones();

  paneRemoved: (pane) ->
    @removeZones();

  tabBarViewAdded: (tabBarView) ->
    if tabBarView in @tabBarViews
      return;

    tabBarView.addEventListener "dragstart", (e) => @onDragStart(e)
    tabBarView.addEventListener "dragend", (e) => @onDragEnd(e)
    @tabBarViews.push(tabBarView);

  onDragStart: (e) ->
    panes = atom.workspace.getPanes();
    activePane = atom.workspace.getActivePane();
    activePaneItem = atom.workspace.getActivePaneItem();
    workspaceView = atom.views.getView(atom.workspace);
    includeActivePane = activePane.getItems().length > 1;
    @zones = [];

    for pane in panes
      if pane != activePane or includeActivePane
        @addZones(activePane, activePaneItem, pane);

  onDragEnd: (e) ->
    @removeZones();

  removeZones: ->
    for zone in @zones
      zone.remove();
    @zones = [];

  addZones: (activePane, activePaneItem, targetPane) ->
    left = new TabascoZone();
    right = new TabascoZone();
    top = new TabascoZone();
    bottom = new TabascoZone();

    left.initialize(@, activePane, activePaneItem, targetPane, 'left');
    right.initialize(@, activePane, activePaneItem, targetPane, 'right');
    top.initialize(@, activePane, activePaneItem, targetPane, 'top');
    bottom.initialize(@, activePane, activePaneItem, targetPane, 'bottom');

    @zones.push(left);
    @zones.push(right);
    @zones.push(top);
    @zones.push(bottom);

    if activePane != targetPane
      center = new TabascoZone();
      center.initialize(@, activePane, activePaneItem, targetPane, 'center');
      @zones.push(center);

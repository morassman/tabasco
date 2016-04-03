{CompositeDisposable} = require 'atom'
{$} = require 'atom-space-pen-views'
TabascoZone = require './tabasco-zone'

module.exports = Tabasco =

  activate: (state) ->
    @disposables = new CompositeDisposable();
    @disposables.add atom.packages.onDidActivatePackage (pkg) => @packageActivated(pkg)
    @disposables.add atom.packages.onDidDeactivatePackage (pkg) => @packageDeactivated(pkg)
    @zones = [];

    if atom.packages.isPackageActive('tabs')
      @tabsActivated(atom.packages.getActivePackage('tabs'));

  deactivate: ->
    @disposables.dispose()

  packageActivated: (pkg) ->
    if pkg.name == 'tabs'
      @tabsActivated(pkg);

  packageDeactivated: (pkg) ->
    if pkg.name == 'tabs'
      @tabsDeactivated();

  tabsActivated: (@tabs) ->
    @paneDisposables = new CompositeDisposable();
    @paneDisposables.add atom.workspace.observePanes (pane) => @paneAdded(pane)
    @paneDisposables.add atom.workspace.onDidDestroyPane (pane) => @paneRemoved(pane)
    @paneDisposables.add atom.workspace.onDidAddPaneItem => @removeZones()
    @paneDisposables.add atom.workspace.onDidDestroyPaneItem => @removeZones()

  tabsDeactivated: ->
    @tabs = null;
    @paneDisposables.dispose();

  paneAdded: (pane) ->
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
    tabBarView.addEventListener "dragstart", (e) => @onDragStart(e)
    tabBarView.addEventListener "dragend", (e) => @onDragEnd(e)

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